import os
import sys
from pathlib import Path
from PIL import Image

def check_image_sizes():
    base_path = Path(r"D:\work\secondYearMaster\thesis\reference\appeal\algorithms\preference_evaluate\deepskin\data\toMax\rendered_face")
    
    # 找到所有以 i 结尾的文件夹
    i_folders = [f for f in base_path.iterdir() if f.is_dir() and f.name.endswith('i')]
    print(f"找到 {len(i_folders)} 个以 i 结尾的文件夹")
    
    large_images = []
    
    for folder in i_folders:
        print(f"\n检查文件夹: {folder.name}")
        count = 0
        for img_file in folder.glob("*.jpg"):
            try:
                with Image.open(img_file) as img:
                    width, height = img.size
                    if width > 800 or height > 800:
                        # 提取前缀
                        filename = img_file.stem  # 不带扩展名
                        # 第一个 _ 前的部分
                        prefix = filename.split('_')[0]
                        large_images.append({
                            'folder': folder.name,
                            'filename': img_file.name,
                            'prefix': prefix,
                            'width': width,
                            'height': height,
                            'path': str(img_file)
                        })
                        count += 1
            except Exception as e:
                print(f"  处理 {img_file.name} 时出错: {e}")
        
        if count > 0:
            print(f"  找到 {count} 张尺寸大于800像素的图片")
    
    print(f"\n总共找到 {len(large_images)} 张尺寸大于800像素的图片")
    
    # 分析前缀模式
    prefixes = {}
    for item in large_images:
        prefix = item['prefix']
        if prefix not in prefixes:
            prefixes[prefix] = []
        prefixes[prefix].append(item)
    
    print(f"\n找到 {len(prefixes)} 个不同的前缀:")
    for prefix in list(prefixes.keys())[:10]:  # 只显示前10个
        print(f"  {prefix}: {len(prefixes[prefix])} 张图片")
    
    if len(prefixes) > 10:
        print(f"  ... 还有 {len(prefixes) - 10} 个前缀")
    
    return large_images

if __name__ == "__main__":
    large_images = check_image_sizes()
    
    # 保存结果到文件
    output_file = Path(__file__).parent / "large_images.txt"
    with open(output_file, 'w', encoding='utf-8') as f:
        for item in large_images:
            f.write(f"{item['path']}|{item['prefix']}|{item['width']}x{item['height']}\n")
    
    print(f"\n结果已保存到: {output_file}")