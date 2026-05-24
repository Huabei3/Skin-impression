#!/bin/bash
# DeepSkin 云实例传输脚本
# 使用方法: ./transfer_to_cloud.sh [cloud_host]
# 示例: ./transfer_to_cloud.sh seetacloud-skin

CLOUD_HOST=${1:-seetacloud-skin}
REMOTE_DIR="/root/workspace/deepskin"

echo "=== DeepSkin 云实例传输 ==="
echo "目标主机: $CLOUD_HOST"
echo "远程目录: $REMOTE_DIR"
echo ""

# 测试连接
echo "1. 测试云实例连接..."
if ! ssh -o ConnectTimeout=5 $CLOUD_HOST "echo 'Connection OK'"; then
    echo "错误: 无法连接到云实例"
    echo "请检查:"
    echo "  - 实例是否已启动"
    echo "  - SSH 端口是否正确 (检查 ~/.ssh/config)"
    echo "  - 网络连接是否正常"
    exit 1
fi

# 创建远程目录
echo -e "\n2. 创建远程目录..."
ssh $CLOUD_HOST "mkdir -p $REMOTE_DIR/{pretrained_models,data}"

# 传输代码文件
echo -e "\n3. 传输代码文件 (~1MB)..."
rsync -avz --progress \
    facial_preference/ \
    $CLOUD_HOST:$REMOTE_DIR/facial_preference/

rsync -avz --progress \
    inference_config.py \
    run_inference.py \
    test_data_loading.py \
    $CLOUD_HOST:$REMOTE_DIR/

# 传输预训练模型
echo -e "\n4. 传输预训练模型 (310MB)..."
rsync -avz --progress \
    pretrained_models/Universal_preference_V3_best.pth \
    $CLOUD_HOST:$REMOTE_DIR/pretrained_models/

# 传输数据集
echo -e "\n5. 传输 OPPO 数据集..."
echo "数据集位置: Z:/homes/Max/deepskin/OPPOskinExpe/"
read -p "是否传输数据集? (y/n): " transfer_data

if [ "$transfer_data" = "y" ]; then
    echo "传输 GT 标注文件..."
    rsync -avz --progress \
        Z:/homes/Max/deepskin/OPPOskinExpe/oppo_preference_gt.xlsx \
        $CLOUD_HOST:$REMOTE_DIR/data/

    echo "传输图像数据 (rendered, rendered_face, rendered_face_uv)..."
    rsync -avz --progress \
        Z:/homes/Max/deepskin/OPPOskinExpe/rendered/ \
        $CLOUD_HOST:$REMOTE_DIR/data/rendered/

    rsync -avz --progress \
        Z:/homes/Max/deepskin/OPPOskinExpe/rendered_face/ \
        $CLOUD_HOST:$REMOTE_DIR/data/rendered_face/

    rsync -avz --progress \
        Z:/homes/Max/deepskin/OPPOskinExpe/rendered_face_uv/ \
        $CLOUD_HOST:$REMOTE_DIR/data/rendered_face_uv/
else
    echo "跳过数据集传输"
fi

# 验证传输
echo -e "\n6. 验证传输完整性..."
ssh $CLOUD_HOST "ls -lh $REMOTE_DIR/"
ssh $CLOUD_HOST "ls -lh $REMOTE_DIR/pretrained_models/"
ssh $CLOUD_HOST "du -sh $REMOTE_DIR/"

echo -e "\n=== 传输完成 ==="
echo "远程目录: $CLOUD_HOST:$REMOTE_DIR"
echo ""
echo "下一步:"
echo "  1. SSH 登录: ssh $CLOUD_HOST"
echo "  2. 进入目录: cd $REMOTE_DIR"
echo "  3. 安装依赖: pip install torch torchvision pandas openpyxl pillow"
echo "  4. 运行推理: python run_inference.py"
