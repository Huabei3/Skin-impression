"""
Gao 2024 deepskin data adapter — unified data loading for both training and xlsx export.
Refactored: GaoDataset is the single source of truth for GT loading, image scanning,
subject-level split, skin-tone label clustering, and xlsx export.

Follows the same pattern as predict_p/data/dataset.py:
  _load_data() → filter → save snapshot → split → export xlsx → output per-split data.
"""
import os
import sys
import json
import argparse
from pathlib import Path
from collections import defaultdict
from typing import List, Dict, Optional, Tuple

import numpy as np
import pandas as pd

# ── race config ──────────────────────────────────────────────
RACE_CONFIG = {
    "CA": {"model_ids": ["01", "02", "03"], "test_male": "m02",
           "valid_f_r_prefixes": ["f02rrs02", "f02rrs04"]},
    "AS": {"model_ids": ["04", "05", "06"], "test_male": "m05",
           "valid_f_r_prefixes": ["f05rrs02", "f05rrs04"]},
    "SA": {"model_ids": ["07", "08"], "test_male": "m08",
           "valid_f_r_prefixes": ["f08rrs02", "f08rrs04"]},
    "AF": {"model_ids": ["09", "10"], "test_male": "m09",
           "valid_f_r_prefixes": ["f09rrs02", "f09rrs04"]},
}
REFERENCE_VARIANT = "01"  # _01 variant → raw reference per scene

# ── helpers ──────────────────────────────────────────────────
def _extract_subject(folder_name: str) -> str:
    return folder_name[:3]

def _extract_location(folder_name: str) -> str:
    return folder_name[3]

def _is_race_folder(folder_name: str, model_ids: list) -> bool:
    return folder_name[1:3] in model_ids

def _normalize_score(score: float) -> float:
    return float(np.clip(score * 2.0 - 1.0, -1.0, 1.0))

# ── Monk Skin Tone Scale → CIELAB centers (for optional skin label) ──
MONK_SKIN_TONES = [
    "#f6ede4", "#f3e7db", "#f7ead0", "#eadaba", "#d7bd96",
    "#a07e56", "#825c43", "#604134", "#3a312a", "#292420",
]

def _hex_to_rgb(h: str) -> Tuple[float, float, float]:
    h = h.lstrip("#")
    return (int(h[0:2], 16) / 255.0, int(h[2:4], 16) / 255.0, int(h[4:6], 16) / 255.0)

def _rgb_to_cielab(r: float, g: float, b: float) -> Tuple[float, float, float]:
    def _lin(c): return ((c + 0.055) / 1.055) ** 2.4 if c > 0.04045 else c / 12.92
    rl, gl, bl = _lin(r), _lin(g), _lin(b)
    x = rl * 0.4124564 + gl * 0.3575761 + bl * 0.1804375
    y = rl * 0.2126729 + gl * 0.7151522 + bl * 0.0721750
    z = rl * 0.0193339 + gl * 0.1191920 + bl * 0.9503041
    xn, yn, zn = 0.95047, 1.0, 1.08883
    def _f(t):
        d = 6.0 / 29.0
        return t ** (1.0 / 3.0) if t > d ** 3 else t / (3 * d ** 2) + 4.0 / 29.0
    fy = _f(y / yn)
    return (116.0 * fy - 16.0, 500.0 * (_f(x / xn) - fy), 200.0 * (fy - _f(z / zn)))


class SkinLabelClustering:
    """Optional skin tone labels (1-10) via Monk Skin Tone Scale CIELAB centers.

    Not used in per-race training (use_skin_label=False), but kept available
    for cross-race or future experiments.
    """
    def __init__(self):
        self.centers_lab = np.zeros((10, 3), dtype=np.float32)
        for i, h in enumerate(MONK_SKIN_TONES):
            r, g, b = _hex_to_rgb(h)
            L, a, bb = _rgb_to_cielab(r, g, b)
            self.centers_lab[i] = [L, a, bb]
        print(f"[SkinLabel] Monk centers (CIELAB):\n{self.centers_lab}")

    def assign_label(self, avg_rgb: np.ndarray) -> int:
        if avg_rgb.sum() == 0:
            return 5
        r, g, b = float(avg_rgb[0]), float(avg_rgb[1]), float(avg_rgb[2])
        L, a, bb = _rgb_to_cielab(r, g, b)
        pt = np.array([L, a, bb], dtype=np.float32)
        return int(np.argmin(np.sum((self.centers_lab - pt) ** 2, axis=1))) + 1


