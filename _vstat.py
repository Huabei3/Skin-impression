import torch
from predict_p.models.stat_stream import StatisticalStream, extract_metadata

# Test 1: extract_metadata
f1 = extract_metadata("f07ih3k_01")
f2 = extract_metadata("m05rrs03_15")
print(f"stat f07ih3k_01: shape={tuple(f1.shape)}, sum={f1.sum().item():.1f}, vals={[round(v,2) for v in f1.tolist()]}")
print(f"stat m05rrs03_15: shape={tuple(f2.shape)}, sum={f2.sum().item():.1f}, vals={[round(v,2) for v in f2.tolist()]}")

# Test 2: StatisticalStream forward
s = StatisticalStream()
x = torch.randn(2, 11)
out = s(x)
print(f"StatStream in={tuple(x.shape)} out={tuple(out.shape)}")

# Test 3: Full model with stat
from predict_p.models.network import create_model
from predict_p.config import Config
c = Config.get_config_dict()
c["MODEL_VARIANT"] = "v3"
c["ABLATION_STAT_STREAM"] = True
c["MULTI_HEAD"] = True
c["ATTRIBUTE_HEAD_NAMES"] = ["01Preference"]
m = create_model(c, model_variant="v3")
x = torch.randn(4, 3, 224, 224)
sf = torch.randn(4, 11)
out = m(x, None, x, stat_features=sf)
print(f"Model forward: {tuple(out.shape)}, params={sum(p.numel() for p in m.parameters()):,}")

# Test 4: Backward compat - without stat stream flag, stat_features should not break
c2 = Config.get_config_dict()
c2["MODEL_VARIANT"] = "v3"
c2["MULTI_HEAD"] = True
c2["ATTRIBUTE_HEAD_NAMES"] = ["01Preference"]
m2 = create_model(c2, model_variant="v3")
out2 = m2(x, None, x, stat_features=None)
print(f"Backward compat (no stat): {tuple(out2.shape)}, params={sum(p.numel() for p in m2.parameters()):,}")
out3 = m2(x, None, x)  # no stat_features keyword
print(f"Backward compat (no kwarg): {tuple(out3.shape)}")

print("\nALL PASSED")
