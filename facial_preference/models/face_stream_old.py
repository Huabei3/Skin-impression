"""
人脸流网络模�?- 处理人脸RGB图像和UV数据
"""
import torch
import torch.nn as nn
import torchvision.models as models
from typing import Dict, Tuple


def compute_uv_histogram(
    face_uv: torch.Tensor,
    num_bins_u: int = 32,
    num_bins_v: int = 32,
    u_range = (0.0, 1.0),
    v_range = (0.0, 1.0),
) -> torch.Tensor:
    """�� UV ����ͼת��Ϊ��άֱ��ͼͼ�񣨲�����һ������

    Args:
        face_uv: (B, 2, H, W) �� UV ����ͼ��
        num_bins_u: U ����ֱ��ͼ bin ����
        num_bins_v: V ����ֱ��ͼ bin ����
        u_range: U ����ȡֵ��Χ (u_min, u_max)��
        v_range: V ����ȡֵ��Χ (v_min, v_max)��

    Returns:
        (B, C, num_bins_u, num_bins_v) �� UV ֱ��ͼ��ͼ�񡱣�
        ���� C ������ͨ����һ�£���ǰΪ 2������ͨ��������ͬ��
    """
    if face_uv.dim() != 4:
        raise ValueError(f"face_uv must be 4D (B, C, H, W), got {face_uv.shape}")

    B, C, H, W = face_uv.shape
    if C < 2:
        raise ValueError(f"face_uv must have at least 2 channels (U,V), got {C}")

    # ������ֵ������ NaN/Inf Ӱ��ͳ��
    uv = torch.nan_to_num(face_uv, nan=0.0, posinf=0.0, neginf=0.0)

    # չƽ����ά��
    u = uv[:, 0].view(B, -1)  # (B, N)
    v = uv[:, 1].view(B, -1)  # (B, N)

    u_min, u_max = float(u_range[0]), float(u_range[1])
    v_min, v_max = float(v_range[0]), float(v_range[1])
    u_span = max(u_max - u_min, 1e-6)
    v_span = max(v_max - v_min, 1e-6)

    # ��ԭʼֵ��������Χ����ӳ�䵽 [0,1]������������ɢ bin ����
    u_norm = ((u - u_min) / u_span).clamp(0.0, 1.0)
    v_norm = ((v - v_min) / v_span).clamp(0.0, 1.0)

    u_idx = (u_norm * (num_bins_u - 1)).long().clamp(0, num_bins_u - 1)
    v_idx = (v_norm * (num_bins_v - 1)).long().clamp(0, num_bins_v - 1)

    hist_list = []
    for b in range(B):
        # ÿ�����ض�Ӧһ����ά bin���� (u_idx, v_idx) ӳ��Ϊһά����
        idx = u_idx[b] * num_bins_v + v_idx[b]

        # �������ֱ��ͼ��������һ��������������Ϣ��
        hist_1d = torch.bincount(idx, minlength=num_bins_u * num_bins_v).float()
        hist = hist_1d.view(1, num_bins_u, num_bins_v)  # (1, H_bins, W_bins)

        hist_list.append(hist)

    # (B, 1, H_bins, W_bins)
    hist = torch.stack(hist_list, dim=0)

    # Ϊ���뵱ǰ UVBranch ��������״���ݣ���ͨ��ά���Ƶ� C ͨ��
    if C > 1:
        hist = hist.expand(-1, C, -1, -1).contiguous()

    return hist

class RGBBranch(nn.Module):
    """RGB图像处理分支 - 使用预训练的ResNet50"""
    
    def __init__(self, 
                 backbone: str = 'resnet50',
                 pretrained: bool = True,
                 feature_dim: int = 512):
        """
        初始化RGB分支
        
        Args:
            backbone: 骨干网络类型
            pretrained: 是否使用预训练权�?
            feature_dim: 输出特征维度
        """
        super(RGBBranch, self).__init__()
        
        # 加载预训练骨干网�?
        if backbone == 'resnet50':
            self.backbone = models.resnet50(pretrained=pretrained)
            in_features = self.backbone.fc.in_features
            # 移除原始的全连接�?
            self.backbone = nn.Sequential(*list(self.backbone.children())[:-1])
        elif backbone == 'efficientnet_b0':
            self.backbone = models.efficientnet_b0(pretrained=pretrained)
            in_features = self.backbone.classifier[1].in_features
            # 移除原始的分类器
            self.backbone.classifier = nn.Identity()
        else:
            raise ValueError(f"Unsupported backbone: {backbone}")
        
        # 特征投影�?
        self.feature_projector = nn.Sequential(
            nn.Linear(in_features, feature_dim),
            nn.BatchNorm1d(feature_dim),
            nn.ReLU(inplace=True),
            nn.Dropout(0.2)
        )
        
        self.feature_dim = feature_dim
    
    def forward(self, x: torch.Tensor) -> torch.Tensor:
        """
        前向传播
        
        Args:
            x: 输入RGB图像 (B, 3, H, W)
            
        Returns:
            特征向量 (B, feature_dim)
        """
        # 提取特征
        features = self.backbone(x)
        
        # 展平特征
        if len(features.shape) == 4:
            features = features.view(features.size(0), -1)
        
        # 投影到指定维�?
        features = self.feature_projector(features)
        
        return features


