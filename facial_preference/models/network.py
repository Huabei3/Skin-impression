"""
主网络模型 - 整合所有流和组件
"""
import torch
import torch.nn as nn
from typing import Dict, Tuple, Optional
from .face_stream import FaceStream, AttentiveFaceStream
from .global_stream import GlobalStream, StatisticalStream, SceneFeatureExtractor
from .fusion import CrossModalAttention, AdaptiveFusion, DualTaskPredictionHead


class FacialPreferenceNetwork(nn.Module):
    """人脸颜色喜好度预测网络 - 主模型"""
    
    def __init__(self, config: Dict, use_attention: bool = True):
        """
        初始化网络
        
        Args:
            config: 配置字典
            use_attention: 是否使用注意力机制
        """
        super(FacialPreferenceNetwork, self).__init__()
        
        self.config = config
        self.use_attention = use_attention
        
        # 初始化各个流
        if use_attention:
            self.face_stream = AttentiveFaceStream(config)
        else:
            self.face_stream = FaceStream(config)
        
        self.global_stream = GlobalStream(config)
        self.stat_stream = StatisticalStream(config)
        
        # 场景特征提取器
        self.scene_extractor = SceneFeatureExtractor()
        
        # 特征融合
        if use_attention:
            self.fusion = CrossModalAttention(
                face_dim=self.face_stream.output_dim,
                global_dim=self.global_stream.output_dim,
                stat_dim=self.stat_stream.output_dim,
                hidden_dim=config['MODEL']['fusion']['fusion_dim'],
                num_heads=config['MODEL']['fusion']['attention_heads'],
                dropout=config['MODEL']['fusion']['dropout']
            )
        else:
            self.fusion = AdaptiveFusion(
                face_dim=self.face_stream.output_dim,
                global_dim=self.global_stream.output_dim,
                stat_dim=self.stat_stream.output_dim,
                fusion_dim=config['MODEL']['fusion']['fusion_dim'],
                dropout=config['MODEL']['fusion']['dropout']
            )
        
        # 预测头
        self.prediction_head = DualTaskPredictionHead(config)
        
        # 初始化权重
        self._initialize_weights()
    
    def _initialize_weights(self):
        """初始化网络权重"""
        for m in self.modules():
            if isinstance(m, nn.Conv2d):
                nn.init.kaiming_normal_(m.weight, mode='fan_out', nonlinearity='relu')
                if m.bias is not None:
                    nn.init.constant_(m.bias, 0)
            elif isinstance(m, nn.BatchNorm2d) or isinstance(m, nn.BatchNorm1d):
                nn.init.constant_(m.weight, 1)
                nn.init.constant_(m.bias, 0)
            elif isinstance(m, nn.Linear):
                nn.init.normal_(m.weight, 0, 0.01)
                if m.bias is not None:
                    nn.init.constant_(m.bias, 0)
    
    def forward(self, 
                face_rgb: torch.Tensor,
                face_uv: torch.Tensor,
                global_rgb: Optional[torch.Tensor] = None,
                stat_features: Optional[torch.Tensor] = None) -> Tuple[torch.Tensor, torch.Tensor]:
        """
        前向传播
        
        Args:
            face_rgb: 人脸RGB图像 (B, 3, H, W)
            face_uv: 人脸UV数据 (B, 2, H, W)
            global_rgb: 全局图像 (B, 3, H, W)，可选
            stat_features: 统计特征 (B, 10)，可选
            
        Returns:
            - preference_score: 喜好度评分 (B, 1)
            - preference_center: 喜好中心 (B, 2)
        """
        # 1. 人脸流特征提取
        face_features = self.face_stream(face_rgb, face_uv)
        
        # 2. 全局流特征提取
        if global_rgb is not None:
            global_features = self.global_stream(global_rgb)
        else:
            # 如果没有提供全局图像，使用人脸图像作为替代
            global_features = self.global_stream(face_rgb)
        
        # 3. 统计特征提取
        if stat_features is None:
            # 自动提取统计特征
            stat_features = self.scene_extractor.prepare_statistical_features(
                face_rgb, global_rgb
            )
        stat_features = self.stat_stream(stat_features)
        
        # 4. 特征融合
        fused_features = self.fusion(face_features, global_features, stat_features)
        
        # 5. 预测
        preference_score, preference_center = self.prediction_head(fused_features)
        
        return preference_score, preference_center
    
    def get_intermediate_features(self, 
                                 face_rgb: torch.Tensor,
                                 face_uv: torch.Tensor,
                                 global_rgb: Optional[torch.Tensor] = None) -> Dict[str, torch.Tensor]:
        """
        获取中间特征（用于可视化和分析）
        
        Args:
            face_rgb: 人脸RGB图像
            face_uv: 人脸UV数据
            global_rgb: 全局图像
            
        Returns:
            包含各层特征的字典
        """
        features = {}
        
        # 提取各流特征
        face_features = self.face_stream(face_rgb, face_uv)
        features['face_features'] = face_features
        
        if global_rgb is not None:
            global_features = self.global_stream(global_rgb)
        else:
            global_features = self.global_stream(face_rgb)
        features['global_features'] = global_features
        
        stat_features_raw = self.scene_extractor.prepare_statistical_features(
            face_rgb, global_rgb
        )
        features['stat_features_raw'] = stat_features_raw
        
        stat_features = self.stat_stream(stat_features_raw)
        features['stat_features'] = stat_features
        
        # 融合特征
        fused_features = self.fusion(face_features, global_features, stat_features)
        features['fused_features'] = fused_features
        
        return features


