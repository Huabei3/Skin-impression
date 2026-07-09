from __future__ import annotations

from typing import List, Optional

import torch
import torch.nn as nn


class ConvBNAct(nn.Module):
    def __init__(
        self,
        in_channels: int,
        out_channels: int,
        kernel_size: int = 3,
        stride: int = 1,
        padding: Optional[int] = None,
    ) -> None:
        super().__init__()
        if padding is None:
            padding = kernel_size // 2
        self.net = nn.Sequential(
            nn.Conv2d(in_channels, out_channels, kernel_size=kernel_size, stride=stride, padding=padding, bias=False),
            nn.BatchNorm2d(out_channels),
            nn.ReLU(inplace=True),
        )

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        return self.net(x)


class SimpleCNNBackbone(nn.Module):
    """
    Lightweight CNN backbone (no pretrained weights).

    Returns a pooled feature vector of shape (B, out_dim).
    """

    def __init__(self, in_channels: int = 3, channels: Optional[List[int]] = None, out_dim: int = 256) -> None:
        super().__init__()
        if channels is None:
            channels = [32, 64, 128, 256]
        if not channels:
            raise ValueError("channels must be non-empty")

        layers: List[nn.Module] = []
        c_in = int(in_channels)
        for i, c_out in enumerate(channels):
            stride = 2 if i < 3 else 1
            layers.append(ConvBNAct(c_in, int(c_out), kernel_size=3, stride=stride))
            layers.append(ConvBNAct(int(c_out), int(c_out), kernel_size=3, stride=1))
            c_in = int(c_out)

        self.features = nn.Sequential(*layers)
        self.pool = nn.AdaptiveAvgPool2d(1)
        self.proj = nn.Sequential(
            nn.Flatten(1),
            nn.Linear(c_in, int(out_dim)),
            nn.BatchNorm1d(int(out_dim)),
            nn.ReLU(inplace=True),
            nn.Dropout(0.2),
        )
        self.out_dim = int(out_dim)

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        x = self.features(x)
        x = self.pool(x)
        return self.proj(x)


# ============================================================
# Phase 0 新增: MobileNetV3 / ViT / Swin / CLIP backbones
# 所有新 backbone 通过 --rgb-backbone 参数选择
# 不加参数 → 回退到原有 simple_cnn
# ============================================================

class MobileNetV3Backbone(nn.Module):
    """MobileNetV3-Small 或 Large backbone (torchvision)."""
    def __init__(self, variant: str = "small", pretrained: bool = True, out_dim: int = 256) -> None:
        super().__init__()
        import torchvision.models as models
        if variant == "small":
            net = models.mobilenet_v3_small(pretrained=pretrained)
            in_features = net.classifier[0].in_features  # 576
        elif variant == "large":
            net = models.mobilenet_v3_large(pretrained=pretrained)
            in_features = net.classifier[0].in_features  # 960
        else:
            raise ValueError(f"Unknown MobileNetV3 variant: {variant}")
        net.classifier = nn.Identity()
        self.backbone = net
        self.out_dim = int(out_dim)
        self.proj = nn.Sequential(
            nn.Linear(in_features, int(out_dim)),
            nn.BatchNorm1d(int(out_dim)),
            nn.ReLU(inplace=True),
            nn.Dropout(0.2),
        )

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        feats = self.backbone(x)
        if feats.ndim > 2:
            feats = feats.view(feats.size(0), -1)
        return self.proj(feats)

    def freeze_backbone(self) -> None:
        for p in self.backbone.parameters():
            p.requires_grad_(False)

    def unfreeze_backbone(self) -> None:
        for p in self.backbone.parameters():
            p.requires_grad_(True)


class ViTBackbone(nn.Module):
    """ViT-B/16 backbone (timm). 默认 frozen encoder. 输出 CLS token."""
    def __init__(self, pretrained: bool = True, out_dim: int = 256, freeze: bool = True) -> None:
        super().__init__()
        try:
            import timm
        except ImportError:
            raise ImportError("ViT backbone requires timm: pip install timm")
        self.backbone = timm.create_model("vit_base_patch16_224", pretrained=pretrained, num_classes=0)
        in_features = self.backbone.embed_dim  # 768
        self.out_dim = int(out_dim)
        self.proj = nn.Sequential(
            nn.Linear(in_features, int(out_dim)),
            nn.BatchNorm1d(int(out_dim)),
            nn.ReLU(inplace=True),
            nn.Dropout(0.2),
        )
        if freeze:
            self.freeze_backbone()

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        feats = self.backbone(x)
        if feats.ndim > 2:
            feats = feats.view(feats.size(0), -1)
        return self.proj(feats)

    def freeze_backbone(self) -> None:
        for p in self.backbone.parameters():
            p.requires_grad_(False)

    def unfreeze_backbone(self) -> None:
        for p in self.backbone.parameters():
            p.requires_grad_(True)


