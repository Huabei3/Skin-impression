"""在 deepskin test set 上评估训练好的模型"""
import os, json, torch, yaml
import numpy as np
from scipy import stats
from tqdm import tqdm
from pyiqa.data import build_dataloader, build_dataset
from pyiqa.archs import build_network

EXPERIMENTS = "/root/autodl-tmp/iqa_pytorch_train/experiments"
RACES = ["SA", "CA", "AS", "AF"]
MODELS = ["DBCNN", "MANIQA", "HyperIQA"]

results_all = {}

for model_name in MODELS:
    results_all[model_name] = {}
    for race in RACES:
        exp_name = f"{model_name}_{race}_deepskin"
        exp_dir = os.path.join(EXPERIMENTS, exp_name)

        # Read YAML
        yml_path = f"options/train/deepskin/{model_name}/train_{model_name}_{race}.yml"
        with open(yml_path) as f:
            opt = yaml.safe_load(f)

        # Find checkpoint
        ckpt_path = os.path.join(exp_dir, "models", "net_best.pth")
        if not os.path.exists(ckpt_path):
            ckpt_path = os.path.join(exp_dir, "models", "net_latest.pth")
        if not os.path.exists(ckpt_path):
            print(f"[SKIP] {model_name}/{race}: no checkpoint")
            continue

        # Build model
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

        # Build test dataset (phase=test)
        test_opt = opt['datasets']['train'].copy()
        test_opt['phase'] = 'test'
        test_opt.pop('augment', None)
        test_opt.pop('batch_size_per_gpu', None)
        test_opt.pop('num_worker_per_gpu', None)

        test_set = build_dataset(test_opt)
        test_loader = build_dataloader(test_set, test_opt, num_gpu=1)

        # Run inference
        preds, gts = [], []
        for data in tqdm(test_loader, desc=f"{model_name}/{race}"):
            img = data['img'].cuda()
            with torch.no_grad():
                pred = net(img)
            preds.extend(pred.squeeze(1).cpu().tolist())
            gts.extend(data['mos_label'].squeeze(1).cpu().tolist())

        srcc, _ = stats.spearmanr(preds, gts)
        plcc, _ = stats.pearsonr(preds, gts)

        results_all[model_name][race] = {
            "srcc": round(float(srcc), 4),
            "plcc": round(float(plcc), 4),
            "n_test": len(preds),
        }

        print(f"  {race}: SRCC={srcc:.4f}, PLCC={plcc:.4f} (n={len(preds)})")

# Save
os.makedirs("results", exist_ok=True)
with open("results/test_results.json", "w") as f:
    json.dump(results_all, f, indent=2)

# Print table
print("\n" + "=" * 60)
print("  FINAL TEST RESULTS")
print("=" * 60)
print(f"{'Model':<10} {'Race':<6} {'SRCC':>8} {'PLCC':>8} {'N':>6}")
print("-" * 42)
for model in MODELS:
    for race in RACES:
        if race in results_all[model]:
            r = results_all[model][race]
            print(f"{model:<10} {race:<6} {r['srcc']:>8.4f} {r['plcc']:>8.4f} {r['n_test']:>6}")
print("-" * 42)
for model in MODELS:
    srccs = [v['srcc'] for v in results_all[model].values()]
    plccs = [v['plcc'] for v in results_all[model].values()]
    if srccs:
        print(f"{model:<10} {'AVG':<6} {np.mean(srccs):>8.4f} {np.mean(plccs):>8.4f}")
print("\nSaved to results/test_results.json")
