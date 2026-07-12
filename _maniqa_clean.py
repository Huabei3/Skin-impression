
import torch, time, sys
sys.path.insert(0, '/root/autodl-tmp/iqa_pytorch_train')
import pyiqa

print("=== MANIQA Clean Benchmark ===")
print(f"GPU: {torch.cuda.get_device_name(0)}")
device = torch.device('cuda')

# Clear cache
torch.cuda.empty_cache()
torch.cuda.reset_peak_memory_stats()

maniqa = pyiqa.create_metric('maniqa', device=device)
maniqa.eval()
total_params = sum(p.numel() for p in maniqa.parameters())
print(f"MANIQA params: {total_params:,} ({total_params/1e6:.2f}M)")

print("\n--- Single Image Inference ---")
dummy = torch.rand(1, 3, 224, 224).to(device)

# Warmup
with torch.no_grad():
    for _ in range(30):
        _ = maniqa(dummy)
torch.cuda.synchronize()

# Benchmark
n_iters = 300
torch.cuda.synchronize()
start = time.perf_counter()
with torch.no_grad():
    for _ in range(n_iters):
        _ = maniqa(dummy)
torch.cuda.synchronize()
elapsed = time.perf_counter() - start

avg_ms = (elapsed / n_iters) * 1000
fps = n_iters / elapsed

print(f"Total: {elapsed:.2f}s for {n_iters} iters")
print(f"Per image: {avg_ms:.2f} ms")
print(f"FPS: {fps:.1f}")

# Batch=4 (safer)
torch.cuda.empty_cache()
print("\n--- Batch=4 Inference ---")
dummy4 = torch.rand(4, 3, 224, 224).to(device)
with torch.no_grad():
    for _ in range(10):
        _ = maniqa(dummy4)
torch.cuda.synchronize()

start = time.perf_counter()
with torch.no_grad():
    for _ in range(100):
        _ = maniqa(dummy4)
torch.cuda.synchronize()
elapsed4 = time.perf_counter() - start

avg4_ms = (elapsed4 / 100) * 1000
fps4 = 4 * 100 / elapsed4
print(f"Per batch: {avg4_ms:.2f} ms, {fps4:.1f} effective FPS")

print("\nDone!")
