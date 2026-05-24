"""
predict_p training entrypoint (standalone project).

This project predicts only p (score), and removes the statistical stream entirely.
"""

from __future__ import annotations

import argparse
import logging
import sys
from pathlib import Path

import numpy as np
import torch


def _ensure_repo_on_path() -> None:
    repo_root = Path(__file__).resolve().parents[1]
    if str(repo_root) not in sys.path:
        sys.path.append(str(repo_root))

def _apply_model_variant_overrides(config: dict) -> None:
    variant = str(config.get("MODEL_VARIANT", "v1")).lower().strip()
    config["MODEL_VARIANT"] = variant

    if variant == "v1":
        return

    model_name = str(config.get("MODEL_NAME", "predict_p"))
    if model_name == "predict_p":
        model_name = f"predict_p_{variant}"
        config["MODEL_NAME"] = model_name

        output_root = Path(str(config["OUTPUT_ROOT"]))
        output_dir = output_root / model_name
        config["OUTPUT_DIR"] = str(output_dir)
        config["CHECKPOINT_DIR"] = str(output_dir / "checkpoints")
        config["LOG_DIR"] = str(output_dir / "logs")
        config["RESULT_DIR"] = str(output_dir / "results")


def main() -> None:
    _ensure_repo_on_path()

    from predict_p.config import Config
    from predict_p.trainer import Trainer

    parser = argparse.ArgumentParser(description="predict_p training entrypoint")
    parser.add_argument("--model-variant", choices=["v1", "v2", "v3"], default=None, help="Select model variant")
    parser.add_argument(
        "--rgb-backbone",
        choices=["simple_cnn", "resnet50", "efficientnet_b0"],
        default=None,
        help="Face RGB backbone",
    )
    parser.add_argument(
        "--global-backbone",
        choices=["simple_cnn", "mobilenet_v3_small", "mobilenet_v3_large", "efficientnet_b0"],
        default=None,
        help="Global image backbone",
    )
    parser.add_argument(
        "--no-pretrained",
        action="store_true",
        help="Disable torchvision pretrained weights (ignored for simple_cnn)",
    )
    parser.add_argument(
        "--num-workers",
        type=int,
        default=None,
        help="DataLoader num_workers (override config.DATALOADER.num_workers)",
    )
    parser.add_argument(
        "--prefetch-factor",
        type=int,
        default=None,
        help="DataLoader prefetch_factor (only when num_workers>0)",
    )
    parser.add_argument(
        "--persistent-workers",
        action="store_true",
        help="Enable persistent_workers for DataLoader (only when num_workers>0)",
    )
    args = parser.parse_args()

    config = Config.get_config_dict()
    if args.model_variant is not None:
        config["MODEL_VARIANT"] = args.model_variant
    if args.rgb_backbone is not None:
        config["MODEL"]["face_stream"]["rgb_backbone"] = args.rgb_backbone
        if args.rgb_backbone == "simple_cnn":
            config["MODEL"]["face_stream"]["rgb_pretrained"] = False
    if args.global_backbone is not None:
        config["MODEL"]["global_stream"]["backbone"] = args.global_backbone
        if args.global_backbone == "simple_cnn":
            config["MODEL"]["global_stream"]["pretrained"] = False
    if bool(args.no_pretrained):
        config["MODEL"]["face_stream"]["rgb_pretrained"] = False
        config["MODEL"]["global_stream"]["pretrained"] = False

    if "DATALOADER" not in config or not isinstance(config["DATALOADER"], dict):
        config["DATALOADER"] = {}
    if args.num_workers is not None:
        config["DATALOADER"]["num_workers"] = int(args.num_workers)
    if args.prefetch_factor is not None:
        config["DATALOADER"]["prefetch_factor"] = int(args.prefetch_factor)
    if bool(args.persistent_workers):
        config["DATALOADER"]["persistent_workers"] = True
    _apply_model_variant_overrides(config)

    log_level_name = str(config.get("LOGGING", {}).get("level", "INFO")).upper()
    log_level = getattr(logging, log_level_name, logging.INFO)
    logging.basicConfig(level=log_level, format="%(asctime)s - %(levelname)s - %(message)s", force=True)

    torch.manual_seed(config["RANDOM_SEED"])
    np.random.seed(config["RANDOM_SEED"])
    if torch.cuda.is_available():
        torch.cuda.manual_seed(config["RANDOM_SEED"])

    trainer = Trainer(config)
    trainer.train()
    trainer.test()


if __name__ == "__main__":
    main()
