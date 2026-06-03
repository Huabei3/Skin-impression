"""检查模型加载与推理 —— 最小复现"""
import sys
sys.path.insert(0, ".")

import torch
from pathlib import Path
from predict_p.config import Config
from predict_p.trainer import Trainer
from predict_p.train import _apply_model_variant_overrides, _apply_race_overrides

# 模拟 test_only.py 的配置流程
config = Config.get_config_dict()

# 设置数据路径
dr = Path("/root/autodl-tmp")
config["FACE_RGB_ROOT"] = str(dr / "rendered_face")
config["FACE_UV_ROOT"] = str(dr / "rendered_face_uv")
config["GLOBAL_RGB_ROOT"] = str(dr / "rendered_2max")
config["GT_EXCEL_PATH"] = str(dr / "gt" / "toMax_gt.xlsx")
config["OUTPUT_ROOT"] = "/root/autodl-tmp/deepskin/predict_p/output"

# v3 + simple_cnn
config["MODEL_VARIANT"] = "v3"
config["MODEL"]["face_stream"]["rgb_backbone"] = "simple_cnn"
config["MODEL"]["face_stream"]["rgb_pretrained"] = False
config["MODEL"]["global_stream"]["backbone"] = "simple_cnn"
config["MODEL"]["global_stream"]["pretrained"] = False

_apply_model_variant_overrides(config)
_apply_race_overrides(config, "SA")

print("=== Config after overrides ===")
print(f"MODEL_VARIANT: {config.get('MODEL_VARIANT')}")
print(f"SPLIT_STRATEGY: {config.get('SPLIT_STRATEGY')}")
print(f"TEST_PREFIXES count: {len(config.get('TEST_PREFIXES', []))}")
print(f"TRAIN_IDS: {config.get('TRAIN_IDS')}")
print(f"TEST_IDS: {config.get('TEST_IDS')}")
print(f"CHECKPOINT_DIR: {config.get('CHECKPOINT_DIR')}")
print(f"RESULT_DIR: {config.get('RESULT_DIR')}")

# 创建 Trainer
trainer = Trainer(config)
print(f"\nTest samples: {len(trainer.test_loader.dataset)}")

# 加载权重
ckpt_path = "/root/autodl-tmp/deepskin/predict_p/output/v3_cnn_pt/best_model_5_SA"
ckpt = torch.load(ckpt_path, map_location=trainer.device)
print(f"\nCheckpoint keys: {list(ckpt.keys())}")
print(f"Checkpoint epoch: {ckpt.get('epoch')}")

sd = ckpt["model_state_dict"]
model_sd = trainer.model.state_dict()

# 检查 key 匹配
ckpt_keys = set(sd.keys())
model_keys = set(model_sd.keys())
print(f"\nCheckpoint params: {len(ckpt_keys)}")
print(f"Model params: {len(model_keys)}")
print(f"Only in ckpt: {ckpt_keys - model_keys}")
print(f"Only in model: {model_keys - ckpt_keys}")
print(f"Common: {len(ckpt_keys & model_keys)}")

# 检查 shape 匹配
mismatch = []
for k in ckpt_keys & model_keys:
    if sd[k].shape != model_sd[k].shape:
        mismatch.append((k, sd[k].shape, model_sd[k].shape))
if mismatch:
    print(f"\nSHAPE MISMATCH ({len(mismatch)}):")
    for k, cs, ms in mismatch[:10]:
        print(f"  {k}: ckpt={cs} model={ms}")
else:
    print("\nAll shapes match!")

# 尝试加载
try:
    trainer.model.load_state_dict(sd, strict=True)
    print("\nload_state_dict: SUCCESS (strict=True)")
except Exception as e:
    print(f"\nload_state_dict strict=True FAILED: {e}")
    # 尝试 strict=False
    missing, unexpected = trainer.model.load_state_dict(sd, strict=False)
    print(f"  missing keys: {missing}")
    print(f"  unexpected keys: {unexpected}")
