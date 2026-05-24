"""
预测头模块 - 用于最终的喜好度评分和喜好中心预测
"""

import torch
import torch.nn as nn
import torch.nn.functional as F
from typing import Tuple, Optional


class PreferenceScoreHead(nn.Module):
    """
    喜好度评分预测头
    预测范围在[0, 1]之间的喜好度评分
    """
    
    def __init__(self, 
                 input_dim: int = 256,
                 hidden_dims: list = None,
                 dropout_rate: float = 0.3):
        """
        初始化喜好度评分预测头
        
        Args:
            input_dim: 输入特征维度
            hidden_dims: 隐藏层维度列表
            dropout_rate: Dropout概率
        """
        super().__init__()
        
        if hidden_dims is None:
            hidden_dims = [128, 64]
        
        layers = []
        in_dim = input_dim
        
        # 构建隐藏层
        for hidden_dim in hidden_dims:
            layers.extend([
                nn.Linear(in_dim, hidden_dim),
                nn.BatchNorm1d(hidden_dim),
                nn.ReLU(inplace=True),
                nn.Dropout(dropout_rate)
            ])
            in_dim = hidden_dim
        
        # 输出层
        layers.append(nn.Linear(in_dim, 1))
        layers.append(nn.Sigmoid())  # 确保输出在[0, 1]范围内
        
        self.mlp = nn.Sequential(*layers)
        
        # 初始化权重
        self._initialize_weights()
    
    def _initialize_weights(self):
        """初始化网络权重"""
        for m in self.modules():
            if isinstance(m, nn.Linear):
                nn.init.xavier_normal_(m.weight)
                if m.bias is not None:
                    nn.init.constant_(m.bias, 0)
            elif isinstance(m, nn.BatchNorm1d):
                nn.init.constant_(m.weight, 1)
                nn.init.constant_(m.bias, 0)
    
    def forward(self, features: torch.Tensor) -> torch.Tensor:
        """
        前向传播
        
        Args:
            features: 输入特征 [batch_size, input_dim]
        
        Returns:
            喜好度评分 [batch_size, 1]，范围在[0, 1]
        """
        return self.mlp(features)


class PreferenceCenterHead(nn.Module):
    """
    喜好中心预测头
    预测LAB色彩空间中的a*和b*坐标
    """
    
    def __init__(self, 
                 input_dim: int = 256,
                 hidden_dims: list = None,
                 dropout_rate: float = 0.3,
                 use_tanh: bool = True):
        """
        初始化喜好中心预测头
        
        Args:
            input_dim: 输入特征维度
            hidden_dims: 隐藏层维度列表
            dropout_rate: Dropout概率
            use_tanh: 是否使用tanh激活函数限制输出范围
        """
        super().__init__()
        
        if hidden_dims is None:
            hidden_dims = [128, 64]
        
        self.use_tanh = use_tanh
        
        layers = []
        in_dim = input_dim
        
        # 构建隐藏层
        for hidden_dim in hidden_dims:
            layers.extend([
                nn.Linear(in_dim, hidden_dim),
                nn.BatchNorm1d(hidden_dim),
                nn.ReLU(inplace=True),
                nn.Dropout(dropout_rate)
            ])
            in_dim = hidden_dim
        
        # 输出层 - 输出2维(a*, b*)
        layers.append(nn.Linear(in_dim, 2))
        
        if use_tanh:
            # 使用tanh将输出限制在[-1, 1]，然后缩放到LAB范围
            layers.append(nn.Tanh())
        
        self.mlp = nn.Sequential(*layers)
        
        # LAB空间的范围
        self.lab_scale = 100.0  # a*和b*的典型范围是[-128, 127]，这里使用100作为缩放因子
        
        # 初始化权重
        self._initialize_weights()
    
    def _initialize_weights(self):
        """初始化网络权重"""
        for m in self.modules():
            if isinstance(m, nn.Linear):
                nn.init.xavier_normal_(m.weight)
                if m.bias is not None:
                    nn.init.constant_(m.bias, 0)
            elif isinstance(m, nn.BatchNorm1d):
                nn.init.constant_(m.weight, 1)
                nn.init.constant_(m.bias, 0)
    
    def forward(self, features: torch.Tensor) -> torch.Tensor:
        """
        前向传播
        
        Args:
            features: 输入特征 [batch_size, input_dim]
        
        Returns:
            喜好中心坐标 [batch_size, 2]，表示LAB空间的(a*, b*)
        """
        output = self.mlp(features)
        
        if self.use_tanh:
            # 如果使用了tanh，输出在[-1, 1]范围，需要缩放到LAB范围
            output = output * self.lab_scale
        else:
            # 如果没有使用tanh，直接限制输出范围
            output = torch.clamp(output, -128, 127)
        
        return output


