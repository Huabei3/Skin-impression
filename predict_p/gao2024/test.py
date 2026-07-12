"""
Gao 2024 inference & evaluation on deepskin test set.
Outputs enhanced images + per-sample metrics + Pearson r table.
"""
import os
import sys
import json
import argparse
from pathlib import Path

import torch
import torchvision
import numpy as np
from scipy.stats import pearsonr
from tqdm import tqdm
from PIL import Image
from torchvision import transforms


def evaluate_race(args, race: str):
    # Import model
    gao_path = Path("/root/autodl-tmp/Quality_guided_STE")
    if str(gao_path) not in sys.path:
        sys.path.insert(0, str(gao_path))
    from model import QualityGuidedEnhancer

    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

    # ── Model ─────────────────────────────────────────────────
    model = QualityGuidedEnhancer(
        n_base_1d=args.n_base_1d, n_base_3d=args.n_base_3d,
        lut_dim=args.lut_dim, use_skin_label=args.use_skin_label,
        backbone_size=args.backbone_size,
    ).to(device)

    ckpt_path = Path(args.output_root) / f"gao2024_{race}" / "best_model.pth"
    if not ckpt_path.exists():
        print(f"[ERROR] Checkpoint not found: {ckpt_path}")
        return None

    ckpt = torch.load(ckpt_path, map_location=device, weights_only=False)
    model.load_state_dict(ckpt["model_state_dict"])
    model.eval()
    print(f"[{race}] Loaded checkpoint: epoch={ckpt.get('epoch', '?')+1}, "
          f"val_r={ckpt.get('metrics', {}).get('val_pearson_r', '?')}")

    # ── Test data ─────────────────────────────────────────────
    import pandas as pd
    test_xlsx = Path(args.output_root) / "data_check" / f"split_result_{race}.xlsx"
    if not test_xlsx.exists():
        # Read directly from data dir
        test_dir = Path(args.data_root) / "Quality_guided_STE" / f"gao_data_{race}" / "test"
        if not test_dir.exists():
            print(f"[ERROR] Test data not found: {test_dir}")
            return None

        from utils import build_data_list
        test_list = build_data_list(str(test_dir))
    else:
        # Use split_result xlsx to find test images
        df = pd.read_excel(test_xlsx)
        df = df[df["split"] == "test"]
        test_list = []
        rendered_root = Path(args.data_root) / "rendered_2max"
        for _, row in df.iterrows():
            folder = row["folder"]
            orig = row.get("original_name", None)
            if orig is None:
                # Reconstruct from folder + variant
                orig = f"{folder}_{row['variant']}" if "variant" in row else None
            if orig is None:
                continue
            img_path = rendered_root / folder / f"{orig}.jpg"
            if img_path.exists():
                test_list.append({
                    "raw": str(img_path),
                    "adjusted": str(img_path),  # test mode: same image
                    "score": float(row["score_norm"]),
                    "label": float(row.get("label", 5)),
                })

    print(f"[{race}] Test samples: {len(test_list)}")

    # ── Run inference ─────────────────────────────────────────
    transform = transforms.Compose([
        transforms.Resize((args.img_size, args.img_size)),
        transforms.ToTensor(),
    ])

    results = []
    all_pred_means = []
    all_score_inputs = []

    out_img_dir = Path(args.output_root) / f"gao2024_{race}" / "test_outputs"
    out_img_dir.mkdir(parents=True, exist_ok=True)

    for i, sample in enumerate(tqdm(test_list, desc=f"[{race}] Test")):
        img = Image.open(sample["raw"]).convert("RGB")
        img_t = transform(img).unsqueeze(0).to(device)
        score = torch.tensor([[sample["score"]]], dtype=torch.float32, device=device)
        label = torch.tensor([[sample["label"]]], dtype=torch.float32, device=device) if args.use_skin_label else None

        with torch.no_grad():
            out = model(img_t, score, label)

        # Save output image
        out_name = f"enhanced_{i:04d}.png"
        torchvision.utils.save_image(out.squeeze(0).cpu(), str(out_img_dir / out_name))

        pred_mean = out.mean().item()
        all_pred_means.append(pred_mean)
        all_score_inputs.append(sample["score"])

        results.append({
            "index": i,
            "folder": sample.get("folder", ""),
            "orig_name": Path(sample["raw"]).stem,
            "score_input": sample["score"],
            "pred_mean": pred_mean,
            "output_path": str(out_img_dir / out_name),
        })

    # ── Compute Pearson r (score vs predicted output) ─────────
    pred_arr = np.array(all_pred_means)
    score_arr = np.array(all_score_inputs)
    r, _ = pearsonr(pred_arr, score_arr) if len(pred_arr) >= 2 else (0.0, 1.0)
    print(f"[{race}] Test Pearson (score→output): r={r:.4f}")

    # ── Save results ──────────────────────────────────────────
    results_path = Path(args.output_root) / f"gao2024_{race}" / "test_results.json"
    with open(results_path, "w") as f:
        json.dump({"pearson_r": float(r), "n_samples": len(results), "results": results}, f, indent=2)
    print(f"[{race}] Results saved to {results_path}")

    return {"race": race, "pearson_r": r, "n_samples": len(results)}


def main():
    parser = argparse.ArgumentParser(description="Test Gao2024 on deepskin")
    parser.add_argument("--data-root", type=str, default="/root/autodl-tmp")
    parser.add_argument("--output-root", type=str, default=None)
    parser.add_argument("--race", type=str, default=None, choices=["CA", "AS", "SA", "AF"])
    parser.add_argument("--img-size", type=int, default=256)
    parser.add_argument("--backbone-size", type=int, default=256)
    parser.add_argument("--n-base-1d", type=int, default=3)
    parser.add_argument("--n-base-3d", type=int, default=3)
    parser.add_argument("--lut-dim", type=int, default=33)
    parser.add_argument("--use-skin-label", action="store_true", default=False)
    args = parser.parse_args()

    if args.output_root is None:
        args.output_root = str(Path(args.data_root) / "Quality_guided_STE" / "output")

    races = [args.race] if args.race else ["CA", "AS", "SA", "AF"]
    all_results = {}
    for race in races:
        res = evaluate_race(args, race)
        if res:
            all_results[race] = res

    print(f"\n{'='*60}")
    print("Test Summary:")
    for race, res in all_results.items():
        print(f"  {race}: Pearson r={res['pearson_r']:.4f}, n={res['n_samples']}")


if __name__ == "__main__":
    main()
