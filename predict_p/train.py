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


# 人种配置映射
# key: race, value: {test_male_model, valid_female_r_prefixes, model_ids}
_RACE_CONFIG = {
    "CA": {
        "test_male": "m02",        # test = m02全部图片
        "valid_female_r_prefixes": ["f02rrs02", "f02rrs04"],  # valid = f02r的rs02+rs04
        "model_ids": ["01", "02", "03"],  # CA: {f/m}01-03
    },
    "AS": {
        "test_male": "m05",
        "valid_female_r_prefixes": ["f05rrs02", "f05rrs04"],
        "model_ids": ["04", "05", "06"],  # AS: {f/m}04-06
    },
    "SA": {
        "test_male": "m08",
        "valid_female_r_prefixes": ["f08rrs02", "f08rrs04"],
        "model_ids": ["07", "08"],  # SA: {f/m}07-08
    },
    "AF": {
        "test_male": "m09",
        "valid_female_r_prefixes": ["f09rrs02", "f09rrs04"],
        "model_ids": ["09", "10"],  # AF: {f/m}09-10
    },
}


def _apply_race_overrides(config: dict, race: str) -> None:
    """覆盖配置为按人种分组训练模式。
    
    设置:
    - SPLIT_STRATEGY = "manual_prefix"
    - TEST_PREFIXES = [test模特的全部前缀]
    - VALID_PREFIXES = [同人种女性r的固定场景]
    - MODEL_NAME 改为 predict_p_{race}
    - SPLIT_EXPORT_PATH 指向输出目录
    """
    rc = _RACE_CONFIG[race]
    test_male = rc["test_male"]
    valid_f_prefixes = rc["valid_female_r_prefixes"]
    
    # 构建 test 前缀：test模特的 i+r 全部场景
    # i 场景: {m}XXih3k, {m}XXih4k, ..., {m}XXimd65 (21个)
    # r 场景: {m}XXrrs01 ... {m}XXrrs14 (14个)
    i_scenes = ["h3k", "h4k", "h5k", "h6k", "h7k", "h8k", "hd65",
                "l3k", "l4k", "l5k", "l6k", "l7k", "l8k", "ld65",
                "m3k", "m4k", "m5k", "m6k", "m7k", "m8k", "md65"]
    r_scenes = [f"rs{s:02d}" for s in range(1, 15)]
    
    test_prefixes = []
    for s in i_scenes:
        test_prefixes.append(f"{test_male}i{s}")
    for s in r_scenes:
        test_prefixes.append(f"{test_male}r{s}")
    
    config["SPLIT_STRATEGY"] = "manual_prefix"
    config["TEST_PREFIXES"] = test_prefixes
    config["VALID_PREFIXES"] = valid_f_prefixes
    # manual_prefix 策略下，用编号过滤限制在人种范围内（前缀精确控制 train/val/test 分配）
    config["TRAIN_IDS"] = rc["model_ids"]
    config["TEST_IDS"] = rc["model_ids"]
    
    # 修改输出目录
    model_name = f"predict_p_{race}"
    config["MODEL_NAME"] = model_name
    output_root = Path(str(config["OUTPUT_ROOT"]))
    output_dir = output_root / model_name
    config["OUTPUT_DIR"] = str(output_dir)
    config["CHECKPOINT_DIR"] = str(output_dir / "checkpoints")
    config["LOG_DIR"] = str(output_dir / "logs")
    config["RESULT_DIR"] = str(output_dir / "results")
    config["SPLIT_EXPORT_PATH"] = str(output_dir / "split_result.xlsx")


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
    parser.add_argument(
        "--race",
        choices=["CA", "AS", "SA", "AF"],
        default=None,
        help="Train on a specific race subset (CA/AS/SA/AF). Overrides split strategy to manual_prefix.",
    )
    parser.add_argument(
        "--data-root",
        type=str,
        default=None,
        help="Override data root directory (e.g., /root/autodl-tmp). "
             "Will set FACE_RGB_ROOT=<data-root>/rendered_face, "
             "FACE_UV_ROOT=<data-root>/rendered_face_uv, "
             "GLOBAL_RGB_ROOT=<data-root>/rendered_2max, "
             "GT_EXCEL_PATH=<data-root>/gt/Preference_non_model_gt.xlsx",
    )
    parser.add_argument(
        "--gt-excel",
        type=str,
        default=None,
        help="Override GT Excel file path directly (e.g., .../toMax_gt.xlsx). "
             "If --data-root is also set, this takes priority.",
    )
    parser.add_argument(
        "--output-root",
        type=str,
        default=None,
        help="Override output root directory (e.g., /root/autodl-tmp/deepskin/predict_p/output)",
    )
    args = parser.parse_args()

    config = Config.get_config_dict()
    # 云端数据路径覆盖
    if args.data_root is not None:
        data_root = Path(args.data_root)
        config["FACE_RGB_ROOT"] = str(data_root / "rendered_face")
        config["FACE_UV_ROOT"] = str(data_root / "rendered_face_uv")
        config["GLOBAL_RGB_ROOT"] = str(data_root / "rendered_2max")
        config["GT_EXCEL_PATH"] = str(data_root / "gt" / "Preference_non_model_gt.xlsx")
    if args.gt_excel is not None:
        config["GT_EXCEL_PATH"] = str(Path(args.gt_excel))
    if args.output_root is not None:
        config["OUTPUT_ROOT"] = str(Path(args.output_root))
        # 重新推导 output/checkpoint/log/result 目录（model_variant 和 race 后续可能还会改）
        # 这里先设 OUTPUT_ROOT，后续 _apply_race_overrides 会根据 OUTPUT_ROOT 重新设置子目录
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

    # ========== 人种分组训练覆盖 ==========
    if args.race is not None:
        _apply_race_overrides(config, args.race)
    # =====================================

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
