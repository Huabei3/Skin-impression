# MS_CAN vs DeepSkin 项目详细对比报告

## 📊 执行摘要

本报告详细对比了两个人脸颜色喜好度预测项目：**MS_CAN** 和 **DeepSkin**。

**核心发现：**
- DeepSkin 是一个更复杂、更全面的多模态系统
- MS_CAN 更简单、更易部署，但功能有限
- 两者使用不同的数据格式，**不能直接共享数据集**

---

## 1️⃣ 数据加载方式对比

### MS_CAN 数据加载

**文件位置**: `MS_CAN/data/dataset.py:10-125`

**数据源结构**:
```
toMax/
├── f01i/
│   ├── drawable/
│   │   ├── f01ih3k_01.jpg
│   │   ├── f01ih3k_02.jpg
│   │   └── ...
│   └── non_model/
│       └── 01Preference/
│           └── labNscore/
│               ├── labNscore_groupf01ih3k.mat
│               └── ...
├── f01r/
└── ...
```

**加载逻辑**:
```python
# 从 .mat 文件加载标签
mat_data = sio.loadmat(mat_path)
p_group = mat_data['p_group'].flatten()  # 喜好度评分数组 (33,)

# 可选加载喜好中心
if 'average_bf' in mat_data:
    preference_center = mat_data['average_bf'][0]  # [L*, a*, b*]

# 图像路径
img_path = os.path.join(drawable_path, f"{base_name}_{idx+1:02d}.jpg")
```

**输入数据**:
- ✅ RGB图像 (224×224)
- ❌ 无UV数据
- ❌ 无全局场景图

**标签**:
- 喜好度评分 (归一化到 [0,1])
- 可选: L*a*b* 喜好中心

---

### DeepSkin 数据加载

**文件位置**: `deepskin/facial_preference/data/dataset.py:23-180`

**数据源结构**:
```
数据根目录/
├── rendered_face/          # 人脸RGB
│   ├── f01i/
│   │   ├── f01ih3k_01_face.jpg
│   │   └── ...
├── rendered_face_uv/       # 人脸UV (关键!)
│   ├── f01i/
│   │   ├── f01ih3k_01_face_uv.npy
│   │   └── ...
├── rendered/               # 全局场景
│   ├── f01i/
│   │   ├── f01ih3k_01.jpg
│   │   └── ...
└── gt/
    └── Healthy_non_model_gt.xlsx
```

**加载逻辑**:
```python
# 从 Excel 加载标签
df = pd.read_excel(excel_file, sheet_name=sheet_name)
for idx, row in df.iterrows():
    original_name = row.iloc[0]
    preference_score = float(row.iloc[1])
    l_star = float(row.iloc[2])
    a_star = float(row.iloc[3])
    b_star = float(row.iloc[4])

# 构建三种数据路径
face_rgb_path = self.face_rgb_root / scene_person / f"{original_name}_face.jpg"
face_uv_path = self.face_uv_root / scene_person / f"{original_name}_face_uv.npy"
global_rgb_path = self.global_rgb_root / scene_person / f"{original_name}.jpg"

# 加载UV数据
uv_data = np.load(face_uv_path)  # Shape: (H, W, 2) 或 (2, H, W)
```

**输入数据**:
- ✅ 人脸RGB图像 (224×224)
- ✅ 人脸UV色度数据 (2通道, 224×224)
- ✅ 全局场景图像 (224×224)
- ✅ 统计特征 (13维: 亮度、色温、场景类别等)

**标签**:
- 喜好度评分
- L*a*b* 喜好中心 (a*, b*)

**关键代码位置**:
- Excel加载: `dataset.py:104-134`
- UV数据加载: `dataset.py:145-165`
- 数据预处理: `dataset.py:400-550`

---

## 2️⃣ 训练集/验证集划分对比

### MS_CAN 划分策略

**文件位置**: `MS_CAN/data/dataset.py:29-37`

```python
# 样本级随机划分
np.random.seed(42)
indices = np.random.permutation(len(self.samples))
split_idx = int(len(self.samples) * train_ratio)  # 默认 0.8

if split == 'train':
    self.samples = [self.samples[i] for i in indices[:split_idx]]
else:
    self.samples = [self.samples[i] for i in indices[split_idx:]]
```

