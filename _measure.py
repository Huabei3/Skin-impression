"""Quick measure params & runtime for predict_p (multi-head, V3, simple_cnn) on cloud."""
from __future__ import annotations
import sys, os, time, json, copy
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import torch, torch.nn as nn
from predict_p.models.network import create_model
from predict_p.config import Config

def count_params(model, name=""):
    total = sum(p.numel() for p in model.parameters())
    trainable = sum(p.numel() for p in model.parameters() if p.requires_grad)
    breakdown = {}
    for nm, m in model.named_children():
        n = sum(p.numel() for p in m.parameters())
        if n > 0:
            breakdown[nm] = n
    return total, trainable, breakdown


def bench_inference(model, device, bs=1, warmup=20, repeats=200):
    model.eval()
    x = torch.randn(bs, 3, 224, 224).to(device)
    with torch.no_grad():
        for _ in range(warmup):
            _ = model(x, None, x)
    if device == "cuda":
        torch.cuda.synchronize()
    t0 = time.perf_counter()
    with torch.no_grad():
        for _ in range(repeats):
            _ = model(x, None, x)
    if device == "cuda":
        torch.cuda.synchronize()
    elapsed = time.perf_counter() - t0
    ms = elapsed / repeats * 1000
    return ms, 1000.0 / ms


def bench_train_step(model, loss_fn, optimizer, device, bs, warmup=5, repeats=20):
    model.train()
    x = torch.randn(bs, 3, 224, 224).to(device)
    tgt = torch.rand(bs, 10).to(device)
    mask = torch.ones(bs, 10).to(device)
    for _ in range(warmup):
        optimizer.zero_grad()
        pred = model(x, None, x)
        loss, _ = loss_fn(pred, tgt, mask)
        loss.backward()
        optimizer.step()
    if device == "cuda":
        torch.cuda.synchronize()
    t0 = time.perf_counter()
    for _ in range(repeats):
        optimizer.zero_grad()
        pred = model(x, None, x)
        loss, _ = loss_fn(pred, tgt, mask)
        loss.backward()
        optimizer.step()
    if device == "cuda":
        torch.cuda.synchronize()
    elapsed = time.perf_counter() - t0
    return elapsed / repeats * 1000


class MultiHeadLoss(nn.Module):
    def __init__(self, base_loss):
        super().__init__()
        self.base = base_loss
    def forward(self, pred, target, mask):
        total = 0.0
        for i in range(pred.shape[1]):
            valid = mask[:, i].bool()
            if valid.sum() == 0:
                continue
            loss_i, _ = self.base(pred[valid, i:i+1], target[valid, i:i+1])
            total = total + loss_i
        return total, {}


def main():
    device = "cuda" if torch.cuda.is_available() else "cpu"
    print(f"Device: {device}")
    if device == "cuda":
        print(f"GPU: {torch.cuda.get_device_name(0)}")

    attributes = [
        "01Preference","02Attractiveness","03Feminine","04Cooperative",
        "05Youth","06Healthy","07Fidelity","08Harmony","09Fair","10Ruddy"
    ]

    cfg = Config()
    cfg_dict = cfg.get_config_dict()
    cfg_dict["MULTI_HEAD"] = True
    cfg_dict["ATTRIBUTE_HEAD_NAMES"] = attributes
    cfg_dict["MODEL_VARIANT"] = "v3"
    cfg_dict["MODEL"]["face_stream"]["rgb_backbone"] = "simple_cnn"
    cfg_dict["MODEL"]["global_stream"]["backbone"] = "simple_cnn"

    model = create_model(cfg_dict, use_attention=False, model_variant="v3")
    total, trainable, breakdown = count_params(model)

    print(f"\n=== PARAMS ===")
    print(f"Total: {total:,}")
    print(f"Trainable: {trainable:,}")
    for k, v in breakdown.items():
        print(f"  {k}: {v:,}")

    # Sub-breakdown
    if hasattr(model, 'face_stream'):
        ft, _, fb = count_params(model.face_stream)
        print(f"  face_stream detail: {fb}")
    if hasattr(model, 'global_stream') and model.global_stream is not None:
        gt, _, gb = count_params(model.global_stream)
        print(f"  global_stream detail: {gb}")
    if hasattr(model, 'fusion') and model.fusion is not None:
        fut, _, fub = count_params(model.fusion)
        print(f"  fusion detail: {fub}")
    if hasattr(model.score_head, 'heads'):
        # MultiScoreHead
        if hasattr(model.score_head, 'heads') and len(model.score_head.heads) > 0:
            h_total = sum(p.numel() for p in model.score_head.heads.parameters())
            print(f"  MultiScoreHead (10 heads): {h_total:,}  per-head: {h_total/10:,.0f}")
    else:
        ht, _, hb = count_params(model.score_head)
        print(f"  score_head detail: {hb}")

    model = model.to(device)

    # Inference
    print(f"\n=== GPU INFERENCE ===")
    ms1, fps1 = bench_inference(model, device, bs=1)
    print(f"Batch=1: {ms1:.4f} ms  ({fps1:.0f} FPS)")
    ms8, fps8 = bench_inference(model, device, bs=8)
    print(f"Batch=8: {ms8:.4f} ms  ({fps8*8:.0f} img/s)")

    # Training step
    print(f"\n=== TRAINING STEP (batch=16) ===")
    try:
        from predict_p.loss import ScoreOnlyLoss
        loss_cfg_base = copy.deepcopy(cfg_dict["LOSS"])
        base_loss = ScoreOnlyLoss({"LOSS": loss_cfg_base}).to(device)
        mh_loss = MultiHeadLoss(base_loss)
        opt = torch.optim.Adam(model.parameters(), lr=7e-4)
        ms_iter = bench_train_step(model, mh_loss, opt, device, bs=16)
        print(f"Forward+backward: {ms_iter:.2f} ms/iter")
    except Exception as e:
        print(f"Train bench failed: {e}")

    # Epoch time estimate (with ~500 batches doc claims)
    n_batches = 500  # as per document
    epoch_sec = n_batches * ms_iter / 1000
    print(f"Est epoch ({n_batches} batches): {epoch_sec:.0f}s")

    print("\nDone")
    return 0

if __name__ == "__main__":
    main()
