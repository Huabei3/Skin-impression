# pyiqa (IQA-PyTorch) 在 deepskin 数据集上训练 + 测试保姆级教程

> 更新时间：2026-07-13
> 适用实例：inst5 (westc, vGPU 48GB, port 32567)
> 数据集：toMax_gt_01Preference.xlsx + rendered_2max/ (23,100 张, 40 subjects, 4 races)
> 划分方式：subject-level split (train/val/test 零泄漏)
> 支持模型：DBCNN / MANIQA / HyperIQA / NIMA / TReS / CLIPIQA / TOPIQ_NR_Face

---

## 0. 环境确认


ssh -p 32567 root@connect.westc.seetacloud.com
# 密码: cIVCU3dIzcLt

. /root/miniconda3/etc/profile.d/conda.sh
conda activate deepskin
python -c "import torch; print(torch.__version__, torch.cuda.is_available())"
# 预期: 2.13.0.dev... True


### 离线权重准备

inst5 无外网，需提前本地下载后上传：

| 文件 | 下载地址 | inst5 目标路径 |
|------|---------|---------------|
| resnet50 backbone | `https://huggingface.co/timm/resnet50.a1_in1k/resolve/main/model.safetensors` | `~/.cache/huggingface/hub/models--timm--resnet50.a1_in1k/snapshots/main/` |
| TOPIQ GFIQA 权重 | `https://huggingface.co/chaofengc/IQA-PyTorch-Weights/resolve/main/topiq_nr_gfiqa_res50-d76bf1ae.pth` | `~/.cache/torch/hub/pyiqa/` |
| facexlib 人脸检测 | `https://github.com/xinntao/facexlib/releases/download/v0.1.0/detection_Resnet50_Final.pth` | `~/.cache/torch/hub/checkpoints/facexlib/weights/` |

上传命令：

# 本地执行（需先下载上述文件到本地）
scp -P 32567 model.safetensors root@connect.westc.seetacloud.com:/root/.cache/huggingface/hub/models--timm--resnet50.a1_in1k/snapshots/main/
scp -P 32567 topiq_nr_gfiqa_res50-d76bf1ae.pth root@connect.westc.seetacloud.com:/root/.cache/torch/hub/pyiqa/
scp -P 32567 detection_Resnet50_Final.pth root@connect.westc.seetacloud.com:/root/.cache/torch/hub/checkpoints/facexlib/weights/


---

## 1. 数据准备：生成 split_result + loss_mask xlsx + meta_info CSV


cd /root/autodl-tmp/iqa_pytorch_train
. /root/miniconda3/etc/profile.d/conda.sh && conda activate deepskin

# 一键生成 4 个 race 的：
#   - datasets/deepskin/{RACE}/meta_info.csv          (pyiqa 训练输入)
#   - datasets/deepskin/{RACE}/split_result_{RACE}.xlsx (场景级 train/val/test 划分)
#   - datasets/deepskin/{RACE}/loss_mask_{RACE}.xlsx   (场景级 10 属性 loss mask)
python prepare_deepskin_data.py --all-races

# 验证 split 分布
for R in SA CA AS AF; do
    echo "=== $R ==="
    python -c "
import pandas as pd
df = pd.read_excel(f'datasets/deepskin/$R/split_result_$R.xlsx')
print(df['Set'].value_counts().to_string())
"
done

# 验证 loss mask
for R in SA CA AS AF; do
    echo "=== $R ==="
    python -c "
import pandas as pd
df = pd.read_excel(f'datasets/deepskin/$R/loss_mask_$R.xlsx')
attr_cols = [c for c in df.columns if c.endswith('_valid')]
print(df[attr_cols].sum().to_string())
print(f'Total scenes: {len(df)}')
"
done


### 输出文件说明

