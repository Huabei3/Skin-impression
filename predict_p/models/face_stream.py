"""
Face stream module (local copy for predict_p).

This file is intentionally NOT shared with predict_center.
"""

from typing import Dict, Optional

import torch
import torch.nn as nn
import torchvision.models as models

from .backbones import SimpleCNNBackbone


def _log_ratio_uv_to_unit_interval(face_uv: torch.Tensor, clip: float = 3.0, eps: float = 1e-6) -> torch.Tensor:
    """
    Convert UV ratio map to log-ratio and normalize to [0,1].

    Expected input channels:
      - U: R/G ratio
      - V: B/G ratio
    """
    if face_uv.dim() != 4:
        raise ValueError(f"face_uv must be 4D (B, C, H, W), got {face_uv.shape}")
    if face_uv.size(1) < 2:
        raise ValueError(f"face_uv must have at least 2 channels (U,V), got {face_uv.size(1)}")

    uv = torch.nan_to_num(face_uv, nan=1.0, posinf=1.0, neginf=1.0).clamp_min(float(eps))
    u = torch.log(uv[:, 0])
    v = torch.log(uv[:, 1])
    c = float(max(float(clip), 1e-6))
    u = u.clamp(-c, c)
    v = v.clamp(-c, c)
    u = (u + c) / (2.0 * c)
    v = (v + c) / (2.0 * c)
    return torch.stack([u, v], dim=1)


def _ensure_hist_channels(hist: torch.Tensor, out_channels: int) -> torch.Tensor:
    if hist.dim() != 4:
        raise ValueError(f"uv_hist must be 4D (B, C, H, W), got {hist.shape}")
    if out_channels < 1:
        raise ValueError(f"out_channels must be >= 1, got {out_channels}")
    c = int(hist.size(1))
    if c == out_channels:
        return hist
    if c > out_channels:
        return hist[:, :out_channels]
    return hist.expand(-1, out_channels, -1, -1).contiguous()


def compute_uv_histogram(
    face_uv: torch.Tensor,
    num_bins_u: int = 32,
    num_bins_v: int = 32,
    u_range=(0.0, 1.0),
    v_range=(0.0, 1.0),
    out_channels: Optional[int] = None,
) -> torch.Tensor:
    if face_uv.dim() != 4:
        raise ValueError(f"face_uv must be 4D (B, C, H, W), got {face_uv.shape}")

    b, c, _, _ = face_uv.shape
    if c < 2:
        raise ValueError(f"face_uv must have at least 2 channels (U,V), got {c}")

    uv = torch.nan_to_num(face_uv, nan=0.0, posinf=0.0, neginf=0.0)
    u = uv[:, 0].view(b, -1)
    v = uv[:, 1].view(b, -1)

    u_min, u_max = float(u_range[0]), float(u_range[1])
    v_min, v_max = float(v_range[0]), float(v_range[1])
    u_span = max(u_max - u_min, 1e-6)
    v_span = max(v_max - v_min, 1e-6)

    u_norm = ((u - u_min) / u_span).clamp(0.0, 1.0)
    v_norm = ((v - v_min) / v_span).clamp(0.0, 1.0)

    u_idx = (u_norm * (num_bins_u - 1)).long().clamp(0, num_bins_u - 1)
    v_idx = (v_norm * (num_bins_v - 1)).long().clamp(0, num_bins_v - 1)

    hist_list = []
    for bi in range(b):
        flat_idx = u_idx[bi] * num_bins_v + v_idx[bi]
        hist_1d = torch.bincount(flat_idx, minlength=num_bins_u * num_bins_v).float()
        hist = hist_1d.view(1, num_bins_u, num_bins_v)
        hist_list.append(hist)

    hist = torch.stack(hist_list, dim=0)
    if out_channels is None:
        out_channels = c
    if out_channels < 1:
        raise ValueError(f"out_channels must be >= 1, got {out_channels}")
    if out_channels != 1:
        hist = hist.expand(-1, out_channels, -1, -1).contiguous()
    return hist


