import os
import numpy as np
import torch
from torch.utils.data import Dataset, DataLoader
from PIL import Image
import scipy.io as sio
from torchvision import transforms


class SkinPreferenceDataset(Dataset):
    """Dataset for skin preference evaluation"""
    def __init__(self, data_root, transform=None, split='train', train_ratio=0.8):
        """
        Args:
            data_root: Root directory containing the dataset
            transform: Image transformations
            split: 'train' or 'test'
            train_ratio: Ratio of training data
        """
        self.data_root = data_root
        self.transform = transform
        self.split = split

        self.samples = []
        self._load_dataset()

        # Split dataset
        np.random.seed(42)
        indices = np.random.permutation(len(self.samples))
        split_idx = int(len(self.samples) * train_ratio)

        if split == 'train':
            self.samples = [self.samples[i] for i in indices[:split_idx]]
        else:
            self.samples = [self.samples[i] for i in indices[split_idx:]]

    def _load_dataset(self):
        """Load all image-score pairs from the dataset"""
        for subdir in os.listdir(self.data_root):
            subdir_path = os.path.join(self.data_root, subdir)
            if not os.path.isdir(subdir_path):
                continue

            drawable_path = os.path.join(subdir_path, 'drawable')
            if not os.path.exists(drawable_path):
                continue

            labnscore_path = os.path.join(subdir_path, 'non_model', '01Preference', 'labNscore')
            if not os.path.exists(labnscore_path):
                continue

            for mat_file in os.listdir(labnscore_path):
                if not mat_file.endswith('.mat') or mat_file.startswith('f0') and 'picname' in mat_file:
                    continue

                mat_path = os.path.join(labnscore_path, mat_file)

                try:
                    mat_data = sio.loadmat(mat_path)

                    if 'p_group' not in mat_data:
                        continue

                    p_group = mat_data['p_group'].flatten()

                    base_name = mat_file.replace('labNscore_group', '').replace('.mat', '')

                    for idx in range(len(p_group)):
                        img_name = f"{base_name}_{idx+1:02d}.jpg"
                        img_path = os.path.join(drawable_path, img_name)

                        if os.path.exists(img_path):
                            score = p_group[idx]
                            self.samples.append({
                                'image_path': img_path,
                                'score': score,
                                'group': base_name
                            })

                except Exception as e:
                    print(f"Error loading {mat_path}: {e}")
                    continue

        print(f"Loaded {len(self.samples)} samples for {self.split} split")

    def __len__(self):
        return len(self.samples)

    def __getitem__(self, idx):
        sample = self.samples[idx]

        image = Image.open(sample['image_path']).convert('RGB')

        if self.transform:
            image = self.transform(image)

        score = torch.tensor(sample['score'], dtype=torch.float32)

        return image, score


def get_transforms(img_size=224, augment=True):
    """Get image transformations"""
    if augment:
        transform = transforms.Compose([
            transforms.Resize((img_size, img_size)),
            transforms.RandomHorizontalFlip(p=0.5),
            transforms.ColorJitter(brightness=0.2, contrast=0.2, saturation=0.2, hue=0.1),
            transforms.RandomRotation(10),
            transforms.ToTensor(),
            transforms.Normalize(mean=[0.485, 0.456, 0.406],
                               std=[0.229, 0.224, 0.225])
        ])
    else:
        transform = transforms.Compose([
            transforms.Resize((img_size, img_size)),
            transforms.ToTensor(),
            transforms.Normalize(mean=[0.485, 0.456, 0.406],
                               std=[0.229, 0.224, 0.225])
        ])

    return transform


def get_dataloaders(data_root, batch_size=32, img_size=224, num_workers=4):
    """Create train and test dataloaders"""
    train_transform = get_transforms(img_size=img_size, augment=True)
    test_transform = get_transforms(img_size=img_size, augment=False)

    train_dataset = SkinPreferenceDataset(
        data_root=data_root,
        transform=train_transform,
        split='train'
    )

    test_dataset = SkinPreferenceDataset(
        data_root=data_root,
        transform=test_transform,
        split='test'
    )

    train_loader = DataLoader(
        train_dataset,
        batch_size=batch_size,
        shuffle=True,
        num_workers=num_workers,
        pin_memory=True
    )

    test_loader = DataLoader(
        test_dataset,
        batch_size=batch_size,
        shuffle=False,
        num_workers=num_workers,
        pin_memory=True
    )

    return train_loader, test_loader
