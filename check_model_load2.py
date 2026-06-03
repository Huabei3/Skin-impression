"""检查加载权重后模型的实际输出"""
import sys
sys.path.insert(0, ".")

import torch
from pathlib import Path
from predict_p.config import Config
from predict_p.trainer import Trainer
from predict_p.train import _apply_model_variant_overrides, _apply_race_overrides

config = Config.get_config_dict()

dr = Path("/root/autodl-tmp")
config["FACE_RGB_ROOT"] = str(dr / "rendered_face")
config["FACE_UV_ROOT"] = str(dr / "rendered_face_uv")
config["GLOBAL_RGB_ROOT"] = str(dr / "rendered_2max")
config["GT_EXCEL_PATH"] = str(dr / "gt" / "toMax_gt.xlsx")
config["OUTPUT_ROOT"] = "/root/autodl-tmp/deepskin/predict_p/output"

config["MODEL_VARIANT"] = "v3"
config["MODEL"]["face_stream"]["rgb_backbone"] = "simple_cnn"
config["MODEL"]["face_stream"]["rgb_pretrained"] = False
config["MODEL"]["global_stream"]["backbone"] = "simple_cnn"
config["MODEL"]["global_stream"]["pretrained"] = False

_apply_model_variant_overrides(config)
_apply_race_overrides(config, "SA")

trainer = Trainer(config)

# 未加载权重前
trainer.model.eval()
batch = next(iter(trainer.test_loader))
face_rgb = batch["face_rgb"].to(trainer.device)
global_rgb = batch.get("global_rgb", face_rgb).to(trainer.device)

with torch.no_grad():
    logits_before = trainer.model(face_rgb, None, global_rgb)
    preds_before = torch.sigmoid(logits_before)

print("=== BEFORE loading weights ===")
print(f"Logits: min={logits_before.min().item():.4f} max={logits_before.max().item():.4f} mean={logits_before.mean().item():.4f}")
print(f"Preds:  min={preds_before.min().item():.4f} max={preds_before.max().item():.4f} mean={preds_before.mean().item():.4f}")

# 加载权重
ckpt_path = "/root/autodl-tmp/deepskin/predict_p/output/v3_cnn_pt/best_model_5_SA"
ckpt = torch.load(ckpt_path, map_location=trainer.device)
trainer.model.load_state_dict(ckpt["model_state_dict"], strict=True)

trainer.model.eval()
with torch.no_grad():
    logits_after = trainer.model(face_rgb, None, global_rgb)
    preds_after = torch.sigmoid(logits_after)

print("\n=== AFTER loading weights ===")
print(f"Logits: min={logits_after.min().item():.4f} max={logits_after.max().item():.4f} mean={logits_after.mean().item():.4f}")
print(f"Preds:  min={preds_after.min().item():.4f} max={preds_after.max().item():.4f} mean={preds_after.mean().item():.4f}")

# 检查输入数据的范围
print(f"\n=== Input data ===")
print(f"face_rgb shape: {face_rgb.shape}, min={face_rgb.min().item():.4f}, max={face_rgb.max().item():.4f}, mean={face_rgb.mean().item():.4f}")
print(f"global_rgb shape: {global_rgb.shape}, min={global_rgb.min().item():.4f}, max={global_rgb.max().item():.4f}, mean={global_rgb.mean().item():.4f}")
