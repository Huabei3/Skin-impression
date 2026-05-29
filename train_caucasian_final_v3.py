#!/usr/bin/env python3
import sys
sys.path.insert(0, '/root/autodl-tmp/deepskin')

import torch
from pathlib import Path
from facial_preference.config import Config
from facial_preference.data import FacialPreferenceDataset, get_data_transforms
from torch.utils.data import DataLoader
from facial_preference.train import Trainer

Config.MODEL_NAME = 'caucasian_final_v3'
Config.TRAIN_SCENES = ['f01i', 'f01r', 'f03i', 'f03r', 'm01i', 'm01r', 'm03i', 'm03r']
Config.VAL_SCENES = ['m02i', 'm02r']
Config.TEST_SCENES = ['f02i', 'f02r']

def create_caucasian_data_loaders():
    face_rgb_root = Config.FACE_RGB_ROOT
    face_uv_root = Config.FACE_UV_ROOT
    gt_excel_path = Config.GT_EXCEL_PATH
    global_rgb_root = Config.GLOBAL_RGB_ROOT
    
    train_transform = get_data_transforms(Config.get_config_dict(), 'train')
    val_transform = get_data_transforms(Config.get_config_dict(), 'val')
    test_transform = get_data_transforms(Config.get_config_dict(), 'test')
    
    train_dataset = FacialPreferenceDataset(
        face_rgb_root=face_rgb_root, face_uv_root=face_uv_root, gt_excel_path=gt_excel_path,
        split='train', transform=train_transform, seed=Config.RANDOM_SEED,
        train_ratio=1.0, val_ratio=0.0, test_ratio=0.0, allowed_ids=None,
        global_rgb_root=global_rgb_root, split_strategy='stable_by_id_hash',
        load_uv=True, uv_is_hist=False, uv_log_ratio=False, allowed_scenes=Config.TRAIN_SCENES,
    )
    
    val_dataset = FacialPreferenceDataset(
        face_rgb_root=face_rgb_root, face_uv_root=face_uv_root, gt_excel_path=gt_excel_path,
        split='train', transform=val_transform, seed=Config.RANDOM_SEED,
        train_ratio=1.0, val_ratio=0.0, test_ratio=0.0, allowed_ids=None,
        global_rgb_root=global_rgb_root, split_strategy='stable_by_id_hash',
        load_uv=True, uv_is_hist=False, uv_log_ratio=False, allowed_scenes=Config.VAL_SCENES,
    )
    
    test_dataset = FacialPreferenceDataset(
        face_rgb_root=face_rgb_root, face_uv_root=face_uv_root, gt_excel_path=gt_excel_path,
        split='train', transform=test_transform, seed=Config.RANDOM_SEED,
        train_ratio=1.0, val_ratio=0.0, test_ratio=0.0, allowed_ids=None,
        global_rgb_root=global_rgb_root, split_strategy='stable_by_id_hash',
        load_uv=True, uv_is_hist=False, uv_log_ratio=False, allowed_scenes=Config.TEST_SCENES,
    )
    
    batch_size = Config.TRAINING['batch_size']
    
    train_loader = DataLoader(train_dataset, batch_size=batch_size, shuffle=True, num_workers=0, pin_memory=True, drop_last=True)
    val_loader = DataLoader(val_dataset, batch_size=batch_size, shuffle=False, num_workers=0, pin_memory=True)
    test_loader = DataLoader(test_dataset, batch_size=batch_size, shuffle=False, num_workers=0, pin_memory=True)
    
    return train_loader, val_loader, test_loader

if __name__ == '__main__':
    print('=' * 60)
    print('Caucasian Training - With Checkpoint Saving')
    print('=' * 60)
    print(f'Training scenes: {Config.TRAIN_SCENES}')
    print(f'Validation scenes: {Config.VAL_SCENES}')
    print(f'Test scenes: {Config.TEST_SCENES}')
    print('=' * 60)
    
    config_dict = Config.get_config_dict()
    
    print('Creating data loaders...')
    train_loader, val_loader, test_loader = create_caucasian_data_loaders()
    
    print(f'Train samples: {len(train_loader.dataset)}')
    print(f'Val samples: {len(val_loader.dataset)}')
    print(f'Test samples: {len(test_loader.dataset)}')
    
    trainer = Trainer(config_dict)
    trainer.train_loader = train_loader
    trainer.val_loader = val_loader
    trainer.test_loader = test_loader
    
    checkpoint_dir = Path(trainer.config['CHECKPOINT_DIR'])
    checkpoint_dir.mkdir(parents=True, exist_ok=True)
    
    checkpoints = sorted(checkpoint_dir.glob('checkpoint_epoch_*.pth'))
    if checkpoints:
        latest_checkpoint = checkpoints[-1]
        print(f'Loading checkpoint: {latest_checkpoint}')
        try:
            checkpoint = torch.load(latest_checkpoint, map_location=trainer.device)
            trainer.model.load_state_dict(checkpoint['model_state_dict'])
            trainer.optimizer.load_state_dict(checkpoint['optimizer_state_dict'])
            trainer.current_epoch = checkpoint['epoch']
            trainer.best_val_loss = checkpoint.get('best_val_loss', float('inf'))
            print(f'Resumed from epoch {trainer.current_epoch}')
        except Exception as e:
            print(f'Failed to load checkpoint: {e}')
    
    print('Starting training...')
    trainer.train()
    
    print('Saving final checkpoint...')
    checkpoint = {
        'epoch': trainer.current_epoch,
        'model_state_dict': trainer.model.state_dict(),
        'optimizer_state_dict': trainer.optimizer.state_dict(),
        'best_val_loss': trainer.best_val_loss,
    }
    torch.save(checkpoint, checkpoint_dir / f'checkpoint_epoch_{trainer.current_epoch}.pth')
    print('Training completed!')
