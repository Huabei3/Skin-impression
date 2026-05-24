"""
简化的推理脚本 - 使用OPPO数据集测试DeepSkin模型
"""
import sys
from pathlib import Path

# 添加项目路径
project_root = Path(__file__).parent / "facial_preference"
sys.path.insert(0, str(project_root))

print("=" * 80)
print("DeepSkin 模型推理测试 - OPPO数据集")
print("=" * 80)

# 1. 加载配置
print("\n1. 加载配置...")
try:
    from inference_config import InferenceConfig
    InferenceConfig.print_config()

    if not InferenceConfig.validate():
        print("\n❌ 配置验证失败，请检查数据路径")
        sys.exit(1)
except Exception as e:
    print(f"❌ 配置加载失败: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)

# 2. 检查依赖
print("\n2. 检查依赖...")
try:
    import torch
    import numpy as np
    import pandas as pd
    from PIL import Image
    print(f"  ✓ PyTorch版本: {torch.__version__}")
    print(f"  ✓ CUDA可用: {torch.cuda.is_available()}")
    if torch.cuda.is_available():
        print(f"  ✓ CUDA设备: {torch.cuda.get_device_name(0)}")
except ImportError as e:
    print(f"  ❌ 缺少依赖: {e}")
    print("\n请安装依赖:")
    print("  pip install torch torchvision numpy pandas pillow openpyxl")
    sys.exit(1)

# 3. 加载模型
print("\n3. 加载模型...")
try:
    device = torch.device(InferenceConfig.DEVICE if torch.cuda.is_available() else 'cpu')
    print(f"  使用设备: {device}")

    checkpoint = torch.load(InferenceConfig.CHECKPOINT_PATH, map_location=device)
    print(f"  ✓ 检查点加载成功")

    if 'epoch' in checkpoint:
        print(f"  训练轮次: {checkpoint['epoch']}")

    # 获取配置
    if 'config' in checkpoint:
        model_config = checkpoint['config']
        print(f"  ✓ 模型配置已加载")
    else:
        print(f"  ⚠️  使用默认配置")
        from config import Config
        model_config = Config.get_config_dict()

    # 创建模型
    from models import create_model
    model = create_model(model_config, model_type='full')
    model.load_state_dict(checkpoint['model_state_dict'])
    model = model.to(device)
    model.eval()
    print(f"  ✓ 模型加载成功")

    # 统计参数
    total_params = sum(p.numel() for p in model.parameters())
    print(f"  总参数量: {total_params / 1e6:.2f}M")

except Exception as e:
    print(f"  ❌ 模型加载失败: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)

# 4. 加载数据集
print("\n4. 加载数据集...")
try:
    from data.dataset import FacialPreferenceDataset, get_data_transforms

    # 获取数据变换
    test_transform = get_data_transforms(model_config, split='test')

    # 创建测试数据集
    test_dataset = FacialPreferenceDataset(
        face_rgb_root=InferenceConfig.FACE_RGB_ROOT,
        face_uv_root=InferenceConfig.FACE_UV_ROOT,
        gt_excel_path=InferenceConfig.GT_EXCEL_PATH,
        split='test',
        transform=test_transform,
        seed=InferenceConfig.RANDOM_SEED,
        train_ratio=InferenceConfig.TRAIN_RATIO,
        val_ratio=InferenceConfig.VAL_RATIO,
        test_ratio=InferenceConfig.TEST_RATIO,
        global_rgb_root=InferenceConfig.GLOBAL_RGB_ROOT,
        allowed_scenes=InferenceConfig.ALLOWED_SCENES
    )

    print(f"  ✓ 测试集样本数: {len(test_dataset)}")

    if len(test_dataset) == 0:
        print("  ❌ 测试集为空，请检查数据路径和场景设置")
        sys.exit(1)

except Exception as e:
    print(f"  ❌ 数据集加载失败: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)

# 5. 测试推理（前5个样本）
print("\n5. 测试推理（前5个样本）...")
try:
    from torch.utils.data import DataLoader

    # 创建数据加载器
    test_loader = DataLoader(
        test_dataset,
        batch_size=min(5, len(test_dataset)),
        shuffle=False,
        num_workers=0
    )

    # 获取一个批次
    batch = next(iter(test_loader))

    face_rgb = batch['face_rgb'].to(device)
    face_uv = batch['face_uv'].to(device)
    global_rgb = batch['global_rgb'].to(device) if 'global_rgb' in batch else None
    true_score = batch['preference_score']
    true_center = batch['preference_center']

    print(f"  输入形状:")
    print(f"    - face_rgb: {face_rgb.shape}")
    print(f"    - face_uv: {face_uv.shape}")
    if global_rgb is not None:
        print(f"    - global_rgb: {global_rgb.shape}")

    # 推理
    with torch.no_grad():
        if global_rgb is not None:
            pred_score, pred_center = model(face_rgb, face_uv, global_rgb)
        else:
            pred_score, pred_center = model(face_rgb, face_uv)

    print(f"\n  ✓ 推理成功！")
    print(f"\n  预测结果对比:")
    print(f"  {'样本':<6} {'真实评分':<10} {'预测评分':<10} {'真实a*':<10} {'预测a*':<10} {'真实b*':<10} {'预测b*':<10}")
    print(f"  {'-'*70}")

    for i in range(min(5, len(true_score))):
        true_s = true_score[i].item()
        pred_s = torch.sigmoid(pred_score[i]).item()
        true_a = true_center[i, 0].item()
        pred_a = pred_center[i, 0].item()
        true_b = true_center[i, 1].item()
        pred_b = pred_center[i, 1].item()

        print(f"  {i+1:<6} {true_s:<10.4f} {pred_s:<10.4f} {true_a:<10.2f} {pred_a:<10.2f} {true_b:<10.2f} {pred_b:<10.2f}")

except Exception as e:
    print(f"  ❌ 推理失败: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)

# 6. 完整测试集评估（可选）
print("\n6. 是否进行完整测试集评估？")
print("  这将对所有测试样本进行推理并计算指标...")
print("  (按Ctrl+C跳过)")

try:
    import time
    time.sleep(3)

    print("\n  开始完整评估...")

    from scipy.stats import pearsonr, spearmanr

    all_true_scores = []
    all_pred_scores = []
    all_true_centers = []
    all_pred_centers = []

    test_loader_full = DataLoader(
        test_dataset,
        batch_size=InferenceConfig.BATCH_SIZE,
        shuffle=False,
        num_workers=InferenceConfig.NUM_WORKERS
    )

    with torch.no_grad():
        for batch in test_loader_full:
            face_rgb = batch['face_rgb'].to(device)
            face_uv = batch['face_uv'].to(device)
            global_rgb = batch['global_rgb'].to(device) if 'global_rgb' in batch else None

            if global_rgb is not None:
                pred_score, pred_center = model(face_rgb, face_uv, global_rgb)
            else:
                pred_score, pred_center = model(face_rgb, face_uv)

            # 收集结果
            all_true_scores.extend(batch['preference_score'].cpu().numpy())
            all_pred_scores.extend(torch.sigmoid(pred_score).cpu().numpy())
            all_true_centers.extend(batch['preference_center'].cpu().numpy())
            all_pred_centers.extend(pred_center.cpu().numpy())

    # 转换为numpy数组
    all_true_scores = np.array(all_true_scores).flatten()
    all_pred_scores = np.array(all_pred_scores).flatten()
    all_true_centers = np.array(all_true_centers)
    all_pred_centers = np.array(all_pred_centers)

    # 计算指标
    pc, _ = pearsonr(all_true_scores, all_pred_scores)
    srcc, _ = spearmanr(all_true_scores, all_pred_scores)
    mae = np.mean(np.abs(all_true_scores - all_pred_scores))
    rmse = np.sqrt(np.mean((all_true_scores - all_pred_scores) ** 2))

    # LAB中心的MAE
    center_mae = np.mean(np.abs(all_true_centers - all_pred_centers), axis=0)

    print(f"\n  ✓ 评估完成！")
    print(f"\n  评估指标:")
    print(f"    喜好度评分:")
    print(f"      - Pearson Correlation (PC): {pc:.4f}")
    print(f"      - Spearman Correlation (SRCC): {srcc:.4f}")
    print(f"      - Mean Absolute Error (MAE): {mae:.4f}")
    print(f"      - Root Mean Square Error (RMSE): {rmse:.4f}")
    print(f"    LAB色彩中心:")
    print(f"      - a* MAE: {center_mae[0]:.2f}")
    print(f"      - b* MAE: {center_mae[1]:.2f}")

    # 保存结果
    InferenceConfig.OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    results_file = InferenceConfig.OUTPUT_DIR / "test_results.txt"

    with open(results_file, 'w') as f:
        f.write("DeepSkin 测试集评估结果\n")
        f.write("=" * 80 + "\n\n")
        f.write(f"测试样本数: {len(all_true_scores)}\n\n")
        f.write(f"喜好度评分指标:\n")
        f.write(f"  PC: {pc:.4f}\n")
        f.write(f"  SRCC: {srcc:.4f}\n")
        f.write(f"  MAE: {mae:.4f}\n")
        f.write(f"  RMSE: {rmse:.4f}\n\n")
        f.write(f"LAB色彩中心指标:\n")
        f.write(f"  a* MAE: {center_mae[0]:.2f}\n")
        f.write(f"  b* MAE: {center_mae[1]:.2f}\n")

    print(f"\n  结果已保存到: {results_file}")

except KeyboardInterrupt:
    print("\n  ⚠️  跳过完整评估")
except Exception as e:
    print(f"\n  ⚠️  完整评估失败: {e}")
    import traceback
    traceback.print_exc()

print("\n" + "=" * 80)
print("✓ 推理测试完成！")
print("=" * 80)