class GaoDataset:
    """Single source of truth: GT loading, image scanning, splitting, xlsx export, skin labels.

    After construction:
      - self._all_items: full data list (before split), used for xlsx export
      - self._data_train: list of dicts for training
      - self._data_valid: list of dicts for validation
      - self._data_test:  list of dicts for testing

    Usage:
      ds = GaoDataset(data_root="/root/autodl-tmp/rendered_2max",
                      face_root="/root/autodl-tmp/rendered_face",
                      gt_xlsx="/root/autodl-tmp/gt/toMax_gt.xlsx",
                      race="SA",
                      output_dir="/root/autodl-tmp/Quality_guided_STE/data_check",
                      write_info_json=True,
                      info_json_base="/root/autodl-tmp/Quality_guided_STE")
      # ds.get_data_list('train') → ready for EnhancementDataset
    """

    def __init__(self,
                 data_root: str,
                 face_root: str,
                 gt_xlsx: str,
                 race: str,
                 output_dir: Optional[str] = None,
                 write_info_json: bool = False,
                 info_json_base: Optional[str] = None,
                 attribute_serial: str = "01Preference"):
        self.data_root = Path(data_root)        # rendered_2max/
        self.face_root = Path(face_root)         # rendered_face/
        self.race = race
        self.write_info = write_info_json
        self.info_base = Path(info_json_base) if info_json_base else None
        self.race_cfg = RACE_CONFIG[race]
        self.attr_serial = attribute_serial
        self.output_dir = Path(output_dir) if output_dir else None

        # Resolve GT xlsx: when attribute_serial is given, use toMax_gt_{attr}.xlsx
        if gt_xlsx is None:
            self.gt_path = Path(".")
        else:
            self.gt_path = Path(gt_xlsx)
        attr_gt = self.gt_path.parent / f"toMax_gt_{attribute_serial}.xlsx"
        if attr_gt.exists():
            self.gt_path = attr_gt
        elif not self.gt_path.exists():
            # Fallback
            self.gt_path = self.gt_path.parent / "toMax_gt.xlsx"

        # Resolve GT xlsx
        if not self.gt_path.exists():
            alt = self.gt_path.parent / f"toMax_gt_{attribute_serial}.xlsx"
            if alt.exists():
                self.gt_path = alt

        # ── Step 1: Load GT ──────────────────────────────────
        print(f"[{race}] Loading GT from {self.gt_path.name} ...")
        self.gt_scores: Dict[Tuple[str, str], float] = self._load_gt()

        # ── Step 2: Scan rendered_2max & build full data ─────
        print(f"[{race}] Scanning {self.data_root} ...")
        self._all_items: List[Dict] = self._build_full_data()

        # ── Step 3: Skin label assignment (runs but only used if use_skin_label=True) ──
        self._assign_skin_labels()

        # ── Step 4: Save full snapshot (before split) for xlsx export ──
        self._all_items_snapshot = list(self._all_items)

        # ── Step 5: Split ────────────────────────────────────
        self._data_train = [x for x in self._all_items if x["split"] == "train"]
        self._data_valid = [x for x in self._all_items if x["split"] == "valid"]
        self._data_test  = [x for x in self._all_items if x["split"] == "test"]

        print(f"[{race}] Split: train={len(self._data_train)}, valid={len(self._data_valid)}, test={len(self._data_test)}")
        subjects_train = sorted(set(x["subject"] for x in self._data_train))
        subjects_valid = sorted(set(x["subject"] for x in self._data_valid))
        subjects_test  = sorted(set(x["subject"] for x in self._data_test))
        print(f"       subjects: train={subjects_train}, valid={subjects_valid}, test={subjects_test}")

        # ── Step 6: Export xlsx (from snapshot) ──────────────
        if self.output_dir:
            self.output_dir.mkdir(parents=True, exist_ok=True)
            self._export_split_xlsx()
            self._export_integrity_xlsx()

        # ── Step 7: Write info.json for training ──────────────
        if self.write_info and self.info_base:
            self._write_info_json()

    # ── internal ─────────────────────────────────────────────
    def _load_gt(self) -> Dict[Tuple[str, str], float]:
        scores = {}
        xl = pd.ExcelFile(self.gt_path)
        for sheet in xl.sheet_names:
            df = pd.read_excel(self.gt_path, sheet_name=sheet)
            if df.empty:
                continue
            col0 = df.columns[0]
            score_col = None
            for c in df.columns:
                if "preference" in str(c).lower() or "score" in str(c).lower():
                    score_col = c
                    break
            if score_col is None and len(df.columns) >= 2:
                score_col = df.columns[1]
            if score_col is None:
                continue
            for _, row in df.iterrows():
                orig = str(row[col0]).strip()
                if not orig or orig.lower() == "nan":
                    continue
                sv = float(row[score_col]) if not pd.isna(row[score_col]) else None
                if sv is not None:
                    scores[(sheet, orig)] = sv
        print(f"[{self.race}] GT entries loaded: {len(scores)}")
        return scores

    def _build_full_data(self) -> List[Dict]:
        all_folders = sorted([d.name for d in self.data_root.iterdir()
                              if d.is_dir() and (d.name.endswith("i") or d.name.endswith("r"))])
        race_folders = [f for f in all_folders if _is_race_folder(f, self.race_cfg["model_ids"])]
        print(f"[{self.race}] {len(race_folders)} race folders")

        items = []
        missing = []
        for folder in race_folders:
            subject = _extract_subject(folder)
            location = _extract_location(folder)
            base_split = "test" if subject == self.race_cfg["test_male"] else "train"

            folder_path = self.data_root / folder
            jpg_files = sorted(folder_path.glob("*.jpg"))

            scene_groups = defaultdict(list)
            for f in jpg_files:
                parts = f.stem.rsplit("_", 1)
                if len(parts) == 2:
                    scene_groups[parts[0]].append((parts[1], f))

            for prefix, variants in scene_groups.items():
                scene_split = "valid" if prefix in self.race_cfg["valid_f_r_prefixes"] else base_split

                # Find reference (_01) image for this scene
                ref_path = None
                for vn, fp in variants:
                    if vn == REFERENCE_VARIANT:
                        ref_path = fp
                        break
                if ref_path is None:
                    ref_path = variants[0][1]

                for vn, fp in variants:
                    orig_name = fp.stem
                    score = self.gt_scores.get((folder, orig_name))
                    if score is None:
                        missing.append((folder, orig_name))
                        continue

                    items.append({
                        "folder": folder,
                        "subject": subject,
                        "split": scene_split,
                        "scene": prefix,
                        "variant": vn,
                        "raw_path": str(ref_path),
                        "adjusted_path": str(fp),
                        "score": _normalize_score(score),
                        "raw_gt_score": score,
                        "label": None,  # filled later
                        "original_name": orig_name,
                        "scene_person": folder,
                        "model": subject,
                        "ior": location,
                        "scene_name": prefix.replace(folder, ""),  # "h3k" from "f01ih3k"
                    })

        if missing:
            print(f"[{self.race}] WARNING: {len(missing)} samples missing GT score (first 5): {missing[:5]}")
        print(f"[{self.race}] Total samples: {len(items)}")
        return items

    def _assign_skin_labels(self):
        """Optional: assign skin tone label 1-10 via Monk Scale CIELAB centers.
        Only consumed when use_skin_label=True. Always runs but cheap."""
        try:
            from PIL import Image
        except ImportError:
            for item in self._all_items:
                item["label"] = 5
            return

        ref_paths = sorted(set(x["raw_path"] for x in self._all_items))
        label_cache: Dict[str, int] = {}
        clustering = SkinLabelClustering()
        for rp in ref_paths:
            try:
                img = Image.open(rp).convert("RGB")
                arr = np.array(img, dtype=np.float32) / 255.0
                label_cache[rp] = clustering.assign_label(arr.mean(axis=(0, 1)))
            except Exception:
                label_cache[rp] = 5

        for item in self._all_items:
            item["label"] = label_cache.get(item["raw_path"], 5)

        from collections import Counter
        cnt = Counter(item["label"] for item in self._all_items)
        print(f"[{self.race}] Skin label distribution: {dict(sorted(cnt.items()))}")

    def _export_split_xlsx(self):
        """Export split_result_{RACE}.xlsx — scene-level aggregation for readability.
        Data loading remains per-variant; this is display-only.
        Columns: Set | Model | iOr | Scene | original_name (scene prefix) | scene_person"""
        import pandas as pd
        # Deduplicate to scene level: one row per unique scene prefix
        seen = set()
        rows = []
        for item in self._all_items_snapshot:
            key = item["scene"]  # e.g., "f04ih3k"
            if key in seen:
                continue
            seen.add(key)
            rows.append({
                "Set": item["split"],
                "Model": item["model"],
                "iOr": item["ior"],
                "Scene": item["scene_name"],
                "original_name": item["scene"],  # scene prefix, not variant
                "scene_person": item["scene_person"],
            })
        df = pd.DataFrame(rows)
        path = self.output_dir / f"split_result_{self.race}.xlsx"
        df.to_excel(path, index=False)
        print(f"[{self.race}] split_result → {path} ({len(df)} scenes)")

    def _export_integrity_xlsx(self):
        """Export data_integrity_{RACE}.xlsx — scene-level, per-attribute validity."""
        import pandas as pd
        # Group by scene: check if all 33 variants have valid scores
        scene_stats = {}
        for item in self._all_items_snapshot:
            s = item["scene"]  # e.g., "f04ih3k"
            if s not in scene_stats:
                scene_stats[s] = {"folder": item["folder"], "subject": item["subject"],
                                  "split": item["split"], "total": 0, "valid": 0}
            scene_stats[s]["total"] += 1
            if Path(item["adjusted_path"]).exists() and item["raw_gt_score"] is not None:
                scene_stats[s]["valid"] += 1

        rows = []
        for scene, st in scene_stats.items():
            rows.append({
                "folder": st["folder"],
                "subject": st["subject"],
                "split": st["split"],
                "scene": scene,
                "total_variants": st["total"],
                "valid_variants": st["valid"],
                "all_valid": st["valid"] == st["total"],
            })
        df = pd.DataFrame(rows)
        path = self.output_dir / f"data_integrity_{self.race}.xlsx"
        df.to_excel(path, index=False)
        n_ok = int(df["all_valid"].sum())
        print(f"[{self.race}] data_integrity → {path} ({len(df)} scenes, {n_ok} complete)")

    def _write_info_json(self):
        """Write info.json files per sample in Gao format directory.
        Same data that was exported to xlsx → training reads exactly this."""
        import shutil
        base = self.info_base / f"gao_data_{self.race}"
        for split_name, data in [("train", self._data_train),
                                  ("valid", self._data_valid),
                                  ("test", self._data_test)]:
            split_dir = base / split_name
            for i, s in enumerate(data):
                sample_dir = split_dir / f"sample_{i:05d}"
                sample_dir.mkdir(parents=True, exist_ok=True)

                raw_dst = sample_dir / "raw.png"
                adj_dst = sample_dir / "adjusted.png"
                if not raw_dst.exists():
                    try:
                        raw_dst.symlink_to(Path(s["raw_path"]))
                    except OSError:
                        shutil.copy2(s["raw_path"], str(raw_dst))
                if not adj_dst.exists():
                    try:
                        adj_dst.symlink_to(Path(s["adjusted_path"]))
                    except OSError:
                        shutil.copy2(s["adjusted_path"], str(adj_dst))

                info = {"score": s["score"], "label": s["label"], "raw": "raw.png", "adjusted": "adjusted.png"}
                with open(sample_dir / "info.json", "w") as f:
                    json.dump(info, f)
        print(f"[{self.race}] info.json written to {base}/{{train,valid,test}}/")

    # ── public API (used by training) ─────────────────────────
    def get_data_list(self, split: str) -> List[Dict]:
        """Return data_list compatible with EnhancementDataset.
        This is the SAME data that was used for xlsx export (from snapshot)."""
        mapping = {"train": self._data_train, "valid": self._data_valid, "test": self._data_test}
        data = mapping.get(split, [])
        result = []
        for s in data:
            result.append({
                "raw": s["raw_path"],
                "adjusted": s["adjusted_path"],
                "score": s["score"],
                "label": s["label"],
            })
        return result


