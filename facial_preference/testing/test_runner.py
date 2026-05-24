"""
测试运行器 - 提供快速测试和模型比较功能（支持分组子目录）
"""
import sys
from pathlib import Path
from typing import Dict, Optional
import json
import logging

# 添加父目录到系统路径
sys.path.append(str(Path(__file__).parent.parent))

# 绝对导入
try:
    from batch_tester import BatchTester
except ImportError:  # pragma: no cover
    from .batch_tester import BatchTester

from config import Config
from data import FacialPreferenceDataset

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)


class QuickTester:
    """快速测试器 - 用于快速测试模型"""

    def __init__(self, checkpoint_path: Optional[str] = None):
        if checkpoint_path is None:
            self.checkpoint_path = self._resolve_default_checkpoint_path()
        else:
            self.checkpoint_path = Path(checkpoint_path)

        if not self.checkpoint_path.exists():
            raise FileNotFoundError(f"找不到模型文件: {self.checkpoint_path}")

        logger.info(f"使用模型: {self.checkpoint_path}")

    def _resolve_default_checkpoint_path(self) -> Path:
        cfg = Config.get_config_dict()
        train_ids = FacialPreferenceDataset._normalize_ids(cfg.get('TRAIN_IDS'))
        test_ids = FacialPreferenceDataset._normalize_ids(cfg.get('TEST_IDS'))
        def _tag(ids):
            return 'all' if ids is None else '-'.join(ids)
        run_tag = f"ids_train_{_tag(train_ids)}__test_{_tag(test_ids)}"
        candidate = Path(cfg['OUTPUT_DIR']) / 'checkpoints' / run_tag / 'best_model.pth'
        if candidate.exists():
            return candidate
        # 兼容旧路径
        return Path('F:/Github/deepskin/output/checkpoints/best_model.pth')

    def run(self, output_dir: Optional[str] = None) -> Dict:
        if output_dir is None:
            # 默认放在工程根目录下 test_results
            output_dir = Path(Config.get_config_dict()['OUTPUT_DIR']).parent / 'test_results'
        else:
            output_dir = Path(output_dir)

        output_dir.mkdir(parents=True, exist_ok=True)

        logger.info("=" * 60)
        logger.info("开始快速测试")
        logger.info("=" * 60)

        tester = BatchTester(
            checkpoint_path=str(self.checkpoint_path),
            device='cuda',
            output_dir=str(output_dir)
        )

        results = tester.run_complete_test()
        self._print_summary(results)
        return results

    def _print_summary(self, results: Dict):
        print("\n" + "=" * 60)
        print("测试完成！关键指标总结:")
        print("=" * 60)

        score = results['score_analysis']
        center = results['center_analysis']
        print("\n【第一维度：喜好度评分(部分)】")
        print(f"├─ 平均绝对误差(MAE): {score['平均绝对误差(MAE)']:.4f}")
        print(f"├─ 中位数误差: {score['中位数误差']:.4f}")
        print(f"└─ Pearson相关系数: {score['Pearson相关系数']:.4f}")

        print("\n【第二维度：喜好中心(a*b*) - 欧氏距离】")
        print(f"├─ 欧氏距离平均: {center['欧氏距离_平均']:.4f}")
        print(f"└─ Delta E平均: {center['DeltaE_平均']:.4f}")

        print(f"\n测试样本总数: {results['metadata']['total_samples']}")


class ModelComparator:
    """模型比较器 - 递归扫描并比较多个模型"""

    def __init__(self, checkpoint_dir: Optional[str] = None):
        cfg = Config.get_config_dict()
        self.checkpoint_dir = Path(checkpoint_dir) if checkpoint_dir else Path(cfg['OUTPUT_DIR']) / 'checkpoints'
        if not self.checkpoint_dir.exists():
            raise FileNotFoundError(f"找不到检查点目录: {self.checkpoint_dir}")
        self.checkpoints = list(self.checkpoint_dir.rglob('*.pth'))
        if not self.checkpoints:
            raise FileNotFoundError(f"在 {self.checkpoint_dir} 中没有找到任何检查点")

        logger.info(f"找到 {len(self.checkpoints)} 个检查点")

    def compare_all(self, output_dir: Optional[str] = None) -> Dict:
        base = Path(Config.get_config_dict()['OUTPUT_DIR']).parent / 'test_results' / 'comparison'
        output_base = Path(output_dir) if output_dir else base
        output_base.mkdir(parents=True, exist_ok=True)

        all_results: Dict[str, Dict] = {}
        for checkpoint in self.checkpoints:
            parent_tag = checkpoint.parent.name
            logger.info(f"\n测试检查点: {parent_tag}/{checkpoint.name}")
            checkpoint_output_dir = output_base / f"{parent_tag}__{checkpoint.stem}"
            checkpoint_output_dir.mkdir(parents=True, exist_ok=True)

            try:
                tester = BatchTester(
                    checkpoint_path=str(checkpoint),
                    device='cuda',
                    output_dir=str(checkpoint_output_dir)
                )
                results = tester.run_complete_test()
                all_results[f"{parent_tag}/{checkpoint.name}"] = {
                    'MAE': results['score_analysis']['平均绝对误差(MAE)'],
                    '中位数误差': results['score_analysis']['中位数误差'],
                    '欧氏距离_平均': results['center_analysis']['欧氏距离_平均'],
                    '欧氏距离_中位': results['center_analysis']['欧氏距离_中位'],
                    'Pearson': results['score_analysis']['Pearson相关系数'],
                    'DeltaE_平均': results['center_analysis']['DeltaE_平均'],
                    '样本数': results['metadata']['total_samples']
                }
            except Exception as e:
                logger.error(f"测试失败: {e}")
                continue

        self._save_comparison_results(all_results, output_base)
        self._print_comparison(all_results)
        return all_results

    def _save_comparison_results(self, all_results: Dict, output_dir: Path):
        json_path = output_dir / 'model_comparison.json'
        with open(json_path, 'w', encoding='utf-8') as f:
            json.dump(all_results, f, ensure_ascii=False, indent=2)
        logger.info(f"比较结果已保存至: {json_path}")

    def _print_comparison(self, all_results: Dict):
        print("\n" + "=" * 80)
        print("模型性能比较")
        print("=" * 80)
        for name, metrics in all_results.items():
            print(f"{name:<40} MAE={metrics['MAE']:.4f} 欧氏距离={metrics['欧氏距离_平均']:.4f} Pearson={metrics['Pearson']:.4f}")


def quick_test(checkpoint_path: Optional[str] = None):
    tester = QuickTester(checkpoint_path)
    return tester.run()


def compare_models(checkpoint_dir: Optional[str] = None):
    comparator = ModelComparator(checkpoint_dir)
    return comparator.compare_all()


def main():
    import argparse

    parser = argparse.ArgumentParser(description='人脸颜色喜好度预测模型测试工具')
    parser.add_argument('--mode', type=str, default='quick', choices=['quick', 'compare'])
    parser.add_argument('--checkpoint', type=str, help='模型检查点路径(quick模式)')
    parser.add_argument('--checkpoint-dir', type=str, help='检查点目录(compare模式)')
    parser.add_argument('--output-dir', type=str, help='输出目录')

    args = parser.parse_args()

    if args.mode == 'quick':
        quick_test(args.checkpoint)
    elif args.mode == 'compare':
        compare_models(args.checkpoint_dir)


if __name__ == '__main__':
    main()
