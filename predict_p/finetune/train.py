"""
predict_p finetune entrypoint (standalone project).

Loads a pretrained checkpoint (optionally strict), then trains predict_p
(score-only, no statistical stream) on OPPO-style data.
"""

from __future__ import annotations

import logging
import sys
from pathlib import Path
from typing import Any, Dict, Optional

import numpy as np
import torch

# ==================== User config ====================
BASE_CHECKPOINT: str = r"F:\Github\deepskin\facial_preference\output\predict_p_v3\checkpoints\best_model.pth"

# Fine-tune recommended:
# - Keep model architecture/config consistent with BASE_CHECKPOINT.
# - Only override data/training/output unless you intentionally change the model.
USE_CHECKPOINT_CONFIG_AS_BASE: bool = True
OVERRIDE_MODEL_CONFIG: bool = False  # set True if you really want to change MODEL_VARIANT/backbones below

# If OVERRIDE_MODEL_CONFIG=True, select predict_p model variant: "v1"/"v2"/"v3"
MODEL_VARIANT: str = "v3"

# If OVERRIDE_MODEL_CONFIG=True, optional: select backbones (keep "simple_cnn" to train from scratch)
FACE_RGB_BACKBONE: str = "simple_cnn"  # "simple_cnn"/"resnet50"/"efficientnet_b0"
GLOBAL_RGB_BACKBONE: str = "simple_cnn"  # "simple_cnn"/"mobilenet_v3_small"/"mobilenet_v3_large"/"efficientnet_b0"
DISABLE_TORCHVISION_PRETRAINED: bool = True

OPPO_FACE_RGB_ROOT: str = r"I:\OPPOskinExpe\rendered_face"
OPPO_GLOBAL_RGB_ROOT: str = r"I:\OPPOskinExpe\rendered"
OPPO_FACE_UV_ROOT: str = r"I:\OPPOskinExpe\rendered_face_uv"
OPPO_GT_EXCEL_PATH: str = r"I:\OPPOskinExpe\oppo_preference_gt_ratio.xlsx"

# Optional: select which OPPO scenes/sheets to use (by Excel sheet name)
# - None/"all": use all sheets
# - "inLab": only use inLab
# - "inLab2v": only use inLab2v
# - "inLab,outdoor": multiple sheets
# - ["inLab", "outdoor"]: list form
FINETUNE_SCENES = "inLab2"

TRAIN_RATIO: float = 0.05
VAL_RATIO: float = 0.05
TEST_RATIO: float = 0.9

FINETUNE_BATCH_SIZE: int = 2
FINETUNE_EPOCHS: int = 500
FINETUNE_LR: float = 1e-7
FINETUNE_EARLY_STOPPING_PATIENCE: int = 50

OUTPUT_SUFFIX: str = "oppo_finetune_test"
DEVICE: str = "cuda"

# For "true" fine-tune, keep this True so architecture mismatch fails fast.
LOAD_WEIGHTS_STRICT: bool = True

# If True, and FINETUNE_SCENES is None/"all", infer a strict scene selection from OUTPUT_SUFFIX.
# This prevents accidental mixing (e.g. suffix contains "2v" but scenes still default to "all").
AUTO_SCENES_FROM_SUFFIX: bool = True
# ======================================================


def _ensure_repo_on_path() -> None:
    repo_root = Path(__file__).resolve().parents[2]
    if str(repo_root) not in sys.path:
        sys.path.append(str(repo_root))


def _deep_merge_dict(base: Dict[str, Any], override: Dict[str, Any]) -> Dict[str, Any]:
    out: Dict[str, Any] = dict(base)
    for k, v in (override or {}).items():
        if isinstance(v, dict) and isinstance(out.get(k), dict):
            out[k] = _deep_merge_dict(out[k], v)  # type: ignore[arg-type]
        else:
            out[k] = v
    return out


