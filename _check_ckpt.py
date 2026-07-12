
import sys, os, glob
sys.path.insert(0, '/root/autodl-tmp/deepskin')
import torch
import json

checkpoint_dir = '/root/autodl-tmp/deepskin/predict_p/output/full_v3_loss_mask'
for race_dir in sorted(glob.glob(f'{checkpoint_dir}/predict_p_*')):
    race = os.path.basename(race_dir).replace('predict_p_', '')
    ckpt_path = os.path.join(race_dir, 'checkpoints', 'best_model.pth')
    
    # Check for training log/metrics
    info_files = glob.glob(f'{race_dir}/**/info.txt', recursive=True) + \
                 glob.glob(f'{race_dir}/**/*metrics*.json', recursive=True) + \
                 glob.glob(f'{race_dir}/**/*log*.txt', recursive=True) + \
                 glob.glob(f'{race_dir}/**/best*.json', recursive=True)
    
    print(f"\n{race}:")
    if os.path.exists(ckpt_path):
        try:
            ckpt = torch.load(ckpt_path, map_location='cpu')
            print(f"  Checkpoint keys: {list(ckpt.keys())[:10]}")
            if 'epoch' in ckpt:
                print(f"  Epoch at best: {ckpt['epoch']}")
            if 'best_val_loss' in ckpt:
                print(f"  Best val loss: {ckpt['best_val_loss']:.6f}")
            if 'best_epoch' in ckpt:
                print(f"  Best epoch: {ckpt['best_epoch']}")
            # Check for training info
            for k in ckpt:
                if 'epoch' in str(k).lower() or 'best' in str(k).lower() or 'info' in str(k).lower() or 'iter' in str(k).lower():
                    print(f"  {k}: {ckpt[k]}")
        except Exception as e:
            print(f"  Error loading checkpoint: {e}")
    else:
        print(f"  No checkpoint at {ckpt_path}")
    
    # Print info files
    print(f"  Info files found: {info_files}")
    for f_path in info_files:
        try:
            with open(f_path) as ff:
                content = ff.read()[:500]
            print(f"  {f_path}: {content}")
        except:
            pass
    
    # Also check for training logs
    log_files = glob.glob(f'{race_dir}/**/*.log', recursive=True) + \
                glob.glob(f'{race_dir}/**/*.txt', recursive=True)
    for lf in log_files:
        if lf not in info_files:
            try:
                with open(lf) as ff:
                    content = ff.read()[:500]
                print(f"  {lf}: {content}")
            except:
                pass

print("\nDone.")