class DWSeparableBlock(nn.Module):
    """深度可分离卷积块，带轻量残差"""

    def __init__(self, in_channels: int, out_channels: int, stride: int = 1, use_residual: bool = True):
        super().__init__()
        self.use_residual = use_residual and (stride == 1) and (in_channels == out_channels)

        # depthwise conv
        self.dw = nn.Conv2d(in_channels, in_channels, kernel_size=3, stride=stride,
                            padding=1, groups=in_channels, bias=False)
        self.dw_bn = nn.BatchNorm2d(in_channels)
        # pointwise conv
        self.pw = nn.Conv2d(in_channels, out_channels, kernel_size=1, bias=False)
        self.pw_bn = nn.BatchNorm2d(out_channels)
        self.relu = nn.ReLU(inplace=True)

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        out = self.dw(x)
        out = self.dw_bn(out)
        out = self.relu(out)
        out = self.pw(out)
        out = self.pw_bn(out)
        if self.use_residual:
            out = out + x
        out = self.relu(out)
        return out


def build_dw_sep_layers(in_channels: int, channels_list: list) -> list:
    """构建深度可分离卷积层序列，隔层下采样"""
    layers = []
    current = in_channels
    for i, out_ch in enumerate(channels_list):
        stride = 2 if i % 2 == 1 else 1  # 模拟原实现每两层一次下采样
        layers.append(DWSeparableBlock(current, out_ch, stride=stride, use_residual=True))
        current = out_ch
    return layers


class UVBranch(nn.Module):
    """UV色彩空间处理分支 - 专门设计的轻量级CNN"""
    
    def __init__(self,
                 input_channels: int = 2,
                 conv_layers: list = [32, 64, 128, 128],
                 feature_dim: int = 128):
        """
        初始化UV分支
        
        Args:
            input_channels: 输入通道数（UV�?通道�?
            conv_layers: 卷积层通道数列�?
            feature_dim: 输出特征维度
        """
        super(UVBranch, self).__init__()
        
        # 构建卷积�?
        layers = []
        in_channels = input_channels
        
        for i, out_channels in enumerate([]):  # replaced by build_dw_sep_layers
            layers.append(nn.Conv2d(in_channels, out_channels, 
                                   kernel_size=3, padding=1))
            layers.append(nn.BatchNorm2d(out_channels))
            layers.append(nn.ReLU(inplace=True))
            
            # 每两层添加一个池化层
            if i % 2 == 1:
                layers.append(nn.MaxPool2d(2, 2))
            
            in_channels = out_channels
        
        self.conv_layers = nn.Sequential(*build_dw_sep_layers(input_channels, conv_layers))
        
        # 全局平均池化
        self.global_pool = nn.AdaptiveAvgPool2d(1)
        
        # 特征投影�?
        self.feature_projector = nn.Sequential(
            nn.Linear(conv_layers[-1], feature_dim),
            nn.BatchNorm1d(feature_dim),
            nn.ReLU(inplace=True),
            nn.Dropout(0.2)
        )
        
        self.feature_dim = feature_dim
    
    def forward(self, x: torch.Tensor) -> torch.Tensor:
        """
        前向传播
        
        Args:
            x: 输入UV数据 (B, 2, H, W)
            
        Returns:
            特征向量 (B, feature_dim)
        """
        # 卷积特征提取
        features = self.conv_layers(x)
        
        # 全局池化
        features = self.global_pool(features)
        features = features.view(features.size(0), -1)
        
        # 投影到指定维�?
        features = self.feature_projector(features)
        
        return features


