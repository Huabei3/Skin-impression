"""
训练脚本 - 训练人脸颜色喜好度预测网络
"""
import os
import sys
import torch
import torch.nn as nn
import torch.optim as optim
from torch.utils.data import DataLoader, WeightedRandomSampler
from torch.cuda.amp import GradScaler, autocast
from torch.utils.tensorboard import SummaryWriter
import numpy as np
from tqdm import tqdm
import logging
from datetime import datetime
from pathlib import Path
from typing import Dict, Tuple, Optional
import json

# 兼容作为脚本运行与包导入的双路径导入
try:
    from config import Config
    from data import create_data_loaders, FacialPreferenceDataset
    from models import (
        create_model,
        MultiTaskLoss,
        SimpleLoss,
        PrimaryLoss,
        freeze_backbone,
        unfreeze_layers,
        count_parameters
    )
    from models.simple_loss import SimpleRegressionLoss
    from utils.metrics import evaluate_model
except ModuleNotFoundError:
    from .config import Config
    from .data import create_data_loaders, FacialPreferenceDataset
    from .models import (
        create_model,
        MultiTaskLoss,
        SimpleLoss,
        PrimaryLoss,
        freeze_backbone,
        unfreeze_layers,
        count_parameters
    )
    from .models.simple_loss import SimpleRegressionLoss
    from .utils.metrics import evaluate_model

# 兼容运行方式差异：将包内模块注册为顶层别名，避免内部局部导入失败
try:
    import config as _cfg_alias  # noqa: F401
except ModuleNotFoundError:
    try:
        import facial_preference.config as _cfg_alias
        sys.modules['config'] = _cfg_alias
    except Exception:
        pass


# 设置日志
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


