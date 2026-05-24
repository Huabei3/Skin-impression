# 原作者DeepSkin项目部署指南

## 项目概述

这是原作者的完整实现，包含：
- **多流融合网络**：人脸流(RGB+UV) + 全局流 + 统计流
- **多任务学习**：同时预测喜好度评分和喜好中心(LAB)
- **完整的训练pipeline**：数据加载、模型训练、评估

## 项目结构

```
deepskin/
├── facial_preference/          # 主项目目录
│   ├── config.py              # 配置文件（需要修改数据路径）
│   ├── train.py               # 训练脚本
│   ├── inference.py           # 推理脚本
│   ├── data/                  # 数据加载模块
│   │   └── dataset.py
│   ├── models/                # 模型定义
│   │   ├── network.py         # 主网络
│   │   ├── face_stream.py     # 人脸流
│   │   ├── global_stream.py   # 全局流
│   │   ├── statistical_stream.py  # 统计流
│   │   ├── fusion.py          # 融合层
│   │   └── losses.py          # 损失函数
│   └── utils/                 # 工具函数
│       └── metrics.py
├── OPPOskinExpe/              # 大文件目录（需要从网盘下载）
└── output/                    # 输出目录（需要从网盘下载）
```

## 关键特性

### 1. 多流网络架构

**人脸流 (Face Stream)**
- RGB分支：ResNet50提取人脸RGB特征
- UV分支：轻量级CNN处理UV色彩空间数据（直方图）

**全局流 (Global Stream)**
- MobileNetV3提取全局场景特征

**统计流 (Statistical Stream)**
- 处理场景统计信息：亮度、色温、场景类别、性别、人种

**融合层**
- 多头注意力机制
- 自适应权重学习

### 2. 数据格式

```
数据目录/
├── face_rgb/              # 人脸RGB图像
│   └── 场景_人物/
│       └── 原名_face.jpg
├── face_uv/               # 人脸UV数据（直方图）
│   └── 场景_人物/
│       └── 原名_face_uv.npy
├── rendered_2max/         # 全局RGB图像
│   └── 场景_人物/
│       └── 原名.jpg
└── gt/
    └── Healthy_non_model_gt.xlsx  # GT标注
```

### 3. 训练配置

**当前config.py中的配置：**
- 数据路径：`I:\skin_data_2max\`
- 训练ID：`["01"]`
- 测试ID：`["01"]`
- Batch size：32
- Epochs：1000
- Learning rate：7e-4
- 损失权重：
  - alpha (score)：1.0
  - beta (center)：1.0
  - gamma (consistency)：0.7

## 部署步骤

### Step 1: 数据准备

**问题：** 大文件目录太大，无法直接上传

**解���方案：**
1. 从网盘下载数据：`Z:\homes\Max\deepskin`
2. 需要的数据：
   - `face_rgb/` - 人脸RGB图像
   - `face_uv/` - 人脸UV直方图
   - `rendered_2max/` - 全局RGB图像
   - `gt/Healthy_non_model_gt.xlsx` - GT标注

### Step 2: 修改配置文件

需要修改 `config.py` 中的路径：

```python
# 原配置（本地路径）
FACE_RGB_ROOT = Path(r"I:\skin_data_2max\rendered_face")
FACE_UV_ROOT = Path(r"I:\skin_data_2max\rendered_face_uv")
GT_EXCEL_PATH = Path(r"I:\skin_data_2max\gt\Healthy_non_model_gt.xlsx")
GLOBAL_RGB_ROOT = Path(r"I:\skin_data_2max\rendered_2max")

# 修改为云实例路径
FACE_RGB_ROOT = Path(r"/root/autodl-tmp/skin_data/rendered_face")
FACE_UV_ROOT = Path(r"/root/autodl-tmp/skin_data/rendered_face_uv")
GT_EXCEL_PATH = Path(r"/root/autodl-tmp/skin_data/gt/Healthy_non_model_gt.xlsx")
GLOBAL_RGB_ROOT = Path(r"/root/autodl-tmp/skin_data/rendered_2max")
OUTPUT_ROOT = Path(r"/root/autodl-tmp/deepskin/facial_preference/output")
```

### Step 3: 上传代码到云实例

```bash
# 在本地执行
cd D:\work\secondYearMaster\thesis\reference\appeal\algorithms\preference_evaluate\deepskin

# 上传facial_preference目录（不包括output和大文件）
scp -P 10845 -r facial_preference root@connect.westc.seetacloud.com:/root/autodl-tmp/deepskin/
```

### Step 4: 上传数据到云实例

**选项A：从本地上传（如果已下载）**
```bash
# 上传数据（这会很慢，因为文件很大）
scp -P 10845 -r I:\skin_data_2max root@connect.westc.seetacloud.com:/root/autodl-tmp/
```

**选项B：在云实例上从网盘下载（推荐）**
```bash
# SSH到云实例
ssh -p 10845 root@connect.westc.seetacloud.com

# 创建数据目录
mkdir -p /root/autodl-tmp/skin_data

# 从网盘下载（需要配置网盘访问）
# 或者使用其他方式传输大文件
```

### Step 5: 安装依赖

```bash
ssh -p 10845 root@connect.westc.seetacloud.com

cd /root/autodl-tmp/deepskin/facial_preference

# 安装依赖
/root/miniconda3/bin/pip install -r requirements.txt
```

### Step 6: 测试数据加载

```bash
cd /root/autodl-tmp/deepskin/facial_preference