# ── CLI (data adapter mode) ────────────────────────────────────
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Gao2024 data adapter — unified data loading + xlsx export")
    parser.add_argument("--data-root", type=str, default="/root/autodl-tmp",
                        help="Root dir containing rendered_2max/ rendered_face/ gt/")
    parser.add_argument("--gt-xlsx", type=str, default=None)
    parser.add_argument("--race", type=str, default=None, choices=["CA", "AS", "SA", "AF"])
    parser.add_argument("--output-dir", type=str, default=None)
    parser.add_argument("--all-races", action="store_true")
    parser.add_argument("--write-info-json", action="store_true")
    parser.add_argument("--attribute-serial", type=str, default="01Preference")
    parser.add_argument("--combine-integrity", action="store_true",
                        help="Merge 10 attribute data_integrity files into scene-level combined table")
    args = parser.parse_args()

    data_root = Path(args.data_root)
    out_dir = Path(args.output_dir) if args.output_dir else data_root / "Quality_guided_STE"

    if args.combine_integrity:
        # ── Combine mode: read 10 GT xlsx directly, scene-level integrity with 10 attr columns ──
        from collections import defaultdict
        attrs = ["01Preference","02Attractiveness","03Feminine","04Cooperative",
                 "05Youth","06Healthy","07Fidelity","08Harmony","09Fair","10Ruddy"]
        races = ["CA","AS","SA","AF"] if args.all_races else ([args.race] if args.race else ["CA","AS","SA","AF"])
        gt_dir = Path(data_root) / "gt"

        for race in races:
            print(f"\n=== 10-attr integrity: {race} ===")
            # Collect all scene folders for this race
            rendered_root = Path(data_root) / "rendered_2max"
            race_folders = sorted([d.name for d in rendered_root.iterdir()
                                   if d.is_dir() and _is_race_folder(d.name, RACE_CONFIG[race]["model_ids"])])

            # Build full scene list: for each folder, find all scene prefixes
            all_scenes = {}  # scene → {folder, subject}
            for folder in race_folders:
                folder_path = rendered_root / folder
                for f in folder_path.glob("*.jpg"):
                    parts = f.stem.rsplit("_", 1)
                    if len(parts) == 2:
                        scene = parts[0]  # "f04ih3k"
                        if scene not in all_scenes:
                            all_scenes[scene] = {"folder": folder, "subject": _extract_subject(folder)}

            # Per attribute: count variants per scene
            attr_cols = {}
            for attr in attrs:
                gt_path = gt_dir / f"toMax_gt_{attr}.xlsx"
                if not gt_path.exists():
                    print(f"  [SKIP] {attr}: GT file not found")
                    for s in all_scenes:
                        attr_cols.setdefault(s, {})[attr] = False
                    continue

                # Read all sheets: count variants with VALID (non-NaN) scores per scene
                scene_counts = defaultdict(int)
                xl = pd.ExcelFile(gt_path)
                for sheet in xl.sheet_names:
                    df = pd.read_excel(gt_path, sheet_name=sheet)
                    if df.empty:
                        continue
                    col0 = df.columns[0]
                    # Find the score column
                    score_col = None
                    for c in df.columns:
                        if "preference" in str(c).lower() or "score" in str(c).lower():
                            score_col = c
                            break
                    if score_col is None and len(df.columns) >= 2:
                        score_col = df.columns[1]
                    if score_col is None:
                        continue
                    for _, row in df.iterrows():
                        orig = str(row[col0]).strip()
                        if not orig or orig.lower() == "nan":
                            continue
                        # Skip rows with NaN score
                        if pd.isna(row[score_col]):
                            continue
                        parts = orig.rsplit("_", 1)
                        if len(parts) == 2:
                            scene_counts[parts[0]] += 1

                for s in all_scenes:
                    attr_cols.setdefault(s, {})[attr] = scene_counts.get(s, 0) == 33

            # Build table
            rows = []
            for scene, info in all_scenes.items():
                row = {"folder": info["folder"], "subject": info["subject"], "scene": scene}
                for attr in attrs:
                    row[f"{attr}_valid"] = attr_cols.get(scene, {}).get(attr, False)
                row["valid_attrs"] = sum(1 for attr in attrs if row[f"{attr}_valid"])
                rows.append(row)

            df = pd.DataFrame(rows)
            out_path = out_dir / "data_check" / f"data_integrity_{race}.xlsx"
            df.to_excel(out_path, index=False)
            print(f"[{race}] → {out_path} ({len(df)} scenes)")
            print(df["valid_attrs"].value_counts().sort_index().to_string())
        print("\nDone.")
        sys.exit(0)

    if not args.all_races and args.race is None:
        parser.error("either --race, --all-races, or --combine-integrity required")

    face_root = data_root / "rendered_face"
    gt_xlsx = Path(args.gt_xlsx) if args.gt_xlsx else data_root / "gt" / "toMax_gt.xlsx"

    races = ["CA", "AS", "SA", "AF"] if args.all_races else [args.race]
    for race in races:
        print(f"\n{'='*60}")
        print(f"GaoDataset: race={race}")
        print(f"{'='*60}")
        ds = GaoDataset(
            data_root=str(data_root / "rendered_2max"),
            face_root=str(face_root),
            gt_xlsx=str(gt_xlsx),
            race=race,
            output_dir=str(out_dir / "data_check"),
            write_info_json=bool(args.write_info_json),
            info_json_base=str(out_dir),
            attribute_serial=args.attribute_serial,
        )
        # Data is loaded, split, exported. Verify:
        print(f"  train: {len(ds._data_train)}  valid: {len(ds._data_valid)}  test: {len(ds._data_test)}")
