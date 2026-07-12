"""
Gao 2024 training on deepskin dataset — per-race, real-time metrics.
"""
import os
import sys
import json
import argparse
from pathlib import Path
from collections import defaultdict

import torch
import torch.optim as optim
from torch.utils.data import DataLoader
import numpy as np
from scipy.stats import pearsonr
from tqdm import tqdm


def _add_gao_to_path():
    """Add Quality_guided_STE + deepskin root to path for imports."""
    gao_path = Path(__file__).resolve().parents[3] / "thesis" / "Quality_guided_STE"
    cloud_gao = Path("/root/autodl-tmp/Quality_guided_STE")
    # deepskin project root: predict_p/gao2024/train.py → ../../.. → deepskin/
    deepskin_root = Path(__file__).resolve().parents[2]
    for p in [str(gao_path), str(cloud_gao), str(deepskin_root)]:
        if os.path.isdir(p) and p not in sys.path:
            sys.path.insert(0, p)


def _normalize_score(score: float) -> float:
    return float(np.clip(score * 2.0 - 1.0, -1.0, 1.0))


def _best_model_path(output_dir: str) -> str:
    return str(Path(output_dir) / "best_model.pth")


def _metrics_path(output_dir: str) -> str:
    return str(Path(output_dir) / "best_metrics.json")


def compute_pearson(pred: np.ndarray, target: np.ndarray) -> float:
    """Compute Pearson r, handling edge cases."""
    pred = np.asarray(pred).ravel()
    target = np.asarray(target).ravel()
    if len(pred) < 2:
        return 0.0
    mask = ~(np.isnan(pred) | np.isnan(target))
    if mask.sum() < 2:
        return 0.0
    r, _ = pearsonr(pred[mask], target[mask])
    return r if np.isfinite(r) else 0.0


