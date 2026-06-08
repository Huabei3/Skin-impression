"""可视化 full_v3 gate 权重。用法: python viz_gate.py AS"""
import torch, numpy as np, sys, os
sys.path.insert(0, '/root/autodl-tmp/deepskin')

from predict_p.config import Config
from predict_p.models.fusion import TwoStreamFusion
from predict_p.data.dataset import create_data_loaders
from predict_p.trainer import Trainer

race = sys.argv[1] if len(sys.argv) > 1 else 'AS'
exp = 'full_v3_loss_mask'
config = Config.get_config_dict()
config['OUTPUT_ROOT'] = '/root/autodl-tmp/deepskin/predict_p/output/' + exp
config['GT_EXCEL_PATH'] = '/root/autodl-tmp/gt/toMax_gt.xlsx'
config['FACE_RGB_ROOT'] = '/root/autodl-tmp/rendered_face'
config['FACE_UV_ROOT'] = '/root/autodl-tmp/rendered_face_uv'
config['GLOBAL_RGB_ROOT'] = '/root/autodl-tmp/rendered_2max'
config['RACE'] = race
config['MODEL_VARIANT'] = 'v3'
config['MULTI_HEAD'] = True
config['ATTRIBUTES'] = 'all'

# Monkey-patch forward to collect gate weights
gate_weights_list = []
_orig = TwoStreamFusion.forward

def patched(self, face, g):
    f = self.face_proj(face)
    g2 = self.global_proj(g)
    w = self.gate(torch.cat([f, g2], dim=1))
    gate_weights_list.append(w.detach().cpu().numpy())
    fused = w[:, 0:1] * f + w[:, 1:2] * g2
    return self.out(fused)

TwoStreamFusion.forward = patched

# Build trainer and load checkpoint
trainer = Trainer(config)
output_root = config['OUTPUT_ROOT']
ckpt_path = os.path.join(output_root, f'predict_p_{race}', 'checkpoints', 'best_model.pth')
ckpt = torch.load(ckpt_path, map_location='cpu')
trainer.model.load_state_dict(ckpt['model_state_dict'], strict=False)
trainer.model.eval().cuda()

# Run inference on test set
_, _, test_loader = create_data_loaders(config)
with torch.no_grad():
    for batch in test_loader:
        trainer.model(batch['face_rgb'].cuda())

# Analyze
w = np.concatenate(gate_weights_list, axis=0)
wf, wg = w[:, 0], w[:, 1]

print(f'Samples: {len(wf)}')
print(f'w_face   : mean={wf.mean():.4f}  std={wf.std():.4f}  min={wf.min():.4f}  max={wf.max():.4f}')
print(f'w_global : mean={wg.mean():.4f}  std={wg.std():.4f}  min={wg.min():.4f}  max={wg.max():.4f}')
for thr in [0.5, 0.7, 0.9, 0.95]:
    pct = np.mean(wf > thr) * 100
    print(f'  w_face > {thr:.2f}: {pct:.1f}%')

# Save
out_path = f'/root/autodl-tmp/deepskin/prepare/gate_{exp}_{race}.npz'
np.savez(out_path, w_face=wf, w_global=wg)
print(f'Saved to {out_path}')

TwoStreamFusion.forward = _orig