class Trainer:  
    """训练器类"""
    
    def __init__(self, config: Dict):
        """
        初始化训练器
        
        Args:
            config: 配置字典
        """
        self.config = config
        
        # 基于所选编号生成运行标签，并将输出/检查点/日志/结果目录挂到此标签下
        try:
            train_ids_norm = FacialPreferenceDataset._normalize_ids(self.config.get('TRAIN_IDS'))
            test_ids_norm = FacialPreferenceDataset._normalize_ids(self.config.get('TEST_IDS'))
            def _tag(ids):
                return 'all' if ids is None else '-'.join(ids)
            run_tag = f"ids_train_{_tag(train_ids_norm)}__test_{_tag(test_ids_norm)}"
            base_output = Path(self.config['OUTPUT_DIR'])
            # 覆盖目录到带标签的子目录
            self.config['CHECKPOINT_DIR'] = str(base_output / 'checkpoints' / run_tag)
            self.config['LOG_DIR'] = str(base_output / 'logs' / run_tag)
            self.config['RESULT_DIR'] = str(base_output / 'results' / run_tag)
        except Exception:
            # 回退到原有目录结构
            pass
        self.device = torch.device(config['DEVICE'] if torch.cuda.is_available() else 'cpu')
        
        # 创建输出目录
        self.setup_directories()
        
        # 初始化数据加载器
        logger.info("Loading datasets...")
        # 需要使用Config的字典格式
        from config import Config
        config_dict = Config.get_config_dict()
        self.train_loader, self.val_loader, self.test_loader = create_data_loaders(config_dict)
        logger.info(f"Train samples: {len(self.train_loader.dataset)}")
        logger.info(f"Val samples: {len(self.val_loader.dataset)}")
        logger.info(f"Test samples: {len(self.test_loader.dataset)}")

        # 启用加权采样以强调极端区间（0-0.1 与 0.9-1）
        try:
            tr_cfg = self.config.get('TRAINING', {})
            sampler_mode = tr_cfg.get('sampler', 'weighted')
            if sampler_mode == 'weighted':
                bins = tr_cfg.get('extreme_bins', [[0.0, 0.1], [0.9, 1.0]])
                extreme_w = float(tr_cfg.get('extreme_sample_weight', 3.0))
                ds = self.train_loader.dataset
                weights = []
                if hasattr(ds, 'data_items'):
                    for item in ds.data_items:
                        s = float(item.get('preference_score', 0.5))
                        s_norm = s / 10.0 if s > 1.5 else s
                        in_extreme = any((s_norm >= b[0] and s_norm <= b[1]) for b in bins)
                        weights.append(extreme_w if in_extreme else 1.0)
                    sampler = WeightedRandomSampler(weights=weights, num_samples=len(weights), replacement=True)
                    self.train_loader = DataLoader(
                        ds,
                        batch_size=self.config['TRAINING']['batch_size'],
                        shuffle=False,
                        sampler=sampler,
                        num_workers=0,
                        pin_memory=True,
                        drop_last=True
                    )
                    logger.info("Enabled weighted sampler for extreme score ranges")
        except Exception as e:
            logger.warning(f"Weighted sampler init failed, fallback to default. Err: {e}")
        
        # 初始化模型
        logger.info("Initializing model...")
        self.model = create_model(config, model_type='full', use_attention=True)
        self.model = self.model.to(self.device)
        logger.info(f"Model parameters: {count_parameters(self.model):,}")
        
        # 初始化损失函数 - 使用简化版本
        self.criterion = PrimaryLoss(config)
        logger.info("Using PrimaryLoss (BCEWithLogits + extreme weighting + L1 center)")
        
        # 初始化优化器
        self.setup_optimizer()
        
        # 初始化学习率调度器
        self.setup_scheduler()
        
        # 混合精度训练
        self.scaler = GradScaler() if config['TRAINING']['mixed_precision'] else None
        
        # TensorBoard
        if config['LOGGING']['tensorboard']:
            self.writer = SummaryWriter(log_dir=self.config['LOG_DIR'])
        else:
            self.writer = None
        
        # 训练状态
        self.current_epoch = 0
        self.best_val_loss = float('inf')
        self.patience_counter = 0
        # 初始化为0，确保第一轮调用 update_training_stage() 时执行冻结
        self.training_stage = 0
    
    def setup_directories(self):
        """创建必要的目录"""
        dirs = [
            self.config['OUTPUT_DIR'],
            self.config['CHECKPOINT_DIR'],
            self.config['LOG_DIR'],
            self.config['RESULT_DIR']
        ]
        for dir_path in dirs:
            Path(dir_path).mkdir(parents=True, exist_ok=True)
    
    def setup_optimizer(self):
        """设置优化器"""
        train_config = self.config['TRAINING']
        
        if train_config['optimizer'] == 'AdamW':
            self.optimizer = optim.AdamW(
                self.model.parameters(),
                lr=train_config['learning_rate'],
                weight_decay=train_config['weight_decay']
            )
        elif train_config['optimizer'] == 'Adam':
            self.optimizer = optim.Adam(
                self.model.parameters(),
                lr=train_config['learning_rate'],
                weight_decay=train_config['weight_decay']
            )
        else:
            raise ValueError(f"Unknown optimizer: {train_config['optimizer']}")
    
    def setup_scheduler(self):
        """设置学习率调度器"""
        train_config = self.config['TRAINING']
        
        if train_config['scheduler'] == 'CosineAnnealingWarmRestarts':
            self.scheduler = optim.lr_scheduler.CosineAnnealingWarmRestarts(
                self.optimizer,
                T_0=train_config['T_0'],
                T_mult=2,
                eta_min=train_config['min_lr']
            )
        elif train_config['scheduler'] == 'StepLR':
            self.scheduler = optim.lr_scheduler.StepLR(
                self.optimizer,
                step_size=10,
                gamma=0.1
            )
        else:
            self.scheduler = None
    
    def update_training_stage(self):
        """更新训练阶段"""
        train_config = self.config['TRAINING']
        
        if self.current_epoch < train_config['stage1_epochs']:
            # 阶段1：冻结骨干网络
            if self.training_stage != 1:
                logger.info("Stage 1: Freezing backbone")
                freeze_backbone(self.model, freeze=True)
                self.training_stage = 1
        
        elif self.current_epoch < train_config['stage1_epochs'] + train_config['stage2_epochs']:
            # 阶段2：解冻最后2层
            if self.training_stage != 2:
                logger.info("Stage 2: Unfreezing last 2 layers")
                freeze_backbone(self.model, freeze=True)
                unfreeze_layers(self.model, num_layers=2)
                self.training_stage = 2
                # 降低学习率到原来的1/10，避免梯度爆炸
                for param_group in self.optimizer.param_groups:
                    param_group['lr'] = train_config['learning_rate'] * 0.1
                logger.info(f"Reduced learning rate to {self.optimizer.param_groups[0]['lr']:.6f}")
        
        else:
            # 阶段3：全模型微调
            if self.training_stage != 3:
                logger.info("Stage 3: Full model fine-tuning")
                freeze_backbone(self.model, freeze=False)
                self.training_stage = 3
                # 进一步降低学习率
                for param_group in self.optimizer.param_groups:
                    param_group['lr'] = train_config['learning_rate'] * 0.01
                logger.info(f"Reduced learning rate to {self.optimizer.param_groups[0]['lr']:.6f}")
    
    def train_epoch(self) -> Dict[str, float]:
        """
        训练一个epoch
        
        Returns:
            训练指标字典
        """
        self.model.train()
        
        total_loss = 0
        score_loss_sum = 0
        center_loss_sum = 0
        num_batches = 0
        
        progress_bar = tqdm(self.train_loader, desc=f"Epoch {self.current_epoch}")
        
        for batch_idx, batch in enumerate(progress_bar):
            # 移动数据到设备
            face_rgb = batch['face_rgb'].to(self.device)
            face_uv = batch['face_uv'].to(self.device)
            # 全局流当前直接复用人脸图像（与原实现保持数值行为一致）
            global_rgb = batch.get('global_rgb', face_rgb).to(self.device)
            preference_score = batch['preference_score'].to(self.device)
            preference_center = batch['preference_center'].to(self.device)
            
            # 数据预处理和调试信息（仅在第一个epoch的前几个batch）
            if self.current_epoch == 0 and batch_idx < 3:
                logger.info(f"\nBatch {batch_idx} data stats:")
                logger.info(f"  Score range: [{preference_score.min():.2f}, {preference_score.max():.2f}]")
                logger.info(f"  Center range: [{preference_center.min():.2f}, {preference_center.max():.2f}]")
            
            # 清零梯度
            self.optimizer.zero_grad()
            
            # 混合精度训练
            if self.scaler:
                with autocast():
                    # 前向传播
                    pred_score, pred_center = self.model(face_rgb, face_uv, global_rgb)
                    # 清理网络输出中的非有限值，防止loss/梯度出现NaN
                    pred_score = torch.nan_to_num(pred_score, nan=0.0, posinf=1e6, neginf=-1e6)
                    pred_center = torch.nan_to_num(pred_center, nan=0.0, posinf=127.0, neginf=-128.0)
                    
                    # 调试信息（评分展示为概率范围）
                    if self.current_epoch == 0 and batch_idx < 3:
                        _pred_prob = torch.sigmoid(pred_score)
                        logger.info(f"  Pred score prob range: [{_pred_prob.min():.3f}, {_pred_prob.max():.3f}]")
                        logger.info(f"  Pred center range: [{pred_center.min():.2f}, {pred_center.max():.2f}]")
                    
                    # 计算损失
                    loss, loss_dict = self.criterion(
                        pred_score, pred_center,
                        preference_score, preference_center,
                        face_uv=face_uv, epoch=self.current_epoch
                    )
                
                # 反向传播
                self.scaler.scale(loss).backward()
                
                # 梯度裁剪
                self.scaler.unscale_(self.optimizer)
                torch.nn.utils.clip_grad_norm_(
                    self.model.parameters(), 
                    self.config['TRAINING']['gradient_clip']
                )
                
                # 优化器步骤
                self.scaler.step(self.optimizer)
                self.scaler.update()
            else:
                # 标准训练
                pred_score, pred_center = self.model(face_rgb, face_uv, global_rgb)
                # 清理网络输出中的非有限值
                pred_score = torch.nan_to_num(pred_score, nan=0.0, posinf=1e6, neginf=-1e6)
                pred_center = torch.nan_to_num(pred_center, nan=0.0, posinf=127.0, neginf=-128.0)
                
                # 检查NaN值
                if torch.isnan(pred_score).any() or torch.isnan(pred_center).any():
                    logger.warning(f"NaN detected in predictions at batch {batch_idx}, epoch {self.current_epoch}")
                    logger.warning(f"  Pred score has NaN: {torch.isnan(pred_score).any()}")
                    logger.warning(f"  Pred center has NaN: {torch.isnan(pred_center).any()}")
                    # 跳过这个batch
                    continue
                
                # 调试信息（评分展示为概率范围）
                if self.current_epoch == 0 and batch_idx < 3:
                    _pred_prob = torch.sigmoid(pred_score)
                    logger.info(f"  Pred score prob range: [{_pred_prob.min():.3f}, {_pred_prob.max():.3f}]")
                    logger.info(f"  Pred center range: [{pred_center.min():.2f}, {pred_center.max():.2f}]")
                
                loss, loss_dict = self.criterion(
                    pred_score, pred_center,
                    preference_score, preference_center,
                    face_uv=face_uv, epoch=self.current_epoch
                )
                
                # 检查loss是否为NaN
                if torch.isnan(loss):
                    logger.warning(f"NaN loss detected at batch {batch_idx}, epoch {self.current_epoch}")
                    continue
                
                loss.backward()
                
                # 梯度裁剪前检查梯度
                total_norm = 0
                for p in self.model.parameters():
                    if p.grad is not None:
                        param_norm = p.grad.data.norm(2)
                        total_norm += param_norm.item() ** 2
                total_norm = total_norm ** 0.5
                
                if total_norm > 100:  # 如果梯度太大，记录警告
                    logger.warning(f"Large gradient norm: {total_norm:.2f} at batch {batch_idx}, epoch {self.current_epoch}")
                
                torch.nn.utils.clip_grad_norm_(
                    self.model.parameters(),
                    self.config['TRAINING']['gradient_clip']
                )
                self.optimizer.step()
            
            # 累积损失
            total_loss += loss.item()
            score_loss_sum += loss_dict['score']
            center_loss_sum += loss_dict['center']
            num_batches += 1
            
            # 更新进度条
            progress_bar.set_postfix({
                'loss': f'{loss.item():.4f}',
                'score': f'{loss_dict["score"]:.4f}',
                'center': f'{loss_dict["center"]:.4f}'
            })
            
            # 记录到TensorBoard
            if self.writer and batch_idx % 10 == 0:
                global_step = self.current_epoch * len(self.train_loader) + batch_idx
                self.writer.add_scalar('Train/Loss', loss.item(), global_step)
                self.writer.add_scalar('Train/ScoreLoss', loss_dict['score'], global_step)
                self.writer.add_scalar('Train/CenterLoss', loss_dict['center'], global_step)
        
        # 计算平均损失（空集保护）
        if num_batches == 0:
            logger.warning("No batches in training epoch. Check dataset/sampler configuration.")
            metrics = {
                'train_loss': float('inf'),
                'train_score_loss': float('inf'),
                'train_center_loss': float('inf')
            }
        else:
            metrics = {
                'train_loss': total_loss / num_batches,
                'train_score_loss': score_loss_sum / num_batches,
                'train_center_loss': center_loss_sum / num_batches
            }
        
        return metrics
    
    def validate(self) -> Dict[str, float]:
        """
        验证模型
        
        Returns:
            验证指标字典
        """
        self.model.eval()
        
        total_loss = 0
        score_loss_sum = 0
        center_loss_sum = 0
        num_batches = 0
        
        all_pred_scores = []
        all_target_scores = []
        all_pred_centers = []
        all_target_centers = []
        
        with torch.no_grad():
            for batch in tqdm(self.val_loader, desc="Validation"):
                # 移动数据到设备
                face_rgb = batch['face_rgb'].to(self.device)
                face_uv = batch['face_uv'].to(self.device)
                # 全局流当前直接复用人脸图像（与原实现保持数值行为一致）
                global_rgb = batch.get('global_rgb', face_rgb).to(self.device)
                preference_score = batch['preference_score'].to(self.device)
                preference_center = batch['preference_center'].to(self.device)
                
                # 前向传播
                pred_score, pred_center = self.model(face_rgb, face_uv, global_rgb)
                # 清理网络输出中的非有限值
                pred_score = torch.nan_to_num(pred_score, nan=0.0, posinf=1e6, neginf=-1e6)
                pred_center = torch.nan_to_num(pred_center, nan=0.0, posinf=127.0, neginf=-128.0)
                
                # 计算损失
                loss, loss_dict = self.criterion(
                    pred_score, pred_center,
                    preference_score, preference_center,
                    face_uv=face_uv, epoch=self.current_epoch
                )
                # 非有限loss保护
                if not torch.isfinite(loss):
                    logger.warning("Validation: non-finite loss (NaN/Inf) encountered; skipping this batch")
                    continue
                
                # 累积损失
                total_loss += loss.item()
                score_loss_sum += loss_dict['score']
                center_loss_sum += loss_dict['center']
                num_batches += 1
                
                # 收集预测结果
                all_pred_scores.append(torch.sigmoid(pred_score).cpu())
                all_target_scores.append(preference_score.cpu())
                all_pred_centers.append(pred_center.cpu())
                all_target_centers.append(preference_center.cpu())
        
        # 空集保护：无batch或无预测时直接返回默认指标
        if num_batches == 0 or len(all_pred_scores) == 0:
            logger.warning("Validation produced no batches; returning default metrics.")
            return {
                'val_loss': float('inf'),
                'val_score_loss': float('inf'),
                'val_center_loss': float('inf'),
                'mae_score': float('nan'),
                'rmse_score': float('nan'),
                'r2': float('nan'),
                'pearson': float('nan'),
                'pearson_p': float('nan'),
                'spearman': float('nan'),
                'spearman_p': float('nan'),
                'delta_e_mean': float('nan'),
                'delta_e_std': float('nan'),
                'delta_e_median': float('nan'),
                'delta_e_90': float('nan'),
                'euclidean_mean': float('nan'),
                'angle_error_mean': float('nan'),
                'val_pref_mean': float('nan'),
                'val_pref_mean_pred': float('nan'),
            }
        
        # 合并所有预测
        all_pred_scores = torch.cat(all_pred_scores)
        all_target_scores = torch.cat(all_target_scores)
        all_pred_centers = torch.cat(all_pred_centers)
        all_target_centers = torch.cat(all_target_centers)

        # 计算喜好度（score）的均值：GT与预测
        val_pref_mean = float(all_target_scores.mean().item())
        val_pref_mean_pred = float(all_pred_scores.mean().item())

        # 计算评估指标
        eval_metrics = evaluate_model(
            all_pred_scores.numpy(),
            all_target_scores.numpy(),
            all_pred_centers.numpy(),
            all_target_centers.numpy()
        )
        
        # 添加损失指标
        metrics = {
            'val_loss': total_loss / num_batches,
            'val_score_loss': score_loss_sum / num_batches,
            'val_center_loss': center_loss_sum / num_batches,
            'val_pref_mean': val_pref_mean,
            'val_pref_mean_pred': val_pref_mean_pred,
            **eval_metrics
        }
        
        return metrics
    
    def train(self):
        """完整的训练流程"""
        logger.info("Starting training...")
        
        for epoch in range(self.config['TRAINING']['num_epochs']):
            self.current_epoch = epoch
            
            # 更新训练阶段
            self.update_training_stage()
            
            # 训练一个epoch
            logger.info(f"\n{'='*50}")
            logger.info(f"Epoch {epoch + 1}/{self.config['TRAINING']['num_epochs']}")
            logger.info(f"Learning rate: {self.optimizer.param_groups[0]['lr']:.6f}")
            
            train_metrics = self.train_epoch()
            
            # 验证
            val_metrics = self.validate()
            
            # 更新学习率 - 但在阶段转换时不使用scheduler
            if self.scheduler and self.training_stage == 1:
                self.scheduler.step()
            
            # 打印指标
            logger.info(f"Train Loss: {train_metrics['train_loss']:.4f}")
            logger.info(f"Val Loss: {val_metrics['val_loss']:.4f}")
            logger.info(f"Val MAE (score): {val_metrics['mae_score']:.4f}")
            logger.info(f"Val Pref Mean: {val_metrics['val_pref_mean']:.4f}")
            logger.info(f"Val Pearson: {val_metrics['pearson']:.4f}")
            logger.info(f"Val Delta E: {val_metrics['delta_e_mean']:.4f}")

            # 记录到TensorBoard
            if self.writer:
                self.writer.add_scalars('Loss', {
                    'train': train_metrics['train_loss'],
                    'val': val_metrics['val_loss']
                }, epoch)
                
                self.writer.add_scalar('Metrics/MAE', val_metrics['mae_score'], epoch)
                self.writer.add_scalar('Metrics/Pearson', val_metrics['pearson'], epoch)
                self.writer.add_scalar('Metrics/DeltaE', val_metrics['delta_e_mean'], epoch)
            
            # 保存最佳模型
            if val_metrics['val_loss'] < self.best_val_loss:
                self.best_val_loss = val_metrics['val_loss']
                self.patience_counter = 0
                
                # 保存检查点
                checkpoint = {
                    'epoch': epoch,
                    'model_state_dict': self.model.state_dict(),
                    'optimizer_state_dict': self.optimizer.state_dict(),
                    'scheduler_state_dict': self.scheduler.state_dict() if self.scheduler else None,
                    'best_val_loss': self.best_val_loss,
                    'config': self.config,
                    'metrics': val_metrics
                }
                
                checkpoint_path = Path(self.config['CHECKPOINT_DIR']) / 'best_model.pth'
                torch.save(checkpoint, checkpoint_path)
                logger.info(f"Saved best model to {checkpoint_path}")
                
                # 保存指标
                metrics_path = Path(self.config['RESULT_DIR']) / 'best_metrics.json'
                with open(metrics_path, 'w') as f:
                    json.dump(val_metrics, f, indent=4)
            else:
                self.patience_counter += 1
            
            # 早停
            if self.patience_counter >= self.config['TRAINING']['early_stopping_patience']:
                logger.info(f"Early stopping triggered after {epoch + 1} epochs")
                break
            
            # 定期保存检查点
            interval = self.config['TRAINING'].get('checkpoint_interval', 100)
            if interval and (epoch + 1) % interval == 0:
                checkpoint_path = Path(self.config['CHECKPOINT_DIR']) / f'checkpoint_epoch_{epoch+1}.pth'
                checkpoint = {
                    'epoch': epoch,
                    'model_state_dict': self.model.state_dict(),
                    'optimizer_state_dict': self.optimizer.state_dict(),
                    'scheduler_state_dict': self.scheduler.state_dict() if self.scheduler else None,
                    'val_loss': val_metrics['val_loss'],
                    'config': self.config
                }
                torch.save(checkpoint, checkpoint_path)
        
        # 训练结束
        logger.info("\nTraining completed!")
        logger.info(f"Best validation loss: {self.best_val_loss:.4f}")
        
        # 关闭TensorBoard
        if self.writer:
            self.writer.close()
    
    def test(self):
        """测试模型"""
        logger.info("\nTesting model on test set...")
        
        # 加载最佳模型
        checkpoint_path = Path(self.config['CHECKPOINT_DIR']) / 'best_model.pth'
        if checkpoint_path.exists():
            checkpoint = torch.load(checkpoint_path, map_location=self.device)
            self.model.load_state_dict(checkpoint['model_state_dict'])
            logger.info(f"Loaded best model from epoch {checkpoint['epoch'] + 1}")
        
        # 测试
        self.model.eval()
        test_metrics = self.validate()  # 使用相同的验证函数
        
        # 保存测试结果
        test_results_path = Path(self.config['RESULT_DIR']) / 'test_results.json'
        with open(test_results_path, 'w') as f:
            json.dump(test_metrics, f, indent=4)
        
        # 打印测试结果
        logger.info("\nTest Results:")
        logger.info(f"Test Loss: {test_metrics['val_loss']:.4f}")
        logger.info(f"MAE (score): {test_metrics['mae_score']:.4f}")
        logger.info(f"RMSE (score): {test_metrics['rmse_score']:.4f}")
        logger.info(f"Pearson: {test_metrics['pearson']:.4f}")
        logger.info(f"Spearman: {test_metrics['spearman']:.4f}")
        logger.info(f"R²: {test_metrics['r2']:.4f}")
        logger.info(f"Delta E (mean): {test_metrics['delta_e_mean']:.4f}")
        logger.info(f"Delta E (90%): {test_metrics['delta_e_90']:.4f}")
        # 同时print到控制台
        print("\n=== Test Results ===")
        print(f"Test Loss: {test_metrics['val_loss']:.4f}")
        print(f"MAE (score): {test_metrics['mae_score']:.4f}")
        print(f"RMSE (score): {test_metrics['rmse_score']:.4f}")
        print(f"Pearson: {test_metrics['pearson']:.4f}")
        print(f"Spearman: {test_metrics['spearman']:.4f}")
        print(f"R²: {test_metrics['r2']:.4f}")
        print(f"Delta E (mean): {test_metrics['delta_e_mean']:.4f}")
        print(f"Delta E (90%): {test_metrics['delta_e_90']:.4f}")
        return test_metrics


def main():
    """主函数"""
    # 加载配置
    config = Config.get_config_dict()
    
    # 设置随机种子
    torch.manual_seed(config['RANDOM_SEED'])
    np.random.seed(config['RANDOM_SEED'])
    if torch.cuda.is_available():
        torch.cuda.manual_seed(config['RANDOM_SEED'])
    
    # 创建训练器
    trainer = Trainer(config)
    
    # 训练
    trainer.train()
    
    # 测试
    trainer.test()


if __name__ == '__main__':
    main()
