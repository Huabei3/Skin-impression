# ===== 环境 =====
cd /root/autodl-tmp/deepskin
. /root/miniconda3/etc/profile.d/conda.sh
conda activate deepskin

# ===== 通用参数 =====
DATA=/root/autodl-tmp
GT=/root/autodl-tmp/gt/toMax_gt.xlsx
OUT=/root/autodl-tmp/deepskin/predict_p/output

# ============================================================
# ① V3 训练
# ============================================================
# 注意: 每个 for 循环内加了 CKPT 检查，已有 checkpoints 的 race 自动跳过

# Ablation 1: face_only V3
for RACE in SA; do
<!-- for RACE in SA CA AS AF; do -->
  <!-- CKPT="$OUT/ablation_face_only_loss_mask_v3/predict_p_$RACE/checkpoints/best_model.pth"
  [ -f "$CKPT" ] && echo "SKIP $RACE: exists" && continue -->
  python predict_p/train.py \
    --model-variant v3 \
    --race $RACE --multi-head --attributes all --nan-handling loss_mask \
    --ablation-face-only --rgb-backbone simple_cnn --global-backbone simple_cnn \
    --data-root $DATA --gt-excel $GT \
    --output-root $OUT \
    --exp-name ablation_face_only_loss_mask_v3 --num-workers 4 --batch-size 16
done

# Ablation 2: concat fusion V3
for RACE in SA CA AS AF; do
  CKPT="$OUT/ablation_concat_loss_mask_v3/predict_p_$RACE/checkpoints/best_model.pth"
  [ -f "$CKPT" ] && echo "SKIP $RACE: exists" && continue
  python predict_p/train.py \
    --model-variant v3 \
    --race $RACE --multi-head --attributes all --nan-handling loss_mask \
    --ablation-fusion-type concat --rgb-backbone simple_cnn --global-backbone simple_cnn \
    --data-root $DATA --gt-excel $GT \
    --output-root $OUT \
    --exp-name ablation_concat_loss_mask_v3 --num-workers 4 --batch-size 16
done

# Ablation 3: resnet50 backbone V3
for RACE in SA CA AS AF; do
  CKPT="$OUT/ablation_resnet50_loss_mask_v3/predict_p_$RACE/checkpoints/best_model.pth"
  [ -f "$CKPT" ] && echo "SKIP $RACE: exists" && continue
  python predict_p/train.py \
    --model-variant v3 \
    --race $RACE --multi-head --attributes all --nan-handling loss_mask \
    --rgb-backbone resnet50 --global-backbone simple_cnn \
    --data-root $DATA --gt-excel $GT \
    --output-root $OUT \
    --exp-name ablation_resnet50_loss_mask_v3 --num-workers 4 --batch-size 16
done


云实例指令：ssh -p 36632 root@connect.westc.seetacloud.com
密码：VULYLA/HdU6r
项目：deepskin
我想要测试：
人脸分支与全局分支（采用轻量级CNN骨干）参数量约[]。门控加权融合模块额外参数量约[]。10个多属性预测头各由三层MLP组成参数量约[]。完整模型的可训练参数量约为[]。
在训练效率方面，模型在单张NVIDIA RTX 4080 SUPER GPU上以batch size []进行训练，前向传播与反向传播单次迭代耗时约[]毫秒，单轮epoch（约[]个batch）耗时约[]秒。在早停机制（patience=100）触发时，典型训练收敛轮次约为[] epoch，单次完整训练耗时约[]分钟。 
在推理效率方面，ZJU_SKIN在单张NVIDIA RTX 4080 SUPER GPU上处理单张224×224图像的耗时约[]毫秒，GPU推理速度约[] FPS，而MANIQA在同等GPU条件下推理速度约[] FPS。

训练指令：
# Full V3: 从头训
for RACE in AF; do
<!-- for RACE in SA CA AS AF; do -->
  <!-- CKPT="$OUT/full_v3_loss_mask/predict_p_$RACE/checkpoints/best_model.pth"
  [ -f "$CKPT" ] && echo "SKIP $RACE: exists" && continue -->
  python predict_p/train.py \
    --model-variant v3 \
    --race $RACE --multi-head --attributes all --nan-handling loss_mask \
    --rgb-backbone simple_cnn --global-backbone simple_cnn \
    --data-root $DATA --gt-excel $GT \
    --output-root $OUT \
    --exp-name full_v3_loss_mask --num-workers 4 --batch-size 16 \
    --resume $OUT/full_v3_loss_mask/predict_p_$RACE/checkpoints/best_model.pth
done

# ============================================================
# ①-bis V1 训练（仅 inst2 保留用于对比）
# ============================================================
# Full V1: 从头训
for RACE in SA CA AS AF; do
  CKPT="$OUT/full_v1_loss_mask/predict_p_$RACE/checkpoints/best_model.pth"
  [ -f "$CKPT" ] && echo "SKIP $RACE: exists" && continue
  python predict_p/train.py \
    --model-variant v1 \
    --race $RACE --multi-head --attributes all --nan-handling loss_mask \
    --rgb-backbone simple_cnn --global-backbone simple_cnn \
    --data-root $DATA --gt-excel $GT \
    --output-root $OUT \
    --exp-name full_v1_loss_mask --num-workers 4 --batch-size 16 \

