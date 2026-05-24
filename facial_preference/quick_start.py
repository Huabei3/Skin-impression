"""
快速启动脚本 - 提供简单的命令行接口
"""
import argparse
import sys
import logging
from pathlib import Path

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)


def main():
    parser = argparse.ArgumentParser(
        description='人脸颜色喜好度预测系统',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
示例:
  # 测试框架
  python quick_start.py test
  
  # 训练模型
  python quick_start.py train
  
  # 单张图像预测
  python quick_start.py predict --face-rgb path/to/face.jpg --face-uv path/to/face_uv.npy
  
  # 修改配置并训练
  python quick_start.py train --batch-size 16 --epochs 50 --lr 0.0001
        """
    )
    
    subparsers = parser.add_subparsers(dest='command', help='可用命令')
    
    # 测试命令
    test_parser = subparsers.add_parser('test', help='测试框架是否正确安装')
    
    # 训练命令
    train_parser = subparsers.add_parser('train', help='训练模型')
    train_parser.add_argument('--batch-size', type=int, default=32, help='批次大小')
    train_parser.add_argument('--epochs', type=int, default=100, help='训练轮数')
    train_parser.add_argument('--lr', type=float, default=1e-4, help='学习率')
    train_parser.add_argument('--model-type', default='full', choices=['full', 'simplified'], 
                            help='模型类型')
    train_parser.add_argument('--resume', type=str, help='从检查点恢复训练')
    
    # 预测命令
    predict_parser = subparsers.add_parser('predict', help='预测单张图像')
    predict_parser.add_argument('--checkpoint', type=str, 
                              default='output/checkpoints/best_model.pth',
                              help='模型检查点路径')
    predict_parser.add_argument('--face-rgb', type=str, required=True, 
                              help='人脸RGB图像路径')
    predict_parser.add_argument('--face-uv', type=str, required=True, 
                              help='人脸UV数据路径')
    predict_parser.add_argument('--output', type=str, default='prediction.json',
                              help='输出文件路径')
    
    # 评估命令
    eval_parser = subparsers.add_parser('evaluate', help='在测试集上评估模型')
    eval_parser.add_argument('--checkpoint', type=str, 
                           default='output/checkpoints/best_model.pth',
                           help='模型检查点路径')
    eval_parser.add_argument('--output', type=str, default='evaluation_results.json',
                           help='输出结果路径')
    
    # 配置命令
    config_parser = subparsers.add_parser('config', help='显示或修改配置')
    config_parser.add_argument('--show', action='store_true', help='显示当前配置')
    config_parser.add_argument('--set-data-path', type=str, help='设置数据路径')
    
    args = parser.parse_args()
    
    if args.command == 'test':
        logger.info("运行框架测试...")
        from test_framework import main as test_main
        success = test_main()
        sys.exit(0 if success else 1)
    
    elif args.command == 'train':
        logger.info("开始训练...")
        logger.info(f"参数: batch_size={args.batch_size}, epochs={args.epochs}, lr={args.lr}")
        
        # 动态修改配置
        from config import Config
        Config.TRAINING['batch_size'] = args.batch_size
        Config.TRAINING['num_epochs'] = args.epochs
        Config.TRAINING['learning_rate'] = args.lr
        
        # 开始训练
        from train import main as train_main
        train_main()
    
    elif args.command == 'predict':
        logger.info("运行预测...")
        from inference import FacialPreferencePredictor
        
        # 创建预测器
        predictor = FacialPreferencePredictor(args.checkpoint)
        
        # 预测
        result = predictor.predict_single(args.face_rgb, args.face_uv)
        
        # 显示结果
        logger.info("预测结果:")
        logger.info(f"  喜好度评分: {result['preference_score']:.4f}")
        logger.info(f"  喜好中心 (a*, b*): ({result['preference_center_a']:.2f}, {result['preference_center_b']:.2f})")
        
        # 保存结果
        import json
        with open(args.output, 'w') as f:
            json.dump(result, f, indent=4)
        logger.info(f"结果已保存到: {args.output}")
    
    elif args.command == 'evaluate':
        logger.info("评估模型...")
        from inference import test_model_on_dataset
        test_model_on_dataset(args.checkpoint, "", args.output)
    
    elif args.command == 'config':
        if args.show:
            from config import Config
            import json
            config_dict = Config.get_config_dict()
            print("\n当前配置:")
            print(json.dumps(config_dict, indent=2, default=str))
        elif args.set_data_path:
            logger.info(f"设置数据路径为: {args.set_data_path}")
            # 这里可以实现配置文件的修改逻辑
            logger.info("注意: 请手动编辑 config.py 文件来修改数据路径")
    
    else:
        parser.print_help()


if __name__ == '__main__':
    main()