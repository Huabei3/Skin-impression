from __future__ import annotations

from typing import Optional

import torch
import torch.nn as nn


class TwoStreamFusion(nn.Module):
    """
    Two-stream fusion (face + global), without statistical stream.
    """

    def __init__(self, face_dim: int, global_dim: int, fusion_dim: int = 256, dropout: float = 0.3) -> None:
        super().__init__()
        self.face_proj = nn.Linear(face_dim, fusion_dim)
        self.global_proj = nn.Linear(global_dim, fusion_dim)

        self.gate = nn.Sequential(
            nn.Linear(fusion_dim * 2, fusion_dim),
            nn.ReLU(inplace=True),
            nn.Linear(fusion_dim, 2),
            nn.Softmax(dim=1),
        )

        self.out = nn.Sequential(
            nn.Linear(fusion_dim, fusion_dim),
            nn.BatchNorm1d(fusion_dim),
            nn.ReLU(inplace=True),
            nn.Dropout(dropout),
        )

    def forward(self, face_features: torch.Tensor, global_features: torch.Tensor) -> torch.Tensor:
        f = self.face_proj(face_features)
        g = self.global_proj(global_features)
        w = self.gate(torch.cat([f, g], dim=1))
        fused = w[:, 0:1] * f + w[:, 1:2] * g
        return self.out(fused)


# ============================================================
# Phase 0 新增: SE-Gated + Cross-Attention 融合模块
# 通过 --ablation-fusion-type se_gated / cross_attn 选择
# 不加或设 gated → TwoStreamFusion (原有逻辑)
# ============================================================


