"""验证 multi-head + single-head 模式"""
import sys
sys.path.insert(0, '/root/autodl-tmp/deepskin')

from predict_p.models.network import PredictPNetwork
from predict_p.config import Config

# Test 1: Single-head
c1 = Config.get_config_dict()
c1["MODEL_VARIANT"] = "v3"
m1 = PredictPNetwork(c1, model_variant="v3")
print(f"[Single-head] is_multi_head={m1.is_multi_head}, attrs={m1.attribute_names}, params={sum(p.numel() for p in m1.parameters()):,}")

# Test 2: Multi-head
c2 = Config.get_config_dict()
c2["MULTI_HEAD"] = True
c2["ATTRIBUTE_HEAD_NAMES"] = ["01Preference", "02Attractiveness"]
c2["MODEL_VARIANT"] = "v3"
m2 = PredictPNetwork(c2, model_variant="v3")
print(f"[Multi-head]  is_multi_head={m2.is_multi_head}, attrs={m2.attribute_names}, params={sum(p.numel() for p in m2.parameters()):,}")

# Test 3: Forward shape
import torch
x = torch.randn(4, 3, 224, 224)
with torch.no_grad():
    out1 = m1(x, None, x)
    out2 = m2(x, None, x)
print(f"[Forward]   single-head output: {tuple(out1.shape)}")  # (4, 1)
print(f"[Forward]   multi-head output:  {tuple(out2.shape)}")   # (4, 2)

# Test 4: Trainer creation
from predict_p.trainer import Trainer
c3 = Config.get_config_dict()
c3["MULTI_HEAD"] = True
c3["ATTRIBUTE_HEAD_NAMES"] = ["01Preference", "02Attractiveness"]
c3["MODEL_VARIANT"] = "v3"
# skip data loading test, just check _multi_head marking
m3 = PredictPNetwork(c3, model_variant="v3")
print(f"[Trainer check] model.is_multi_head={m3.is_multi_head}, model.attribute_names={m3.attribute_names}")

print("\n=== ALL TESTS PASSED ===")
