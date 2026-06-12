"""test_on_deepskin.py - Per-scene evaluation + val set sanity check
用法: python test_on_deepskin.py [--legacy] [--models DBCNN MANIQA] [--races SA CA]
"""
import os, json, torch, yaml, re, argparse
import numpy as np
import pandas as pd
from scipy import stats
from collections import defaultdict
from tqdm import tqdm
from pyiqa.data import build_dataloader, build_dataset
from pyiqa.archs import build_network

EXPERIMENTS = "/root/autodl-tmp/iqa_pytorch_train/experiments"
RACES = ["SA", "CA", "AS", "AF"]
MODELS = ["DBCNN", "MANIQA", "HyperIQA"]

parser = argparse.ArgumentParser()
parser.add_argument('--legacy', action='store_true', help='Use fc:true DBCNN')
parser.add_argument('--models', nargs='+', default=None)
parser.add_argument('--races', nargs='+', default=None)
parser.add_argument('--val', action='store_true', help='Run on val set (sanity check)')
parser.add_argument('--debug', action='store_true', help='Print per-image pred/gt values')
args = parser.parse_args()

DB_LEGACY = args.legacy
if args.models: MODELS = args.models
if args.races: RACES = args.races
PHASES = ["test"]
DEBUG = args.debug
if args.val:
    PHASES = ["val", "test"]

print(f"[INFO] Models: {MODELS}, Races: {RACES}, Phases: {PHASES}")

def parse_scene_subject(img_path_str):
    """Parse absolute or relative path -> subject, scene
    e.g. /root/autodl-tmp/rendered_2max/f07i/f07ih3k_01.jpg -> f07i, h3k
         /root/autodl-tmp/rendered_2max/m08r/m08rrs05_01.jpg -> m08r, rs05
    """
    # Take last two path components
    parts = img_path_str.replace(".jpg", "").split("/")
    if len(parts) >= 2:
        subj = parts[-2]   # e.g. "m08i"
        fname = parts[-1]  # e.g. "m08ih3k_01"
        # Extract scene: strip subject prefix
        if subj.endswith("i"):
            scene = fname[len(subj):].split("_")[0]  # h3k
        else:
            m = re.match(r".*r(rs\d+)_", fname)
            scene = m.group(1) if m else fname.split("_")[0]
        return subj, scene
    return img_path_str[:4], "unknown"


def _safe_scalar(x):
    """Extract scalar from scipy stats result, handling ndarray/nan"""
    return float(np.asarray(x).flat[0])

def evaluate_model(net, dataloader, phase_name):
    """Run inference, group by scene, return per-scene PLCC table + overall metrics."""
    preds_all, gts_all = [], []
    scene_data = defaultdict(lambda: defaultdict(list))  # scene_data[scene][subject] = list of (pred,gt)
    detail_preds = []

    pbar = tqdm(dataloader, desc=phase_name)
    scene_batch_preds, scene_batch_gts = [], []
    last_scene = None
    scene_count = 0
    for data in pbar:
        img = data['img'].cuda()
        with torch.no_grad():
            pred = net(img)
        pred_val = pred.squeeze(1).cpu().tolist()
        gt_val = data['mos_label'].squeeze(1).cpu().tolist()

        for i in range(len(pred_val)):
            img_path = data['img_path'][i]
            subj, scene = parse_scene_subject(img_path)
            scene_data[scene][subj].append((pred_val[i], gt_val[i]))
            preds_all.append(pred_val[i])
            gts_all.append(gt_val[i])
            detail_preds.append({
                "name": img_path, "pred": pred_val[i], "gt": gt_val[i],
                "subject": subj, "scene": scene
            })
            if DEBUG:
                pbar.write(f"    {img_path.split('/')[-1]:30s} pred={float(np.asarray(pred_val[i]).flat[0]):.4f} gt={float(np.asarray(gt_val[i]).flat[0]):.4f}")

            # Track scene-level metrics in progress bar
            if scene != last_scene and last_scene is not None:
                if len(scene_batch_preds) > 1 and len(set(scene_batch_gts)) > 1:
                    sc_plcc = _safe_scalar(stats.pearsonr(scene_batch_preds, scene_batch_gts)[0])
                    pbar.set_postfix_str(f"scene#{scene_count} {last_scene}/{subj_prev} PLCC={float(np.asarray(sc_plcc).flat[0]):.3f}")
                scene_batch_preds, scene_batch_gts = [], []
                scene_count += 1
            scene_batch_preds.append(pred_val[i])
            scene_batch_gts.append(gt_val[i])
            last_scene = scene
            subj_prev = subj

    # Per-scene metrics
    scene_results = []
    for scene in sorted(scene_data.keys()):
        for subj in sorted(scene_data[scene].keys()):
            pairs = scene_data[scene][subj]
            preds = [p[0] for p in pairs]
            gts = [p[1] for p in pairs]
            n = len(pairs)
            if n > 1 and len(set(gts)) > 1:
                sc_srcc = _safe_scalar(stats.spearmanr(preds, gts)[0])
                sc_plcc = _safe_scalar(stats.pearsonr(preds, gts)[0])
            else:
                sc_srcc, sc_plcc = np.nan, np.nan
            scene_results.append({"scene": scene, "subject": subj, "plcc": round(sc_plcc, 4), "srcc": round(sc_srcc, 4), "n": n})

    scene_df = pd.DataFrame(scene_results)
    if len(scene_df) > 0:
        # Pivot with merged subjects: single PLCC column
        pivot_merged = scene_df.groupby("scene")["plcc"].mean().to_frame("PLCC")
        print(f"  [{phase_name}] Per-scene PLCC:")
        print(pivot_merged.to_string())

    # Compute average per-scene metrics
    avg_srcc = np.nanmean([r["srcc"] for r in scene_results]) if scene_results else 0
    avg_plcc = np.nanmean([r["plcc"] for r in scene_results]) if scene_results else 0
    print(f"  [{phase_name}] Overall: SRCC={avg_srcc:.4f}, PLCC={avg_plcc:.4f} (mean of {len(scene_results)} scenes, {len(preds_all)} images)")
    # Overall = mean of per-scene correlations
    avg_srcc = np.nanmean([r["srcc"] for r in scene_results]) if scene_results else 0
    avg_plcc = np.nanmean([r["plcc"] for r in scene_results]) if scene_results else 0
    print(f"  [{phase_name}] Overall: SRCC={avg_srcc:.4f}, PLCC={avg_plcc:.4f} (mean of {len(scene_results)} scenes, {len(preds_all)} images)")
    return float(avg_srcc), float(avg_plcc), len(preds_all), pivot_merged, detail_preds