class SimplifiedFacialPreferenceNetwork(nn.Module):
    """简化版网络 - 仅使用人脸流"""
    
    def __init__(self, config: Dict):
        """
        初始化简化网络
        
        Args:
            config: 配置字典
        """
        super(SimplifiedFacialPreferenceNetwork, self).__init__()
        
        # 仅使用人脸流
        self.face_stream = FaceStream(config)
        
        # 直接预测
        fusion_dim = self.face_stream.output_dim
        pred_config = config['MODEL']['prediction_heads']
        
        # 喜好度评分预测
        self.score_head = nn.Sequential(
            nn.Linear(fusion_dim, 128),
            nn.BatchNorm1d(128),
            nn.ReLU(inplace=True),
            nn.Dropout(0.3),
            nn.Linear(128, 64),
            nn.BatchNorm1d(64),
            nn.ReLU(inplace=True),
            nn.Linear(64, 1)
        )
        
        # 喜好中心预测
        self.center_head = nn.Sequential(
            nn.Linear(fusion_dim, 128),
            nn.BatchNorm1d(128),
            nn.ReLU(inplace=True),
            nn.Dropout(0.3),
            nn.Linear(128, 64),
            nn.BatchNorm1d(64),
            nn.ReLU(inplace=True),
            nn.Linear(64, 2)
        )
    
    def forward(self, 
                face_rgb: torch.Tensor,
                face_uv: torch.Tensor) -> Tuple[torch.Tensor, torch.Tensor]:
        """
        前向传播
        
        Args:
            face_rgb: 人脸RGB图像 (B, 3, H, W)
            face_uv: 人脸UV数据 (B, 2, H, W)
            
        Returns:
            - preference_score: 喜好度评分 (B, 1)
            - preference_center: 喜好中心 (B, 2)
        """
        # 人脸特征提取
        features = self.face_stream(face_rgb, face_uv)
        
        # 预测
        preference_score = self.score_head(features)
        preference_center = self.center_head(features)
        
        # 限制LAB范围
        preference_center = torch.clamp(preference_center, -128, 127)
        
        return preference_score, preference_center


def create_model(config: Dict, 
                 model_type: str = 'full',
                 use_attention: bool = True) -> nn.Module:
    """
    创建模型
    
    Args:
        config: 配置字典
        model_type: 模型类型 ('full', 'simplified')
        use_attention: 是否使用注意力机制
        
    Returns:
        模型实例
    """
    if model_type == 'full':
        model = FacialPreferenceNetwork(config, use_attention)
    elif model_type == 'simplified':
        model = SimplifiedFacialPreferenceNetwork(config)
    else:
        raise ValueError(f"Unknown model type: {model_type}")
    
    return model


def count_parameters(model: nn.Module) -> int:
    """
    统计模型参数量
    
    Args:
        model: 模型
        
    Returns:
        参数总数
    """
    return sum(p.numel() for p in model.parameters() if p.requires_grad)


def freeze_backbone(model: nn.Module, freeze: bool = True):
    """
    冻结/解冻预训练骨干网络
    
    Args:
        model: 模型
        freeze: 是否冻结
    """
    # 冻结人脸流的RGB分支骨干
    if hasattr(model, 'face_stream'):
        if hasattr(model.face_stream, 'rgb_branch'):
            for param in model.face_stream.rgb_branch.backbone.parameters():
                param.requires_grad = not freeze
    
    # 冻结全局流骨干
    if hasattr(model, 'global_stream'):
        for param in model.global_stream.backbone.parameters():
            param.requires_grad = not freeze


def unfreeze_layers(model: nn.Module, num_layers: int = 2):
    """
    解冻骨干网络的最后几层
    
    Args:
        model: 模型
        num_layers: 要解冻的层数
    """
    # 解冻人脸流RGB分支的最后几层
    if hasattr(model, 'face_stream'):
        if hasattr(model.face_stream, 'rgb_branch'):
            backbone = model.face_stream.rgb_branch.backbone
            if isinstance(backbone, nn.Sequential):
                # 获取所有层
                all_layers = list(backbone.children())
                # 解冻最后几层
                for layer in all_layers[-num_layers:]:
                    for param in layer.parameters():
                        param.requires_grad = True
    
    # 解冻全局流的最后几层
    if hasattr(model, 'global_stream'):
        backbone = model.global_stream.backbone
        # MobileNet的结构不同，需要特殊处理
        if hasattr(backbone, 'features'):
            features = backbone.features
            if isinstance(features, nn.Sequential):
                all_layers = list(features.children())
                for layer in all_layers[-num_layers:]:
                    for param in layer.parameters():
                        param.requires_grad = True
