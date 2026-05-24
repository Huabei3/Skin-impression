"""
特征融合模块 - 多流特征融合与注意力机制
"""
import torch
import torch.nn as nn
import torch.nn.functional as F
from typing import Dict, Tuple, Optional
import math


class MultiHeadAttention(nn.Module):
    """多头注意力机制"""
    
    def __init__(self, 
                 d_model: int,
                 num_heads: int = 8,
                 dropout: float = 0.1):
        """
        初始化多头注意力
        
        Args:
            d_model: 模型维度
            num_heads: 注意力头数
            dropout: Dropout概率
        """
        super(MultiHeadAttention, self).__init__()
        
        assert d_model % num_heads == 0
        
        self.d_model = d_model
        self.num_heads = num_heads
        self.d_k = d_model // num_heads
        
        # 线性变换层
        self.w_q = nn.Linear(d_model, d_model)
        self.w_k = nn.Linear(d_model, d_model)
        self.w_v = nn.Linear(d_model, d_model)
        self.w_o = nn.Linear(d_model, d_model)
        
        self.dropout = nn.Dropout(dropout)
        self.layer_norm = nn.LayerNorm(d_model)
    
    def forward(self, query: torch.Tensor, 
                key: torch.Tensor, 
                value: torch.Tensor,
                mask: Optional[torch.Tensor] = None) -> torch.Tensor:
        """
        前向传播
        
        Args:
            query: 查询张量 (B, L, D)
            key: 键张量 (B, L, D)
            value: 值张量 (B, L, D)
            mask: 掩码张量
            
        Returns:
            注意力输出 (B, L, D)
        """
        batch_size = query.size(0)
        
        # 1. 线性变换并分头
        Q = self.w_q(query).view(batch_size, -1, self.num_heads, self.d_k).transpose(1, 2)
        K = self.w_k(key).view(batch_size, -1, self.num_heads, self.d_k).transpose(1, 2)
        V = self.w_v(value).view(batch_size, -1, self.num_heads, self.d_k).transpose(1, 2)
        
        # 2. 计算注意力得分
        scores = torch.matmul(Q, K.transpose(-2, -1)) / math.sqrt(self.d_k)
        
        if mask is not None:
            scores = scores.masked_fill(mask == 0, -1e9)
        
        attention_weights = F.softmax(scores, dim=-1)
        attention_weights = self.dropout(attention_weights)
        
        # 3. 应用注意力权重
        context = torch.matmul(attention_weights, V)
        
        # 4. 合并多头
        context = context.transpose(1, 2).contiguous().view(
            batch_size, -1, self.d_model
        )
        
        # 5. 输出线性变换
        output = self.w_o(context)
        
        # 6. 残差连接和层归一化
        output = self.layer_norm(output + query)
        
        return output


class CrossModalAttention(nn.Module):
    """跨模态注意力机制 - 用于不同流之间的信息交互"""
    
    def __init__(self, 
                 face_dim: int,
                 global_dim: int,
                 stat_dim: int,
                 hidden_dim: int = 256,
                 num_heads: int = 8,
                 dropout: float = 0.3):
        """
        初始化跨模态注意力
        
        Args:
            face_dim: 人脸流特征维度
            global_dim: 全局流特征维度
            stat_dim: 统计流特征维度
            hidden_dim: 隐藏层维度
            num_heads: 注意力头数
            dropout: Dropout概率
        """
        super(CrossModalAttention, self).__init__()
        
        # 特征投影层（将不同维度投影到统一维度）
        self.face_proj = nn.Linear(face_dim, hidden_dim)
        self.global_proj = nn.Linear(global_dim, hidden_dim)
        self.stat_proj = nn.Linear(stat_dim, hidden_dim)
        
        # 多头注意力
        self.multi_head_attn = MultiHeadAttention(
            d_model=hidden_dim,
            num_heads=num_heads,
            dropout=dropout
        )
        
        # 门控机制
        self.gate = nn.Sequential(
            nn.Linear(hidden_dim * 3, hidden_dim),
            nn.ReLU(inplace=True),
            nn.Linear(hidden_dim, 3),
            nn.Softmax(dim=1)
        )
        
        # 输出投影
        self.output_proj = nn.Sequential(
            nn.Linear(hidden_dim, hidden_dim),
            nn.BatchNorm1d(hidden_dim),
            nn.ReLU(inplace=True),
            nn.Dropout(dropout)
        )
        
        self.output_dim = hidden_dim
    
    def forward(self, 
                face_features: torch.Tensor,
                global_features: torch.Tensor,
                stat_features: torch.Tensor) -> torch.Tensor:
        """
        前向传播
        
        Args:
            face_features: 人脸流特征 (B, face_dim)
            global_features: 全局流特征 (B, global_dim)
            stat_features: 统计流特征 (B, stat_dim)
            
        Returns:
            融合特征 (B, hidden_dim)
        """
        # 投影到统一维度
        face_proj = self.face_proj(face_features)
        global_proj = self.global_proj(global_features)
        stat_proj = self.stat_proj(stat_features)
        
        # 堆叠特征用于注意力计算 (B, 3, hidden_dim)
        stacked_features = torch.stack([face_proj, global_proj, stat_proj], dim=1)
        
        # 应用多头注意力
        attended_features = self.multi_head_attn(
            stacked_features, stacked_features, stacked_features
        )
        
        # 计算门控权重
        concat_features = torch.cat([face_proj, global_proj, stat_proj], dim=1)
        gate_weights = self.gate(concat_features)
        
        # 加权融合
        weighted_features = (
            attended_features[:, 0] * gate_weights[:, 0:1] +
            attended_features[:, 1] * gate_weights[:, 1:2] +
            attended_features[:, 2] * gate_weights[:, 2:3]
        )
        
        # 输出投影
        output = self.output_proj(weighted_features)
        
        return output


