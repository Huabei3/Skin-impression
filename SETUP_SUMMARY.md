# DeepSkin 项目准备完成总结

## ✅ 已完成的工作

### 1. 项目对比分析
已创建详细的对比报告，包含以下文档：

- **`PROJECT_COMPARISON.md`** - 完整的项目对比报告
  - 9个维度的详细对比
  - 代码位置精确定位
  - 使用建议和性能分析

- **`INFERENCE_GUIDE.md`** - 推理指南
  - 环境配置步骤
  - 数据格式说明
  - 运行推理的详细指令

### 2. 数据和模型准备

#### ✅ 预训练模型
```
位置: ./pretrained_models/Universal_preference_V3_best.pth
大小: 310 MB
来源: Z:\homes\Max\deepskin\facial_preference\output\Universal_preference_V3
```

#### ✅ 数据集（使用Z盘，只读）
```
位置: Z:\homes\Max\deepskin\OPPOskinExpe
大小: ~689 MB (压缩包)
包含:
  - rendered_face/      (人脸RGB图像)
  - rendered_face_uv/   (人脸UV色度数据)
  - rendered/           (全局场景图像)
  - oppo_preference_gt.xlsx (GT标注)
```

**场景类别**:
- inLab (实验室)
- inLab2v (实验室2版本)
- indoor (室内)
- outdoor (室外)
- night (夜晚)
- sunset (日落)

### 3. 创建的脚本

#### `inference_config.py` - 推理配置
- 指向Z盘数据（只读，不修改原始数据）
- 配置验证功能
- 打印配置信息

#### `run_inference.py` - 推理脚本
- 加载预训练模型
- 加载OPPO数据集
- 测试推理（前5个样本）
- 完整测试集评估
- 计算评估指标（PC, SRCC, MAE, RMSE）

#### `test_inference.py` - 模型结构测试
- 使用随机数据测试模型
- 无需真实数据集
- 验证模型加载和推理流程

---

## 📊 核心发现总结

### MS_CAN vs DeepSkin 关键差异

| 维度 | MS_CAN | DeepSkin |
|------|--------|----------|
| **输入模态** | 单模态（RGB） | 三模态（RGB + UV + 全局） |
| **模型架���** | 单流 + 多尺度注意力 | 三流融合 + 跨模态注意力 |
| **参数量** | ~25M | ~80M |
| **输出任务** | 单任务（评分） | 双任务（评分 + LAB中心） |
| **数据划分** | 样本级随机 (0.8:0.2) | 场景级严格 (0.7:0.15:0.15) |
| **损失函数** | 简单MSE | 复合多任务损失 |
| **训练策略** | 单阶段 | 三阶段渐进式 |

### 数据加载方式差异

