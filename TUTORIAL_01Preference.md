# hyperIQA x Deepskin 01Preference 保姆级教程

## 当前状态 (已完成)

| 步骤 | 状态 | 说明 |
|------|------|------|
| CSV 数据 | Done | data/deepskin_01pref.csv (693条) |
| DeepskinFolder | Done | 已追加到 folders.py |
| train_test_IQA.py | Done | 路径 + 数量已修正 |

## 项目结构速览

```
/root/autodl-tmp/hyperIQA/
├── data/
│   └── deepskin_01pref.csv    # 新生成的 CSV (693条)
├── folders.py                 # 已添加 DeepskinFolder 类
├── data_loader.py             # 已注册 deepskin 数据集
├── train_test_IQA.py          # 入口 (路径已修正)
├── HyerIQASolver.py           # 训练器
├── models.py                  # 模型定义
└── prepare_deepskin_01pref.py # 数据准备脚本
```

## 数据格式

CSV 格式 (`deepskin_01pref.csv`):
```
img_path,score
/root/autodl-tmp/rendered_2max/f04i/f04ih3k_01.jpg,0.8
/root/autodl-tmp/rendered_2max/f04i/f04ih3k_02.jpg,0.7
...
```

图像映射: `original_name = f04ih3k_01`
→ subject_prefix = `f04i` (前4字符)
→ 路径 = `rendered_2max/f04i/f04ih3k_01.jpg`

## 一行命令启动

```bash
cd /root/autodl-tmp/hyperIQA
. /root/miniconda3/etc/profile.d/conda.sh
conda activate deepskin
find . -name __pycache__ -exec rm -rf {} + 2>/dev/null

# 推荐: 用 screen 跑，断线不中断
screen -S hyperIQA_01pref
python train_test_IQA.py --dataset deepskin
# Ctrl+A D 分离
```

## 快速测试命令

```bash
# 1轮1epoch快速验证 (约5分钟)
python train_test_IQA.py --dataset deepskin --train_test_num 1 --epochs 1 --train_patch_num 5 --test_patch_num 5

# 完整训练
python train_test_IQA.py --dataset deepskin --train_test_num 10 --epochs 16 --batch_size 96
```

## 参数说明

| 参数 | 默认值 | 针对 693 图建议 |
|------|--------|----------------|
| --dataset | deepskin | 必选 |
| --train_test_num | 10 | 可增至20 (小数据多打乱) |
| --epochs | 16 | 可增至30 |
| --batch_size | 96 | 96 安全 |
| --train_patch_num | 25 | 默认即可 |
| --test_patch_num | 25 | 默认即可 |
| --lr | 2e-5 | 默认即可 |
| --patch_size | 224 | 从256x256随机裁剪 |

## 监控

```bash
# 重连 screen
screen -r hyperIQA_01pref

# 监控 GPU
watch -n 2 nvidia-smi
```

## 结果解读

训练完输出:
```
Testing median SRCC x.xxxx,  median PLCC x.xxxx
```

| 指标 | 含义 | 范围 |
|------|------|------|
| SRCC | Spearman 排序相关 | [-1, 1] |
| PLCC | Pearson 线性相关 | [-1, 1] |

## 注意事项

- 数据仅 693 张 (单 subject f04i)，SRCC/PLCC 可能偏低
- Python 环境: conda activate deepskin 或直接用 /root/autodl-tmp/conda_env/bin/python
- RTX 5090 如遇 CUDA 问题: pip install torch torchvision --index-url https://download.pytorch.org/whl/nightly/cu132

