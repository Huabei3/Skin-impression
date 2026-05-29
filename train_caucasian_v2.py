#!/usr/bin/env python3
"""
Caucasian training script for toMax dataset - Version 2
Training: f01i, f01r, f03i, f03r, m01i, m01r (complete data)
Validation: f02i
Testing: f02r
"""
import sys
import os
sys.path.insert(0, '/root/autodl-tmp/deepskin')

import torch
from pathlib import Path
from facial_preference.config import Config
from facial_preference.data import FacialPreferenceDataset, get_data_transforms
from torch.utils.data import DataLoader
from facial_preference.train import Trainer

# Update config for Caucasian training
Config.MODEL_NAME = 'caucasian_tomax_v2'
Config.TRAIN_SCENES = ['f01i', 'f01r', 'f03i', 'f03r', 'm01i', 'm01r']
Config.VAL_SCENES = ['f02i']
Config.TEST_SCENES = ['f02r']

# Create custom data loaders with separate scene lists
def create_caucasian_data_loaders():
    face_rgb_root = Config.FACE_RGB_ROOT
    face_uv_root = Config.FACE_UV_ROOT
    gt_excel_path = Config.GT_EXCEL_PATH
    global_rgb_root = Config.GLOBAL_RGB_ROOT
    
    train_transform = get_data_transforms(Config.get_config_dict(), 'train')
    val_transform = get_data_transforms(Config.get_config_dict(), 'val')
    test_transform = get_data_transforms(Config.get_config_dict(), 'test')
    
    # Training dataset with training scenes
    train_dataset = FacialPreferenceDataset(
        face_rgb_root=face_rgb_root,
        face_uv_root=face_uv_root,
        gt_excel_path=gt_excel_path,
        split='train',
        transform=train_transform,
        seed=Config.RANDOM_SEED,
        train_ratio=0.85,  # Use more data for training
        val_ratio=0.10,
        test_ratio=0.05,
        allowed_ids=None,
        global_rgb_root=global_rgb_root,
        split_strategy='stable_by_id_hash',
        load_uv=True,
        uv_is_hist=False,
        uv_log_ratio=False,
        allowed_scenes=Config.TRAIN_SCENES,
    )
    
    # Validation dataset with validation scenes
    val_dataset = FacialPreferenceDataset(
        face_rgb_root=face_rgb_root,
        face_uv_root=face_uv_root,
        gt_excel_path=gt_excel_path,
        split='val',
        transform=val_transform,
        seed=Config.RANDOM_SEED,
        train_ratio=0.85,
        val_ratio=0.10,
        test_ratio=0.05,
        allowed_ids=None,
        global_rgb_root=global_rgb_root,
        split_strategy='stable_by_id_hash',
        load_uv=True,
        uv_is_hist=False,
        uv_log_ratio=False,
        allowed_scenes=Config.VAL_SCENES,
    )
    
    # Test dataset with test scenes
    test_dataset = FacialPreferenceDataset(
        face_rgb_root=face_rgb_root,
        face_uv_root=face_uv_root,
        gt_excel_path=gt_excel_path,
        split='test',
        transform=test_transform,
        seed=Config.RANDOM_SEED,
        train_ratio=0.85,
        val_ratio=0.10,
        test_ratio=0.05,
        allowed_ids=None,
        global_rgb_root=global_rgb_root,
        split_strategy='stable_by_id_hash',
        load_uv=True,
        uv_is_hist=False,
        uv_log_ratio=False,
        allowed_scenes=Config.TEST_SCENES,
    )
    
    batch_size = Config.TRAINING['batch_size']
    
    train_loader = DataLoader(
        train_dataset,
        batch_size=batch_size,
        shuffle=True,
        num_workers=0,
        pin_memory=True,
        drop_last=True
    )
    
    val_loader = DataLoader(
        val_dataset,
        batch_size=batch_size,
        shuffle=False,
        num_workers=0,
        pin_memory=True
    )
    
    test_loader = DataLoader(
        test_dataset,
        batch_size=batch_size,
        shuffle=False,
        num_workers=0,
        pin_memory=True
    )
    
    return train_loader, val_loader, test_loader

if __name__ == '__main__':
    print('=' * 60)
    print('Caucasian Training for toMax Dataset - V2')
    print('=' * 60)
    print(f'Training scenes: {Config.TRAIN_SCENES}')
    print(f'Validation scenes: {Config.VAL_SCENES}')
    print(f'Test scenes: {Config.TEST_SCENES}')
    print('=' * 60)
    
    # Get config dict
    config_dict = Config.get_config_dict()
    
    # Create custom trainer with modified data loaders
    print('Creating data loaders...')
    train_loader, val_loader, test_loader = create_caucasian_data_loaders()
    
    print(f'Train samples: {len(train_loader.dataset)}')
    print(f'Val samples: {len(val_loader.dataset)}')
    print(f'Test samples: {len(test_loader.dataset)}')
    
    # Create trainer
    trainer = Trainer(config_dict)
    
    # Replace data loaders
    trainer.train_loader = train_loader
    trainer.val_loader = val_loader
    trainer.test_loader = test_loader
    
    # Start training
    print('Starting training...')
    trainer.train()
