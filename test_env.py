import torch
import torchvision
import sys
import os

print("=" * 50)
print("Environment Test")
print("=" * 50)

# Python version
print(f"\nPython version: {sys.version}")

# PyTorch info
print(f"\nPyTorch version: {torch.__version__}")
print(f"Torchvision version: {torchvision.__version__}")
print(f"CUDA available: {torch.cuda.is_available()}")

if torch.cuda.is_available():
    print(f"CUDA version: {torch.version.cuda}")
    print(f"GPU count: {torch.cuda.device_count()}")
    print(f"GPU name: {torch.cuda.get_device_name(0)}")
    print(f"GPU memory: {torch.cuda.get_device_properties(0).total_memory / 1024**3:.2f} GB")

# Test model import
print("\n" + "=" * 50)
print("Testing MS-CAN Model")
print("=" * 50)

sys.path.insert(0, '/root/autodl-tmp/MS-CAN')
from models.mscan import MSCAN

model = MSCAN(num_classes=1, pretrained=False)
print(f"✓ Model created successfully")
print(f"Total parameters: {sum(p.numel() for p in model.parameters()) / 1e6:.2f}M")

# Test forward pass
if torch.cuda.is_available():
    model = model.cuda()
    x = torch.randn(2, 3, 224, 224).cuda()
    print(f"\n✓ Testing forward pass on GPU...")
else:
    x = torch.randn(2, 3, 224, 224)
    print(f"\n✓ Testing forward pass on CPU...")

with torch.no_grad():
    output = model(x)
    print(f"✓ Forward pass successful")
    print(f"Input shape: {x.shape}")
    print(f"Output shape: {output.shape}")

print("\n" + "=" * 50)
print("All tests passed!")
print("=" * 50)
