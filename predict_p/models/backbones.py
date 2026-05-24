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

