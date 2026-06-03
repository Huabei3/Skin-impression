"""
predict_p project configuration (standalone).

This config is intentionally minimal and only contains what predict_p needs.
It is NOT shared with predict_center.
"""

from __future__ import annotations

from pathlib import Path


class Config:
    # ==================== Data paths ====================
    FACE_RGB_ROOT = Path(r"I:\skin_data_2max\rendered_face")
    FACE_UV_ROOT = Path(r"I:\skin_data_2max\rendered_face_uv")
    GLOBAL_RGB_ROOT = Path(r"I:\skin_data_2max\rendered_2max")
    GT_EXCEL_PATH = Path(r"I:\skin_data_2max\gt\Preference_non_model_gt.xlsx")
    # If True, FACE_UV_ROOT contains precomputed UV histograms (C x bins x bins) rather than UV maps.
    FACE_UV_IS_HIST = False

    TRAIN_IDS = None
    TEST_IDS = None

    PROJECT_ROOT = Path(__file__).resolve().parent
    OUTPUT_ROOT = PROJECT_ROOT / "output"
    MODEL_NAME = "predict_p"
    MODEL_VARIANT = "v1"  # "v1" original, "v2" 1ch UV hist (no face attention), "v3" RGB-only (no UV branch)
    OUTPUT_DIR = OUTPUT_ROOT / MODEL_NAME
    CHECKPOINT_DIR = OUTPUT_DIR / "checkpoints"
    LOG_DIR = OUTPUT_DIR / "logs"
    RESULT_DIR = OUTPUT_DIR / "results"

    # ==================== Ablation ====================
    # Ablation-1: Face-Only（去掉 GlobalStream，face_feat 直连 head）
    ABLATION_FACE_ONLY = False
    # Ablation-2: SimpleConcat（门控融合 → 简单 concat + MLP）
    # 可选值: "gated" (默认) / "concat"
    ABLATION_FUSION_TYPE = "gated"
    # Ablation-3: ResNet50 Backbone（通过 CLI --rgb-backbone resnet50 --global-backbone resnet50 控制）
    #            不需要额外 config 参数

    # ==================== Multi-Head ====================
    # 设为 True 开启多属性 head 模式（并联多个 ScoreHead，共享特征提取器）
    MULTI_HEAD = False
    # 多属性 head 名称列表（与 GT xlsx 文件名中的 attribute_serial 对应）
    # 例如: ["01Preference", "02Attractiveness", "03Feminine", ...]
    ATTRIBUTE_HEAD_NAMES = None  # None 或 [] 表示回退到单 head
    # 多属性 GT 文件目录（存放 toMax_gt_*.xlsx 的文件夹路径）
    ATTRIBUTE_GT_DIR = None  # 例如: Path("/root/autodl-tmp/gt")

    # ==================== Dataset split ====================
    TRAIN_RATIO = 0.7
    VAL_RATIO = 0.15
    TEST_RATIO = 0.15
    RANDOM_SEED = 666
    SPLIT_STRATEGY = "stable_by_id_hash"
    TEST_SPLIT_SOURCE = "subset"
    # manual_prefix 策略专用：手动指定进入 val/test 的 original_name 前缀列表
    # 前缀格式：从 original_name（如 f08rrs02_01）去掉末尾 _数字 后缀，即 f08rrs02
    # 示例: VALID_PREFIXES = ["f08rrs02", "f08rrs04"]
    VALID_PREFIXES = None   # None 或 [] 表示不手动指定（回退到自动切分）
    TEST_PREFIXES = None    # None 或 [] 表示不手动指定（回退到自动切分）
    # 划分结果导出路径（None 不导出）
    SPLIT_EXPORT_PATH = None  # 例如: OUTPUT_DIR / "split_result.xlsx"

    # ==================== Augmentation ====================
    AUGMENTATION = {
        "horizontal_flip": True,
        "rotation_degree": 10,
        "enable_color_jitter": False,
        "brightness_range": (0.8, 1.2),
        "contrast_range": (0.8, 1.2),
    }

    # ==================== Model ====================
    FACE_INPUT_SIZE = (224, 224)

    MODEL = {
        "face_stream": {
            "rgb_backbone": "simple_cnn",  # "simple_cnn"/"resnet50"/"efficientnet_b0"
            "rgb_pretrained": False,  # only applies to torchvision backbones
            "rgb_feature_dim": 256,
            "uv_hist_bins": 64,
            "uv_hist_u_range": [0.0, 1.0],
            "uv_hist_v_range": [0.0, 1.0],
            # When using UV maps (not hist), apply log-ratio transform (log(R/G), log(B/G)) then normalize to [0,1].
            "uv_log_ratio": True,
            "uv_log_clip": 3.0,
            # UV branch expects histogram (flattened) -> MLP by default; set to "cnn" to use conv on (bins,bins).
            "uv_branch_type": "mlp",  # "mlp" or "cnn"
            "uv_mlp_hidden_dims": [512, 256],
            "uv_channels": 2,
            "uv_feature_dim": 128,
            "uv_conv_layers": [32, 64, 128, 128],
        },
        "global_stream": {
            "backbone": "simple_cnn",  # "simple_cnn"/"resnet50"/"mobilenet_v3_small"/"mobilenet_v3_large"/"efficientnet_b0"
            "pretrained": False,  # only applies to torchvision backbones
            "feature_dim": 256,
        },
        "fusion": {
            "fusion_dim": 256,
            "dropout": 0.3,
        },
        "prediction_heads": {
            "preference_score": {
                "hidden_dims": [128, 64],
                "output_dim": 1,
            }
        },
    }

    # ==================== Training ====================
    TRAINING = {
        "optimizer": "AdamW",
        "learning_rate": 7e-4,
        "weight_decay": 1e-4,
        "scheduler": "CosineAnnealingWarmRestarts",
        "warmup_epochs": 5,
        "min_lr": 1e-6,
        "T_0": 10,
        "batch_size": 256,
        "num_epochs": 1000,
        "gradient_clip": 1.0,
        "early_stopping_patience": 100,
        "mixed_precision": True,
        "checkpoint_interval": 100,
    }

    # ==================== DataLoader ====================
    # Note (Windows): num_workers>0 can improve throughput but may expose multiprocess issues
    # depending on environment; keep default 0 and override via CLI/config when stable.
    DATALOADER = {
        "num_workers": 0,
        "pin_memory": True,
        "persistent_workers": False,
        "prefetch_factor": 2,
    }

    # ==================== Loss (score-only) ====================
    LOSS = {
        "label_smoothing": 0.01,
        "extreme_weighting": {"enabled": True, "lambda": 2.0, "gamma": 2.0},
        "pearson_weight": 3,
    }

    # ==================== Device/Logging ====================
    DEVICE = "cuda"
    LOGGING = {"level": "INFO", "tensorboard": True}

    @classmethod
    def get_config_dict(cls) -> dict:
        cfg = {}
        for key in dir(cls):
            if not key.startswith("_") and key.isupper():
                value = getattr(cls, key)
                if isinstance(value, Path):
                    cfg[key] = str(value)
                elif isinstance(value, dict):
                    cfg[key] = _convert_paths_in_dict(value)
                else:
                    cfg[key] = value
        return cfg


def _convert_paths_in_dict(d: dict) -> dict:
    out = {}
    for k, v in d.items():
        if isinstance(v, dict):
            out[k] = _convert_paths_in_dict(v)
        elif isinstance(v, Path):
            out[k] = str(v)
        else:
            out[k] = v
    return out
