from __future__ import annotations

from typing import Dict, List, Optional

import torch
import torch.nn as nn

from .face_stream import AttentiveFaceStream, FaceStream, FaceStreamV2, FaceStreamV3
from .fusion import TwoStreamFusion, create_fusion
from .global_stream import GlobalStream
from .heads import ScoreHead
from .stat_stream import StatisticalStream


class PredictPNetwork(nn.Module):
    """
    predict_p standalone network.

    Supports:
      - Single-head (default): self.score_head → (B, 1)
      - Multi-head (MULTI_HEAD=True): self.score_heads (ModuleDict) → (B, N)
      - Statistical Stream (ABLATION_STAT_STREAM=True): metadata → stat features fused before head
    """

    def __init__(self, config: Dict, use_attention: bool = True, model_variant: str = "v1") -> None:
        super().__init__()
        self.config = config
        self.use_attention = use_attention
        self.model_variant = str(model_variant).lower().strip()

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

        # ===== Phase 0: 通过 ABLATION_FUSION_TYPE 选择融合模块 =====
        fusion_type = str(config.get("ABLATION_FUSION_TYPE", "gated")).lower().strip()
        fusion_cfg = config["MODEL"]["fusion"]
        fusion_dim = int(fusion_cfg["fusion_dim"])
        dropout = float(fusion_cfg.get("dropout", 0.3))

        if fusion_type in ("gated", "default", ""):
            self.fusion = TwoStreamFusion(
                face_dim=self.face_stream.output_dim,
                global_dim=self.global_stream.output_dim,
                fusion_dim=fusion_dim,
                dropout=dropout,
            )
        else:
            self.fusion = create_fusion(
                fusion_type=fusion_type,
                face_dim=self.face_stream.output_dim,
                global_dim=self.global_stream.output_dim,
                fusion_dim=fusion_dim,
                dropout=dropout,
            )
        # ============================================================

        # ===== Statistical Stream =====
        self._stat_enabled = bool(config.get("ABLATION_STAT_STREAM", False))
        if self._stat_enabled:
            self.stat_stream = StatisticalStream(
                input_dim=11, hidden_dim=64, output_dim=128, dropout=dropout,
            )
            # merge stat (128-D) + fused (256-D) → 256-D
            self.stat_merge = nn.Sequential(
                nn.Linear(fusion_dim + 128, fusion_dim),
                nn.BatchNorm1d(fusion_dim),
                nn.ReLU(inplace=True),
                nn.Dropout(dropout),
            )
            head_input_dim = fusion_dim
        else:
            head_input_dim = fusion_dim
        # ===============================

        # ===== Multi-head / Single-head =====
        self._multi_head_enabled = bool(config.get("MULTI_HEAD", False))
        if self._multi_head_enabled:
            attr_names: List[str] = list(config.get("ATTRIBUTE_HEAD_NAMES", []))
            if not attr_names:
                raise ValueError("MULTI_HEAD=True but ATTRIBUTE_HEAD_NAMES is empty")
            head_cfg = config["MODEL"]["prediction_heads"]["preference_score"]
            heads = {}
            for name in attr_names:
                heads[name] = ScoreHead(
                    input_dim=head_input_dim,
                    hidden_dims=list(head_cfg.get("hidden_dims", [128, 64])),
                    output_dim=int(head_cfg.get("output_dim", 1)),
                )
            self.score_heads = nn.ModuleDict(heads)
            self._attribute_names = list(attr_names)
            self.score_head = self.score_heads[attr_names[0]]
        else:
            head_cfg = config["MODEL"]["prediction_heads"]["preference_score"]
            self.score_head = ScoreHead(
                input_dim=head_input_dim,
                hidden_dims=list(head_cfg.get("hidden_dims", [128, 64])),
                output_dim=int(head_cfg.get("output_dim", 1)),
            )
            self._attribute_names = []
        # ====================================

        # ===== A9: Lab center regression heads =====
        self._lab_center_enabled = bool(config.get("ABLATION_LAB_CENTER", False))
        if self._lab_center_enabled and self._multi_head_enabled:
            center_cfg = config["MODEL"]["prediction_heads"].get("lab_center",
                          config["MODEL"]["prediction_heads"]["preference_score"])
            centers = {}
            for name in self._attribute_names:
                centers[name] = ScoreHead(
                    input_dim=head_input_dim,
                    hidden_dims=list(center_cfg.get("hidden_dims", [128, 64])),
                    output_dim=3,  # L*, a*, b*
                )
            self.center_heads = nn.ModuleDict(centers)
        # ============================================

        self._initialize_weights()

    @property
    def is_multi_head(self) -> bool:
        return self._multi_head_enabled

    @property
    def attribute_names(self) -> List[str]:
        return list(self._attribute_names)

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
        stat_features: Optional[torch.Tensor] = None,
    ) -> torch.Tensor:
        if self.model_variant == "v3":
            face_features = self.face_stream(face_rgb)
        else:
            if face_uv is None:
                raise ValueError(f"face_uv is required for model_variant={self.model_variant!r}")
            face_features = self.face_stream(face_rgb, face_uv)
        global_features = self.global_stream(global_rgb if global_rgb is not None else face_rgb)
        fused = self.fusion(face_features, global_features)

        # ===== Statistical Stream: concat metadata after fusion =====
        if self._stat_enabled and stat_features is not None:
            stat = self.stat_stream(stat_features)       # (B, 128)
            fused = torch.cat([fused, stat], dim=1)      # (B, 256+128)
            fused = self.stat_merge(fused)               # (B, 256)
        # ==============================================================

        if self._multi_head_enabled:
            outputs = []
            for name in self._attribute_names:
                outputs.append(self.score_heads[name](fused))
            scores =  torch.cat(outputs, dim=1)  # (B, N_attrs)
            if self._lab_center_enabled:
                center_outs = []
                for name in self._attribute_names:
                    center_outs.append(self.center_heads[name](fused))
                centers = torch.cat(center_outs, dim=1)  # (B, N_attrs*3)
                return scores, centers
            return scores
        else:
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
    return PredictPNetwork(config, use_attention=use_attention, model_variant=model_variant)
