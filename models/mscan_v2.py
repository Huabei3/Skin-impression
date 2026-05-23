import torch
import torch.nn as nn
import torch.nn.functional as F
import torchvision.models as models
import yaml
from .modules import (
    SkinRegionAttention,
    ColorSpaceBranch,
    SkinStatisticsModule,
    MultiTaskHead,
    SkinRenderingModule
)


class MultiScaleFeatureExtractor(nn.Module):
    """Multi-scale feature extraction using different kernel sizes"""
    def __init__(self, in_channels, out_channels):
        super(MultiScaleFeatureExtractor, self).__init__()

        # Different scale convolutions
        self.conv1x1 = nn.Conv2d(in_channels, out_channels // 4, kernel_size=1)
        self.conv3x3 = nn.Conv2d(in_channels, out_channels // 4, kernel_size=3, padding=1)
        self.conv5x5 = nn.Conv2d(in_channels, out_channels // 4, kernel_size=5, padding=2)
        self.conv7x7 = nn.Conv2d(in_channels, out_channels // 4, kernel_size=7, padding=3)

        self.bn = nn.BatchNorm2d(out_channels)
        self.relu = nn.ReLU(inplace=True)

    def forward(self, x):
        x1 = self.conv1x1(x)
        x2 = self.conv3x3(x)
        x3 = self.conv5x5(x)
        x4 = self.conv7x7(x)

        out = torch.cat([x1, x2, x3, x4], dim=1)
        out = self.bn(out)
        out = self.relu(out)

        return out


class EfficientCrossAttention(nn.Module):
    """Memory-efficient cross-attention with spatial downsampling"""
    def __init__(self, dim, num_heads=8, downsample_ratio=4):
        super(EfficientCrossAttention, self).__init__()
        self.num_heads = num_heads
        self.dim = dim
        self.head_dim = dim // num_heads
        self.downsample_ratio = downsample_ratio

        assert self.head_dim * num_heads == dim, "dim must be divisible by num_heads"

        self.query = nn.Linear(dim, dim)
        self.key = nn.Linear(dim, dim)
        self.value = nn.Linear(dim, dim)

        self.out_proj = nn.Linear(dim, dim)
        self.dropout = nn.Dropout(0.1)

    def forward(self, x1, x2):
        B, C, H, W = x1.shape

        # Downsample spatial dimensions to reduce memory
        H_down = max(H // self.downsample_ratio, 4)
        W_down = max(W // self.downsample_ratio, 4)

        x1_down = F.adaptive_avg_pool2d(x1, (H_down, W_down))
        x2_down = F.adaptive_avg_pool2d(x2, (H_down, W_down))

        # Reshape to (B, H*W, C)
        x1_flat = x1_down.view(B, C, -1).permute(0, 2, 1)
        x2_flat = x2_down.view(B, C, -1).permute(0, 2, 1)

        # Generate Q, K, V
        Q = self.query(x1_flat).view(B, -1, self.num_heads, self.head_dim).transpose(1, 2)
        K = self.key(x2_flat).view(B, -1, self.num_heads, self.head_dim).transpose(1, 2)
        V = self.value(x2_flat).view(B, -1, self.num_heads, self.head_dim).transpose(1, 2)

        # Attention scores
        attn_scores = torch.matmul(Q, K.transpose(-2, -1)) / (self.head_dim ** 0.5)
        attn_probs = F.softmax(attn_scores, dim=-1)
        attn_probs = self.dropout(attn_probs)

        # Apply attention to values
        attn_output = torch.matmul(attn_probs, V)
        attn_output = attn_output.transpose(1, 2).contiguous().view(B, -1, self.dim)

        # Output projection
        output = self.out_proj(attn_output)
        output = output.permute(0, 2, 1).view(B, C, H_down, W_down)

        # Upsample back to original size
        output = F.interpolate(output, size=(H, W), mode='bilinear', align_corners=False)

        return output


class MSCAN_v2(nn.Module):
    """
    Improved Multi-Scale Cross-Attention Network with modular components
    """
    def __init__(self, config=None, pretrained=True):
        super(MSCAN_v2, self).__init__()

        # Load config
        if config is None:
            config = {}
        self.config = config
        self.modules_config = config.get('modules', {})

        # Backbone: ResNet50
        resnet = models.resnet50(pretrained=pretrained)
        self.conv1 = resnet.conv1
        self.bn1 = resnet.bn1
        self.relu = resnet.relu
        self.maxpool = resnet.maxpool

        self.layer1 = resnet.layer1  # 256 channels
        self.layer2 = resnet.layer2  # 512 channels
        self.layer3 = resnet.layer3  # 1024 channels
        self.layer4 = resnet.layer4  # 2048 channels

        # ① 肤色区域注意力
        if self.modules_config.get('skin_region_attention', {}).get('enabled', False):
            method = self.modules_config['skin_region_attention'].get('method', 'hsv_threshold')
            self.skin_attention = SkinRegionAttention(method=method)
        else:
            self.skin_attention = None

        # ② 色彩空间多分支
        if self.modules_config.get('color_space_branches', {}).get('enabled', False):
            # TODO: 实现多分支架构
            self.use_lab_branch = 'lab' in self.modules_config['color_space_branches'].get('branches', [])
        else:
            self.use_lab_branch = False

        # Multi-scale feature extractors
        self.ms_feat1 = MultiScaleFeatureExtractor(256, 256)
        self.ms_feat2 = MultiScaleFeatureExtractor(512, 512)
        self.ms_feat3 = MultiScaleFeatureExtractor(1024, 1024)
        self.ms_feat4 = MultiScaleFeatureExtractor(2048, 2048)

        # Efficient cross-attention modules
        self.cross_attn1 = EfficientCrossAttention(256, num_heads=8, downsample_ratio=4)
        self.cross_attn2 = EfficientCrossAttention(512, num_heads=8, downsample_ratio=4)
        self.cross_attn3 = EfficientCrossAttention(1024, num_heads=8, downsample_ratio=4)

        # ③ 肤色统计特征
        if self.modules_config.get('skin_statistics', {}).get('enabled', False):
            feature_dim = self.modules_config['skin_statistics'].get('feature_dim', 64)
            self.skin_stats = SkinStatisticsModule(feature_dim=feature_dim)
            fusion_dim = 256 + 512 + 1024 + 2048 + feature_dim
        else:
            self.skin_stats = None
            fusion_dim = 256 + 512 + 1024 + 2048

        # Feature fusion
        self.fusion_conv = nn.Sequential(
            nn.Conv2d(fusion_dim, 1024, kernel_size=1),
            nn.BatchNorm2d(1024),
            nn.ReLU(inplace=True),
            nn.Dropout(0.5)
        )

        # Global average pooling
        self.gap = nn.AdaptiveAvgPool2d(1)

        # ⑤ 多任务头
        if self.modules_config.get('multi_task', {}).get('enabled', False):
            tasks_config = self.modules_config['multi_task'].get('tasks', {})
            self.head = MultiTaskHead(in_features=1024, tasks_config=tasks_config)
            self.use_multi_task = True
        else:
            # 单任务回归头
            self.head = nn.Sequential(
                nn.Linear(1024, 512),
                nn.ReLU(inplace=True),
                nn.Dropout(0.5),
                nn.Linear(512, 128),
                nn.ReLU(inplace=True),
                nn.Dropout(0.3),
                nn.Linear(128, 1)
            )
            self.use_multi_task = False

        # ⑥ 肤色渲染模块（推理时使用）
        if self.modules_config.get('skin_rendering', {}).get('enabled', False):
            self.renderer = SkinRenderingModule()
        else:
            self.renderer = None

    def forward(self, x, return_intermediate=False):
        """
        x: [B, 3, H, W] RGB图像
        return_intermediate: 是否返回中间结果（用于可视化）
        """
        intermediate = {}

        # ① 肤色区域注意力
        skin_mask = None
        if self.skin_attention is not None:
            x, skin_mask = self.skin_attention(x)
            intermediate['skin_mask'] = skin_mask

        # Backbone feature extraction
        x = self.conv1(x)
        x = self.bn1(x)
        x = self.relu(x)
        x = self.maxpool(x)

        x1 = self.layer1(x)   # [B, 256, H/4, W/4]
        x2 = self.layer2(x1)  # [B, 512, H/8, W/8]
        x3 = self.layer3(x2)  # [B, 1024, H/16, W/16]
        x4 = self.layer4(x3)  # [B, 2048, H/32, W/32]

        # Multi-scale feature extraction
        ms1 = self.ms_feat1(x1)
        ms2 = self.ms_feat2(x2)
        ms3 = self.ms_feat3(x3)
        ms4 = self.ms_feat4(x4)

        # Cross-attention between adjacent scales
        attn1 = self.cross_attn1(ms1, F.interpolate(ms2, size=ms1.shape[2:], mode='bilinear', align_corners=False))
        attn2 = self.cross_attn2(ms2, F.interpolate(ms3, size=ms2.shape[2:], mode='bilinear', align_corners=False))
        attn3 = self.cross_attn3(ms3, F.interpolate(ms4, size=ms3.shape[2:], mode='bilinear', align_corners=False))

        # Resize all features to the same size
        target_size = attn3.shape[2:]
        attn1_up = F.interpolate(attn1, size=target_size, mode='bilinear', align_corners=False)
        attn2_up = F.interpolate(attn2, size=target_size, mode='bilinear', align_corners=False)
        ms4_down = F.interpolate(ms4, size=target_size, mode='bilinear', align_corners=False)

        # Concatenate all features
        fused = torch.cat([attn1_up, attn2_up, attn3, ms4_down], dim=1)

        # ③ 添加肤色统计特征
        if self.skin_stats is not None and skin_mask is not None:
            # 需要原始输入图像，这里简化处理
            # 实际应该保存原始输入
            pass

        # Feature fusion
        fused = self.fusion_conv(fused)

        # Global pooling
        pooled = self.gap(fused)
        pooled = pooled.view(pooled.size(0), -1)

        # Prediction
        if self.use_multi_task:
            outputs = self.head(pooled)
            if return_intermediate:
                outputs['intermediate'] = intermediate
            return outputs
        else:
            output = self.head(pooled)
            if return_intermediate:
                return output, intermediate
            return output


def load_model_from_config(config_path, pretrained=True):
    """从配置文件加载模型"""
    with open(config_path, 'r') as f:
        config = yaml.safe_load(f)

    model = MSCAN_v2(config=config, pretrained=pretrained)
    return model, config
