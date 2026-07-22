"""
Scale-Interaction Transformer (SIT) — Hybrid CNN-Transformer for Facial Beauty Prediction.

Reference: Boukhari, "SCALE-INTERACTION TRANSFORMER: A HYBRID CNN-TRANSFORMER MODEL
FOR FACIAL BEAUTY PREDICTION", September 2025.

Architecture:
  RGB Image → Lightweight CNN Backbone → Multi-Scale Conv (3×3, 5×5, 7×7)
  → [CLS] + Position Embedding → Transformer Encoder × N → [CLS] → MLP Head → Score

Adapted for deepskin:
  - Supports multi-head prediction (10 attributes)
  - Integrates with existing face/global stream pipeline via SITPredictPNetwork
  - Uses depth-wise separable convs for the multi-scale module (parameter efficient)
"""
from __future__ import annotations

import math
from typing import Dict, List, Optional

import torch
import torch.nn as nn
import torch.nn.functional as F


# ============================================================
# Positional Encoding
# ============================================================

class LearnablePositionalEncoding(nn.Module):
    """Learnable position embeddings for Transformer input."""

    def __init__(self, num_tokens: int, d_model: int) -> None:
        super().__init__()
        self.pos_embed = nn.Parameter(torch.randn(1, num_tokens, d_model) * 0.02)

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        return x + self.pos_embed


# ============================================================
# Multi-Scale Convolution Module
# ============================================================

