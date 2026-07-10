import os
import json
import torch
import torch.nn.functional as F


def rgb_to_lab(img):
    """img: (B,3,H,W) in [0,1]"""
    try:
        import kornia
        return kornia.color.rgb_to_lab(img)
    except ImportError:
        raise ImportError("kornia is required. Please run: pip install kornia")


def lab_to_rgb(img):
    """img: (B,3,H,W), L in [0,100], a/b in approx [-128,127]"""
    try:
        import kornia
        return kornia.color.lab_to_rgb(img)
    except ImportError:
        raise ImportError("kornia is required. Please run: pip install kornia")


def build_data_list(data_dir):
    """
    Build data list from directory.
    Expected structure per sample folder:
        raw.png, adjusted.png, info.json with {'score': float, 'label': int}
    """
    data_list = []
    subdirs = [d for d in os.listdir(data_dir)
               if os.path.isdir(os.path.join(data_dir, d))]
    for sub in subdirs:
        subpath = os.path.join(data_dir, sub)
        info_path = os.path.join(subpath, 'info.json')
        if not os.path.exists(info_path):
            continue
        with open(info_path, 'r') as f:
            info = json.load(f)
        raw = os.path.join(subpath, info.get('raw', 'raw.png'))
        adjusted = os.path.join(subpath, info.get('adjusted', 'adjusted.png'))
        data_list.append({
            'raw': raw,
            'adjusted': adjusted,
            'score': info['score'],
            'label': info.get('label', 5)
        })
    return data_list


def compute_loss(pred, target, base_1d, base_3d, lambda1=1.0, lambda2=1e-4, lambda3=10.0):
    l_r = F.l1_loss(pred, target)

    l_s = torch.mean((base_1d[:, :, 1:] - base_1d[:, :, :-1]) ** 2)
    diff_x = base_3d[:, :, 1:, :, :] - base_3d[:, :, :-1, :, :]
    diff_y = base_3d[:, :, :, 1:, :] - base_3d[:, :, :, :-1, :]
    diff_z = base_3d[:, :, :, :, 1:] - base_3d[:, :, :, :, :-1]
    l_s += torch.mean(diff_x ** 2) + torch.mean(diff_y ** 2) + torch.mean(diff_z ** 2)

    diff_1d = base_1d[:, :, 1:] - base_1d[:, :, :-1]
    l_m = F.relu(-diff_1d).mean()

    l_m += F.relu(-diff_x).mean()
    l_m += F.relu(-diff_y).mean()
    l_m += F.relu(-diff_z).mean()

    loss = lambda1 * l_r + lambda2 * l_s + lambda3 * l_m
    return loss, {
        'l_r': l_r.item(),
        'l_s': l_s.item(),
        'l_m': l_m.item()
    }


def save_checkpoint(model, optimizer, epoch, save_dir):
    os.makedirs(save_dir, exist_ok=True)
    path = os.path.join(save_dir, f'epoch_{epoch + 1}.pth')
    torch.save({
        'epoch': epoch,
        'model_state_dict': model.state_dict(),
        'optimizer_state_dict': optimizer.state_dict(),
    }, path)
    print(f"Saved checkpoint to {path}")