class RGBBranch(nn.Module):
    def __init__(self, backbone: str = "resnet50", pretrained: bool = True, feature_dim: int = 512,
                 freeze_backbone: bool = False) -> None:
        super().__init__()

        if backbone == "resnet50":
            net = models.resnet50(pretrained=pretrained)
            in_features = net.fc.in_features
            self.backbone_raw = nn.Sequential(*list(net.children())[:-1])
            self._needs_projection = True
            self._in_features = in_features
        elif backbone == "efficientnet_b0":
            net = models.efficientnet_b0(pretrained=pretrained)
            in_features = net.classifier[1].in_features
            net.classifier = nn.Identity()
            self.backbone_raw = net
            self._needs_projection = True
            self._in_features = in_features
        elif backbone == "simple_cnn":
            from .backbones import SimpleCNNBackbone as _SimpleCNN
            self.backbone_raw = _SimpleCNN(in_channels=3, out_dim=int(feature_dim))
            self.feature_projector = nn.Identity()
            self.feature_dim = int(feature_dim)
            self._needs_projection = False
            return
        # ===== Phase 0 新增: MobileNetV3 / ViT / Swin / CLIP =====
        elif backbone in ("mobilenet_v3_small", "mobilenet_v3_large",
                          "vit_b_16", "swin_t", "clip_vit_b32"):
            from .backbones import create_backbone as _create_backbone
            bb = _create_backbone(
                backbone_name=backbone, pretrained=pretrained,
                feature_dim=int(feature_dim), freeze=freeze_backbone,
            )
            self.backbone_raw = bb
            self.feature_projector = nn.Identity()
            self.feature_dim = int(feature_dim)
            self._needs_projection = False
            return
        # ============================================================
        else:
            raise ValueError(f"Unsupported RGB backbone: {backbone}")

        # 需要额外 projection 的 backbone (resnet50, efficientnet_b0)
        self.feature_projector = nn.Sequential(
            nn.Linear(self._in_features, feature_dim),
            nn.BatchNorm1d(feature_dim),
            nn.ReLU(inplace=True),
            nn.Dropout(0.2),
        )
        self.feature_dim = feature_dim
        self._needs_projection = True

        if freeze_backbone:
            self.freeze_backbone()

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        feats = self.backbone_raw(x)
        if feats.ndim == 4:
            feats = feats.view(feats.size(0), -1)
        return self.feature_projector(feats)

    def freeze_backbone(self) -> None:
        """冻结 backbone 参数，仅训练 projection head。"""
        for p in self.backbone_raw.parameters():
            p.requires_grad_(False)

    def unfreeze_backbone(self) -> None:
        """解冻 backbone 参数。"""
        for p in self.backbone_raw.parameters():
            p.requires_grad_(True)


class DWSeparableBlock(nn.Module):
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


class UVBranch(nn.Module):
    def __init__(self, input_channels: int = 2, conv_layers=None, feature_dim: int = 128) -> None:
        super().__init__()
        if conv_layers is None:
            conv_layers = [32, 64, 128]

        layers = []
        in_ch = input_channels
        for i, out_ch in enumerate(conv_layers):
            stride = 2 if i < 2 else 1
            layers.append(DWSeparableBlock(in_ch, out_ch, stride=stride))
            in_ch = out_ch

        self.conv_layers = nn.Sequential(*layers)
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


class UVBranchMLP(nn.Module):
    def __init__(self, bins: int, feature_dim: int = 128, hidden_dims=None) -> None:
        super().__init__()
        if hidden_dims is None:
            hidden_dims = [512, 256]
        bins = int(bins)
        if bins < 2:
            raise ValueError(f"bins must be >= 2, got {bins}")

        in_dim = bins * bins
        layers = []
        for h in hidden_dims:
            layers.append(nn.Linear(in_dim, int(h)))
            layers.append(nn.BatchNorm1d(int(h)))
            layers.append(nn.ReLU(inplace=True))
            layers.append(nn.Dropout(0.2))
            in_dim = int(h)
        layers.append(nn.Linear(in_dim, int(feature_dim)))
        layers.append(nn.BatchNorm1d(int(feature_dim)))
        layers.append(nn.ReLU(inplace=True))
        self.net = nn.Sequential(*layers)
        self.feature_dim = int(feature_dim)
        self.output_dim = int(feature_dim)

    def forward(self, hist: torch.Tensor) -> torch.Tensor:
        if hist.dim() != 4:
            raise ValueError(f"uv_hist must be 4D (B, C, H, W), got {hist.shape}")
        if hist.size(1) < 1:
            raise ValueError(f"uv_hist must have at least 1 channel, got {hist.shape}")
        x = hist[:, 0:1].contiguous()
        x = x.view(x.size(0), -1)
        return self.net(x)


