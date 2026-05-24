"""
统计特征流模块
提取场景统计特征，包括亮度信息、场景类别和色温
"""

import torch
import torch.nn as nn


class StatisticalStream(nn.Module):
    """
    统计特征流
    处理场景统计信息，包括亮度、场景类别和色温
    """
    
    def __init__(self, output_dim=64):
        """
        初始化统计特征流
        
        Args:
            output_dim: 输出特征维度
        """
        super().__init__()
        
        # 输入特征维度：
        # - 场景亮度信息：5维（平均亮度、标准差、10%分位数、50%分位数、90%分位数）
        # - 场景类别：2维（one-hot编码：室内/室外）
        # - 色温估计：1维
        # 总计：8维
        input_dim = 8
        
        # 特征提取网络
        self.feature_extractor = nn.Sequential(
            nn.Linear(input_dim, 32),
            nn.BatchNorm1d(32),
            nn.ReLU(inplace=True),
            nn.Dropout(0.2),
            
            nn.Linear(32, 64),
            nn.BatchNorm1d(64),
            nn.ReLU(inplace=True),
            nn.Dropout(0.2),
            
            nn.Linear(64, output_dim),
            nn.BatchNorm1d(output_dim),
            nn.ReLU(inplace=True)
        )
        
        # 初始化权重
        self._initialize_weights()
    
    def _initialize_weights(self):
        """初始化网络权重"""
        for m in self.modules():
            if isinstance(m, nn.Linear):
                nn.init.xavier_uniform_(m.weight)
                if m.bias is not None:
                    nn.init.constant_(m.bias, 0)
            elif isinstance(m, nn.BatchNorm1d):
                nn.init.constant_(m.weight, 1)
                nn.init.constant_(m.bias, 0)
    
    def forward(self, scene_brightness, scene_category, color_temperature):
        """
        前向传播
        
        Args:
            scene_brightness: 场景亮度统计信息 [batch_size, 5]
                - dim 0: 平均亮度
                - dim 1: 亮度标准差
                - dim 2: 10%分位数
                - dim 3: 50%分位数（中位数）
                - dim 4: 90%分位数
            scene_category: 场景类别 [batch_size, 2] (one-hot编码)
            color_temperature: 色温估计 [batch_size, 1]
        
        Returns:
            统计特征 [batch_size, output_dim]
        """
        # 确保输入维度正确
        batch_size = scene_brightness.shape[0]
        
        # 如果色温是标量，扩展维度
        if color_temperature.dim() == 1:
            color_temperature = color_temperature.unsqueeze(1)
        
        # 拼接所有统计特征
        statistical_features = torch.cat([
            scene_brightness,      # [batch_size, 5]
            scene_category,        # [batch_size, 2]
            color_temperature      # [batch_size, 1]
        ], dim=1)  # [batch_size, 8]
        
        # 通过特征提取网络
        features = self.feature_extractor(statistical_features)
        
        return features


class BrightnessExtractor:
    """
    亮度信息提取器
    从图像中提取亮度统计信息
    """
    
    @staticmethod
    def extract_brightness_stats(image):
        """
        提取图像的亮度统计信息
        
        Args:
            image: RGB图像张量 [batch_size, 3, H, W] 或 [3, H, W]
        
        Returns:
            亮度统计信息 [batch_size, 5] 或 [5]
        """
        # 处理单张图像的情况
        single_image = False
        if image.dim() == 3:
            single_image = True
            image = image.unsqueeze(0)
        
        batch_size = image.shape[0]
        
        # 转换为灰度图像（亮度）
        # Y = 0.299*R + 0.587*G + 0.114*B
        brightness = 0.299 * image[:, 0] + 0.587 * image[:, 1] + 0.114 * image[:, 2]
        
        # 展平每张图像
        brightness_flat = brightness.view(batch_size, -1)
        
        # 计算统计信息
        stats = []
        for i in range(batch_size):
            img_brightness = brightness_flat[i]
            
            # 计算各种统计量
            mean_val = img_brightness.mean()
            std_val = img_brightness.std()
            
            # 计算分位数
            sorted_brightness, _ = torch.sort(img_brightness)
            n = len(sorted_brightness)
            
            # 10%, 50%, 90%分位数
            percentile_10 = sorted_brightness[int(n * 0.1)]
            percentile_50 = sorted_brightness[int(n * 0.5)]  # 中位数
            percentile_90 = sorted_brightness[int(n * 0.9)]
            
            img_stats = torch.tensor([
                mean_val,
                std_val,
                percentile_10,
                percentile_50,
                percentile_90
            ])
            stats.append(img_stats)
        
        result = torch.stack(stats)
        
        # 如果输入是单张图像，返回单个向量
        if single_image:
            result = result.squeeze(0)
        
        return result