class FaceStream(nn.Module):
    """人脸�?- 融合RGB和UV特征"""
    
    def __init__(self, config: Dict):
        """
        初始化人脸流
        
        Args:
            config: 配置字典
        """
        super(FaceStream, self).__init__()
        
        face_config = config['MODEL']['face_stream']

        # UV 直方�?bin 数（U/V 方向统一使用该值）
        self.uv_hist_bins = int(face_config.get('uv_hist_bins', 32))\n        self.uv_hist_u_range = tuple(face_config.get('uv_hist_u_range', [0.0, 1.0]))\n        self.uv_hist_v_range = tuple(face_config.get('uv_hist_v_range', [0.0, 1.0]))
        
        # RGB分支
        self.rgb_branch = RGBBranch(
            backbone=face_config['rgb_backbone'],
            pretrained=face_config['rgb_pretrained'],
            feature_dim=face_config['rgb_feature_dim']
        )
        
        # UV分支
        self.uv_branch = UVBranch(
            input_channels=face_config['uv_channels'],
            conv_layers=face_config['uv_conv_layers'],
            feature_dim=face_config['uv_feature_dim']
        )
        
        # 特征融合
        total_dim = face_config['rgb_feature_dim'] + face_config['uv_feature_dim']
        self.fusion = nn.Sequential(
            nn.Linear(total_dim, 512),
            nn.BatchNorm1d(512),
            nn.ReLU(inplace=True),
            nn.Dropout(0.3),
            nn.Linear(512, 256),
            nn.BatchNorm1d(256),
            nn.ReLU(inplace=True)
        )
        
        self.output_dim = 256
    
    def forward(self, 
                face_rgb: torch.Tensor, 
                face_uv: torch.Tensor) -> torch.Tensor:
        """
        前向传播
        
        Args:
            face_rgb: RGB人脸图像 (B, 3, H, W)
            face_uv: UV人脸数据 (B, 2, H, W)
            
        Returns:
            融合特征 (B, 256)
        """
        # 提取RGB特征
        rgb_features = self.rgb_branch(face_rgb)
        
        # �?UV 特征图转换为二维直方图后再送入 UV 分支
        uv_hist = compute_uv_histogram(
            face_uv,
            num_bins_u=self.uv_hist_bins,
            num_bins_v=self.uv_hist_bins,
        )
        uv_features = self.uv_branch(uv_hist)
        
        # 拼接特征
        combined_features = torch.cat([rgb_features, uv_features], dim=1)
        
        # 融合特征
        fused_features = self.fusion(combined_features)
        
        return fused_features


class AttentiveFaceStream(nn.Module):
    """带注意力机制的人脸流 - 自适应融合RGB和UV特征"""
    
    def __init__(self, config: Dict):
        """
        初始化带注意力的人脸�?
        
        Args:
            config: 配置字典
        """
        super(AttentiveFaceStream, self).__init__()
        
        face_config = config['MODEL']['face_stream']

        # UV 直方�?bin 数（U/V 方向统一使用该值）
        self.uv_hist_bins = int(face_config.get('uv_hist_bins', 32))\n        self.uv_hist_u_range = tuple(face_config.get('uv_hist_u_range', [0.0, 1.0]))\n        self.uv_hist_v_range = tuple(face_config.get('uv_hist_v_range', [0.0, 1.0]))
        
        # RGB分支
        self.rgb_branch = RGBBranch(
            backbone=face_config['rgb_backbone'],
            pretrained=face_config['rgb_pretrained'],
            feature_dim=face_config['rgb_feature_dim']
        )
        
        # UV分支
        self.uv_branch = UVBranch(
            input_channels=face_config['uv_channels'],
            conv_layers=face_config['uv_conv_layers'],
            feature_dim=face_config['uv_feature_dim']
        )
        
        # 注意力权重生�?
        rgb_dim = face_config['rgb_feature_dim']
        uv_dim = face_config['uv_feature_dim']
        
        self.attention = nn.Sequential(
            nn.Linear(rgb_dim + uv_dim, 128),
            nn.ReLU(inplace=True),
            nn.Linear(128, 2),
            nn.Softmax(dim=1)
        )
        
        # 特征融合
        self.fusion = nn.Sequential(
            nn.Linear(rgb_dim + uv_dim, 512),
            nn.BatchNorm1d(512),
            nn.ReLU(inplace=True),
            nn.Dropout(0.3),
            nn.Linear(512, 256),
            nn.BatchNorm1d(256),
            nn.ReLU(inplace=True)
        )
        
        self.output_dim = 256
    
    def forward(self, 
                face_rgb: torch.Tensor, 
                face_uv: torch.Tensor) -> torch.Tensor:
        """
        前向传播
        
        Args:
            face_rgb: RGB人脸图像 (B, 3, H, W)
            face_uv: UV人脸数据 (B, 2, H, W)
            
        Returns:
            融合特征 (B, 256)
        """
        # 提取RGB特征
        rgb_features = self.rgb_branch(face_rgb)
        
        # �?UV 特征图转换为二维直方图后再送入 UV 分支
        uv_hist = compute_uv_histogram(
            face_uv,
            num_bins_u=self.uv_hist_bins,
            num_bins_v=self.uv_hist_bins,
        )
        uv_features = self.uv_branch(uv_hist)
        
        # 计算注意力权�?
        combined = torch.cat([rgb_features, uv_features], dim=1)
        attention_weights = self.attention(combined)
        
        # 加权融合
        weighted_rgb = rgb_features * attention_weights[:, 0:1]
        weighted_uv = uv_features * attention_weights[:, 1:2]
        
        # 拼接加权特征
        weighted_features = torch.cat([weighted_rgb, weighted_uv], dim=1)
        
        # 最终融�?
        fused_features = self.fusion(weighted_features)
        
        return fused_features



