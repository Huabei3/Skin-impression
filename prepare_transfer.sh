#!/bin/bash
# DeepSkin 传输准备脚本

echo "=== DeepSkin 传输文件清单 ==="

echo -e "\n1. 代码文件:"
find facial_preference -name "*.py" | wc -l
echo "   Python 文件数量: $(find facial_preference -name "*.py" | wc -l)"

echo -e "\n2. 配置和脚本:"
ls -lh inference_config.py run_inference.py test_data_loading.py 2>/dev/null

echo -e "\n3. 预训练模型:"
ls -lh pretrained_models/*.pth

echo -e "\n4. 数据集位置:"
echo "   Z:/homes/Max/deepskin/OPPOskinExpe/"

echo -e "\n=== 准备传输包 ==="
echo "创建临时目录..."
mkdir -p /tmp/deepskin_transfer

echo "复制代码文件..."
cp -r facial_preference /tmp/deepskin_transfer/
cp inference_config.py run_inference.py test_data_loading.py /tmp/deepskin_transfer/ 2>/dev/null

echo -e "\n传输包准备完成: /tmp/deepskin_transfer/"
du -sh /tmp/deepskin_transfer/
