#!/bin/bash
# Batch inference for all experiments with existing checkpoints
# Corresponds to README_retrain_guide1.md lines 102-150 + 484-596
set -e

cd /root/autodl-tmp/deepskin
. /root/miniconda3/etc/profile.d/conda.sh
conda activate deepskin

DATA=/root/autodl-tmp
GT=/root/autodl-tmp/gt/toMax_gt.xlsx
OUT=/root/autodl-tmp/deepskin/predict_p/output
LOG=/root/autodl-tmp/deepskin/predict_p/output/inference_log.txt

echo "===== Batch Inference Started: $(date) =====" | tee $LOG

run_infer() {
    local exp=$1 race=$2 argv="$3"
    echo "[$(date +%H:%M:%S)] $exp / $race ..." | tee -a $LOG
    python predict_p/test_only.py $argv \
        --data-root $DATA --gt-excel $GT --output-root $OUT --num-workers 4 \
        --exp-name $exp --race $race \
        --resume $OUT/$exp/predict_p_$race/checkpoints/best_model.pth \
        2>&1 | grep -E 'Loaded checkpoint|Error|OVERALL|pearson:|pearson_r=|Traceback|RuntimeError' | tee -a $LOG
    echo "---" | tee -a $LOG
}

# ============================================================
# 102-150: Full V1 / Face-only / Concat / ResNet50
# (Full V3 already done)
# ============================================================

# Full V1
for R in SA CA AS AF; do
    run_infer full_v1_loss_mask $R "--model-variant v1 --rgb-backbone simple_cnn --global-backbone simple_cnn --multi-head --attributes all"
done

# Face-only V3
for R in SA CA AS AF; do
    run_infer ablation_face_only_loss_mask_v3 $R "--model-variant v3 --ablation-face-only --rgb-backbone simple_cnn --global-backbone simple_cnn --multi-head --attributes all"
done

# Concat V3
for R in SA CA AS AF; do
    run_infer ablation_concat_loss_mask_v3 $R "--model-variant v3 --ablation-fusion-type concat --rgb-backbone simple_cnn --global-backbone simple_cnn --multi-head --attributes all"
done

# ResNet50 V3
for R in SA CA AS AF; do
    run_infer ablation_resnet50_loss_mask_v3 $R "--model-variant v3 --rgb-backbone resnet50 --global-backbone simple_cnn --multi-head --attributes all"
done

# ============================================================
# 484-596: A1(SA only), A3, A6-A11
# ============================================================

# A1 — MobileNetV3-S (only SA has ckpt)
run_infer ablation_mobilenetv3s_v3 SA "--model-variant v3 --rgb-backbone mobilenet_v3_small --global-backbone simple_cnn --multi-head --attributes all"

# A3 — ViT-B/16
for R in SA CA AS AF; do
    run_infer ablation_vitb16_v3 $R "--model-variant v3 --rgb-backbone vit_b_16 --global-backbone simple_cnn --freeze-backbone --multi-head --attributes all"
done

# A6 — SE-Gated fusion
for R in SA CA AS AF; do
    run_infer ablation_se_fusion_v3 $R "--model-variant v3 --ablation-fusion-type se_gated --rgb-backbone simple_cnn --global-backbone simple_cnn --multi-head --attributes all"
done

# A7 — Cross-Attention fusion
for R in SA CA AS AF; do
    run_infer ablation_cross_attn_v3 $R "--model-variant v3 --ablation-fusion-type cross_attn --rgb-backbone simple_cnn --global-backbone simple_cnn --multi-head --attributes all"
done

# A8 — Statistical Stream
for R in SA CA AS AF; do
    run_infer ablation_stat_stream_v3 $R "--model-variant v3 --ablation-stat-stream --rgb-backbone simple_cnn --global-backbone simple_cnn --multi-head --attributes all"
done

# A9 — Lab center
for R in SA CA AS AF; do
    run_infer ablation_lab_center_v3 $R "--model-variant v3 --ablation-lab-center --rgb-backbone simple_cnn --global-backbone simple_cnn --multi-head --attributes all"
done

# A10 — BCE+SmoothL1
for R in SA CA AS AF; do
    run_infer ablation_bce_loss_v3 $R "--model-variant v3 --ablation-lab-center --ablation-loss-type bce_smooth_l1 --rgb-backbone simple_cnn --global-backbone simple_cnn --multi-head --attributes all"
done

# A11 — MS-CMAN backbone
for R in SA CA AS AF; do
    run_infer ablation_mscman_backbone_v3 $R "--model-variant v3 --rgb-backbone resnet50 --global-backbone mobilenet_v3_small --multi-head --attributes all"
done

echo "===== Batch Inference Finished: $(date) =====" | tee -a $LOG
