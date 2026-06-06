#!/usr/bin/env python
"""SCUT-FBP ResNet-18 训练脚本 —— 适配 deepskin 数据集。
数据格式: 每行 "img_path score"
用法: python train_scut_resnet.py --data /path/to/deepskin_train.csv --epochs 50
"""

import argparse
import os
from pathlib import Path
import numpy as np
import torch
import torch.nn as nn
from torch.utils.data import Dataset, DataLoader
from torchvision import transforms, models
from PIL import Image
from scipy.stats import pearsonr, spearmanr

# ===================== Dataset =====================
class BeautyDataset(Dataset):
    """读取 img_path score 格式的数据文件"""
    def __init__(self, data_path, transform=None):
        self.samples = []
        with open(data_path, 'r') as f:
            for line in f:
                parts = line.strip().split()
                if len(parts) >= 2:
                    self.samples.append((parts[0], float(parts[1])))
        self.transform = transform

    def __len__(self):
        return len(self.samples)

    def __getitem__(self, idx):
        img_path, score = self.samples[idx]
        img = Image.open(img_path).convert('RGB')
        if self.transform:
            img = self.transform(img)
        return img, torch.tensor(score, dtype=torch.float32)


# ===================== Model =====================
def build_model():
    """加载 ImageNet 预训练 ResNet-18，替换最后一层为回归输出"""
    model = models.resnet18(weights=models.ResNet18_Weights.IMAGENET1K_V1)
    model.fc = nn.Linear(512, 1)
    return model


# ===================== Metrics =====================
def compute_metrics(preds, targets):
    preds, targets = np.array(preds), np.array(targets)
    mae = np.mean(np.abs(preds - targets))
    rmse = np.sqrt(np.mean((preds - targets) ** 2))
    plcc, _ = pearsonr(preds, targets)
    srcc, _ = spearmanr(preds, targets)
    return {"MAE": mae, "RMSE": rmse, "PLCC": plcc, "SRCC": srcc}


# ===================== Train =====================
def train_epoch(model, loader, criterion, optimizer, device):
    model.train()
    total_loss = 0.0
    for imgs, scores in loader:
        imgs, scores = imgs.to(device), scores.to(device)
        optimizer.zero_grad()
        preds = model(imgs).squeeze(1)
        loss = criterion(preds, scores)
        loss.backward()
        optimizer.step()
        total_loss += loss.item() * imgs.size(0)
    return total_loss / len(loader.dataset)


@torch.no_grad()
def validate(model, loader, device):
    model.eval()
    all_preds, all_targets = [], []
    for imgs, scores in loader:
        imgs, scores = imgs.to(device), scores.to(device)
        preds = model(imgs).squeeze(1)
        all_preds.extend(preds.cpu().tolist())
        all_targets.extend(scores.cpu().tolist())
    return compute_metrics(all_preds, all_targets)


# ===================== Main =====================
def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--data', type=str, required=True, help='Training data file (img_path score per line)')
    parser.add_argument('--output', type=str, default='./checkpoints', help='Checkpoint save dir')
    parser.add_argument('--batch-size', type=int, default=32)
    parser.add_argument('--epochs', type=int, default=50)
    parser.add_argument('--lr', type=float, default=1e-4)
    parser.add_argument('--num-workers', type=int, default=4)
    parser.add_argument('--val-split', type=float, default=0.2, help='Validation ratio')
    args = parser.parse_args()

    os.makedirs(args.output, exist_ok=True)
    device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
    print(f"Device: {device}")

    # Transforms (SCUT-FBP style: Resize(256) + CenterCrop(224))
    train_transform = transforms.Compose([
        transforms.Resize(256),
        transforms.RandomCrop(224),
        transforms.RandomHorizontalFlip(),
        transforms.ToTensor(),
        transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]),
    ])
    val_transform = transforms.Compose([
        transforms.Resize(256),
        transforms.CenterCrop(224),
        transforms.ToTensor(),
        transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]),
    ])

    # Load & split data
    full_dataset = BeautyDataset(args.data)
    n = len(full_dataset)
    n_val = int(n * args.val_split)
    indices = torch.randperm(n).tolist()
    train_ds = torch.utils.data.Subset(BeautyDataset(args.data, train_transform), indices[n_val:])
    val_ds = torch.utils.data.Subset(BeautyDataset(args.data, val_transform), indices[:n_val])

    train_loader = DataLoader(train_ds, batch_size=args.batch_size, shuffle=True,
                               num_workers=args.num_workers, pin_memory=True)
    val_loader = DataLoader(val_ds, batch_size=args.batch_size, shuffle=False,
                             num_workers=args.num_workers, pin_memory=True)
    print(f"Train: {len(train_ds)}, Val: {len(val_ds)}")

    # Build model
    model = build_model().to(device)
    criterion = nn.MSELoss()
    optimizer = torch.optim.Adam(model.parameters(), lr=args.lr)
    scheduler = torch.optim.lr_scheduler.ReduceLROnPlateau(optimizer, mode='min', factor=0.5, patience=5)

    best_srcc = -1.0
    for epoch in range(1, args.epochs + 1):
        train_loss = train_epoch(model, train_loader, criterion, optimizer, device)
        metrics = validate(model, val_loader, device)
        scheduler.step(metrics['MAE'])

        print(f"Epoch {epoch:3d}/{args.epochs} | "
              f"Loss={train_loss:.4f} | MAE={metrics['MAE']:.4f} | "
              f"PLCC={metrics['PLCC']:.4f} | SRCC={metrics['SRCC']:.4f}")

        if metrics['SRCC'] > best_srcc:
            best_srcc = metrics['SRCC']
            torch.save(model.state_dict(), os.path.join(args.output, 'best_model.pth'))
            print(f"  >>> Best SRCC={best_srcc:.4f} saved")

    print(f"\nBest SRCC: {best_srcc:.4f}")


if __name__ == '__main__':
    main()