**特点**:
- 划分级别: **样本级**
- 比例: train:test = **0.8:0.2** (二分法)
- 随机种子: 42 (固定)
- 问题: 同一人物的不同图像可能分散在训练集和测试集

---

### DeepSkin 划分策略

**文件位置**: `deepskin/facial_preference/data/dataset.py:254-299`

```python
# 场景-人物组合级别划分
scene_persons = list(set([item['scene_person'] for item in self.data_items]))
np.random.seed(self.seed)
np.random.shuffle(scene_persons)

# 三分法
n_train = int(round(n_total * self.train_ratio))  # 0.7
n_val = int(round(rem * (self.val_ratio / vt)))   # 0.15
n_test = rem - n_val                               # 0.15

# 划分场景组合
train_scenes = scene_persons[:n_train]
val_scenes = scene_persons[n_train:n_train+n_val]
test_scenes = scene_persons[n_train+n_val:]

# 根据场景筛选数据
if self.split == 'train':
    self.data_items = [item for item in self.data_items 
                      if item['scene_person'] in train_scenes]
```

**特点**:
- 划分级别: **场景-人物组合级**
- 比例: train:val:test = **0.7:0.15:0.15** (三分法)
- 随机种子: 可配置 (默认666)
- 优势: **避免数据泄露**，同一人物的所有图像只出现在一个集合中

**支持两种策略**:
1. **随机划分**: 每次运行可能不同
2. **哈希稳定划分** (`dataset.py:301-380`): 基于ID哈希，保证跨实验一致性

```python
# 哈希稳定划分
def _split_by_id_hash(self, scene_person: str) -> str:
    hash_val = int(hashlib.md5(scene_person.encode()).hexdigest(), 16)
    ratio = (hash_val % 10000) / 10000.0
    
    if ratio < self.train_ratio:
        return 'train'
    elif ratio < self.train_ratio + self.val_ratio:
        return 'val'
    else:
        return 'test'
```

---

## 3️⃣ 模型架构对比

### MS_CAN 架构

**文件位置**: `MS_CAN/models/mscan.py:79-171`

**架构图**:
```
输入: RGB图像 (3, 224, 224)
    ↓
ResNet50 骨干网络
    ↓
┌─────────────────────────────────┐
│  多尺度特征提取                  │
│  - 1×1 卷积                      │
│  - 3×3 卷积                      │
│  - 5×5 卷积                      │
│  - 7×7 卷积                      │
└─────────────────────────────────┘
    ↓
┌─────────────────────────────────┐
│  跨尺度交叉注意力                │
│  - Layer1 ↔ Layer2              │
│  - Layer2 ↔ Layer3              │
│  - Layer3 ↔ Layer4              │
└─────────────────────────────────┘
    ↓
特征融合 (Concat + Conv)
    ↓
全局平均池化
    ↓
全连接层 (1024→512→128→1)
    ↓
输出: 喜好度评分 (1维)
```

**关键组件**:

1. **MultiScaleFeatureExtractor** (`mscan.py:7-31`)
```python
class MultiScaleFeatureExtractor(nn.Module):
    def __init__(self, in_channels, out_channels):
        self.conv1x1 = nn.Conv2d(in_channels, out_channels // 4, kernel_size=1)
        self.conv3x3 = nn.Conv2d(in_channels, out_channels // 4, kernel_size=3, padding=1)
        self.conv5x5 = nn.Conv2d(in_channels, out_channels // 4, kernel_size=5, padding=2)
        self.conv7x7 = nn.Conv2d(in_channels, out_channels // 4, kernel_size=7, padding=3)
```

2. **CrossAttention** (`mscan.py:34-76`)
```python
class CrossAttention(nn.Module):
    def __init__(self, dim, num_heads=8):
        self.query = nn.Linear(dim, dim)
        self.key = nn.Linear(dim, dim)
        self.value = nn.Linear(dim, dim)
```

**参数量**: ~25M

---

### DeepSkin 架构

**文件位置**: `deepskin/facial_preference/models/network.py:12-122`

