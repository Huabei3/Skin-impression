from __future__ import annotations

import torch
import torch.nn as nn


class TwoStreamFusion(nn.Module):
    """
    Two-stream fusion (face + global), without statistical stream.
    门控加权融合: gate = Softmax(MLP([face; global])) → w[0]*face + w[1]*global
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


class SimpleConcatFusion(nn.Module):
    """
    Ablation-2: 简单 concat 融合（替换门控融合）。
    face + global → concat → Linear(512→256) → BN → ReLU → Dropout
    """

    def __init__(self, face_dim: int, global_dim: int, fusion_dim: int = 256, dropout: float = 0.3) -> None:
        super().__init__()
        self.concat_mlp = nn.Sequential(
            nn.Linear(face_dim + global_dim, fusion_dim),
            nn.BatchNorm1d(fusion_dim),
            nn.ReLU(inplace=True),
            nn.Dropout(dropout),
        )

    def forward(self, face_features: torch.Tensor, global_features: torch.Tensor) -> torch.Tensor:
        concat = torch.cat([face_features, global_features], dim=1)
        return self.concat_mlp(concat)