| 文件 | 格式 | 内容 |
|------|------|------|
| `split_result_{RACE}.xlsx` | 场景级，列: `Set/Model/iOr/Scene/original_name/scene_person` | 每个 scene 一行，Set ∈ {train, val, test} |
| `loss_mask_{RACE}.xlsx` | 场景级，列: `folder/subject/scene/{10属性}_valid/valid_attrs` | 每个属性列 TRUE=该 scene 的 33 个 variant 在对应 GT xlsx 中全部有值 |
| `meta_info.csv` | 图片级，列: `name/mos/std/split_name` | pyiqa GeneralNRDataset 训练时的数据输入 |

> 数据加载逻辑**复用** pyiqa 训练时的 `GeneralNRDataset.init_path_mos()` + `get_split()`：
> 路径拼接 = `dataroot_target + name`，split 筛选 = `meta_info['split_name'] == phase`

---


# > 删旧权重的命令 
rm -f /root/autodl-tmp/iqa_pytorch_train/experiments/TReS_*_deepskin/models/net_best.pth
rm -f /root/autodl-tmp/iqa_pytorch_train/experiments/NIMA_*_deepskin/models/net_best.pth


## 2. 训练


cd /root/autodl-tmp/iqa_pytorch_train
. /root/miniconda3/etc/profile.d/conda.sh && conda activate deepskin

RACES=(SA CA AS AF)
# > 支持模型：DBCNN / MANIQA / HyperIQA / NIMA / TReS / CLIPIQA / TOPIQ_NR_Face
MODELS=(NIMA)