def build_finetune_config(*, checkpoint_config: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
    from predict_p.config import Config

    def _is_all_scenes(x) -> bool:
        if x is None:
            return True
        if isinstance(x, str):
            s = x.strip().lower()
            return (not s) or s == "all"
        return False

    cfg: Dict[str, Any] = Config.get_config_dict()
    if checkpoint_config:
        cfg = _deep_merge_dict(cfg, checkpoint_config)

    if bool(OVERRIDE_MODEL_CONFIG):
        variant = str(MODEL_VARIANT).lower().strip()
        cfg["MODEL_VARIANT"] = variant
    else:
        variant = str(cfg.get("MODEL_VARIANT", "v1")).lower().strip()

    # Keep outputs separated by variant, similar to predict_p/train.py.
    if variant != "v1" and str(cfg.get("MODEL_NAME", "predict_p")) == "predict_p":
        cfg["MODEL_NAME"] = f"predict_p_{variant}"
        output_root = Path(str(cfg["OUTPUT_ROOT"]))
        output_dir = output_root / str(cfg["MODEL_NAME"])
        cfg["OUTPUT_DIR"] = str(output_dir)
        cfg["CHECKPOINT_DIR"] = str(output_dir / "checkpoints")
        cfg["LOG_DIR"] = str(output_dir / "logs")
        cfg["RESULT_DIR"] = str(output_dir / "results")

    if bool(OVERRIDE_MODEL_CONFIG):
        cfg["MODEL"]["face_stream"]["rgb_backbone"] = str(FACE_RGB_BACKBONE)
        cfg["MODEL"]["global_stream"]["backbone"] = str(GLOBAL_RGB_BACKBONE)
        if bool(DISABLE_TORCHVISION_PRETRAINED):
            cfg["MODEL"]["face_stream"]["rgb_pretrained"] = False
            cfg["MODEL"]["global_stream"]["pretrained"] = False
        if str(FACE_RGB_BACKBONE) == "simple_cnn":
            cfg["MODEL"]["face_stream"]["rgb_pretrained"] = False
        if str(GLOBAL_RGB_BACKBONE) == "simple_cnn":
            cfg["MODEL"]["global_stream"]["pretrained"] = False

    cfg["FACE_RGB_ROOT"] = str(Path(OPPO_FACE_RGB_ROOT))
    cfg["FACE_UV_ROOT"] = str(Path(OPPO_FACE_UV_ROOT))
    cfg["GLOBAL_RGB_ROOT"] = str(Path(OPPO_GLOBAL_RGB_ROOT))
    cfg["GT_EXCEL_PATH"] = str(Path(OPPO_GT_EXCEL_PATH))
    cfg["TRAIN_IDS"] = None
    cfg["TEST_IDS"] = None
    scenes = FINETUNE_SCENES
    if bool(AUTO_SCENES_FROM_SUFFIX) and _is_all_scenes(scenes):
        suffix_lower = str(OUTPUT_SUFFIX or "").lower()
        if "2v" in suffix_lower:
            scenes = "inLab2v"
    cfg["SCENES"] = scenes

    cfg["TRAIN_RATIO"] = float(TRAIN_RATIO)
    cfg["VAL_RATIO"] = float(VAL_RATIO)
    cfg["TEST_RATIO"] = float(TEST_RATIO)

    cfg["DEVICE"] = DEVICE
    cfg["TRAINING"]["batch_size"] = int(FINETUNE_BATCH_SIZE)
    cfg["TRAINING"]["num_epochs"] = int(FINETUNE_EPOCHS)
    cfg["TRAINING"]["learning_rate"] = float(FINETUNE_LR)
    cfg["TRAINING"]["early_stopping_patience"] = int(FINETUNE_EARLY_STOPPING_PATIENCE)

    base_output = Path(cfg["OUTPUT_DIR"])
    suffix = (OUTPUT_SUFFIX or "").strip()
    out = base_output.parent / f"{base_output.name}_{suffix}" if suffix else base_output
    cfg["OUTPUT_DIR"] = str(out)
    cfg["CHECKPOINT_DIR"] = str(out / "checkpoints")
    cfg["LOG_DIR"] = str(out / "logs")
    cfg["RESULT_DIR"] = str(out / "results")
    return cfg


def main() -> None:
    _ensure_repo_on_path()
    logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")

    from predict_p.trainer import Trainer

    ckpt = torch.load(BASE_CHECKPOINT, map_location="cpu")
    checkpoint_config = ckpt.get("config") if bool(USE_CHECKPOINT_CONFIG_AS_BASE) else None
    checkpoint_config = checkpoint_config if isinstance(checkpoint_config, dict) else None

    config = build_finetune_config(checkpoint_config=checkpoint_config)

    torch.manual_seed(config["RANDOM_SEED"])
    np.random.seed(config["RANDOM_SEED"])
    if torch.cuda.is_available():
        torch.cuda.manual_seed(config["RANDOM_SEED"])

    trainer = Trainer(config)

    state_dict = ckpt.get("model_state_dict", ckpt)
    strict = bool(LOAD_WEIGHTS_STRICT)
    missing, unexpected = trainer.model.load_state_dict(state_dict, strict=strict)
    logging.info("Loaded pretrained weights (strict=%s). missing=%d unexpected=%d", strict, len(missing), len(unexpected))

    trainer.train()
    trainer.test()


if __name__ == "__main__":
    main()