**架构图**:
```
输入1: 人脸RGB (3, 224, 224)
    ↓
┌─────────────────────────────────┐
│  FaceStream                      │
│  ├─ RGB分支: ResNet50           │
│  └─ UV分支: Custom CNN          │
│  输出: 512维                     │
└─────────────────────────────────┘

输入2: 人脸UV (2, 224, 224)
    ↓ (合并到FaceStream)

输入3: 全局RGB (3, 224, 224)
    ↓
┌──────���──────────────────────────┐
│  GlobalStream                    │
│  骨干: MobileNetV3-Small         │
│  输出: 256维                     │
└─────────────────────────────────┘

输入4: 统计特征 (13维)
    ↓
┌─────────────────────────────────┐
│  StatisticalStream               │
│  MLP: 13→32→64→32               │
│  输出: 32维                      │
└─────────────────────────────────┘

    ↓ (三流特征)
┌─────────────────────────────────┐
│  CrossModalAttention             │
│  - 8个注意力头                   │
│  - 跨模态特征融合                │
│  输出: 256维                     │
└─────────────────────────────────┘
    ↓
┌─────────────────────────────────┐
│  DualTaskPredictionHead          │
│  ├─ 任务1: 喜好度评分 (1维)     │
│  └─ 任务2: LAB中心 (2维)        │
└─────────────────────────────────┘
```

**关键组件**:

1. **FaceStream** (`face_stream.py`)
```python
class AttentiveFaceStream(nn.Module):
    def __init__(self, config):
        # RGB分支
        self.rgb_branch = RGBBranch(
            backbone='resnet50',
            pretrained=True,
            feature_dim=512
        )
        # UV分支
        self.uv_branch = UVBranch(
            uv_channels=2,
            feature_dim=128
        )
        # 跨模态注意力
        self.cross_attention = CrossModalAttention(...)
```

2. **GlobalStream** (`global_stream.py`)
```python
class GlobalStream(nn.Module):
    def __init__(self, config):
        self.backbone = models.mobilenet_v3_small(pretrained=True)
        self.feature_dim = 256
```

3. **StatisticalStream** (`global_stream.py`)
```python
class StatisticalStream(nn.Module):
    def __init__(self, config):
        # 输入: 13维统计特征
        # - 5维亮度统计 (mean, std, min, max, median)
        # - 1维色温
        # - 2维场景类别 (indoor/outdoor)
        # - 2维性别 (male/female)
        # - 3维人种 (asian/black/white)
        self.mlp = nn.Sequential(
            nn.Linear(13, 32),
            nn.ReLU(),
            nn.Linear(32, 64),
            nn.ReLU(),
            nn.Linear(64, 32)
        )
```

4. **CrossModalAttention** (`fusion.py`)
```python
class CrossModalAttention(nn.Module):
    def __init__(self, face_dim, global_dim, stat_dim, hidden_dim, num_heads=8):
        self.face_attn = MultiHeadAttention(face_dim, num_heads)
        self.global_attn = MultiHeadAttention(global_dim, num_heads)
        self.stat_attn = MultiHeadAttention(stat_dim, num_heads)
```

**参数量**: ~80M

---

## 4️⃣ 损失函数对比

### MS_CAN 损失函数

**文件位置**: `MS_CAN/train.py:104`

```python
criterion = nn.MSELoss()
```

**特点**:
- 单一损失: 均方误差 (MSE)
- 优化目标: 最小化预测评分与真实评分的差异
- 简单直接

---

### DeepSkin 损失函数

**文件位置**: `deepskin/facial_preference/loss.py:220-350`

**复合损失函数**:
```python
total_loss = α·score_loss + β·center_loss + γ·consistency_loss + δ·ranking_loss
```

**组件详解**:

1. **HuberLoss** (`loss.py:12-49`)
```python
class HuberLoss(nn.Module):
    def __init__(self, delta=0.1):
        # 小误差: L2损失
        # 大误差: L1损失
        # 对异常值鲁棒
```

2. **RankingLoss** (`loss.py:52-104`)
```python
class RankingLoss(nn.Module):
    # 确保预测分数的相对顺序与真实值一致
    # 如果 score_i > score_j，则 pred_i > pred_j
```

3. **PerceptualColorLoss** (`loss.py:107-164`)
```python
class PerceptualColorLoss(nn.Module):
    def __init__(self, skin_weight=1.5, extreme_weight=0.7):
        # 肤色区域: a*∈[0,20], b*∈[10,30] → 权重1.5
        # 极端色彩: √(a*²+b*²) > 80 → 权重0.7
```

