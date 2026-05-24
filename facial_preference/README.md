# 人脸颜色喜好度预测网络

## 项目概述

这是一个基于深度学习的人脸颜色喜好度预测系统，使用多流融合网络架构来预测图像中人脸颜色的主观喜好度评分以及喜好中心的LAB色彩坐标。

## 系统架构

### 多流网络设计
1. **人脸流 (Face Stream)**
   - RGB分支：使用预训练的ResNet50提取人脸特征
   - UV分支：专门设计的轻量级CNN处理UV色彩空间数据
   
2. **全局流 (Global Stream)**
   - 使用MobileNetV3捕捉全局场景信息
   
3. **统计流 (Statistical Stream)**
   - 处理场景统计信息（亮度、色温、场景类别等）

4. **特征融合层**
   - 多头注意力机制
   - 自适应权重学习
   - 跨模态信息交互

## 数据组织结构

```
数据目录/
├── face_rgb/              # 人脸RGB图像
│   └── 场景_人物/
│       └── 原名_face.jpg
├── face_uv/               # 人脸UV数据
│   └── 场景_人物/
│       └── 原名_face_uv.npy
└── ground_truth.xlsx      # GT标注文件
    └── Sheet: 场景_人物
        ├── 列1: 原始文件名
        ├── 列2: 喜好度评分
        └── 列3-5: LAB值 (L*, a*, b*)
```

## 安装与配置

### 环境要求
- Python >= 3.8
- CUDA >= 11.0 (用于GPU训练)
- PyTorch >= 2.0.0

### 安装步骤

1. 克隆项目
```bash
cd facial_preference
```

2. 安装依赖
```bash
pip install -r requirements.txt
```

3. 配置数据路径
编辑 `config.py` 文件，设置正确的数据路径：
```python
# 数据路径配置
FACE_RGB_ROOT = Path("F:/Dataset/face_preference/face_rgb")
FACE_UV_ROOT = Path("F:/Dataset/face_preference/face_uv")
GT_EXCEL_PATH = Path("F:/Dataset/face_preference/ground_truth.xlsx")
```

## 使用方法

### 训练模型

```bash
python train.py
```

训练过程会自动：
- 进行3-fold数据集划分（7:1.5:1.5）
- 使用三阶段训练策略
- 保存最佳模型和训练日志
- 生成TensorBoard可视化

### 模型推理

1. **单张图像预测**
```bash
python inference.py \
    --checkpoint output/checkpoints/best_model.pth \
    --mode single \
    --face_rgb path/to/face.jpg \
    --face_uv path/to/face_uv.npy \
    --output prediction.json
```

2. **批量预测**
```python
from inference import FacialPreferencePredictor

predictor = FacialPreferencePredictor('path/to/checkpoint.pth')
results = predictor.predict_batch(face_rgb_paths, face_uv_paths)
```

3. **测试集评估**
```bash
python inference.py \
    --checkpoint output/checkpoints/best_model.pth \
    --mode test \
    --output test_results.json
```

## 配置说明

主要配置项在 `config.py` 中：

### 训练配置
- `TRAIN_RATIO`: 训练集比例 (0.7)
- `VAL_RATIO`: 验证集比例 (0.15)
- `TEST_RATIO`: 测试集比例 (0.15)
- `RANDOM_SEED`: 随机种子，控制数据划分的一致性
- `batch_size`: 批次大小 (32)
- `num_epochs`: 训练轮数 (100)
- `learning_rate`: 初始学习率 (1e-4)

### 模型配置
- `face_stream`: 人脸流配置
  - `rgb_backbone`: RGB分支骨干网络 (resnet50)
  - `uv_conv_layers`: UV分支卷积层配置
- `global_stream`: 全局流配置
  - `backbone`: 轻量级骨干网络 (mobilenet_v3_small)
- `fusion`: 融合层配置
  - `attention_heads`: 注意力头数 (8)
  - `fusion_dim`: 融合维度 (256)

### 损失函数配置
- `alpha`: 喜好度评分损失权重 (1.0)
- `beta`: 喜好中心损失权重 (0.5)
- `gamma`: 一致性损失权重 (0.1)
- `dynamic_weighting`: 是否使用动态权重调整

## 评估指标

### 喜好度评分指标
- MAE (平均绝对误差)
- RMSE (均方根误差)
- Pearson相关系数
- Spearman等级相关
- R²决定系数

### 喜好中心预测指标
- ΔE*ab (CIE色差公式)
- 欧氏距离
- 角度误差

## 项目结构

```
facial_preference/
├── config.py              # 配置文件
├── train.py              # 训练脚本
├── inference.py          # 推理脚本
├── requirements.txt      # 依赖包
├── README.md            # 项目文档
│
├── data/                # 数据处理模块
│   ├── __init__.py
│   └── dataset.py       # 数据集类
│
├── models/              # 模型模块
│   ├── __init__.py
│   ├── network.py       # 主网络
│   ├── face_stream.py   # 人脸流
│   ├── global_stream.py # 全局流
│   ├── fusion.py        # 融合层
│   └── losses.py        # 损失函数
│
└── utils/               # 工具函数
    ├── __init__.py
    └── metrics.py       # 评估指标
```

## 训练策略

### 三阶段训练
1. **阶段1** (前10个epoch)：冻结预训练骨干网络，仅训练新增层
2. **阶段2** (10-40 epoch)：解冻骨干网络最后2层，联合微调
3. **阶段3** (40-100 epoch)：全模型微调，降低学习率

### 数据增强
- 随机水平翻转
- 随机旋转 (±10度)
- 亮度/对比度调整
- MixUp和CutMix（可选）

## 注意事项

1. **数据格式**
   - 人脸RGB图像：JPG格式，命名为 `原名_face.jpg`
   - UV数据：NPY格式，命名为 `原名_face_uv.npy`
   - GT标注：Excel文件，每个Sheet代表一个场景-人物组合

2. **硬件要求**
   - 建议使用GPU训练（至少8GB显存）
   - 支持混合精度训练以节省显存

3. **数据集划分**
   - 使用固定的随机种子确保可重复性
   - 按场景-人物组合进行划分，避免数据泄露

## 性能目标

- 喜好度评分 MAE < 0.05
- Pearson相关系数 > 0.85
- 平均色差 ΔE*ab < 5.0
- 90%样本 ΔE*ab < 10.0

## 联系方式

如有问题或建议，请联系项目维护者。

## 许可证

本项目仅供研究使用。