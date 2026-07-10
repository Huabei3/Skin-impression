import os
import argparse
import torch
import torch.optim as optim
from torch.utils.data import DataLoader
from model import QualityGuidedEnhancer
from dataset import EnhancementDataset
from utils import compute_loss, save_checkpoint, build_data_list


def train(args):
    device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
    model = QualityGuidedEnhancer(
        n_base_1d=args.n_base_1d,
        n_base_3d=args.n_base_3d,
        lut_dim=args.lut_dim,
        use_skin_label=args.use_skin_label,
        backbone_size=args.backbone_size
    ).to(device)

    optimizer = optim.Adam(model.parameters(), lr=args.lr)

    data_list = build_data_list(args.data_dir)
    if len(data_list) == 0:
        raise ValueError(f"No valid data found in {args.data_dir}. Please check the expected folder structure.")

    train_set = EnhancementDataset(data_list, img_size=args.img_size)
    train_loader = DataLoader(train_set, batch_size=args.batch_size,
                              shuffle=True, num_workers=args.num_workers)

    os.makedirs(args.save_dir, exist_ok=True)

    for epoch in range(args.epochs):
        model.train()
        epoch_loss = 0.0
        for batch in train_loader:
            raw = batch['raw'].to(device)
            adj = batch['adjusted'].to(device)
            score = batch['score'].to(device)
            label = batch['label'].to(device)

            pred = model(raw, score, label if args.use_skin_label else None)
            loss, loss_dict = compute_loss(pred, adj, model.base_1d, model.base_3d)

            optimizer.zero_grad()
            loss.backward()
            optimizer.step()
            epoch_loss += loss.item()

        avg_loss = epoch_loss / len(train_loader)
        print(f"Epoch [{epoch + 1}/{args.epochs}] Loss: {avg_loss:.4f}  "
              f"Lr: {loss_dict['l_r']:.4f}  Ls: {loss_dict['l_s']:.6f}  Lm: {loss_dict['l_m']:.6f}")

        if (epoch + 1) % args.save_freq == 0:
            save_checkpoint(model, optimizer, epoch, args.save_dir)

    final_path = os.path.join(args.save_dir, 'final.pth')
    torch.save({'model_state_dict': model.state_dict()}, final_path)
    print(f"Training finished. Final model saved to {final_path}")


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Train Quality-guided Skin Tone Enhancement')
    parser.add_argument('--data_dir', type=str, required=True, help='Root directory of training data')
    parser.add_argument('--save_dir', type=str, default='./checkpoints', help='Directory to save checkpoints')
    parser.add_argument('--img_size', type=int, default=256, help='Image resize size for data loading')
    parser.add_argument('--backbone_size', type=int, default=256, help='Spatial size fed into the CNN backbone')
    parser.add_argument('--batch_size', type=int, default=1, help='Batch size (paper uses 1)')
    parser.add_argument('--epochs', type=int, default=400, help='Total training epochs')
    parser.add_argument('--lr', type=float, default=1e-4, help='Learning rate')
    parser.add_argument('--n_base_1d', type=int, default=3, help='Number of base 1D LUTs')
    parser.add_argument('--n_base_3d', type=int, default=3, help='Number of base 3D LUTs')
    parser.add_argument('--lut_dim', type=int, default=33, help='LUT lattice dimension')
    parser.add_argument('--use_skin_label', action='store_true', default=True, help='Use skin tone label')
    parser.add_argument('--no_skin_label', dest='use_skin_label', action='store_false', help='Disable skin tone label')
    parser.add_argument('--save_freq', type=int, default=50, help='Checkpoint save frequency (epochs)')
    parser.add_argument('--num_workers', type=int, default=4, help='DataLoader num_workers')
    args = parser.parse_args()
    train(args)
