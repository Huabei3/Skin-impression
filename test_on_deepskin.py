"""在 deepskin test/val set 上评估训练好的模型

用法:
  python test_on_deepskin.py --val --models TOPIQ_NR_Face --races SA
  python test_on_deepskin.py --models DBCNN MANIQA
  python test_on_deepskin.py  # 全部模型全部 race

输出:
  results/test_{MODEL}_{RACE}.xlsx  (或 val_{MODEL}_{RACE}.xlsx)
  每个 xlsx 包含 sheets: Params | Overall | PerGroup | RawData
"""
import os, json, torch, yaml, argparse, re
import numpy as np
import pandas as pd
from scipy import stats
from tqdm import tqdm
from pyiqa.data import build_dataloader, build_dataset
from pyiqa.archs import build_network

EXPERIMENTS = "/root/autodl-tmp/iqa_pytorch_train/experiments"
ALL_RACES = ["SA", "CA", "AS", "AF"]
ALL_MODELS = ["DBCNN", "MANIQA", "HyperIQA", "NIMA", "TReS", "CLIPIQA", "TOPIQ_NR_Face"]
ZERO_SHOT_MODELS = {"CLIPIQA"}


def extract_scene(img_path):
    """Extract scene name: f08r/f08rrs02_01.jpg -> f08rrs02, also handles _face suffix"""
    fname = os.path.basename(img_path)
    # Strip _face suffix first, then extract scene
    fname = fname.replace("_face.jpg", ".jpg")
    m = re.match(r"(.+?)_\d+\.jpg$", fname)
    return m.group(1) if m else fname


def extract_model_iOr(img_path):
    """Extract subject+iOr: f08r/f08rrs02_01.jpg -> (f08, r)"""
    parts = img_path.replace("\\", "/").split("/")
    folder = parts[-2]  # "f08r"
    model = folder[:3]   # "f08"
    ior = folder[3]      # "r"
    return model, ior


def build_per_group_df(preds, gts, img_paths):
    """Build PerGroup DataFrame: Model/iOr/Scene/n_samples/Pearson_r/MAE

    Each scene = 33 variants (e.g. m02ih3k_01..33), Pearson r computed per-scene.
    """
    rows = []
    scene_data = {}
    for p, g, path in zip(preds, gts, img_paths):
        scene = extract_scene(path)
        if scene not in scene_data:
            scene_data[scene] = {"preds": [], "gts": [], "path": path}
        scene_data[scene]["preds"].append(p)
        scene_data[scene]["gts"].append(g)

    for scene, data in sorted(scene_data.items()):
        p_arr = np.array(data["preds"])
        g_arr = np.array(data["gts"])
        model, ior = extract_model_iOr(data["path"])
        r, _ = stats.pearsonr(p_arr, g_arr) if len(p_arr) >= 2 else (0, None)
        mae = np.mean(np.abs(p_arr - g_arr))
        rows.append({
            "Model": model, "iOr": ior, "Scene": scene,
            "n_samples": len(p_arr), "Pearson_r": round(float(r), 6),
            "MAE": round(float(mae), 6),
        })
    return pd.DataFrame(rows)


def build_overall_df(per_group_df, preds, gts):
    """Build Overall DataFrame.

    PLCC = mean of per-scene Pearson_r (not overall Pearson on all samples).
    SRCC = overall Spearman on all samples.
    """
    p_arr = np.array(preds)
    g_arr = np.array(gts)
    s, _ = stats.spearmanr(p_arr, g_arr)
    mae = np.mean(np.abs(p_arr - g_arr))
    rmse = np.sqrt(np.mean((p_arr - g_arr) ** 2))
    mean_plcc = per_group_df["Pearson_r"].mean()
    return pd.DataFrame([
        ("srcc", round(float(s), 6)),
        ("plcc", round(float(mean_plcc), 6)),
        ("mae", round(float(mae), 6)),
        ("rmse", round(float(rmse), 6)),
        ("n_samples", len(preds)),
    ], columns=["Metric", "Value"])





