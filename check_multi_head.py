"""快速验证 multi-head 模型创建是否正常。"""
import sys
sys.path.insert(0, '.')

from predict_p.models.network import create_model
from predict_p.config import Config

config = Config.get_config_dict()
config["MODEL_VARIANT"] = "v3"
config["MODEL"]["face_stream"]["rgb_backbone"] = "simple_cnn"
config["MODEL"]["global_stream"]["backbone"] = "simple_cnn"

# 1. 单头
m1 = create_model(config, model_variant="v3")
print(f"Single-head output dim: {m1.output_dim}")
print(f"  is_multi_head: {m1.is_multi_head}")

# 2. 多头
config["MULTI_HEAD"] = True
config["ATTRIBUTE_HEAD_NAMES"] = ["01Preference", "02Attractiveness", "03Feminine"]
m2 = create_model(config, model_variant="v3")
print(f"Multi-head output dim: {m2.output_dim}")
print(f"  is_multi_head: {m2.is_multi_head}")
print(f"  attribute_names: {m2.attribute_names}")

# 3. 测试 forward
import torch
x_rgb = torch.randn(2, 3, 224, 224)
x_global = torch.randn(2, 3, 224, 224)

out1 = m1(x_rgb, None, x_global)
print(f"Single-head forward shape: {out1.shape}")

out2 = m2(x_rgb, None, x_global)
print(f"Multi-head forward shape: {out2.shape}")

# 4. 测试 forward_single_head
fused = m2.fusion(m2.face_stream(x_rgb), m2.global_stream(x_global))
single_out = m2.forward_single_head(fused, "01Preference")
print(f"forward_single_head shape: {single_out.shape}")

print("\nAll checks passed!")
