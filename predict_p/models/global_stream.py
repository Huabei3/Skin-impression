"""
Global stream module (local copy for predict_p).

Statistical stream is intentionally NOT included here.
"""

from typing import Dict

import torch
import torch.nn as nn
import torchvision.models as models

from .backbones import SimpleCNNBackbone


class GlobalStream(nn.Module):
    def __init__(self, config: Dict):
        super().__init__()
        global_config = config["MODEL"]["global_stream"]
        backbone_name = global_config.get("backbone", "mobilenet_v3_small")
        pretrained = bool(global_config.get("pretrained", True))

        if backbone_name == "simple_cnn":
            feat_dim = int(global_config.get("feature_dim", 256))
            self.backbone = SimpleCNNBackbone(in_channels=3, out_dim=feat_dim)
            self.feature_projector = nn.Identity()
            self.output_dim = feat_dim
            return
        if backbone_name == "mobilenet_v3_small":
            self.backbone = models.mobilenet_v3_small(pretrained=pretrained)
            in_features = self.backbone.classifier[0].in_features
            self.backbone.classifier = nn.Identity()
        elif backbone_name == "mobilenet_v3_large":
            self.backbone = models.mobilenet_v3_large(pretrained=pretrained)
            in_features = self.backbone.classifier[0].in_features
            self.backbone.classifier = nn.Identity()
        elif backbone_name == "efficientnet_b0":
            self.backbone = models.efficientnet_b0(pretrained=pretrained)
            in_features = self.backbone.classifier[1].in_features
            self.backbone.classifier = nn.Identity()
        else:
            raise ValueError(f"Unsupported global backbone: {backbone_name}")

        feat_dim = int(global_config.get("feature_dim", 256))
        self.feature_projector = nn.Sequential(
            nn.Linear(in_features, feat_dim),
            nn.BatchNorm1d(feat_dim),
            nn.ReLU(inplace=True),
            nn.Dropout(0.2),
        )
        self.output_dim = feat_dim

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        features = self.backbone(x)
        if features.ndim > 2:
            features = features.view(features.size(0), -1)
        return self.feature_projector(features)
