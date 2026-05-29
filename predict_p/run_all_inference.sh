#!/bin/bash
# predict_p 批量推理脚本 - 在云端运行
set -e

OUTPUT_ROOT="/root/autodl-tmp/deepskin/predict_p/inference_results"
CHECKPOINT_DIR="/root/autodl-tmp/deepskin/facial_preference/output/pt"
PYTHON="/root/miniconda3/envs/deepskin/bin/python3"

mkdir -p "$OUTPUT_ROOT"

echo "=========================================="
echo "predict_p 批量推理"
echo "=========================================="
echo "Python: $PYTHON"
$PYTHON --version
echo "Checkpoint目录: $CHECKPOINT_DIR"
echo "输出目录: $OUTPUT_ROOT"
echo ""

CHECKPOINTS=(
    "best_model_predict_p:best_model_predict_p.pth"
    "best_model_all:best_model_all.pth"
    "best_model_predict_p_v3:best_model_predict_p_v3.pth"
    "best_model_predict_p_v3_oppo_finetune:best_model_predict_p_v3_oppo_finetune.pth"
    "best_model_predict_p_v3_oppo_finetune_ori:best_model_predict_p_v3_oppo_finetune_ori.pth"
    "best_model_predict_p_v3_oppo_finetune2v:best_model_predict_p_v3_oppo_finetune2v.pth"
    "best_model_predict_p_v3_oppo_finetune_2v:best_model_predict_p_v3_oppo_finetune_2v.pth"
    "best_model_universal_p_v3:best_model_universal_p_v3.pth"
)

run_inference() {
    local name=$1
    local checkpoint_file=$2
    local checkpoint_path="$CHECKPOINT_DIR/$checkpoint_file"

    echo "----------------------------------------"
    echo "处理模型: $name"
    echo "Checkpoint: $checkpoint_path"

    if [ ! -f "$checkpoint_path" ]; then
        echo "ERROR: Checkpoint文件不存在: $checkpoint_path"
        return 1
    fi

    $PYTHON /root/autodl-tmp/deepskin/predict_p/predict_p_inference.py \
        --checkpoint "$checkpoint_path" \
        --subjects "f01,f02,f03,m01,m02,m03" \
        --output "$OUTPUT_ROOT/$name" \
        --device cuda

    echo "完成: $name"
}

for item in "${CHECKPOINTS[@]}"; do
    name="${item%%:*}"
    file="${item##*:}"
    run_inference "$name" "$file" || true
done

echo "=========================================="
echo "所有推理完成!"
echo "结果保存在: $OUTPUT_ROOT"
echo "=========================================="
ls -la "$OUTPUT_ROOT"