def train_race(args, race: str):
    _add_gao_to_path()
    from model import QualityGuidedEnhancer
    from utils import compute_loss, save_checkpoint, rgb_to_lab, lab_to_rgb

    # Import GaoDataset for unified data loading (same source as xlsx export)
    from predict_p.gao2024.data_adapter import GaoDataset

    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

    # ── Unified data loading (same logic as xlsx export) ──────
    data_root = Path(args.data_root)

    # ── Determine attributes ──────────────────────────────────
    _ALL_ATTRS = ["01Preference","02Attractiveness","03Feminine","04Cooperative",
                  "05Youth","06Healthy","07Fidelity","08Harmony","09Fair","10Ruddy"]
    multi_head = getattr(args, 'multi_head', False)
    if multi_head:
        attributes = getattr(args, 'attributes', "all")
        if attributes is None or str(attributes).strip().lower() == "all":
            enabled_attrs = list(_ALL_ATTRS)
        else:
            enabled_attrs = [s.strip() for s in str(attributes).split(",") if s.strip()]
        # Always include 01Preference first
        if "01Preference" not in enabled_attrs:
            enabled_attrs.insert(0, "01Preference")
    else:
        enabled_attrs = ["01Preference"]

    print(f"[{race}] Attributes: {enabled_attrs}")
    print(f"[{race}] Multi-head: {multi_head}")

    ds = GaoDataset(
        data_root=str(data_root / "rendered_2max"),
        face_root=str(data_root / "rendered_face"),
        gt_xlsx=str(data_root / "gt" / "toMax_gt.xlsx"),
        race=race,
        output_dir=None,
        write_info_json=False,
    )

    data_list = ds.get_data_list("train")
    val_list = ds.get_data_list("valid")

    # ── Merge multi-attribute scores into data_list ─────────
    if multi_head and len(enabled_attrs) > 1:
        import pandas as pd
        gt_dir = data_root / "gt"
        # Build lookup: {(folder, orig_name): {attr: score}}
        for attr_name in enabled_attrs:
            if attr_name == "01Preference":
                continue  # already loaded as "score"
            attr_gt = gt_dir / f"toMax_gt_{attr_name}.xlsx"
            if not attr_gt.exists():
                print(f"  [WARN] {attr_name} GT not found, skipping")
                continue
            xl = pd.ExcelFile(attr_gt)
            attr_scores = {}
            for sheet in xl.sheet_names:
                df = pd.read_excel(attr_gt, sheet_name=sheet)
                if df.empty: continue
                col0 = df.columns[0]
                score_col = None
                for c in df.columns:
                    if "preference" in str(c).lower(): score_col = c; break
                if score_col is None and len(df.columns) >= 2:
                    score_col = df.columns[1]
                if score_col is None: continue
                for _, row in df.iterrows():
                    orig = str(row[col0]).strip()
                    if not orig or orig.lower() == "nan": continue
                    if pd.isna(row[score_col]): continue
                    attr_scores[(sheet, orig)] = _normalize_score(float(row[score_col]))
            # Attach to data_list
            for sample in data_list:
                key = (sample.get("folder", ""), sample.get("adjusted", "").rsplit("/", 1)[-1].replace(".png", ""))
                # Try to match by path
                adjusted_path = Path(sample["adjusted"])
                folder = adjusted_path.parent.name if adjusted_path.parent.name.endswith(("i","r")) else ""
                orig_name = adjusted_path.stem
                sample.setdefault("attr_scores", {})
                sample["attr_scores"][attr_name] = attr_scores.get((folder, orig_name), None)
        print(f"[{race}] Merged {len(enabled_attrs)} attribute scores")

        # Build val data similarly (simple: just reuse same attr_scores if paths match)
        for sample in val_list:
            if "attr_scores" not in sample:
                # Try matching by path
                adj_path = Path(sample["adjusted"])
                folder = adj_path.parent.name
                orig_name = adj_path.stem
                sample["attr_scores"] = {}
                for train_s in data_list:
                    tp = Path(train_s["adjusted"])
                    if tp.parent.name == folder and tp.stem == orig_name:
                        sample["attr_scores"] = train_s.get("attr_scores", {}).copy()
                        break

    if len(data_list) == 0:
        print(f"[ERROR] No training samples for {race}")
        return

    print(f"[{race}] Train samples: {len(data_list)}")
    if val_list:
        print(f"[{race}] Valid samples: {len(val_list)}")

    # ── Custom dataset for multi-attr ───────────────────────
    from dataset import EnhancementDataset
    if multi_head and len(enabled_attrs) > 1:
        class MultiAttrDataset(EnhancementDataset):
            def __getitem__(self, idx):
                item = self.data[idx]
                raw = self.transform(PIL_Image.open(item['raw']).convert('RGB'))
                adj = self.transform(PIL_Image.open(item['adjusted']).convert('RGB'))
                score = torch.tensor(float(item['score']), dtype=torch.float32)
                label = torch.tensor(float(item.get('label', 5)), dtype=torch.float32)
                # Build attr scores tensor: (N_attrs,) with NaN for missing
                attr_tensor = torch.full((len(enabled_attrs),), float('nan'))
                attr_tensor[0] = score  # 01Preference = idx 0
                for i, aname in enumerate(enabled_attrs):
                    if i == 0: continue
                    v = item.get("attr_scores", {}).get(aname)
                    if v is not None:
                        attr_tensor[i] = float(v)
                return {'raw': raw, 'adjusted': adj, 'score': score, 'label': label, 'attr_scores': attr_tensor}
        import PIL.Image as PIL_Image
        train_set = MultiAttrDataset(data_list, img_size=args.img_size)
    else:
        train_set = EnhancementDataset(data_list, img_size=args.img_size)
    train_loader = DataLoader(train_set, batch_size=args.batch_size,
                              shuffle=True, num_workers=args.num_workers, drop_last=True)

    # ── Model ─────────────────────────────────────────────────
    model = QualityGuidedEnhancer(
        n_base_1d=args.n_base_1d, n_base_3d=args.n_base_3d, lut_dim=args.lut_dim,
        use_skin_label=args.use_skin_label, backbone_size=args.backbone_size,
    ).to(device)
    optimizer = optim.Adam(model.parameters(), lr=args.lr)

    # ── Output dirs ───────────────────────────────────────────
    output_dir = Path(args.output_root) / f"gao2024_{race}"
    output_dir.mkdir(parents=True, exist_ok=True)
    best_pearson = -1.0
    best_val_loss = float("inf")
    history = {"epoch": [], "train_loss": [], "train_pearson_r": [], "val_loss": [], "val_pearson_r": []}
    print(f"[{race}] Starting training: {args.epochs} epochs, lr={args.lr}, batch={args.batch_size}")
    print(f"[{race}] Output: {output_dir}")

    for epoch in range(args.epochs):
        model.train()
        epoch_loss = 0.0
        all_pred_train = []
        all_tgt_train = []

        pbar = tqdm(train_loader, desc=f"[{race}] Epoch {epoch+1}/{args.epochs}", leave=False)
        for batch_idx, batch in enumerate(pbar):
            raw = batch["raw"].to(device)
            adj = batch["adjusted"].to(device)
            label = batch["label"].to(device) if args.use_skin_label else None

            if multi_head and "attr_scores" in batch:
                total_loss = 0.0
                attr_scores = batch["attr_scores"].to(device)
                for ai in range(len(enabled_attrs)):
                    scores_i = attr_scores[:, ai]
                    mask = ~torch.isnan(scores_i)
                    if mask.sum() == 0: continue
                    pred_i = model(raw[mask], scores_i[mask], label[mask] if label is not None else None)
                    loss_i, ld = compute_loss(pred_i, adj[mask], model.base_1d, model.base_3d)
                    total_loss = total_loss + loss_i

                if isinstance(total_loss, float): continue
                optimizer.zero_grad()
                total_loss.backward()
                optimizer.step()
                epoch_loss += total_loss.item()
                # Rolling Pearson (single-attr proxy: use preference score output)
                display_loss = total_loss.item()
            else:
                score = batch["score"].to(device)
                pred = model(raw, score, label)
                loss, loss_dict = compute_loss(pred, adj, model.base_1d, model.base_3d)
                optimizer.zero_grad()
                loss.backward()
                optimizer.step()
                epoch_loss += loss.item()
                display_loss = loss.item()
                # Accumulate for rolling Pearson
                pred_mean = pred.mean(dim=[1,2,3]).detach().cpu().numpy()
                adj_mean = adj.mean(dim=[1,2,3]).detach().cpu().numpy()
                all_pred_train.extend(pred_mean)
                all_tgt_train.extend(adj_mean)

            # ── Rolling Pearson r (print to stdout, bypass tqdm) ──
            if len(all_pred_train) >= 33 and len(all_pred_train) % 33 == 0:
                win_pred = np.array(all_pred_train[-33:])
                win_tgt  = np.array(all_tgt_train[-33:])
                rr = compute_pearson(win_pred, win_tgt)
                print(f"  [r33@{len(all_pred_train)}] loss={display_loss:.4f} pearson_r={rr:.4f}", flush=True)
            pbar.set_postfix(loss=f"{display_loss:.4f}")

        avg_loss = epoch_loss / max(len(train_loader), 1)
        train_r = compute_pearson(all_pred_train, all_tgt_train)

        # ── Validate (per-batch to avoid OOM) ──────────────────
        val_loss = None
        val_r = None
        if val_list:
            model.eval()
            val_loss_sum = 0.0
            all_pred_val = []
            all_tgt_val = []
            n_val_batches = 0

            for i in range(0, len(val_list), args.batch_size):
                batch_indices = range(i, min(i + args.batch_size, len(val_list)))
                batch_data = [val_list[j] for j in batch_indices]
                batch_set = EnhancementDataset(batch_data, img_size=args.img_size)
                batch_loader = DataLoader(batch_set, batch_size=len(batch_data), shuffle=False)

                for b in batch_loader:
                    raw_v = b["raw"].to(device)
                    adj_v = b["adjusted"].to(device)
                    score_v = b["score"].to(device)
                    label_v = b["label"].to(device) if args.use_skin_label else None

                    with torch.no_grad():
                        pred_v = model(raw_v, score_v, label_v if args.use_skin_label else None)
                        loss_v, _ = compute_loss(pred_v, adj_v, model.base_1d, model.base_3d)

                    val_loss_sum += loss_v.item()
                    n_val_batches += 1

                    pred_mean_v = pred_v.mean(dim=[1, 2, 3]).cpu().numpy()
                    adj_mean_v = adj_v.mean(dim=[1, 2, 3]).cpu().numpy()
                    all_pred_val.extend(pred_mean_v)
                    all_tgt_val.extend(adj_mean_v)

            val_loss = val_loss_sum / max(n_val_batches, 1)
            val_r = compute_pearson(all_pred_val, all_tgt_val)
        else:
            val_loss = avg_loss
            val_r = train_r

        # ── Print ──────────────────────────────────────────────
        log_msg = (f"[{race}] Epoch {epoch+1:3d}/{args.epochs} | "
                   f"train_loss={avg_loss:.4f} train_r={train_r:.4f} | "
                   f"val_loss={val_loss:.4f} val_r={val_r:.4f}")
        print(log_msg)

        # ── History ────────────────────────────────────────────
        history["epoch"].append(epoch + 1)
        history["train_loss"].append(avg_loss)
        history["train_pearson_r"].append(train_r)
        history["val_loss"].append(val_loss)
        history["val_pearson_r"].append(val_r)

        # ── Save best (by val_r, with tie-break on val_loss) ──
        is_best = False
        if val_r is not None and (val_r > best_pearson or (val_r == best_pearson and val_loss < best_val_loss)):
            best_pearson = val_r
            best_val_loss = val_loss
            is_best = True

            ckpt_path = _best_model_path(str(output_dir))
            metrics_path = _metrics_path(str(output_dir))
            torch.save({
                "epoch": epoch,
                "model_state_dict": model.state_dict(),
                "optimizer_state_dict": optimizer.state_dict(),
                "metrics": {"val_loss": val_loss, "val_pearson_r": val_r, "train_loss": avg_loss, "train_pearson_r": train_r},
            }, ckpt_path)
            with open(metrics_path, "w") as f:
                json.dump({"epoch": epoch + 1, "val_loss": val_loss, "val_pearson_r": val_r}, f, indent=2)
            print(f"  ★ Best model saved: r={val_r:.4f} loss={val_loss:.4f}")

        # ── Periodic checkpoint ────────────────────────────────
        if (epoch + 1) % args.save_freq == 0:
            ckpt_path = str(output_dir / f"epoch_{epoch+1}.pth")
            torch.save({
                "epoch": epoch,
                "model_state_dict": model.state_dict(),
                "optimizer_state_dict": optimizer.state_dict(),
                "metrics": {"val_loss": val_loss, "val_pearson_r": val_r},
            }, ckpt_path)
            print(f"  Checkpoint: {ckpt_path}")

    # ── Save history ──────────────────────────────────────────
    hist_path = output_dir / "training_history.json"
    with open(hist_path, "w") as f:
        json.dump(history, f, indent=2)

    print(f"\n[{race}] Training complete. Best val_r={best_pearson:.4f}")
    print(f"[{race}] Results saved to {output_dir}")

    return best_pearson


