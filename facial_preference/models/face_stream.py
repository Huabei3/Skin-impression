"""
Face stream module.

This module processes face RGB images together with face UV maps.
The UV maps are first converted into 2D histograms before being fed
into a lightweight CNN branch.
"""

from typing import Dict

import torch
import torch.nn as nn
import torchvision.models as models


def compute_uv_histogram(
    face_uv: torch.Tensor,
    num_bins_u: int = 32,
    num_bins_v: int = 32,
    u_range=(0.0, 1.0),
    v_range=(0.0, 1.0),
) -> torch.Tensor:
    """
    Convert a UV map into a 2D histogram image (no normalization).

    Args:
        face_uv: Tensor of shape (B, C, H, W), where the first two channels
            correspond to U and V respectively.
        num_bins_u: Number of histogram bins along U.
        num_bins_v: Number of histogram bins along V.
        u_range: Value range (u_min, u_max) used to clip and bin U.
        v_range: Value range (v_min, v_max) used to clip and bin V.

    Returns:
        Histogram tensor of shape (B, C, num_bins_u, num_bins_v).
        All channels share the same histogram; we simply expand along C.
    """
    if face_uv.dim() != 4:
        raise ValueError(f"face_uv must be 4D (B, C, H, W), got {face_uv.shape}")

    b, c, h, w = face_uv.shape
    if c < 2:
        raise ValueError(f"face_uv must have at least 2 channels (U,V), got {c}")

    # Clean NaN/Inf to avoid breaking the histogram
    uv = torch.nan_to_num(face_uv, nan=0.0, posinf=0.0, neginf=0.0)

    # Flatten spatial dimensions
    u = uv[:, 0].view(b, -1)  # (B, N)
    v = uv[:, 1].view(b, -1)  # (B, N)

    u_min, u_max = float(u_range[0]), float(u_range[1])
    v_min, v_max = float(v_range[0]), float(v_range[1])
    u_span = max(u_max - u_min, 1e-6)
    v_span = max(v_max - v_min, 1e-6)

    # Map original values into [0, 1] according to the provided ranges,
    # then discretize into integer bin indices.
    u_norm = ((u - u_min) / u_span).clamp(0.0, 1.0)
    v_norm = ((v - v_min) / v_span).clamp(0.0, 1.0)

    u_idx = (u_norm * (num_bins_u - 1)).long().clamp(0, num_bins_u - 1)
    v_idx = (v_norm * (num_bins_v - 1)).long().clamp(0, num_bins_v - 1)

    hist_list = []
    for bi in range(b):
        # Each (u_idx, v_idx) pair corresponds to one 2D bin.
        flat_idx = u_idx[bi] * num_bins_v + v_idx[bi]

        # Count occurrences; keep raw counts (no normalization).
        hist_1d = torch.bincount(flat_idx, minlength=num_bins_u * num_bins_v).float()
        hist = hist_1d.view(1, num_bins_u, num_bins_v)  # (1, H_bins, W_bins)
        hist_list.append(hist)

    # (B, 1, H_bins, W_bins)
    hist = torch.stack(hist_list, dim=0)

    # Match the original UV channel count expected by UVBranch.
    if c > 1:
        hist = hist.expand(-1, c, -1, -1).contiguous()

    return hist


class RGBBranch(nn.Module):
    """RGB branch using a configurable backbone (e.g., ResNet-50)."""

    def __init__(
        self,
        backbone: str = "resnet50",
        pretrained: bool = True,
        feature_dim: int = 512,
    ) -> None:
        super().__init__()

        if backbone == "resnet50":
            net = models.resnet50(pretrained=pretrained)
            in_features = net.fc.in_features
            # Remove original classifier head
            self.backbone = nn.Sequential(*list(net.children())[:-1])
        elif backbone == "efficientnet_b0":
            net = models.efficientnet_b0(pretrained=pretrained)
            in_features = net.classifier[1].in_features
            net.classifier = nn.Identity()
            self.backbone = net
        else:
            raise ValueError(f"Unsupported RGB backbone: {backbone}")

        # Project to a compact feature vector
        self.feature_projector = nn.Sequential(
            nn.Linear(in_features, feature_dim),
            nn.BatchNorm1d(feature_dim),
            nn.ReLU(inplace=True),
            nn.Dropout(0.2),
        )

        self.feature_dim = feature_dim

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        # Extract convolutional features
        feats = self.backbone(x)
        # Flatten if (B, C, 1, 1)
        if feats.ndim == 4:
            feats = feats.view(feats.size(0), -1)
        return self.feature_projector(feats)


