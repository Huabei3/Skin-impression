"""
31主测试运行脚本 - 提供简单的命令行接口
"""
import sys
from pathlib import Path

# 添加父目录到系统路径
sys.path.append(str(Path(__file__).parent.parent))

from test_runner import QuickTester, ModelComparator


def main():
    """主函数 - 提供简单的交互式界面"""
    
    print("=" * 60)
    print("人脸颜色喜好度预测模型 - 批量测试工具")
    print("=" * 60)
    print("\n请选择测试模式:")
    print("1. 快速测试 (测试最佳模型)")
    print("2. 测试指定模型")
    print("3. 比较所有模型")
    print("4. 退出")
    
    while True:
        choice = input("\n请输入选项 (1-4): ").strip()
        
        if choice == '1':
            # 快速测试
            print("\n开始快速测试...")
            try:
                tester = QuickTester()
                results = tester.run()
                print("\n测试完成！结果已保存至 test_results 目录")
            except Exception as e:
                print(f"测试失败: {e}")
            break
            
        elif choice == '2':
            # 测试指定模型
            checkpoint_path = input("请输入模型检查点路径: ").strip()
            if not Path(checkpoint_path).exists():
                print(f"错误: 找不到文件 {checkpoint_path}")
                continue
            
            print(f"\n开始测试模型: {checkpoint_path}")
            try:
                tester = QuickTester(checkpoint_path)
                results = tester.run()
                print("\n测试完成！结果已保存至 test_results 目录")
            except Exception as e:
                print(f"测试失败: {e}")
            break
            
        elif choice == '3':
            # 比较所有模型
            print("\n开始比较所有模型...")
            print("这可能需要较长时间，请耐心等待...")
            try:
                comparator = ModelComparator()
                results = comparator.compare_all()
                print("\n比较完成！结果已保存至 test_results/comparison 目录")
            except Exception as e:
                print(f"比较失败: {e}")
            break
            
        elif choice == '4':
            print("退出程序")
            break
            
        else:
            print("无效选项，请重新输入")
    
    print("\n感谢使用！")


if __name__ == '__main__':
    # 检查是否有命令行参数
    if len(sys.argv) > 1:
        # 如果有参数，使用test_runner的主函数
        from test_runner import main as runner_main
        runner_main()
    else:
        # 没有参数，运行交互式界面
        main()