def main():
    parser = argparse.ArgumentParser(description="Train Gao2024 on deepskin (per-race)")
    parser.add_argument("--data-root", type=str, default="/root/autodl-tmp",
                        help="Root dir containing Quality_guided_STE/gao_data_{RACE}/")
    parser.add_argument("--output-root", type=str, default=None,
                        help="Output root (default: data-root/Quality_guided_STE/output)")
    parser.add_argument("--race", type=str, default=None, choices=["CA", "AS", "SA", "AF"],
                        help="Single race to train (omit for all)")
    parser.add_argument("--img-size", type=int, default=256)
    parser.add_argument("--backbone-size", type=int, default=256)
    parser.add_argument("--batch-size", type=int, default=1)
    parser.add_argument("--epochs", type=int, default=400)
    parser.add_argument("--lr", type=float, default=1e-4)
    parser.add_argument("--n-base-1d", type=int, default=3)
    parser.add_argument("--n-base-3d", type=int, default=3)
    parser.add_argument("--lut-dim", type=int, default=33)
    parser.add_argument("--use-skin-label", action="store_true", default=False,
                        help="Use skin tone label (default off, no clustering yet)")
    parser.add_argument("--save-freq", type=int, default=50)
    parser.add_argument("--num-workers", type=int, default=4)
    parser.add_argument("--multi-head", action="store_true", default=False,
                        help="Enable multi-attribute training (iterate over --attributes)")
    parser.add_argument("--attributes", type=str, default="all",
                        help="Comma-separated attribute serials (e.g. 01Preference,09Fair). Default: all 10")
    args = parser.parse_args()

    if args.output_root is None:
        args.output_root = str(Path(args.data_root) / "Quality_guided_STE" / "output")

    races = [args.race] if args.race else ["CA", "AS", "SA", "AF"]
    results = {}

    for race in races:
        print(f"\n{'='*60}")
        print(f"Training race: {race}")
        print(f"{'='*60}")
        best_r = train_race(args, race)
        results[race] = best_r

    print(f"\n{'='*60}")
    print("All races complete:")
    for race, r in results.items():
        print(f"  {race}: best_val_r={r:.4f}")


if __name__ == "__main__":
    main()