class DWSeparableBlock(nn.Module):
    """Depthwise separable conv block with optional residual."""

    def __init__(self, in_channels: int, out_channels: int, stride: int = 1) -> None:
        super().__init__()
        self.use_residual = stride == 1 and in_channels == out_channels

        self.dw = nn.Conv2d(
            in_channels,
            in_channels,
            kernel_size=3,
            stride=stride,
            padding=1,
            groups=in_channels,
            bias=False,
        )
        self.dw_bn = nn.BatchNorm2d(in_channels)

        self.pw = nn.Conv2d(in_channels, out_channels, kernel_size=1, bias=False)
        self.pw_bn = nn.BatchNorm2d(out_channels)

        self.relu = nn.ReLU(inplace=True)

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        out = self.dw(x)
        out = self.dw_bn(out)
        out = self.relu(out)

        out = self.pw(out)
        out = self.pw_bn(out)

        if self.use_residual:
            out = out + x
        out = self.relu(out)
        return out


def build_dw_sep_layers(in_channels: int, channels_list: list) -> nn.Sequential:
    """Build a stack of depthwise separable conv blocks with periodic downsampling."""
    layers = []
    current = in_channels
    for i, out_ch in enumerate(channels_list):
        stride = 2 if i % 2 == 1 else 1
        layers.append(DWSeparableBlock(current, out_ch, stride=stride))
        current = out_ch
    return nn.Sequential(*layers)


class UVBranch(nn.Module):
    """UV branch: lightweight CNN operating on UV histograms."""

    def __init__(
        self,
        input_channels: int = 2,
        conv_layers: list | None = None,
        feature_dim: int = 128,
    ) -> None:
        super().__init__()

        if conv_layers is None:
            conv_layers = [32, 64, 128, 128]

        self.conv_layers = build_dw_sep_layers(input_channels, conv_layers)

        self.global_pool = nn.AdaptiveAvgPool2d(1)

        self.feature_projector = nn.Sequential(
            nn.Linear(conv_layers[-1], feature_dim),
            nn.BatchNorm1d(feature_dim),
            nn.ReLU(inplace=True),
            nn.Dropout(0.2),
        )

        self.feature_dim = feature_dim

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        feats = self.conv_layers(x)
        feats = self.global_pool(feats)
        feats = feats.view(feats.size(0), -1)
        return self.feature_projector(feats)