class MultiTaskHead(nn.Module):
    """
    多任务预测头
    同时预测喜好度评分和喜好中心
    """
    
    def __init__(self, 
                 input_dim: int = 256,
                 score_hidden_dims: list = None,
                 center_hidden_dims: list = None,
                 shared_layers: int = 1,
                 dropout_rate: float = 0.3):
        """
        初始化多任务预测头
        
        Args:
            input_dim: 输入特征维度
            score_hidden_dims: 评分预测的隐藏层维度
            center_hidden_dims: 中心预测的隐藏层维度
            shared_layers: 共享层数
            dropout_rate: Dropout概率
        """
        super().__init__()
        
        if score_hidden_dims is None:
            score_hidden_dims = [128, 64]
        if center_hidden_dims is None:
            center_hidden_dims = [128, 64]
        
        # 共享层
        shared_modules = []
        current_dim = input_dim
        
        for i in range(shared_layers):
            next_dim = min(score_hidden_dims[0], center_hidden_dims[0])
            shared_modules.extend([
                nn.Linear(current_dim, next_dim),
                nn.BatchNorm1d(next_dim),
                nn.ReLU(inplace=True),
                nn.Dropout(dropout_rate)
            ])
            current_dim = next_dim
        
        self.shared_layers = nn.Sequential(*shared_modules) if shared_modules else None
        
        # 分离的任务特定层
        self.score_head = PreferenceScoreHead(
            input_dim=current_dim,
            hidden_dims=score_hidden_dims[shared_layers:] if shared_layers > 0 else score_hidden_dims,
            dropout_rate=dropout_rate
        )
        
        self.center_head = PreferenceCenterHead(
            input_dim=current_dim,
            hidden_dims=center_hidden_dims[shared_layers:] if shared_layers > 0 else center_hidden_dims,
            dropout_rate=dropout_rate
        )
    
    def forward(self, features: torch.Tensor) -> Tuple[torch.Tensor, torch.Tensor]:
        """
        前向传播
        
        Args:
            features: 输入特征 [batch_size, input_dim]
        
        Returns:
            tuple: (喜好度评分 [batch_size, 1], 喜好中心 [batch_size, 2])
        """
        # 通过共享层
        if self.shared_layers is not None:
            shared_features = self.shared_layers(features)
        else:
            shared_features = features
        
        # 分别通过两个任务头
        preference_score = self.score_head(shared_features)
        preference_center = self.center_head(shared_features)
        
        return preference_score, preference_center