class FaceStream(nn.Module):
    def __init__(self, config: Dict) -> None:
        super().__init__()
        face_cfg = config["MODEL"]["face_stream"]

        self.uv_hist_bins = int(face_cfg.get("uv_hist_bins", 32))
        self.uv_hist_u_range = tuple(face_cfg.get("uv_hist_u_range", [0.0, 1.0]))
        self.uv_hist_v_range = tuple(face_cfg.get("uv_hist_v_range", [0.0, 1.0]))
        self.uv_is_hist = bool(config.get("FACE_UV_IS_HIST", False))
        self.uv_log_ratio = bool(face_cfg.get("uv_log_ratio", False))
        self.uv_log_clip = float(face_cfg.get("uv_log_clip", 3.0))
        self.uv_branch_type = str(face_cfg.get("uv_branch_type", "cnn")).lower().strip()

        self.rgb_branch = RGBBranch(
            backbone=face_cfg["rgb_backbone"],
            pretrained=face_cfg["rgb_pretrained"],
            feature_dim=face_cfg["rgb_feature_dim"],
        )

        if self.uv_branch_type in {"mlp", "fc", "linear"}:
            self.uv_branch = UVBranchMLP(
                bins=self.uv_hist_bins,
                feature_dim=face_cfg["uv_feature_dim"],
                hidden_dims=list(face_cfg.get("uv_mlp_hidden_dims", [512, 256])),
            )
            self._uv_expected_channels = 1
        else:
            self.uv_branch = UVBranch(
                input_channels=face_cfg["uv_channels"],
                conv_layers=face_cfg["uv_conv_layers"],
                feature_dim=face_cfg["uv_feature_dim"],
            )
            self._uv_expected_channels = int(face_cfg.get("uv_channels", 2))

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
        if self.uv_is_hist:
            uv_hist = face_uv
            if uv_hist.size(-2) != self.uv_hist_bins or uv_hist.size(-1) != self.uv_hist_bins:
                raise ValueError(
                    f"FACE_UV_IS_HIST=True expects face_uv hist with spatial size "
                    f"{self.uv_hist_bins}x{self.uv_hist_bins}, got {tuple(uv_hist.shape)}"
                )
            uv_hist = _ensure_hist_channels(uv_hist, out_channels=self._uv_expected_channels)
        else:
            uv_for_hist = _log_ratio_uv_to_unit_interval(face_uv, clip=self.uv_log_clip) if self.uv_log_ratio else face_uv
            uv_hist = compute_uv_histogram(
                uv_for_hist,
                num_bins_u=self.uv_hist_bins,
                num_bins_v=self.uv_hist_bins,
                u_range=self.uv_hist_u_range,
                v_range=self.uv_hist_v_range,
                out_channels=1 if self.uv_branch_type in {"mlp", "fc", "linear"} else None,
            )
        uv_feats = self.uv_branch(uv_hist)
        combined = torch.cat([rgb_feats, uv_feats], dim=1)
        return self.fusion(combined)


class AttentiveFaceStream(nn.Module):
    def __init__(self, config: Dict) -> None:
        super().__init__()
        face_cfg = config["MODEL"]["face_stream"]

        self.uv_hist_bins = int(face_cfg.get("uv_hist_bins", 32))
        self.uv_hist_u_range = tuple(face_cfg.get("uv_hist_u_range", [0.0, 1.0]))
        self.uv_hist_v_range = tuple(face_cfg.get("uv_hist_v_range", [0.0, 1.0]))
        self.uv_is_hist = bool(config.get("FACE_UV_IS_HIST", False))
        self.uv_log_ratio = bool(face_cfg.get("uv_log_ratio", False))
        self.uv_log_clip = float(face_cfg.get("uv_log_clip", 3.0))
        self.uv_branch_type = str(face_cfg.get("uv_branch_type", "cnn")).lower().strip()

        self.rgb_branch = RGBBranch(
            backbone=face_cfg["rgb_backbone"],
            pretrained=face_cfg["rgb_pretrained"],
            feature_dim=face_cfg["rgb_feature_dim"],
        )
        if self.uv_branch_type in {"mlp", "fc", "linear"}:
            self.uv_branch = UVBranchMLP(
                bins=self.uv_hist_bins,
                feature_dim=face_cfg["uv_feature_dim"],
                hidden_dims=list(face_cfg.get("uv_mlp_hidden_dims", [512, 256])),
            )
            self._uv_expected_channels = 1
        else:
            self.uv_branch = UVBranch(
                input_channels=face_cfg["uv_channels"],
                conv_layers=face_cfg["uv_conv_layers"],
                feature_dim=face_cfg["uv_feature_dim"],
            )
            self._uv_expected_channels = int(face_cfg.get("uv_channels", 2))

        rgb_dim = face_cfg["rgb_feature_dim"]
        uv_dim = face_cfg["uv_feature_dim"]

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
        if self.uv_is_hist:
            uv_hist = face_uv
            if uv_hist.size(-2) != self.uv_hist_bins or uv_hist.size(-1) != self.uv_hist_bins:
                raise ValueError(
                    f"FACE_UV_IS_HIST=True expects face_uv hist with spatial size "
                    f"{self.uv_hist_bins}x{self.uv_hist_bins}, got {tuple(uv_hist.shape)}"
                )
            uv_hist = _ensure_hist_channels(uv_hist, out_channels=self._uv_expected_channels)
        else:
            uv_for_hist = _log_ratio_uv_to_unit_interval(face_uv, clip=self.uv_log_clip) if self.uv_log_ratio else face_uv
            uv_hist = compute_uv_histogram(
                uv_for_hist,
                num_bins_u=self.uv_hist_bins,
                num_bins_v=self.uv_hist_bins,
                u_range=self.uv_hist_u_range,
                v_range=self.uv_hist_v_range,
                out_channels=1 if self.uv_branch_type in {"mlp", "fc", "linear"} else None,
            )
        uv_feats = self.uv_branch(uv_hist)
        combined = torch.cat([rgb_feats, uv_feats], dim=1)
        attn_weights = self.attention(combined)
        w_rgb = attn_weights[:, 0:1]
        w_uv = attn_weights[:, 1:2]
        fused_input = torch.cat([rgb_feats * w_rgb, uv_feats * w_uv], dim=1)
        return self.fusion(fused_input)


