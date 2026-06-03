# 外部 IQA 算法 Retrain 保姆级教程

> 在 deepskin 数据集上重训/评估 HyperIQA、DN-PIQA、SCUT-FBP5500、PIQ2023 及简单机器学习基线
> 云实例: instance2 (ssh -p 36828 root@connect.westd.seetacloud.com)

---

## 0. 数据集概览

| 属性 | 值 |
|------|-----|
| 总图像数 | 40 个 scene-person 文件夹 |
| 总样本数 | ~54,000 组评价 (21 受试者 × 48 图像) |
| 图像类型 | 人脸 crop (_face.jpg) + 全局图像 (.jpg) |
| 图像尺寸 | 224×224 (已 resize) |
| GT 格式 | Excel (每个 sheet = 一个人一个场景) |
| 人种划分 | CA(01-03), AS(04-06), SA(07-08), AF(09-10) |

---

## 1. 简单机器学习基线

### 方法
- **特征**: L\*a\*b\* 统计 (均值/标准差/分位数) + C\*ab + h_ab + ITA° + GT 偏好中心
- **模型**: LinearRegression, Ridge, SVR(RBF/Poly/Linear)
- **评估**: 按人种 train/val/test 划分，MAE + Pearson r

### 运行命令

```bash
cd /root/autodl-tmp/deepskin
conda activate deepskin

# 四个 race 串行
for R in SA CA AS AF; do
    echo "===== Simple ML: $R ====="
    python simple_ml/handcrafted_baseline.py \
        --face-root /root/autodl-tmp/rendered_face \
        --gt-excel /root/autodl-tmp/gt/toMax_gt_01Preference.xlsx \
        --output-dir ./simple_ml/output \
        --race $R
    echo "===== $R done ====="
done
```

### 输出
- `simple_ml/output/baseline_{RACE}.json` — 各模型在 train/val/test 上的 MAE + Pearson r

---

## 2. HyperIQA

### 数据集适配
HyperIQA 需要一个 CSV 文件（`image_name, score`）和图像文件夹。

**适配方式**: 直接使用 deepskin 的人脸 crop 图像，导出 CSV。

### Step 1: 准备数据

```bash
cd /root/autodl-tmp/deepskin
conda activate deepskin

# 为 4 个人种准备 HyperIQA 格式数据（用软链接，不复制图像）
for R in SA CA AS AF; do
    echo "===== Prepare HyperIQA: $R ====="
    python simple_ml/prepare_iqa_data.py \
        --face-root /root/autodl-tmp/rendered_face \
        --gt-excel /root/autodl-tmp/gt/toMax_gt_01Preference.xlsx \
        --output-dir /root/autodl-tmp/iqa_prepared \
        --format hyperiqa \
        --race $R
    echo "===== $R done ====="
done
```

输出结构:
```
iqa_prepared/hyperIQA/
  images/          (软链接到 rendered_face)
  train.csv        (image_name, score)
  val.csv
  test.csv
```

### Step 2: 修改 HyperIQA 代码

HyperIQA 代码在 `/root/autodl-tmp/hyperIQA/`，需要修改 `folders.py`：

在 `folders.py` 末尾添加新的 Dataset 类:

```python
class DeepskinFolder(data.Dataset):
    """Custom dataset for deepskin face images."""
    def __init__(self, root, csv_file, transform, patch_num=1):
        import pandas as pd
        df = pd.read_csv(csv_file)
        self.samples = []
        for _, row in df.iterrows():
            img_path = os.path.join(root, 'images', row['image_name'])
            score = float(row['score'])
            for _ in range(patch_num):
                self.samples.append((img_path, score))
        self.transform = transform

    def __getitem__(self, index):
        path, target = self.samples[index]
        sample = Image.open(path).convert('RGB')
        if self.transform is not None:
            sample = self.transform(sample)
        return sample, target

    def __len__(self):
        return len(self.samples)
```

### Step 3: 训练

创建训练脚本 `train_deepskin.py`:

```python
import torch
import torchvision.transforms as transforms
import folders
from IQASolver import HyperIQASolver

# 配置
config = {
    'train_csv': '/root/autodl-tmp/iqa_prepared/hyperIQA/train.csv',
    'val_csv': '/root/autodl-tmp/iqa_prepared/hyperIQA/val.csv',
    'test_csv': '/root/autodl-tmp/iqa_prepared/hyperIQA/test.csv',
    'image_root': '/root/autodl-tmp/iqa_prepared/hyperIQA',
    'batch_size': 16,
    'lr': 1e-4,
    'epochs': 100,
}

train_transform = transforms.Compose([
    transforms.RandomHorizontalFlip(),
    transforms.Resize((224, 224)),
    transforms.ToTensor(),
    transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
])
test_transform = transforms.Compose([
    transforms.Resize((224, 224)),
    transforms.ToTensor(),
    transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
])

train_loader = torch.utils.data.DataLoader(
    folders.DeepskinFolder(config['image_root'], config['train_csv'], train_transform),
    batch_size=config['batch_size'], shuffle=True, num_workers=4
)
val_loader = torch.utils.data.DataLoader(
    folders.DeepskinFolder(config['image_root'], config['val_csv'], test_transform),
    batch_size=config['batch_size'], shuffle=False, num_workers=4
)

# 创建 solver 并训练
solver = HyperIQASolver(config)
solver.train(train_loader, val_loader)
```