for MODEL in "${MODELS[@]}"; do
    echo "========================================================"
    echo "  MODEL: $MODEL"
    echo "========================================================"
    NUM_RACES=${#RACES[@]}
    for ((i=0; i<NUM_RACES; i++)); do
        RACE="${RACES[$i]}"
        CKPT="experiments/${MODEL}_${RACE}_deepskin/models/net_best.pth"

        # 检查下一个 race 是否有 best_model.pth
        if [ $((i+1)) -lt $NUM_RACES ]; then
            NEXT_RACE="${RACES[$((i+1))]}"
            NEXT_CKPT="experiments/${MODEL}_${NEXT_RACE}_deepskin/models/net_best.pth"
        else
            NEXT_CKPT=""
        fi

        # 如果下一个 race 有 best，说明当前 race 早已训完 → skip
        if [ -n "$NEXT_CKPT" ] && [ -f "$NEXT_CKPT" ]; then
            echo "[$MODEL] $RACE SKIPPED (next race $NEXT_RACE has best_model.pth)"
            continue
        fi

        # 当前 race 需要训练：有 best 则续训，没有则从头开始
        if [ -f "$CKPT" ]; then
            echo "[$MODEL] $RACE RESUMING from best_model.pth ..."
        else
            echo "[$MODEL] $RACE Training from scratch ..."
        fi
        HF_HUB_OFFLINE=1 python pyiqa/train.py \
            -opt options/train/deepskin/$MODEL/train_${MODEL}_${RACE}.yml
        echo "[$MODEL] $RACE DONE"
    done
done
echo "ALL DONE"


### 训练逻辑说明

| 场景 | SA | CA | AS | AF | 行为 |
|------|:--:|:--:|:--:|:--:|------|
| 全部训完 | ✅ | ✅ | ✅ | ✅ | 全部 skip |
| AF 未训 | ✅ | ✅ | ✅ | ❌ | SA/CA skip → AS 续训 → AF 从头 |
| AS/AF 未训 | ✅ | ✅ | ❌ | ❌ | SA skip → CA 续训 → AS 从头 → AF 从头 |
| 全部未训 | ❌ | ❌ | ❌ | ❌ | 全部从头 |

- **skip 判断**：下一个 race 有 best_model.pth → 当前 skip（说明更后面的都训完了，当前肯定也训完了）
- **续训判断**：当前 race 有 best_model.pth → 从自己的 best 续训；没有 → 从头训练
- **best_model.pth 不跨 race**：每个 race 独立，各有自己的 best_model.pth
- **不再 archive**：重训时直接复用目录，best_model.pth 只在 val SRCC 更高时才覆盖

### 续训模式（强制从 best_model.pth resume，不 skip）

适用于已训过一轮、想从各 race 的 best 继续训练的场景（配合 early stopping 和更大的 total_iter）：

```bash
cd /root/autodl-tmp/iqa_pytorch_train
. /root/miniconda3/etc/profile.d/conda.sh && conda activate deepskin

RACES=(SA CA AS AF)
MODELS=(NIMA)

for MODEL in "${MODELS[@]}"; do
    for RACE in "${RACES[@]}"; do
        CKPT="experiments/${MODEL}_${RACE}_deepskin/models/net_best.pth"
        if [ -f "$CKPT" ]; then
            echo "[$MODEL] $RACE RESUMING from best_model.pth ..."
        else
            echo "[$MODEL] $RACE WARNING: no best_model.pth, training from scratch"
        fi
        HF_HUB_OFFLINE=1 python pyiqa/train.py \
            -opt options/train/deepskin/$MODEL/train_${MODEL}_${RACE}.yml
        echo "[$MODEL] $RACE DONE"
    done
done
echo "ALL DONE"
```

### 训练配置说明

- **total_iter**: 5000（从 3000 上调，给模型更多收敛空间）
- **early stopping**: patience=10, min_delta=0.001（连续 10 次 val 不改善 SRCC 就停）
- **val_freq**: 200 iter（每 200 iter 触发一次验证）


训练时每 200 iter 触发 val，**实时按 scene 打印 Pearson r**：

  [Val] f08rrs02: Pearson r=0.7234 (iter 200)
  [Val] f08rrs04: Pearson r=0.6851 (iter 200)


### 权重保存路径

experiments/{MODEL}_{RACE}_deepskin/models/net_best.pth     (val最佳)
experiments/{MODEL}_{RACE}_deepskin/models/net_latest.pth   (最新可resume)
experiments/{MODEL}_{RACE}_deepskin/training_states/         (训练状态)


---

## 3. 测试/验证集推理
# > 支持模型：DBCNN / MANIQA / HyperIQA / NIMA / TReS / CLIPIQA / TOPIQ_NR_Face
```bash
cd /root/autodl-tmp/iqa_pytorch_train
. /root/miniconda3/etc/profile.d/conda.sh && conda activate deepskin

# 测试集（test split）
python test_on_deepskin.py --models TReS --races SA       # 单个 model+race
python test_on_deepskin.py --models DBCNN MANIQA TReS    NIMA      TOPIQ_NR_Face    # 多个 model
python test_on_deepskin.py                                          # 全部

# 验证集（val split）
python test_on_deepskin.py --val --models TOPIQ_NR_Face
```

**输出**：`results/{test|val}_{MODEL}_{RACE}.xlsx`，每个文件 4 个 sheet：

| Sheet | 内容 |
|-------|------|
| Params | model/race/phase/ckpt/data_root |
| Overall | SRCC / PLCC(各scene Pearson_r均值) / MAE / RMSE |
| PerGroup | 每个 scene 的 Pearson_r + MAE（33张一组，如 m02ih3k_01~33） |
| RawData | 逐样本 pred/gt/error |

汇总表：`results/{test|val}_summary.xlsx`

---

## 4. 查看所有训练结果汇总

```bash
# 查看 test/val summary
cat /root/autodl-tmp/iqa_pytorch_train/results/test_summary.xlsx
cat /root/autodl-tmp/iqa_pytorch_train/results/val_summary.xlsx
```

---

## 5. 数据结构说明

### CSV 格式 (per race)

csv
name,mos,std,split_name
f04i/f04ih3k_01.jpg,0.8,0.0,train
f02r/f02rrs02_01.jpg,0.58,0.0,val
m02i/m02ih3k_01.jpg,0.7,0.0,test


- `name`: 相对路径 = `{subject}/{filename}.jpg`
- `mos`: preference_score (0-1)
- `split_name`: train / val / test

### YAML 配置结构 (最终版本)

yaml
name: DBCNN_SA_deepskin
model_type: GeneralIQAModel
num_gpu: 1
manual_seed: 42

datasets:
  train:
    name: deepskin_SA
    type: GeneralNRDataset
    dataroot_target: /root/autodl-tmp/rendered_2max
    meta_info_file: .../SA/meta_info.csv
    split_index: split_name          # 新增：按列名筛选
    augment:
      resize: [256, 256]
      random_crop: 224
      hflip: true
    phase: train
    batch_size_per_gpu: 32           # 新增
    num_worker_per_gpu: 4            # 新增
  val:
    name: deepskin_SA
    type: GeneralNRDataset
    dataroot_target: /root/autodl-tmp/rendered_2max
    meta_info_file: .../SA/meta_info.csv
    split_index: split_name          # 新增
    phase: val

network:                              # 注意不是 network_g
  type: DBCNN
  pretrained: true
  fc: false                              # false=全参数微调, true=仅冻骨干(默认)

train:
  optim:                              # 注意不是 optim_g
    type: Adam
    lr: !!float 1e-4
    weight_decay: !!float 1e-4
  scheduler:
    type: CosineAnnealingLR
    T_max: 3000
    eta_min: !!float 1e-7
  total_iter: 3000
  warmup_iter: -1
  mos_loss_opt:                       # 注意不是 losses
    type: L1Loss
    loss_weight: 1.0                  # 注意不是 weight

val:
  val_freq: 200
  save_checkpoint_freq: 500
  key_metric: srcc                    # best model 以 srcc 为准
  save_img: false                     # 新增
  metrics:
    srcc:
      type: calculate_srcc
    plcc:
      type: calculate_plcc

logger:
  print_freq: 50
  save_latest_freq: 500               # 新增
  save_checkpoint_freq: 500
  use_tb_logger: true


### 与原始 pyiqa 示例的差异 (陷阱清单)

| 陷阱 | 错误写法 | 正确写法 |
|------|---------|---------|
| 网络配置 | `network_g:` | `network:` |
| 优化器配置 | `optim_g:` | `optim:` |
| 损失函数 | `losses:` | `mos_loss_opt:` |
| 损失权重 | `weight:` | `loss_weight:` |
| 数据集筛选 | 缺少 | `split_index: split_name` |
| batch size | 缺少 | `batch_size_per_gpu: 32` |
| val 配置 | 缺少 | `save_img: false` |
| logger | 缺少 | `save_latest_freq: 500` |
| 多余参数 | `pretrained_path: null` | 删除 |
| DBCNN 冻骨干 | 默认 `fc: true` | 设为 `fc: false` 可全参数微调 |

---

## 6. pyiqa 可用的 NR 模型

| model_type | 架构 | 参数量 | 权重需求 |
|------------|------|--------|---------|
| `DBCNN` | VGG16+SCNN | ~50M | VGG16 + scnn + KonIQ10k |
| `MANIQA` | ViT-B/8+多维注意力 | ~88M | ViT-B/8 (timm) + koniq10k |
| `HyperIQA` | ResNet50+HyperNet | ~25M | ResNet50 (自带) |
| `NIMA` | VGG16→10-bin分布 | ~138M | ImageNet + AVA |
| `TReS` | ViT-S/16+相对排序 | ~22M | KonIQ-10k |
| `CLIPIQA` | CLIP ViT-B/32 (zero-shot) | ~150M | OpenAI CLIP (自带) |
| `TOPIQ_NR_Face` | Swin-T (人脸专用) | ~28M | Swin-T + 人脸 IQA |
| `MUSIQ` | 多尺度Hash Transformer | ~30M | — |

> 详细架构见 `pyiqa_models_summary.md`

---

## 7. 权重文件手动下载

实例无法访问 HuggingFace，需要本地下载后上传。

| 文件 | 下载地址 | inst5 目标路径 |
|------|---------|---------------|
| ResNet50 backbone | `https://huggingface.co/timm/resnet50.a1_in1k/resolve/main/model.safetensors` | `~/.cache/huggingface/hub/models--timm--resnet50.a1_in1k/snapshots/main/` |
| TOPIQ GFIQA 权重 | `https://huggingface.co/chaofengc/IQA-PyTorch-Weights/resolve/main/topiq_nr_gfiqa_res50-d76bf1ae.pth` | `~/.cache/torch/hub/pyiqa/` |
| facexlib 人脸检测 | `https://github.com/xinntao/facexlib/releases/download/v0.1.0/detection_Resnet50_Final.pth` | `~/.cache/torch/hub/checkpoints/facexlib/weights/` |
| ViT-B/8 | `https://huggingface.co/timm/vit_base_patch8_224.augreg2_in21k_ft_in1k/resolve/main/model.safetensors` | `~/.cache/huggingface/hub/models--timm--vit_base_patch8_224.augreg2_in21k_ft_in1k/snapshots/main/` |
| MANIQA ckpt | `https://huggingface.co/chaofengc/IQA-PyTorch-Weights/resolve/main/ckpt_koniq10k.pt` | `~/.cache/torch/hub/pyiqa/` |
| DBCNN SCNN | `https://huggingface.co/chaofengc/IQA-PyTorch-Weights/resolve/main/DBCNN_scnn-7ea73d75.pth` | `~/.cache/torch/hub/pyiqa/` |
| DBCNN KonIQ | `https://huggingface.co/chaofengc/IQA-PyTorch-Weights/resolve/main/DBCNN_KonIQ10k-2de81c0a.pth` | `~/.cache/torch/hub/pyiqa/` |

---

## 8. checkpoint 说明


experiments/{MODEL}_{RACE}_deepskin/models/
├── net_best.pth       # val SRCC 最佳时的模型参数（覆盖）
├── net_latest.pth     # 最新状态（含 optimizer/scheduler, 用于 resume）
├── net_500.pth        # iter 500 快照（保留）
├── net_1000.pth       # iter 1000 快照
...
└── net_3000.pth       # iter 3000 快照

experiments/{MODEL}_{RACE}_deepskin/training_states/
└── epoch_*.state      # 训练状态（优化器、学习率等）


| 文件 | 触发 | 行为 |
|------|------|------|
| `net_best.pth` | val SRCC 改善 | 覆盖（只保留最优） |
| `net_latest.pth` | 每 500 iter | 覆盖（始终最新） |
| `net_{iter}.pth` | 每 500 iter | 保留（可回溯） |

---

## 9. 重要提示

- **23,100 张全量数据**，subject-level 划分，train/val/test 零泄漏
- **Val = 66 张** (f02/f05/f08/f09 的 rs02+rs04)，用于 early stopping
- **Test = 1,155 张** (m02/m05/m08/m09 全部图片)，只跑一次
- 每个 race 训练约 40 分钟 (DBCNN) ~ 90 分钟 (MANIQA)


# ⑤ DBCNN vs MANIQA 泛化性差异
差异来源	DBCNN (VGG16)	MANIQA (ViT-B/8)
感受野	局部卷积，堆叠扩大	全局自注意力，天然跨区域
特征粒度	固定尺度	多尺度 token + Swin 窗口
参数量	50M（大量冗余在 early layer）	88M（attention 更高效分配）
预训练	ImageNet 分类	ImageNet + KonIQ-10k IQA
跨人泛化	过拟合具体人脸的纹理	学到"美感"的抽象表征
核心原因：MANIQA 的 ViT 自注意力能跨空间建模面部的整体和谐度，VGG16 只能看局部纹理。一个人的纹理换到另一个人身上就失效了。