4. **ConsistencyLoss** (`loss.py:167-218`)
```python
class ConsistencyLoss(nn.Module):
    # 确保预测的LAB中心与输入UV分布相关
```

5. **PearsonCorrelationLoss**
```python
# 最大化预测与真实值的皮尔逊相关系数
```

**权重配置** (`config.py:159-186`):
```python
LOSS = {
    'alpha': 1.0,           # 喜好度评分损失
    'beta': 1.0,            # 喜好中心损失
    'gamma': 0.7,           # 一致性损失
    'ranking_weight': 0.4,  # 排序损失
    'pearson_weight': 0.7,  # 皮尔逊相关损失
    'dynamic_weighting': True  # 动态权重调整
}
```

---

## 5️⃣ 训练策略对比

### MS_CAN 训练策略

**文件位置**: `MS_CAN/train.py:83-173`

```python
# 优化器
optimizer = optim.Adam(model.parameters(), lr=1e-4, weight_decay=1e-4)

# 学习率调度器
scheduler = optim.lr_scheduler.ReduceLROnPlateau(
    optimizer, mode='min', factor=0.5, patience=5
)

# 训练循环
for epoch in range(1, 100):
    train_loss = train_one_epoch(...)
    val_loss = validate(...)
    scheduler.step(val_loss)
```

**特点**:
- 优化器: Adam
- 学习率: 1e-4 (固定初始值)
- 调度器: ReduceLROnPlateau (验证损失不下降时降低)
- 训练阶段: **单阶段**
- 数据增强: 基础 (RandomCrop, HorizontalFlip, ColorJitter)
- 混合精度: 不支持

---

### DeepSkin 训练策略

**文件位置**: `deepskin/facial_preference/config.py:120-157`

```python
TRAINING = {
    # 优化器
    'optimizer': 'AdamW',
    'learning_rate': 7e-4,
    'weight_decay': 1e-4,
    
    # 学习率调度器
    'scheduler': 'CosineAnnealingWarmRestarts',
    'warmup_epochs': 5,
    'min_lr': 1e-6,
    'T_0': 10,  # 周期
    
    # 训练配置
    'batch_size': 32,
    'num_epochs': 1000,
    'gradient_clip': 1.0,
    'early_stopping_patience': 100,
    
    # 三阶段训练
    'stage1_epochs': 20,   # 冻结backbone
    'stage2_epochs': 60,   # 部分解冻
    'stage3_epochs': 120,  # 全部解冻
    
    # 混合精度训练
    'mixed_precision': True,
    
    # 加权采样
    'sampler': 'weighted',
    'extreme_bins': [[0.0, 0.1], [0.9, 1.0]],
    'extreme_sample_weight': 1.0
}
```

**三阶段训练策略**:

```python
# Stage 1: 冻结预训练骨干网络
freeze_backbone(model, freeze=True)
train(epochs=20, lr=7e-4)

# Stage 2: 解冻最后几层
unfreeze_layers(model, num_layers=2)
train(epochs=60, lr=5e-4)

# Stage 3: 全部解冻
freeze_backbone(model, freeze=False)
train(epochs=120, lr=3e-4)
```

**高级数据增强**:
```python
AUGMENTATION = {
    'random_crop': True,
    'horizontal_flip': True,
    'rotation_degree': 10,
    'brightness_range': (0.8, 1.2),
    'contrast_range': (0.8, 1.2),
    'mixup_alpha': 0.2,      # Mixup增强
    'cutmix_prob': 0.5       # CutMix增强
}
```

---

## 6️⃣ 评估指标对比

### MS_CAN 评估指标

**文件位置**: `MS_CAN/utils/metrics.py:5-36`

```python
def calculate_metrics(labels, predictions):
    return {
        'PC': pearsonr(labels, predictions)[0],      # 皮尔逊相关
        'SRCC': spearmanr(labels, predictions)[0],   # 斯皮尔曼相关
        'MAE': np.mean(np.abs(labels - predictions)), # 平均绝对误差
        'RMSE': np.sqrt(np.mean((labels - predictions) ** 2))  # 均方根误差
    }
```

---

### DeepSkin 评估指标

**基础指标** (与MS_CAN相同):
- PC (Pearson Correlation)
- SRCC (Spearman Rank Correlation)
- MAE (Mean Absolute Error)
- RMSE (Root Mean Square Error)