---

## 3. DN-PIQA

### 数据集适配
DN-PIQA 使用 NTIRE24 格式，需要按场景组织图像。

**适配方式**: 将 deepskin 图像按 scene 分组复制/链接，导出 CSV。

### Step 1: 准备数据

```bash
cd /root/autodl-tmp/deepskin
conda activate deepskin

# 为 4 个人种准备 DN-PIQA 格式数据
for R in SA CA AS AF; do
    echo "===== Prepare DN-PIQA: $R ====="
    python simple_ml/prepare_iqa_data.py \
        --face-root /root/autodl-tmp/rendered_face \
        --gt-excel /root/autodl-tmp/gt/toMax_gt_01Preference.xlsx \
        --output-dir /root/autodl-tmp/iqa_prepared \
        --format dnpiqa \
        --race $R
    echo "===== $R done ====="
done
```

输出结构:
```
iqa_prepared/dnpiqa/
  csvfiles/
    train.csv      (image_path, score)
    test.csv
  train/{scene}/   (按场景分组的图像)
  test/{scene}/
```

### Step 2: 修改 CSV 格式为 DN-PIQA 期望的格式

DN-PIQA 的 CSV 格式较复杂（多列特征），最简单的做法是修改 `IQADataset.py` 中的 `PIQA` 类来读取简化版 CSV。

在 `/root/autodl-tmp/DN-PIQA/models/IQADataset.py` 中添加:

```python
class DeepskinDataset(data.Dataset):
    def __init__(self, csv_path, transform, istrain=True):
        df = pd.read_csv(csv_path)
        self.samples = []
        for _, row in df.iterrows():
            self.samples.append((row['image_path'], row['score']))
        self.transform = transform
    # ... 类似 PIQA 类
```

### Step 3: 训练

```bash
cd /root/autodl-tmp/DN-PIQA

python models/train.py \
    --num_epochs 30 \
    --batch_size 8 \
    --resize 448 \
    --crop_size 384 \
    --lr 0.00001 \
    --decay_ratio 0.9 \
    --decay_interval 5 \
    --snapshot /root/autodl-tmp/dnpiqa_checkpoints/ \
    --database_dir /root/autodl-tmp/iqa_prepared/dnpiqa/ \
    --model DN_PIQA \
    --database PIQ \
    --test_method five \
    --loss_type fidelity
```

---

## 4. SCUT-FBP5500

### 状态
SCUT-FBP5500 数据库已在 `/root/SCUT-FBP5500-Database-Release/`。

这是一个**独立的人脸美感数据库**（5500 张图片，每张有 5 个评分者的美感评分）。

### 适配方案
**SCUT-FBP5500 无法直接用于 deepskin 数据**——它是独立数据集。

如果要做对比实验，应该在 SCUT-FBP5500 上训练，在 deepskin 上测试（跨数据集评估），或反过来。

### 在 SCUT-FBP5500 上训练

SCUT-FBP5500 的标签文件在数据库目录中，需要先解析。常见做法：

```bash
cd /root
git clone https://github.com/HCIILAB/SCUT-FBP5500-Benchmark.git
cd SCUT-FBP5500-Benchmark

# 修改数据路径指向 /root/SCUT-FBP5500-Database-Release/
# 然后运行训练脚本
```

---

## 5. PIQ2023 (SemHyperIQA)

### 状态
PIQ2023 代码在 `/root/autodl-tmp/PIQ2023/`，但只有模型架构文件，没有完整的训练入口。

### 分析
`/root/autodl-tmp/PIQ2023/src/models/archs/sem_hyperiqa_arch.py` 包含 SemHyperIQA 模型定义，这是基于 HyperIQA 改进的语义感知 IQA 模型。

### 适配方案
由于 PIQ2023 只有模型代码没有训练 pipeline，建议：
1. 提取 SemHyperIQA 模型代码
2. 集成到 HyperIQA 的训练 pipeline 中
3. 使用 HyperIQA 格式的数据（见第 2 节）

---

## 6. 快速运行清单

### 在 instance2 上依次执行:

