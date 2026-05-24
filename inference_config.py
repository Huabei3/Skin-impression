"""
推理配置文件 - 使用OPPO数据集和预训练模型
"""
from pathlib import Path

class InferenceConfig:
    """推理配置"""

    # ==================== 模型配置 ====================
    # 预训练模型路径
    CHECKPOINT_PATH = Path(__file__).parent / "pretrained_models/Universal_preference_V3_best.pth"

    # 设备
    DEVICE = 'cuda'  # 'cuda' or 'cpu'

    # ==================== 数据路径配置 ====================
    # 使用Z盘的数据（只读，不修改）
    DATA_ROOT = Path(r"Z:\homes\Max\deepskin\OPPOskinExpe")

    # 人脸RGB图像根目录
    FACE_RGB_ROOT = DATA_ROOT / "rendered_face"

    # 人脸UV数据根目录
    FACE_UV_ROOT = DATA_ROOT / "rendered_face_uv"

    # 全局RGB图像根目录
    GLOBAL_RGB_ROOT = DATA_ROOT / "rendered"

    # GT Excel文件路径
    GT_EXCEL_PATH = DATA_ROOT / "oppo_preference_gt.xlsx"

    # ==================== 数据集配置 ====================
    # 数据集划分比例
    TRAIN_RATIO = 0.4
    VAL_RATIO = 0.3
    TEST_RATIO = 0.3

    # 随机种子
    RANDOM_SEED = 42

    # 允许的场景（None表示全部）
    ALLOWED_SCENES = None  # 或者 ['inLab', 'outdoor', 'indoor', 'night', 'sunset']

    # ==================== 推理配置 ====================
    BATCH_SIZE = 8
    NUM_WORKERS = 2

    # 输出目录
    OUTPUT_DIR = Path(__file__).parent / "inference_results"

    @classmethod
    def validate(cls):
        """验证配置"""
        errors = []

        # 检查模型文件
        if not cls.CHECKPOINT_PATH.exists():
            errors.append(f"模型文件不存在: {cls.CHECKPOINT_PATH}")

        # 检查数据路径
        if not cls.DATA_ROOT.exists():
            errors.append(f"数据根目录不存在: {cls.DATA_ROOT}")

        if not cls.FACE_RGB_ROOT.exists():
            errors.append(f"人脸RGB目录不存在: {cls.FACE_RGB_ROOT}")

        if not cls.FACE_UV_ROOT.exists():
            errors.append(f"人脸UV目录不存在: {cls.FACE_UV_ROOT}")

        if not cls.GLOBAL_RGB_ROOT.exists():
            errors.append(f"全局RGB目录不存在: {cls.GLOBAL_RGB_ROOT}")

        if not cls.GT_EXCEL_PATH.exists():
            errors.append(f"GT文件不存在: {cls.GT_EXCEL_PATH}")

        if errors:
            print("[ERROR] Configuration validation failed:")
            for error in errors:
                print(f"  - {error}")
            return False
        else:
            print("[OK] Configuration validation passed")
            return True

    @classmethod
    def print_config(cls):
        """Print configuration info"""
        print("=" * 80)
        print("Inference Configuration")
        print("=" * 80)
        print(f"\nModel Config:")
        print(f"  Checkpoint: {cls.CHECKPOINT_PATH}")
        print(f"  Device: {cls.DEVICE}")

        print(f"\nData Paths:")
        print(f"  Data Root: {cls.DATA_ROOT}")
        print(f"  Face RGB: {cls.FACE_RGB_ROOT}")
        print(f"  Face UV: {cls.FACE_UV_ROOT}")
        print(f"  Global RGB: {cls.GLOBAL_RGB_ROOT}")
        print(f"  GT File: {cls.GT_EXCEL_PATH}")

        print(f"\nDataset Config:")
        print(f"  Split Ratio: train={cls.TRAIN_RATIO}, val={cls.VAL_RATIO}, test={cls.TEST_RATIO}")
        print(f"  Random Seed: {cls.RANDOM_SEED}")
        print(f"  Allowed Scenes: {cls.ALLOWED_SCENES or 'All'}")

        print(f"\nInference Config:")
        print(f"  Batch Size: {cls.BATCH_SIZE}")
        print(f"  Num Workers: {cls.NUM_WORKERS}")
        print(f"  Output Dir: {cls.OUTPUT_DIR}")
        print("=" * 80)


if __name__ == '__main__':
    # 测试配置
    InferenceConfig.print_config()
    InferenceConfig.validate()
