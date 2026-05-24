"""
测试模块 - 用于评估人脸颜色喜好度预测模型
"""

try:
    # 尝试相对导入（作为包使用时）
    from .batch_tester import BatchTester
    from .test_runner import QuickTester, ModelComparator
except ImportError:
    # 绝对导入（直接运行时）
    from batch_tester import BatchTester
    from test_runner import QuickTester, ModelComparator

__version__ = "1.0.0"
__author__ = "DeepSkin Testing Team"

__all__ = [
    'BatchTester',
    'QuickTester',
    'ModelComparator'
]