class AdaptiveFusion(nn.Module):
    """自适应特征融合模块"""
    
    def __init__(self, 
                 face_dim: int,
                 global_dim: int,
                 stat_dim: int,
                 fusion_dim: int = 256,
                 dropout: float = 0.3):
        """
        初始化自适应融合
        
        Args:
            face_dim: 人脸流特征维度
            global_dim: 全局流特征维度
            stat_dim: 统计流特征维度
            fusion_dim: 融合后维度
            dropout: Dropout概率
        """
        super(AdaptiveFusion, self).__init__()
        
        total_dim = face_dim + global_dim + stat_dim
        
        # 特征变换
        self.feature_transform = nn.Sequential(
            nn.Linear(total_dim, fusion_dim * 2),
            nn.BatchNorm1d(fusion_dim * 2),
            nn.ReLU(inplace=True),
            nn.Dropout(dropout)
        )
        
        # 自适应权重生成
        self.weight_generator = nn.Sequential(
            nn.Linear(fusion_dim * 2, fusion_dim),
            nn.ReLU(inplace=True),
            nn.Linear(fusion_dim, 3),
            nn.Softmax(dim=1)
        )
        
        # 特征精炼
        self.refine = nn.Sequential(
            nn.Linear(fusion_dim * 2, fusion_dim),
            nn.BatchNorm1d(fusion_dim),
            nn.ReLU(inplace=True),
            nn.Dropout(dropout),
            nn.Linear(fusion_dim, fusion_dim),
            nn.BatchNorm1d(fusion_dim),
            nn.ReLU(inplace=True)
        )
        
        self.output_dim = fusion_dim
    
    def forward(self,
                face_features: torch.Tensor,
                global_features: torch.Tensor,
                stat_features: torch.Tensor) -> torch.Tensor:
        """
        前向传播
        
        Args:
            face_features: 人脸流特征 (B, face_dim)
            global_features: 全局流特征 (B, global_dim)
            stat_features: 统计流特征 (B, stat_dim)
            
        Returns:
            融合特征 (B, fusion_dim)
        """
        # 拼接所有特征
        concat_features = torch.cat([
            face_features, 
            global_features, 
            stat_features
        ], dim=1)
        
        # 特征变换
        transformed = self.feature_transform(concat_features)
        
        # 生成自适应权重
        weights = self.weight_generator(transformed)
        
        # 加权组合原始特征
        weighted_face = face_features * weights[:, 0:1]
        weighted_global = global_features * weights[:, 1:2]
        weighted_stat = stat_features * weights[:, 2:3]
        
        # 再次拼接加权特征
        weighted_concat = torch.cat([
            weighted_face,
            weighted_global,
            weighted_stat,
            transformed  # 包含变换后的特征
        ], dim=1)
        
        # 精炼融合特征
        output = self.refine(weighted_concat[:, :transformed.size(1)])
        
        return output


class PredictionHead(nn.Module):
    """预测头 - 用于最终的任务预测"""
    
    def __init__(self,
                 input_dim: int,
                 hidden_dims: list,
                 output_dim: int,
                 dropout: float = 0.3,
                 activation: str = 'none'):
        """
        初始化预测头
        
        Args:
            input_dim: 输入维度
            hidden_dims: 隐藏层维度列表
            output_dim: 输出维度
            dropout: Dropout概率
            activation: 输出激活函数 ('none', 'sigmoid', 'tanh')
        """
        super(PredictionHead, self).__init__()
        
        layers = []
        in_dim = input_dim
        
        # 构建隐藏层
        for hidden_dim in hidden_dims:
            layers.append(nn.Linear(in_dim, hidden_dim))
            layers.append(nn.BatchNorm1d(hidden_dim))
            layers.append(nn.ReLU(inplace=True))
            layers.append(nn.Dropout(dropout))
            in_dim = hidden_dim
        
        # 输出层
        layers.append(nn.Linear(in_dim, output_dim))
        
        # 添加激活函数
        if activation == 'sigmoid':
            layers.append(nn.Sigmoid())
        elif activation == 'tanh':
            layers.append(nn.Tanh())
        
        self.mlp = nn.Sequential(*layers)
    
    def forward(self, x: torch.Tensor) -> torch.Tensor:
        """
        前向传播
        
        Args:
            x: 输入特征 (B, input_dim)
            
        Returns:
            预测结果 (B, output_dim)
        """
        return self.mlp(x)