class MultiScaleConv(nn.Module):
    """Multi-scale feature extraction with parallel depth-wise separable convolutions.

    Uses three kernel sizes (3×3, 5×5, 7×7) to capture facial features at different
    receptive fields: fine texture (3×3), local structure (5×5), global layout (7×7).
    """

    def __init__(self, in_channels: int, d_model: int = 128, reduction: int = 4) -> None:
        """
        Args:
            in_channels: Input channel count from backbone.
            d_model: Transformer hidden dimension.
            reduction: Channel reduction factor for bottleneck (reduces param count).
        """
        super().__init__()
        mid_channels = max(d_model // reduction, 16)

        # Bottleneck: reduce channel count first
        self.bottleneck = nn.Sequential(
            nn.Conv2d(in_channels, mid_channels, kernel_size=1, bias=False),
            nn.BatchNorm2d(mid_channels),
            nn.ReLU(inplace=True),
        )

        kernel_sizes = [3, 5, 7]
        self.convs = nn.ModuleList()
        for k in kernel_sizes:
            self.convs.append(
                nn.Sequential(
                    # Depth-wise
                    nn.Conv2d(mid_channels, mid_channels, kernel_size=k,
                              padding=k // 2, groups=mid_channels, bias=False),
                    nn.BatchNorm2d(mid_channels),
                    nn.ReLU(inplace=True),
                    # Point-wise
                    nn.Conv2d(mid_channels, d_model, kernel_size=1, bias=False),
                    nn.BatchNorm2d(d_model),
                    nn.ReLU(inplace=True),
                )
            )

        # After GAP, project each scale to d_model
        self.scale_proj = nn.ModuleList([
            nn.Linear(d_model, d_model) for _ in kernel_sizes
        ])

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        """
        Args:
            x: (B, C, H, W) feature map from backbone.
        Returns:
            scale_tokens: (B, num_scales, d_model).
        """
        x = self.bottleneck(x)                       # (B, mid, H, W)
        scale_tokens = []
        for conv, proj in zip(self.convs, self.scale_proj):
            feat = conv(x)                            # (B, d_model, H, W)
            feat = F.adaptive_avg_pool2d(feat, 1)     # (B, d_model, 1, 1)
            feat = feat.flatten(1)                    # (B, d_model)
            feat = proj(feat)                         # (B, d_model)
            scale_tokens.append(feat)
        return torch.stack(scale_tokens, dim=1)       # (B, num_scales, d_model)


# ============================================================
# Transformer Encoder
# ============================================================

class TransformerEncoderLayer(nn.Module):
    """Single Transformer encoder layer (Pre-LN style)."""

    def __init__(self, d_model: int, nhead: int, dim_feedforward: int = 512,
                 dropout: float = 0.1) -> None:
        super().__init__()
        self.norm1 = nn.LayerNorm(d_model)
        self.self_attn = nn.MultiheadAttention(
            d_model, nhead, dropout=dropout, batch_first=True,
        )
        self.norm2 = nn.LayerNorm(d_model)
        self.ffn = nn.Sequential(
            nn.Linear(d_model, dim_feedforward),
            nn.GELU(),
            nn.Dropout(dropout),
            nn.Linear(dim_feedforward, d_model),
            nn.Dropout(dropout),
        )

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        # Self-Attention (Pre-LN)
        x = x + self.self_attn(self.norm1(x), self.norm1(x), self.norm1(x))[0]
        # FFN (Pre-LN)
        x = x + self.ffn(self.norm2(x))
        return x


class ScaleInteractionTransformer(nn.Module):
    """Transformer encoder that models cross-scale interactions.

    Takes multi-scale tokens + [CLS] token → self-attention → returns [CLS] output.
    """

    def __init__(self, d_model: int = 128, nhead: int = 4, num_layers: int = 4,
                 dim_feedforward: int = 256, dropout: float = 0.1,
                 num_scales: int = 3) -> None:
        super().__init__()
        self.d_model = d_model
        self.num_scales = num_scales

        # Learnable [CLS] token
        self.cls_token = nn.Parameter(torch.randn(1, 1, d_model) * 0.02)

        # Learnable position embedding for [CLS] + scale_tokens
        self.pos_encoding = LearnablePositionalEncoding(num_tokens=1 + num_scales, d_model=d_model)

        # Transformer encoder layers
        self.layers = nn.ModuleList([
            TransformerEncoderLayer(d_model, nhead, dim_feedforward, dropout)
            for _ in range(num_layers)
        ])
        self.norm = nn.LayerNorm(d_model)

    def forward(self, scale_tokens: torch.Tensor) -> torch.Tensor:
        """
        Args:
            scale_tokens: (B, num_scales, d_model).
        Returns:
            cls_out: (B, d_model) — [CLS] token output after Transformer.
        """
        B = scale_tokens.shape[0]
        cls_tokens = self.cls_token.expand(B, -1, -1)  # (B, 1, d_model)
        x = torch.cat([cls_tokens, scale_tokens], dim=1)  # (B, 1+num_scales, d_model)
        x = self.pos_encoding(x)

        for layer in self.layers:
            x = layer(x)

        x = self.norm(x)
        return x[:, 0, :]  # [CLS] token


# ============================================================
# SIT Backbone (standalone version, for single-image prediction)
# ============================================================

class SITBackbone(nn.Module):
    """Complete Scale-Interaction Transformer backbone.

    This is the standalone SIT model as described in the paper, adapted for deepskin.
    Can be used as a replacement for any existing backbone (face, global).

    Architecture:
      Input → Stem CNN → MultiScaleConv → Transformer → [CLS] → MLP Head → Score
    """

    def __init__(self, config: Dict) -> None:
        """
        Args:
            config: Configuration dictionary. Uses keys:
                - SIT_IN_CHANNELS: Input channels (default 3 for RGB).
                - SIT_STEM_CHANNELS: Stem output channels (default 32).
                - SIT_D_MODEL: Transformer hidden dim (default 128).
                - SIT_NHEAD: Number of attention heads (default 4).
                - SIT_NUM_LAYERS: Transformer encoder layers (default 4).
                - SIT_DIM_FF: Feed-forward hidden dim (default 256).
                - SIT_DROPOUT: Dropout rate (default 0.1).
                - SIT_OUTPUT_DIM: Output feature dim (default 256, for compatibility).
        """
        super().__init__()
        sit_cfg = config.get("SIT", {})
        in_channels = int(sit_cfg.get("IN_CHANNELS", config.get("SIT_IN_CHANNELS", 3)))
        stem_channels = int(sit_cfg.get("STEM_CHANNELS", config.get("SIT_STEM_CHANNELS", 32)))
        d_model = int(sit_cfg.get("D_MODEL", config.get("SIT_D_MODEL", 128)))
        nhead = int(sit_cfg.get("NHEAD", config.get("SIT_NHEAD", 4)))
        num_layers = int(sit_cfg.get("NUM_LAYERS", config.get("SIT_NUM_LAYERS", 4)))
        dim_ff = int(sit_cfg.get("DIM_FF", config.get("SIT_DIM_FF", 256)))
        dropout = float(sit_cfg.get("DROPOUT", config.get("SIT_DROPOUT", 0.1)))
        self.output_dim = int(sit_cfg.get("OUTPUT_DIM", config.get("SIT_OUTPUT_DIM", 256)))

        # --- Stem CNN (initial feature extraction) ---
        self.stem = nn.Sequential(
            nn.Conv2d(in_channels, stem_channels, kernel_size=7, stride=2, padding=3, bias=False),
            nn.BatchNorm2d(stem_channels),
            nn.ReLU(inplace=True),
            nn.Conv2d(stem_channels, stem_channels, kernel_size=3, stride=2, padding=1,
                      groups=stem_channels, bias=False),
            nn.BatchNorm2d(stem_channels),
            nn.ReLU(inplace=True),
            nn.Conv2d(stem_channels, stem_channels * 2, kernel_size=1, bias=False),
            nn.BatchNorm2d(stem_channels * 2),
            nn.ReLU(inplace=True),
        )
        stem_out = stem_channels * 2

        # --- Multi-Scale Convolution Module ---
        self.multi_scale = MultiScaleConv(
            in_channels=stem_out, d_model=d_model, reduction=4,
        )

        # --- Scale-Interaction Transformer ---
        self.transformer = ScaleInteractionTransformer(
            d_model=d_model, nhead=nhead, num_layers=num_layers,
            dim_feedforward=dim_ff, dropout=dropout, num_scales=3,
        )

        # --- Output projection (to match existing pipeline dimensions) ---
        self.out_proj = nn.Sequential(
            nn.Linear(d_model, self.output_dim),
            nn.BatchNorm1d(self.output_dim),
            nn.ReLU(inplace=True),
            nn.Dropout(dropout),
        )

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        """
        Args:
            x: (B, C, H, W) input image tensor.
        Returns:
            features: (B, output_dim) extracted features.
        """
        x = self.stem(x)                              # (B, stem_out*2, H/4, W/4)
        scale_tokens = self.multi_scale(x)            # (B, 3, d_model)
        cls_out = self.transformer(scale_tokens)      # (B, d_model)
        return self.out_proj(cls_out)                 # (B, output_dim)


# ============================================================
# SIT Stream (Face/Global stream using SIT backbone)
# ============================================================

class SITStream(nn.Module):
    """A face/global stream backed by the SIT model.

    Replaces the standard CNN backbone + projection with SIT's multi-scale +
    transformer architecture, but keeps the output dimension compatible with
    the existing two-stream fusion pipeline.
    """

    def __init__(self, config: Dict, stream_type: str = "face") -> None:
        """
        Args:
            config: Configuration dictionary.
            stream_type: "face" or "global" — affects which config section is read.
        """
        super().__init__()
        self.stream_type = stream_type

        if stream_type == "face":
            stream_cfg = config["MODEL"]["face_stream"]
            # Use SIT config or derive from face_stream
            sit_cfg = config.get("SIT", {})
            input_dim = 3
        else:
            stream_cfg = config["MODEL"]["global_stream"]
            sit_cfg = config.get("SIT", {})
            input_dim = 3

        d_model = int(sit_cfg.get("D_MODEL", config.get("SIT_D_MODEL", 128)))
        nhead = int(sit_cfg.get("NHEAD", config.get("SIT_NHEAD", 4)))
        num_layers = int(sit_cfg.get("NUM_LAYERS", config.get("SIT_NUM_LAYERS", 4)))
        dim_ff = int(sit_cfg.get("DIM_FF", config.get("SIT_DIM_FF", 256)))
        dropout = float(sit_cfg.get("DROPOUT", config.get("SIT_DROPOUT", 0.1)))

        # Override SIT config with stream-specific settings if present
        if "sit_d_model" in stream_cfg:
            d_model = int(stream_cfg["sit_d_model"])
        if "sit_nhead" in stream_cfg:
            nhead = int(stream_cfg["sit_nhead"])
        if "sit_num_layers" in stream_cfg:
            num_layers = int(stream_cfg["sit_num_layers"])

        # Output dimension must match existing fusion module's expectation
        self.output_dim = int(stream_cfg.get("feature_dim", 256))

        # Build SIT backbone for 3-channel RGB input
        sit_config_for_backbone = {
            "SIT_IN_CHANNELS": input_dim,
            "SIT_D_MODEL": d_model,
            "SIT_NHEAD": nhead,
            "SIT_NUM_LAYERS": num_layers,
            "SIT_DIM_FF": dim_ff,
            "SIT_DROPOUT": dropout,
            "SIT_OUTPUT_DIM": self.output_dim,
        }
        self.backbone = SITBackbone(sit_config_for_backbone)

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        """x: (B, 3, H, W) → (B, output_dim)."""
        return self.backbone(x)


# ============================================================
# PredictPNetwork with SIT Backbone
# ============================================================

class SITPredictPNetwork(nn.Module):
    """PredictP network variant using SIT backbone for face and/or global stream.

    Supports:
      - SIT as face stream only, global stream can be standard CNN or SIT.
      - Multi-head prediction (10 attribute scores) with loss_mask support.
      - Backward compatible: when MULTI_HEAD=False, behaves like single-head.
      - Statistical stream (optional, for ablation).

    Usage:
      Set config["MODEL_BACKBONE"] = "sit" to use this network.
    """

    def __init__(self, config: Dict) -> None:
        super().__init__()
        self.config = config

        # --- Determine which streams use SIT ---
        sit_cfg = config.get("SIT", {})
        sit_face = bool(sit_cfg.get("USE_SIT_FACE", config.get("SIT_USE_FACE", True)))
        sit_global = bool(sit_cfg.get("USE_SIT_GLOBAL", config.get("SIT_USE_GLOBAL", True)))

        from .face_stream import AttentiveFaceStream, FaceStreamV3
        from .global_stream import GlobalStream
        from .fusion import TwoStreamFusion, create_fusion
        from .heads import ScoreHead

        # --- Face Stream ---
        if sit_face:
            self.face_stream = SITStream(config, stream_type="face")
        else:
            # Fallback to standard face stream
            model_variant = str(config.get("MODEL_VARIANT", "v1")).lower().strip()
            if model_variant == "v3":
                self.face_stream = FaceStreamV3(config)
            else:
                self.face_stream = AttentiveFaceStream(config)

        # --- Global Stream ---
        if sit_global:
            self.global_stream = SITStream(config, stream_type="global")
        else:
            self.global_stream = GlobalStream(config)

        # --- Fusion ---
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

        # --- Statistical Stream (optional) ---
        self._stat_enabled = bool(config.get("ABLATION_STAT_STREAM", False))
        if self._stat_enabled:
            from .stat_stream import StatisticalStream
            self.stat_stream = StatisticalStream(
                input_dim=11, hidden_dim=64, output_dim=128, dropout=dropout,
            )
            self.stat_merge = nn.Sequential(
                nn.Linear(fusion_dim + 128, fusion_dim),
                nn.BatchNorm1d(fusion_dim),
                nn.ReLU(inplace=True),
                nn.Dropout(dropout),
            )
            head_input_dim = fusion_dim
        else:
            head_input_dim = fusion_dim

        # --- Multi-head / Single-head ---
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
        else:
            head_cfg = config["MODEL"]["prediction_heads"]["preference_score"]
            self.score_head = ScoreHead(
                input_dim=head_input_dim,
                hidden_dims=list(head_cfg.get("hidden_dims", [128, 64])),
                output_dim=int(head_cfg.get("output_dim", 1)),
            )
            self._attribute_names = []

        # --- A9: Lab center regression heads ---
        self._lab_center_enabled = bool(config.get("ABLATION_LAB_CENTER", False))
        if self._lab_center_enabled and self._multi_head_enabled:
            center_cfg = config["MODEL"]["prediction_heads"].get(
                "lab_center",
                config["MODEL"]["prediction_heads"]["preference_score"],
            )
            centers = {}
            for name in self._attribute_names:
                centers[name] = ScoreHead(
                    input_dim=head_input_dim,
                    hidden_dims=list(center_cfg.get("hidden_dims", [128, 64])),
                    output_dim=3,
                )
            self.center_heads = nn.ModuleDict(centers)

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
        face_uv: Optional[torch.Tensor] = None,
        global_rgb: Optional[torch.Tensor] = None,
        stat_features: Optional[torch.Tensor] = None,
    ) -> torch.Tensor:
        # Face stream: SIT only needs RGB input (no UV)
        face_features = self.face_stream(face_rgb)
        # Global stream
        global_features = self.global_stream(global_rgb if global_rgb is not None else face_rgb)
        # Fusion
        fused = self.fusion(face_features, global_features)

        # Statistical stream (optional)
        if self._stat_enabled and stat_features is not None:
            stat = self.stat_stream(stat_features)
            fused = torch.cat([fused, stat], dim=1)
            fused = self.stat_merge(fused)

        # Multi-head or single-head
        if self._multi_head_enabled:
            outputs = []
            for name in self._attribute_names:
                outputs.append(self.score_heads[name](fused))
            scores = torch.cat(outputs, dim=1)  # (B, N_attrs)
            if self._lab_center_enabled:
                center_outs = []
                for name in self._attribute_names:
                    center_outs.append(self.center_heads[name](fused))
                centers = torch.cat(center_outs, dim=1)
                return scores, centers
            return scores
        else:
            return self.score_head(fused)
