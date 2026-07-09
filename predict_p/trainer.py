from __future__ import annotations

import json
import logging
import sys
from pathlib import Path
from typing import Dict, Optional

import numpy as np
import torch
import torch.nn as nn
import torch.optim as optim
from torch.cuda.amp import GradScaler, autocast
from torch.utils.tensorboard import SummaryWriter
from tqdm import tqdm

from .data.dataset import create_data_loaders

from .loss import ScoreOnlyLoss
from .metrics import evaluate_scores
from .models import create_model

logger = logging.getLogger(__name__)


class Trainer:
    def __init__(self, config: Dict, resume_path: Optional[str] = None, reset_feminine_head: bool = False):
        self.config = config
        self.device = torch.device(config.get("DEVICE", "cuda") if torch.cuda.is_available() else "cpu")
        self.resume_path = resume_path
        self._reset_feminine_head = reset_feminine_head

        self._setup_directories()

        logger.info("Loading datasets...")
        self.train_loader, self.val_loader, self.test_loader = create_data_loaders(self.config)
        logger.info(f"Train samples: {len(self.train_loader.dataset)}")
        logger.info(f"Val samples: {len(self.val_loader.dataset)}")
        logger.info(f"Test samples: {len(self.test_loader.dataset)}")

        model_variant = str(self.config.get("MODEL_VARIANT", "v1")).lower().strip()
        logger.info(f"Initializing model (predict_p:{model_variant}, no stat stream)...")
        self.model = create_model(self.config, model_type="full", use_attention=True, model_variant=model_variant).to(self.device)
        self.criterion = ScoreOnlyLoss(self.config)

        # 多 head 标记
        self._multi_head = bool(self.config.get("MULTI_HEAD", False)) and self.model.is_multi_head
        self._attribute_names = list(self.model.attribute_names) if self._multi_head else []
        # Statistical Stream
        self._stat_enabled = bool(self.config.get("ABLATION_STAT_STREAM", False))
        # A9: Lab center regression
        self._lab_center = bool(self.config.get("ABLATION_LAB_CENTER", False)) and self._multi_head
        if self._lab_center:
            self.center_l1 = nn.L1Loss(reduction="none")

        self._setup_optimizer()
        self._setup_scheduler()

        self.scaler = GradScaler() if self.config["TRAINING"].get("mixed_precision", True) else None
        self.writer: Optional[SummaryWriter] = None
        if bool(self.config.get("LOGGING", {}).get("tensorboard", True)):
            self.writer = SummaryWriter(log_dir=str(self.config["LOG_DIR"]))

        self.best_val_loss = float("inf")
        self.patience_counter = 0
        self.start_epoch = 0

        # --- resume ---
        if self.resume_path is not None:
            self._resume_from_checkpoint(self.resume_path)

    def _setup_directories(self) -> None:
        for k in ("OUTPUT_DIR", "CHECKPOINT_DIR", "LOG_DIR", "RESULT_DIR"):
            Path(self.config[k]).mkdir(parents=True, exist_ok=True)

    def _setup_optimizer(self) -> None:
        tr = self.config["TRAINING"]
        opt = tr.get("optimizer", "AdamW")
        lr = float(tr.get("learning_rate", 1e-3))
        wd = float(tr.get("weight_decay", 0.0))
        if opt == "AdamW":
            self.optimizer = optim.AdamW(self.model.parameters(), lr=lr, weight_decay=wd)
        elif opt == "Adam":
            self.optimizer = optim.Adam(self.model.parameters(), lr=lr, weight_decay=wd)
        else:
            raise ValueError(f"Unknown optimizer: {opt}")

    def _setup_scheduler(self) -> None:
        tr = self.config["TRAINING"]
        sched = tr.get("scheduler", "CosineAnnealingWarmRestarts")
        if sched == "CosineAnnealingWarmRestarts":
            self.scheduler = optim.lr_scheduler.CosineAnnealingWarmRestarts(
                self.optimizer,
                T_0=int(tr.get("T_0", 10)),
                T_mult=2,
                eta_min=float(tr.get("min_lr", 1e-6)),
            )
        else:
            self.scheduler = None

    def _resume_from_checkpoint(self, ckpt_path: str) -> None:
        """从 checkpoint 恢复模型、优化器、scheduler 和训练状态。"""
        ckpt = torch.load(ckpt_path, map_location=self.device)
        logger.info(f"Resuming from checkpoint: {ckpt_path}")

        # 模型权重
        state_dict = ckpt["model_state_dict"]
        if self._reset_feminine_head:
            # 过滤掉 03Feminine head 的权重，让该 head 保持随机初始化
            filtered = {k: v for k, v in state_dict.items() if "03Feminine" not in k}
            n_removed = len(state_dict) - len(filtered)
            logger.info(f"  Reset Feminine head: removed {n_removed} keys from state_dict, "
                         "Feminine head will use random init.")
            state_dict = filtered
        self.model.load_state_dict(state_dict, strict=False)
        logger.info("  Model weights loaded.")
        if "optimizer_state_dict" in ckpt:
            try:
                self.optimizer.load_state_dict(ckpt["optimizer_state_dict"])
                logger.info("  Optimizer state loaded.")
            except Exception as e:
                logger.warning(f"  Could not load optimizer state: {e}. Using fresh optimizer.")

        # scheduler 状态
        if self.scheduler is not None and "scheduler_state_dict" in ckpt and ckpt["scheduler_state_dict"] is not None:
            try:
                self.scheduler.load_state_dict(ckpt["scheduler_state_dict"])
                logger.info("  Scheduler state loaded.")
            except Exception as e:
                logger.warning(f"  Could not load scheduler state: {e}. Using fresh scheduler.")

        # 训练状态
        self.start_epoch = int(ckpt.get("epoch", -1)) + 1
        self.best_val_loss = float(ckpt.get("metrics", {}).get("val_loss", float("inf")))
        self.patience_counter = 0  # resume 时重置 patience

        logger.info(f"  Resuming from epoch {self.start_epoch} (best_val_loss={self.best_val_loss:.4f})")

    @staticmethod
    def _maybe_normalize_target_score(target_score: torch.Tensor) -> torch.Tensor:
        if target_score.max() > 1.5:
            return target_score / 10.0
        return target_score

    def _get_target_from_batch(self, batch: Dict) -> torch.Tensor:
        """从 batch 中获取 target。多头时返回 (B, N)，单头时返回 (B, 1)。"""
        if self._multi_head and "attribute_scores" in batch:
            return batch["attribute_scores"].to(self.device, non_blocking=True)
        return batch["preference_score"].to(self.device, non_blocking=True)

    def _get_center_from_batch(self, batch: Dict) -> Optional[torch.Tensor]:
        """A9: 获取 Lab 色度中心 GT，(B, 3*N_attrs)。NaN 处用 0 填充，由 mask 控制。"""
        L = batch.get("preference_L", None)
        center = batch.get("preference_center", None)
        if L is None or center is None:
            return None
        L = L.to(self.device, non_blocking=True)                        # (B, 1)
        ab = center.to(self.device, non_blocking=True)                   # (B, 2)
        lab = torch.cat([L, ab], dim=1)                                  # (B, 3)
        lab = torch.nan_to_num(lab, nan=0.0)
        # multi-head: replicate for each attr
        if self._multi_head and lab.shape[1] == 3:
            lab = lab.repeat(1, len(self._attribute_names))             # (B, 3*N)
        return lab

    def _get_center_mask_from_batch(self, batch: Dict) -> Optional[torch.Tensor]:
        """A9: 中心 GT 的 mask，NaN → mask=0。"""
        L = batch.get("preference_L", None)
        center = batch.get("preference_center", None)
        if L is None or center is None:
            return None
        L = L.to(self.device, non_blocking=True)
        ab = center.to(self.device, non_blocking=True)
        lab = torch.cat([L, ab], dim=1)                                  # (B, 3)
        mask = torch.isfinite(lab).float()                               # 1=valid, 0=NaN
        if self._multi_head:
            mask = mask.repeat(1, len(self._attribute_names))           # (B, 3*N)
        return mask

    def _compute_loss(self, pred_logits, target_score, attr_mask,
                      pred_centers=None, target_center=None, center_mask=None):
        """Unified loss: score loss + optional center loss."""
        loss, loss_dict = self.criterion(pred_logits, target_score, attr_mask)
        if pred_centers is not None and target_center is not None:
            # normalise: clamp(C/128, -1, 1) as MS-CMAN
            pred_centers = torch.clamp(pred_centers / 128.0, -1.0, 1.0)
            target_center = torch.clamp(target_center / 128.0, -1.0, 1.0)
            center_l1 = self.center_l1(pred_centers, target_center)      # (B, 3*N)
            if center_mask is not None:
                n_valid = center_mask.sum().clamp_min(1)
                center_loss = (center_l1 * center_mask).sum() / n_valid
            else:
                center_loss = center_l1.mean()
            # λ₂=1.5 matching MS-CMAN
            center_weight = float(self.config.get("LOSS", {}).get("center_weight", 1.5))
            loss = loss + center_weight * center_loss
            loss_dict["center"] = float(center_loss.item())
        return loss, loss_dict

    def train_epoch(self, epoch: int) -> Dict[str, float]:
        self.model.train()
        total_loss = 0.0
        score_loss_sum = 0.0
        pearson_loss_sum = 0.0
        num_batches = 0

        progress = tqdm(self.train_loader, desc=f"Epoch {epoch}", disable=not sys.stdout.isatty())
        for batch_idx, batch in enumerate(progress):
            if batch is None or batch.get("face_rgb") is not None and batch["face_rgb"].shape[0] == 0:
                continue
            face_rgb = batch["face_rgb"].to(self.device, non_blocking=True)
            global_rgb = batch.get("global_rgb", face_rgb).to(self.device, non_blocking=True)
            target_score = self._get_target_from_batch(batch)
            attr_mask = batch.get("attribute_mask", None)
            if attr_mask is not None:
                attr_mask = attr_mask.to(self.device, non_blocking=True)
            stat_features = batch.get("stat_features", None)
            if stat_features is not None:
                stat_features = stat_features.to(self.device, non_blocking=True)
            face_uv = None if str(self.config.get("MODEL_VARIANT", "v1")).lower().strip() == "v3" else batch["face_uv"].to(self.device, non_blocking=True)

            self.optimizer.zero_grad(set_to_none=True)

            if self._lab_center:
                model_out = self.model(face_rgb, face_uv, global_rgb, stat_features=stat_features)
                pred_logits, pred_centers = model_out
                target_center = self._get_center_from_batch(batch)
                center_mask = self._get_center_mask_from_batch(batch)
            else:
                pred_logits = self.model(face_rgb, face_uv, global_rgb, stat_features=stat_features)
                target_center = None; center_mask = None

            pred_logits = torch.nan_to_num(pred_logits, nan=0.0, posinf=1e6, neginf=-1e6)

            if self.scaler:
                with autocast():
                    loss, loss_dict = self._compute_loss(pred_logits, target_score, attr_mask, pred_centers, target_center, center_mask)
                self.scaler.scale(loss).backward()
                self.scaler.unscale_(self.optimizer)
                torch.nn.utils.clip_grad_norm_(self.model.parameters(), float(self.config["TRAINING"].get("gradient_clip", 1.0)))
                self.scaler.step(self.optimizer)
                self.scaler.update()
            else:
                loss, loss_dict = self._compute_loss(pred_logits, target_score, attr_mask, pred_centers, target_center, center_mask)
                loss.backward()
                torch.nn.utils.clip_grad_norm_(self.model.parameters(), float(self.config["TRAINING"].get("gradient_clip", 1.0)))
                self.optimizer.step()

            if not torch.isfinite(loss):
                continue

            total_loss += float(loss.item())
            score_loss_sum += float(loss_dict.get("score", 0.0))
            pearson_loss_sum += float(loss_dict.get("pearson", 0.0))
            num_batches += 1

            pearson_r = 1.0 - float(loss_dict.get("pearson", 0.0))
            progress.set_postfix(loss=f"{float(loss.item()):.4f}", r=f"{pearson_r:.4f}")
            if progress.disable and (batch_idx == 0 or (batch_idx + 1) % max(1, len(self.train_loader) // 5) == 0):
                logger.info(f"  Batch {batch_idx+1}/{len(self.train_loader)} loss={float(loss.item()):.4f} r={pearson_r:.4f}")

        if self.scheduler is not None:
            self.scheduler.step(epoch + 1)

        if num_batches == 0:
            return {"loss": float("inf"), "score_loss": float("inf"), "pearson_loss": float("inf")}

        return {
            "loss": total_loss / num_batches,
            "score_loss": score_loss_sum / num_batches,
            "pearson_loss": pearson_loss_sum / num_batches,
        }

    @torch.no_grad()
    def validate(self) -> Dict[str, float]:
        self.model.eval()
        losses = []
        all_pred = []
        all_tgt = []

        for batch in self.val_loader:
            face_rgb = batch["face_rgb"].to(self.device, non_blocking=True)
            global_rgb = batch.get("global_rgb", face_rgb).to(self.device, non_blocking=True)
            target_score = self._get_target_from_batch(batch)
            stat_features = batch.get("stat_features", None)
            if stat_features is not None:
                stat_features = stat_features.to(self.device, non_blocking=True)
            face_uv = None if str(self.config.get("MODEL_VARIANT", "v1")).lower().strip() == "v3" else batch["face_uv"].to(self.device, non_blocking=True)

            model_out = self.model(face_rgb, face_uv, global_rgb, stat_features=stat_features)
            if self._lab_center:
                pred_logits = model_out[0]
            else:
                pred_logits = model_out
            pred_logits = torch.nan_to_num(pred_logits, nan=0.0, posinf=1e6, neginf=-1e6)
            loss, _ = self.criterion(pred_logits, target_score)
            if torch.isfinite(loss):
                losses.append(float(loss.item()))

            # 多 head 时只取第 0 个（preference_score）计算 metrics
            if self._multi_head and pred_logits.shape[1] > 1:
                pred_for_metrics = pred_logits[:, 0:1]
                tgt_for_metrics = target_score[:, 0:1] if target_score.dim() == 2 and target_score.shape[1] > 1 else target_score
            else:
                pred_for_metrics = pred_logits
                tgt_for_metrics = target_score

            all_pred.append(torch.sigmoid(pred_for_metrics).cpu())
            all_tgt.append(self._maybe_normalize_target_score(tgt_for_metrics).cpu())

        if not losses or not all_pred:
            return {"val_loss": float("inf"), "mae": float("nan"), "pearson": float("nan")}

        ps = torch.cat(all_pred, dim=0).numpy()
        ts = torch.cat(all_tgt, dim=0).numpy()
        metrics = evaluate_scores(ps, ts)
        metrics["val_loss"] = float(np.mean(losses))
        return metrics

    def train(self) -> None:
        num_epochs = int(self.config["TRAINING"].get("num_epochs", 1))
        patience = int(self.config["TRAINING"].get("early_stopping_patience", 20))
        interval = int(self.config["TRAINING"].get("checkpoint_interval", 100))

        for epoch in range(self.start_epoch, num_epochs):
            train_m = self.train_epoch(epoch)
            val_m = self.validate()

            logger.info(
                f"Epoch {epoch+1}/{num_epochs} "
                f"train_loss={train_m['loss']:.4f} val_loss={val_m['val_loss']:.4f} "
                f"mae={val_m.get('mae', float('nan')):.4f} pearson={val_m.get('pearson', float('nan')):.4f}"
            )

            if self.writer:
                self.writer.add_scalar("Train/Loss", train_m["loss"], epoch)
                self.writer.add_scalar("Val/Loss", val_m["val_loss"], epoch)
                if "mae" in val_m:
                    self.writer.add_scalar("Val/MAE", val_m["mae"], epoch)
                if "pearson" in val_m:
                    self.writer.add_scalar("Val/Pearson", val_m["pearson"], epoch)

            improved = val_m["val_loss"] < self.best_val_loss
            if improved:
                self.best_val_loss = val_m["val_loss"]
                self.patience_counter = 0
                self._save_best(epoch, val_m)
            else:
                self.patience_counter += 1

            if interval and (epoch + 1) % interval == 0:
                self._save_checkpoint(epoch, val_m)

            if self.patience_counter >= patience:
                logger.info("Early stopping triggered.")
                break

        if self.writer:
            self.writer.close()

    def _save_best(self, epoch: int, metrics: Dict[str, float]) -> None:
        ckpt = {
            "epoch": epoch,
            "model_state_dict": self.model.state_dict(),
            "optimizer_state_dict": self.optimizer.state_dict(),
            "scheduler_state_dict": self.scheduler.state_dict() if self.scheduler else None,
            "config": self.config,
            "metrics": metrics,
        }
        ckpt_path = Path(self.config["CHECKPOINT_DIR"]) / "best_model.pth"
        torch.save(ckpt, ckpt_path)

        metrics_path = Path(self.config["RESULT_DIR"]) / "best_metrics.json"
        with open(metrics_path, "w", encoding="utf-8") as f:
            json.dump(metrics, f, indent=2, ensure_ascii=False)

    def _save_checkpoint(self, epoch: int, metrics: Dict[str, float]) -> None:
        ckpt_path = Path(self.config["CHECKPOINT_DIR"]) / f"checkpoint_epoch_{epoch+1}.pth"
        ckpt = {
            "epoch": epoch,
            "model_state_dict": self.model.state_dict(),
            "optimizer_state_dict": self.optimizer.state_dict(),
            "scheduler_state_dict": self.scheduler.state_dict() if self.scheduler else None,
            "config": self.config,
            "metrics": metrics,
        }
        torch.save(ckpt, ckpt_path)

    @torch.no_grad()
    def test(self) -> Dict[str, float]:
        ckpt_path = Path(self.config["CHECKPOINT_DIR"]) / "best_model.pth"
        if ckpt_path.exists():
            ckpt = torch.load(ckpt_path, map_location=self.device)
            self.model.load_state_dict(ckpt["model_state_dict"], strict=True)

        self.model.eval()
        all_pred = []
        all_tgt = []
        for batch in self.test_loader:
            face_rgb = batch["face_rgb"].to(self.device, non_blocking=True)
            global_rgb = batch.get("global_rgb", face_rgb).to(self.device, non_blocking=True)
            target_score = self._get_target_from_batch(batch)
            stat_features = batch.get("stat_features", None)
            if stat_features is not None:
                stat_features = stat_features.to(self.device, non_blocking=True)
            face_uv = None if str(self.config.get("MODEL_VARIANT", "v1")).lower().strip() == "v3" else batch["face_uv"].to(self.device, non_blocking=True)
            pred_logits = self.model(face_rgb, face_uv, global_rgb, stat_features=stat_features)

            # 多 head 时只取第 0 个（preference_score）计算 metrics
            if self._multi_head and pred_logits.shape[1] > 1:
                pred_for_metrics = pred_logits[:, 0:1]
                tgt_for_metrics = target_score[:, 0:1] if target_score.dim() == 2 and target_score.shape[1] > 1 else target_score
            else:
                pred_for_metrics = pred_logits
                tgt_for_metrics = target_score

            all_pred.append(torch.sigmoid(pred_for_metrics).cpu())
            all_tgt.append(self._maybe_normalize_target_score(tgt_for_metrics).cpu())

        ps = torch.cat(all_pred, dim=0).numpy() if all_pred else np.array([])
        ts = torch.cat(all_tgt, dim=0).numpy() if all_tgt else np.array([])
        metrics = evaluate_scores(ps, ts)

        out_path = Path(self.config["RESULT_DIR"]) / "test_metrics.json"
        with open(out_path, "w", encoding="utf-8") as f:
            json.dump(metrics, f, indent=2, ensure_ascii=False)

        return metrics