class DualTaskPredictionHead(nn.Module):
    """双任务预测头 - 同时预测喜好度评分和喜好中心"""
    
    def __init__(self, config: Dict):
        """
        初始化双任务预测头
        
        Args:
            config: 配置字典
        """
        super(DualTaskPredictionHead, self).__init__()
        
        fusion_dim = config['MODEL']['fusion']['fusion_dim']
        pred_config = config['MODEL']['prediction_heads']
        
        # 喜好度评分预测头（输出logits，由损失函数内部做Sigmoid）
        self.preference_score_head = PredictionHead(
            input_dim=fusion_dim,
            hidden_dims=pred_config['preference_score']['hidden_dims'],
            output_dim=pred_config['preference_score']['output_dim'],
            activation='none'
        )
        
        # 喜好中心预测头
        self.preference_center_head = PredictionHead(
            input_dim=fusion_dim,
            hidden_dims=pred_config['preference_center']['hidden_dims'],
            output_dim=pred_config['preference_center']['output_dim'],
            activation='none'  # LAB空间的a*, b*不需要激活
        )
    
    def forward(self, features: torch.Tensor) -> Tuple[torch.Tensor, torch.Tensor]:
        """
        前向传播
        
        Args:
            features: 融合特征 (B, fusion_dim)
            
        Returns:
            - preference_score: 喜好度评分 (B, 1)
            - preference_center: 喜好中心 (B, 2)
        """
        preference_score = self.preference_score_head(features)
        preference_center = self.preference_center_head(features)
        
        # 限制LAB空间的范围
        preference_center = torch.clamp(preference_center, -128, 127)
        
        return preference_score, preference_center


class FeatureFusion(nn.Module):
    """
    特征融合主类 - 整合多种融合策略
    """
    
    def __init__(self,
                 face_dim: int = 640,  # ResNet50 + UV CNN
                 global_dim: int = 256,  # MobileNetV3
                 stat_dim: int = 64,  # 统计特征
                 fusion_dim: int = 256,
                 fusion_type: str = 'adaptive',  # 'adaptive', 'attention', 'both'
                 num_heads: int = 8,
                 dropout: float = 0.3):
        """
        初始化特征融合模块
        
        Args:
            face_dim: 人脸流特征维度
            global_dim: 全局流特征维度
            stat_dim: 统计流特征维度
            fusion_dim: 融合后的特征维度
            fusion_type: 融合类型
            num_heads: 注意力头数
            dropout: Dropout概率
        """
        super().__init__()
        
        self.fusion_type = fusion_type
        
        if fusion_type in ['adaptive', 'both']:
            self.adaptive_fusion = AdaptiveFusion(
                face_dim=face_dim,
                global_dim=global_dim,
                stat_dim=stat_dim,
                fusion_dim=fusion_dim,
                dropout=dropout
            )
        
        if fusion_type in ['attention', 'both']:
            self.attention_fusion = CrossModalAttention(
                face_dim=face_dim,
                global_dim=global_dim,
                stat_dim=stat_dim,
                hidden_dim=fusion_dim,
                num_heads=num_heads,
                dropout=dropout
            )
        
        if fusion_type == 'both':
            # 组合两种融合方式
            self.combine_layer = nn.Sequential(
                nn.Linear(fusion_dim * 2, fusion_dim),
                nn.BatchNorm1d(fusion_dim),
                nn.ReLU(inplace=True),
                nn.Dropout(dropout)
            )
        
        self.output_dim = fusion_dim
    
    def forward(self,
                face_features: torch.Tensor,
                global_features: torch.Tensor,
                stat_features: torch.Tensor) -> torch.Tensor:
        """
        前向传播
        
        Args:
            face_features: 人脸流特征
            global_features: 全局流特征
            stat_features: 统计流特征
            
        Returns:
            融合后的特征
        """
        if self.fusion_type == 'adaptive':
            return self.adaptive_fusion(face_features, global_features, stat_features)
        
        elif self.fusion_type == 'attention':
            return self.attention_fusion(face_features, global_features, stat_features)
        
        elif self.fusion_type == 'both':
            adaptive_out = self.adaptive_fusion(face_features, global_features, stat_features)
            attention_out = self.attention_fusion(face_features, global_features, stat_features)
            combined = torch.cat([adaptive_out, attention_out], dim=1)
            return self.combine_layer(combined)
        
        else:
            raise ValueError(f"Unknown fusion type: {self.fusion_type}")
