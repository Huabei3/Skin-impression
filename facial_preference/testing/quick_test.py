"""
快速测试脚本 - 支持在此处指定 TEST_IDS，用于只测试部分编号数据。
"""
import sys
from pathlib import Path

# 添加父目录到系统路径（便于直接导入 testing/data/config 等模块）
sys.path.append(str(Path(__file__).parent.parent))


# =============== 在此定义测试使用的编号 ===============
# 支持格式：
# - 字符串列表：例如 ["01", "02", "03"]
# - 整数列表：例如 [1, 2, 3]（会自动补零）
# - 逗号字符串：例如 "01,02,03"
# - 'all' 或 None：表示使用全部编号
TEST_IDS = None
# model_path = "F:/Github/deepskin/facial_preference/output/white/checkpoints/ids_train_01-02-03__test_all/best_model.pth"
model_path = "F:/Github/deepskin/facial_preference/output/all/checkpoints/ids_train_all__test_all/best_model.pth"
# 是否对所有预测的喜好度分数做[0,1]等比例映射后再计算误差并绘图
NORMALIZE = False

# 若希望强行调整预测分数与真值之间的 Pearson 相关系数，请在此设置目标值
# - 取值范围：[-1.0, 1.0]
# - 设置为 None 表示保持现状不变（不做强行映射）
# - 设置为数值（例如 0.85 或 -0.3）表示将预测值进行映射，使得与真值的 Pearson 系数接近该数
FORCE_PEARSON = None

# =====================================================


def main():
    print("=" * 60)
    print("人脸颜色喜好度预测模型 - 快速测试")
    print("=" * 60)

    # 根据配置尝试优先定位按编号分组的模型路径，否则回退到老路径
    try:
        from config import Config
        from data.dataset import FacialPreferenceDataset as _FPD
        cfg = Config.get_config_dict()
        # 生成运行标签（与训练保存目录一致）
        # 优先使用代码中的 TEST_IDS，其次才是 config
        try:
            norm_test_local = _FPD._normalize_ids(TEST_IDS)
        except Exception:
            norm_test_local = None if TEST_IDS in (None, 'all') else TEST_IDS

        norm_train = _FPD._normalize_ids(cfg.get('TRAIN_IDS'))
        norm_test_for_path = norm_test_local if norm_test_local is not None else _FPD._normalize_ids(cfg.get('TEST_IDS'))

        def _tag(ids):
            return 'all' if ids is None else '-'.join(ids)

        run_tag = f"ids_train_{_tag(norm_train)}__test_{_tag(norm_test_for_path)}"
        candidate = Path(cfg['OUTPUT_DIR']) / 'checkpoints' / run_tag / 'best_model.pth'
        # 优先使用代码中给定的 model_path，其次才使用 config 推导的候选路径
        code_path = Path(model_path) if model_path else None
        if code_path and code_path.exists():
            checkpoint_path = code_path
        elif candidate.exists():
            checkpoint_path = candidate
        else:
            checkpoint_path = code_path or candidate
    except Exception:
        checkpoint_path = Path(model_path)

    # 检查模型文件是否存在
    if not checkpoint_path.exists():
        print(f"\n[错误] 找不到模型文件")
        print(f"   尝试路径: {checkpoint_path}")
        print("\n请先训练模型或确保模型文件存在")
        return

    print(f"\n[OK] 使用模型: {checkpoint_path}")

    # 导入 BatchTester 并通过 config 覆盖 TEST_IDS
    try:
        from testing.batch_tester import BatchTester  # 绝对导入以兼容 IDE 结构
    except ImportError:
        from batch_tester import BatchTester  # 相对路径导入（已把父目录加到 sys.path）

    try:
        from config import Config
        from data.dataset import FacialPreferenceDataset as _FPD

        # 规范化测试编号
        try:
            norm_test_ids = _FPD._normalize_ids(TEST_IDS)
        except Exception:
            norm_test_ids = None if TEST_IDS in (None, 'all') else TEST_IDS

        # 准备覆盖配置：若代码中给出具体 TEST_IDS（非 None/'all'），则以其为准；否则沿用配置中的值
        cfg = Config.get_config_dict()
        if norm_test_ids is not None:
            cfg['TEST_IDS'] = norm_test_ids

        print("\n开始测试...")
        print("-" * 40)

        tester = BatchTester(
            checkpoint_path=str(checkpoint_path),
            config=cfg,
            device='cuda',
            output_dir=str(Path(cfg['OUTPUT_DIR']).parent / 'test_results'),
            normalize=NORMALIZE,
            force_pearson=FORCE_PEARSON
        )

        results = tester.run_complete_test()

        print("\n" + "=" * 60)
        print("√ 测试完成！")
        print("=" * 60)

        if results:
            # 尽量兼容不同键名
            score = results.get('score_analysis', {})
            center = results.get('center_analysis', {})
            total = results.get('metadata', {}).get('total_samples', 'N/A')
            mae = score.get('平均绝对误差(MAE)') or score.get('MAE')
            de2000 = center.get('de2000_mean') or center.get('DeltaE_平均')
            print("\n📊 关键指标:")
            print(f"   - 样本总数: {total}")
            if mae is not None:
                print(f"   - 评分MAE: {float(mae):.4f}")
            if de2000 is not None:
                print(f"   - DE2000: {float(de2000):.4f}")
            # 追加详尽统计
            p_median = score.get('p_error_median')
            p_best25 = score.get('p_error_best25_mean')
            p_worst25 = score.get('p_error_worst25_mean')
            p_min = score.get('p_error_min')
            p_max = score.get('p_error_max')
            pearson = score.get('pearson_r') or score.get('Pearson相关系数')
            if p_median is not None:
                print(f"   - 评分中位数误差: {float(p_median):.4f}")
            if p_best25 is not None:
                print(f"   - 评分最优25%平均误差: {float(p_best25):.4f}")
            if p_worst25 is not None:
                print(f"   - 评分最差25%平均误差: {float(p_worst25):.4f}")
            if p_min is not None:
                print(f"   - 评分最好值(最小误差): {float(p_min):.4f}")
            if p_max is not None:
                print(f"   - 评分最差值(最大误差): {float(p_max):.4f}")
            de_median = center.get('de2000_median') or center.get('DeltaE_中位数')
            de_best25 = center.get('de2000_best25_mean')
            de_worst25 = center.get('de2000_worst25_mean')
            de_min = center.get('de2000_min') or center.get('DeltaE_最小值')
            de_max = center.get('de2000_max') or center.get('DeltaE_最大值')
            if de_median is not None:
                print(f"   - DE2000中位数: {float(de_median):.4f}")
            if de_best25 is not None:
                print(f"   - DE2000最优25%平均: {float(de_best25):.4f}")
            if de_worst25 is not None:
                print(f"   - DE2000最差25%平均: {float(de_worst25):.4f}")
            if de_min is not None:
                print(f"   - DE2000最好值(最小): {float(de_min):.4f}")
            if de_max is not None:
                print(f"   - DE2000最差值(最大): {float(de_max):.4f}")
            if pearson is not None:
                print(f"   - Pearson相关系数: {float(pearson):.4f}")
            print(f"\n📁 详细结果保存于: {(Path(cfg['OUTPUT_DIR']).parent / 'test_results')} ")

    except Exception as e:
        print(f"\n[测试失败] {e}")
        import traceback
        print("\n详细错误信息:")
        traceback.print_exc()


if __name__ == '__main__':
    main()
