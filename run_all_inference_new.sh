#!/bin/bash
# Batch inference: baseline + ablation1/2/3
set -e
PYTHON=/root/miniconda3/envs/deepskin/bin/python
DATA=/root/autodl-tmp
GT=/root/autodl-tmp/gt/toMax_gt.xlsx
OUT=/root/autodl-tmp/deepskin/predict_p/output
LOG_BASE="$OUT/inference_logs"
mkdir -p "$LOG_BASE"

log() {
    echo "[$(date '+%H:%M:%S')] $1" | tee -a "$LOG_BASE/inference_all.log"
}

run_infer() {
    local exp="$1" race="$2" extra_args="$3"
    local ckpt="$OUT/$exp/predict_p_$race/checkpoints/best_model.pth"
    local logfile="$LOG_BASE/${exp}_${race}.log"

    if [ ! -f "$ckpt" ]; then
        log "SKIP $exp/$race: checkpoint not found"
        return
    fi

    log "START $exp/$race"
    $PYTHON predict_p/test_only.py \
        --model-variant v3 \
        --race "$race" \
        --data-root "$DATA" \
        --gt-excel "$GT" \
        --output-root "$OUT" \
        --exp-name "$exp" \
        --resume "$ckpt" \
        --num-workers 4 \
        --multi-head \
        --attributes all \
        $extra_args \
        >> "$logfile" 2>&1
    local rc=$?
    log "DONE  $exp/$race (exit=$rc)"
}

cd /root/autodl-tmp/deepskin

log "==== baseline (full V3) ===="
run_infer baseline AS "--rgb-backbone simple_cnn --global-backbone simple_cnn"
run_infer baseline CA "--rgb-backbone simple_cnn --global-backbone simple_cnn"

log "==== ablation_face_only ===="
run_infer ablation_face_only CA "--rgb-backbone simple_cnn --global-backbone simple_cnn --ablation-face-only"
run_infer ablation_face_only SA "--rgb-backbone simple_cnn --global-backbone simple_cnn --ablation-face-only"

log "==== ablation_concat ===="
run_infer ablation_concat AS "--rgb-backbone simple_cnn --global-backbone simple_cnn --ablation-fusion-type concat"
run_infer ablation_concat CA "--rgb-backbone simple_cnn --global-backbone simple_cnn --ablation-fusion-type concat"
run_infer ablation_concat SA "--rgb-backbone simple_cnn --global-backbone simple_cnn --ablation-fusion-type concat"

log "==== ablation_resnet50 ===="
run_infer ablation_resnet50 CA "--rgb-backbone resnet50 --global-backbone simple_cnn"
run_infer ablation_resnet50 SA "--rgb-backbone resnet50 --global-backbone simple_cnn"

log "==== ALL DONE ===="
