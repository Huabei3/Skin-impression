from __future__ import annotations

import json
import logging
from pathlib import Path
from typing import Dict, Optional, Tuple

import numpy as np
import torch
from torch.utils.data import DataLoader

from ..data.dataset import FacialPreferenceDataset, get_data_transforms

from ..metrics import evaluate_scores
from ..models import create_model

logger = logging.getLogger(__name__)


class BatchTester:
    def __init__(
        self,
        checkpoint_path: str,
        config: Optional[Dict] = None,
        device: str = "cuda",
        output_dir: str = "test_results_predict_p",
        data_paths_override: Optional[Dict[str, str]] = None,
    ) -> None:
        self.device = torch.device(device if torch.cuda.is_available() else "cpu")
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(parents=True, exist_ok=True)

        self.checkpoint = torch.load(checkpoint_path, map_location=self.device)
        ckpt_cfg = self.checkpoint.get("config", {}) or {}
        if ckpt_cfg:
            # Always prefer checkpoint config for model architecture to avoid state_dict mismatch
            # when current defaults differ (e.g., v1/v2/v3 or backbone changes).
            self.config = dict(ckpt_cfg)
            if config:
                for k in (
                    "TEST_IDS",
                    "TEST_SPLIT_SOURCE",
                    "SPLIT_STRATEGY",
                    "TEST_BATCH_SIZE",
                    "TRAIN_RATIO",
                    "VAL_RATIO",
                    "TEST_RATIO",
                    "DATALOADER",
                ):
                    if k in config:
                        self.config[k] = config[k]
        else:
            # Backward compatibility: checkpoints without embedded config.
            self.config = config or {}

        if data_paths_override:
            for k, v in data_paths_override.items():
                if v is not None:
                    self.config[k] = str(v)

        model_variant = str(self.config.get("MODEL_VARIANT", "v1")).lower().strip()
        self.model = create_model(self.config, model_type="full", use_attention=True, model_variant=model_variant).to(self.device)
        self.model.load_state_dict(self.checkpoint["model_state_dict"], strict=True)
        self.model.eval()

        self.pred_scores: np.ndarray = np.array([], dtype=np.float32)
        self.tgt_scores: np.ndarray = np.array([], dtype=np.float32)

    @staticmethod
    def _summary_stats(values: np.ndarray) -> Dict[str, float]:
        v = np.asarray(values, dtype=float).reshape(-1)
        v = v[np.isfinite(v)]
        if v.size == 0:
            return {
                "mean": float("nan"),
                "median": float("nan"),
                "trimean": float("nan"),
                "best25_mean": float("nan"),
                "worst25_mean": float("nan"),
                "min": float("nan"),
                "max": float("nan"),
            }

        mean = float(np.mean(v))
        median = float(np.median(v))
        q1 = float(np.percentile(v, 25))
        q3 = float(np.percentile(v, 75))
        trimean = float((q1 + 2.0 * median + q3) / 4.0)

        v_sorted = np.sort(v)
        k = int(np.ceil(0.25 * v_sorted.size))
        k = max(1, k)
        best25_mean = float(np.mean(v_sorted[:k]))
        worst25_mean = float(np.mean(v_sorted[-k:]))
        return {
            "mean": mean,
            "median": median,
            "trimean": trimean,
            "best25_mean": best25_mean,
            "worst25_mean": worst25_mean,
            "min": float(v_sorted[0]),
            "max": float(v_sorted[-1]),
        }

    @staticmethod
    def _maybe_normalize_target_score(target_score: torch.Tensor) -> torch.Tensor:
        if target_score.max() > 1.5:
            return target_score / 10.0
        return target_score

    def prepare_test_dataset(self) -> DataLoader:
        transform = get_data_transforms(self.config, split="test")

        # Try to reproduce training-time split rules from checkpoint config, then optionally filter by TEST_IDS.
        split_ref_cfg = self.checkpoint.get("config") or {}
        seed = int(split_ref_cfg.get("RANDOM_SEED", self.config.get("RANDOM_SEED", 42)))
        train_ratio = float(split_ref_cfg.get("TRAIN_RATIO", self.config.get("TRAIN_RATIO", 0.7)))
        val_ratio = float(split_ref_cfg.get("VAL_RATIO", self.config.get("VAL_RATIO", 0.15)))
        test_ratio = float(split_ref_cfg.get("TEST_RATIO", self.config.get("TEST_RATIO", 0.15)))

        if isinstance(split_ref_cfg, dict) and split_ref_cfg:
            split_strategy = str(split_ref_cfg.get("SPLIT_STRATEGY", self.config.get("SPLIT_STRATEGY", "stable_by_id_hash")))
        else:
            split_strategy = str(self.config.get("SPLIT_STRATEGY", "stable_by_id_hash"))

        test_split_source = str(self.config.get("TEST_SPLIT_SOURCE") or "subset").strip().lower()
        desired_test_ids = FacialPreferenceDataset._normalize_ids(self.config.get("TEST_IDS"))

        base_train_ids = FacialPreferenceDataset._normalize_ids(split_ref_cfg.get("TRAIN_IDS"))
        base_test_ids = FacialPreferenceDataset._normalize_ids(split_ref_cfg.get("TEST_IDS"))
        if base_test_ids is None and base_train_ids is not None:
            base_test_ids = base_train_ids

        global_rgb_root = Path(self.config.get("GLOBAL_RGB_ROOT", self.config["FACE_RGB_ROOT"]))
        model_variant = str(self.config.get("MODEL_VARIANT", "v1")).lower().strip()
        load_uv = model_variant != "v3"
        uv_is_hist = bool(self.config.get("FACE_UV_IS_HIST", False))
        uv_log_ratio = bool(((self.config.get("MODEL", {}) or {}).get("face_stream", {}) or {}).get("uv_log_ratio", False))

        dl_cfg = self.config.get("DATALOADER", {}) or {}
        num_workers = int(dl_cfg.get("num_workers", 0))
        pin_memory = bool(dl_cfg.get("pin_memory", True))
        persistent_workers = bool(dl_cfg.get("persistent_workers", False)) if num_workers > 0 else False
        prefetch_factor = int(dl_cfg.get("prefetch_factor", 2)) if num_workers > 0 else None

        if test_split_source in {"base_then_filter", "train_then_filter", "global_then_filter"}:
            test_dataset = FacialPreferenceDataset(
                face_rgb_root=Path(self.config["FACE_RGB_ROOT"]),
                face_uv_root=Path(self.config["FACE_UV_ROOT"]),
                gt_excel_path=Path(self.config["GT_EXCEL_PATH"]),
                split="test",
                transform=transform,
                seed=seed,
                train_ratio=train_ratio,
                val_ratio=val_ratio,
                test_ratio=test_ratio,
                allowed_ids=base_test_ids,
                global_rgb_root=global_rgb_root,
                split_strategy=split_strategy,
                load_uv=load_uv,
                uv_is_hist=uv_is_hist,
                uv_log_ratio=uv_log_ratio,
            )

            if desired_test_ids is not None and desired_test_ids != base_test_ids:
                before = len(test_dataset)
                test_dataset.allowed_ids = desired_test_ids
                test_dataset._filter_by_ids()
                logger.info(f"[Split] base_then_filter: {before} -> {len(test_dataset)} samples (TEST_IDS={desired_test_ids})")
        else:
            test_dataset = FacialPreferenceDataset(
                face_rgb_root=Path(self.config["FACE_RGB_ROOT"]),
                face_uv_root=Path(self.config["FACE_UV_ROOT"]),
                gt_excel_path=Path(self.config["GT_EXCEL_PATH"]),
                split="test",
                transform=transform,
                seed=seed,
                train_ratio=train_ratio,
                val_ratio=val_ratio,
                test_ratio=test_ratio,
                allowed_ids=desired_test_ids,
                global_rgb_root=global_rgb_root,
                split_strategy=split_strategy,
                load_uv=load_uv,
                uv_is_hist=uv_is_hist,
                uv_log_ratio=uv_log_ratio,
            )

        batch_size = int(self.config.get("TEST_BATCH_SIZE", self.config.get("TRAINING", {}).get("batch_size", 32)))
        return DataLoader(
            test_dataset,
            batch_size=batch_size,
            shuffle=False,
            num_workers=num_workers,
            pin_memory=pin_memory,
            persistent_workers=persistent_workers,
            prefetch_factor=prefetch_factor,
        )

    @torch.no_grad()
    def run_inference(self, test_loader: DataLoader) -> None:
        preds = []
        tgts = []
        try:
            from tqdm import tqdm  # type: ignore

            iterator = tqdm(test_loader, desc="Inference", unit="batch", total=len(test_loader))
        except Exception:
            iterator = test_loader

        for batch in iterator:
            face_rgb = batch["face_rgb"].to(self.device, non_blocking=True)
            global_rgb = batch.get("global_rgb", face_rgb).to(self.device, non_blocking=True)
            target_score = batch["preference_score"].to(self.device, non_blocking=True)
            face_uv = None if str(self.config.get("MODEL_VARIANT", "v1")).lower().strip() == "v3" else batch["face_uv"].to(self.device, non_blocking=True)

            logits = self.model(face_rgb, face_uv, global_rgb)
            prob = torch.sigmoid(logits).cpu().numpy().reshape(-1)
            tgt = self._maybe_normalize_target_score(target_score).cpu().numpy().reshape(-1)
            preds.append(prob)
            tgts.append(tgt)

        self.pred_scores = np.concatenate(preds).astype(np.float32) if preds else np.array([], dtype=np.float32)
        self.tgt_scores = np.concatenate(tgts).astype(np.float32) if tgts else np.array([], dtype=np.float32)

    def _save_gt_vs_pred_plot(self, pred: np.ndarray, tgt: np.ndarray) -> Optional[Path]:
        try:
            import matplotlib.pyplot as plt  # type: ignore
        except Exception as e:
            logger.warning("matplotlib not available, skip plot: %s", e)
            return None

        p = np.asarray(pred, dtype=float).reshape(-1)
        t = np.asarray(tgt, dtype=float).reshape(-1)
        mask = np.isfinite(p) & np.isfinite(t)
        p = p[mask]
        t = t[mask]
        if p.size == 0:
            return None

        lim_min = float(min(np.min(p), np.min(t)))
        lim_max = float(max(np.max(p), np.max(t)))
        pad = 0.02 * (lim_max - lim_min + 1e-8)
        lim_min -= pad
        lim_max += pad

        fig = plt.figure(figsize=(6, 6), dpi=140)
        ax = fig.add_subplot(1, 1, 1)
        ax.scatter(t, p, s=10, alpha=0.55)
        ax.plot([lim_min, lim_max], [lim_min, lim_max], "r--", linewidth=1.0)
        ax.set_xlabel("GT p")
        ax.set_ylabel("Pred p")
        ax.set_xlim(lim_min, lim_max)
        ax.set_ylim(lim_min, lim_max)
        ax.grid(True, linestyle="--", alpha=0.3)
        ax.set_title("GT vs Pred (p)")

        out_path = self.output_dir / "gt_vs_pred.png"
        fig.tight_layout()
        fig.savefig(out_path)
        plt.close(fig)
        return out_path

    def _save_error_hist(self, pred: np.ndarray, tgt: np.ndarray) -> Optional[Path]:
        try:
            import matplotlib.pyplot as plt  # type: ignore
        except Exception as e:
            logger.warning("matplotlib not available, skip hist: %s", e)
            return None

        p = np.asarray(pred, dtype=float).reshape(-1)
        t = np.asarray(tgt, dtype=float).reshape(-1)
        mask = np.isfinite(p) & np.isfinite(t)
        p = p[mask]
        t = t[mask]
        if p.size == 0:
            return None

        abs_err = np.abs(p - t)
        fig = plt.figure(figsize=(6, 4), dpi=140)
        ax = fig.add_subplot(1, 1, 1)
        ax.hist(abs_err, bins=40, alpha=0.9)
        ax.set_xlabel("|pred - gt|")
        ax.set_ylabel("Count")
        ax.grid(True, linestyle="--", alpha=0.3)
        ax.set_title("Absolute Error Histogram")

        out_path = self.output_dir / "abs_error_hist.png"
        fig.tight_layout()
        fig.savefig(out_path)
        plt.close(fig)
        return out_path

    def run_complete_test(self) -> Dict[str, Dict]:
        test_loader = self.prepare_test_dataset()
        self.run_inference(test_loader)

        metrics = evaluate_scores(self.pred_scores, self.tgt_scores)
        abs_err = np.abs(self.pred_scores.astype(float) - self.tgt_scores.astype(float))
        pred_stats = self._summary_stats(self.pred_scores)
        tgt_stats = self._summary_stats(self.tgt_scores)
        err_stats = self._summary_stats(abs_err)

        plot_gt_pred = self._save_gt_vs_pred_plot(self.pred_scores, self.tgt_scores)
        plot_err_hist = self._save_error_hist(self.pred_scores, self.tgt_scores)

        results = {
            "score_metrics": metrics,
            "summary": {
                "pred": pred_stats,
                "gt": tgt_stats,
                "abs_error": err_stats,
            },
            "artifacts": {
                "gt_vs_pred_png": str(plot_gt_pred) if plot_gt_pred else None,
                "abs_error_hist_png": str(plot_err_hist) if plot_err_hist else None,
            },
            "metadata": {"total_samples": int(self.pred_scores.size)},
        }

        out_path = self.output_dir / "test_results.json"
        with open(out_path, "w", encoding="utf-8") as f:
            json.dump(results, f, indent=2, ensure_ascii=False)
        logger.info(f"Saved: {out_path}")
        return results
