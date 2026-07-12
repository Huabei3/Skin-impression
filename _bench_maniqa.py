"""Benchmark MANIQA inference speed on RTX 4080 SUPER."""
import torch
import time
import sys
import numpy as np

# Path setup
sys.path.insert(0, '/root/autodl-tmp/iqa_pytorch_train')
sys.path.insert(0, '/root/autodl-tmp/iqa_pytorch_train/pyiqa')

print("=== MANIQA Inference Benchmark ===")
print(f"CUDA available: {torch.cuda.is_available()}")
if torch.cuda.is_available():
    print(f"GPU: {torch.cuda.get_device_name(0)}")
    print(f"CUDA Memory: {torch.cuda.get_device_properties(0).total_memory / 1024**3:.1f} GB")

# Try to load MANIQA via pyiqa
try:
    import pyiqa
    print(f"pyiqa path: {pyiqa.__file__}")
except Exception as e:
    print(f"pyiqa import failed: {e}")
    # Try alternative import
    try:
        from pyiqa import create_metric
        print("pyiqa.create_metric imported")
    except:
        print("Cannot import pyiqa, trying direct model load...")

# Load MANIQA
print("\nLoading MANIQA model...")
device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')

try:
    # Try pyiqa API
    maniqa = pyiqa.create_metric('maniqa', device=device)
    print("MANIQA loaded via pyiqa.create_metric")
except:
    # Try direct import
    from pyiqa.archs.maniqa_arch import MANIQA
    maniqa = MANIQA()
    maniqa = maniqa.to(device)
    maniqa.eval()
    print("MANIQA loaded directly from arch")

# Count params
total_params = sum(p.numel() for p in maniqa.parameters())
trainable_params = sum(p.numel() for p in maniqa.parameters() if p.requires_grad)
print(f"MANIQA parameters: {total_params:,} total, {trainable_params:,} trainable")

# Benchmark inference
print("\n--- Inference Benchmark (224×224) ---")
dummy = torch.rand(1, 3, 224, 224).to(device)  # [0,1] range

# Warmup
print("Warming up...")
with torch.no_grad():
    for _ in range(50):
        _ = maniqa(dummy)
torch.cuda.synchronize()

# Benchmark
n_iters = 500
print(f"Running {n_iters} iterations...")
torch.cuda.synchronize()
start = time.perf_counter()
with torch.no_grad():
    for _ in range(n_iters):
        _ = maniqa(dummy)
torch.cuda.synchronize()
elapsed = time.perf_counter() - start

avg_ms = (elapsed / n_iters) * 1000
fps = n_iters / elapsed

print(f"\n=== Results ===")
print(f"Total time: {elapsed:.2f}s for {n_iters} iterations")
print(f"Per image: {avg_ms:.2f} ms")
print(f"FPS: {fps:.1f}")

# Also test batch processing if applicable
print("\n--- Batch Benchmark (batch=16) ---")
dummy_batch = torch.rand(16, 3, 224, 224).to(device)  # [0,1] range
with torch.no_grad():
    for _ in range(20):
        _ = maniqa(dummy_batch)
torch.cuda.synchronize()

start = time.perf_counter()
n_batch_iters = 100
with torch.no_grad():
    for _ in range(n_batch_iters):
        _ = maniqa(dummy_batch)
torch.cuda.synchronize()
elapsed_batch = time.perf_counter() - start

avg_batch_ms = (elapsed_batch / n_batch_iters) * 1000
batch_fps = (16 * n_batch_iters) / elapsed_batch

print(f"Batch 16: {avg_batch_ms:.2f} ms per batch, {batch_fps:.1f} FPS (effective)")

print("\nDone!")