class UncertaintyHead(nn.Module):
    """
    带不确定性估计的预测头
    同时预测值和不确定性
    """
    
    def __init__(self, 
                 input_dim: int = 256,
                 hidden_dims: list = None,
                 output_dim: int = 1,
                 dropout_rate: float = 0.3):
        """
        初始化不确定性预测头
        
        Args:
            input_dim: 输入特征维度
            hidden_dims: 隐藏层维度列表
            output_dim: 输出维度
            dropout_rate: Dropout概率
        """
        super().__init__()
        
        if hidden_dims is None:
            hidden_dims = [128, 64]
        
        layers = []
        in_dim = input_dim
        
        # 构建隐藏层
        for hidden_dim in hidden_dims:
            layers.extend([
                nn.Linear(in_dim, hidden_dim),
                nn.BatchNorm1d(hidden_dim),
                nn.ReLU(inplace=True),
                nn.Dropout(dropout_rate)
            ])
            in_dim = hidden_dim
        
        self.feature_extractor = nn.Sequential(*layers)
        
        # 分别预测均值和方差
        self.mean_head = nn.Linear(in_dim, output_dim)
        self.var_head = nn.Linear(in_dim, output_dim)
        
        # 初始化权重
        self._initialize_weights()
    
    def _initialize_weights(self):
        """初始化网络权重"""
        for m in self.modules():
            if isinstance(m, nn.Linear):
                nn.init.xavier_normal_(m.weight)
                if m.bias is not None:
                    nn.init.constant_(m.bias, 0)
            elif isinstance(m, nn.BatchNorm1d):
                nn.init.constant_(m.weight, 1)
                nn.init.constant_(m.bias, 0)
    
    def forward(self, features: torch.Tensor) -> Tuple[torch.Tensor, torch.Tensor]:
        """
        前向传播
        
        Args:
            features: 输入特征 [batch_size, input_dim]
        
        Returns:
            tuple: (预测均值 [batch_size, output_dim], 预测方差 [batch_size, output_dim])
        """
        extracted = self.feature_extractor(features)
        
        mean = self.mean_head(extracted)
        # 使用softplus确保方差为正
        var = F.softplus(self.var_head(extracted)) + 1e-6
        
        return mean, var


if __name__ == "__main__":
    """测试预测头模块"""
    
    # 测试数据
    batch_size = 4
    input_dim = 256
    features = torch.randn(batch_size, input_dim)
    
    print("=" * 60)
    print("测试预测头模块")
    print("=" * 60)
    
    # 测试喜好度评分头
    print("\n1. 测试喜好度评分头")
    score_head = PreferenceScoreHead(input_dim=input_dim)
    scores = score_head(features)
    print(f"输入形状: {features.shape}")
    print(f"输出形状: {scores.shape}")
    print(f"输出范围: [{scores.min().item():.3f}, {scores.max().item():.3f}]")
    assert torch.all(scores >= 0) and torch.all(scores <= 1), "评分应在[0,1]范围内"
    print("✓ 喜好度评分头测试通过")
    
    # 测试喜好中心头
    print("\n2. 测试喜好中心头")
    center_head = PreferenceCenterHead(input_dim=input_dim)
    centers = center_head(features)
    print(f"输入形状: {features.shape}")
    print(f"输出形状: {centers.shape}")
    print(f"输出范围: a*=[{centers[:, 0].min().item():.1f}, {centers[:, 0].max().item():.1f}], "
          f"b*=[{centers[:, 1].min().item():.1f}, {centers[:, 1].max().item():.1f}]")
    print("✓ 喜好中心头测试通过")
    
    # 测试多任务头
    print("\n3. 测试多任务头")
    multi_head = MultiTaskHead(input_dim=input_dim)
    scores, centers = multi_head(features)
    print(f"输入形状: {features.shape}")
    print(f"评分输出形状: {scores.shape}")
    print(f"中心输出形状: {centers.shape}")
    print("✓ 多任务头测试通过")
    
    # 测试不确定性头
    print("\n4. 测试不确定性头")
    uncertainty_head = UncertaintyHead(input_dim=input_dim, output_dim=1)
    mean, var = uncertainty_head(features)
    print(f"输入形状: {features.shape}")
    print(f"均值形状: {mean.shape}")
    print(f"方差形状: {var.shape}")
    assert torch.all(var > 0), "方差应为正数"
    print("✓ 不确定性头测试通过")
    
    print("\n" + "=" * 60)
    print("所有测试通过！")
    print("=" * 60)