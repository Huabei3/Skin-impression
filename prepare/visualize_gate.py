"""可视化 full_v3 的 gate 权重（face vs global 贡献比）。
运行: python visualize_gate.py --exp-name full_v3_loss_mask --race SA
"""
import argparse, os, sys, torch, numpy as np
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from predict_p.config import Config
from predict_p.test_only import parse_args as test_parse_args

# Monkey-patch fusion 的 forward 来收集 gate weights
gate_weights_list = []

def patched_forward(self, face, global_feat):
    f = self.face_proj(face)
    g = self.global_proj(global_feat)
    w = self.gate(torch.cat([f, g], dim=1))
    gate_weights_list.append(w.detach().cpu().numpy())  # 收集 (B, 2)
    fused = w[:, 0:1] * f + w[:, 1:2] * g
    return self.out(fused)

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--exp-name", required=True)
    parser.add_argument("--race", required=True)
    parser.add_argument("--output", default="./gate_analysis")
    args, _ = parser.parse_known_args()

    config = Config.get_config_dict()
    config["OUTPUT_ROOT"] = str(Path(config["OUTPUT_ROOT"]) / args.exp_name)

    from predict_p.models.network import create_model
    from predict_p.data.dataset import create_data_loaders
    from predict_p.trainer import Trainer
    from predict_p.models.fusion import TwoStreamFusion

    # 替换 forward
    TwoStreamFusion.forward = patched_forward

    trainer = Trainer(config)
    ckpt = torch.load(config["OUTPUT_ROOT"] / f"predict_p_{args.race}/checkpoints/best_model.pth", map_location="cpu")
    trainer.model.load_state_dict(ckpt["model_state_dict"], strict=True)
    trainer.model.eval().cuda()

    # 只在 test set 上跑
    _, _, test_loader = create_data_loaders(config)
    with torch.no_grad():
        for batch in test_loader:
            img = batch["rgb"].cuda()
            trainer.model(img)

    weights = np.concatenate(gate_weights_list, axis=0)  # (N_test, 2)
    w_face = weights[:, 0]
    w_global = weights[:, 1]

    print(f"Gate stats ({len(w_face)} samples):")
    print(f"  w_face   : mean={w_face.mean():.4f}, std={w_face.std():.4f}, min={w_face.min():.4f}, max={w_face.max():.4f}")
    print(f"  w_global : mean={w_global.mean():.4f}, std={w_global.std():.4f}, min={w_global.min():.4f}, max={w_global.max():.4f}")
    print(f"  face_dominant (w_face>0.5): {np.mean(w_face > 0.5) * 100:.1f}%")
    print(f"  face_dominant (w_face>0.7): {np.mean(w_face > 0.7) * 100:.1f}%")
    print(f"  face_dominant (w_face>0.9): {np.mean(w_face > 0.9) * 100:.1f}%")

    os.makedirs(args.output, exist_ok=True)
    np.savez(f"{args.output}/gate_weights_{args.exp_name}_{args.race}.npz",
             w_face=w_face, w_global=w_global)
    print(f"Saved to {args.output}/gate_weights_{args.exp_name}_{args.race}.npz")

if __name__ == "__main__":
    main()
