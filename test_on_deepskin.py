"""在 deepskin test set 上评估训练好的模型"""
import os, json, torch, yaml
import numpy as np
from scipy import stats
from tqdm import tqdm
from pyiqa.data import build_dataloader
from pyiqa.archs import build_network
from pyiqa.utils import get_root_logger

EXPERIMENTS = "/root/autodl-tmp/iqa_pytorch_train/experiments"
RACES = ["SA", "CA", "AS", "AF"]
MODELS = ["DBCNN", "MANIQA", "HyperIQA", "NIMA", "TReS", "CLIPIQA", "TOPIQ_NR_Face"]

results_all = {}

for model_name in MODELS:
    results_all[model_name] = {}
    for race in RACES:
        exp_name = f"{model_name}_{race}_deepskin"
        exp_dir = os.path.join(EXPERIMENTS, exp_name)

        # 找 YAML 配置
        yml_path = f"options/train/deepskin/{model_name}/train_{model_name}_{race}.yml"
        with open(yml_path) as f:
            opt = yaml.safe_load(f)

        # 找 best checkpoint
        ckpt_path = os.path.join(exp_dir, "models", "net_best.pth")
        if not os.path.exists(ckpt_path):
            ckpt_path = os.path.join(exp_dir, "models", "net_g_latest.pth")
        if not os.path.exists(ckpt_path):
            print(f"[SKIP] {model_name}/{race}: no checkpoint found")
            continue

        # Build model
        net_type = opt['network']['type']
        net = build_network(opt['network'])
        state = torch.load(ckpt_path, map_location='cpu', weights_only=True)
        # Try different state_dict keys
        if 'params' in state:
            net.load_state_dict(state['params'], strict=False)
        elif 'model_state_dict' in state:
            net.load_state_dict(state['model_state_dict'], strict=False)
        else:
            net.load_state_dict(state, strict=False)
        net = net.cuda()
        net.eval()

        # Build test dataloader (phase=test)
        test_opt = opt['datasets']['train'].copy()
        test_opt['phase'] = 'test'
        test_opt['split_index'] = 'split_name'
        test_opt.pop('augment', None)

        test_loader = build_dataloader(
            test_opt, 'deepskin', 1, 1, False, None, None
        )

        # Run inference
        test_loader = test_loader.loader if hasattr(test_loader, 'loader') else test_loader
        preds, gts = [], []
        for data in tqdm(test_loader, desc=f"{model_name}/{race}"):
            img = data['img'].cuda()
            with torch.no_grad():
                pred = net(img)
            preds.append(pred.item())
            gts.append(data['mos_label'].item())

        srcc, _ = stats.spearmanr(preds, gts)
        plcc, _ = stats.pearsonr(preds, gts)

        results_all[model_name][race] = {
            "srcc": round(float(srcc), 4),
            "plcc": round(float(plcc), 4),
            "n_test": len(preds),
            "ckpt": ckpt_path,
        }

        print(f"  {race}: SRCC={srcc:.4f}, PLCC={plcc:.4f} (n={len(preds)})")

# 保存结果
os.makedirs("results", exist_ok=True)
with open("results/test_results.json", "w") as f:
    json.dump(results_all, f, indent=2)
# 同时生成 results/test_predictions.xlsx (每个sheet一个race, 每列一个subject, 每行一个scene)

# 打印汇总表
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

# 每个模型跨 race 平均
print("-" * 42)
for model in MODELS:
    srccs = [v['srcc'] for v in results_all[model].values()]
    plccs = [v['plcc'] for v in results_all[model].values()]
    if srccs:
        print(f"{model:<10} {'AVG':<6} {np.mean(srccs):>8.4f} {np.mean(plccs):>8.4f}")

print("\nResults saved to results/test_results.json")
