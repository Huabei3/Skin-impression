"""
损失函数模块 - 包含多任务损失和各种损失组件
"""
import torch
import torch.nn as nn
import torch.nn.functional as F
from typing import Dict, Tuple, Optional
import numpy as np


class HuberLoss(nn.Module):
    """Huber损失 - 对异常值鲁棒"""
    
    def __init__(self, delta: float = 0.1):
        """
        初始化Huber损失
        
        Args:
            delta: Huber损失的阈值
        """
        super(HuberLoss, self).__init__()
        self.delta = delta
    
    def forward(self, pred: torch.Tensor, target: torch.Tensor) -> torch.Tensor:
        """
        计算Huber损失
        
        Args:
            pred: 预测值
            target: 目标值
            
        Returns:
            损失值
        """
        residual = torch.abs(pred - target)
        mask = residual < self.delta
        
        # 小误差使用L2损失，大误差使用L1损失
        loss = torch.where(
            mask,
            0.5 * residual ** 2,
            self.delta * (residual - 0.5 * self.delta)
        )
        
        return loss.mean()


class RankingLoss(nn.Module):
    """排序一致性损失 - 确保预测分数的相对顺序与真实值一致"""
    
    def __init__(self, margin: float = 0.1):
        """
        初始化排序损失
        
        Args:
            margin: 边界值
        """
        super(RankingLoss, self).__init__()
        self.margin = margin
    
    def forward(self, pred: torch.Tensor, target: torch.Tensor) -> torch.Tensor:
        """
        计算排序损失
        
        Args:
            pred: 预测值 (B, 1)
            target: 目标值 (B, 1)
            
        Returns:
            损失值
        """
        batch_size = pred.size(0)
        if batch_size < 2:
            return torch.tensor(0.0, device=pred.device)
        
        # 计算所有对的排序关系
        pred_diff = pred.unsqueeze(0) - pred.unsqueeze(1)  # (B, B, 1)
        target_diff = target.unsqueeze(0) - target.unsqueeze(1)  # (B, B, 1)
        
        # 创建掩码：只考虑target_diff显著的对
        mask = torch.abs(target_diff) > 0.05
        
        # 计算损失：如果排序不一致则产生损失
        loss = F.relu(self.margin - pred_diff * torch.sign(target_diff))
        loss = loss * mask.float()
        
        # 平均损失
        num_pairs = mask.sum()
        if num_pairs > 0:
            return loss.sum() / num_pairs
        else:
            return torch.tensor(0.0, device=pred.device)


class PerceptualColorLoss(nn.Module):
    """感知色彩损失 - 基于LAB空间的感知加权"""
    
    def __init__(self, skin_weight: float = 1.5, extreme_weight: float = 0.7):
        """
        初始化感知色彩损失
        
        Args:
            skin_weight: 肤色区域权重
            extreme_weight: 极端色彩区域权重
        """
        super(PerceptualColorLoss, self).__init__()
        self.skin_weight = skin_weight
        self.extreme_weight = extreme_weight
    
    def _get_perceptual_weight(self, lab_values: torch.Tensor) -> torch.Tensor:
        """
        计算感知权重
        
        Args:
            lab_values: LAB值 (B, 2) - 只有a*和b*
            
        Returns:
            权重 (B, 1)
        """
        a_star = lab_values[:, 0]
        b_star = lab_values[:, 1]
        
        # 计算到原点的距离（色彩饱和度）
        chroma = torch.sqrt(a_star ** 2 + b_star ** 2)
        
        # 肤色通常在a*=[0, 20], b*=[0, 20]范围内
        is_skin_tone = (a_star >= 0) & (a_star <= 20) & (b_star >= 0) & (b_star <= 20)
        
        # 极端色彩（高饱和度）
        is_extreme = chroma > 50
        
        # 计算权重
        weights = torch.ones_like(chroma)
        weights[is_skin_tone] = self.skin_weight
        weights[is_extreme] = self.extreme_weight
        
        return weights.unsqueeze(1)
    
    def forward(self, pred: torch.Tensor, target: torch.Tensor) -> torch.Tensor:
        """
        计算感知加权的色彩损失
        
        Args:
            pred: 预测的LAB值 (B, 2)
            target: 目标LAB值 (B, 2)
            
        Returns:
            损失值
        """
        # 计算欧氏距离
        distance = torch.sqrt(torch.sum((pred - target) ** 2, dim=1, keepdim=True))
        
        # 获取感知权重
        weights = self._get_perceptual_weight(target)
        
        # 加权损失
        weighted_loss = distance * weights
        
        return weighted_loss.mean()