class FaceStreamV2(nn.Module):
    """
    V2 face stream:
    - No RGB/UV attention (keeps FaceStream-style fusion).
    - Keeps UV histogram, but uses single-channel histogram (no channel replication).
    """

    def __init__(self, config: Dict) -> None:
        super().__init__()
        face_cfg = config["MODEL"]["face_stream"]

        self.uv_hist_bins = int(face_cfg.get("uv_hist_bins", 32))
        self.uv_hist_u_range = tuple(face_cfg.get("uv_hist_u_range", [0.0, 1.0]))
        self.uv_hist_v_range = tuple(face_cfg.get("uv_hist_v_range", [0.0, 1.0]))
        self.uv_is_hist = bool(config.get("FACE_UV_IS_HIST", False))
        self.uv_log_ratio = bool(face_cfg.get("uv_log_ratio", False))
        self.uv_log_clip = float(face_cfg.get("uv_log_clip", 3.0))
        self.uv_branch_type = str(face_cfg.get("uv_branch_type", "cnn")).lower().strip()

        self.rgb_branch = RGBBranch(
            backbone=face_cfg["rgb_backbone"],
            pretrained=face_cfg["rgb_pretrained"],
            feature_dim=face_cfg["rgb_feature_dim"],
        )
        if self.uv_branch_type in {"mlp", "fc", "linear"}:
            self.uv_branch = UVBranchMLP(
                bins=self.uv_hist_bins,
                feature_dim=face_cfg["uv_feature_dim"],
                hidden_dims=list(face_cfg.get("uv_mlp_hidden_dims", [512, 256])),
            )
        else:
            self.uv_branch = UVBranch(
                input_channels=1,
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
        if self.uv_is_hist:
            uv_hist = face_uv
            if uv_hist.size(-2) != self.uv_hist_bins or uv_hist.size(-1) != self.uv_hist_bins:
                raise ValueError(
                    f"FACE_UV_IS_HIST=True expects face_uv hist with spatial size "
                    f"{self.uv_hist_bins}x{self.uv_hist_bins}, got {tuple(uv_hist.shape)}"
                )
            uv_hist = _ensure_hist_channels(uv_hist, out_channels=1)
        else:
            uv_for_hist = _log_ratio_uv_to_unit_interval(face_uv, clip=self.uv_log_clip) if self.uv_log_ratio else face_uv
            uv_hist = compute_uv_histogram(
                uv_for_hist,
                num_bins_u=self.uv_hist_bins,
                num_bins_v=self.uv_hist_bins,
                u_range=self.uv_hist_u_range,
                v_range=self.uv_hist_v_range,
                out_channels=1,
            )
        uv_feats = self.uv_branch(uv_hist)
        combined = torch.cat([rgb_feats, uv_feats], dim=1)
        return self.fusion(combined)


class FaceStreamV3(nn.Module):
    """
    V3 face stream:
    - RGB-only (UV branch removed).
    """

    def __init__(self, config: Dict) -> None:
        super().__init__()
        face_cfg = config["MODEL"]["face_stream"]

        self.rgb_branch = RGBBranch(
            backbone=face_cfg["rgb_backbone"],
            pretrained=face_cfg.get("rgb_pretrained", False),
            feature_dim=int(face_cfg.get("rgb_feature_dim", 256)),
            freeze_backbone=bool(face_cfg.get("freeze_backbone", False)),
        )

        rgb_dim = int(face_cfg.get("rgb_feature_dim", 256))
        out_dim = int(face_cfg.get("rgb_only_output_dim", 256))
        self.fusion = nn.Sequential(
            nn.Linear(rgb_dim, out_dim),
            nn.BatchNorm1d(out_dim),
            nn.ReLU(inplace=True),
        )
        self.output_dim = out_dim

    def forward(self, face_rgb: torch.Tensor) -> torch.Tensor:
        rgb_feats = self.rgb_branch(face_rgb)
        return self.fusion(rgb_feats)