def main():
    results_all = {}
    xlsx_path = "results/test_predictions.xlsx"
    # Remove old file on first run so we always start fresh per script execution
    if os.path.exists(xlsx_path):
        os.remove(xlsx_path)  # collect all sheets, write at end

    for model_name in MODELS:
        results_all[model_name] = {}
        for phase in PHASES:
            for race in RACES:
                exp_name = f"{model_name}_{race}_deepskin"
                exp_dir = os.path.join(EXPERIMENTS, exp_name)

                # YAML
                yml_path = f"options/train/deepskin/{model_name}/train_{model_name}_{race}.yml"
                with open(yml_path) as f:
                    opt = yaml.safe_load(f)

                # Checkpoint
                ckpt_path = os.path.join(exp_dir, "models", "net_best.pth")
                if not os.path.exists(ckpt_path):
                    ckpt_path = os.path.join(exp_dir, "models", "net_latest.pth")
                if not os.path.exists(ckpt_path):
                    print(f"[SKIP] {model_name}/{race}/{phase}: no checkpoint")
                    continue

                # Build model
                net = build_network(opt['network'])
                try:
                    state = torch.load(ckpt_path, map_location='cpu', weights_only=True)
                except Exception as e:
                    print(f'[SKIP] {model_name}/{race}/{phase}: corrupted checkpoint ({e})')
                    continue
                if 'params' in state:
                    net.load_state_dict(state['params'], strict=False)
                else:
                    net.load_state_dict(state, strict=False)
                net = net.cuda()
                net.eval()

                # Build dataloader
                ds_opt = opt['datasets']['train'].copy()
                ds_opt['phase'] = phase
                ds_opt['split_index'] = 'split_name'
                ds_opt.pop('augment', None)
                ds_opt.pop('batch_size_per_gpu', None)
                ds_opt.pop('num_worker_per_gpu', None)

                dataset = build_dataset(ds_opt)
                dataloader = build_dataloader(dataset, ds_opt, num_gpu=1)

                print(f"\n{'='*50}")
                print(f"  {model_name}/{race}/{phase}")
                print(f"{'='*50}")

                srcc, plcc, n, pivot, details = evaluate_model(net, dataloader, f"{model_name}/{race}/{phase}")

                key = f"{phase}"
                results_all[model_name][f"{race}_{phase}"] = {
                    "srcc": srcc, "plcc": plcc, "n_test": n
                }

                # Write sheet immediately (append to existing xlsx)
                sheet_name = f"{model_name}_{race}_{phase}"[:31]
                if pivot is not None and len(pivot) > 0:
                    mode = "w" if not os.path.exists(xlsx_path) else "a"
                    try:
                        kwargs = {"engine": "openpyxl", "mode": mode}
                        if mode == "a":
                            kwargs["if_sheet_exists"] = "replace"
                        with pd.ExcelWriter(xlsx_path, **kwargs) as writer:
                            pivot.to_excel(writer, sheet_name=sheet_name)
                        print(f"  -> Sheet '{sheet_name}' written")
                    except Exception as e:
                        print(f"  -> Sheet '{sheet_name}' FAILED: {e}")

    # Save summary JSON
    os.makedirs("results", exist_ok=True)
    with open("results/test_results.json", "w") as f:
        json.dump(results_all, f, indent=2)

    print(f"\nSaved: {xlsx_path}, results/test_results.json")

if __name__ == "__main__":
    main()