# 测试数据集是否正确加载
/root/miniconda3/bin/python -c "
from config import Config
from data import create_data_loaders

train_loader, val_loader, test_loader = create_data_loaders(Config.get_config_dict())
print(f'Train samples: {len(train_loader.dataset)}')
print(f'Val samples: {len(val_loader.dataset)}')
print(f'Test samples: {len(test_loader.dataset)}')
"
```

### Step 7: 开始训练

```bash
cd /root/autodl-tmp/deepskin/facial_preference

nohup /root/miniconda3/bin/python train.py > train.log 2>&1 &

# 监控训练
tail -f train.log
```

## 关键验证点

### 1. 数据加载验证 ⭐⭐⭐

**检查内容：**
- 人脸RGB图像正确加载
- UV直方图数据正确加载
- 全局RGB图像正确加载
- GT标注正确读取
- 训练/验证/测试集划分正确

**验证方法：**
```python
from data import FacialPreferenceDataset
from config import Config

dataset = FacialPreferenceDataset(
    face_rgb_root=Config.FACE_RGB_ROOT,
    face_uv_root=Config.FACE_UV_ROOT,
    global_rgb_root=Config.GLOBAL_RGB_ROOT,
    gt_excel_path=Config.GT_EXCEL_PATH,
    split='train'
)

# 检查一个样本
sample = dataset[0]
print(f"Face RGB shape: {sample['face_rgb'].shape}")
print(f"Face UV shape: {sample['face_uv'].shape}")
print(f"Global RGB shape: {sample['global_rgb'].shape}")
print(f"Stats shape: {sample['stats'].shape}")
print(f"Score: {sample['score']}")
print(f"Center: {sample['center']}")
```

### 2. 模型架构验证 ⭐⭐

**检查内容：**
- 人脸流正确处理RGB和UV输入
- 全局流正确处理全局图像
- 统计流正确处理统计特征
- 融合层正确融合多流特征
- 预测头输出维度正确

**验证方法：**
```python
from models import create_model
from config import Config

model = create_model(Config.get_config_dict())
print(model)

# 测试前向传播
import torch
batch = {
    'face_rgb': torch.randn(2, 3, 224, 224),
    'face_uv': torch.randn(2, 2, 64, 64),  # UV直方图
    'global_rgb': torch.randn(2, 3, 224, 224),
    'stats': torch.randn(2, 13)
}

outputs = model(batch)
print(f"Score output: {outputs['score'].shape}")  # (2, 1)
print(f"Center output: {outputs['center'].shape}")  # (2, 2)
```

### 3. 损失函数验证 ⭐⭐

**检查内容：**
- 多任务损失正确计算
- 损失权重正确应用
- 一致性损失正确计算

**验证方法：**
查看训练日志中的损失值：
```
Epoch 1/1000
Train Loss: 0.xxxx (Score: 0.xxxx, Center: 0.xxxx, Consistency: 0.xxxx)
```

## 与我们之前实现的对比

| 特性 | 我们的实现 (MS-CAN) | 原作者实现 (DeepSkin) |
|------|---------------------|----------------------|
| 网络架构 | 单流ResNet50 | 多流融合（人脸+全局+统计） |
| 输入数据 | 仅人脸RGB | 人脸RGB + UV + 全局RGB + 统计 |
| 任务 | 单任务（评分）或多任务 | 多任务（评分+中心） |
| UV数据 | 未使用 | 使用UV直方图 |
| 统计特征 | 未使用 | 使用（亮度、色温、场景等） |
| 数据划分 | 按人划分 | 按场景-人物组合划分 |

## 预期性能

根据README.md中的目标：
- 喜好度评分 MAE < 0.05
- Pearson相关系数 > 0.85
- 平均色差 ΔE*ab < 5.0

## 常见问题

### Q1: UV数据是什么格式？

A: UV数据是直方图格式，存储为`.npy`文件，shape为`(2, 64, 64)`，表示U和V通道的2D直方图。

### Q2: 统计特征包含什么？

A: 13维特征：
- 5维：亮度统计（均值、标准差等）
- 1维：色温
- 2维：场景类别 (one-hot)
- 2维：性别 (one-hot)
- 3维：人种 (three-class one-hot)

### Q3: 数据太大怎么办？

A: 
1. 只上传必要的数据子集
2. 在云实例上直接从网盘下载
3. 使用数据压缩

### Q4: 如何修改训练配置？

A: 修改`config.py`中的相应参数：
- `TRAINING['batch_size']`：批次大小
- `TRAINING['num_epochs']`：训练轮数
- `TRAINING['learning_rate']`：学习率
- `LOSS['alpha']`, `LOSS['beta']`, `LOSS['gamma']`：损失权重

## 下一步计划

1. ✅ 检查原作者代码结构
2. ⏳ 停止云实例上当前训练
3. ⏳ 从网盘下载数据
4. ⏳ 修改config.py配置
5. ⏳ 上传代码到云实例
6. ⏳ 测试数据加载
7. ⏳ 开始训练
8. ⏳ 对比性能

## 注意事项

1. **数据路径**：确保所有路径都正确指向云实例上的数据位置
2. **依赖版本**：检查requirements.txt中的依赖是否与云实例环境兼容
3. **GPU内存**：多流网络可能需要更多GPU内存，注意batch size
4. **训练时间**：1000个epoch可能需要很长时间，建议先用少量epoch测试
