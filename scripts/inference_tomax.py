"""
Custom dataset inference script for toMax dataset
Reads .mat files with p_group scores and runs inference on corresponding images
"""
import numpy as np
import os
import torch
import torch.nn as nn
import torchvision.transforms as transforms
from PIL import Image
import scipy.io as sio
import glob
import sys

# Add parent directory to path to import Nets
sys.path.insert(0, '/root/autodl-tmp/SCUT_FBP5500/trained_models_for_pytorch')
import Nets


def load_model(pretrained_dict, new):
    model_dict = new.state_dict()
    # 1. filter out unnecessary keys
    pretrained_dict = {k: v for k, v in pretrained_dict['state_dict'].items() if k in model_dict}
    # 2. overwrite entries in the existing state dict
    model_dict.update(pretrained_dict)
    new.load_state_dict(model_dict)


def parse_tomax_dataset(base_dir):
    """
    Parse toMax dataset structure
    Returns: list of (image_path, score) tuples
    """
    dataset = []

    # Get all first-level subdirectories (f01i, f01r, f02i, etc.)
    subdirs = sorted([d for d in os.listdir(base_dir)
                     if os.path.isdir(os.path.join(base_dir, d))])

    print(f"Found {len(subdirs)} subdirectories: {subdirs[:5]}...")

    for subdir in subdirs:
        subdir_path = os.path.join(base_dir, subdir)

        # Path to drawable images
        drawable_path = os.path.join(subdir_path, 'drawable')
        if not os.path.exists(drawable_path):
            print(f"Warning: {drawable_path} does not exist, skipping...")
            continue

        # Path to labNscore files
        labnscore_path = os.path.join(subdir_path, 'non_model', '01Preference', 'labNscore')
        if not os.path.exists(labnscore_path):
            print(f"Warning: {labnscore_path} does not exist, skipping...")
            continue

        # Get all labNscore_group*.mat files
        mat_files = glob.glob(os.path.join(labnscore_path, 'labNscore_group*.mat'))

        for mat_file in mat_files:
            # Extract group name (e.g., f01ih3k from labNscore_groupf01ih3k.mat)
            mat_filename = os.path.basename(mat_file)
            group_name = mat_filename.replace('labNscore_group', '').replace('.mat', '')

            # Load mat file
            try:
                mat_data = sio.loadmat(mat_file)
                if 'p_group' not in mat_data:
                    print(f"Warning: p_group not found in {mat_file}, skipping...")
                    continue

                p_group = mat_data['p_group'].flatten()  # Shape: (33,)

                # Match images
                for i, score in enumerate(p_group, start=1):
                    img_name = f"{group_name}_{i:02d}.jpg"
                    img_path = os.path.join(drawable_path, img_name)

                    if os.path.exists(img_path):
                        dataset.append((img_path, float(score)))
                    else:
                        print(f"Warning: Image not found: {img_path}")

            except Exception as e:
                print(f"Error loading {mat_file}: {e}")
                continue

    return dataset


def main():
    # Check CUDA availability
    device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
    print(f'Using device: {device}')

    # Load model
    net = Nets.ResNet(block=Nets.BasicBlock, layers=[2, 2, 2, 2], num_classes=1).to(device)
    model_path = '/root/autodl-tmp/SCUT_FBP5500/trained_models_for_pytorch/models/resnet18_hf.pth'

    print(f'Loading model from: {model_path}')
    checkpoint = torch.load(model_path, map_location=device, encoding='latin1')
    load_model(checkpoint, net)
    net.eval()

    # Parse dataset
    base_dir = '/root/autodl-tmp/toMax'
    print(f'\nParsing dataset from: {base_dir}')
    dataset = parse_tomax_dataset(base_dir)

    if len(dataset) == 0:
        print("Error: No valid data found!")
        return

    print(f'\nFound {len(dataset)} images with scores')
    print(f'Score range: [{min(s for _, s in dataset):.3f}, {max(s for _, s in dataset):.3f}]')

    # Image preprocessing
    transform = transforms.Compose([
        transforms.Resize(256),
        transforms.CenterCrop(224),
        transforms.ToTensor(),
        transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]),
    ])

    # Run inference
    print('\nRunning inference...')
    labels = []
    predictions = []

    with torch.no_grad():
        for i, (img_path, score) in enumerate(dataset):
            try:
                # Load and preprocess image
                img = Image.open(img_path).convert('RGB')
                img_tensor = transform(img).unsqueeze(0).to(device)

                # Predict
                output = net(img_tensor).squeeze()

                labels.append(score)
                predictions.append(output.cpu().item())

                if (i + 1) % 100 == 0:
                    print(f'Processed {i + 1}/{len(dataset)} images')

            except Exception as e:
                print(f"Error processing {img_path}: {e}")
                continue

    # Calculate metrics
    labels = np.array(labels)
    predictions = np.array(predictions)

    # Normalize predictions to [0, 1] range to match p_group scores
    pred_min, pred_max = predictions.min(), predictions.max()
    predictions_normalized = (predictions - pred_min) / (pred_max - pred_min)

    correlation = np.corrcoef(labels, predictions_normalized)[0][1]
    mae = np.mean(np.abs(labels - predictions_normalized))
    rmse = np.sqrt(np.mean(np.square(labels - predictions_normalized)))

    print('\n=== Results ===')
    print(f'Total images processed: {len(labels)}')
    print(f'Correlation: {correlation:.4f}')
    print(f'MAE: {mae:.4f}')
    print(f'RMSE: {rmse:.4f}')
    print(f'\nPrediction range (raw): [{pred_min:.3f}, {pred_max:.3f}]')
    print(f'Prediction range (normalized): [{predictions_normalized.min():.3f}, {predictions_normalized.max():.3f}]')
    print(f'Ground truth range: [{labels.min():.3f}, {labels.max():.3f}]')


if __name__ == '__main__':
    main()
