#!/bin/bash
# ============================================================
# predict_p 环境测试脚本
# 运行完整训练前先跑这个，确保环境配置正确
# ============================================================

set -e

PROJECT_ROOT="/root/autodl-tmp/deepskin/predict_p"
DATA_ROOT="/root/autodl-tmp/toMax"

echo "=========================================="
echo "predict_p 环境测试"
echo "=========================================="

# 测试 Python 和 torch
echo ""
echo "[1/4] 检查 Python 环境..."
python3 -c "import torch; print(f'  ✅ PyTorch {torch.__version__}'); print(f'  ✅ CUDA available: {torch.cuda.is_available()}'); print(f'  ✅ GPU: {torch.cuda.get_device_name(0) if torch.cuda.is_available() else \"无\"}')"

# 测试数据路径
echo ""
echo "[2/4] 检查数据路径..."
python3 << 'PYEOF'
import os
from pathlib import Path

paths = {
    "FACE_RGB": "/root/autodl-tmp/toMax/rendered_face",
    "FACE_UV": "/root/autodl-tmp/toMax/rendered_face_uv",
    "GLOBAL_RGB": "/root/autodl-tmp/toMax/rendered_2max",
    "GT_EXCEL": "/root/autodl-tmp/toMax/gt/Preference_non_model_gt.xlsx",
}

all_ok = True
for name, path in paths.items():
    if Path(path).exists():
        if name == "FACE_UV":
            count = len(list(Path(path).rglob("*.npy")))
            print(f"  ✅ {name}: {count} files")
        elif Path(path).is_file():
            print(f"  ✅ {name}: {Path(path).name}")
        else:
            count = len(list(Path(path).rglob("*.jpg"))) + len(list(Path(path).rglob("*.png")))
            print(f"  ✅ {name}: {count} files")
    else:
        print(f"  ❌ {name}: 不存在")
        all_ok = False

# 测试GT Excel
import pandas as pd
try:
    df = pd.read_excel("/root/autodl-tmp/toMax/gt/Preference_non_model_gt.xlsx")
    print(f"  ✅ GT Excel: {len(df)} rows, columns: {list(df.columns)[:5]}...")
except Exception as e:
    print(f"  ❌ GT Excel读取失败: {e}")
    all_ok = False

if all_ok:
    print("\n  🎉 所有数据路径检查通过!")
else:
    print("\n  ⚠️ 部分数据路径缺失")
    exit(1)
PYEOF

# 测试模块导入
echo ""
echo "[3/4] 检查 predict_p 模块..."
cd "$PROJECT_ROOT"
python3 -c "from predict_p.config import Config; print('  ✅ predict_p.config 导入成功')" || echo "  ❌ predict_p.config 导入失败"
python3 -c "from predict_p.models.network import Network; print('  ✅ predict_p.models.network 导入成功')" || echo "  ❌ predict_p.models.network 导入失败"

# 测试数据集
echo ""
echo "[4/4] 测试数据集加载 (只加载2个batch)..."
python3 << 'PYEOF'
import sys
sys.path.insert(0, "/root/autodl-tmp/deepskin")

from predict_p.config import Config
from predict_p.data.dataset import FaceDataset

try:
    config = Config.get_config_dict()
    config["DATALOADER"]["num_workers"] = 0  # 测试时用0

    dataset = FaceDataset(config)
    print(f"  ✅ Dataset创建成功: {len(dataset)} 样本")

    # 测试加载几个样本
    if len(dataset) > 0:
        sample = dataset[0]
        print(f"  ✅ 样本加载成功")
        print(f"     - face_rgb shape: {sample.get('face_rgb', 'N/A')}")
        print(f"     - global_rgb shape: {sample.get('global_rgb', 'N/A')}")
        print(f"     - label: {sample.get('label', 'N/A')}")
        print(f"     - uv_available: {sample.get('uv_available', False)}")
except Exception as e:
    print(f"  ❌ Dataset测试失败: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)

print("\n  🎉 环境测试全部通过!")
PYEOF

echo ""
echo "=========================================="
echo "✅ 可以开始训练了!"
echo ""
echo "训练命令:"
echo "  bash ${PROJECT_ROOT}/train_predict_p.sh v3"
echo "=========================================="