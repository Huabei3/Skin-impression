"""非交互式快速测试脚本"""
import sys
from pathlib import Path

# 添加父目录到系统路径
sys.path.append(str(Path(__file__).parent))
sys.path.append(str(Path(__file__).parent / "facial_preference"))

from facial_preference.testing.test_runner import QuickTester

def main():
    print("=" * 60)
    print("开始快速测试...")
    print("=" * 60)
    
    try:
        tester = QuickTester()
        results = tester.run()
        print("\n" + "=" * 60)
        print("测试完成！结果已保存至 test_results 目录")
        print("=" * 60)
    except Exception as e:
        print(f"测试失败: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

if __name__ == "__main__":
    main()