class SceneClassifier:
    """
    场景分类器
    判断图像是室内还是室外场景
    """
    
    def __init__(self):
        """初始化场景分类器"""
        # 这里可以加载预训练的场景分类模型
        # 为了简化，我们使用基于亮度和色彩统计的简单规则
        pass
    
    @staticmethod
    def classify_scene(image, brightness_stats=None):
        """
        对场景进行分类（室内/室外）
        
        Args:
            image: RGB图像张量 [batch_size, 3, H, W] 或 [3, H, W]
            brightness_stats: 预计算的亮度统计信息（可选）
        
        Returns:
            场景类别的one-hot编码 [batch_size, 2] 或 [2]
            - [1, 0]: 室内
            - [0, 1]: 室外
        """
        # 处理单张图像的情况
        single_image = False
        if image.dim() == 3:
            single_image = True
            image = image.unsqueeze(0)
        
        batch_size = image.shape[0]
        
        # 如果没有提供亮度统计，则计算
        if brightness_stats is None:
            brightness_stats = BrightnessExtractor.extract_brightness_stats(image)
        
        # 简单的启发式规则（实际应用中应使用训练好的分类器）
        # 室外场景通常：
        # 1. 平均亮度较高
        # 2. 亮度分布更均匀（标准差较小）
        # 3. 高亮度区域较多（90%分位数较高）
        
        scene_categories = []
        for i in range(batch_size):
            stats = brightness_stats[i]
            mean_brightness = stats[0]
            std_brightness = stats[1]
            percentile_90 = stats[4]
            
            # 简单的阈值判断
            # 这些阈值应该通过实验确定
            is_outdoor = (
                mean_brightness > 0.5 and
                percentile_90 > 0.7
            ) or (
                mean_brightness > 0.4 and
                std_brightness < 0.3
            )
            
            if is_outdoor:
                category = torch.tensor([0.0, 1.0])  # 室外
            else:
                category = torch.tensor([1.0, 0.0])  # 室内
            
            scene_categories.append(category)
        
        result = torch.stack(scene_categories)
        
        # 如果输入是单张图像，返回单个向量
        if single_image:
            result = result.squeeze(0)
        
        return result


if __name__ == "__main__":
    """测试统计特征流"""
    
    # 创建测试数据
    batch_size = 4
    scene_brightness = torch.randn(batch_size, 5)
    scene_category = torch.tensor([
        [1, 0],  # 室内
        [0, 1],  # 室外
        [1, 0],  # 室内
        [0, 1],  # 室外
    ], dtype=torch.float32)
    color_temperature = torch.randn(batch_size, 1) * 1000 + 5500  # 色温范围约4500-6500K
    
    # 创建模型
    model = StatisticalStream(output_dim=64)
    
    # 前向传播
    output = model(scene_brightness, scene_category, color_temperature)
    
    print(f"输入形状:")
    print(f"  场景亮度: {scene_brightness.shape}")
    print(f"  场景类别: {scene_category.shape}")
    print(f"  色温: {color_temperature.shape}")
    print(f"输出形状: {output.shape}")
    
    # 测试亮度提取器
    test_image = torch.randn(batch_size, 3, 224, 224)
    brightness_stats = BrightnessExtractor.extract_brightness_stats(test_image)
    print(f"\n亮度统计信息形状: {brightness_stats.shape}")
    
    # 测试场景分类器
    scene_classes = SceneClassifier.classify_scene(test_image, brightness_stats)
    print(f"场景分类结果形状: {scene_classes.shape}")