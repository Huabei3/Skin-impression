"""
toMax dataset inference with group-wise ranking analysis
Calculates Spearman correlation within each group of 33 images
"""
import numpy as np
import os
import torch
import torch.nn as nn
import torchvision.transforms as transforms
from PIL import Image, ImageDraw, ImageFont
import scipy.io as sio
from scipy.stats import spearmanr
import glob
import sys
import csv

sys.path.insert(0, '/root/autodl-tmp/SCUT_FBP5500/trained_models_for_pytorch')
import Nets


def load_model(pretrained_dict, new):
    model_dict = new.state_dict()
    pretrained_dict = {k: v for k, v in pretrained_dict['state_dict'].items() if k in model_dict}
    model_dict.update(pretrained_dict)
    new.load_state_dict(model_dict)


def parse_tomax_by_groups(base_dir):
    """Parse toMax dataset and organize by groups"""
    groups = {}
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

                group_data = []
                for i, score in enumerate(p_group, start=1):
                    img_name = f"{group_name}_{i:02d}.jpg"
                    img_path = os.path.join(drawable_path, img_name)

                    if os.path.exists(img_path):
                        group_data.append({
                            'img_path': img_path,
                            'img_name': img_name,
                            'gt_score': float(score),
                            'index': i
                        })

                if len(group_data) > 0:
                    groups[group_name] = group_data

            except Exception as e:
                print(f"Error loading {mat_file}: {e}")
                continue

    return groups


def annotate_image(img_path, pred_score, gt_score, output_path):
    """Annotate image with SCUT-FBP5500 prediction and p_group ground truth"""
    try:
        img = Image.open(img_path).convert('RGB')
        draw = ImageDraw.Draw(img)

        try:
            font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 24)
        except:
            font = ImageFont.load_default()

        text = f"SCUT Pred: {pred_score:.3f}\np_group GT: {gt_score:.3f}"

        bbox = draw.textbbox((10, 10), text, font=font)
        draw.rectangle(bbox, fill='black')
        draw.text((10, 10), text, fill='yellow', font=font)

        img.save(output_path)
        return True
    except Exception as e:
        print(f"Error annotating {img_path}: {e}")
        return False


def main():
    device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
    print(f'Using device: {device}')

    net = Nets.ResNet(block=Nets.BasicBlock, layers=[2, 2, 2, 2], num_classes=1).to(device)
    model_path = '/root/autodl-tmp/SCUT_FBP5500/trained_models_for_pytorch/models/resnet18_hf.pth'

    print(f'Loading model from: {model_path}')
    checkpoint = torch.load(model_path, map_location=device, encoding='latin1')
    load_model(checkpoint, net)
    net.eval()

    base_dir = '/root/autodl-tmp/toMax'
    print(f'\nParsing dataset from: {base_dir}')
    groups = parse_tomax_by_groups(base_dir)

    if len(groups) == 0:
        print("Error: No valid data found!")
        return

    print(f'\nFound {len(groups)} groups')
    total_images = sum(len(g) for g in groups.values())
    print(f'Total images: {total_images}')

    output_dir = '/root/autodl-tmp/output_ranking'
    os.makedirs(output_dir, exist_ok=True)
    annotated_dir = os.path.join(output_dir, 'annotated_images')
    os.makedirs(annotated_dir, exist_ok=True)

    transform = transforms.Compose([
        transforms.Resize(256),
        transforms.CenterCrop(224),
        transforms.ToTensor(),
        transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]),
    ])

    print('\nRunning inference...')
    group_results = {}
    all_predictions = []
    all_labels = []

    with torch.no_grad():
        for group_name, group_data in groups.items():
            print(f'\nProcessing group: {group_name} ({len(group_data)} images)')

            for item in group_data:
                try:
                    img = Image.open(item['img_path']).convert('RGB')
                    img_tensor = transform(img).unsqueeze(0).to(device)
                    output = net(img_tensor).squeeze()

                    pred_score = output.cpu().item()
                    item['pred_score'] = pred_score

                    all_predictions.append(pred_score)
                    all_labels.append(item['gt_score'])

                except Exception as e:
                    print(f"Error processing {item['img_path']}: {e}")
                    continue

            group_results[group_name] = group_data

    # Calculate group-wise Spearman correlation
    print('\n=== Group-wise Ranking Analysis ===')
    group_correlations = []

    csv_path = os.path.join(output_dir, 'group_ranking_results.csv')
    with open(csv_path, 'w', newline='') as f:
        writer = csv.writer(f)
        writer.writerow(['group_name', 'num_images', 'spearman_corr', 'p_value'])

        for group_name, group_data in group_results.items():
            if len(group_data) < 2:
                continue

            preds = [item['pred_score'] for item in group_data]
            gts = [item['gt_score'] for item in group_data]

            corr, p_value = spearmanr(preds, gts)
            group_correlations.append(corr)

            writer.writerow([group_name, len(group_data), f'{corr:.4f}', f'{p_value:.4f}'])
            print(f'{group_name}: Spearman={corr:.4f}, p={p_value:.4f}, n={len(group_data)}')

    mean_spearman = np.mean(group_correlations)
    print(f'\nMean Spearman correlation across groups: {mean_spearman:.4f}')

    # Overall Pearson correlation
    all_predictions = np.array(all_predictions)
    all_labels = np.array(all_labels)
    overall_pearson = np.corrcoef(all_predictions, all_labels)[0][1]
    print(f'Overall Pearson correlation: {overall_pearson:.4f}')

    # Annotate all images
    print(f'\nAnnotating images to {annotated_dir}...')
    count = 0
    for group_name, group_data in group_results.items():
        for item in group_data:
            if 'pred_score' not in item:
                continue
            output_path = os.path.join(annotated_dir, item['img_name'])
            annotate_image(item['img_path'], item['pred_score'],
                         item['gt_score'], output_path)
            count += 1
            if count % 100 == 0:
                print(f'Annotated {count} images')

    print(f'\nTotal annotated: {count} images')
    print(f'Results saved to: {output_dir}')

    # Save summary
    summary_path = os.path.join(output_dir, 'summary.txt')
    with open(summary_path, 'w') as f:
        f.write('=== Group-wise Ranking Analysis Summary ===\n')
        f.write(f'Total groups: {len(groups)}\n')
        f.write(f'Total images: {total_images}\n')
        f.write(f'Mean Spearman correlation: {mean_spearman:.4f}\n')
        f.write(f'Overall Pearson correlation: {overall_pearson:.4f}\n')
        f.write(f'\nPrediction range: [{all_predictions.min():.3f}, {all_predictions.max():.3f}]\n')
        f.write(f'Ground truth range: [{all_labels.min():.3f}, {all_labels.max():.3f}]\n')


if __name__ == '__main__':
    main()