class SEGatedFusion(nn.Module):
    """
    SE-Gated Fusion:
    在 gated 融合前加入 Squeeze-and-Excitation channel recalibration。
    concat(face, global) → SE recalibrate → gate → weighted sum → out.
    """
    def __init__(
        self, face_dim: int, global_dim: int, fusion_dim: int = 256,
        dropout: float = 0.3, se_reduction: int = 8,
    ) -> None:
        super().__init__()
        self.face_proj = nn.Linear(face_dim, fusion_dim)
        self.global_proj = nn.Linear(global_dim, fusion_dim)
        concat_dim = fusion_dim * 2

        # SE block: squeeze → excite → channel-wise recalibration
        bottleneck = max(concat_dim // se_reduction, 16)
        self.se = nn.Sequential(
            nn.Linear(concat_dim, bottleneck),
            nn.ReLU(inplace=True),
            nn.Linear(bottleneck, concat_dim),
            nn.Sigmoid(),
        )

        self.gate = nn.Sequential(
            nn.Linear(concat_dim, fusion_dim),
            nn.ReLU(inplace=True),
            nn.Linear(fusion_dim, 2),
            nn.Softmax(dim=1),
        )

        self.out = nn.Sequential(
            nn.Linear(fusion_dim, fusion_dim),
            nn.BatchNorm1d(fusion_dim),
            nn.ReLU(inplace=True),
            nn.Dropout(dropout),
        )

    def forward(self, face_features: torch.Tensor, global_features: torch.Tensor) -> torch.Tensor:
        f = self.face_proj(face_features)
        g = self.global_proj(global_features)
        concat = torch.cat([f, g], dim=1)

        # SE recalibration: channel-wise re-weighting
        se_weight = self.se(concat)
        concat = concat * se_weight

        w = self.gate(concat)
        fused = w[:, 0:1] * f + w[:, 1:2] * g
        return self.out(fused)


class CrossAttentionFusion(nn.Module):
    """
    Cross-Attention Fusion:
    face→global 和 global→face 双向交叉注意力，实现信息双向交换。
    Q_f = face·Wq_f, K_g = global·Wk_g, V_g = global·Wv_g  →  f' = attn·V_g
    Q_g = global·Wq_g, K_f = face·Wk_f, V_f = face·Wv_f    →  g' = attn·V_f
    concat(f', g') → FC → out.
    """
    def __init__(
        self, face_dim: int, global_dim: int, fusion_dim: int = 256,
        dropout: float = 0.3, num_heads: int = 4,
    ) -> None:
        super().__init__()
        self.face_proj = nn.Linear(face_dim, fusion_dim)
        self.global_proj = nn.Linear(global_dim, fusion_dim)
        self.num_heads = int(num_heads)
        self.head_dim = fusion_dim // self.num_heads
        assert fusion_dim % self.num_heads == 0, f"fusion_dim {fusion_dim} must be divisible by num_heads {num_heads}"

        # face→global cross-attention
        self.q_f = nn.Linear(fusion_dim, fusion_dim)
        self.k_g = nn.Linear(fusion_dim, fusion_dim)
        self.v_g = nn.Linear(fusion_dim, fusion_dim)

        # global→face cross-attention
        self.q_g = nn.Linear(fusion_dim, fusion_dim)
        self.k_f = nn.Linear(fusion_dim, fusion_dim)
        self.v_f = nn.Linear(fusion_dim, fusion_dim)

        self.out = nn.Sequential(
            nn.Linear(fusion_dim * 2, fusion_dim),
            nn.BatchNorm1d(fusion_dim),
            nn.ReLU(inplace=True),
            nn.Dropout(dropout),
        )

    def _cross_attn(self, q: torch.Tensor, k: torch.Tensor, v: torch.Tensor) -> torch.Tensor:
        """Multi-head cross-attention: softmax(Q·K^T/√d)·V."""
        B, D = q.shape
        H, d = self.num_heads, self.head_dim

        # reshape to (B, H, 1, d) and (B, H, 1, d)
        q = q.view(B, H, d).unsqueeze(2)    # (B, H, 1, d)
        k = k.view(B, H, d).unsqueeze(2)    # (B, H, 1, d)
        v = v.view(B, H, d).unsqueeze(2)    # (B, H, 1, d)

        attn = torch.matmul(q, k.transpose(-2, -1)) / (d ** 0.5)  # (B, H, 1, 1)
        attn = torch.softmax(attn, dim=-1)
        out = torch.matmul(attn, v)  # (B, H, 1, d)
        out = out.squeeze(2).reshape(B, D)  # (B, D)
        return out

    def forward(self, face_features: torch.Tensor, global_features: torch.Tensor) -> torch.Tensor:
        f = self.face_proj(face_features)   # (B, D)
        g = self.global_proj(global_features)  # (B, D)

        # face→global: face 查询 global 中的相关信息
        f2g = self._cross_attn(self.q_f(f), self.k_g(g), self.v_g(g))

        # global→face: global 查询 face 中的相关信息
        g2f = self._cross_attn(self.q_g(g), self.k_f(f), self.v_f(f))

        # concat 两种交叉特征
        fused = torch.cat([f2g, g2f], dim=1)  # (B, 2D)
        return self.out(fused)


# ============================================================
# Fusion 工厂函数
# ============================================================

def create_fusion(
    fusion_type: str,
    face_dim: int,
    global_dim: int,
    fusion_dim: int = 256,
    dropout: float = 0.3,
) -> nn.Module:
    """根据 fusion_type 创建融合模块。"""
    ft = str(fusion_type).lower().strip()
    if ft in ("gated", "default", ""):
        return TwoStreamFusion(face_dim, global_dim, fusion_dim, dropout)
    elif ft in ("concat",):
        # simple concat 沿用原有 TwoStreamFusion 但把 gate 返回平均权重
        # 这里用简化的 concat+MLP
        from collections import OrderedDict
        module = nn.Sequential(OrderedDict([
            ("face_proj", nn.Linear(face_dim, fusion_dim)),
            ("global_proj", nn.Linear(global_dim, fusion_dim)),
        ]))
        # 覆盖 forward: 在外部拼接，这里返回一个包装
        return _ConcatFusionWrapper(face_dim, global_dim, fusion_dim, dropout)
    elif ft in ("se_gated", "se"):
        return SEGatedFusion(face_dim, global_dim, fusion_dim, dropout)
    elif ft in ("cross_attn", "cross_attention", "crossattn"):
        return CrossAttentionFusion(face_dim, global_dim, fusion_dim, dropout)
    else:
        raise ValueError(f"Unknown fusion type: {fusion_type!r}. Supported: gated, concat, se_gated, cross_attn")


class _ConcatFusionWrapper(nn.Module):
    """Simple concat + MLP fusion (ablation baseline)."""
    def __init__(self, face_dim: int, global_dim: int, fusion_dim: int = 256, dropout: float = 0.3) -> None:
        super().__init__()
        self.face_proj = nn.Linear(face_dim, fusion_dim)
        self.global_proj = nn.Linear(global_dim, fusion_dim)
        self.out = nn.Sequential(
            nn.Linear(fusion_dim * 2, fusion_dim),
            nn.BatchNorm1d(fusion_dim),
            nn.ReLU(inplace=True),
            nn.Dropout(dropout),
        )

    def forward(self, face_features: torch.Tensor, global_features: torch.Tensor) -> torch.Tensor:
        f = self.face_proj(face_features)
        g = self.global_proj(global_features)
        return self.out(torch.cat([f, g], dim=1))