class ColorConsistencyLoss(nn.Module):
    """色彩一致性损失 - 确保预测的色彩与输入UV分布相关"""
    
    def __init__(self, weight: float = 0.1):
        """
        初始化色彩一致性损失
        
        Args:
            weight: 损失权重
        """
        super(ColorConsistencyLoss, self).__init__()
        self.weight = weight
    
    def forward(self, 
                pred_center: torch.Tensor,
                face_uv: torch.Tensor) -> torch.Tensor:
        """
        计算色彩一致性损失
        
        Args:
            pred_center: 预测的LAB中心 (B, 2)
            face_uv: 输入的UV数据 (B, 2, H, W)
            
        Returns:
            损失值
        """
        batch_size = pred_center.size(0)
        
        # 计算UV数据的统计信息
        uv_mean = face_uv.view(batch_size, 2, -1).mean(dim=2)  # (B, 2)
        uv_std = face_uv.view(batch_size, 2, -1).std(dim=2)    # (B, 2)
        
        # 简化的一致性检查：预测的中心应该与UV统计相关
        # 这里使用一个简单的相关性度量
        
        # 将UV统计映射到类似LAB的范围
        uv_mapped = (uv_mean - 0.5) * 256 - 128  # 映射到[-128, 128]
        
        # 计算与预测中心的差异
        consistency_loss = F.mse_loss(pred_center, uv_mapped)
        
        return consistency_loss * self.weight


