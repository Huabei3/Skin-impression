#!/bin/bash
# ============================================================
# Gao 2024 Quality-guided STE on deepskin — full pipeline
# Run on cloud instance inst2 (westd, port 49348)
# Usage: bash run_all.sh [--skip-adapter] [--race CA]
# ============================================================
set -e

DATA=/root/autodl-tmp
GT=${DATA}/gt/toMax_gt.xlsx
GAO_DIR=${DATA}/Quality_guided_STE
OUT_DIR=${GAO_DIR}/output

cd ${DATA}/deepskin
. /root/miniconda3/etc/profile.d/conda.sh
conda activate deepskin

# ── Step 0: Install kornia if not present ──
python -c "import kornia" 2>/dev/null || pip install kornia openpyxl pandas scipy tqdm -q

# ── Step 1: Data preparation ──
if [[ "$1" != "--skip-adapter" ]]; then
    echo "========================================"
    echo "  Step 1: Data Adapter (all 4 races)"
    echo "========================================"
    for RACE in CA AS SA AF; do
        echo "--- Preparing data for $RACE ---"
        python predict_p/gao2024/data_adapter.py \
            --data-root ${DATA} \
            --gt-xlsx ${GT} \
            --race ${RACE} \
            --output-dir ${GAO_DIR} \
            --write-info-json
    done
    echo "Data preparation complete."
    echo ""
    echo "═══ CHECK 1: Split result xlsx ═══"
    ls -la ${GAO_DIR}/data_check/split_result_*.xlsx
    echo ""
    echo "═══ CHECK 2: Data integrity xlsx ═══"
    ls -la ${GAO_DIR}/data_check/data_integrity_*.xlsx
    echo ""
else
    shift
    echo "Skipping data adapter (--skip-adapter)"
fi

# ── Step 2: Training (per race) ──
echo "========================================"
echo "  Step 2: Training"
echo "========================================"

RACE_ARG=""
if [[ -n "$1" ]]; then
    RACE_ARG="--race $1"
fi

if [[ -n "$RACE_ARG" ]]; then
    echo "Training single race: $1"
    python predict_p/gao2024/train.py \
        --data-root ${DATA} \
        --output-root ${OUT_DIR} \
        ${RACE_ARG} \
        --batch-size 1 --epochs 400 --lr 1e-4 \
        --num-workers 4

    echo "Training complete."
    echo "═══ CHECK: best_model.pth ═══"
    for R in CA AS SA AF; do
        CKPT=${OUT_DIR}/gao2024_${R}/best_model.pth
        if [ -f "$CKPT" ]; then
            echo "  ✅ $R: $CKPT"
        else
            echo "  ❌ $R: missing"
        fi
    done
else
    echo "Training all 4 races..."
    for RACE in CA AS SA AF; do
        echo "========================================"
        echo "  Training: $RACE"
        echo "========================================"
        python predict_p/gao2024/train.py \
            --data-root ${DATA} \
            --output-root ${OUT_DIR} \
            --race ${RACE} \
            --batch-size 1 --epochs 400 --lr 1e-4 \
            --num-workers 4
    done
fi

echo "========================================"
echo "  All done — best_model.pth check"
echo "========================================"
for R in CA AS SA AF; do
    CKPT=${OUT_DIR}/gao2024_${R}/best_model.pth
    if [ -f "$CKPT" ]; then
        SIZE=$(du -h "$CKPT" | cut -f1)
        # Get val_pearson_r from json
        METRICS=${OUT_DIR}/gao2024_${R}/best_metrics.json
        VAL_R="?"
        [ -f "$METRICS" ] && VAL_R=$(python -c "import json; d=json.load(open('$METRICS')); print(f\"{d['val_pearson_r']:.4f}\")" 2>/dev/null || echo "?")
        echo "  ✅ $R  r=$VAL_R  size=$SIZE  $CKPT"
    else
        echo "  ❌ $R  missing"
    fi
done
