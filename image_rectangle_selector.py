"""
交互式图像框选工具
允许用户打开图像，用鼠标框选矩形区域，并将矩形参数保存为JSON文件
"""
import os
import sys
import json
import argparse
from pathlib import Path
import cv2
import numpy as np


class RectangleSelector:
    """交互式矩形选择器"""
    
    def __init__(self, image_path, output_dir=None):
        """
        初始化选择器
        
        Args:
            image_path: 图像文件路径
            output_dir: 输出目录，如果为None则使用图像所在目录
        """
        self.image_path = Path(image_path)
        if not self.image_path.exists():
            raise FileNotFoundError(f"图像文件不存在: {image_path}")
        
        # 设置输出目录
        if output_dir is None:
            self.output_dir = self.image_path.parent
        else:
            self.output_dir = Path(output_dir)
            self.output_dir.mkdir(parents=True, exist_ok=True)
        
        # 矩形参数
        self.rect = None
        self.drawing = False
        self.ix, self.iy = -1, -1
        self.temp_rect = None
        
        # 加载图像
        self.image = cv2.imread(str(self.image_path))
        if self.image is None:
            raise ValueError(f"无法加载图像: {image_path}")
        
        # 创建窗口
        self.window_name = f"矩形选择器 - {self.image_path.name}"
        cv2.namedWindow(self.window_name)
        cv2.setMouseCallback(self.window_name, self.mouse_callback)
        
        # 显示指令
        self.show_instructions()
    
    def show_instructions(self):
        """显示操作指令"""
        print("\n" + "="*60)
        print("图像矩形选择工具")
        print("="*60)
        print(f"图像: {self.image_path.name}")
        print(f"尺寸: {self.image.shape[1]}x{self.image.shape[0]}")
        print("\n操作指令:")
        print("  1. 按住鼠标左键并拖动以绘制矩形")
        print("  2. 松开鼠标左键完成绘制")
        print("  3. 按 's' 键保存当前矩形")
        print("  4. 按 'r' 键重置当前矩形")
        print("  5. 按 'q' 键退出程序")
        print("  6. 按 'n' 键加载下一张图像（仅批处理模式）")
        print("="*60 + "\n")
    
    def mouse_callback(self, event, x, y, flags, param):
        """鼠标回调函数"""
        if event == cv2.EVENT_LBUTTONDOWN:
            # 开始绘制
            self.drawing = True
            self.ix, self.iy = x, y
            self.temp_rect = (x, y, 0, 0)
            
        elif event == cv2.EVENT_MOUSEMOVE:
            # 正在绘制
            if self.drawing:
                # 更新临时矩形
                width = x - self.ix
                height = y - self.iy
                self.temp_rect = (self.ix, self.iy, width, height)
                
        elif event == cv2.EVENT_LBUTTONUP:
            # 结束绘制
            self.drawing = False
            width = x - self.ix
            height = y - self.iy
            
            # 确保宽度和高度为正数
            if width < 0:
                self.ix += width
                width = abs(width)
            if height < 0:
                self.iy += height
                height = abs(height)
            
            # 设置最终矩形
            self.rect = (self.ix, self.iy, width, height)
            print(f"已选择矩形: x={self.ix}, y={self.iy}, w={width}, h={height}")
    
    def draw_rectangle(self, img, rect, color=(0, 255, 0), thickness=2):
        """在图像上绘制矩形"""
        if rect is None:
            return img
        
        x, y, w, h = rect
        cv2.rectangle(img, (x, y), (x + w, y + h), color, thickness)
        
        # 添加坐标文本
        text = f"({x}, {y}, {w}, {h})"
        cv2.putText(img, text, (x, y - 10), cv2.FONT_HERSHEY_SIMPLEX, 
                   0.5, color, 1, cv2.LINE_AA)
        
        return img
    
    def save_rectangle(self):
        """保存矩形参数到JSON文件"""
        if self.rect is None:
            print("警告: 没有选择矩形，无法保存")
            return False
        
        # 准备数据
        image_name = self.image_path.stem  # 不含后缀的文件名
        output_file = self.output_dir / f"{image_name}_rect.json"
        
        rect_data = {
            "image_file": self.image_path.name,
            "image_path": str(self.image_path),
            "image_size": {
                "width": self.image.shape[1],
                "height": self.image.shape[0],
                "channels": self.image.shape[2] if len(self.image.shape) > 2 else 1
            },
            "rectangle": {
                "x": int(self.rect[0]),
                "y": int(self.rect[1]),
                "width": int(self.rect[2]),
                "height": int(self.rect[3])
            },
            "normalized_rectangle": {
                "x": self.rect[0] / self.image.shape[1],
                "y": self.rect[1] / self.image.shape[0],
                "width": self.rect[2] / self.image.shape[1],
                "height": self.rect[3] / self.image.shape[0]
            }
        }
        
        # 保存为JSON
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(rect_data, f, indent=2, ensure_ascii=False)
        
        print(f"矩形参数已保存到: {output_file}")
        return True
    
    def run(self):
        """运行交互式选择器"""
        print(f"正在显示图像: {self.image_path.name}")
        print("请使用鼠标绘制矩形...")
        
        while True:
            # 复制图像用于显示
            display_img = self.image.copy()
            
            # 如果有最终矩形，绘制它
            if self.rect is not None:
                display_img = self.draw_rectangle(display_img, self.rect)
            
            # 如果有临时矩形（正在绘制），绘制它
            if self.drawing and self.temp_rect is not None:
                display_img = self.draw_rectangle(display_img, self.temp_rect, color=(255, 0, 0))
            
            # 显示图像
            cv2.imshow(self.window_name, display_img)
            
            # 等待按键
            key = cv2.waitKey(1) & 0xFF
            
            if key == ord('s'):
                # 保存矩形
                if self.save_rectangle():
                    print("矩形已保存，继续绘制或按'q'退出")
            
            elif key == ord('r'):
                # 重置矩形
                self.rect = None
                self.temp_rect = None
                print("矩形已重置")
            
            elif key == ord('q'):
                # 退出
                print("退出程序")
                break
            
            elif key == ord('n'):
                # 下一张图像（批处理模式使用）
                cv2.destroyWindow(self.window_name)
                return 'next'
        
        # 清理
        cv2.destroyWindow(self.window_name)
        return 'quit'


