from __future__ import annotations

from typing import Dict, Tuple

import torch
import torch.nn as nn


class ScoreOnlyLoss(nn.Module):
    """
    Score-only loss for predict_p.

    - BCEWithLogits (with optional extreme weighting)
    - SmoothL1 between sigmoid(logits) and target
    - Optional Pearson penalty to encourage correlation
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

    def forward(self, pred_score_logits: torch.Tensor, target_score: torch.Tensor) -> Tuple[torch.Tensor, Dict[str, float]]:
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

        pearson_loss = pred_score_logits.new_tensor(0.0)
        if self.pearson_weight > 0.0 and pred_prob.numel() > 1:
            corr = self._pearson_corr(pred_prob, target_for_corr)
            if torch.isfinite(corr):
                pearson_loss = 1.0 - corr

        total = score_loss + self.pearson_weight * pearson_loss
        return total, {
            "total": float(total.item()),
            "score": float(score_loss.item()),
            "pearson": float(pearson_loss.item()),
        }