class FaceStream(nn.Module):
    """
    Face stream that fuses RGB and UV branches.

    The UV input is first converted to a 2D histogram, then passed into UVBranch.
    """

    def __init__(self, config: Dict) -> None:
        super().__init__()

        face_cfg = config["MODEL"]["face_stream"]

        # UV histogram hyper-parameters
        self.uv_hist_bins = int(face_cfg.get("uv_hist_bins", 32))
        self.uv_hist_u_range = tuple(face_cfg.get("uv_hist_u_range", [0.0, 1.0]))
        self.uv_hist_v_range = tuple(face_cfg.get("uv_hist_v_range", [0.0, 1.0]))

        # RGB and UV branches
        self.rgb_branch = RGBBranch(
            backbone=face_cfg["rgb_backbone"],
            pretrained=face_cfg["rgb_pretrained"],
            feature_dim=face_cfg["rgb_feature_dim"],
        )

        self.uv_branch = UVBranch(
            input_channels=face_cfg["uv_channels"],
            conv_layers=face_cfg["uv_conv_layers"],
            feature_dim=face_cfg["uv_feature_dim"],
        )

        total_dim = face_cfg["rgb_feature_dim"] + face_cfg["uv_feature_dim"]
        self.fusion = nn.Sequential(
            nn.Linear(total_dim, 512),
            nn.BatchNorm1d(512),
            nn.ReLU(inplace=True),
            nn.Dropout(0.3),
            nn.Linear(512, 256),
            nn.BatchNorm1d(256),
            nn.ReLU(inplace=True),
        )

        self.output_dim = 256

    def forward(self, face_rgb: torch.Tensor, face_uv: torch.Tensor) -> torch.Tensor:
        rgb_feats = self.rgb_branch(face_rgb)

        uv_hist = compute_uv_histogram(
            face_uv,
            num_bins_u=self.uv_hist_bins,
            num_bins_v=self.uv_hist_bins,
            u_range=self.uv_hist_u_range,
            v_range=self.uv_hist_v_range,
        )
        uv_feats = self.uv_branch(uv_hist)

        combined = torch.cat([rgb_feats, uv_feats], dim=1)
        fused = self.fusion(combined)
        return fused


class AttentiveFaceStream(nn.Module):
    """
    Face stream with an attention mechanism between RGB and UV features.

    Still uses UV histograms as the input to the UV branch.
    """

    def __init__(self, config: Dict) -> None:
        super().__init__()

        face_cfg = config["MODEL"]["face_stream"]

        # UV histogram hyper-parameters
        self.uv_hist_bins = int(face_cfg.get("uv_hist_bins", 32))
        self.uv_hist_u_range = tuple(face_cfg.get("uv_hist_u_range", [0.0, 1.0]))
        self.uv_hist_v_range = tuple(face_cfg.get("uv_hist_v_range", [0.0, 1.0]))

        # RGB and UV branches
        self.rgb_branch = RGBBranch(
            backbone=face_cfg["rgb_backbone"],
            pretrained=face_cfg["rgb_pretrained"],
            feature_dim=face_cfg["rgb_feature_dim"],
        )

        self.uv_branch = UVBranch(
            input_channels=face_cfg["uv_channels"],
            conv_layers=face_cfg["uv_conv_layers"],
            feature_dim=face_cfg["uv_feature_dim"],
        )

        rgb_dim = face_cfg["rgb_feature_dim"]
        uv_dim = face_cfg["uv_feature_dim"]

        # Simple 2-way attention to weight RGB vs UV
        self.attention = nn.Sequential(
            nn.Linear(rgb_dim + uv_dim, 128),
            nn.ReLU(inplace=True),
            nn.Linear(128, 2),
            nn.Softmax(dim=1),
        )

        self.fusion = nn.Sequential(
            nn.Linear(rgb_dim + uv_dim, 512),
            nn.BatchNorm1d(512),
            nn.ReLU(inplace=True),
            nn.Dropout(0.3),
            nn.Linear(512, 256),
            nn.BatchNorm1d(256),
            nn.ReLU(inplace=True),
        )

        self.output_dim = 256

    def forward(self, face_rgb: torch.Tensor, face_uv: torch.Tensor) -> torch.Tensor:
        rgb_feats = self.rgb_branch(face_rgb)

        uv_hist = compute_uv_histogram(
            face_uv,
            num_bins_u=self.uv_hist_bins,
            num_bins_v=self.uv_hist_bins,
            u_range=self.uv_hist_u_range,
            v_range=self.uv_hist_v_range,
        )
        uv_feats = self.uv_branch(uv_hist)

        combined = torch.cat([rgb_feats, uv_feats], dim=1)
        attn_weights = self.attention(combined)  # (B, 2)

        # Re-weight the two feature vectors
        w_rgb = attn_weights[:, 0:1]
        w_uv = attn_weights[:, 1:2]
        weighted_rgb = rgb_feats * w_rgb
        weighted_uv = uv_feats * w_uv

        fused_input = torch.cat([weighted_rgb, weighted_uv], dim=1)
        fused = self.fusion(fused_input)
        return fused