def process_single_image(image_path, output_dir=None):
    """处理单张图像"""
    try:
        selector = RectangleSelector(image_path, output_dir)
        selector.run()
        return True
    except Exception as e:
        print(f"处理图像 {image_path} 时出错: {e}")
        import traceback
        traceback.print_exc()
        return False


def process_batch_images(input_dir, output_dir=None, extensions=None):
    """批量处理图像目录中的所有图像"""
    if extensions is None:
        extensions = ['.jpg', '.jpeg', '.png', '.bmp', '.tiff', '.tif']
    
    input_path = Path(input_dir)
    if not input_path.exists():
        print(f"输入目录不存在: {input_dir}")
        return
    
    # 收集所有图像文件
    image_files = []
    for ext in extensions:
        image_files.extend(list(input_path.glob(f"*{ext}")))
        image_files.extend(list(input_path.glob(f"*{ext.upper()}")))
    
    if not image_files:
        print(f"在目录 {input_dir} 中未找到支持的图像文件")
        return
    
    print(f"找到 {len(image_files)} 个图像文件")
    
    # 处理每个图像
    for i, img_path in enumerate(image_files):
        print(f"\n处理图像 {i+1}/{len(image_files)}: {img_path.name}")
        
        # 检查是否已存在矩形文件
        rect_file = (output_dir if output_dir else img_path.parent) / f"{img_path.stem}_rect.json"
        if rect_file.exists():
            print(f"跳过: 矩形文件已存在 {rect_file.name}")
            continue
        
        try:
            selector = RectangleSelector(img_path, output_dir)
            result = selector.run()
            
            if result == 'quit':
                print("用户提前退出批处理")
                break
            elif result == 'next':
                print("继续下一张图像...")
                continue
                
        except Exception as e:
            print(f"处理图像 {img_path.name} 时出错: {e}")
            continue


def main():
    """主函数"""
    parser = argparse.ArgumentParser(description="交互式图像矩形选择工具")
    parser.add_argument("input", help="输入图像文件路径或图像目录路径")
    parser.add_argument("-o", "--output", help="输出目录（默认为输入图像所在目录）")
    parser.add_argument("-b", "--batch", action="store_true", 
                       help="批处理模式，处理目录中的所有图像")
    
    args = parser.parse_args()
    
    # 检查OpenCV是否可用
    try:
        import cv2
        print(f"OpenCV版本: {cv2.__version__}")
    except ImportError:
        print("错误: 需要安装OpenCV库")
        print("请运行: pip install opencv-python")
        sys.exit(1)
    
    # 处理输入
    input_path = Path(args.input)
    
    if not input_path.exists():
        print(f"错误: 路径不存在: {args.input}")
        sys.exit(1)
    
    if args.batch:
        # 批处理模式
        if not input_path.is_dir():
            print("错误: 批处理模式需要目录路径")
            sys.exit(1)
        
        process_batch_images(args.input, args.output)
    else:
        # 单图像模式
        if not input_path.is_file():
            print("错误: 需要图像文件路径")
            sys.exit(1)
        
        process_single_image(args.input, args.output)
    
    print("\n程序执行完成")


if __name__ == "__main__":
    main()