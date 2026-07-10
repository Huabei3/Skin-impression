# Gao 2024 Quality-guided Skin Tone Enhancement — deepskin 适配指南

> **云端实例**: inst2 (westc) — `ssh -p 30844 root@connect.westc.seetacloud.com` / 密码 `9uJXpNG3JN04` / GPU: RTX 4080 SUPER 32GB  
> **项目路径**: `/root/autodl-tmp/deepskin`  
> **Gao 代码**: `/root/autodl-tmp/Quality_guided_STE/`  
> **数据根目录**: `/root/autodl-tmp`

---

## 一、从头开始训练（完整流程）

```bash
# 1. SSH 登录
ssh -p 30844 root@connect.westc.seetacloud.com

# 2. 进入环境
cd /root/autodl-tmp/deepskin
. /root/miniconda3/etc/profile.d/conda.sh
conda activate deepskin

# 3. 【Step 1】数据预处理 — 生成 split + integrity xlsx + info.json
rm -rf /root/autodl-tmp/Quality_guided_STE/gao_data_* \
       /root/autodl-tmp/Quality_guided_STE/data_check

python predict_p/gao2024/data_adapter.py \
    --data-root /root/autodl-tmp \
    --gt-xlsx /root/autodl-tmp/gt/toMax_gt.xlsx \
    --output-dir /root/autodl-tmp/Quality_guided_STE \
    --all-races --write-info-json

# 4. 【CHECK ①】验证 split 输出
ls -la /root/autodl-tmp/Quality_guided_STE/data_check/

# 5. 【CHECK ②】验证数据完整性
python -c "
import pandas as pd
for race in ['CA','AS','SA','AF']:
    df = pd.read_excel(f'/root/autodl-tmp/Quality_guided_STE/data_check/data_integrity_{race}.xlsx')
    missing = (~df['img_exists']).sum()
    print(f'{race}: {len(df)} rows, {missing} missing images')
"

# 6. 【Step 2】开始训练（4 race 循环，建议用 screen）
screen -S train_gao
for RACE in CA AS SA AF; do
    echo "========== Training $RACE =========="
    python predict_p/gao2024/train.py \
        --data-root /root/autodl-tmp \
        --output-root /root/autodl-tmp/Quality_guided_STE/output \
        --race $RACE \
        --batch-size 1 --epochs 400 --lr 1e-4 \
        --num-workers 4
done
# Ctrl+A D 断开 screen，screen -r train_gao 恢复

# 7. 【CHECK ③】确认 best_model.pth 和 metrics
for R in CA AS SA AF; do
    CKPT=/root/autodl-tmp/Quality_guided_STE/output/gao2024_${R}/best_model.pth
    METRICS=/root/autodl-tmp/Quality_guided_STE/output/gao2024_${R}/best_metrics.json
    if [ -f "$CKPT" ]; then
        SIZE=$(du -h "$CKPT" | cut -f1)
        R_VAL=$(python -c "import json; print(f\"{json.load(open('$METRICS'))['val_pearson_r']:.4f}\")" 2>/dev/null || echo "?")
        echo "✅ $R  r=$R_VAL  size=$SIZE"
    else
        echo "❌ $R  MISSING"
    fi
done

# 8. 【Step 3】测试
for RACE in CA AS SA AF; do
    echo "========== Testing $RACE =========="
    python predict_p/gao2024/test.py \
        --data-root /root/autodl-tmp \
        --output-root /root/autodl-tmp/Quality_guided_STE/output \
        --race $RACE
done
```

---

## 二、单 race 训练（快速验证）

```bash
cd /root/autodl-tmp/deepskin && . /root/miniconda3/etc/profile.d/conda.sh && conda activate deepskin

# 仅训练 SA（最快，3465 样本）
python predict_p/gao2024/train.py \
    --data-root /root/autodl-tmp \
    --output-root /root/autodl-tmp/Quality_guided_STE/output \
    --race SA \
    --batch-size 1 --epochs 400 --lr 1e-4 \
    --num-workers 4
```

---

## 三、断点续训

Gao 2024 的 train.py **暂未实现 resume**。如需续训：

```bash
# 方式: 减少 epochs 数，降低 lr 做 fine-tune
python predict_p/gao2024/train.py \
    --data-root /root/autodl-tmp \
    --output-root /root/autodl-tmp/Quality_guided_STE/output \
    --race SA \
    --epochs 600 \
    --lr 5e-5 \
    --num-workers 4

# train.py 会自动保存 best_model.pth（按 val_pearson_r 择优）
# 每 50 epoch 保存 checkpoint_epoch_XX.pth
```

---

## 四、仅预处理（输出 xlsx 验证）— 喜好度

```bash
cd /root/autodl-tmp/deepskin && . /root/miniconda3/etc/profile.d/conda.sh && conda activate deepskin

# 清旧数据
rm -rf /root/autodl-tmp/Quality_guided_STE/gao_data_* \
       /root/autodl-tmp/Quality_guided_STE/data_check

# 生成 split 和 integrity（只出 xlsx，不写 info.json，更快）
# 会自动从 toMax_gt_{attribute_serial}.xlsx 读取对应属性
python predict_p/gao2024/data_adapter.py \
    --data-root /root/autodl-tmp \
    --output-dir /root/autodl-tmp/Quality_guided_STE \
    --all-races \
    --attribute-serial 01Preference

# 检查输出
ls -lh /root/autodl-tmp/Quality_guided_STE/data_check/

# 验证 split 分布
python -c "
import pandas as pd
for race in ['CA','AS','SA','AF']:
    df = pd.read_excel(f'/root/autodl-tmp/Quality_guided_STE/data_check/split_result_{race}.xlsx')
    print(f'--- {race} ---')
    print(df['Set'].value_counts().to_string())
    print()
"
```

