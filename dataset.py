import torch
from torch.utils.data import Dataset
from PIL import Image
import torchvision.transforms as transforms


class EnhancementDataset(Dataset):
    def __init__(self, data_list, img_size=256):
        """
        data_list: list of dict with keys:
            'raw': path to raw image
            'adjusted': path to adjusted image
            'score': float, quality score (normalized to [-1,1] preferably)
            'label': float/int, skin tone label (optional, default 5)
        """
        self.data = data_list
        self.transform = transforms.Compose([
            transforms.Resize((img_size, img_size)),
            transforms.ToTensor(),
        ])

    def __len__(self):
        return len(self.data)

    def __getitem__(self, idx):
        item = self.data[idx]
        raw = self.transform(Image.open(item['raw']).convert('RGB'))
        adj = self.transform(Image.open(item['adjusted']).convert('RGB'))
        score = torch.tensor(float(item['score']), dtype=torch.float32)
        label = torch.tensor(float(item.get('label', 5)), dtype=torch.float32)
        return {
            'raw': raw,
            'adjusted': adj,
            'score': score,
            'label': label
        }
