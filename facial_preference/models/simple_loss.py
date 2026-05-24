"""
简化的损失函数 - 只关注评分和LAB坐标的直接差距
"""
import torch
import torch.nn as nn
import torch.nn.functional as F
from typing import Dict, Tuple


class VerySimpleLoss(nn.Module):
    """极简损失函数 - 只计算MSE"""
    
    def __init__(self, score_weight: float = 2.0, center_weight: float = 1.0):
        """
        初始化损失函数
        
        Args:
            score_weight: 评分损失权重（更重要）
            center_weight: LAB中心损失权重
        """
        super(VerySimpleLoss, self).__init__()
        self.score_weight = score_weight
        self.center_weight = center_weight
        
    def forward(self,
                pred_score: torch.Tensor,
                pred_center: torch.Tensor,
                target_score: torch.Tensor,
                target_center: torch.Tensor,
                **kwargs) -> Tuple[torch.Tensor, Dict[str, float]]:
        """
        计算损失
        
        Args:
            pred_score: 预测评分 (B, 1)，范围应该是[0, 1]
            pred_center: 预测LAB中心 (B, 2)
            target_score: 目标评分 (B, 1)
            target_center: 目标LAB中心 (B, 2)
            
        Returns:
            - total_loss: 总损失
            - loss_dict: 各项损失字典
        """
        # 确保评分在[0, 1]范围内
        # 假设原始评分范围是[0, 10]，需要归一化
        if target_score.max() > 1.5:  # 检查是否需要归一化
            target_score = target_score / 10.0
        
        # 确保预测评分在[0, 1]范围
        pred_score = torch.sigmoid(pred_score) if pred_score.min() < 0 or pred_score.max() > 1 else pred_score
        
        # 评分损失 - 简单的MSE
        score_loss = F.mse_loss(pred_score, target_score)
        
        # LAB中心损失 - L1损失（对异常值更鲁棒）
        # LAB值范围是[-128, 127]，归一化到[-1, 1]
        target_center_norm = target_center / 128.0
        pred_center_norm = pred_center / 128.0
        center_loss = F.l1_loss(pred_center_norm, target_center_norm)
        
        # 总损失 - 评分权重更高
        total_loss = self.score_weight * score_loss + self.center_weight * center_loss
        
        # 构建损失字典
        loss_dict = {
            'total': total_loss.item(),
            'score': score_loss.item(),
            'center': center_loss.item()
        }
        
        return total_loss, loss_dict


class SimpleRegressionLoss(nn.Module):
    """简单的回归损失 - 使用Smooth L1损失"""
    
    def __init__(self, score_weight: float = 3.0, center_weight: float = 1.0):
        """
        初始化损失函数
        
        Args:
            score_weight: 评分损失权重
            center_weight: LAB中心损失权重
        """
        super(SimpleRegressionLoss, self).__init__()
        self.score_weight = score_weight
        self.center_weight = center_weight
        
    def forward(self,
                pred_score: torch.Tensor,
                pred_center: torch.Tensor,
                target_score: torch.Tensor,
                target_center: torch.Tensor,
                **kwargs) -> Tuple[torch.Tensor, Dict[str, float]]:
        """
        计算损失
        
        Args:
            pred_score: 预测评分 (B, 1)
            pred_center: 预测LAB中心 (B, 2)
            target_score: 目标评分 (B, 1)
            target_center: 目标LAB中心 (B, 2)
            
        Returns:
            - total_loss: 总损失
            - loss_dict: 各项损失字典
        """
        # 数据预处理
        # 1. 评分归一化到[0, 1]
        if target_score.max() > 1.5:
            target_score_norm = target_score / 10.0
        else:
            target_score_norm = target_score
            
        # 确保预测评分在合理范围
        if pred_score.min() < -1 or pred_score.max() > 2:
            pred_score = torch.sigmoid(pred_score)
        
        # 2. LAB中心归一化
        target_center_norm = target_center / 100.0  # 归一化到更小的范围
        pred_center_norm = pred_center / 100.0
        
        # 使用Smooth L1损失（Huber损失）- 对异常值更鲁棒
        score_loss = F.smooth_l1_loss(pred_score, target_score_norm)
        center_loss = F.smooth_l1_loss(pred_center_norm, target_center_norm)
        
        # 总损失
        total_loss = self.score_weight * score_loss + self.center_weight * center_loss
        
        # 额外的相关性损失（可选）
        # 确保预测的一致性
        if pred_score.shape[0] > 1:
            # 计算批次内的排序一致性
            pred_diff = pred_score[1:] - pred_score[:-1]
            target_diff = target_score_norm[1:] - target_score_norm[:-1]
            ranking_loss = F.mse_loss(pred_diff, target_diff) * 0.1
            total_loss = total_loss + ranking_loss
        else:
            ranking_loss = torch.tensor(0.0)
        
        # 构建损失字典
        loss_dict = {
            'total': total_loss.item(),
            'score': score_loss.item(),
            'center': center_loss.item(),
            'ranking': ranking_loss.item() if isinstance(ranking_loss, torch.Tensor) else 0.0
        }
        
        return total_loss, loss_dict


if __name__ == "__main__":
    """测试损失函数"""
    
    # 创建测试数据
    batch_size = 8
    pred_score = torch.rand(batch_size, 1)  # [0, 1]范围
    target_score = torch.rand(batch_size, 1) * 10  # [0, 10]范围
    pred_center = torch.randn(batch_size, 2) * 50  # LAB范围
    target_center = torch.randn(batch_size, 2) * 50
    
    print("="*60)
    print("测试简化损失函数")
    print("="*60)
    
    # 测试VerySimpleLoss
    print("\n1. VerySimpleLoss:")
    simple_loss = VerySimpleLoss()
    loss, loss_dict = simple_loss(pred_score, pred_center, target_score, target_center)
    print(f"Total loss: {loss.item():.4f}")
    for key, value in loss_dict.items():
        if key != 'total':
            print(f"  {key}: {value:.4f}")
    
    # 测试SimpleRegressionLoss
    print("\n2. SimpleRegressionLoss:")
    reg_loss = SimpleRegressionLoss()
    loss, loss_dict = reg_loss(pred_score, pred_center, target_score, target_center)
    print(f"Total loss: {loss.item():.4f}")
    for key, value in loss_dict.items():
        if key != 'total':
            print(f"  {key}: {value:.4f}")
    
    print("\n" + "="*60)
    print("测试完成！")