class SwinTBackbone(nn.Module):
    """Swin-Tiny backbone (timm). 默认 frozen encoder."""
    def __init__(self, pretrained: bool = True, out_dim: int = 256, freeze: bool = True) -> None:
        super().__init__()
        try:
            import timm
        except ImportError:
            raise ImportError("Swin backbone requires timm: pip install timm")
        self.backbone = timm.create_model("swin_tiny_patch4_window7_224", pretrained=pretrained, num_classes=0)
        in_features = self.backbone.num_features  # 768
        self.out_dim = int(out_dim)
        self.proj = nn.Sequential(
            nn.Linear(in_features, int(out_dim)),
            nn.BatchNorm1d(int(out_dim)),
            nn.ReLU(inplace=True),
            nn.Dropout(0.2),
        )
        if freeze:
            self.freeze_backbone()

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        feats = self.backbone(x)
        if feats.ndim > 2:
            feats = feats.view(feats.size(0), -1)
        return self.proj(feats)

    def freeze_backbone(self) -> None:
        for p in self.backbone.parameters():
            p.requires_grad_(False)

    def unfreeze_backbone(self) -> None:
        for p in self.backbone.parameters():
            p.requires_grad_(True)


class CLIPBackbone(nn.Module):
    """CLIP ViT-B/32 visual encoder (open_clip). 默认 frozen."""
    def __init__(self, pretrained: bool = True, out_dim: int = 256, freeze: bool = True) -> None:
        super().__init__()
        try:
            import open_clip
        except ImportError:
            raise ImportError("CLIP backbone requires open_clip: pip install open_clip_torch")
        self.clip_model, _, _ = open_clip.create_model_and_transforms(
            "ViT-B-32", pretrained="openai" if pretrained else None
        )
        self.visual = self.clip_model.visual
        in_features = self.visual.output_dim  # 512
        self.out_dim = int(out_dim)
        self.proj = nn.Sequential(
            nn.Linear(in_features, int(out_dim)),
            nn.BatchNorm1d(int(out_dim)),
            nn.ReLU(inplace=True),
            nn.Dropout(0.2),
        )
        if freeze:
            self.freeze_backbone()

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        feats = self.visual(x)
        if feats.ndim > 2:
            feats = feats.view(feats.size(0), -1)
        return self.proj(feats)

    def freeze_backbone(self) -> None:
        for p in self.visual.parameters():
            p.requires_grad_(False)

    def unfreeze_backbone(self) -> None:
        for p in self.visual.parameters():
            p.requires_grad_(True)


# ============================================================
# Backbone 工厂函数 (统一接口)
# ============================================================

def create_backbone(
    backbone_name: str, pretrained: bool = True, feature_dim: int = 256, freeze: bool = False
) -> nn.Module:
    """根据名称创建 backbone 实例，统一返回 nn.Module with .out_dim."""
    bn = str(backbone_name).lower().strip()
    if bn == "simple_cnn":
        return SimpleCNNBackbone(in_channels=3, out_dim=feature_dim)
    elif bn in ("mobilenet_v3_small", "mobilenet_v3s"):
        return MobileNetV3Backbone(variant="small", pretrained=pretrained, out_dim=feature_dim)
    elif bn in ("mobilenet_v3_large", "mobilenet_v3l"):
        return MobileNetV3Backbone(variant="large", pretrained=pretrained, out_dim=feature_dim)
    elif bn in ("vit_b_16", "vit_b16", "vit"):
        return ViTBackbone(pretrained=pretrained, out_dim=feature_dim, freeze=freeze)
    elif bn in ("swin_t", "swin_tiny"):
        return SwinTBackbone(pretrained=pretrained, out_dim=feature_dim, freeze=freeze)
    elif bn in ("clip_vit_b32", "clip"):
        return CLIPBackbone(pretrained=pretrained, out_dim=feature_dim, freeze=freeze)
    else:
        raise ValueError(
            f"Unknown backbone: {backbone_name!r}. "
            f"Supported: simple_cnn, mobilenet_v3_small, mobilenet_v3_large, "
            f"vit_b_16, swin_t, clip_vit_b32"
        )

