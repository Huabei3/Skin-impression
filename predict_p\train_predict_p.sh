#!/bin/bash
# ============================================================
# predict_p 训练脚本 - 保姆级教程
# 使用方法: bash train_predict_p.sh [v1|v2|v3]
# 默认训练 v3 (RGB-only，不需要UV)
# ============================================================

set -e  # 遇到错误就退出

# ---------------------- 配置区 ----------------------
# 云端数据路径 (根据你的实际情况修改)
FACE_RGB_ROOT="/root/autodl-tmp/toMax/rendered_face"
FACE_UV_ROOT="/root/autodl-tmp/toMax/rendered_face_uv"
GLOBAL_RGB_ROOT="/root/autodl-tmp/toMax/rendered_2max"
GT_EXCEL_PATH="/root/autodl-tmp/toMax/gt/Preference_non_model_gt.xlsx"

# 输出路径
PROJECT_ROOT="/root/autodl-tmp/deepskin/predict_p"
OUTPUT_ROOT="${PROJECT_ROOT}/output"

# 训练参数
MODEL_VARIANT="${1:-v3}"  # 默认 v3
BATCH_SIZE=256
NUM_EPOCHS=1000
LEARNING_RATE=7e-4
NUM_WORKERS=4

# ---------------------- 环境检查 ----------------------
echo "=========================================="
echo "predict_p 训练脚本"
echo "=========================================="
echo "Python: $(which python3)"
echo "Conda环境: $CONDA_DEFAULT_ENV"
echo "GPU: $(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null || echo '无')"
echo "=========================================="

# ---------------------- 数据检查 ----------------------
echo ""
echo "[1/5] 检查数据路径..."
for path in "$FACE_RGB_ROOT" "$GLOBAL_RGB_ROOT" "$GT_EXCEL_PATH"; do
    if [ -d "$path" ] || [ -f "$path" ]; then
        echo "  ✅ $path"
    else
        echo "  ❌ 缺失: $path"
        exit 1
    fi
done

# 检查UV (v1/v2需要)
if [ "$MODEL_VARIANT" = "v1" ] || [ "$MODEL_VARIANT" = "v2" ]; then
    if [ ! -d "$FACE_UV_ROOT" ]; then
        echo "  ❌ v1/v2 需要UV数据，但 $FACE_UV_ROOT 不存在"
        exit 1
    fi
    UV_COUNT=$(find "$FACE_UV_ROOT" -type f | wc -l)
    echo "  📊 UV文件数量: $UV_COUNT"
fi

# ---------------------- 创建配置 ----------------------
echo ""
echo "[2/5] 创建临时配置..."

# 创建临时配置文件，修改数据路径
cat > "${PROJECT_ROOT}/config_cloud.py" << 'EOF'
"""云端训练配置 - 覆盖默认路径"""
from pathlib import Path
import sys

# 向上找两层到 predict_p 目录
PROJECT_ROOT = Path(__file__).resolve().parent
sys.path.insert(0, str(PROJECT_ROOT.parent))

# 导入原始配置
from predict_p.config import Config as BaseConfig

class CloudConfig(BaseConfig):
    # ==================== 云端数据路径 ====================
    FACE_RGB_ROOT = Path("/root/autodl-tmp/toMax/rendered_face")
    FACE_UV_ROOT = Path("/root/autodl-tmp/toMax/rendered_face_uv")
    GLOBAL_RGB_ROOT = Path("/root/autodl-tmp/toMax/rendered_2max")
    GT_EXCEL_PATH = Path("/root/autodl-tmp/toMax/gt/Preference_non_model_gt.xlsx")

    # UV设置
    FACE_UV_IS_HIST = False

    # ==================== 输出路径 ====================
    OUTPUT_ROOT = PROJECT_ROOT / "output"

    # ==================== 训练参数 ====================
    TRAINING = {
        **BaseConfig.TRAINING,
        "batch_size": 256,
        "num_epochs": 1000,
        "learning_rate": 7e-4,
        "mixed_precision": True,
    }

    # ==================== DataLoader ====================
    DATALOADER = {
        "num_workers": 4,
        "pin_memory": True,
        "persistent_workers": False,
        "prefetch_factor": 2,
    }

    # ==================== Device ====================
    DEVICE = "cuda"

    @classmethod
    def get_config_dict(cls) -> dict:
        cfg = {}
        for key in dir(cls):
            if not key.startswith("_") and key.isupper():
                value = getattr(cls, key)
                if isinstance(value, Path):
                    cfg[key] = str(value)
                elif isinstance(value, dict):
                    # 合并配置
                    if key == "TRAINING":
                        # 使用云端覆盖值
                        orig = BaseConfig.TRAINING.copy()
                        orig.update(value)
                        cfg[key] = orig
                    else:
                        cfg[key] = value
                else:
                    cfg[key] = value
        return cfg

# 导出
Config = CloudConfig
EOF

echo "  ✅ 配置文件已创建: ${PROJECT_ROOT}/config_cloud.py"

# ---------------------- 开始训练 ----------------------
echo ""
echo "[3/5] 准备训练环境..."
cd "$PROJECT_ROOT"

# 确保输出目录存在
mkdir -p "${OUTPUT_ROOT}"

echo ""
echo "[4/5] 开始训练..."
echo "  模型变体: $MODEL_VARIANT"
echo "  Batch Size: $BATCH_SIZE"
echo "  Learning Rate: $LEARNING_RATE"
echo "  Epochs: $NUM_EPOCHS"
echo ""

# 激活conda环境 (如果有)
if [ -f "/root/miniconda3/etc/profile.d/conda.sh" ]; then
    source /root/miniconda3/etc/profile.d/conda.sh
    conda activate deepskin
fi

# 训练命令
python3 train.py \
    --model-variant "$MODEL_VARIANT" \
    --num-workers "$NUM_WORKERS" \
    2>&1 | tee "${PROJECT_ROOT}/training.log"

echo ""
echo "[5/5] 训练完成!"
echo "  日志: ${PROJECT_ROOT}/training.log"
echo "  模型: ${OUTPUT_ROOT}/predict_p_${MODEL_VARIANT}/checkpoints/"
echo "=========================================="