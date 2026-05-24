# DeepSkin 项目推理指南

## 📋 项目概述

DeepSkin 是一个**三流融合的多模态人脸颜色喜好度预测模型**，与 MS_CAN 相比具有以下特点：

### 核心差异对比

| 特性 | MS_CAN | DeepSkin |
|------|--------|----------|
| **输入模态** | 单模态（RGB图像） | 三模态（人脸RGB + UV色度 + 全局场景） |
| **模型架构** | 单流 + 多尺度交叉注意力 | 三流融合 + 跨模态注意力 |
| **输出任务** | 单任务（喜好度评分） | 双任务（评分 + LAB色彩中心） |
| **参数量** | ~25M | ~80M |
| **数据需求** | 仅RGB图像 | RGB + UV + 全局图 |

---

## 🗂️ 数据格式要求

### DeepSkin 需要的数据结构：

```
数据根目录/
├── rendered_face/          # 人脸RGB图像
│   ├── f01i/
│   │   ├── f01ih3k_01_face.jpg
│   │   ├── f01ih3k_02_face.jpg
│   │   └── ...
│   └── ...
├── rendered_face_uv/       # 人脸UV色度数据 (关键！)
│   ├── f01i/
│   │   ├── f01ih3k_01_face_uv.npy
│   │   ├── f01ih3k_02_face_uv.npy
│   │   └── ...
│   └── ...
├── rendered/               # 全局场景图像
│   ├── f01i/
│   │   ├── f01ih3k_01.jpg
│   │   ├── f01ih3k_02.jpg
│   │   └── ...
│   └── ...
└── gt/
    └── Healthy_non_model_gt.xlsx  # Ground Truth标注
```

### UV数据格式：
- **文件格式**: `.npy` (NumPy数组)
- **形状**: `(H, W, 2)` 或 `(2, H, W)`
- **通道**: 2通道（U和V色度分量）
- **数值范围**: 通常在 [0, 3] 之间

### Excel GT格式：
- 每个Sheet代表一个场景-人物组合（如 `f01i`, `m02r`）
- 列：`[原始文件名, 喜好度评分, L*, a*, b*]`

---

## ⚙️ 环境配置

### 1. 创建Python环境

```bash
# 使用conda创建环境
conda create -n deepskin python=3.9
conda activate deepskin

# 或使用venv
python -m venv deepskin_env
source deepskin_env/bin/activate  # Linux/Mac
# deepskin_env\Scripts\activate  # Windows
```

### 2. 安装依赖

```bash
cd /d/work/secondYearMaster/thesis/reference/appeal/algorithms/preference_evaluate/deepskin

# 安装PyTorch (根据你的CUDA版本选择)
# CUDA 11.8
pip install torch torchvision --index-url https://download.pytorch.org/whl/cu118

# CPU版本
# pip install torch torchvision

# 安装其他依赖
pip install -r facial_preference/requirements.txt
```

---

## 🚀 运行推理

### 方法1: 使用测试脚本（推荐 - 无需真实数据）

```bash
cd /d/work/secondYearMaster/thesis/reference/appeal/algorithms/preference_evaluate/deepskin

# 运行测试脚本（使用随机数据测试模型结构）
python test_inference.py
```

**这个脚本会：**
- ✅ 加载训练好的模型检查点
- ✅ 验证模型结构完整性
- ✅ 使用随机数据测试推理流程
- ✅ 输出模型参数量和推理结果示例

### 方法2: 使用真实数据推理

如果你有完整的数据集（包含UV数据）：

```bash
cd facial_preference

# 单张图像推理
python inference.py \
    --checkpoint ../facial_preference_cloud/output/predict_p/checkpoints/best_model.pth \
    --mode single \
    --face_rgb /path/to/face_rgb.jpg \
    --face_uv /path/to/face_uv.npy \
    --output result.json

# 批量推理
python inference.py \
    --checkpoint ../facial_preference_cloud/output/predict_p/checkpoints/best_model.pth \
    --mode batch \
    --output batch_results.json

# 在测试集上评估
python inference.py \
    --checkpoint ../facial_preference_cloud/output/predict_p/checkpoints/best_model.pth \
    --mode test \
    --output test_metrics.json
```

