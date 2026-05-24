"""
简化的推理测试脚本 - 用于测试模型加载和推理流程
不需要完整数据集，使用随机数据测试
"""
import sys
from pathlib import Path
import torch
import numpy as np

# 添加项目路径
project_root = Path(__file__).parent / "facial_preference"
sys.path.insert(0, str(project_root))

print("=" * 80)
print("DeepSkin 模型推理测试")
print("=" * 80)

# 1. 检查模型文件
checkpoint_path = Path(__file__).parent / "facial_preference_cloud/output/predict_p/checkpoints/best_model.pth"
print(f"\n1. 检查模型文件: {checkpoint_path}")
if not checkpoint_path.exists():
    print(f"   ❌ 模型文件不存在")
    sys.exit(1)
print(f"   ✓ 模型文件存在 ({checkpoint_path.stat().st_size / 1024 / 1024:.1f} MB)")

# 2. 加载模型检查点
print("\n2. 加载模型检查点...")
try:
    device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
    print(f"   使用设备: {device}")

    checkpoint = torch.load(checkpoint_path, map_location=device)
    print(f"   ✓ 检查点加载成功")
    print(f"   检查点包含的键: {list(checkpoint.keys())}")

    if 'epoch' in checkpoint:
        print(f"   训练轮次: {checkpoint['epoch']}")
    if 'config' in checkpoint:
        print(f"   配置信息: 存在")
        config = checkpoint['config']
    else:
        print(f"   ⚠️  配置信息缺失，使用默认配置")
        from config import Config
        config = Config.get_config_dict()

except Exception as e:
    print(f"   ❌ 加载失败: {e}")
    sys.exit(1)

# 3. 创建模型
print("\n3. 创建模型...")
try:
    from models import create_model

    model = create_model(config, model_type='full')
    print(f"   ✓ 模型创建成功")

    # 加载权重
    model.load_state_dict(checkpoint['model_state_dict'])
    model = model.to(device)
    model.eval()
    print(f"   ✓ 模型权重加载成功")

    # 统计参数量
    total_params = sum(p.numel() for p in model.parameters())
    trainable_params = sum(p.numel() for p in model.parameters() if p.requires_grad)
    print(f"   总参数量: {total_params / 1e6:.2f}M")
    print(f"   可训练参数: {trainable_params / 1e6:.2f}M")

except Exception as e:
    print(f"   ❌ 模型创建失败: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)

# 4. 测试推理（使用随机数据）
print("\n4. 测试推理（使用随机数据）...")
try:
    batch_size = 2

    # 创建随机输入数据
    face_rgb = torch.randn(batch_size, 3, 224, 224).to(device)
    face_uv = torch.randn(batch_size, 2, 224, 224).to(device)
    global_rgb = torch.randn(batch_size, 3, 224, 224).to(device)

    print(f"   输入形状:")
    print(f"     - face_rgb: {face_rgb.shape}")
    print(f"     - face_uv: {face_uv.shape}")
    print(f"     - global_rgb: {global_rgb.shape}")

    # 推理
    with torch.no_grad():
        pred_score, pred_center = model(face_rgb, face_uv, global_rgb)

    print(f"\n   输出形状:")
    print(f"     - preference_score: {pred_score.shape}")
    print(f"     - preference_center (a*b*): {pred_center.shape}")

    print(f"\n   ✓ 推理成功！")
    print(f"\n   示例输出:")
    for i in range(batch_size):
        score = torch.sigmoid(pred_score[i]).item()
        a_star = pred_center[i, 0].item()
        b_star = pred_center[i, 1].item()
        print(f"     样本 {i+1}:")
        print(f"       喜好度评分: {score:.4f}")
        print(f"       喜好中心 (a*, b*): ({a_star:.2f}, {b_star:.2f})")

except Exception as e:
    print(f"   ❌ 推理失败: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)

# 5. 测试模型各个组件
print("\n5. 测试模型组件...")
try:
    print(f"   模型结构:")
    if hasattr(model, 'face_stream'):
        print(f"     ✓ face_stream (人脸流)")
    if hasattr(model, 'global_stream'):
        print(f"     ✓ global_stream (全局流)")
    if hasattr(model, 'stat_stream'):
        print(f"     ✓ stat_stream (统计流)")
    if hasattr(model, 'fusion'):
        print(f"     ✓ fusion (融合模块)")
    if hasattr(model, 'prediction_head'):
        print(f"     ✓ prediction_head (预测头)")

except Exception as e:
    print(f"   ⚠️  组件检查失败: {e}")

print("\n" + "=" * 80)
print("✓ 所有测试通过！模型可以正常加载和推理")
print("=" * 80)
print("\n注意: 这是使用随机数据的测试，实际推理需要真实的图像和UV数据")
print("数据格式要求:")
print("  - face_rgb: 人脸RGB图像 (224x224)")
print("  - face_uv: 人脸UV色度数据 (2通道, 224x224)")
print("  - global_rgb: 全局场景图像 (224x224)")
