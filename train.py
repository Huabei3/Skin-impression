import os
import time
import argparse
import torch
import torch.nn as nn
import torch.optim as optim
from torch.utils.tensorboard import SummaryWriter
import numpy as np
from tqdm import tqdm

import sys
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from models.mscan import MSCAN
from data.dataset import get_dataloaders
from utils.metrics import calculate_metrics


def train_one_epoch(model, train_loader, criterion, optimizer, device, epoch):
    """Train for one epoch"""
    model.train()
    running_loss = 0.0
    all_preds = []
    all_labels = []

    pbar = tqdm(train_loader, desc=f'Epoch {epoch} [Train]')
    for images, scores in pbar:
        images = images.to(device)
        scores = scores.to(device).unsqueeze(1)

        # Forward pass
        optimizer.zero_grad()
        outputs = model(images)
        loss = criterion(outputs, scores)

        # Backward pass
        loss.backward()
        optimizer.step()

        # Statistics
        running_loss += loss.item() * images.size(0)
        all_preds.extend(outputs.detach().cpu().numpy())
        all_labels.extend(scores.detach().cpu().numpy())

        pbar.set_postfix({'loss': loss.item()})

    epoch_loss = running_loss / len(train_loader.dataset)
    metrics = calculate_metrics(np.array(all_labels), np.array(all_preds))

    return epoch_loss, metrics


def validate(model, val_loader, criterion, device, epoch):
    """Validate the model"""
    model.eval()
    running_loss = 0.0
    all_preds = []
    all_labels = []

    with torch.no_grad():
        pbar = tqdm(val_loader, desc=f'Epoch {epoch} [Val]')
        for images, scores in pbar:
            images = images.to(device)
            scores = scores.to(device).unsqueeze(1)

            # Forward pass
            outputs = model(images)
            loss = criterion(outputs, scores)

            # Statistics
            running_loss += loss.item() * images.size(0)
            all_preds.extend(outputs.cpu().numpy())
            all_labels.extend(scores.cpu().numpy())

            pbar.set_postfix({'loss': loss.item()})

    epoch_loss = running_loss / len(val_loader.dataset)
    metrics = calculate_metrics(np.array(all_labels), np.array(all_preds))

    return epoch_loss, metrics


def train(args):
    """Main training function"""
    # Set device
    device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
    print(f"Using device: {device}")

    # Create dataloaders
    print("Loading dataset...")
    train_loader, val_loader = get_dataloaders(
        data_root=args.data_root,
        batch_size=args.batch_size,
        img_size=args.img_size,
        num_workers=args.num_workers
    )

    # Create model
    print("Creating model...")
    model = MSCAN(num_classes=1, pretrained=args.pretrained)
    model = model.to(device)

    # Loss function and optimizer
    criterion = nn.MSELoss()
    optimizer = optim.Adam(model.parameters(), lr=args.lr, weight_decay=args.weight_decay)
    scheduler = optim.lr_scheduler.ReduceLROnPlateau(
        optimizer, mode='min', factor=0.5, patience=5, verbose=True
    )

    # Tensorboard
    writer = SummaryWriter(log_dir=os.path.join(args.save_dir, 'logs'))

    # Training loop
    best_val_loss = float('inf')
    best_pc = -1.0

    print("Starting training...")
    for epoch in range(1, args.epochs + 1):
        # Train
        train_loss, train_metrics = train_one_epoch(
            model, train_loader, criterion, optimizer, device, epoch
        )

        # Validate
        val_loss, val_metrics = validate(
            model, val_loader, criterion, device, epoch
        )

        # Learning rate scheduling
        scheduler.step(val_loss)

        # Log to tensorboard
        writer.add_scalar('Loss/train', train_loss, epoch)
        writer.add_scalar('Loss/val', val_loss, epoch)
        writer.add_scalar('Metrics/train_PC', train_metrics['PC'], epoch)
        writer.add_scalar('Metrics/val_PC', val_metrics['PC'], epoch)
        writer.add_scalar('Metrics/train_MAE', train_metrics['MAE'], epoch)
        writer.add_scalar('Metrics/val_MAE', val_metrics['MAE'], epoch)
        writer.add_scalar('LR', optimizer.param_groups[0]['lr'], epoch)

        # Print results
        print(f"\nEpoch {epoch}/{args.epochs}")
        print(f"Train Loss: {train_loss:.4f} | PC: {train_metrics['PC']:.4f} | "
              f"MAE: {train_metrics['MAE']:.4f} | RMSE: {train_metrics['RMSE']:.4f}")
        print(f"Val Loss: {val_loss:.4f} | PC: {val_metrics['PC']:.4f} | "
              f"MAE: {val_metrics['MAE']:.4f} | RMSE: {val_metrics['RMSE']:.4f}")

        # Save best model
        if val_metrics['PC'] > best_pc:
            best_pc = val_metrics['PC']
            best_val_loss = val_loss
            torch.save({
                'epoch': epoch,
                'model_state_dict': model.state_dict(),
                'optimizer_state_dict': optimizer.state_dict(),
                'val_loss': val_loss,
                'val_metrics': val_metrics,
            }, os.path.join(args.save_dir, 'best_model.pth'))
            print(f"Saved best model with PC: {best_pc:.4f}")

        # Save checkpoint
        if epoch % args.save_freq == 0:
            torch.save({
                'epoch': epoch,
                'model_state_dict': model.state_dict(),
                'optimizer_state_dict': optimizer.state_dict(),
                'val_loss': val_loss,
                'val_metrics': val_metrics,
            }, os.path.join(args.save_dir, f'checkpoint_epoch_{epoch}.pth'))

    writer.close()
    print(f"\nTraining completed! Best PC: {best_pc:.4f}")


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Train MS-CAN for Facial Beauty Prediction')

    # Data parameters
    parser.add_argument('--data_root', type=str,
                       default='/root/autodl-tmp/MS-CAN/data/dataset',
                       help='Root directory of the dataset')
    parser.add_argument('--img_size', type=int, default=224,
                       help='Input image size')

    # Training parameters
    parser.add_argument('--batch_size', type=int, default=32,
                       help='Batch size')
    parser.add_argument('--epochs', type=int, default=100,
                       help='Number of epochs')
    parser.add_argument('--lr', type=float, default=1e-4,
                       help='Learning rate')
    parser.add_argument('--weight_decay', type=float, default=1e-4,
                       help='Weight decay')
    parser.add_argument('--num_workers', type=int, default=4,
                       help='Number of data loading workers')

    # Model parameters
    parser.add_argument('--pretrained', action='store_true', default=True,
                       help='Use pretrained ResNet50 backbone')

    # Save parameters
    parser.add_argument('--save_dir', type=str, default='./checkpoints',
                       help='Directory to save checkpoints')
    parser.add_argument('--save_freq', type=int, default=10,
                       help='Save checkpoint every N epochs')

    args = parser.parse_args()

    # Create save directory
    os.makedirs(args.save_dir, exist_ok=True)

    # Train
    train(args)
