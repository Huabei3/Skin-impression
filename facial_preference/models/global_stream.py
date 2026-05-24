"""
Global and statistical streams for the facial color preference network.

This module provides:
- GlobalStream: CNN backbone over the global RGB image.
- StatisticalStream: MLP over hand-crafted scene statistics.
- SceneFeatureExtractor: utilities to build the 13-D statistical feature vector.

The final 13-D statistical feature vector has the following layout:
- dims 0–4: brightness statistics (mean, std, 10%/50%/90% quantiles)
- dim 5: normalized color temperature
- dims 6–7: indoor / outdoor one-hot (2-D)
- dims 8–9: gender one-hot (female, male)
- dims 10–12: 3-way race one-hot (light, Asian, dark)
Gender and race are estimated with DeepFace from the face RGB crop.
"""

from typing import Dict, Tuple, List, Union

import numpy as np
import torch
import torch.nn as nn
import torchvision.models as models
from scipy.ndimage import gaussian_gradient_magnitude, uniform_filter

# Optional DeepFace support for gender / race estimation.
# NOTE: Import lazily to avoid heavy imports (and TensorFlow logs) when DeepFace
# isn't actually needed (e.g. parameter counting, lightweight inference).
DeepFace = None  # type: ignore
_DEEPFACE_AVAILABLE: bool = False
_DEEPFACE_TRIED_IMPORT: bool = False


def _get_deepface():  # pragma: no cover - optional dependency
    global DeepFace, _DEEPFACE_AVAILABLE, _DEEPFACE_TRIED_IMPORT  # noqa: PLW0603
    if _DEEPFACE_TRIED_IMPORT:
        return DeepFace
    _DEEPFACE_TRIED_IMPORT = True
    try:
        from deepface import DeepFace as _DeepFace  # type: ignore

        DeepFace = _DeepFace  # type: ignore
        _DEEPFACE_AVAILABLE = True
    except Exception:
        DeepFace = None  # type: ignore
        _DEEPFACE_AVAILABLE = False
    return DeepFace


# Map DeepFace's fine-grained race labels to 3 coarse classes
_DEEPFACE_RACE_TO_THREE_CLASS = {
    "asian": "asian",  # Asian -> Asian
    "indian": "asian",  # Indian -> Asian group
    "white": "light",  # Caucasian / White -> Light
    "middle eastern": "light",  # Middle Eastern -> Light
    "latino hispanic": "dark",  # Latino / Hispanic -> Dark group
    "black": "dark",  # African / Black -> Dark
}

# Numerical encoding for the 3 race classes
_THREE_CLASS_TO_ID = {
    "light": 0.0,
    "asian": 1.0,
    "dark": 2.0,
}


class GlobalStream(nn.Module):
    """Global stream: captures global scene information from RGB image."""

    def __init__(self, config: Dict):
        super().__init__()

        global_config = config["MODEL"]["global_stream"]
        backbone_name = global_config.get("backbone", "mobilenet_v3_small")
        pretrained = bool(global_config.get("pretrained", True))

        if backbone_name == "mobilenet_v3_small":
            self.backbone = models.mobilenet_v3_small(pretrained=pretrained)
            in_features = self.backbone.classifier[0].in_features
            self.backbone.classifier = nn.Identity()
        elif backbone_name == "mobilenet_v3_large":
            self.backbone = models.mobilenet_v3_large(pretrained=pretrained)
            in_features = self.backbone.classifier[0].in_features
            self.backbone.classifier = nn.Identity()
        elif backbone_name == "efficientnet_b0":
            self.backbone = models.efficientnet_b0(pretrained=pretrained)
            in_features = self.backbone.classifier[1].in_features
            self.backbone.classifier = nn.Identity()
        else:  # pragma: no cover - config error
            raise ValueError(f"Unsupported global backbone: {backbone_name}")

        # Project backbone features to configured dimension
        feat_dim = int(global_config.get("feature_dim", 256))
        self.feature_projector = nn.Sequential(
            nn.Linear(in_features, feat_dim),
            nn.BatchNorm1d(feat_dim),
            nn.ReLU(inplace=True),
            nn.Dropout(0.2),
        )

        self.output_dim = feat_dim

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        """
        Args:
            x: global RGB image, shape (B, 3, H, W)

        Returns:
            Global feature tensor, shape (B, feature_dim)
        """
        features = self.backbone(x)

        if features.ndim > 2:
            features = features.view(features.size(0), -1)

        features = self.feature_projector(features)
        return features


