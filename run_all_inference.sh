#!/bin/bash
# 自动推理：检测所有可用 checkpoint 并跑 test_only
PYTHON=/root/miniconda3/envs/deepskin/bin/python
DATA=/root/autodl-tmp
GT=/root/autodl-tmp/gt/toMax_gt.xlsx
OUT=/root/autodl-tmp/deepskin/predict_p/output
LOG="$OUT/inference_auto_$(date +%m%d_%H%M).log"
LOG_BASE="$OUT/inference_auto_logs"
mkdir -p "$LOG_BASE"

log() { echo "[$(date '+%H:%M:%S')] $1" | tee -a "$LOG"; }

run_ckpt() {
    local exp="$1" race="$2" variant="$3" extra="$4"
    local ckpt="$OUT/$exp/predict_p_$race/checkpoints/best_model.pth"
    local logfile="$LOG_BASE/${exp}_${race}.log"
    [ -f "$ckpt" ] || { log "SKIP $exp/$race (no ckpt)"; return; }
    log "START $exp/$race ($variant)"
    $PYTHON predict_p/test_only.py --model-variant "$variant" \
        --race "$race" --data-root "$DATA" --gt-excel "$GT" \
        --output-root "$OUT" --exp-name "$exp" --resume "$ckpt" \
        --multi-head --attributes all --num-workers 4 $extra \
        >> "$logfile" 2>&1
    local rc=$?
    log "DONE  $exp/$race (exit=$rc)"
}

cd /root/autodl-tmp/deepskin

# V3 experiments
V3_EXPS=(
  "full_v3_loss_mask|simple_cnn|simple_cnn|"
  "ablation_face_only_loss_mask_v3|simple_cnn|simple_cnn|--ablation-face-only"
  "ablation_concat_loss_mask_v3|simple_cnn|simple_cnn|--ablation-fusion-type concat"
  "ablation_resnet50_loss_mask_v3|resnet50|simple_cnn|"
)

for entry in "${V3_EXPS[@]}"; do
  IFS='|' read exp rgb gbl extra <<< "$entry"
  for race in SA CA AS AF; do
    run_ckpt "$exp" "$race" "v3" "--rgb-backbone $rgb --global-backbone $gbl $extra"
  done
done

# V1 experiments
for race in SA CA AS AF; do
  run_ckpt "full_v1_loss_mask" "$race" "v1" "--rgb-backbone simple_cnn --global-backbone simple_cnn"
done

log "==== ALL DONE ===="
