import os
import numpy as np
import torch
from torch.utils.data import Dataset, DataLoader
from PIL import Image
import scipy.io as sio
from torchvision import transforms


class SkinPreferenceDataset(Dataset):
    """Dataset for skin preference evaluation"""
    def __init__(self, data_root, transform=None, split='train', train_ratio=0.8, load_preference_center=False):
        """
        Args:
            data_root: Root directory containing the dataset (e.g., D:/work/.../toMax)
            transform: Image transformations
            split: 'train' or 'test'
            train_ratio: Ratio of training data
            load_preference_center: Whether to load L*a*b* preference center labels
        """
        self.data_root = data_root
        self.transform = transform
        self.split = split
        self.load_preference_center = load_preference_center

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
        # Iterate through all first-level subdirectories (e.g., f01i, f01r, etc.)
        for subdir in os.listdir(self.data_root):
            subdir_path = os.path.join(self.data_root, subdir)
            if not os.path.isdir(subdir_path):
                continue

            # Path to drawable folder
            drawable_path = os.path.join(subdir_path, 'drawable')
            if not os.path.exists(drawable_path):
                continue

            # Path to labNscore folder
            labnscore_path = os.path.join(subdir_path, 'non_model', '01Preference', 'labNscore')
            if not os.path.exists(labnscore_path):
                continue

            # Load preference center if needed
            preference_center_dict = {}
            if self.load_preference_center:
                # Load average_bf from each labNscore mat file
                for mat_file in os.listdir(labnscore_path):
                    if not mat_file.endswith('.mat') or 'picname' in mat_file:
                        continue

                    mat_path = os.path.join(labnscore_path, mat_file)
                    try:
                        mat_data = sio.loadmat(mat_path)
                        if 'average_bf' in mat_data:
                            # Extract group name: labNscore_groupf01ih3k.mat -> f01ih3k
                            group_name = mat_file.replace('labNscore_group', '').replace('.mat', '')
                            # average_bf shape: (1, 3) -> [L*, a*, b*]
                            preference_center_dict[group_name] = mat_data['average_bf'][0]
                    except Exception as e:
                        print(f"Error loading preference center from {mat_path}: {e}")

            # Load all .mat files in labNscore folder
            for mat_file in os.listdir(labnscore_path):
                if not mat_file.endswith('.mat') or mat_file.startswith('f0') and 'picname' in mat_file:
                    continue

                mat_path = os.path.join(labnscore_path, mat_file)

                try:
                    # Load .mat file
                    mat_data = sio.loadmat(mat_path)

                    # Extract p_group (preference scores)
                    if 'p_group' not in mat_data:
                        continue

                    p_group = mat_data['p_group'].flatten()  # Shape: (33,)

                    # Extract base name from mat file
                    # e.g., labNscore_groupf01ih3k.mat -> f01ih3k
                    base_name = mat_file.replace('labNscore_group', '').replace('.mat', '')

                    # Get preference center for this group
                    pref_center = preference_center_dict.get(base_name, None)

                    # Load corresponding images
                    for idx in range(len(p_group)):
                        img_name = f"{base_name}_{idx+1:02d}.jpg"
                        img_path = os.path.join(drawable_path, img_name)

                        if os.path.exists(img_path):
                            # Normalize score to [0, 1]
                            score = p_group[idx]
                            sample = {
                                'image_path': img_path,
                                'score': score,
                                'group': base_name
                            }

                            # Add preference center if available
                            if pref_center is not None:
                                sample['preference_center'] = pref_center

                            self.samples.append(sample)

                except Exception as e:
                    print(f"Error loading {mat_path}: {e}")
                    continue

        print(f"Loaded {len(self.samples)} samples for {self.split} split")

    def __len__(self):
        return len(self.samples)

    def __getitem__(self, idx):
        sample = self.samples[idx]

        # Load image
        image = Image.open(sample['image_path']).convert('RGB')

        # Apply transformations
        if self.transform:
            image = self.transform(image)

        # Get score
        score = torch.tensor(sample['score'], dtype=torch.float32)

        # Return with or without preference center
        if self.load_preference_center and 'preference_center' in sample:
            pref_center = torch.tensor(sample['preference_center'], dtype=torch.float32)
            return image, score, pref_center
        else:
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


def get_dataloaders(data_root, batch_size=32, img_size=224, num_workers=4, load_preference_center=False):
    """Create train and test dataloaders"""
    train_transform = get_transforms(img_size=img_size, augment=True)
    test_transform = get_transforms(img_size=img_size, augment=False)

    train_dataset = SkinPreferenceDataset(
        data_root=data_root,
        transform=train_transform,
        split='train',
        load_preference_center=load_preference_center
    )

    test_dataset = SkinPreferenceDataset(
        data_root=data_root,
        transform=test_transform,
        split='test',
        load_preference_center=load_preference_center
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


if __name__ == '__main__':
    # Test the dataset
    data_root = r"D:\work\secondYearMaster\thesis\reference\appeal\datasets\toMax"

    train_loader, test_loader = get_dataloaders(
        data_root=data_root,
        batch_size=8,
        img_size=224,
        num_workers=0
    )

    print(f"Train batches: {len(train_loader)}")
    print(f"Test batches: {len(test_loader)}")

    # Test one batch
    for images, scores in train_loader:
        print(f"Image batch shape: {images.shape}")
        print(f"Score batch shape: {scores.shape}")
        print(f"Score range: [{scores.min():.3f}, {scores.max():.3f}]")
        break