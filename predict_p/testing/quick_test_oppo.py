"""
predict_p OPPO quick test (no split).

Aligned with `predict_p/testing/quick_test.py`:
- Uses BatchTester pipeline
- Saves `test_results.json` + GT-vs-Pred plot(s) under output_dir

This script differs only in dataset construction:
- No train/val/test split: all samples in the Excel are used as test
- Optional filter by OPPO_SCENES (sheet/folder name)
"""

from __future__ import annotations

import sys
from pathlib import Path
from typing import Any, Dict, Optional

from torch.utils.data import DataLoader

sys.path.append(str(Path(__file__).resolve().parents[2]))

# =============== User config ===============
checkpoint_path: str = r"F:\Github\deepskin\facial_preference\output\predict_p_v3\checkpoints\best_model.pth"  # best_model.pth

OPPO_SCENES = "inLab2v"  # None/"all"/"inLab,outdoor"/["inLab","outdoor"]

TEST_FACE_RGB_ROOT: Optional[str] = r"I:\OPPOskinExpe\rendered_face"
TEST_GLOBAL_RGB_ROOT: Optional[str] = r"I:\OPPOskinExpe\rendered"
TEST_FACE_UV_ROOT: Optional[str] = r"I:\OPPOskinExpe\rendered_face_uv"
TEST_GT_EXCEL_PATH: Optional[str] = r"I:\OPPOskinExpe\oppo_preference_gt_ratio.xlsx"

TEST_BATCH_SIZE: int = 32
NUM_WORKERS: int = 0
# ==========================================


def _normalize_oppo_scenes(scenes):
    if scenes is None:
        return None
    if isinstance(scenes, str):
        s = scenes.strip()
        if not s or s.lower() == "all":
            return None
        parts = [p.strip() for p in s.split(",") if p.strip()]
    else:
        try:
            parts = [str(x).strip() for x in scenes if str(x).strip()]
        except TypeError:
            parts = [str(scenes).strip()]
    if not parts:
        return None
    return sorted({p.lower() for p in parts})


def main() -> None:
    from predict_p.data.dataset import FacialPreferenceDataset, get_data_transforms
    from predict_p.config import Config
    from predict_p.testing.batch_tester import BatchTester

    ckpt = Path(checkpoint_path) if checkpoint_path else None
    if not ckpt or not ckpt.exists():
        raise FileNotFoundError(f"checkpoint_path not found: {checkpoint_path!r}")

    cfg = Config.get_config_dict()
    cfg["TEST_IDS"] = None
    cfg["TEST_BATCH_SIZE"] = int(TEST_BATCH_SIZE)
    cfg["DATALOADER"] = {
        "num_workers": int(NUM_WORKERS),
        "pin_memory": True,
        "persistent_workers": False,
        "prefetch_factor": 2,
    }
    cfg["TRAIN_RATIO"] = 0.0
    cfg["VAL_RATIO"] = 0.0
    cfg["TEST_RATIO"] = 1.0

    data_paths_override: Dict[str, Any] = {}
    if TEST_FACE_RGB_ROOT:
        data_paths_override["FACE_RGB_ROOT"] = str(TEST_FACE_RGB_ROOT)
    if TEST_FACE_UV_ROOT:
        data_paths_override["FACE_UV_ROOT"] = str(TEST_FACE_UV_ROOT)
    if TEST_GLOBAL_RGB_ROOT:
        data_paths_override["GLOBAL_RGB_ROOT"] = str(TEST_GLOBAL_RGB_ROOT)
    if TEST_GT_EXCEL_PATH:
        data_paths_override["GT_EXCEL_PATH"] = str(TEST_GT_EXCEL_PATH)
    if not data_paths_override:
        data_paths_override = None  # type: ignore[assignment]

    output_dir = ckpt.parent / "test_results_oppo_predict_p"

    class OppoBatchTester(BatchTester):
        def prepare_test_dataset(self) -> DataLoader:
            transform = get_data_transforms(self.config, split="test")
            global_rgb_root = Path(self.config.get("GLOBAL_RGB_ROOT", self.config["FACE_RGB_ROOT"]))
            model_variant = str(self.config.get("MODEL_VARIANT", "v1")).lower().strip()
            load_uv = model_variant != "v3"
            uv_is_hist = bool(self.config.get("FACE_UV_IS_HIST", False))
            uv_log_ratio = bool(((self.config.get("MODEL", {}) or {}).get("face_stream", {}) or {}).get("uv_log_ratio", False))

            ds = FacialPreferenceDataset(
                face_rgb_root=Path(self.config["FACE_RGB_ROOT"]),
                face_uv_root=Path(self.config["FACE_UV_ROOT"]),
                gt_excel_path=Path(self.config["GT_EXCEL_PATH"]),
                split="test",
                transform=transform,
                seed=int(self.config.get("RANDOM_SEED", 42)),
                train_ratio=0.0,
                val_ratio=0.0,
                test_ratio=1.0,
                allowed_ids=None,
                global_rgb_root=global_rgb_root,
                split_strategy=str(self.config.get("SPLIT_STRATEGY", "stable_by_id_hash")),
                load_uv=load_uv,
                uv_is_hist=uv_is_hist,
                uv_log_ratio=uv_log_ratio,
            )

            scenes = _normalize_oppo_scenes(OPPO_SCENES)
            if scenes is not None:
                scene_set = set(scenes)
                ds.data_items = [it for it in ds.data_items if str(it.get("scene_person", "")).lower() in scene_set]

            return DataLoader(
                ds,
                batch_size=int(self.config.get("TEST_BATCH_SIZE", 32)),
                shuffle=False,
                num_workers=int(self.config.get("DATALOADER", {}).get("num_workers", 0)),
                pin_memory=bool(self.config.get("DATALOADER", {}).get("pin_memory", True)),
            )

    tester = OppoBatchTester(
        checkpoint_path=str(ckpt),
        config=cfg,
        device="cuda",
        output_dir=str(output_dir),
        data_paths_override=data_paths_override,
    )
    results = tester.run_complete_test()
    print(results.get("score_metrics", {}))
    print(results.get("summary", {}))
    print(results.get("artifacts", {}))


if __name__ == "__main__":
    main()
