import torch
import torch.nn as nn
import torch.nn.functional as F
from utils import rgb_to_lab, lab_to_rgb


class BackBoneCNN(nn.Module):
    def __init__(self, in_channels=5):
        super().__init__()
        self.conv = nn.Sequential(
            nn.Conv2d(in_channels, 16, 3, stride=2, padding=1),
            nn.InstanceNorm2d(16),
            nn.ReLU(inplace=True),
            nn.Conv2d(16, 32, 3, stride=2, padding=1),
            nn.InstanceNorm2d(32),
            nn.ReLU(inplace=True),
            nn.Conv2d(32, 64, 3, stride=2, padding=1),
            nn.InstanceNorm2d(64),
            nn.ReLU(inplace=True),
            nn.Conv2d(64, 32, 3, stride=2, padding=1),
            nn.InstanceNorm2d(32),
            nn.ReLU(inplace=True),
            nn.Conv2d(32, 16, 3, stride=2, padding=1),
            nn.InstanceNorm2d(16),
            nn.ReLU(inplace=True),
            nn.AdaptiveAvgPool2d(1),
        )

    def forward(self, x):
        return self.conv(x).view(x.size(0), -1)


class QualityGuidedEnhancer(nn.Module):
    def __init__(self, n_base_1d=3, n_base_3d=3, lut_dim=33, use_skin_label=True, backbone_size=256):
        super().__init__()
        self.n_base_1d = n_base_1d
        self.n_base_3d = n_base_3d
        self.lut_dim = lut_dim
        self.use_skin_label = use_skin_label
        self.backbone_size = backbone_size

        in_ch = 5 if use_skin_label else 4
        self.backbone = BackBoneCNN(in_ch)

        feat_dim = 16
        self.mlp_1d = nn.Sequential(
            nn.Linear(feat_dim, feat_dim),
            nn.ReLU(inplace=True),
            nn.Linear(feat_dim, 3 * n_base_1d)
        )
        self.mlp_3d = nn.Sequential(
            nn.Linear(feat_dim, feat_dim),
            nn.ReLU(inplace=True),
            nn.Linear(feat_dim, n_base_3d)
        )

        self.base_1d = nn.Parameter(torch.randn(n_base_1d, 3, lut_dim) * 0.01)
        self.base_3d = nn.Parameter(torch.randn(n_base_3d, 3, lut_dim, lut_dim, lut_dim) * 0.01)

    def apply_1d_lut(self, x, luts):
        """
        x: (B, 3, H, W), values in [-1, 1]
        luts: (B, 3, D) fused 1D LUTs
        """
        B, C, H, W = x.shape
        D = luts.size(2)
        x_flat = x.view(B, C, -1)
        t = (x_flat + 1) / 2.0
        t = t.clamp(0, 1) * (D - 1)
        t0 = t.long()
        t1 = (t0 + 1).clamp(max=D - 1)
        wa = t1.float() - t
        wb = t - t0.float()
        lut_b = torch.gather(luts, 2, t0)
        lut_a = torch.gather(luts, 2, t1)
        out = wa * lut_b + wb * lut_a
        return out.view(B, C, H, W)

    def apply_3d_lut(self, x, luts):
        """
        x: (B, 3, H, W), values in [-1, 1]
        luts: (B, 3, D, D, D) fused 3D LUT
        """
        grid = x.permute(0, 2, 3, 1).unsqueeze(1)
        out = F.grid_sample(luts, grid, mode='bilinear', padding_mode='border', align_corners=True)
        return out.squeeze(2)

    def forward(self, img, score, label=None):
        """
        img: (B, 3, H, W), range [0, 1]
        score: (B,) or (B, 1), normalized to [-1, 1]
        label: (B,) or (B, 1), skin tone label (optional)
        """
        B = img.size(0)
        _, _, H, W = img.shape
        if H != self.backbone_size or W != self.backbone_size:
            img_down = F.interpolate(img, size=(self.backbone_size, self.backbone_size),
                                     mode='bilinear', align_corners=False)
        else:
            img_down = img

        if score.dim() == 1:
            score = score.unsqueeze(1)
        score_map = score.view(B, 1, 1, 1).expand(B, 1, self.backbone_size, self.backbone_size)

        if self.use_skin_label:
            if label is None:
                label = torch.ones_like(score) * 5.0
            if label.dim() == 1:
                label = label.unsqueeze(1)
            label_map = label.view(B, 1, 1, 1).expand(B, 1, self.backbone_size, self.backbone_size)
            x = torch.cat([img_down, score_map, label_map], dim=1)
        else:
            x = torch.cat([img_down, score_map], dim=1)

        F_feat = self.backbone(x)

        w_1d = self.mlp_1d(F_feat).view(B, 3, self.n_base_1d)
        w_1d = F.softmax(w_1d, dim=-1)

        w_3d = self.mlp_3d(F_feat)
        w_3d = F.softmax(w_3d, dim=-1)

        fused_1d = torch.einsum('bcn,nch->bch', w_1d, self.base_1d.permute(1, 0, 2))
        fused_3d = torch.einsum('bn,nchwd->bchwd', w_3d, self.base_3d)

        lab = rgb_to_lab(img)
        lab_norm = torch.zeros_like(lab)
        lab_norm[:, 0] = lab[:, 0] / 50.0 - 1.0
        lab_norm[:, 1] = lab[:, 1] / 128.0
        lab_norm[:, 2] = lab[:, 2] / 128.0

        lab_enhanced = self.apply_1d_lut(lab_norm, fused_1d)

        lab_out = torch.zeros_like(lab_enhanced)
        lab_out[:, 0] = (lab_enhanced[:, 0] + 1.0) * 50.0
        lab_out[:, 1] = lab_enhanced[:, 1] * 128.0
        lab_out[:, 2] = lab_enhanced[:, 2] * 128.0

        rgb = lab_to_rgb(lab_out).clamp(0, 1)
        rgb_norm = rgb * 2.0 - 1.0
        rgb_enhanced = self.apply_3d_lut(rgb_norm, fused_3d)
        out = (rgb_enhanced + 1.0) / 2.0
        return out.clamp(0, 1)
