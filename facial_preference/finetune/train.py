"""
OPPO finetune script - 在 OPPO 数据集上微调人脸颜色喜好度模型

特点:
- 从已有的训练好模型检查点加载权重
- 在 OPPO 数据上继续训练 (finetune)
- 所有输入路径和超参数都在本文件中配置, 运行时无需传入参数
"""

from __future__ import annotations

import logging
import sys
from pathlib import Path
from typing import Dict

import numpy as np
import torch

# ==================== 用户可配置区域 (直接修改下面这些常量) ====================

# 1) 预训练模型检查点路径 (请改成你自己训练好的 best_model.pth)
# 例如:
# BASE_CHECKPOINT = r"F:\Github\deepskin\facial_preference\output\test\checkpoints\ids_train_all__test_all\best_model.pth"
BASE_CHECKPOINT: str = r"F:\Github\deepskin\facial_preference\output\Universal_preference_V2\checkpoints\ids_train_all__test_all\best_model.pth"

# 2) OPPO 数据路径 (由 tools/gather_gt_oppo.py 和重命名脚本生成的数据)
OPPO_FACE_RGB_ROOT: str = r"I:\OPPOskinExpe\rendered_face"
OPPO_GLOBAL_RGB_ROOT: str = r"I:\OPPOskinExpe\rendered"
OPPO_FACE_UV_ROOT: str = r"I:\OPPOskinExpe\rendered_face_uv"
OPPO_GT_EXCEL_PATH: str = r"I:\OPPOskinExpe\oppo_preference_gt.xlsx"

# 3) 数据集划分比例 (train/val/test)
TRAIN_RATIO: float = 0.4
VAL_RATIO: float = 0.3
TEST_RATIO: float = 0.3

# 4) 微调训练超参数
FINETUNE_BATCH_SIZE: int = 32
FINETUNE_EPOCHS: int = 200
FINETUNE_LR: float = 7e-4

# 5) 输出目录后缀 (会在原 OUTPUT_DIR 名称后面加上该后缀, 避免覆盖原模型)
OUTPUT_SUFFIX: str = "oppo_finetune"

# 6) 设备: "cuda" 或 "cpu"
DEVICE: str = "cuda"

# ======================================================================


# 确保项目根目录在 sys.path 中, 便于作为脚本直接运行
PROJECT_ROOT = Path(__file__).resolve().parents[2]
if str(PROJECT_ROOT) not in sys.path:
    sys.path.append(str(PROJECT_ROOT))

# 兼容作为脚本运行与包导入的双路径导入
try:
    # 首选通过包名导入, 避免与当前文件名冲突
    from facial_preference.config import Config  # type: ignore
    from facial_preference.train import Trainer as BaseTrainer  # type: ignore
except ModuleNotFoundError:  # pragma: no cover - fallback: 在 facial_preference 目录下运行
    from config import Config  # type: ignore
    from train import Trainer as BaseTrainer  # type: ignore


logger = logging.getLogger(__name__)


def build_finetune_config() -> Dict:
    """
    基于 Config 和本文件顶部的常量构造用于微调的配置字典。

    注意:
    - 数据路径相关参数直接修改 Config 类属性, 以便 Trainer 内部
      调用 create_data_loaders(Config.get_config_dict()) 时生效
    - 输出目录仅在返回的 config 字典中覆盖, 不影响全局 Config
    """
    # -------- 覆盖数据路径到 OPPO 数据 --------
    Config.FACE_RGB_ROOT = Path(OPPO_FACE_RGB_ROOT)
    Config.FACE_UV_ROOT = Path(OPPO_FACE_UV_ROOT)
    Config.GLOBAL_RGB_ROOT = Path(OPPO_GLOBAL_RGB_ROOT)
    Config.GT_EXCEL_PATH = Path(OPPO_GT_EXCEL_PATH)

    # -------- 禁用按 TRAIN_IDS/TEST_IDS 过滤 (OPPO sheet 名不符合原始编号规则) --------
    Config.TRAIN_IDS = None
    Config.TEST_IDS = None

    # -------- 覆盖数据集划分比例 --------
    Config.TRAIN_RATIO = float(TRAIN_RATIO)
    Config.VAL_RATIO = float(VAL_RATIO)
    Config.TEST_RATIO = float(TEST_RATIO)

    # -------- 覆盖训练超参数 --------
    Config.TRAINING["batch_size"] = int(FINETUNE_BATCH_SIZE)
    Config.TRAINING["num_epochs"] = int(FINETUNE_EPOCHS)
    Config.TRAINING["learning_rate"] = float(FINETUNE_LR)

    # 生成基础配置字典
    cfg = Config.get_config_dict()

    # 设备覆盖: 同时修改 Config 和 cfg
    Config.DEVICE = DEVICE
    cfg["DEVICE"] = DEVICE

    # -------- 为微调输出创建单独的目录 --------
    base_output = Path(cfg["OUTPUT_DIR"])
    suffix = (OUTPUT_SUFFIX or "").strip()
    if suffix:
        new_output = base_output.parent / f"{base_output.name}_{suffix}"
    else:
        new_output = base_output

    cfg["OUTPUT_DIR"] = str(new_output)
    cfg["CHECKPOINT_DIR"] = str(new_output / "checkpoints")
    cfg["LOG_DIR"] = str(new_output / "logs")
    cfg["RESULT_DIR"] = str(new_output / "results")

    return cfg


class FineTuneTrainer(BaseTrainer):
    """
    微调版 Trainer:
    - 继承原有 Trainer 的完整训练 / 验证 / 测试逻辑
    - 在初始化完成后, 额外从给定 checkpoint 加载模型权重
    """

    def __init__(self, config: Dict, checkpoint_path: str):
        self.pretrained_checkpoint = Path(checkpoint_path)
        if not self.pretrained_checkpoint.is_file():
            raise FileNotFoundError(
                f"Checkpoint not found: {self.pretrained_checkpoint}"
            )

        # 先按新的配置初始化数据加载器、模型、优化器等
        super().__init__(config)

        # 然后加载预训练权重 (只加载模型参数, 不加载优化器状态)
        logger.info(f"Loading pretrained weights from: {self.pretrained_checkpoint}")
        checkpoint = torch.load(self.pretrained_checkpoint, map_location=self.device)
        state_dict = checkpoint.get("model_state_dict", checkpoint)

        missing, unexpected = self.model.load_state_dict(state_dict, strict=False)

        if missing:
            logger.warning(
                "Some parameters were not found in checkpoint and "
                "remain randomly initialized: %s",
                ", ".join(missing),
            )
        if unexpected:
            logger.warning(
                "Checkpoint contained unexpected keys that were ignored: %s",
                ", ".join(unexpected),
            )

        logger.info("Pretrained weights loaded, starting finetuning.")


def main() -> None:
    # 基本日志配置
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s - %(levelname)s - %(message)s",
    )

    # 构造用于微调的配置
    config = build_finetune_config()

    # 设置随机种子, 与原 train.py 保持一致
    torch.manual_seed(config["RANDOM_SEED"])
    np.random.seed(config["RANDOM_SEED"])
    if torch.cuda.is_available():
        torch.cuda.manual_seed(config["RANDOM_SEED"])

    # 创建微调 Trainer 并运行
    trainer = FineTuneTrainer(config, checkpoint_path=BASE_CHECKPOINT)
    trainer.train()
    trainer.test()


if __name__ == "__main__":
    main()

