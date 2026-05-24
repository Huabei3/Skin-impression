#!/bin/bash
set -e

echo "=========================================="
echo "DeepSkin 环境配置脚本"
echo "=========================================="

# 激活conda环境
source /root/miniconda3/bin/activate deepskin
cd /root/autodl-tmp/deepskin

echo ""
echo "1. 安装PyTorch和相关库..."
pip install torch==2.0.1 torchvision==0.15.2 torchaudio==2.0.2 --index-url https://download.pytorch.org/whl/cu118

echo ""
echo "2. 验证PyTorch安装..."
python -c "import torch; print(f'PyTorch: {torch.__version__}'); print(f'CUDA available: {torch.cuda.is_available()}'); print(f'CUDA version: {torch.version.cuda}'); print(f'GPU: {torch.cuda.get_device_name(0) if torch.cuda.is_available() else \"N/A\"}')"

echo ""
echo "3. 安装项目依赖..."
pip install -r facial_preference/requirements.txt

echo ""
echo "4. 验证所有依赖..."
python -c "
import torch
import torchvision
import numpy as np
import pandas as pd
from PIL import Image
import matplotlib
print('✓ 所有依赖安装成功!')
print(f'  - PyTorch: {torch.__version__}')
print(f'  - NumPy: {np.__version__}')
print(f'  - Pandas: {pd.__version__}')
"

echo ""
echo "=========================================="
echo "环境配置完成！"
echo "=========================================="
