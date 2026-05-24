from __future__ import annotations

from typing import List

import torch
import torch.nn as nn


class ScoreHead(nn.Module):
    def __init__(self, input_dim: int, hidden_dims: List[int], output_dim: int = 1) -> None:
        super().__init__()
        layers: List[nn.Module] = []
        in_dim = int(input_dim)
        for h in hidden_dims:
            layers.append(nn.Linear(in_dim, int(h)))
            layers.append(nn.BatchNorm1d(int(h)))
            layers.append(nn.ReLU(inplace=True))
            layers.append(nn.Dropout(0.3))
            in_dim = int(h)
        layers.append(nn.Linear(in_dim, int(output_dim)))
        self.net = nn.Sequential(*layers)

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        return self.net(x)

