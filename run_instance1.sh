#!/bin/bash
# ============================================================
# instance1 (RTX 4090, 48GB) — Baseline Full V3 (multi-head)
# ssh -p 17461 root@connect.westb.seetacloud.com
# ============================================================
set -e
cd /root/autodl-tmp/deepskin
. /root/miniconda3/etc/profile.d/conda.sh
conda activate deepskin

DATA=/root/autodl-tmp
GT=/root/autodl-tmp/gt/toMax_gt_01Preference.xlsx
OUT=/root/autodl-tmp/deepskin/predict_p/output
ATTR_DIR=/root/autodl-tmp/gt

for RACE in SA CA AS AF; do
    echo "======================================================"
    echo "  Baseline Full V3: $RACE  $(date)"
    echo "======================================================"
    python predict_p/train.py \
        --model-variant v3 \
        --rgb-backbone simple_cnn --global-backbone simple_cnn \
        --race $RACE \
        --data-root $DATA --gt-excel $GT --output-root $OUT \
        --exp-name baseline \
        --multi-head --attributes all --attribute-gt-dir $ATTR_DIR
    echo "===== Baseline $RACE done @ $(date) ====="
done

echo "======================================================"
echo "  instance1 ALL DONE @ $(date)"
echo "======================================================"
