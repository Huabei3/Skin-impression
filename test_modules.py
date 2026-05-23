import torch
import yaml
from models.modules import SkinRegionAttention, SkinStatisticsModule, MultiTaskHead

# 测试肤色区域注意力
print('Testing SkinRegionAttention...')
skin_attn = SkinRegionAttention(method='hsv_threshold')
x = torch.randn(2, 3, 224, 224)  # 模拟输入
x_attn, mask = skin_attn(x)
print(f'Input shape: {x.shape}')
print(f'Output shape: {x_attn.shape}')
print(f'Mask shape: {mask.shape}')
print('✓ SkinRegionAttention works!\n')

# 测试肤色统计特征
print('Testing SkinStatisticsModule...')
skin_stats = SkinStatisticsModule(feature_dim=64)
stats_feat, mean_color = skin_stats(x, mask)
print(f'Stats features shape: {stats_feat.shape}')
print(f'Mean color shape: {mean_color.shape}')
print(f'Mean color example: {mean_color[0]}')
print('✓ SkinStatisticsModule works!\n')

# 测试多任务头
print('Testing MultiTaskHead...')
tasks_config = {
    'preference_score': {'enabled': True},
    'preference_center': {'enabled': True}
}
head = MultiTaskHead(in_features=1024, tasks_config=tasks_config)
features = torch.randn(2, 1024)
outputs = head(features)
print(f'Outputs keys: {outputs.keys()}')
print(f'Score shape: {outputs["preference_score"].shape}')
print(f'Center shape: {outputs["preference_center"].shape}')
print('✓ MultiTaskHead works!\n')

print('All modules tested successfully!')