done

# ============================================================
# ② 推理命令
# ============================================================

# Full V3 (inst2)
for RACE in SA CA AS AF; do
  python predict_p/test_only.py --model-variant v3 \
    --rgb-backbone simple_cnn --global-backbone simple_cnn \
    --multi-head --attributes all \
    --data-root $DATA --gt-excel $GT --output-root $OUT --num-workers 4 \
    --exp-name full_v3_loss_mask --race $RACE \
    --resume $OUT/full_v3_loss_mask/predict_p_$RACE/checkpoints/best_model.pth
done

# Full V1 (inst1)
for RACE in SA CA AS AF; do
  python predict_p/test_only.py --model-variant v1 \
    --rgb-backbone simple_cnn --global-backbone simple_cnn \
    --multi-head --attributes all \
    --data-root $DATA --gt-excel $GT --output-root $OUT --num-workers 4 \
    --exp-name full_v1_loss_mask --race $RACE \
    --resume $OUT/full_v1_loss_mask/predict_p_$RACE/checkpoints/best_model.pth
done

# Ablation 1 — face_only V3 (inst3)
for RACE in SA CA AS AF; do
  python predict_p/test_only.py --model-variant v3 --ablation-face-only \
    --rgb-backbone simple_cnn --global-backbone simple_cnn \
    --multi-head --attributes all \
    --data-root $DATA --gt-excel $GT --output-root $OUT --num-workers 4 \
    --exp-name ablation_face_only_loss_mask_v3 --race $RACE \
    --resume $OUT/ablation_face_only_loss_mask_v3/predict_p_$RACE/checkpoints/best_model.pth
done

# Ablation 2 — concat V3 (inst4)
for RACE in SA CA AS AF; do
  python predict_p/test_only.py --model-variant v3 --ablation-fusion-type concat \
    --rgb-backbone simple_cnn --global-backbone simple_cnn \
    --multi-head --attributes all \
    --data-root $DATA --gt-excel $GT --output-root $OUT --num-workers 4 \
    --exp-name ablation_concat_loss_mask_v3 --race $RACE \
    --resume $OUT/ablation_concat_loss_mask_v3/predict_p_$RACE/checkpoints/best_model.pth
done

# Ablation 3 — resnet50 V3 (inst5)
for RACE in SA CA AS AF; do
  python predict_p/test_only.py --model-variant v3 \
    --rgb-backbone resnet50 --global-backbone simple_cnn \
    --multi-head --attributes all \
    --data-root $DATA --gt-excel $GT --output-root $OUT --num-workers 4 \
    --exp-name ablation_resnet50_loss_mask_v3 --race $RACE \
    --resume $OUT/ablation_resnet50_loss_mask_v3/predict_p_$RACE/checkpoints/best_model.pth
done


# ============================================================
# ③ 断点续训：从最后一个有 ckpt 的 race 开始，
#    用该 race 自己的 ckpt 续训，后面的 race 从头训
# ============================================================