**MS_CAN** ([dataset.py:10-125](MS_CAN/data/dataset.py#L10-L125)):
- 从 `.mat` 文件加载
- 数据结构: `drawable/` + `non_model/01Preference/labNscore/`
- 仅需 RGB 图像

**DeepSkin** ([dataset.py:23-180](deepskin/facial_preference/data/dataset.py#L23-L180)):
- 从 Excel 文件加载
- 数据结构: `rendered_face/` + `rendered_face_uv/` + `rendered/` + GT Excel
- 需要三种��据：RGB + UV + 全局场景

### 训练集划分差异

**MS_CAN**: 样本级随机划分
- 可能导致数据泄露（同一人物的图像分散在训练/测试集）

**DeepSkin**: 场景-人物组合级划分 ([dataset.py:254-299](deepskin/facial_preference/data/dataset.py#L254-L299))
- 更严格，避免数据泄露
- 支持哈希稳定划分，保证跨实验一致性

---

## 🚀 如何运行推理

### 前提条件

1. **安装PyTorch环境**
```bash
# 创建conda环境
conda create -n deepskin python=3.9
conda activate deepskin

# 安装PyTorch (CUDA 11.8)
pip install torch torchvision --index-url https://download.pytorch.org/whl/cu118

# 或CPU版本
# pip install torch torchvision

# 安装其他依赖
cd /d/work/secondYearMaster/thesis/reference/appeal/algorithms/preference_evaluate/deepskin
pip install -r facial_preference/requirements.txt
```

### 方法1: 快速测试（推荐，无需真实数据）

```bash
# 使用随机数据测试模型结构
python test_inference.py
```

**输出**:
- ✓ 模型加载成功
- ✓ 模型结构验证
- ✓ 推理流程测试
- ✓ 参数量统计

### 方法2: 使用OPPO数据集推理

```bash
# 运行完整推理脚本
python run_inference.py
```

**功能**:
1. 加载配置和验证数据路径
2. 加载预训练模型 (Universal_preference_V3)
3. 加载OPPO测试集
4. 测试推理（前5个样本）
5. 完整测试集评估
6. 计算评估指标并保存结果

**输出示例**:
```
Sample  True Score  Pred Score  True a*   Pred a*   True b*   Pred b*
------  ----------  ----------  --------  --------  --------  --------
1       0.7234      0.7156      12.45     12.38     18.32     18.45
2       0.6543      0.6621      10.23     10.45     16.78     16.92
...

Evaluation Metrics:
  Preference Score:
    - Pearson Correlation (PC): 0.8234
    - Spearman Correlation (SRCC): 0.8156
    - Mean Absolute Error (MAE): 0.0543
    - Root Mean Square Error (RMSE): 0.0721
  LAB Color Center:
    - a* MAE: 2.34
    - b* MAE: 3.12
```

---

## 📁 项目文件结构

```
deepskin/
├── facial_preference/          # 原始项目代码
│   ├── models/                 # 模型定义
│   ├── data/                   # 数据加载
│   ├── config.py               # 配置文件
│   ├── train.py                # 训练脚本
│   ├── inference.py            # 原始推理脚本
│   └── requirements.txt        # 依赖列表
│
├── pretrained_models/          # 预训练模型 (新建)
│   └── Universal_preference_V3_best.pth  (310MB)
│
├── inference_results/          # 推理结果输出 (自动创建)
│   └── test_results.txt
│
├── inference_config.py         # 推理配置 (新建)
├── run_inference.py            # 推理脚本 (新建)
├── test_inference.py           # 模型测试脚本 (新建)
│
├── PROJECT_COMPARISON.md       # 项目对比报告 (新建)
├── INFERENCE_GUIDE.md          # 推理指南 (新建)
└── SETUP_SUMMARY.md            # 本文档 (新建)
```

---

## 🔍 关键代码位置

### DeepSkin 项目

**数据加载**:
- Excel加载: [dataset.py:104-134](deepskin/facial_preference/data/dataset.py#L104-L134)
- UV数据加载: [dataset.py:145-165](deepskin/facial_preference/data/dataset.py#L145-L165)
- 场景级划分: [dataset.py:254-299](deepskin/facial_preference/data/dataset.py#L254-L299)

**模型架构**:
- 主网络: [network.py:80-122](deepskin/facial_preference/models/network.py#L80-L122)
- 人脸流: [face_stream.py](deepskin/facial_preference/models/face_stream.py)
- 全局流: [global_stream.py](deepskin/facial_preference/models/global_stream.py)
- 融合模块: [fusion.py](deepskin/facial_preference/models/fusion.py)

**损失函数**:
- 复合损失: [loss.py:220-350](deepskin/facial_preference/loss.py#L220-L350)
- Huber Loss: [loss.py:12-49](deepskin/facial_preference/loss.py#L12-L49)
- Ranking Loss: [loss.py:52-104](deepskin/facial_preference/loss.py#L52-L104)
- Perceptual Color Loss: [loss.py:107-164](deepskin/facial_preference/loss.py#L107-L164)

**训练配置**:
- 三阶段训练: [config.py:140-143](deepskin/facial_preference/config.py#L140-L143)
- 训练参数: [config.py:120-157](deepskin/facial_preference/config.py#L120-L157)

### MS_CAN 项目

**数据加载**:
- Mat文件加载: [dataset.py:76-122](MS_CAN/data/dataset.py#L76-L122)
- 样本级划分: [dataset.py:29-37](MS_CAN/data/dataset.py#L29-L37)

**模型架构**:
- 主网络: [mscan.py:79-171](MS_CAN/models/mscan.py#L79-L171)
- 多尺度特征: [mscan.py:7-31](MS_CAN/models/mscan.py#L7-L31)
- 交叉注意力: [mscan.py:34-76](MS_CAN/models/mscan.py#L34-L76)

**训练脚本**:
- 训练循环: [train.py:83-173](MS_CAN/train.py#L83-L173)

---

## ⚠️ 注意事项

### 数据访问
- ✅ Z盘数据为**只读**，不会修改原始数据
- ✅ 所有输出保存到当前项目的 `inference_results/` 目录
- ✅ 预训练模型已复制到 `pretrained_models/` 目录

### 环境要求
- Python 3.9+
- PyTorch 2.0+
- CUDA 11.8+ (推荐，CPU也可运行但较慢)
- 8GB+ GPU内存（推荐）

### 常见问题

**Q: 如果没有GPU怎么办？**
A: 修改 `inference_config.py` 中的 `DEVICE = 'cpu'`，但推理速度会较慢。

**Q: 如果UV数据缺失怎么办？**
A: 可以修改配置禁用UV分支，或使用 `test_inference.py` 测试模型结构。

**Q: 如何使用��他预训练模型？**
A: 修改 `inference_config.py` 中的 `CHECKPOINT_PATH` 指向其他模型文件。

---

## 📈 下一步建议

### 1. 验证模型
```bash
# 快速测试模型结构
python test_inference.py
```

### 2. 运行推理
```bash
# 在OPPO数据集上推理
python run_inference.py
```

### 3. 对比实验
- 在相同数据上对比 MS_CAN 和 DeepSkin 的性能
- 分析不同场景下的表现差异
- 评估模型的泛化能力

### 4. 消融实验
使用不同的预训练模型进行对比：
- `Universal_preference_V2` - V2版本
- `Universal_preference_V3` - V3版本（当前使用）
- `Universal_P_abl_no_face_uv` - 无UV分支
- `Universal_P_abl_no_global` - 无全局流
- `Universal_P_abl_no_stat` - 无统计流

---

## 📚 参考文档

- **项目对比**: `PROJECT_COMPARISON.md`
- **推理指南**: `INFERENCE_GUIDE.md`
- **配置文件**: `inference_config.py`
- **推理脚本**: `run_inference.py`
- **测试脚本**: `test_inference.py`

---

## ✅ 总结

已成功完成：
1. ✅ 详细对比 MS_CAN 和 DeepSkin 两个项目
2. ✅ 定位关键代码差异（数据加载、模型架构、训练策略）
3. ✅ 准备预训练模型（310MB）
4. ✅ 配置数据访问（Z盘只读）
5. ✅ 创建推理脚本和配置文件
6. ✅ 生成完整文档

**可以直接运行推理测试！**

```bash
# 方法1: 快速测试（无需数据）
python test_inference.py

# 方法2: 完整推理（使用OPPO数据）
python run_inference.py
```