```bash
# ===== 连接 =====
ssh -p 36828 root@connect.westd.seetacloud.com

# ===== 环境 =====
cd /root/autodl-tmp/deepskin
conda activate deepskin

# ===== 通用参数 =====
DATA=/root/autodl-tmp
GT=/root/autodl-tmp/gt/toMax_gt_01Preference.xlsx
OUT=/root/autodl-tmp/deepskin/predict_p/output
ATTR_DIR=/root/autodl-tmp/gt

# ===== Ablation-1: Face-Only (multi-head, 4人种串行) =====
for RACE in SA CA AS AF; do
    echo "===== Ablation-1 FaceOnly: $RACE ====="
    python predict_p/train.py \
        --model-variant v3 --rgb-backbone simple_cnn --global-backbone simple_cnn \
        --race $RACE --data-root $DATA --gt-excel $GT --output-root $OUT \
        --exp-name ablation_face_only --ablation-face-only \
        --multi-head --attributes all --attribute-gt-dir $ATTR_DIR
    echo "===== $RACE done ====="
done

# ===== Ablation-2: SimpleConcat (multi-head, 4人种串行) =====
for RACE in SA CA AS AF; do
    echo "===== Ablation-2 SimpleConcat: $RACE ====="
    python predict_p/train.py \
        --model-variant v3 --rgb-backbone simple_cnn --global-backbone simple_cnn \
        --race $RACE --data-root $DATA --gt-excel $GT --output-root $OUT \
        --exp-name ablation_concat --ablation-fusion-type concat \
        --multi-head --attributes all --attribute-gt-dir $ATTR_DIR
    echo "===== $RACE done ====="
done

# ===== Ablation-3: ResNet50 backbone (multi-head, 4人种串行) =====
for RACE in SA CA AS AF; do
    echo "===== Ablation-3 ResNet50: $RACE ====="
    python predict_p/train.py \
        --model-variant v3 --rgb-backbone resnet50 --global-backbone resnet50 \
        --race $RACE --data-root $DATA --gt-excel $GT --output-root $OUT \
        --exp-name ablation_resnet50 --batch-size 64 \
        --multi-head --attributes all --attribute-gt-dir $ATTR_DIR
    echo "===== $RACE done ====="
done

# ===== Baseline: Full V3 (multi-head, 4人种串行) =====
for RACE in SA CA AS AF; do
    echo "===== Baseline Full V3: $RACE ====="
    python predict_p/train.py \
        --model-variant v3 --rgb-backbone simple_cnn --global-backbone simple_cnn \
        --race $RACE --data-root $DATA --gt-excel $GT --output-root $OUT \
        --exp-name baseline \
        --multi-head --attributes all --attribute-gt-dir $ATTR_DIR
    echo "===== $RACE done ====="
done

# ===== 简单机器学习 =====
for R in CA AS SA AF; do
    python simple_ml/handcrafted_baseline.py \
        --face-root /root/autodl-tmp/rendered_face \
        --gt-excel /root/autodl-tmp/gt/toMax_gt_01Preference.xlsx \
        --output-dir ./simple_ml/output \
        --race $R
done

# ===== 准备 HyperIQA 数据 (4人种) =====
for R in SA CA AS AF; do
    echo "===== Prepare HyperIQA: $R ====="
    python simple_ml/prepare_iqa_data.py \
        --face-root /root/autodl-tmp/rendered_face \
        --gt-excel /root/autodl-tmp/gt/toMax_gt_01Preference.xlsx \
        --output-dir /root/autodl-tmp/iqa_prepared \
        --format hyperiqa \
        --race $R
    echo "===== $R done ====="
done

# ===== 准备 DN-PIQA 数据 (4人种) =====
for R in SA CA AS AF; do
    echo "===== Prepare DN-PIQA: $R ====="
    python simple_ml/prepare_iqa_data.py \
        --face-root /root/autodl-tmp/rendered_face \
        --gt-excel /root/autodl-tmp/gt/toMax_gt_01Preference.xlsx \
        --output-dir /root/autodl-tmp/iqa_prepared \
        --format dnpiqa \
        --race $R
    echo "===== $R done ====="
done
```

---

## 7. 关键注意事项

1. **不要改动原始数据集**: 所有数据准备通过软链接或复制到 `iqa_prepared/` 目录
2. **人种划分一致性**: 所有实验使用相同的 `_RACE_CONFIG` 划分逻辑
3. **GT 列映射**: 所有方法使用 `preference_score` (第 1 列) 作为目标值
4. **图像尺寸**: 人脸图像 224×224，全局图像 224×224
5. **SCUT-FBP5500**: 独立数据集，无法直接在 deepskin 上"retrain"，只能在 SCUT-FBP5500 上训练后用 deepskin 做 cross-dataset 评估
6. **PIQ2023**: 代码不完整（只有模型定义），建议基于 HyperIQA pipeline 运行