**预期输出**:
```
--- CA ---
train    5445
test     1155
valid     330        ← 约 2场景×33变体×5个f subjects=330
--- AS ---
train    5445
test     1155
valid     330
--- SA ---
train    3300       ← 只有2个f subjects (f07,f08)
test     1155
valid     165       ← f08r 的 rs02+rs04 ×33
--- AF ---
train    3300
test     1155
valid     165
```

---

## 五、全部 10 属性 integrity 检查（loss mask 数据）

直接从 10 个 GT xlsx 读取，按场景聚合，每行一个 scene、10 列对应 10 个属性。

```bash
cd /root/autodl-tmp/deepskin && . /root/miniconda3/etc/profile.d/conda.sh && conda activate deepskin

# 一键生成：场景级，10 属性列，TRUE=该场景 33 个 variant 全部有 GT 评分
python predict_p/gao2024/data_adapter.py \
    --data-root /root/autodl-tmp \
    --output-dir /root/autodl-tmp/Quality_guided_STE \
    --all-races --combine-integrity

# 输出: data_check/data_integrity_{RACE}.xlsx
# 列: folder | subject | scene | 01Preference_valid | ... | 10Ruddy_valid | valid_attrs
```

---

## 六、单独测试

```bash
cd /root/autodl-tmp/deepskin && . /root/miniconda3/etc/profile.d/conda.sh && conda activate deepskin

# 测试 SA（需要先训练完成）
python predict_p/gao2024/test.py \
    --data-root /root/autodl-tmp \
    --output-root /root/autodl-tmp/Quality_guided_STE/output \
    --race SA

# 或全部
for RACE in CA AS SA AF; do
    python predict_p/gao2024/test.py \
        --data-root /root/autodl-tmp \
        --output-root /root/autodl-tmp/Quality_guided_STE/output \
        --race $RACE
done
```

输出文件：
- `gao2024_{RACE}/test_results.json` — Pearson r + 逐样本结果
- `gao2024_{RACE}/test_outputs/` — 增强后的图片

---

## 七、一键脚本

```bash
cd /root/autodl-tmp/deepskin && . /root/miniconda3/etc/profile.d/conda.sh && conda activate deepskin

# 全流程（适配 + 训练 4 race + 检查）
bash predict_p/gao2024/run_all.sh

# 跳过数据预处理
bash predict_p/gao2024/run_all.sh --skip-adapter

# 仅训练单个 race
bash predict_p/gao2024/run_all.sh --skip-adapter --race SA
```

---

## 八、训练过程监控

```bash
# 实时看 loss（训练中 stdout 打印）
# 样本输出:
# [SA] Epoch   1/400 | train_loss=0.0234 train_r=0.8512 | val_loss=0.0241 val_r=0.8432

# 查看已保存的 metrics
cat /root/autodl-tmp/Quality_guided_STE/output/gao2024_SA/best_metrics.json

# 查看训练历史
cat /root/autodl-tmp/Quality_guided_STE/output/gao2024_SA/training_history.json

# 检查 GPU 使用
nvidia-smi
```

---

## 九、本地开发 → 云端同步

```bash
# 本地修改代码后上传
cd D:\work\VIVOSkinExpe\deepskin
python _upload_gao2024_step2.py

# 或手动逐个上传
scp -P 30844 predict_p/gao2024/data_adapter.py root@connect.westc.seetacloud.com:/root/autodl-tmp/deepskin/predict_p/gao2024/
```

---

## 十、关键参数说明

| 参数 | 默认值 | 说明 |
|------|--------|------|
| `--batch-size` | 1 | 论文原值，增大可能 OOM |
| `--epochs` | 400 | 论文原值 |
| `--lr` | 1e-4 | Adam 学习率 |
| `--n-base-1d` | 3 | 1D LUT 基础个数 |
| `--n-base-3d` | 3 | 3D LUT 基础个数 |
| `--lut-dim` | 33 | LUT 分辨率 |
| `--use-skin-label` | False | per-race 训练时关闭；跨 race 训练可开启 |

---

## 十一、输出目录结构

```
/root/autodl-tmp/Quality_guided_STE/
├── data_check/
│   ├── split_result_{CA,AS,SA,AF}.xlsx         ← 场景级训练/验证/测试划分
│   └── data_integrity_{CA,AS,SA,AF}.xlsx       ← 场景级 10 属性 loss mask
├── gao_data_{CA,AS,SA,AF}/
│   ├── train/sample_XXXXX/{raw.png, adjusted.png, info.json}
│   ├── valid/sample_XXXXX/{raw.png, adjusted.png, info.json}
│   └── test/sample_XXXXX/{raw.png, adjusted.png, info.json}
└── output/
    └── gao2024_{CA,AS,SA,AF}/
        ├── best_model.pth
        ├── best_metrics.json
        ├── training_history.json
        └── test_results.json + test_outputs/
```

---

## 十二、完整 checklist（跑模型前必做）

| # | 检查项 | 命令 |
|---|--------|------|
| 1 | 数据集划分验证 | 查看 `data_check/split_result_{RACE}.xlsx`，确认 train/valid/test 分布正确，无 subject 泄漏 |
| 2 | 数据完整性验证 | 查看 `data_check/data_integrity_{RACE}.xlsx`，确认 `img_exists` 全 True |
| 3 | **10 属性 loss mask** | 运行 `--combine-integrity` 查看 `data_integrity_{RACE}.xlsx` 的 10 属性列 |
| 4 | checkpoint 保存确认 | 训练完成后 `ls -la output/gao2024_{RACE}/best_model.pth` |

三个 xlsx + loss_mask xlsx 齐了再开始训练。
