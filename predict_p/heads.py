from __future__ import annotations

from typing import Dict, List, Optional

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


class MultiScoreHead(nn.Module):
    """多个 ScoreHead 并联，共享输入特征，各输出 1D 预测值。

    通过 nn.ModuleDict 管理多个 head，保证：
    - state_dict 中各 head 有独立命名空间
    - 可插拔：不传 attribute_names 时退化为单 ScoreHead 行为
    """

    def __init__(
        self,
        input_dim: int,
        hidden_dims: List[int],
        attribute_names: Optional[List[str]] = None,
    ) -> None:
        super().__init__()
        self.attribute_names: List[str] = list(attribute_names) if attribute_names else []
        self.num_heads = len(self.attribute_names)
        self._is_multi = self.num_heads > 0

        if self._is_multi:
            heads: Dict[str, ScoreHead] = {}
            for name in self.attribute_names:
                heads[name] = ScoreHead(
                    input_dim=input_dim,
                    hidden_dims=list(hidden_dims),
                    output_dim=1,
                )
            self.heads = nn.ModuleDict(heads)
        else:
            # 退化：用单 head，保持与旧逻辑兼容
            self.heads = nn.ModuleDict()  # 空占位
            self._fallback_head = ScoreHead(
                input_dim=input_dim,
                hidden_dims=list(hidden_dims),
                output_dim=1,
            )

    @property
    def output_dim(self) -> int:
        """返回输出维度（多头时=头数，单头时=1）。"""
        return self.num_heads if self._is_multi else 1

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        """
        Args:
            x: (B, input_dim) 融合后的特征
        Returns:
            (B, num_heads)  if multi-head
            (B, 1)           if single-head
        """
        if not self._is_multi:
            return self._fallback_head(x)

        outputs = []
        for name in self.attribute_names:
            head_out = self.heads[name](x)  # (B, 1)
            outputs.append(head_out)
        return torch.cat(outputs, dim=1)  # (B, num_heads)

    def forward_single(self, x: torch.Tensor, attribute_name: str) -> torch.Tensor:
        """按名称调用单个 head（用于 test_only 按属性单独导出）。"""
        if not self._is_multi:
            return self._fallback_head(x)
        return self.heads[attribute_name](x)

