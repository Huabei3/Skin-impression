"""
损失函数模块 - 多任务学习损失
"""

import torch
import torch.nn as nn
import torch.nn.functional as F
from typing import Dict, Optional, Tuple
import numpy as np


class HuberLoss(nn.Module):
    """
    Huber Loss - 对异常值鲁棒的损失函数
    在误差较小时表现为L2损失，误差较大时表现为L1损失
    """
    
    def __init__(self, delta: float = 0.1):
        """
        初始化Huber Loss
        
        Args:
            delta: 阈值，控制L1和L2损失的切换点
        """
        super().__init__()
        self.delta = delta
    
    def forward(self, pred: torch.Tensor, target: torch.Tensor) -> torch.Tensor:
        """
        计算Huber Loss
        
        Args:
            pred: 预测值
            target: 目标值
        
        Returns:
            损失值
        """
        residual = torch.abs(pred - target)
        condition = residual <= self.delta
        
        # 小误差使用L2损失，大误差使用L1损失
        loss = torch.where(
            condition,
            0.5 * residual ** 2,
            self.delta * (residual - 0.5 * self.delta)
        )
        
        return loss.mean()


class RankingLoss(nn.Module):
    """
    排序一致性损失
    确保预测分数的相对顺序与真实值一致
    """
    
    def __init__(self, margin: float = 0.1):
        """
        初始化排序损失
        
        Args:
            margin: 间隔阈值
        """
        super().__init__()
        self.margin = margin
    
    def forward(self, pred: torch.Tensor, target: torch.Tensor) -> torch.Tensor:
        """
        计算排序损失
        
        Args:
            pred: 预测值 [batch_size, 1]
            target: 目标值 [batch_size, 1]
        
        Returns:
            损失值
        """
        batch_size = pred.shape[0]
        if batch_size < 2:
            return torch.tensor(0.0, device=pred.device)
        
        # 计算所有样本对的排序关系
        pred_diff = pred.unsqueeze(0) - pred.unsqueeze(1)  # [batch_size, batch_size, 1]
        target_diff = target.unsqueeze(0) - target.unsqueeze(1)  # [batch_size, batch_size, 1]
        
        # 只考虑目标值不同的样本对
        valid_pairs = torch.abs(target_diff) > 1e-6
        
        # 计算排序损失
        # 如果target_i > target_j，则pred_i也应该 > pred_j
        ranking_loss = torch.where(
            target_diff > 0,
            torch.relu(self.margin - pred_diff),  # pred_i应该比pred_j大至少margin
            torch.relu(self.margin + pred_diff)   # pred_j应该比pred_i大至少margin
        )
        
        # 只计算有效样本对的损失
        if valid_pairs.sum() > 0:
            loss = (ranking_loss * valid_pairs).sum() / valid_pairs.sum()
        else:
            loss = torch.tensor(0.0, device=pred.device)
        
        return loss


class PerceptualColorLoss(nn.Module):
    """
    感知色彩损失
    基于人眼对不同色彩区域的敏感度进行加权
    """
    
    def __init__(self, skin_weight: float = 1.5, extreme_weight: float = 0.7):
        """
        初始化感知色彩损失
        
        Args:
            skin_weight: 肤色区域的权重
            extreme_weight: 极端色彩区域的权重
        """
        super().__init__()
        self.skin_weight = skin_weight
        self.extreme_weight = extreme_weight
        
        # 定义肤色在LAB空间的典型范围
        # a*: [0, 20], b*: [10, 30] 为典型肤色范围
        self.skin_a_range = (0, 20)
        self.skin_b_range = (10, 30)
    
    def forward(self, pred: torch.Tensor, target: torch.Tensor) -> torch.Tensor:
        """
        计算感知色彩损失
        
        Args:
            pred: 预测的LAB坐标 [batch_size, 2]
            target: 目标LAB坐标 [batch_size, 2]
        
        Returns:
            加权的色彩损失
        """
        # 计算欧氏距离
        distance = torch.sqrt(torch.sum((pred - target) ** 2, dim=1) + 1e-6)
        
        # 判断是否在肤色区域
        a_star = target[:, 0]
        b_star = target[:, 1]
        
        is_skin = (
            (a_star >= self.skin_a_range[0]) & (a_star <= self.skin_a_range[1]) &
            (b_star >= self.skin_b_range[0]) & (b_star <= self.skin_b_range[1])
        )
        
        # 判断是否为极端色彩（距离原点很远）
        is_extreme = torch.sqrt(a_star ** 2 + b_star ** 2) > 80
        
        # 应用权重
        weights = torch.ones_like(distance)
        weights[is_skin] = self.skin_weight
        weights[is_extreme] = self.extreme_weight
        
        # 计算加权损失
        weighted_loss = (distance * weights).mean()
        
        return weighted_loss


