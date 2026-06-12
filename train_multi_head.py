"""
train_multi_head.py - pyiqa multi-head 训练脚本 (10 输出头 + loss_mask)

基于 pyiqa 的 backbone (DBCNN/MANIQA/HyperIQA)，替换为 10 头输出，
使用 loss_mask 忽略 NaN 属性的梯度。

用法:
  python train_multi_head.py --model DBCNN --race SA --batch-size 32 --epochs 100

依赖: pyiqa (build_network, build_dataloader, build_dataset)
"""
import os, sys, argparse, yaml, json, logging, time
from pathlib import Path
from collections import defaultdict

import numpy as np
import torch
import torch.nn as nn
from torch.cuda.amp import GradScaler, autocast
from tqdm import tqdm

# 添加 pyiqa 路径
PYIQA_ROOT = Path(__file__).resolve().parent
sys.path.insert(0, str(PYIQA_ROOT))

from pyiqa.data import build_dataset, build_dataloader
from pyiqa.archs import build_network

logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")
logger = logging.getLogger(__name__)

ALL_RACES = ["SA", "CA", "AS", "AF"]
ALL_MODELS = ["DBCNN", "MANIQA", "HyperIQA"]


def parse_args():
    p = argparse.ArgumentParser(description="pyiqa Multi-Head Training")
    p.add_argument("--model", required=True, choices=ALL_MODELS)
    p.add_argument("--race", required=True, choices=ALL_RACES)
    p.add_argument("--batch-size", type=int, default=32)
    p.add_argument("--epochs", type=int, default=100)
    p.add_argument("--lr", type=float, default=1e-4)
    p.add_argument("--wd", type=float, default=1e-4)
    p.add_argument("--num-workers", type=int, default=4)
    p.add_argument("--resume", type=str, default=None, help="Single-head checkpoint to warm-start backbone")
    p.add_argument("--output", type=str, default=None, help="Output directory")
    p.add_argument("--num-outputs", type=int, default=10)
    return p.parse_args()


def build_yml_opt(args):
    """构造 pyiqa 风格的 opt 字典"""
    model_type_map = {
        "DBCNN": "DBCNN",
        "MANIQA": "MANIQA",
        "HyperIQA": "HyperNet",
    }
    return {
        "network": {
            "type": model_type_map[args.model],
            "pretrained": args.resume is None,
            "fc": False,
            "num_outputs": args.num_outputs,
        },
        "datasets": {
            "train": {
                "name": f"deepskin_multi_{args.race}",
                "type": "DeepskinMultiNRDataset",
                "dataroot_target": "/root/autodl-tmp/rendered_2max",
                "meta_info_file": f"/root/autodl-tmp/iqa_pytorch_train/datasets/deepskin_multi/{args.race}/meta_info.csv",
                "split_index": "split_name",
                "phase": "train",
                "batch_size_per_gpu": args.batch_size,
                "num_worker_per_gpu": args.num_workers,
                "augment": {"resize": [256, 256], "random_crop": 224, "hflip": True},
            },
        },
        "num_gpu": 1,
        "dist": False,
        "manual_seed": 42,
    }


def compute_multi_head_loss(pred, target_scores, target_mask):
    """
    pred: (B, num_outputs)
    target_scores: (B, num_outputs)
    target_mask: (B, num_outputs), 1=valid, 0=NaN
    """
    mask = target_mask.bool()
    if not mask.any():
        return torch.tensor(0.0, device=pred.device, requires_grad=True)

    diff = (pred[mask] - target_scores[mask]).abs()
    return diff.mean()


def train_epoch(model, loader, optimizer, scaler, device):
    model.train()
    total_loss = 0.0
    n_batches = 0
    for batch in tqdm(loader, desc="train"):
        img = batch["img"].to(device)
        attr_scores = batch.get("attribute_scores")
        attr_mask = batch.get("attribute_mask")

        if attr_scores is None:
            continue
        attr_scores = attr_scores.to(device)
        attr_mask = attr_mask.to(device)

        optimizer.zero_grad(set_to_none=True)
        if scaler:
            with autocast():
                pred = model(img)
                loss = compute_multi_head_loss(pred, attr_scores, attr_mask)
            scaler.scale(loss).backward()
            scaler.step(optimizer)
            scaler.update()
        else:
            pred = model(img)
            loss = compute_multi_head_loss(pred, attr_scores, attr_mask)
            loss.backward()
            optimizer.step()

        if torch.isfinite(loss):
            total_loss += loss.item()
            n_batches += 1

    return total_loss / max(n_batches, 1)


@torch.no_grad()
def validate(model, loader, device):
    """按属性分别计算验证指标"""
    model.eval()
    attrs = [
        "01Preference", "02Attractiveness", "03Feminine",
        "04Cooperative", "05Youth", "06Healthy",
        "07Fidelity", "08Harmony", "09Fair", "10Ruddy",
    ]
    attr_preds = defaultdict(list)
    attr_gts = defaultdict(list)

    for batch in tqdm(loader, desc="val"):
        img = batch["img"].to(device)
        attr_scores = batch.get("attribute_scores")
        attr_mask = batch.get("attribute_mask")

        if attr_scores is None:
            continue
        pred = model(img)  # (B, 10)
        pred_np = pred.cpu().numpy()
        gt_np = attr_scores.cpu().numpy()
        mask_np = attr_mask.cpu().numpy()

        for i, attr_name in enumerate(attrs):
            valid = mask_np[:, i] > 0.5
            if valid.any():
                attr_preds[attr_name].extend(pred_np[valid, i].tolist())
                attr_gts[attr_name].extend(gt_np[valid, i].tolist())

    from scipy import stats
    results = {}
    for attr in attrs:
        if attr_preds[attr] and len(set(attr_gts[attr])) > 1:
            srcc, _ = stats.spearmanr(attr_preds[attr], attr_gts[attr])
            plcc, _ = stats.pearsonr(attr_preds[attr], attr_gts[attr])
            results[attr] = {"srcc": srcc, "plcc": plcc, "n": len(attr_preds[attr])}

    return results