def build_raw_data_df(preds, gts, img_paths):
    """Build RawData DataFrame: img_path/pred/gt/error"""
    rows = []
    for p, g, path in zip(preds, gts, img_paths):
        rows.append({"img_path": path, "pred": p, "gt": g, "error": abs(p - g)})
    return pd.DataFrame(rows)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--val", action="store_true")
    parser.add_argument("--models", nargs="*", default=None)
    parser.add_argument("--races", nargs="*", default=None)
    parser.add_argument("--batch-size", type=int, default=1)
    args = parser.parse_args()

    models = args.models or ALL_MODELS
    races = args.races or ALL_RACES
    phase = "val" if args.val else "test"

    os.makedirs("results", exist_ok=True)
    summary_rows = []

    for model_name in models:
        for race in races:
            exp_name = f"{model_name}_{race}_deepskin"
            exp_dir = os.path.join(EXPERIMENTS, exp_name)
            yml_path = f"options/train/deepskin/{model_name}/train_{model_name}_{race}.yml"

            if not os.path.exists(yml_path):
                print(f"[SKIP] {model_name}/{race}: no YAML config")
                continue

            with open(yml_path) as f:
                opt = yaml.safe_load(f)

            ckpt_path = None
            if model_name in ZERO_SHOT_MODELS:
                import pyiqa
                net = pyiqa.create_metric(model_name.lower(), device='cuda')
                net.eval()
            else:
                ckpt_path = os.path.join(exp_dir, "models", "net_best.pth")
                if not os.path.exists(ckpt_path):
                    ckpt_path = os.path.join(exp_dir, "models", "net_latest.pth")
                if not os.path.exists(ckpt_path):
                    print(f"[SKIP] {model_name}/{race}: no checkpoint found")
                    continue
                net = build_network(opt['network'])
                state = torch.load(ckpt_path, map_location='cpu', weights_only=True)
                if 'params' in state:
                    net.load_state_dict(state['params'], strict=False)
                elif 'model_state_dict' in state:
                    net.load_state_dict(state['model_state_dict'], strict=False)
                else:
                    net.load_state_dict(state, strict=False)
                net = net.cuda()
                net.eval()

            # Build dataloader
            test_opt = opt['datasets']['train'].copy()
            test_opt['phase'] = phase
            test_opt['split_index'] = 'split_name'
            test_opt.pop('augment', None)
            test_opt['batch_size_per_gpu'] = args.batch_size

            test_set = build_dataset(test_opt)
            test_loader = build_dataloader(test_set, test_opt)

            # Run inference
            preds, gts, img_paths = [], [], []
            for data in tqdm(test_loader, desc=f"{model_name}/{race}"):
                img = data['img'].cuda()
                with torch.no_grad():
                    pred = net(img)
                preds.extend(pred.squeeze(1).cpu().tolist())
                gts.extend(data['mos_label'].squeeze(1).cpu().tolist())
                # img_path from dataloader
                if 'img_path' in data:
                    img_paths.extend(data['img_path'])

            per_group_df = build_per_group_df(preds, gts, img_paths)
            overall_df = build_overall_df(per_group_df, preds, gts)

            srcc_val = float(overall_df[overall_df["Metric"] == "srcc"]["Value"].iloc[0])
            plcc_val = float(overall_df[overall_df["Metric"] == "plcc"]["Value"].iloc[0])
            print(f"  {race}: SRCC={srcc_val:.4f}, PLCC(mean per-scene)={plcc_val:.4f} (n={len(preds)})")

            summary_rows.append({
                "Model": model_name, "Race": race,
                "SRCC": round(srcc_val, 4), "PLCC": round(plcc_val, 4),
                "N": len(preds), "Phase": phase,
            })

            # Save xlsx
            params_df = pd.DataFrame([
                ("model", model_name), ("race", race), ("phase", phase),
                ("ckpt", ckpt_path or "zero-shot"),
                ("data_root", opt['datasets']['train'].get('dataroot_target', '')),
            ], columns=["Parameter", "Value"])

            out_path = f"results/{phase}_{model_name}_{race}.xlsx"
            with pd.ExcelWriter(out_path, engine='openpyxl') as writer:
                params_df.to_excel(writer, sheet_name='Params', index=False)
                overall_df.to_excel(writer, sheet_name='Overall', index=False)
                per_group_df.to_excel(writer, sheet_name='PerGroup', index=False)
                build_raw_data_df(preds, gts, img_paths).to_excel(writer, sheet_name='RawData', index=False)
            print(f"  -> {out_path}")

    # Summary table
    if summary_rows:
        print("\n" + "=" * 60)
        print(f"  {phase.upper()} SUMMARY")
        print("=" * 60)
        print(f"{'Model':<16} {'Race':<6} {'SRCC':>8} {'PLCC':>8} {'N':>6}")
        print("-" * 48)
        for r in summary_rows:
            print(f"{r['Model']:<16} {r['Race']:<6} {r['SRCC']:>8.4f} {r['PLCC']:>8.4f} {r['N']:>6}")

        summary_df = pd.DataFrame(summary_rows)
        summary_path = f"results/{phase}_summary.xlsx"
        summary_df.to_excel(summary_path, index=False)
        print(f"\nSummary saved to {summary_path}")


if __name__ == "__main__":
    main()
