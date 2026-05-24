"""
测试数据加载（不依赖 PyTorch）
验证数据集路径、文件结构和 GT 标注是否正确
"""

import os
import sys
from pathlib import Path

# 添加项目路径
project_root = Path(__file__).parent
sys.path.insert(0, str(project_root / 'facial_preference'))

print("=" * 80)
print("DeepSkin 数据加载测试（无需 PyTorch）")
print("=" * 80)

# 1. 验证路径
print("\n1. 验证数据路径...")
data_root = Path("Z:/homes/Max/deepskin/OPPOskinExpe")
face_rgb_dir = data_root / "rendered_face"
face_uv_dir = data_root / "rendered_face_uv"
global_rgb_dir = data_root / "rendered"
gt_file = data_root / "oppo_preference_gt.xlsx"

paths = {
    "数据根目录": data_root,
    "人脸RGB": face_rgb_dir,
    "人脸UV": face_uv_dir,
    "全局RGB": global_rgb_dir,
    "GT标注": gt_file
}

all_exist = True
for name, path in paths.items():
    exists = path.exists()
    status = "OK" if exists else "FAIL"
    print(f"  [{status}] {name}: {path}")
    if not exists:
        all_exist = False

if not all_exist:
    print("\n[错误] 部分路径不存在，请检查数据集是否正确挂载")
    sys.exit(1)

# 2. 检查文件数量
print("\n2. 检查数据文件...")
try:
    face_rgb_files = list(face_rgb_dir.glob("*.png"))
    face_uv_files = list(face_uv_dir.glob("*.png"))
    global_rgb_files = list(global_rgb_dir.glob("*.png"))

    print(f"  人脸RGB图像: {len(face_rgb_files)} 个")
    print(f"  人脸UV图像: {len(face_uv_files)} 个")
    print(f"  全局RGB图像: {len(global_rgb_files)} 个")

    if len(face_rgb_files) == 0:
        print("\n[警告] 未找到人脸RGB图像文件")
except Exception as e:
    print(f"\n[错误] 读取文件列表失败: {e}")
    sys.exit(1)

# 3. 读取 GT 标注
print("\n3. 读取 GT 标注文件...")
try:
    import pandas as pd
    df = pd.read_excel(gt_file)
    print(f"  标注样本数: {len(df)}")
    print(f"  列名: {list(df.columns)}")

    # 显示前几行
    print("\n  前5行数据:")
    print(df.head().to_string(index=False))

    # 统计场景分布
    if 'scene' in df.columns:
        scene_counts = df['scene'].value_counts()
        print(f"\n  场景分布:")
        for scene, count in scene_counts.items():
            print(f"    {scene}: {count} 样本")

except ImportError:
    print("  [警告] 需要安装 pandas 和 openpyxl: pip install pandas openpyxl")
except Exception as e:
    print(f"  [错误] 读取GT文件失败: {e}")

# 4. 验证文件名匹配
print("\n4. 验证文件名匹配...")
try:
    # 检查前10个样本的文件是否存在
    sample_count = min(10, len(face_rgb_files))
    missing_files = []

    for i, rgb_file in enumerate(face_rgb_files[:sample_count]):
        filename = rgb_file.name
        uv_file = face_uv_dir / filename
        global_file = global_rgb_dir / filename

        if not uv_file.exists():
            missing_files.append(f"UV: {filename}")
        if not global_file.exists():
            missing_files.append(f"Global: {filename}")

    if missing_files:
        print(f"  [警告] 发现 {len(missing_files)} 个缺失文件:")
        for mf in missing_files[:5]:
            print(f"    - {mf}")
    else:
        print(f"  [OK] 前 {sample_count} 个样本的三模态文件均存在")

except Exception as e:
    print(f"  [错误] 验证失败: {e}")

print("\n" + "=" * 80)
print("数据加载测试完成")
print("=" * 80)
print("\n下一步: 安装 PyTorch 环境后运行完整推理测试")
print("  pip install torch torchvision pandas openpyxl pillow numpy scikit-learn")
