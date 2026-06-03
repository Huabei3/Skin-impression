from __future__ import annotations

from typing import Dict, Optional, Tuple

import torch
import torch.nn as nn


class ScoreOnlyLoss(nn.Module):
    """
    Score-only loss for predict_p.

    - BCEWithLogits (with optional extreme weighting)
    - SmoothL1 between sigmoid(logits) and target
    - Optional Pearson penalty to encourage correlation

    Supports multi-head: when pred_score_logits is (B, N) and target_score is (B, N),
    computes loss per head and returns mean.
    """

    def __init__(self, config: Dict):
        super().__init__()
        loss_cfg = config.get("LOSS", {}) or {}

        self.label_smoothing = float(loss_cfg.get("label_smoothing", 0.0))
        self.pearson_weight = float(loss_cfg.get("pearson_weight", 0.0))

        ew_cfg = loss_cfg.get("extreme_weighting", {}) or {}
        self.ew_enabled = bool(ew_cfg.get("enabled", True))
        self.ew_lambda = float(ew_cfg.get("lambda", 2.0))
        self.ew_gamma = float(ew_cfg.get("gamma", 2.0))

        self.bce_logits = nn.BCEWithLogitsLoss(reduction="none")
        self.smooth_l1 = nn.SmoothL1Loss(reduction="mean")

    @staticmethod
    def _maybe_normalize_target_score(target_score: torch.Tensor) -> torch.Tensor:
        if target_score.max() > 1.5:
            return target_score / 10.0
        return target_score

    def _apply_label_smoothing(self, y: torch.Tensor) -> torch.Tensor:
        if self.label_smoothing > 0:
            return y * (1 - self.label_smoothing) + 0.5 * self.label_smoothing
        return y

    @staticmethod
    def _pearson_corr(x: torch.Tensor, y: torch.Tensor) -> torch.Tensor:
        x = x.view(-1)
        y = y.view(-1)
        vx = x - x.mean()
        vy = y - y.mean()
        var_x = (vx * vx).mean()
        var_y = (vy * vy).mean()
        eps = 1e-8
        denom = (var_x * var_y).sqrt().clamp_min(eps)
        cov = (vx * vy).mean()
        corr = cov / denom
        return corr.clamp(-1.0, 1.0)

    def _single_head_loss(
        self,
        pred_score_logits: torch.Tensor,
        target_score: torch.Tensor,
    ) -> Tuple[torch.Tensor, float, float]:
        """计算单个 head 的 loss。返回 (total, score_loss_val, pearson_loss_val)。"""
        target_score = self._maybe_normalize_target_score(target_score)
        target_for_corr = target_score
        target_score = self._apply_label_smoothing(target_score)

        if self.ew_enabled:
            with torch.no_grad():
                w = 1.0 + self.ew_lambda * torch.pow(torch.abs(target_score - 0.5) / 0.5, self.ew_gamma)
        else:
            w = torch.ones_like(target_score)

        bce_vec = self.bce_logits(pred_score_logits, target_score)
        bce = (bce_vec * w).mean()

        pred_prob = torch.sigmoid(pred_score_logits)
        reg = self.smooth_l1(pred_prob, target_score)
        score_loss = 0.5 * bce + 0.5 * reg

        pearson_loss_val = 0.0
        if self.pearson_weight > 0.0 and pred_prob.numel() > 1:
            corr = self._pearson_corr(pred_prob, target_for_corr)
            if torch.isfinite(corr):
                pearson_loss_val = float((1.0 - corr).item())

        total = score_loss + self.pearson_weight * pearson_loss_val
        return total, float(score_loss.item()), pearson_loss_val

    def forward(
        self,
        pred_score_logits: torch.Tensor,
        target_score: torch.Tensor,
        mask: Optional[torch.Tensor] = None,
    ) -> Tuple[torch.Tensor, Dict[str, float]]:
        """
        Args:
            pred_score_logits: (B, 1) or (B, N) for multi-head
            target_score: (B, 1) or (B, N), matching pred shape
            mask: (B, N) optional valid_mask, 1=valid, 0=NaN.
                  Used in loss_mask mode to ignore NaN positions.
        Returns:
            total_loss, loss_dict
        """
        use_mask = mask is not None and mask.any()
        # --- 多头：逐 head 计算取平均 ---
        if pred_score_logits.dim() == 2 and pred_score_logits.shape[1] > 1:
            num_heads = pred_score_logits.shape[1]
            # target 形状兼容：(B,) → (B,1)；或 (B,N) 直接匹配
            if target_score.dim() == 1:
                target_score = target_score.unsqueeze(1)
            if target_score.shape[1] == 1 and num_heads > 1:
                # 所有 head 共享同一个 target（fallback）
                target_score = target_score.expand(-1, num_heads)

            total = pred_score_logits.new_tensor(0.0)
            score_sum = 0.0
            pearson_sum = 0.0
            valid_heads = 0
            for i in range(num_heads):
                head_loss, s_val, p_val = self._single_head_loss(
                    pred_score_logits[:, i:i+1],
                    target_score[:, i:i+1],
                )
                if use_mask:
                    head_mask = mask[:, i]          # (B,)
                    valid_count = head_mask.sum()
                    if valid_count == 0:
                        continue                     # 该 head 全 NaN，跳过
                    head_loss = head_loss * (valid_count / head_mask.shape[0])
                total = total + head_loss
                score_sum += s_val
                pearson_sum += p_val
                valid_heads += 1
            total = total / max(valid_heads, 1)
            return total, {
                "total": float(total.item()),
                "score": score_sum / max(valid_heads, 1),
                "pearson": pearson_sum / max(valid_heads, 1),
            }

        # --- 单头（原始逻辑） ---
        total, s_val, p_val = self._single_head_loss(pred_score_logits, target_score)
        return total, {
            "total": float(total.item()),
            "score": s_val,
            "pearson": p_val,
        }

