from __future__ import annotations

from typing import Dict, List, Optional

import torch
import torch.nn as nn

from .face_stream import AttentiveFaceStream, FaceStream, FaceStreamV2, FaceStreamV3
from .fusion import TwoStreamFusion
from .global_stream import GlobalStream
from .heads import ScoreHead, MultiScoreHead


class PredictPNetwork(nn.Module):
    """
    predict_p standalone network.

Outputs:
  - score_logits: (B, 1)       (single-head)
  - score_logits: (B, num_heads) (multi-head, when MULTI_HEAD=True)
"""

    def __init__(
        self,
        config: Dict,
        use_attention: bool = True,
        model_variant: str = "v1",
        multi_head: bool = False,
        attribute_names: Optional[List[str]] = None,
    ) -> None:
        super().__init__()
        self.config = config
        self.use_attention = use_attention
        self.model_variant = str(model_variant).lower().strip()
        self.multi_head = bool(multi_head)

        if self.model_variant == "v1":
            if use_attention:
                self.face_stream = AttentiveFaceStream(config)
            else:
                self.face_stream = FaceStream(config)
        elif self.model_variant == "v2":
            self.face_stream = FaceStreamV2(config)
        elif self.model_variant == "v3":
            self.face_stream = FaceStreamV3(config)
        else:
            raise ValueError(f"Unsupported model_variant for predict_p: {self.model_variant!r}")
        self.global_stream = GlobalStream(config)

        fusion_cfg = config["MODEL"]["fusion"]
        fusion_dim = int(fusion_cfg["fusion_dim"])
        dropout = float(fusion_cfg.get("dropout", 0.3))
        self.fusion = TwoStreamFusion(
            face_dim=self.face_stream.output_dim,
            global_dim=self.global_stream.output_dim,
            fusion_dim=fusion_dim,
            dropout=dropout,
        )

        head_cfg = config["MODEL"]["prediction_heads"]["preference_score"]
        hidden_dims = list(head_cfg.get("hidden_dims", [128, 64]))

        if self.multi_head and attribute_names:
            self.score_head = MultiScoreHead(
                input_dim=fusion_dim,
                hidden_dims=hidden_dims,
                attribute_names=list(attribute_names),
            )
            self._attribute_names = list(attribute_names)
        else:
            self.score_head = ScoreHead(
                input_dim=fusion_dim,
                hidden_dims=hidden_dims,
                output_dim=int(head_cfg.get("output_dim", 1)),
            )
            self._attribute_names = []

        self._initialize_weights()

    @property
    def is_multi_head(self) -> bool:
        return bool(self.multi_head and len(self._attribute_names) > 0)

    @property
    def attribute_names(self) -> List[str]:
        return list(self._attribute_names)

    @property
    def output_dim(self) -> int:
        """输出维度：单头=1，多头=属性数。"""
        if hasattr(self.score_head, "output_dim"):
            return self.score_head.output_dim
        return 1

    def _initialize_weights(self) -> None:
        for m in self.modules():
            if isinstance(m, nn.Conv2d):
                nn.init.kaiming_normal_(m.weight, mode="fan_out", nonlinearity="relu")
                if m.bias is not None:
                    nn.init.constant_(m.bias, 0)
            elif isinstance(m, (nn.BatchNorm2d, nn.BatchNorm1d)):
                nn.init.constant_(m.weight, 1)
                nn.init.constant_(m.bias, 0)
            elif isinstance(m, nn.Linear):
                nn.init.normal_(m.weight, 0, 0.01)
                if m.bias is not None:
                    nn.init.constant_(m.bias, 0)

    def forward(
        self,
        face_rgb: torch.Tensor,
        face_uv: Optional[torch.Tensor],
        global_rgb: Optional[torch.Tensor] = None,
    ) -> torch.Tensor:
        """Forward pass.
        Returns:
            (B, 1)  if single-head
            (B, N)  if multi-head (N = len(attribute_names))
        """
        if self.model_variant == "v3":
            face_features = self.face_stream(face_rgb)
        else:
            if face_uv is None:
                raise ValueError(f"face_uv is required for model_variant={self.model_variant!r}")
            face_features = self.face_stream(face_rgb, face_uv)
        global_features = self.global_stream(global_rgb if global_rgb is not None else face_rgb)
        fused = self.fusion(face_features, global_features)
        return self.score_head(fused)

    def forward_single_head(self, fused: torch.Tensor, attribute_name: str) -> torch.Tensor:
        """单 head 推理（用于 test_only 按属性导出）。"""
        if hasattr(self.score_head, "forward_single"):
            return self.score_head.forward_single(fused, attribute_name)
        return self.score_head(fused)


def create_model(
    config: Dict,
    model_type: str = "full",
    use_attention: bool = True,
    model_variant: Optional[str] = None,
) -> nn.Module:
    if model_variant is None:
        model_variant = str(config.get("MODEL_VARIANT", "v1"))
    model_variant = str(model_variant).lower().strip()
    if model_type != "full":
        raise ValueError(f"Unsupported model_type for predict_p: {model_type}")
    multi_head = bool(config.get("MULTI_HEAD", False))
    attribute_names = config.get("ATTRIBUTE_HEAD_NAMES", None) or None
    return PredictPNetwork(
        config,
        use_attention=use_attention,
        model_variant=model_variant,
        multi_head=multi_head,
        attribute_names=attribute_names,
    )
