"""检查权重文件是否正常"""
import torch, sys

path = sys.argv[1] if len(sys.argv) > 1 else "predict_p/output/v3_cnn_pt/SA_best_model.pth"
ckpt = torch.load(path, map_location="cpu")
print("Keys:", list(ckpt.keys()))

if "model_state_dict" in ckpt:
    sd = ckpt["model_state_dict"]
    print("Num params:", len(sd))
    first_key = list(sd.keys())[0]
    last_key = list(sd.keys())[-1]
    print(f"First ({first_key}): min={sd[first_key].min().item():.6f} max={sd[first_key].max().item():.6f} mean={sd[first_key].mean().item():.6f}")
    print(f"Last  ({last_key}): min={sd[last_key].min().item():.6f} max={sd[last_key].max().item():.6f} mean={sd[last_key].mean().item():.6f}")

    # 检查是否所有值都相同（退化信号）
    for k, v in sd.items():
        if v.numel() > 1 and v.min() == v.max():
            print(f"WARNING: {k} is constant! min=max={v.min().item():.6f}")
else:
    print("No model_state_dict found!")
