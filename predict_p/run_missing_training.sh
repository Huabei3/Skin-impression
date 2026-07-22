#!/bin/bash
# Training for experiments without checkpoints (missing from v3new1)
# Corresponds to README_retrain_guide1.md A1-A5
set -e

cd /root/autodl-tmp/deepskin
. /root/miniconda3/etc/profile.d/conda.sh
conda activate deepskin

DATA=/root/autodl-tmp
GT=/root/autodl-tmp/gt/toMax_gt.xlsx
OUT=/root/autodl-tmp/deepskin/predict_p/output
LOG=/root/autodl-tmp/deepskin/predict_p/output/training_log.txt

echo "===== Batch Training Started: $(date) =====" | tee $LOG

run_train() {
    local exp=$1 race=$2 argv="$3" bs=${4:-16}
    echo "[$(date +%H:%M:%S)] TRAIN $exp / $race (bs=$bs) ..." | tee -a $LOG
    python predict_p/train.py $argv \
        --data-root $DATA --gt-excel $GT --output-root $OUT --num-workers 4 \
        --exp-name $exp --race $race --batch-size $bs \
        --multi-head --attributes all --nan-handling loss_mask \
        2>&1 | tee -a $LOG
    echo "---" | tee -a $LOG
}

# ============================================================
# A1 — MobileNetV3-S: CA, AS, AF (SA already trained)
# ============================================================
for R in CA AS AF; do
    run_train ablation_mobilenetv3s_v3 $R \
        "--model-variant v3 --rgb-backbone mobilenet_v3_small --global-backbone simple_cnn" 64
done

# ============================================================
# A2 — MobileNetV3-L: all 4 races
# ============================================================
for R in SA CA AS AF; do
    run_train ablation_mobilenetv3l_v3 $R \
        "--model-variant v3 --rgb-backbone mobilenet_v3_large --global-backbone simple_cnn" 32
done

# ============================================================
# A4 — Swin-T (frozen): all 4 races
# ============================================================
for R in SA CA AS AF; do
    run_train ablation_swint_v3 $R \
        "--model-variant v3 --rgb-backbone swin_t --global-backbone simple_cnn --freeze-backbone" 8
done

# ============================================================
# A5 — CLIP ViT-B/32 (frozen): all 4 races
# ============================================================
for R in SA CA AS AF; do
    run_train ablation_clip_v3 $R \
        "--model-variant v3 --rgb-backbone clip_vit_b32 --global-backbone simple_cnn --freeze-backbone" 8
done

echo "===== Batch Training Finished: $(date) =====" | tee -a $LOG
