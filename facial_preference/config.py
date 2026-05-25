"""
配置文件 - 包含所有硬编码路径和超参数
"""
import os
from pathlib import Path

class Config:
    """Project-wide configuration."""
    
    # ==================== 数据路径配置 ====================
    # 人脸RGB图像根目�?
    FACE_RGB_ROOT = Path(r"/root/autodl-tmp/toMax_deepskin/rendered_face")
    
    # 人脸UV数据根目�? 
    FACE_UV_ROOT = Path(r"/root/autodl-tmp/toMax_deepskin/rendered_face_uv")
    
    # GT Excel文件路径
    GT_EXCEL_PATH = Path(r"/root/autodl-tmp/toMax_deepskin/gt/toMax_gt.xlsx")
    
    TRAIN_IDS = ["01"]
    TEST_IDS =["01"]

    # 输出目录
    # 可通过修改 MODEL_NAME 来区分不同模型的保存目录
    GLOBAL_RGB_ROOT =Path(r"/root/autodl-tmp/toMax_deepskin/rendered_2max")
    # GLOBAL_RGB_ROOT =Path(r"I:\skin_data_2max\rendered_2max")

    OUTPUT_ROOT = Path(r"/root/autodl-tmp/deepskin/facial_preference/output")
    # GLOBAL_RGB_ROOT =Path(r"I:\skin_data_2max\rendered_2max")
    # OUTPUT_ROOT = Path(r"F:\Github\deepskin\facial_preference\output")
    MODEL_NAME = "test"  # 修改为你希望的模型名�?
    OUTPUT_DIR = OUTPUT_ROOT / MODEL_NAME
    CHECKPOINT_DIR = OUTPUT_DIR / "checkpoints"
    LOG_DIR = OUTPUT_DIR / "logs"
    RESULT_DIR = OUTPUT_DIR / "results"
    checkpoint_interval = 100
    
    # ==================== 数据集配�?====================
    # 数据集划分比�?(train:val:test = 7:1.5:1.5)
    TRAIN_RATIO = 0.7
    VAL_RATIO = 0.15
    TEST_RATIO = 0.15
    
    # 随机种子（控制数据集划分的一致性）
    RANDOM_SEED = 666
    
    # 数据增强配置
    AUGMENTATION = {
        'random_crop': True,
        'horizontal_flip': True,
        'rotation_degree': 10,
        'brightness_range': (0.8, 1.2),
        'contrast_range': (0.8, 1.2),
        'mixup_alpha': 0.2,
        'cutmix_prob': 0.5
    }
    
    # ==================== 模型配置 ====================
    # 输入尺寸
    FACE_INPUT_SIZE = (224, 224)
    GLOBAL_INPUT_SIZE = (224, 224)
    
    # 网络架构配置
    MODEL = {
        # 人脸流配�?
        'face_stream': {
            'rgb_backbone': 'resnet50',  # 可�? resnet50, efficientnet_b0
            'rgb_pretrained': True,
            'rgb_feature_dim': 512,
            # UV 直方图的 bin 数（U/V 方向统一使用该值）
            'uv_hist_bins': 64,
            'uv_hist_u_range': [0.0, 3.0],
            'uv_hist_v_range': [0.0, 3.0],
            'uv_channels': 2,
            'uv_feature_dim': 128,
            'uv_conv_layers': [32, 64, 128, 128]
        },
        
        # 全局流配�?
        'global_stream': {
            'backbone': 'mobilenet_v3_small',  # 轻量级网�?
            'pretrained': True,
            'feature_dim': 256
        },
        
        # 统计流配置
        'stat_stream': {
            # 统计特征维度：5(亮度统计) + 1(色温) + 2(场景类别 one-hot) + 2(性别 one-hot) + 3(人种 three-class one-hot)
            'input_dim': 13,
            'hidden_dims': [32, 64],
            'output_dim': 32
        },
        
        # 融合层配�?
        'fusion': {
            'attention_heads': 8,
            'fusion_dim': 256,
            'dropout': 0.3
        },
        
        # 预测头配�?
        'prediction_heads': {
            'preference_score': {
                'hidden_dims': [128, 64],
                'output_dim': 1
            },
            'preference_center': {
                'hidden_dims': [128, 64],
                'output_dim': 2  # LAB空间的a*, b*
            }
        }
    }
    
    # 为了兼容性，添加一些便捷属�?
    FACE_BACKBONE = 'resnet50'
    GLOBAL_BACKBONE = 'mobilenet_v3_small'
    FUSION_HIDDEN_DIM = 256
    FUSION_TYPE = 'adaptive'
    DROPOUT_RATE = 0.3
    BATCH_SIZE = 64
    NUM_EPOCHS = 100
    LEARNING_RATE = 1e-4
    
    # ==================== 训练配置 ====================
    TRAINING = {
        # 优化器配�?
        'optimizer': 'AdamW',
        'learning_rate': 7e-4,
        # 'learning_rate': 1e-3,
        'weight_decay': 1e-4,
        
        # 学习率调度器
        'scheduler': 'CosineAnnealingWarmRestarts',
        'warmup_epochs': 5,
        'min_lr': 1e-6,
        'T_0': 10,  # CosineAnnealing的初始周�?
        
        # 训练配置
        'batch_size': 32,
        'num_epochs': 100,
        'gradient_clip': 1.0,
        'early_stopping_patience': 100,
        
        # 训练阶段
        'stage1_epochs': 20,  # 冻结backbone
        'stage2_epochs': 60,  # 部分解冻
        'stage3_epochs': 120,  # 全部解冻
        
        # 混合精度训练
        'mixed_precision': True,
        
        # 分布式训�?
        'distributed': False,
        'num_gpus': 1,

        # 采样器：'weighted' 启用按极端区间加权采�?
        'sampler': 'weighted',
        # 极端区间定义与采样权重（用于采样器）
        'extreme_bins': [[0.0, 0.1], [0.9, 1.0]],
        'extreme_sample_weight': 1.0
    }
    
    # ==================== 损失函数配置 ====================
    LOSS = {

        'pearson_weight': 0.7,

        # 损失权重
        'alpha': 1.0,  # 喜好度评分损失权�?
        'beta': 1.0,   # 喜好中心损失权重
        'gamma': 0.7,  # 一致性损失权�?
        
        # Huber Loss配置
        'huber_delta': 0.1,
        
        # 排序一致性损失权�?
        'ranking_weight': 0.4,
        
        # 感知加权
        'perceptual_weight': {
            'skin_region': 1.5,
            'extreme_region': 0.7
        },
        
        # 标签平滑
        'label_smoothing': 0.01,
        
        # 动态权重调�?
        'dynamic_weighting': True,
        'weight_update_freq': 50  # �?个epoch更新一次权�?
    }
    
    # ==================== 评估配置 ====================
    EVALUATION = {
        'metrics': [
            'mae',           # 平均绝对误差
            'rmse',          # 均方根误�?
            'pearson',       # Pearson相关系数
            'spearman',      # Spearman等级相关
            'r2',            # R²决定系数
            'delta_e_ab',    # CIE色差
            'euclidean'      # 欧氏距离
        ],
        'save_predictions': True,
        'visualization': True
    }
    
    # ==================== 设备配置 ====================
    DEVICE = 'cuda'  # 'cuda' or 'cpu'
    
    # ==================== 日志配置 ====================
    LOGGING = {
        'level': 'INFO',
        'save_to_file': True,
        'tensorboard': True,
        'wandb': False,  # 可选的Weights & Biases集成
        'wandb_project': 'facial_preference'
    }
    
    @classmethod
    def create_directories(cls):
        """Create required output/checkpoint/log/result directories."""
        dirs = [
            cls.OUTPUT_DIR,
            cls.CHECKPOINT_DIR,
            cls.LOG_DIR,
            cls.RESULT_DIR
        ]
        for dir_path in dirs:
            dir_path.mkdir(parents=True, exist_ok=True)
    
    @classmethod
    def get_config_dict(cls):
        """Return the current configuration as a plain Python dict."""
        config_dict = {}
        for key in dir(cls):
            if not key.startswith('_') and key.isupper():
                value = getattr(cls, key)
                # 递归处理嵌套字典中的Path对象
                if isinstance(value, dict):
                    config_dict[key] = cls._convert_paths_in_dict(value)
                elif isinstance(value, Path):
                    config_dict[key] = str(value)
                else:
                    config_dict[key] = value
        return config_dict
    
    @classmethod
    def _convert_paths_in_dict(cls, d):
        """Recursively convert any Path objects inside a dict into strings."""
        result = {}
        for key, value in d.items():
            if isinstance(value, dict):
                result[key] = cls._convert_paths_in_dict(value)
            elif isinstance(value, Path):
                result[key] = str(value)
            else:
                result[key] = value
        return result

