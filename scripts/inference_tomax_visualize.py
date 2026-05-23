"""
Custom dataset inference script for toMax dataset with visualization
Saves predictions and ground truth on images
"""
import numpy as np
import os
import torch
import torch.nn as nn
import torchvision.transforms as transforms
from PIL import Image, ImageDraw, ImageFont
import scipy.io as sio
import glob
import sys
import csv

# Add parent directory to path to import Nets
sys.path.insert(0, '/root/autodl-tmp/SCUT_FBP5500/trained_models_for_pytorch')
import Nets


def load_model(pretrained_dict, new):
    model_dict = new.state_dict()
    pretrained_dict = {k: v for k, v in pretrained_dict['state_dict'].items() if k in model_dict}
    model_dict.update(pretrained_dict)
    new.load_state_dict(model_dict)


def parse_tomax_dataset(base_dir):
    """Parse toMax dataset structure"""
    dataset = []
    subdirs = sorted([d for d in os.listdir(base_dir)
                     if os.path.isdir(os.path.join(base_dir, d))])

    print(f"Found {len(subdirs)} subdirectories: {subdirs[:5]}...")

    for subdir in subdirs:
        subdir_path = os.path.join(base_dir, subdir)
        drawable_path = os.path.join(subdir_path, 'drawable')
        if not os.path.exists(drawable_path):
            continue

        labnscore_path = os.path.join(subdir_path, 'non_model', '01Preference', 'labNscore')
        if not os.path.exists(labnscore_path):
            continue

        mat_files = glob.glob(os.path.join(labnscore_path, 'labNscore_group*.mat'))

        for mat_file in mat_files:
            mat_filename = os.path.basename(mat_file)
            group_name = mat_filename.replace('labNscore_group', '').replace('.mat', '')

            try:
                mat_data = sio.loadmat(mat_file)
                if 'p_group' not in mat_data:
                    continue

                p_group = mat_data['p_group'].flatten()

                for i, score in enumerate(p_group, start=1):
                    img_name = f"{group_name}_{i:02d}.jpg"
                    img_path = os.path.join(drawable_path, img_name)

                    if os.path.exists(img_path):
                        dataset.append((img_path, float(score), group_name))

            except Exception as e:
                print(f"Error loading {mat_file}: {e}")
                continue

    return dataset


def annotate_image(img_path, pred_raw, pred_norm, gt_score, output_path):
    """Annotate image with prediction and ground truth"""
    try:
        img = Image.open(img_path).convert('RGB')
        draw = ImageDraw.Draw(img)

        # Try to use a font, fallback to default if not available
        try:
            font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 20)
        except:
            font = ImageFont.load_default()

        # Add text with background
        text = f"Pred(raw): {pred_raw:.3f}\nPred(norm): {pred_norm:.3f}\nGT: {gt_score:.3f}"

        # Draw text with white background
        bbox = draw.textbbox((10, 10), text, font=font)
        draw.rectangle(bbox, fill='white')
        draw.text((10, 10), text, fill='red', font=font)

        img.save(output_path)
        return True
    except Exception as e:
        print(f"Error annotating {img_path}: {e}")
        return False


def main():
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
    print(f'Score range: [{min(s for _, s, _ in dataset):.3f}, {max(s for _, s, _ in dataset):.3f}]')

    # Create output directory
    output_dir = '/root/autodl-tmp/output'
    os.makedirs(output_dir, exist_ok=True)
    annotated_dir = os.path.join(output_dir, 'annotated_images')
    os.makedirs(annotated_dir, exist_ok=True)

    # Image preprocessing
    transform = transforms.Compose([
        transforms.Resize(256),
        transforms.CenterCrop(224),
        transforms.ToTensor(),
        transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]),
    ])

    # Run inference
    print('\nRunning inference...')
    results = []

    with torch.no_grad():
        for i, (img_path, score, group_name) in enumerate(dataset):
            try:
                img = Image.open(img_path).convert('RGB')
                img_tensor = transform(img).unsqueeze(0).to(device)
                output = net(img_tensor).squeeze()

                pred_raw = output.cpu().item()
                results.append({
                    'image_name': os.path.basename(img_path),
                    'group_name': group_name,
                    'prediction_raw': pred_raw,
                    'ground_truth': score,
                    'image_path': img_path
                })

                if (i + 1) % 100 == 0:
                    print(f'Processed {i + 1}/{len(dataset)} images')

            except Exception as e:
                print(f"Error processing {img_path}: {e}")
                continue

    # Calculate normalized predictions
    predictions_raw = np.array([r['prediction_raw'] for r in results])
    labels = np.array([r['ground_truth'] for r in results])

    pred_min, pred_max = predictions_raw.min(), predictions_raw.max()
    predictions_normalized = (predictions_raw - pred_min) / (pred_max - pred_min) if pred_max > pred_min else predictions_raw

    # Add normalized predictions to results
    for i, r in enumerate(results):
        r['prediction_normalized'] = predictions_normalized[i]

    # Save results to CSV
    csv_path = os.path.join(output_dir, 'predictions.csv')
    with open(csv_path, 'w', newline='') as f:
        writer = csv.DictWriter(f, fieldnames=['image_name', 'group_name', 'prediction_raw',
                                                'prediction_normalized', 'ground_truth'])
        writer.writeheader()
        for r in results:
            writer.writerow({
                'image_name': r['image_name'],
                'group_name': r['group_name'],
                'prediction_raw': r['prediction_raw'],
                'prediction_normalized': r['prediction_normalized'],
                'ground_truth': r['ground_truth']
            })

    print(f'\nSaved predictions to: {csv_path}')

    # Annotate first 50 images
    print('\nAnnotating sample images...')
    for i, r in enumerate(results[:50]):
        output_path = os.path.join(annotated_dir, r['image_name'])
        annotate_image(r['image_path'], r['prediction_raw'],
                      r['prediction_normalized'], r['ground_truth'], output_path)

    print(f'Annotated {min(50, len(results))} images to: {annotated_dir}')

    # Calculate metrics
    correlation = np.corrcoef(labels, predictions_normalized)[0][1]
    mae = np.mean(np.abs(labels - predictions_normalized))
    rmse = np.sqrt(np.mean(np.square(labels - predictions_normalized)))

    # Save summary
    summary_path = os.path.join(output_dir, 'summary.txt')
    with open(summary_path, 'w') as f:
        f.write('=== Results Summary ===\n')
        f.write(f'Total images processed: {len(results)}\n')
        f.write(f'Correlation: {correlation:.4f}\n')
        f.write(f'MAE: {mae:.4f}\n')
        f.write(f'RMSE: {rmse:.4f}\n')
        f.write(f'\nPrediction range (raw): [{pred_min:.3f}, {pred_max:.3f}]\n')
        f.write(f'Prediction range (normalized): [{predictions_normalized.min():.3f}, {predictions_normalized.max():.3f}]\n')
        f.write(f'Ground truth range: [{labels.min():.3f}, {labels.max():.3f}]\n')

    print('\n=== Results ===')
    print(f'Total images processed: {len(results)}')
    print(f'Correlation: {correlation:.4f}')
    print(f'MAE: {mae:.4f}')
    print(f'RMSE: {rmse:.4f}')
    print(f'\nPrediction range (raw): [{pred_min:.3f}, {pred_max:.3f}]')
    print(f'Prediction range (normalized): [{predictions_normalized.min():.3f}, {predictions_normalized.max():.3f}]')
    print(f'Ground truth range: [{labels.min():.3f}, {labels.max():.3f}]')
    print(f'\nResults saved to: {output_dir}')


if __name__ == '__main__':
    main()
