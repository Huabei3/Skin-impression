"""Phase 0 验证脚本 — 在云实例上运行"""
import sys
sys.path.insert(0, '/root/autodl-tmp/deepskin')

# 1) backbones
from predict_p.models.backbones import (
    create_backbone, MobileNetV3Backbone, ViTBackbone,
    SwinTBackbone, CLIPBackbone, SimpleCNNBackbone,
)
for name in ("simple_cnn", "mobilenet_v3_small", "mobilenet_v3_large",
             "vit_b_16", "swin_t", "clip_vit_b32"):
    try:
        bb = create_backbone(name, pretrained=True, feature_dim=256, freeze=False)
        n_trainable = sum(p.numel() for p in bb.parameters() if p.requires_grad)
        n_total = sum(p.numel() for p in bb.parameters())
        print(f"  [OK] create_backbone({name!r}) -> {type(bb).__name__}, "
              f"out_dim={bb.out_dim}, trainable={n_trainable:,}, total={n_total:,}")
    except Exception as e:
        print(f"  [SKIP] {name}: {e}")

# 2) fusion
from predict_p.models.fusion import create_fusion, TwoStreamFusion, SEGatedFusion, CrossAttentionFusion
for ft in ("gated", "concat", "se_gated", "cross_attn"):
    try:
        f = create_fusion(ft, face_dim=256, global_dim=256, fusion_dim=256)
        print(f"  [OK] create_fusion({ft!r}) -> {type(f).__name__}")
    except Exception as e:
        print(f"  [FAIL] {ft}: {e}")

# 3) model creation
from predict_p.models.network import create_model
from predict_p.config import Config
cfg = Config.get_config_dict()
cfg["MODEL_VARIANT"] = "v3"
cfg["MODEL"]["face_stream"]["rgb_backbone"] = "mobilenet_v3_small"
cfg["MODEL"]["face_stream"]["freeze_backbone"] = False

try:
    model = create_model(cfg, model_type="full", use_attention=True, model_variant="v3")
    print(f"  [OK] create_model(v3+mobilenet_v3_small) -> {type(model).__name__}")
    n_params = sum(p.numel() for p in model.parameters())
    print(f"       Total params: {n_params:,}")
except Exception as e:
    print(f"  [FAIL] mobilenet_v3_small model: {e}")

# 4) config auto-freeze
cfg2 = Config.get_config_dict()
cfg2["MODEL_VARIANT"] = "v3"
cfg2["MODEL"]["face_stream"]["rgb_backbone"] = "simple_cnn"
try:
    # 不带 freeze_backbone 默认应正常工作
    from predict_p.models.face_stream import FaceStreamV3, RGBBranch
    bb = RGBBranch(backbone="simple_cnn", pretrained=False, feature_dim=256, freeze_backbone=False)
    print(f"  [OK] RGBBranch(simple_cnn, no_freeze) -> out_dim={bb.feature_dim}")
except Exception as e:
    print(f"  [FAIL] RGBBranch simple_cnn: {e}")

print("\n=== VERIFICATION COMPLETE ===")

# --- extra: verify freeze works on ViT ---
print("\n=== Freeze Test ===")
try:
    bb_frozen = create_backbone("vit_b_16", pretrained=False, feature_dim=256, freeze=True)
    n_trainable = sum(p.numel() for p in bb_frozen.parameters() if p.requires_grad)
    n_total = sum(p.numel() for p in bb_frozen.parameters())
    print(f"  [OK] ViT frozen: trainable={n_trainable:,}, total={n_total:,}")
except Exception as e:
    print(f"  [SKIP] ViT freeze test: {e}")
