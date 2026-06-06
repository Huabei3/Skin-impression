# SCUT-FBP ResNet-18 在 deepskin 上训练

## 项目说明

基于华南理工 SCUT-FBP5500 的 ResNet-18 回归模型，用 torchvision 预训练权重，在 deepskin 数据集上微调，作为 IQA 对比实验的 CNN baseline。

- 输入: 256×256 → RandomCrop 224×224 RGB 人脸
- 输出: preference score [0, 1]
- 损失: MSE
- 指标: PLCC / SRCC / MAE / RMSE

---

## Step 1: 生成数据文件

```bash
cd /root/autodl-tmp/deepskin
. /root/miniconda3/etc/profile.d/conda.sh
conda activate deepskin

python prepare/prepare_scut_data.py
# 输出: /root/autodl-tmp/deepskin/prepare/scut_deepskin_train.txt (23100 行)
```

## Step 2: 训练

```bash
python prepare/train_scut_resnet.py \
  --data /root/autodl-tmp/deepskin/prepare/scut_deepskin_train.txt \
  --output /root/autodl-tmp/deepskin/prepare/checkpoints \
  --batch-size 32 --epochs 50 --lr 1e-4
```

## 参数

| 参数 | 默认值 | 说明 |
|------|--------|------|
| `--data` | (必须) | 数据文件路径 |
| `--output` | `./checkpoints` | 权重保存目录 |
| `--batch-size` | 32 | 批大小 |
| `--epochs` | 50 | 训练轮数 |
| `--lr` | 1e-4 | 学习率 |
| `--val-split` | 0.2 | 验证集比例 |
| `--num-workers` | 4 | DataLoader 线程数 |

## 输出

```
Epoch   1/50 | Loss=0.0234 | MAE=0.1234 | PLCC=0.7234 | SRCC=0.7102
Epoch   2/50 | Loss=0.0189 | MAE=0.1102 | PLCC=0.7512 | SRCC=0.7388
...
>>> Best SRCC=0.8102 saved
```

权重保存在 `--output` 目录下。