def main():
    args = parse_args()
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

    # ===== 1. 加载 pyiqa dataset =====
    opt = build_yml_opt(args)
    logger.info(f"Building multi-head dataset for {args.model}/{args.race}")

    # 需要先注册 DeepskinMultiNRDataset
    import deepskin_multi_dataset  # noqa: registers DATASET_REGISTRY

    train_ds = build_dataset(opt["datasets"]["train"])
    train_loader = build_dataloader(
        train_ds, opt["datasets"]["train"], num_gpu=1
    )

    # val dataset (reuse train config, swap phase)
    val_opt = opt["datasets"]["train"].copy()
    val_opt["phase"] = "val"
    val_ds = build_dataset(val_opt)
    val_loader = build_dataloader(val_ds, val_opt, num_gpu=1)

    logger.info(f"Train: {len(train_ds)} samples, Val: {len(val_ds)} samples")

    # ===== 2. 构建 multi-head 模型 =====
    logger.info(f"Building {args.model} with num_outputs={args.num_outputs}")
    model = build_network(opt["network"]).to(device)

    # 从单头 checkpoint 加载 backbone（跳过 fc 层）
    if args.resume and os.path.exists(args.resume):
        ckpt = torch.load(args.resume, map_location=device)
        state = ckpt.get("params", ckpt.get("model_state_dict", ckpt))
        # 过滤掉 fc 相关层（形状不匹配）
        filtered = {k: v for k, v in state.items()
                     if not any(x in k for x in ["fc.", "fc_score", "fc_weight", "fc_w", "fc_b"])}
        missing, unexpected = model.load_state_dict(filtered, strict=False)
        logger.info(f"Loaded backbone from {args.resume}: {len(filtered)} keys matched, "
                     f"{len(missing)} missing (expected for new heads), "
                     f"{len(unexpected)} unexpected")

    # ===== 3. 优化器 & 混合精度 =====
    optimizer = torch.optim.AdamW(model.parameters(), lr=args.lr, weight_decay=args.wd)
    scheduler = torch.optim.lr_scheduler.CosineAnnealingLR(optimizer, T_max=args.epochs)
    scaler = GradScaler() if device.type == "cuda" else None

    # ===== 4. 输出目录 =====
    out_dir = Path(args.output or f"experiments/{args.model}_{args.race}_deepskin_multi")
    out_dir.mkdir(parents=True, exist_ok=True)
    ckpt_dir = out_dir / "models"
    ckpt_dir.mkdir(exist_ok=True)

    # ===== 5. 训练循环 =====
    best_loss = float("inf")
    for epoch in range(args.epochs):
        train_loss = train_epoch(model, train_loader, optimizer, scaler, device)
        val_results = validate(model, val_loader, device)
        scheduler.step()

        # 计算平均 SRCC
        avg_srcc = np.nanmean([v["srcc"] for v in val_results.values()]) if val_results else 0

        logger.info(f"Epoch {epoch+1}/{args.epochs} | "
                     f"train_loss={train_loss:.4f} | val_avg_srcc={avg_srcc:.4f}")

        # 保存 best
        if train_loss < best_loss:
            best_loss = train_loss
            ckpt_path = ckpt_dir / "net_best.pth"
            torch.save({"params": model.state_dict(), "epoch": epoch, "loss": train_loss}, ckpt_path)
            logger.info(f"  -> Best model saved: {ckpt_path}")
            # 保存 per-attribute metrics
            metrics_path = out_dir / "val_metrics.json"
            with open(metrics_path, "w") as f:
                json.dump(val_results, f, indent=2)

        # 定期保存
        if (epoch + 1) % 50 == 0:
            torch.save(
                {"params": model.state_dict(), "epoch": epoch},
                ckpt_dir / f"net_epoch_{epoch+1}.pth",
            )

    # 保存最终模型
    torch.save({"params": model.state_dict(), "epoch": args.epochs}, ckpt_dir / "net_latest.pth")

    # ===== 6. 输出最终指标 =====
    logger.info("\n" + "=" * 60)
    logger.info("Final Validation Results:")
    logger.info("=" * 60)
    for attr, m in sorted(val_results.items()):
        logger.info(f"  {attr}: SRCC={m['srcc']:.4f}, PLCC={m['plcc']:.4f}, N={m['n']}")

    avg_srcc_final = np.nanmean([v["srcc"] for v in val_results.values()]) if val_results else 0
    logger.info(f"  Average SRCC: {avg_srcc_final:.4f}")
    logger.info(f"Output: {out_dir}")


if __name__ == "__main__":
    main()