class MultiTaskLoss(nn.Module):
    """多任务损失 - 整合所有损失组件"""
    
    def __init__(self, config: Dict):
        """
        初始化多任务损失
        
        Args:
            config: 配置字典
        """
        super(MultiTaskLoss, self).__init__()
        
        loss_config = config['LOSS']
        
        # 初始化各个损失组件
        self.huber = HuberLoss(delta=loss_config['huber_delta'])
        self.ranking = RankingLoss(margin=0.1)
        self.perceptual = PerceptualColorLoss(
            skin_weight=loss_config['perceptual_weight']['skin_region'],
            extreme_weight=loss_config['perceptual_weight']['extreme_region']
        )
        self.consistency = ColorConsistencyLoss(weight=loss_config['gamma'])
        
        # 损失权重
        self.alpha = loss_config['alpha']  # 喜好度评分权重
        self.beta = loss_config['beta']    # 喜好中心权重
        self.gamma = loss_config['gamma']  # 一致性权重
        self.ranking_weight = loss_config['ranking_weight']
        
        # 动态权重调整
        self.dynamic_weighting = loss_config['dynamic_weighting']
        self.weight_update_freq = loss_config['weight_update_freq']
        
        # 标签平滑
        self.label_smoothing = loss_config['label_smoothing']
        
        # 评分分支：是否使用 BCE（对两端更友好）
        self.use_bce_for_score = loss_config.get('use_bce_for_score', True)
        self.bce_logits = nn.BCEWithLogitsLoss(reduction='none')

        # 极端样本连续加权设置
        ew_cfg = loss_config.get('extreme_weighting', {})
        self.ew_enabled = ew_cfg.get('enabled', True)
        self.ew_lambda = float(ew_cfg.get('lambda', 2.0))
        self.ew_gamma = float(ew_cfg.get('gamma', 2.0))
        
        # 记录损失历史（用于动态权重调整）
        self.loss_history = {
            'score': [],
            'center': [],
            'consistency': []
        }
    
    def apply_label_smoothing(self, target: torch.Tensor, epsilon: float) -> torch.Tensor:
        """
        应用标签平滑
        
        Args:
            target: 目标值
            epsilon: 平滑参数
            
        Returns:
            平滑后的目标值
        """
        smoothed = target * (1 - epsilon) + 0.5 * epsilon
        return smoothed
    
    def update_dynamic_weights(self, epoch: int):
        """
        动态更新损失权重
        
        Args:
            epoch: 当前epoch
        """
        if not self.dynamic_weighting:
            return
        
        if epoch % self.weight_update_freq != 0:
            return
        
        # 基于损失历史调整权重
        if len(self.loss_history['score']) >= self.weight_update_freq:
            recent_scores = self.loss_history['score'][-self.weight_update_freq:]
            recent_centers = self.loss_history['center'][-self.weight_update_freq:]
            
            # 计算损失的相对变化率
            score_change = np.std(recent_scores) / (np.mean(recent_scores) + 1e-6)
            center_change = np.std(recent_centers) / (np.mean(recent_centers) + 1e-6)
            
            # 如果某个任务收敛较慢，增加其权重
            if score_change > center_change * 1.5:
                self.alpha = min(self.alpha * 1.1, 2.0)
                self.beta = max(self.beta * 0.9, 0.1)
            elif center_change > score_change * 1.5:
                self.beta = min(self.beta * 1.1, 1.0)
                self.alpha = max(self.alpha * 0.9, 0.5)
    
    def forward(self,
                pred_score: torch.Tensor,
                pred_center: torch.Tensor,
                target_score: torch.Tensor,
                target_center: torch.Tensor,
                face_uv: Optional[torch.Tensor] = None,
                epoch: int = 0) -> Tuple[torch.Tensor, Dict[str, float]]:
        """
        计算总损失
        
        Args:
            pred_score: 预测的喜好度评分 (B, 1)
            pred_center: 预测的喜好中心 (B, 2)
            target_score: 目标喜好度评分 (B, 1)
            target_center: 目标喜好中心 (B, 2)
            face_uv: UV数据（用于一致性损失）
            epoch: 当前epoch（用于动态权重调整）
            
        Returns:
            - total_loss: 总损失
            - loss_dict: 各项损失的字典
        """
        # 应用标签平滑
        if self.label_smoothing > 0:
            target_score = self.apply_label_smoothing(target_score, self.label_smoothing)
        
        # 1. 喜好度评分损失
        score_loss = self.huber(pred_score, target_score)
        ranking_loss = self.ranking(pred_score, target_score)
        total_score_loss = score_loss + self.ranking_weight * ranking_loss

        # 重新计算评分损失与排序损失：BCE + 极端连续加权（增强两端区间学习）
        with torch.no_grad():
            target_for_weight = target_score.clone()
        if target_score.max() > 1.5:
            target_score = target_score / 10.0
            target_for_weight = target_for_weight / 10.0
        if self.label_smoothing > 0:
            target_score = self.apply_label_smoothing(target_score, self.label_smoothing)
        if hasattr(self, 'ew_enabled') and self.ew_enabled:
            w_score = 1.0 + self.ew_lambda * torch.pow(torch.abs(target_for_weight - 0.5) / 0.5, self.ew_gamma)
        else:
            w_score = torch.ones_like(target_score)
        avg_w = w_score.mean()
        if hasattr(self, 'use_bce_for_score') and self.use_bce_for_score:
            # 使用 logits 以兼容 AMP：将概率转为 logits 再计算 BCEWithLogits
            logits = torch.logit(pred_score.clamp(1e-6, 1 - 1e-6))
            score_loss_vec = self.bce_logits(logits, target_score)
            score_loss = (score_loss_vec * w_score).mean()
        else:
            score_loss = self.huber(pred_score, target_score) * avg_w
        ranking_loss = self.ranking(pred_score, target_score) * avg_w
        total_score_loss = score_loss + self.ranking_weight * ranking_loss
        
        # 2. 喜好中心损失
        center_loss = self.perceptual(pred_center, target_center)
        
        # 3. 一致性损失
        consistency_loss = torch.tensor(0.0, device=pred_score.device)
        if face_uv is not None:
            consistency_loss = self.consistency(pred_center, face_uv)
        
        # 更新损失历史
        self.loss_history['score'].append(total_score_loss.item())
        self.loss_history['center'].append(center_loss.item())
        self.loss_history['consistency'].append(consistency_loss.item())
        
        # 动态调整权重
        self.update_dynamic_weights(epoch)
        
        # 计算总损失
        total_loss = (
            self.alpha * total_score_loss + 
            self.beta * center_loss + 
            self.gamma * consistency_loss
        )
        
        # 构建损失字典
        loss_dict = {
            'total': total_loss.item(),
            'score': score_loss.item(),
            'ranking': ranking_loss.item(),
            'center': center_loss.item(),
            'consistency': consistency_loss.item(),
            'weights': {
                'alpha': self.alpha,
                'beta': self.beta,
                'gamma': self.gamma
            }
        }
        
        return total_loss, loss_dict


class SimpleLoss(nn.Module):
    """简化版损失函数 - 用于快速实验"""
    
    def __init__(self):
        super(SimpleLoss, self).__init__()
        self.mse = nn.MSELoss()
        self.mae = nn.L1Loss()
    
    def forward(self,
                pred_score: torch.Tensor,
                pred_center: torch.Tensor,
                target_score: torch.Tensor,
                target_center: torch.Tensor) -> Tuple[torch.Tensor, Dict[str, float]]:
        """
        计算简单损失
        
        Args:
            pred_score: 预测的喜好度评分
            pred_center: 预测的喜好中心
            target_score: 目标喜好度评分
            target_center: 目标喜好中心
            
        Returns:
            - total_loss: 总损失
            - loss_dict: 损失字典
        """
        score_loss = self.mse(pred_score, target_score)
        center_loss = self.mae(pred_center, target_center)
        
        total_loss = score_loss + 0.5 * center_loss
        
        loss_dict = {
            'total': total_loss.item(),
            'score': score_loss.item(),
            'center': center_loss.item()
        }
        
        return total_loss, loss_dict