---

## 📊 模型信息

### 已训练模型位置：
```
facial_preference_cloud/output/predict_p/checkpoints/best_model.pth
大小: 306 MB
训练轮次: 200 epochs
```

### 模型架构组件：

1. **FaceStream (人脸流)**
   - RGB分支: ResNet50 (预训练)
   - UV分支: 自定义CNN
   - 输出维度: 512

2. **GlobalStream (全局流)**
   - 骨干网络: MobileNetV3-Small
   - 输出维度: 256

3. **StatisticalStream (统计流)**
   - 输入: 13维统计特征（亮度、色温、场景类别等）
   - 输出维度: 32

4. **CrossModalAttention (跨模态融合)**
   - 注意力头数: 8
   - 融合维度: 256

5. **DualTaskPredictionHead (双任务预测头)**
   - 任务1: 喜好度评分 (1维)
   - 任务2: LAB色彩中心 (a*, b*) (2维)

---

## ⚠️ 当前数据状态

### 可用数据：
- ✅ **训练好的模型**: `best_model.pth` (306MB)
- ✅ **MS_CAN数据集**: `/d/work/.../datasets/toMax` (仅RGB图像)
- ✅ **OPPO GT文件**: `OPPOskinExpe/oppo_preference_gt.xlsx`

### 缺失数据：
- ❌ **UV色度数据**: `rendered_face_uv/` 目录（在网盘上）
- ❌ **完整渲染数据**: `rendered/` 和 `rendered_face/` 目录

### 解决方案：

#### 选项1: 下载完整数据（推荐）
从网盘下载缺失的UV数据和渲染图像，放置到正确的目录结构。

#### 选项2: 使用测试脚本
运行 `test_inference.py` 使用随机数据验证模型结构和推理流程。

#### 选项3: 简化模型（如果只有RGB数据）
修改模型配置，禁用UV分支：

```python
# 在 config.py 中设置
Config.MODEL['face_stream']['load_uv'] = False
```

---

## 🔍 推理输出示例

```json
{
    "preference_score": 0.7234,
    "preference_center_a": 12.45,
    "preference_center_b": 18.32
}
```

**解释：**
- `preference_score`: 喜好度评分 (0-1之间，越高越好)
- `preference_center_a`: LAB色彩空间的a*分量（红绿轴）
- `preference_center_b`: LAB色彩空间的b*分量（黄蓝轴）

---

## 📝 数据集划分策略

DeepSkin 使用**场景-人物级别划分**，比MS_CAN的样本级划分更严格：

```python
# MS_CAN: 样本级随机划分
train:test = 0.8:0.2

# DeepSkin: 场景-人物组合级别划分
train:val:test = 0.7:0.15:0.15
```

**优势**: 避免数据泄露，同一人物的所有图像只出现在一个集合中。

---

## 🎯 下一步操作

1. **安装环境**: 按照上述步骤安装PyTorch和依赖
2. **运行测试**: 执行 `python test_inference.py` 验证模型
3. **准备数据**: 
   - 如果需要真实推理，从网盘下载UV数据
   - 或者使用MS_CAN的RGB数据训练简化版模型
4. **对比实验**: 在相同数据上对比MS_CAN和DeepSkin的性能

---

## 📚 相关文件

- **模型定义**: `facial_preference/models/network.py`
- **数据加载**: `facial_preference/data/dataset.py`
- **配置文件**: `facial_preference/config.py`
- **训练脚本**: `facial_preference/train.py`
- **推理脚本**: `facial_preference/inference.py`
- **测试脚本**: `test_inference.py` (新创建)

---

## 💡 提示

如果你只想快速验证模型能否运行，直接执行：

```bash
python test_inference.py
```

这会使用随机数据测试整个推理流程，无需下载大量数据。