class StatisticalStream(nn.Module):
    """Statistical stream: processes hand-crafted scene / subject statistics."""

    def __init__(self, config: Dict):
        super().__init__()

        stat_config = config["MODEL"]["stat_stream"]
        in_dim = int(stat_config["input_dim"])
        hidden_dims: List[int] = list(stat_config["hidden_dims"])
        out_dim = int(stat_config["output_dim"])

        layers: List[nn.Module] = []
        for hidden_dim in hidden_dims:
            layers.append(nn.Linear(in_dim, hidden_dim))
            layers.append(nn.BatchNorm1d(hidden_dim))
            layers.append(nn.ReLU(inplace=True))
            layers.append(nn.Dropout(0.1))
            in_dim = hidden_dim

        layers.append(nn.Linear(in_dim, out_dim))
        layers.append(nn.BatchNorm1d(out_dim))
        layers.append(nn.ReLU(inplace=True))

        self.mlp = nn.Sequential(*layers)
        self.output_dim = out_dim

    def forward(self, stat_features: torch.Tensor) -> torch.Tensor:
        """
        Args:
            stat_features: (B, input_dim) statistical feature vectors.

        Returns:
            Processed features, shape (B, output_dim).
        """
        return self.mlp(stat_features)


class SceneFeatureExtractor:
    """
    Extracts hand-crafted scene statistics from images.

    By default we build a 13-D feature vector per sample:
    [0] mean luminance
    [1] luminance std
    [2] luminance 10% quantile
    [3] luminance 50% quantile
    [4] luminance 90% quantile
    [5] normalized color temperature
    [6] indoor / outdoor flag (0 = indoor, 1 = outdoor)
    [7] complement of [6] so that [6] + [7] = 1
    [8:10] gender one-hot (female, male), from DeepFace
    [10:13] race one-hot (light, Asian, dark), from DeepFace

    For backward compatibility with older models, we also support
    the original 10-D layout:
    [0:5] brightness stats, [5] color temperature, [6:8] indoor/outdoor
    one-hot, [8:10] reserved zeros (no gender / race).
    """

    # Global switch: True -> use new 13-D features; False -> legacy 10-D features
    NEW_STAT_FEATURES: bool = True

    # ------------------------------------------------------------------
    # Brightness statistics
    # ------------------------------------------------------------------
    @staticmethod
    def extract_brightness_stats(
        image: torch.Tensor,
    ) -> Union[Dict[str, float], List[Dict[str, float]]]:
        """
        Extract brightness statistics for a single image or a batch.

        Args:
            image: RGB image tensor:
                - Shape (3, H, W) for single image, or
                - Shape (B, 3, H, W) for a batch.
        """
        if image.ndim == 4:
            batch_stats: List[Dict[str, float]] = []
            for img in image:
                stats = SceneFeatureExtractor._extract_single_brightness(img)
                batch_stats.append(stats)
            return batch_stats

        return SceneFeatureExtractor._extract_single_brightness(image)

    @staticmethod
    def _extract_single_brightness(image: torch.Tensor) -> Dict[str, float]:
        """
        Extract brightness statistics from a single RGB image (3, H, W).
        """
        gray = 0.299 * image[0] + 0.587 * image[1] + 0.114 * image[2]
        flat = gray.flatten()

        stats = {
            "mean": float(gray.mean()),
            "std": float(gray.std()),
            "quantile_10": float(torch.quantile(flat, 0.1)),
            "quantile_50": float(torch.quantile(flat, 0.5)),
            "quantile_90": float(torch.quantile(flat, 0.9)),
        }
        return stats

    # ------------------------------------------------------------------
    # Color temperature estimation
    # ------------------------------------------------------------------
    @staticmethod
    def estimate_color_temperature_grey_pixel(image: torch.Tensor) -> float:
        """
        Estimate color temperature (Kelvin) using the Grey Pixel method.

        Args:
            image: RGB image (3, H, W), float in [0, 1].
        """
        if image.is_cuda:
            img_np = image.detach().cpu().numpy()
        else:
            img_np = image.detach().numpy()

        img_np = np.transpose(img_np, (1, 2, 0))  # HWC, RGB

        gi = GraynessIndex(
            percentage_of_GPs=0.1,
            delta_threshold=1e-4,
            epsilon=1e-7,
        )
        mean_gray_pixel = gi.apply(img_np)

        if len(mean_gray_pixel) == 3:
            r, g, b = mean_gray_pixel

            if b > 0:
                rb_ratio = r / b
                # Map R/B ratio to color temperature roughly
                if rb_ratio > 1.2:
                    color_temp = 3000 + (1.5 - rb_ratio) * 2000
                elif rb_ratio < 0.9:
                    color_temp = 5500 + (1.0 - rb_ratio) * 3000
                else:
                    color_temp = 5500 - (rb_ratio - 1.0) * 2500

                color_temp = max(2000, min(10000, color_temp))
            else:
                color_temp = 5500.0
        else:
            color_temp = 5500.0

        return float(color_temp)

    @staticmethod
    def estimate_color_temperature(image: torch.Tensor) -> float:
        """Public wrapper for Grey Pixel color temperature estimation."""
        return SceneFeatureExtractor.estimate_color_temperature_grey_pixel(image)

    # ------------------------------------------------------------------
    # Simple indoor / outdoor classification
    # ------------------------------------------------------------------
    @staticmethod
    def classify_scene(image: torch.Tensor) -> int:
        """
        Very simple scene classification: 0 = indoor, 1 = outdoor.
        Heuristic based on brightness and blue channel dominance.
        """
        gray = 0.299 * image[0] + 0.587 * image[1] + 0.114 * image[2]
        mean_brightness = gray.mean()

        blue_ratio = image[2].mean() / (image.mean() + 1e-6)

        if mean_brightness > 0.6 and blue_ratio > 0.35:
            return 1
        return 0

    # ------------------------------------------------------------------
    # DeepFace-based gender & race extraction
    # ------------------------------------------------------------------
    @staticmethod
    def _extract_gender_and_race(face_image: torch.Tensor) -> Tuple[float, float]:
        """
        Estimate gender and race_id using DeepFace.

        Args:
            face_image: face RGB crop (3, H, W), float in [0, 1].

        Returns:
            (gender, race_id):
            - gender: 0.0 = female, 1.0 = male.
            - race_id: 0.0 = light, 1.0 = Asian, 2.0 = dark.

        If DeepFace is not available or inference fails, returns (0.0, 0.0).
        """
        deepface = _get_deepface()
        if not _DEEPFACE_AVAILABLE or deepface is None:
            return 0.0, 0.0

        try:
            img = face_image.detach()
            if img.is_cuda:
                img = img.cpu()

            img_np = img.numpy()
            if img_np.max() <= 1.0 + 1e-6:
                img_np = np.clip(img_np * 255.0, 0, 255).astype("uint8")
            else:
                img_np = np.clip(img_np, 0, 255).astype("uint8")

            img_np = np.transpose(img_np, (1, 2, 0))  # HWC, RGB
            img_bgr = img_np[:, :, ::-1]  # HWC, BGR for OpenCV

            analysis = deepface.analyze(
                img_path=img_bgr,
                actions=["gender", "race"],
                enforce_detection=False,
                silent=True,
            )

            if isinstance(analysis, list) and analysis:
                analysis = analysis[0]

            gender_raw = str(analysis.get("dominant_gender", "")).lower()
            gender_value = 1.0 if gender_raw.startswith("m") else 0.0

            dominant_race = analysis.get("dominant_race", "")
            race_value = 0.0
            if isinstance(dominant_race, str) and dominant_race:
                dominant_race_l = dominant_race.lower()
                coarse = _DEEPFACE_RACE_TO_THREE_CLASS.get(dominant_race_l)
                if coarse in _THREE_CLASS_TO_ID:
                    race_value = _THREE_CLASS_TO_ID[coarse]

            return gender_value, race_value
        except Exception:
            # Inference failure should not break training; fall back to zeros.
            return 0.0, 0.0

    # ------------------------------------------------------------------
    # Final 10-D statistical feature vector
    # ------------------------------------------------------------------
    @staticmethod
    def prepare_statistical_features(
        image: torch.Tensor,
        global_image: torch.Tensor = None,
    ) -> torch.Tensor:
        """
        Build statistical feature vector per sample.

        Args:
            image: face RGB tensor, shape (B, 3, H, W).
            global_image: optional global RGB tensor (B, 3, H, W).

        Returns:
            Tensor of shape (B, 10) if NEW_STAT_FEATURES is False,
            or (B, 13) if NEW_STAT_FEATURES is True.
        """
        batch_size = image.size(0)
        features_list: List[torch.Tensor] = []

        # Use global image for scene statistics when available
        source_image = global_image if global_image is not None else image

        for i in range(batch_size):
            scene_img = source_image[i]
            face_img = image[i]

            # Brightness statistics (from scene image)
            brightness_stats = SceneFeatureExtractor._extract_single_brightness(scene_img)

            # Color temperature (normalized)
            color_temp = SceneFeatureExtractor.estimate_color_temperature(scene_img)
            color_temp_normalized = (color_temp - 5500.0) / 2500.0

            # Simple indoor / outdoor classification
            scene_class = SceneFeatureExtractor.classify_scene(scene_img)

            if SceneFeatureExtractor.NEW_STAT_FEATURES:
                # New mode: use gender + race one-hot to build 13-D vector.
                gender_value, race_value = SceneFeatureExtractor._extract_gender_and_race(
                    face_img
                )

                # One-hot encode gender: 0=female -> [1,0], 1=male -> [0,1]
                gender_idx = 1 if float(gender_value) >= 0.5 else 0
                gender_one_hot = [1.0, 0.0] if gender_idx == 0 else [0.0, 1.0]

                # One-hot encode race: 0=light, 1=Asian, 2=dark
                try:
                    race_idx = int(round(float(race_value)))
                except Exception:
                    race_idx = 0
                if race_idx < 0 or race_idx > 2:
                    race_idx = 0
                race_one_hot = [0.0, 0.0, 0.0]
                race_one_hot[race_idx] = 1.0

                # Compose 13-D feature vector
                features = torch.tensor(
                    [
                        brightness_stats["mean"],
                        brightness_stats["std"],
                        brightness_stats["quantile_10"],
                        brightness_stats["quantile_50"],
                        brightness_stats["quantile_90"],
                        color_temp_normalized,
                        float(scene_class),
                        1.0 - float(scene_class),
                        gender_one_hot[0],
                        gender_one_hot[1],
                        race_one_hot[0],
                        race_one_hot[1],
                        race_one_hot[2],
                    ],
                    dtype=torch.float32,
                )
            else:
                # Legacy 10-D mode: no DeepFace; last two dims are reserved zeros.
                features = torch.tensor(
                    [
                        brightness_stats["mean"],
                        brightness_stats["std"],
                        brightness_stats["quantile_10"],
                        brightness_stats["quantile_50"],
                        brightness_stats["quantile_90"],
                        color_temp_normalized,
                        float(scene_class),
                        1.0 - float(scene_class),
                        0.0,
                        0.0,
                    ],
                    dtype=torch.float32,
                )

            features_list.append(features)

        return torch.stack(features_list).to(image.device)