class ConsistencyLoss(nn.Module):
    """
    一致性损失
    确保预测的LAB中心点与输入的UV分布相关
    """
    
    def __init__(self, weight: float = 0.1):
        """
        初始化一致性损失
        
        Args:
            weight: 损失权重
        """
        super().__init__()
        self.weight = weight
    
    def forward(self, 
                pred_center: torch.Tensor,
                face_uv: Optional[torch.Tensor] = None) -> torch.Tensor:
        """
        计算一致性损失
        
        Args:
            pred_center: 预测的LAB中心 [batch_size, 2]
            face_uv: 输入的UV数据 [batch_size, 2, H, W]（可选）
        
        Returns:
            一致性损失
        """
        if face_uv is None:
            return torch.tensor(0.0, device=pred_center.device)
        
        # 计算UV数据的统计特征
        batch_size = face_uv.shape[0]
        uv_mean = face_uv.view(batch_size, 2, -1).mean(dim=2)  # [batch_size, 2]
        uv_std = face_uv.view(batch_size, 2, -1).std(dim=2)  # [batch_size, 2]
        
        # 简单的一致性约束：预测的中心应该与UV统计相关
        # 这里使用一个简单的线性关系作为约束
        # 实际应用中可能需要更复杂的色彩空间转换
        
        # 归一化的UV均值应该与LAB中心有某种相关性
        uv_features = torch.cat([uv_mean, uv_std], dim=1)  # [batch_size, 4]
        
        # 计算预测中心的范围
        pred_range = torch.max(torch.abs(pred_center), dim=1)[0]  # [batch_size]
        
        # UV的标准差较大时，允许LAB中心有更大的范围
        expected_range = 50 + 100 * uv_std.mean(dim=1)  # [batch_size]
        
        # 计算一致性损失
        consistency_loss = F.mse_loss(pred_range, expected_range)
        
        return consistency_loss * self.weight


class FacialPreferenceLoss(nn.Module):
    """
    人脸颜色喜好度预测的多任务损失函数
    """
    
    def __init__(self,
                 score_weight: float = 1.0,
                 center_weight: float = 0.5,
                 consistency_weight: float = 0.1,
                 ranking_weight: float = 0.2,
                 use_huber: bool = True,
                 huber_delta: float = 0.1,
                 use_perceptual: bool = True,
                 dynamic_weighting: bool = False):
        """
        初始化多任务损失函数
        
        Args:
            score_weight: 喜好度评分损失权重
            center_weight: 喜好中心损失权重
            consistency_weight: 一致性损失权重
            ranking_weight: 排序损失权重（相对于评分损失）
            use_huber: 是否使用Huber Loss
            huber_delta: Huber Loss的阈值
            use_perceptual: 是否使用感知色彩损失
            dynamic_weighting: 是否使用动态权重调整
        """
        super().__init__()
        
        # 损失权重
        self.score_weight = score_weight
        self.center_weight = center_weight
        self.consistency_weight = consistency_weight
        self.ranking_weight = ranking_weight
        self.dynamic_weighting = dynamic_weighting
        
        # 喜好度评分损失
        if use_huber:
            self.score_loss = HuberLoss(delta=huber_delta)
        else:
            self.score_loss = nn.MSELoss()
        
        # 排序一致性损失
        self.ranking_loss = RankingLoss(margin=0.1)
        
        # 喜好中心损失
        if use_perceptual:
            self.center_loss = PerceptualColorLoss()
        else:
            self.center_loss = nn.MSELoss()
        
        # 一致性损失
        self.consistency_loss = ConsistencyLoss(weight=1.0)
        
        # 用于动态权重调整的参数
        if dynamic_weighting:
            self.log_vars = nn.Parameter(torch.zeros(3))  # 3个任务的log方差
    
    def forward(self,
                pred_score: torch.Tensor,
                true_score: torch.Tensor,
                pred_center: torch.Tensor,
                true_center: torch.Tensor,
                face_uv: Optional[torch.Tensor] = None,
                return_components: bool = True) -> Dict[str, torch.Tensor]:
        """
        计算总损失
        
        Args:
            pred_score: 预测的喜好度评分 [batch_size, 1]
            true_score: 真实的喜好度评分 [batch_size, 1]
            pred_center: 预测的喜好中心 [batch_size, 2]
            true_center: 真实的喜好中心 [batch_size, 2]
            face_uv: UV数据（用于一致性损失）[batch_size, 2, H, W]
            return_components: 是否返回各分量损失
        
        Returns:
            损失字典，包含总损失和各分量损失
        """
        # 计算各项损失
        loss_score_main = self.score_loss(pred_score, true_score)
        loss_ranking = self.ranking_loss(pred_score, true_score)
        loss_score = loss_score_main + self.ranking_weight * loss_ranking
        
        loss_center = self.center_loss(pred_center, true_center)
        loss_consistency = self.consistency_loss(pred_center, face_uv)
        
        # 动态权重调整
        if self.dynamic_weighting:
            # 使用不确定性加权
            precision_score = torch.exp(-self.log_vars[0])
            precision_center = torch.exp(-self.log_vars[1])
            precision_consistency = torch.exp(-self.log_vars[2])
            
            loss_total = (
                precision_score * loss_score + self.log_vars[0] +
                precision_center * loss_center + self.log_vars[1] +
                precision_consistency * loss_consistency + self.log_vars[2]
            )
        else:
            # 固定权重
            loss_total = (
                self.score_weight * loss_score +
                self.center_weight * loss_center +
                self.consistency_weight * loss_consistency
            )
        
        # 构建返回字典
        losses = {
            'total': loss_total,
            'score': loss_score,
            'center': loss_center,
            'consistency': loss_consistency
        }
        
        if return_components:
            losses.update({
                'score_main': loss_score_main,
                'ranking': loss_ranking
            })
        
        return losses


