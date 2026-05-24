from __future__ import annotations

import json
import logging
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
    def __init__(self, config: Dict):
        self.config = config
        self.device = torch.device(config.get("DEVICE", "cuda") if torch.cuda.is_available() else "cpu")

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

        self._setup_optimizer()
        self._setup_scheduler()

        self.scaler = GradScaler() if self.config["TRAINING"].get("mixed_precision", True) else None
        self.writer: Optional[SummaryWriter] = None
        if bool(self.config.get("LOGGING", {}).get("tensorboard", True)):
            self.writer = SummaryWriter(log_dir=str(self.config["LOG_DIR"]))

        self.best_val_loss = float("inf")
        self.patience_counter = 0

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

    @staticmethod
    def _maybe_normalize_target_score(target_score: torch.Tensor) -> torch.Tensor:
        if target_score.max() > 1.5:
            return target_score / 10.0
        return target_score

    def train_epoch(self, epoch: int) -> Dict[str, float]:
        self.model.train()
        total_loss = 0.0
        score_loss_sum = 0.0
        pearson_loss_sum = 0.0
        num_batches = 0

        progress = tqdm(self.train_loader, desc=f"Epoch {epoch}")
        for batch in progress:
            face_rgb = batch["face_rgb"].to(self.device, non_blocking=True)
            global_rgb = batch.get("global_rgb", face_rgb).to(self.device, non_blocking=True)
            target_score = batch["preference_score"].to(self.device, non_blocking=True)
            face_uv = None if str(self.config.get("MODEL_VARIANT", "v1")).lower().strip() == "v3" else batch["face_uv"].to(self.device, non_blocking=True)

            self.optimizer.zero_grad(set_to_none=True)

            if self.scaler:
                with autocast():
                    pred_logits = self.model(face_rgb, face_uv, global_rgb)
                    pred_logits = torch.nan_to_num(pred_logits, nan=0.0, posinf=1e6, neginf=-1e6)
                    loss, loss_dict = self.criterion(pred_logits, target_score)
                self.scaler.scale(loss).backward()
                self.scaler.unscale_(self.optimizer)
                torch.nn.utils.clip_grad_norm_(self.model.parameters(), float(self.config["TRAINING"].get("gradient_clip", 1.0)))
                self.scaler.step(self.optimizer)
                self.scaler.update()
            else:
                pred_logits = self.model(face_rgb, face_uv, global_rgb)
                pred_logits = torch.nan_to_num(pred_logits, nan=0.0, posinf=1e6, neginf=-1e6)
                loss, loss_dict = self.criterion(pred_logits, target_score)
                loss.backward()
                torch.nn.utils.clip_grad_norm_(self.model.parameters(), float(self.config["TRAINING"].get("gradient_clip", 1.0)))
                self.optimizer.step()

            if not torch.isfinite(loss):
                continue

            total_loss += float(loss.item())
            score_loss_sum += float(loss_dict.get("score", 0.0))
            pearson_loss_sum += float(loss_dict.get("pearson", 0.0))
            num_batches += 1

            progress.set_postfix(loss=f"{float(loss.item()):.4f}")

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
            target_score = batch["preference_score"].to(self.device, non_blocking=True)
            face_uv = None if str(self.config.get("MODEL_VARIANT", "v1")).lower().strip() == "v3" else batch["face_uv"].to(self.device, non_blocking=True)

            pred_logits = self.model(face_rgb, face_uv, global_rgb)
            pred_logits = torch.nan_to_num(pred_logits, nan=0.0, posinf=1e6, neginf=-1e6)
            loss, _ = self.criterion(pred_logits, target_score)
            if torch.isfinite(loss):
                losses.append(float(loss.item()))

            all_pred.append(torch.sigmoid(pred_logits).cpu())
            all_tgt.append(self._maybe_normalize_target_score(target_score).cpu())

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

        for epoch in range(num_epochs):
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
            target_score = batch["preference_score"].to(self.device, non_blocking=True)
            face_uv = None if str(self.config.get("MODEL_VARIANT", "v1")).lower().strip() == "v3" else batch["face_uv"].to(self.device, non_blocking=True)
            pred_logits = self.model(face_rgb, face_uv, global_rgb)
            all_pred.append(torch.sigmoid(pred_logits).cpu())
            all_tgt.append(self._maybe_normalize_target_score(target_score).cpu())

        ps = torch.cat(all_pred, dim=0).numpy() if all_pred else np.array([])
        ts = torch.cat(all_tgt, dim=0).numpy() if all_tgt else np.array([])
        metrics = evaluate_scores(ps, ts)

        out_path = Path(self.config["RESULT_DIR"]) / "test_metrics.json"
        with open(out_path, "w", encoding="utf-8") as f:
            json.dump(metrics, f, indent=2, ensure_ascii=False)

        return metrics