class GraynessIndex:
    """
    Grey Pixel implementation used for color temperature estimation.

    This is adapted to operate on numpy arrays with shape (H, W, 3),
    values in [0, 1].
    """

    def __init__(
        self,
        percentage_of_GPs: float = 0.1,
        delta_threshold: float = 1e-4,
        epsilon: float = 1e-7,
    ) -> None:
        self.percentage_of_GPs = percentage_of_GPs
        self.delta_threshold = delta_threshold
        self.epsilon = epsilon

    def apply_smoothing(self, x: np.ndarray) -> np.ndarray:
        return uniform_filter(x, 7, mode="wrap")

    def derivative_gaussian(self, x: np.ndarray) -> np.ndarray:
        return gaussian_gradient_magnitude(x, sigma=0.5, mode="nearest") / 2.0

    def apply(self, I: np.ndarray) -> np.ndarray:
        """
        Grey Pixel computation.

        Args:
            I: RGB input image, shape (H, W, 3), values in [0, 1].

        Returns:
            mean chosen gray pixels as a normalized RGB vector.
        """
        h, w, c = I.shape
        num_pixels = h * w
        num_GPs = int(
            np.floor(self.percentage_of_GPs * num_pixels / 100.0).astype(int)
        )

        R = I[:, :, 0]
        G = I[:, :, 1]
        B = I[:, :, 2]
        M = (np.max(I, axis=-1) >= 0.95) | (np.sum(I, axis=-1) <= 0.0315)
        img_col = np.reshape(I, (num_pixels, c))

        R = self.apply_smoothing(R)
        G = self.apply_smoothing(G)
        B = self.apply_smoothing(B)
        M = M | (R == 0) | (G == 0) | (B == 0)

        R[R <= 0] = self.epsilon
        G[G <= 0] = self.epsilon
        B[B <= 0] = self.epsilon
        norm1 = R + G + B

        delta_R = self.derivative_gaussian(R)
        delta_G = self.derivative_gaussian(G)
        delta_B = self.derivative_gaussian(B)
        M = M | (
            (delta_R <= self.delta_threshold)
            & (delta_G <= self.delta_threshold)
            & (delta_B <= self.delta_threshold)
        )

        norm1[norm1 == 0] = self.epsilon
        log_R = np.log(R) - np.log(norm1)
        log_B = np.log(B) - np.log(norm1)

        delta_log_R = self.derivative_gaussian(log_R)
        delta_log_B = self.derivative_gaussian(log_B)
        M = M | (delta_log_R == np.inf) | (delta_log_B == np.inf)

        delta = np.stack(
            [
                np.reshape(delta_log_R, (h * w, -1)),
                np.reshape(delta_log_B, (h * w, -1)),
            ],
            axis=-1,
        )

        norm2 = np.linalg.norm(delta, axis=-1)
        uniq_lightmap = np.reshape(norm2, delta_log_R.shape)
        uniq_lightmap[M == 1] = np.max(uniq_lightmap)
        uniq_lightmap = self.apply_smoothing(uniq_lightmap)
        uniq_lightmap_flat = np.reshape(uniq_lightmap, (num_pixels,))
        sorted_uniq_lightmap_flat = np.sort(uniq_lightmap_flat)

        unique_GIs = np.zeros_like(uniq_lightmap_flat)
        if num_GPs > 0:
            threshold = sorted_uniq_lightmap_flat[num_GPs - 1]
            unique_GIs[uniq_lightmap_flat < threshold] = 1

        mean_chosen_pixels = np.mean(img_col[unique_GIs == 1, :], axis=0)

        denom = np.sqrt((mean_chosen_pixels ** 2).sum())
        if denom == 0:
            return np.zeros_like(mean_chosen_pixels)

        return mean_chosen_pixels / denom