class UncertaintyLoss(nn.Module):
    """
    带不确定性估计的损失函数
    用于同时学习预测值和不确定性
    """
    
    def __init__(self):
        """初始化不确定性损失"""
        super().__init__()
    
    def forward(self,
                mean: torch.Tensor,
                var: torch.Tensor,
                target: torch.Tensor) -> torch.Tensor:
        """
        计算不确定性损失（负对数似然）
        
        Args:
            mean: 预测均值
            var: 预测方差
            target: 目标值
        
        Returns:
            损失值
        """
        # 负对数似然损失
        loss = 0.5 * (torch.log(var) + (target - mean) ** 2 / var)
        return loss.mean()


if __name__ == "__main__":
    """测试损失函数"""
    
    # 设置随机种子
    torch.manual_seed(42)
    
    # 创建测试数据
    batch_size = 8
    pred_score = torch.rand(batch_size, 1)
    true_score = torch.rand(batch_size, 1)
    pred_center = torch.randn(batch_size, 2) * 50
    true_center = torch.randn(batch_size, 2) * 50
    face_uv = torch.randn(batch_size, 2, 224, 224)
    
    print("=" * 60)
    print("测试损失函数模块")
    print("=" * 60)
    
    # 测试Huber Loss
    print("\n1. 测试Huber Loss")
    huber = HuberLoss(delta=0.1)
    loss = huber(pred_score, true_score)
    print(f"Huber Loss: {loss.item():.4f}")
    
    # 测试排序损失
    print("\n2. 测试排序损失")
    ranking = RankingLoss(margin=0.1)
    loss = ranking(pred_score, true_score)
    print(f"Ranking Loss: {loss.item():.4f}")
    
    # 测试感知色彩损失
    print("\n3. 测试感知色彩损失")
    perceptual = PerceptualColorLoss()
    loss = perceptual(pred_center, true_center)
    print(f"Perceptual Color Loss: {loss.item():.4f}")
    
    # 测试一致性损失
    print("\n4. 测试一致性损失")
    consistency = ConsistencyLoss()
    loss = consistency(pred_center, face_uv)
    print(f"Consistency Loss: {loss.item():.4f}")
    
    # 测试多任务损失
    print("\n5. 测试多任务损失")
    multi_task = FacialPreferenceLoss()
    losses = multi_task(pred_score, true_score, pred_center, true_center, face_uv)
    print("损失分量:")
    for key, value in losses.items():
        print(f"  {key}: {value.item():.4f}")
    
    # 测试动态权重
    print("\n6. 测试动态权重损失")
    dynamic_loss = FacialPreferenceLoss(dynamic_weighting=True)
    losses = dynamic_loss(pred_score, true_score, pred_center, true_center, face_uv)
    print(f"动态权重总损失: {losses['total'].item():.4f}")
    
    print("\n" + "=" * 60)
    print("所有测试通过！")
    print("=" * 60)