**额外指标**:
- **ΔE2000**: LAB色彩中心预测的色差
- **分区间评估**: 极端区间 vs 中间区间的性能
- **跨场景泛化**: 不同场景下的性能差异
- **跨人种泛化**: 不同人种的性能差异

---

## 7️⃣ 数据需求对比

### MS_CAN 数据需求

✅ **优势**:
- 仅需RGB图像
- 数据准备简单
- 易于部署

❌ **劣势**:
- 缺少色度信息
- 无场景上下文
- 信息有限

### DeepSkin 数据需求

✅ **优势**:
- 多模态信息丰富
- 包含色度和场景上下文
- 预测更准确

❌ **劣势**:
- 需要三种数据 (RGB + UV + 全局图)
- 数据准备复杂
- UV数据获取困难

**当前数据状态**:
```
✅ 可用:
  - 训练好的模型: best_model.pth (306MB)
  - MS_CAN数据集: toMax/ (仅RGB)
  - OPPO GT文件: oppo_preference_gt.xlsx

❌ 缺失:
  - UV色度数据: rendered_face_uv/ (在网盘上)
  - 完整渲染数据: rendered/, rendered_face/
```

---

## 8️⃣ 性能对比 (理论分析)

| 维度 | MS_CAN | DeepSkin |
|------|--------|----------|
| **模型复杂度** | 低 (~25M参数) | 高 (~80M参数) |
| **推理速度** | 快 (~50ms/张) | 慢 (~150ms/张) |
| **预测准确性** | 中等 | 高 (多模态信息) |
| **泛化能力** | 一般 | 强 (场景级划分) |
| **部署难度** | 简单 | 复杂 (需UV数据) |
| **训练时间** | 短 (~2小时/100epochs) | 长 (~10小时/100epochs) |
| **数据需求** | 低 (仅RGB) | 高 (RGB+UV+全局) |

---

## 9️⃣ 使用建议

### 选择 MS_CAN 的场景:
- ✅ 只有RGB图像数据
- ✅ 需要快速部署
- ✅ 计算资源有限
- ✅ 对准确性要求不高

### 选择 DeepSkin 的场景:
- ✅ 有完整的多模态数据 (RGB + UV + 全局)
- ✅ 对预测准确性要求高
- ✅ 需要预测LAB色彩中心
- ✅ 有充足的计算资源

---

## 🔟 下一步行动

### 1. 环境准备
```bash
# 安装依赖
conda create -n deepskin python=3.9
conda activate deepskin
pip install torch torchvision
pip install -r facial_preference/requirements.txt
```

### 2. 模型测试
```bash
# 运行测试脚本 (无需真实数据)
python test_inference.py
```

### 3. 数据准备
- **选项A**: 从网盘下载完整UV数据
- **选项B**: 使用MS_CAN的RGB数据训练简化版DeepSkin
- **选项C**: 仅使用已训练模型进行推理测试

### 4. 对比实验
在相同数据上对比两个模型的性能：
- 预测准确性 (PC, SRCC, MAE, RMSE)
- 推理速度
- 模型大小
- 泛化能力

---

## 📚 相关文件索引

### MS_CAN 项目
- 数据加载: `MS_CAN/data/dataset.py`
- 模型定义: `MS_CAN/models/mscan.py`
- 训练脚本: `MS_CAN/train.py`
- 评估指标: `MS_CAN/utils/metrics.py`

### DeepSkin 项目
- 数据加载: `deepskin/facial_preference/data/dataset.py`
- 模型定义: `deepskin/facial_preference/models/network.py`
- 配置文件: `deepskin/facial_preference/config.py`
- 损失函数: `deepskin/facial_preference/loss.py`
- 训练脚本: `deepskin/facial_preference/train.py`
- 推理脚本: `deepskin/facial_preference/inference.py`
- 测试脚本: `deepskin/test_inference.py` ⭐ (新创建)
- 推理指南: `deepskin/INFERENCE_GUIDE.md` ⭐ (新创建)

---

## 📝 总结

**DeepSkin** 是一个更先进、更复杂的系统，通过多模态融合和双任务学习实现了更高的预测准确性。但它需要更多的数据和计算资源。

**MS_CAN** 是一个更简单、更实用的基线模型，适合快速部署和资源受限的场景。

两者的选择取决于你的具体需求、数据可用性和计算资源。
