#!/bin/bash
# ============================================================
# 按人种分组训练脚本 (4090 云端)
# 用法: bash train_by_race.sh [CA|AS|SA|AF|all|parallel]
# ============================================================
# 人种映射:
#   CA (Caucasian): {f/m}01-03  test=m02  valid=f02rrs02+f02rrs04
#   AS (Asian):     {f/m}04-06  test=m05  valid=f05rrs02+f05rrs04
#   SA (South Asian):{f/m}07-08  test=m08  valid=f08rrs02+f08rrs04
#   AF (African):   {f/m}09-10  test=m09  valid=f09rrs02+f09rrs04
#
# valid集设置: train.py 中 _RACE_CONFIG 字典的 valid_female_r_prefixes 字段
#   例如 SA: "valid_female_r_prefixes": ["f08rrs02", "f08rrs04"]
#   → 验证集 = f08 的 r(室外) 数据中 rs02 和 rs04 两个场景的全部33张图片
# ============================================================

set -e

# ---------------------- 路径配置（按需修改）----------------------
DATA_ROOT="/root/autodl-tmp"                     # 数据根目录 (rendered_face/rendered_face_uv/rendered_2max/gt 都在这里)
GT_EXCEL="${DATA_ROOT}/gt/toMax_gt.xlsx"          # GT Excel 文件（注意：云端文件名是 toMax_gt.xlsx）
PROJECT_DIR="/root/autodl-tmp/deepskin"          # 项目根目录
OUTPUT_ROOT="${PROJECT_DIR}/predict_p/output"    # 输出根目录
PYTHON="/root/miniconda3/envs/deepskin/bin/python"

cd "$PROJECT_DIR"

RACE="${1:-all}"

# ============================================================
# train_one: 训练单个人种（串行模式使用）
# ============================================================
train_one() {
    local R=$1
    echo ""
    echo "=============================================="
    echo "  Training: $R"
    echo "  $(date)"
    echo "=============================================="
    $PYTHON predict_p/train.py \
        --model-variant v1 \
        --rgb-backbone simple_cnn \
        --global-backbone simple_cnn \
        --race "$R" \
        --data-root "$DATA_ROOT" \
        --gt-excel "$GT_EXCEL" \
        --output-root "$OUTPUT_ROOT" \
        --num-workers 4
}

# ============================================================
# 串行训练：CA → AS → SA → AF
# ============================================================
train_all_serial() {
    for r in CA AS SA AF; do
        train_one "$r"
    done
}

# ============================================================
# 并行训练：同时启动4个训练进程（适合多GPU或显存充足的4090）
# ============================================================
train_all_parallel() {
    echo "Starting all 4 races in parallel..."
    for r in CA AS SA AF; do
        train_one "$r" &
    done
    wait
}

case "$RACE" in
    all)
        train_all_serial
        ;;
    parallel)
        train_all_parallel
        ;;
    CA|AS|SA|AF)
        train_one "$RACE"
        ;;
    *)
        echo "Usage: bash train_by_race.sh [CA|AS|SA|AF|all|parallel]"
        echo ""
        echo "  CA/AS/SA/AF  训练单个人种"
        echo "  all           串行训练全部4个人种（一个接一个）"
        echo "  parallel      并行训练全部4个人种（同时启动）"
        exit 1
        ;;
esac

echo ""
echo "All training completed at $(date)"