class PrimaryLoss(nn.Module):
    """
    简化版主损失：
    - 评分分支：BCEWithLogitsLoss + 极端分数加权（对靠近0或1的分数给予更高权重）
    - 中心分支：L1 损失（MAE）
    - 无排序一致性、无感知加权、无一致性约束，聚焦于两项主要目标
    """

    def __init__(self, config: Dict):
        super().__init__()
        loss_cfg = config.get('LOSS', {})
        # 权重系数
        self.alpha = float(loss_cfg.get('alpha', 1.0))
        self.beta = float(loss_cfg.get('beta', 1.0))
        self.pearson_weight = float(loss_cfg.get('pearson_weight', 0.01))

        # 标签平滑（应用在目标概率上）
        self.label_smoothing = float(loss_cfg.get('label_smoothing', 0.0))

        # 极端加权配置（可缺省）
        ew_cfg = loss_cfg.get('extreme_weighting', {})
        self.ew_enabled = bool(ew_cfg.get('enabled', True))
        self.ew_lambda = float(ew_cfg.get('lambda', 2.0))
        self.ew_gamma = float(ew_cfg.get('gamma', 2.0))

        self.bce_logits = nn.BCEWithLogitsLoss(reduction='none')
        self.l1 = nn.L1Loss(reduction='mean')
        self.smooth_l1 = nn.SmoothL1Loss(reduction='mean')  # 用作Huber近似

    @staticmethod
    def _maybe_normalize_target_score(target_score: torch.Tensor) -> torch.Tensor:
        # 兼容0-10标注：若检测到>1.5，则视为0-10量纲并缩放到0-1
        if target_score.max() > 1.5:
            return target_score / 10.0
        return target_score

    def _apply_label_smoothing(self, y: torch.Tensor) -> torch.Tensor:
        if self.label_smoothing > 0:
            return y * (1 - self.label_smoothing) + 0.5 * self.label_smoothing
        return y

    @staticmethod
    def _pearson_corr(x: torch.Tensor, y: torch.Tensor) -> torch.Tensor:
        x = x.view(-1)
        y = y.view(-1)
        vx = x - x.mean()
        vy = y - y.mean()
        var_x = (vx * vx).mean()
        var_y = (vy * vy).mean()
        eps = 1e-8
        denom = (var_x * var_y).sqrt().clamp_min(eps)
        cov = (vx * vy).mean()
        corr = cov / denom
        return corr.clamp(-1.0, 1.0)

    def forward(
        self,
        pred_score_logits: torch.Tensor,
        pred_center: torch.Tensor,
        target_score: torch.Tensor,
        target_center: torch.Tensor,
        **kwargs
    ) -> Tuple[torch.Tensor, Dict[str, float]]:
        # 规范化目标分数到[0,1]
        target_score = self._maybe_normalize_target_score(target_score)
        target_for_corr = target_score
        target_score = self._apply_label_smoothing(target_score)

        # 极端分数加权（两端更重）
        if self.ew_enabled:
            with torch.no_grad():
                w_score = 1.0 + self.ew_lambda * torch.pow(torch.abs(target_score - 0.5) / 0.5, self.ew_gamma)
        else:
            w_score = torch.ones_like(target_score)

        # 评分损失：0.5*BCEWithLogits(极端加权) + 0.5*SmoothL1(sigmoid(logits), target)
        score_loss_bce_vec = self.bce_logits(pred_score_logits, target_score)
        score_loss_bce = (score_loss_bce_vec * w_score).mean()
        pred_prob = torch.sigmoid(pred_score_logits)
        score_loss_reg = self.smooth_l1(pred_prob, target_score)
        score_loss = 0.5 * score_loss_bce + 0.5 * score_loss_reg

        pearson_loss = pred_score_logits.new_tensor(0.0)
        if self.pearson_weight > 0.0 and pred_prob.numel() > 1:
            corr = self._pearson_corr(pred_prob, target_for_corr)
            if torch.isfinite(corr):
                pearson_loss = 1.0 - corr

        # 中心损失（L1，按 Plan A 将 a*, b* 归一化到 [-1, 1] 再计算）
        pred_center_n = torch.clamp(pred_center / 128.0, -1.0, 1.0)
        target_center_n = torch.clamp(target_center / 128.0, -1.0, 1.0)
        center_loss = self.l1(pred_center_n, target_center_n)

        total = (
            self.alpha * score_loss
            + self.beta * center_loss
            + self.pearson_weight * pearson_loss
        )

        return total, {
            'total': float(total.item()),
            'score': float(score_loss.item()),
            'center': float(center_loss.item()),
            'pearson': float(pearson_loss.item())
        }