resume_train() {
  # $1=exp_name, $2=variant(v1|v3), $3=extra_args
  local exp="$1" var="$2" ext="$3"
  local races=(SA CA AS AF)
  local start_idx=-1

  # 找到最后一个有完好 ckpt (>20MB) 的 race
  for i in "${!races[@]}"; do
    local ckpt="$OUT/$exp/predict_p_${races[$i]}/checkpoints/best_model.pth"
    if [ -f "$ckpt" ] && [ $(stat -c%s "$ckpt" 2>/dev/null || echo 0) -gt 20000000 ]; then
      start_idx=$i
    fi
  done

  if [ $start_idx -lt 0 ]; then
    echo "=== $exp: no valid ckpt found, start from SA ==="
    start_idx=0
  else
    echo "=== $exp: last valid ckpt = ${races[$start_idx]}, resume from it ==="
  fi

  for ((i=start_idx; i<${#races[@]}; i++)); do
    local race="${races[$i]}"
    local ckpt="$OUT/$exp/predict_p_$race/checkpoints/best_model.pth"
    local resume_flag=""
    [ -f "$ckpt" ] && resume_flag="--resume $ckpt" && echo "  $race: resume from $ckpt" || echo "  $race: train from scratch"
    python predict_p/train.py \
      --model-variant "$var" \
      --race "$race" --multi-head --attributes all --nan-handling loss_mask \
      --data-root $DATA --gt-excel $GT \
      --output-root $OUT \
      --exp-name "$exp" --num-workers 4 --batch-size 16 \
      $resume_flag $ext
  done
}

# Full V3 (inst2): SA✅CA✅AS✅ AF❌ → 从 AS resume，训 AS→AF
resume_train "full_v3_loss_mask" "v3" "--rgb-backbone simple_cnn --global-backbone simple_cnn"

# Ablation 1 (inst3): SA✅CA✅AS✅ AF❌ → 从 AS resume，训 AS→AF
resume_train "ablation_face_only_loss_mask_v3" "v3" "--ablation-face-only --rgb-backbone simple_cnn --global-backbone simple_cnn"

# Ablation 2 (inst4): SA✅CA⚠️14MB 被判定无效 → 从 SA resume，训 SA→CA→AS→AF
resume_train "ablation_concat_loss_mask_v3" "v3" "--ablation-fusion-type concat --rgb-backbone simple_cnn --global-backbone simple_cnn"

# Ablation 3 (inst5): 全齐 → start_idx=3(AF) → 只跑 AF，resume 自己 → 验证后自动停
resume_train "ablation_resnet50_loss_mask_v3" "v3" "--rgb-backbone resnet50 --global-backbone simple_cnn"

# Full V1 (inst1): 全缺 → 从头训 SA
resume_train "full_v1_loss_mask" "v1" "--rgb-backbone simple_cnn --global-backbone simple_cnn"


# ============================================================
# ④ Phase 0 新增实验: backbone + fusion ablation (2026-07-06)
# ============================================================
# 新增 --rgb-backbone 可选值:
#   simple_cnn | resnet50 | efficientnet_b0 |
#   mobilenet_v3_small | mobilenet_v3_large |
#   vit_b_16 | swin_t | clip_vit_b32
#
# 新增 --ablation-fusion-type 可选值:
#   gated | concat | se_gated | cross_attn
#
# 新增 --freeze-backbone: ViT/Swin/CLIP 默认 freeze，也可显式指定
# 不加任何新参数 = 回退到原始 STIM-CNN V3 逻辑
# ============================================================
在A1-A8当中 我打算优先跑 A1、A7、A8 因为这是STIM-CNN与MS-CAN的差别所在。用来跑它们几个的实例分别是：




新的：
inst2：
inst3：指令ssh -p 25543 root@connect.westc.seetacloud.com密码aVNDqobDUhCx
inst4：指令ssh -p 43098 root@connect.weste.seetacloud.com密码C4lhu1bF80MH
inst5：指令ssh -p 32567 root@connect.westc.seetacloud.com密码cIVCU3dIzcLt



inst2 mobilenetv3s  
inst3 cross_attn    
inst4 stat_stream   
inst5 vitb16        
inst6 se_fusion  

# ===== 环境 =====
cd /root/autodl-tmp/deepskin
. /root/miniconda3/etc/profile.d/conda.sh
conda activate deepskin

# ===== 通用参数 =====
DATA=/root/autodl-tmp
GT=/root/autodl-tmp/gt/toMax_gt.xlsx
OUT=/root/autodl-tmp/deepskin/predict_p/output

# 
# -------- A1: MobileNetV3-Small face backbone --------
for RACE in SA CA AS AF; do
  CKPT="$OUT/ablation_mobilenetv3s_v3/predict_p_$RACE/checkpoints/best_model.pth"
  [ -f "$CKPT" ] && echo "SKIP $RACE: exists" && continue
  python predict_p/train.py \
    --model-variant v3 \
    --race $RACE --multi-head --attributes all --nan-handling loss_mask \
    --rgb-backbone mobilenet_v3_small --global-backbone simple_cnn \
    --data-root $DATA --gt-excel $GT \
    --output-root $OUT \
    --exp-name ablation_mobilenetv3s_v3 --num-workers 4 --batch-size 16
done

# -------- A2: MobileNetV3-Large face backbone --------
for RACE in SA CA AS AF; do
  CKPT="$OUT/ablation_mobilenetv3l_v3/predict_p_$RACE/checkpoints/best_model.pth"
  [ -f "$CKPT" ] && echo "SKIP $RACE: exists" && continue
  python predict_p/train.py \
    --model-variant v3 \
    --race $RACE --multi-head --attributes all --nan-handling loss_mask \
    --rgb-backbone mobilenet_v3_large --global-backbone simple_cnn \
    --data-root $DATA --gt-excel $GT \
    --output-root $OUT \
    --exp-name ablation_mobilenetv3l_v3 --num-workers 4 --batch-size 16
done

# -------- A3: ViT-B/16 face backbone (frozen, ViT/CLIP 需先 pip install timm open_clip_torch) --------
for RACE in SA CA AS AF; do
  CKPT="$OUT/ablation_vitb16_v3/predict_p_$RACE/checkpoints/best_model.pth"
  [ -f "$CKPT" ] && echo "SKIP $RACE: exists" && continue
  python predict_p/train.py \
    --model-variant v3 \
    --race $RACE --multi-head --attributes all --nan-handling loss_mask \
    --rgb-backbone vit_b_16 --global-backbone simple_cnn \
    --freeze-backbone \
    --data-root $DATA --gt-excel $GT \
    --output-root $OUT \
    --exp-name ablation_vitb16_v3 --num-workers 4 --batch-size 8
done

# -------- A4: Swin-T face backbone (frozen) --------
for RACE in SA CA AS AF; do
  CKPT="$OUT/ablation_swint_v3/predict_p_$RACE/checkpoints/best_model.pth"
  [ -f "$CKPT" ] && echo "SKIP $RACE: exists" && continue
  python predict_p/train.py \
    --model-variant v3 \
    --race $RACE --multi-head --attributes all --nan-handling loss_mask \
    --rgb-backbone swin_t --global-backbone simple_cnn \
    --freeze-backbone \
    --data-root $DATA --gt-excel $GT \
    --output-root $OUT \
    --exp-name ablation_swint_v3 --num-workers 4 --batch-size 8
done

# -------- A5: CLIP ViT-B/32 face backbone (frozen) --------
for RACE in SA CA AS AF; do
  CKPT="$OUT/ablation_clip_v3/predict_p_$RACE/checkpoints/best_model.pth"
  [ -f "$CKPT" ] && echo "SKIP $RACE: exists" && continue
  python predict_p/train.py \
    --model-variant v3 \
    --race $RACE --multi-head --attributes all --nan-handling loss_mask \
    --rgb-backbone clip_vit_b32 --global-backbone simple_cnn \
    --freeze-backbone \
    --data-root $DATA --gt-excel $GT \
    --output-root $OUT \
    --exp-name ablation_clip_v3 --num-workers 4 --batch-size 8
done

# -------- A6: SE-Gated fusion (simple_cnn backbone) --------
for RACE in SA CA AS AF; do
  CKPT="$OUT/ablation_se_fusion_v3/predict_p_$RACE/checkpoints/best_model.pth"
  [ -f "$CKPT" ] && echo "SKIP $RACE: exists" && continue
  python predict_p/train.py \
    --model-variant v3 \
    --race $RACE --multi-head --attributes all --nan-handling loss_mask \
    --ablation-fusion-type se_gated \
    --rgb-backbone simple_cnn --global-backbone simple_cnn \
    --data-root $DATA --gt-excel $GT \
    --output-root $OUT \
    --exp-name ablation_se_fusion_v3 --num-workers 4 --batch-size 16
done

# -------- A7: Cross-Attention fusion (simple_cnn backbone) --------
for RACE in SA CA AS AF; do
  CKPT="$OUT/ablation_cross_attn_v3/predict_p_$RACE/checkpoints/best_model.pth"
  [ -f "$CKPT" ] && echo "SKIP $RACE: exists" && continue
  python predict_p/train.py \
    --model-variant v3 \
    --race $RACE --multi-head --attributes all --nan-handling loss_mask \
    --ablation-fusion-type cross_attn \
    --rgb-backbone simple_cnn --global-backbone simple_cnn \
    --data-root $DATA --gt-excel $GT \
    --output-root $OUT \
    --exp-name ablation_cross_attn_v3 --num-workers 4 --batch-size 16
done

# -------- A8: Statistical Stream (+ scene/portrait metadata) --------
for RACE in SA CA AS AF; do
  CKPT="$OUT/ablation_stat_stream_v3/predict_p_$RACE/checkpoints/best_model.pth"
  [ -f "$CKPT" ] && echo "SKIP $RACE: exists" && continue
  python predict_p/train.py \
    --model-variant v3 \
    --race $RACE --multi-head --attributes all --nan-handling loss_mask \
    --ablation-stat-stream \
    --rgb-backbone simple_cnn --global-backbone simple_cnn \
    --data-root $DATA --gt-excel $GT \
    --output-root $OUT \
    --exp-name ablation_stat_stream_v3 --num-workers 4 --batch-size 16
done


# ============================================================
# A9~A11 新增消融 (2026-07-09)
# ============================================================
# A9: Lab色度中心回归（双输出：10-dim scores + 3-dim L*a*b* per attr）
# A10: MS-CMAN风格 Loss = BCE+SmoothL1+L1(center)+Pearson (无extreme weighting)
# A11: MS-CMAN backbone = ResNet50 face + MobileNetV3-S global
# ============================================================

# --- A9: Lab色度中心回归 ---
for RACE in SA CA AS AF; do
  CKPT="$OUT/ablation_lab_center_v3/predict_p_$RACE/checkpoints/best_model.pth"
  [ -f "$CKPT" ] && echo "SKIP $RACE: exists" && continue
  python predict_p/train.py --model-variant v3 \
    --race $RACE --multi-head --attributes all --nan-handling loss_mask \
    --ablation-lab-center \
    --rgb-backbone simple_cnn --global-backbone simple_cnn \
    --data-root $DATA --gt-excel $GT --output-root $OUT \
    --exp-name ablation_lab_center_v3 --num-workers 4 --batch-size 16
done

# --- A10: BCE+SmoothL1+L1(center)+Pearson ---
for RACE in SA CA AS AF; do
  CKPT="$OUT/ablation_bce_loss_v3/predict_p_$RACE/checkpoints/best_model.pth"
  [ -f "$CKPT" ] && echo "SKIP $RACE: exists" && continue
  python predict_p/train.py --model-variant v3 \
    --race $RACE --multi-head --attributes all --nan-handling loss_mask \
    --ablation-lab-center --ablation-loss-type bce_smooth_l1 \
    --rgb-backbone simple_cnn --global-backbone simple_cnn \
    --data-root $DATA --gt-excel $GT --output-root $OUT \
    --exp-name ablation_bce_loss_v3 --num-workers 4 --batch-size 16
done

# --- A11: MS-CMAN backbone (ResNet50 face + MobileNetV3-S global) ---
for RACE in SA CA AS AF; do
  CKPT="$OUT/ablation_mscman_backbone_v3/predict_p_$RACE/checkpoints/best_model.pth"
  [ -f "$CKPT" ] && echo "SKIP $RACE: exists" && continue
  python predict_p/train.py --model-variant v3 \
    --race $RACE --multi-head --attributes all --nan-handling loss_mask \
    --rgb-backbone resnet50 --global-backbone mobilenet_v3_small \
    --data-root $DATA --gt-excel $GT --output-root $OUT \
    --exp-name ablation_mscman_backbone_v3 --num-workers 4 --batch-size 16
done

# --- A12: true-cross-atten (token-level cross-attention fusion) ---
for RACE in SA CA AS AF; do
  CKPT="$OUT/ablation_true_cross_attn_v3/predict_p_$RACE/checkpoints/best_model.pth"
  [ -f "$CKPT" ] && echo "SKIP $RACE: exists" && continue
  python predict_p/train.py --model-variant v3 \
    --race $RACE --multi-head --attributes all --nan-handling loss_mask \
    --ablation-fusion-type true_cross_attn \
    --rgb-backbone simple_cnn --global-backbone simple_cnn \
    --data-root $DATA --gt-excel $GT --output-root $OUT \
    --exp-name ablation_true_cross_attn_v3 --num-workers 4 --batch-size 16
done









# ============================================================
# ③-bis Phase 0 断点续训（A1~A8）
# ============================================================
# 使用 resume_train() 函数（定义见上方③节158~192行）
# 每台实例复制对应那行，函数自带 SKIP + 同race自resume 逻辑
#
# 当前进度 (2026-07-07):
#   inst2: A1 4/4 DONE → 续跑 A2  |  inst3: A7 4/4 DONE → 续跑 A4
#   inst4: A8 3/4 缺AF → 补 AF    |  inst5: A3 4/4 DONE → 续跑 A5
#   inst6: A6 3/4 缺AF → 补 AF

# --- A1 MobileNetV3-Small (inst2原任务, 4/4 DONE, skip) ---
resume_train "ablation_mobilenetv3s_v3" "v3" "--rgb-backbone mobilenet_v3_small --global-backbone simple_cnn"

# --- A3 ViT-B/16 (inst5原任务, 4/4 DONE, skip) ---
resume_train "ablation_vitb16_v3" "v3" "--rgb-backbone vit_b_16 --global-backbone simple_cnn --freeze-backbone --batch-size 8"

# --- A7 Cross-Attention fusion (inst3原任务, 4/4 DONE, skip) ---
resume_train "ablation_cross_attn_v3" "v3" "--ablation-fusion-type cross_attn --rgb-backbone simple_cnn --global-backbone simple_cnn"

# --- inst2 (30844): A2 MobileNetV3-Large ---
resume_train "ablation_mobilenetv3l_v3" "v3" "--rgb-backbone mobilenet_v3_large --global-backbone simple_cnn"

# --- inst3 (22898): A4 Swin-T ---
resume_train "ablation_swint_v3" "v3" "--rgb-backbone swin_t --global-backbone simple_cnn --freeze-backbone --batch-size 8"

# --- inst4 (16056): A8 Statistical Stream (补AF) ---
resume_train "ablation_stat_stream_v3" "v3" "--ablation-stat-stream --rgb-backbone simple_cnn --global-backbone simple_cnn"

# --- inst5 (25650): A5 CLIP ViT-B/32 ---
resume_train "ablation_clip_v3" "v3" "--rgb-backbone clip_vit_b32 --global-backbone simple_cnn --freeze-backbone --batch-size 8"

# --- inst6 (30374): A6 SE-Gated fusion (补AF) ---
resume_train "ablation_se_fusion_v3" "v3" "--ablation-fusion-type se_gated --rgb-backbone simple_cnn --global-backbone simple_cnn"

# --- A9: Lab色度中心回归 ---
resume_train "ablation_lab_center_v3" "v3" "--ablation-lab-center --rgb-backbone simple_cnn --global-backbone simple_cnn"

# --- A10: BCE+SmoothL1+L1(center)+Pearson ---
resume_train "ablation_bce_loss_v3" "v3" "--ablation-lab-center --ablation-loss-type bce_smooth_l1 --rgb-backbone simple_cnn --global-backbone simple_cnn"

# --- A11: MS-CMAN backbone (ResNet50 face + MobileNetV3-S global) ---
resume_train "ablation_mscman_backbone_v3" "v3" "--rgb-backbone resnet50 --global-backbone mobilenet_v3_small"


# ===== 任务分配 =====
实例	主任务	状态
inst2	A1 MobileNetV3-S	✅ 4/4
inst3	A7 Cross-Attention	✅ 4/4
inst4	A8 Stat Stream	❌ 缺AF
inst5	A3 ViT-B/16	✅ 4/4
inst6	A6 SE-Gated	❌ 缺AF


# ===== 环境 =====
cd /root/autodl-tmp/deepskin
. /root/miniconda3/etc/profile.d/conda.sh
conda activate deepskin

# ===== 通用参数 =====
DATA=/root/autodl-tmp
GT=/root/autodl-tmp/gt/toMax_gt.xlsx
OUT=/root/autodl-tmp/deepskin/predict_p/output
# ============================================================
# ④-bis Phase 0 推理命令
# ============================================================

# A1 — MobileNetV3-S
for RACE in SA CA AS AF; do
  python predict_p/test_only.py --model-variant v3 \
    --rgb-backbone mobilenet_v3_small --global-backbone simple_cnn \
    --multi-head --attributes all\
    --data-root $DATA --gt-excel $GT --output-root $OUT --num-workers 4 \
    --exp-name ablation_mobilenetv3s_v3 --race $RACE \
    --resume $OUT/ablation_mobilenetv3s_v3/predict_p_$RACE/checkpoints/best_model.pth
done

# A2 — MobileNetV3-L
for RACE in SA CA AS AF; do
  python predict_p/test_only.py --model-variant v3 \
    --rgb-backbone mobilenet_v3_large --global-backbone simple_cnn \
    --multi-head --attributes all \
    --data-root $DATA --gt-excel $GT --output-root $OUT --num-workers 4 \
    --exp-name ablation_mobilenetv3l_v3 --race $RACE \
    --resume $OUT/ablation_mobilenetv3l_v3/predict_p_$RACE/checkpoints/best_model.pth
done

# A3 — ViT-B/16 (frozen)
for RACE in SA CA AS AF; do
  python predict_p/test_only.py --model-variant v3 \
    --rgb-backbone vit_b_16 --global-backbone simple_cnn --freeze-backbone \
    --multi-head --attributes all \
    --data-root $DATA --gt-excel $GT --output-root $OUT --num-workers 4 \
    --exp-name ablation_vitb16_v3 --race $RACE \
    --resume $OUT/ablation_vitb16_v3/predict_p_$RACE/checkpoints/best_model.pth
done

# A4 — Swin-T (frozen)
for RACE in SA CA AS AF; do
  python predict_p/test_only.py --model-variant v3 \
    --rgb-backbone swin_t --global-backbone simple_cnn --freeze-backbone \
    --multi-head --attributes all \
    --data-root $DATA --gt-excel $GT --output-root $OUT --num-workers 4 \
    --exp-name ablation_swint_v3 --race $RACE \
    --resume $OUT/ablation_swint_v3/predict_p_$RACE/checkpoints/best_model.pth
done

# A5 — CLIP ViT-B/32 (frozen)
for RACE in SA CA AS AF; do
  python predict_p/test_only.py --model-variant v3 \
    --rgb-backbone clip_vit_b32 --global-backbone simple_cnn --freeze-backbone \
    --multi-head --attributes all \
    --data-root $DATA --gt-excel $GT --output-root $OUT --num-workers 4 \
    --exp-name ablation_clip_v3 --race $RACE \
    --resume $OUT/ablation_clip_v3/predict_p_$RACE/checkpoints/best_model.pth
done

# A6 — SE-Gated fusion
for RACE in SA CA AS AF; do
  python predict_p/test_only.py --model-variant v3 \
    --ablation-fusion-type se_gated \
    --rgb-backbone simple_cnn --global-backbone simple_cnn \
    --multi-head --attributes all \
    --data-root $DATA --gt-excel $GT --output-root $OUT --num-workers 4 \
    --exp-name ablation_se_fusion_v3 --race $RACE \
    --resume $OUT/ablation_se_fusion_v3/predict_p_$RACE/checkpoints/best_model.pth
done

# A7 — Cross-Attention fusion
for RACE in SA CA AS AF; do
  python predict_p/test_only.py --model-variant v3 \
    --ablation-fusion-type cross_attn \
    --rgb-backbone simple_cnn --global-backbone simple_cnn \
    --multi-head --attributes all \
    --data-root $DATA --gt-excel $GT --output-root $OUT --num-workers 4 \
    --exp-name ablation_cross_attn_v3 --race $RACE \
    --resume $OUT/ablation_cross_attn_v3/predict_p_$RACE/checkpoints/best_model.pth
done

# A8 — Statistical Stream
for RACE in SA CA AS AF; do
  python predict_p/test_only.py --model-variant v3 \
    --ablation-stat-stream \
    --rgb-backbone simple_cnn --global-backbone simple_cnn \
    --multi-head --attributes all \
    --data-root $DATA --gt-excel $GT --output-root $OUT --num-workers 4 \
    --exp-name ablation_stat_stream_v3 --race $RACE \
    --resume $OUT/ablation_stat_stream_v3/predict_p_$RACE/checkpoints/best_model.pth
done

# A9 — Lab色度中心回归
for RACE in SA CA AS AF; do
  python predict_p/test_only.py --model-variant v3 \
    --ablation-lab-center \
    --rgb-backbone simple_cnn --global-backbone simple_cnn \
    --multi-head --attributes all \
    --data-root $DATA --gt-excel $GT --output-root $OUT --num-workers 4 \
    --exp-name ablation_lab_center_v3 --race $RACE \
    --resume $OUT/ablation_lab_center_v3/predict_p_$RACE/checkpoints/best_model.pth
done

# A10 — BCE+SmoothL1+L1(center)+Pearson
for RACE in SA CA AS AF; do
  python predict_p/test_only.py --model-variant v3 \
    --ablation-lab-center --ablation-loss-type bce_smooth_l1 \
    --rgb-backbone simple_cnn --global-backbone simple_cnn \
    --multi-head --attributes all \
    --data-root $DATA --gt-excel $GT --output-root $OUT --num-workers 4 \
    --exp-name ablation_bce_loss_v3 --race $RACE \
    --resume $OUT/ablation_bce_loss_v3/predict_p_$RACE/checkpoints/best_model.pth
done

# A11 — MS-CMAN backbone (ResNet50 face + MobileNetV3-S global)
for RACE in SA CA AS AF; do
  python predict_p/test_only.py --model-variant v3 \
    --rgb-backbone resnet50 --global-backbone mobilenet_v3_small \
    --multi-head --attributes all \
    --data-root $DATA --gt-excel $GT --output-root $OUT --num-workers 4 \
    --exp-name ablation_mscman_backbone_v3 --race $RACE \
    --resume $OUT/ablation_mscman_backbone_v3/predict_p_$RACE/checkpoints/best_model.pth
done



# 
============================================================
# 每台实例只需复制对应的一行
# ============================================================

# inst4 (stat_stream A8) — 缺 AF
resume_ablation "ablation_stat_stream_v3" "--ablation-stat-stream --rgb-backbone simple_cnn --global-backbone simple_cnn"

# inst6 (se_fusion A6) — 缺 AF
resume_ablation "ablation_se_fusion_v3" "--ablation-fusion-type se_gated --rgb-backbone simple_cnn --global-backbone simple_cnn"

# inst2 (A1 done, 空闲) — 跑 A2: MobileNetV3-Large  (SA已有, CA/AS/AF待补)
resume_ablation "ablation_mobilenetv3l_v3" "--rgb-backbone mobilenet_v3_large --global-backbone simple_cnn"

# inst3 (A7 done, 空闲) — 跑 A4: Swin-T (frozen, bs=8)
resume_ablation "ablation_swint_v3" "--rgb-backbone swin_t --global-backbone simple_cnn --freeze-backbone --batch-size 8"

# inst5 (A3 done, 空闲) — 跑 A5: CLIP ViT-B/32 (frozen, bs=8)
resume_ablation "ablation_clip_v3" "--rgb-backbone clip_vit_b32 --global-backbone simple_cnn --freeze-backbone --batch-size 8"

# ============================================================
# 操作步骤：
# 1. 复制 resume_ablation() 函数定义（上面那整段）+ 对应实例那一行
#    例如 inst4：复制函数定义 + "resume_ablation ablation_stat_stream_v3 ..."
# 2. 粘贴到该实例的终端
# 3. 回车执行，脚本会自动检测断点并续训
# 4. 想后台跑：nohup bash -c '...函数定义... resume_ablation ...' > train.log 2>&1 &
# ============================================================


# ============================================================
# 消融实验逻辑说明
# ============================================================
# 所有实验共用：
#   --model-variant v3  --multi-head --attributes all --nan-handling loss_mask
#   --data-root $DATA --gt-excel $GT --output-root $OUT --num-workers 4
#   训练 seed=666, AdamW lr=7e-4, CosineAnnealingWarmRestarts, early stop patience=100
#   subject-level split (test=male全场景, val=female固定2场景)
# ============================================================

# full_v3_loss_mask（主模型 baseline）
#   STIM-CNN 完整版：face 和 global 均使用 simple_cnn（4 层卷积，从头训练，约 30 万参数），
#   门控加权融合，10 个独立 MLP 输出头输出 10 维印象指数。
#   loss = BCE + SmoothL1 + 3.0×Pearson，带 extreme weighting 和 label smoothing。
#   所有消融实验均以此为基础，只改动单一组件。

# full_v1_loss_mask（UV 色度分支消融）
#   在 V3 纯 RGB 的基础上恢复 UV 色度直方图分支（face_uv 输入）。
#   V1 架构：face_rgb + face_uv（CIELUV 2D 直方图 → 小型 CNN 编码）+ global_rgb。
#   验证 UV 分支是否提供额外的色度分布信息。论文消融组 2。

# sing_model（单头消融）
#   10 个独立 MLP 输出头 → 1 个共享 MLP 输出头。
#   训练时只使用 01Preference 属性，验证多任务学习（10 属性联合优化）
#   是否为共享特征提取器注入了额外的监督信号。论文消融组 1。

# ablation_face_only_loss_mask_v3（移除全局分支消融）
#   --ablation-face-only：global stream 的输出被置零，不参与融合。
#   只使用 face_rgb 输入做预测。验证全局场景上下文（照明、背景等）
#   对肤色印象判断是否必要。论文消融组 3。

# ablation_concat_loss_mask_v3（简单融合消融）
#   --ablation-fusion-type concat：门控加权融合 → 直接 concat + MLP 投影。
#   验证门控机制（自适应学习 face/global 融合比例）是否优于固定拼接。
#   论文消融组 4（对应原版 concat 融合基线）。

# ablation_resnet50_loss_mask_v3（大 backbone 消融）
#   --rgb-backbone resnet50：face backbone 从 simple_cnn → ResNet50（ImageNet 预训练）。
#   参数量从 30 万增至约 2500 万。验证在当前数据规模下增大模型容量
#   是否带来表征能力的提升，还是反而过拟合。论文消融组 4（对应 ResNet50 变体）。

# ablation_mobilenetv3s_v3（现代轻量 CNN 消融）
#   --rgb-backbone mobilenet_v3_small：face backbone 从 simple_cnn → MobileNetV3-Small（预训练）。
#   验证工业级轻量 CNN（含 SE 模块、hard-swish 等现代设计）是否优于
#   手写的 4 层简单 CNN。

# ablation_se_fusion_v3（SE-Gated 融合消融）
#   --ablation-fusion-type se_gated：在门控融合之前对两分支特征做 SE channel recalibration。
#   验证通道注意力加权是否能进一步优化门控融合的特征质量。

# ablation_cross_attn_v3（Cross-Attention 融合消融）
#   --ablation-fusion-type cross_attn：门控加权融合 → 双向 Cross-Attention。
#   face features 和 global features 互相作为 query/key/value 做信息交换。
#   验证注意力机制是否优于显式的门控竞争策略。

# ablation_stat_stream_v3（统计特征流消融）
#   --ablation-stat-stream：在融合后的 256-D 特征基础上拼接 11-D 统计特征
#   （scene_type(4) + CCT + illuminance + ethnicity(4) + gender，从 original_name 解析），
#   再经 MLP 投影回 256-D。验证显式注入场景/人种/性别先验是否有补充作用。

# ablation_vitb16_v3（Transformer backbone 消融）
#   --rgb-backbone vit_b_16 --freeze-backbone --batch-size 8：
#   face backbone 从 simple_cnn → 冻结的 ViT-B/16（ImageNet-21k 预训练，86M 参数）。
#   仅训练 fusion + head 层。验证 Transformer 架构的全局自注意力机制
#   是否适配以局部纹理为核心的肤色评估任务。

# ablation_lab_center_v3（A9: Lab 色度中心回归）
#   --ablation-lab-center：在 10 个 score head 之外新增 10 个 center head，
#   每个输出 3 维 L*a*b* 色度中心。center loss = L1 loss，λ=1.5，
#   预测值和 GT 均除以 K=128 做归一化。(50,0,0) 的 GT 占位符视为 NaN，
#   通过 center_mask 排除出 loss 计算。验证双任务（评分 + 色度回归）联合训练
#   是否提升偏好预测精度。

# ablation_bce_loss_v3（A10: MS-CMAN 风格 Loss）
#   与 A9 架构完全相同（--ablation-lab-center），区别仅在于 Pearson λ 从 3.0 → 0.7，
#   对齐 MS-CMAN 论文的 λ₃=0.7。其余 loss 组件（BCE+SmoothL1+extreme weighting
#   +label smoothing+center L1 λ=1.5）与 A9 一致。验证 Pearson 权重
#   对多任务训练平衡性的影响。

# ablation_mscman_backbone_v3（A11: MS-CMAN Backbone）
#   --rgb-backbone resnet50 --global-backbone mobilenet_v3_small：
#   使用 MS-CMAN 论文的异构 backbone 配置（face=ResNet50 预训练 + global=MobileNetV3-Small 预训练）。
#   保持 STIM-CNN 的门控融合和 10 head 输出不变。验证异构 backbone
#   设计是否优于 STIM-CNN 的同构简单 CNN。注：不含 MS-CMAN 的统计流和 Cross-Attention 融合，
#   非完整复现。
