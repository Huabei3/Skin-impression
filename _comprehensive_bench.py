"""
Comprehensive benchmark for thesis: params, training speed, inference speed.
Uses cloud's native multi-head support in predict_p/models/network.py.
"""
from __future__ import annotations
import sys, os, time, copy
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import torch, torch.nn as nn
from predict_p.config import Config
from predict_p.models.network import create_model
from predict_p.loss import ScoreOnlyLoss


def count_params(model):
    total = sum(p.numel() for p in model.parameters())
    trainable = sum(p.numel() for p in model.parameters() if p.requires_grad)
    breakdown = {}
    for nm, m in model.named_children():
        n = sum(p.numel() for p in m.parameters())
        if n > 0:
            breakdown[nm] = n
            # sub-modules
            sub = {}
            for sn, sm in m.named_children():
                sn_val = sum(p.numel() for p in sm.parameters())
                if sn_val > 0:
                    sub[sn] = sn_val
            if sub:
                breakdown[nm + "_sub"] = sub
    return total, trainable, breakdown


def bench_inference(model, device, bs=1, warmup=30, repeats=200):
    model.eval()
    x_face = torch.randn(bs, 3, 224, 224).to(device)
    x_global = torch.randn(bs, 3, 224, 224).to(device)
    with torch.no_grad():
        for _ in range(warmup):
            _ = model(x_face, None, x_global)
    if device == "cuda":
        torch.cuda.synchronize()
    t0 = time.perf_counter()
    with torch.no_grad():
        for _ in range(repeats):
            _ = model(x_face, None, x_global)
    if device == "cuda":
        torch.cuda.synchronize()
    elapsed = time.perf_counter() - t0
    ms_per_batch = elapsed / repeats * 1000
    ms_per_img = ms_per_batch / bs
    fps = 1000.0 / ms_per_img
    return ms_per_batch, ms_per_img, fps


def bench_train_step(model, loss_fn, optimizer, device, bs=16, warmup=5, repeats=30):
    model.train()
    x_face = torch.randn(bs, 3, 224, 224).to(device)
    x_global = torch.randn(bs, 3, 224, 224).to(device)
    tgt = torch.rand(bs, 1).to(device)

    for _ in range(warmup):
        optimizer.zero_grad()
        pred = model(x_face, None, x_global)
        loss, _ = loss_fn(pred, tgt)
        loss.backward()
        optimizer.step()

    if device == "cuda":
        torch.cuda.synchronize()
    t0 = time.perf_counter()
    for _ in range(repeats):
        optimizer.zero_grad()
        pred = model(x_face, None, x_global)
        loss, _ = loss_fn(pred, tgt)
        loss.backward()
        optimizer.step()
    if device == "cuda":
        torch.cuda.synchronize()
    elapsed = time.perf_counter() - t0
    return elapsed / repeats * 1000


def main():
    device = "cuda" if torch.cuda.is_available() else "cpu"
    print(f"Device: {device}")
    if device == "cuda":
        print(f"GPU: {torch.cuda.get_device_name(0)}")
        print(f"VRAM: {torch.cuda.get_device_properties(0).total_memory / 1024**3:.1f} GB")

    ATTRIBUTES = [
        "01Preference","02Attractiveness","03Feminine","04Cooperative",
        "05Youth","06Healthy","07Fidelity","08Harmony","09Fair","10Ruddy"
    ]

    # ========================================
    # 1. PARAMETER COUNTS
    # ========================================
    print("\n" + "=" * 70)
    print("1. PARAMETER COUNTS")
    print("=" * 70)

    # --- Single-head ---
    cfg1 = Config.get_config_dict()
    cfg1["MODEL"]["face_stream"]["rgb_backbone"] = "simple_cnn"
    cfg1["MODEL"]["global_stream"]["backbone"] = "simple_cnn"
    model_1h = create_model(cfg1, use_attention=True, model_variant="v3")
    t1, tr1, b1 = count_params(model_1h)
    print("\n--- Single-head V3 ---")
    for k, v in b1.items():
        if k.endswith("_sub"):
            for sk, sv in v.items():
                print(f"  {sk}: {sv:,} ({sv/1e6:.4f}M)")
        else:
            print(f"  {k}: {v:,} ({v/1e6:.4f}M)")
    print(f"  TOTAL: {t1:,} ({t1/1e6:.4f}M)")

    # --- Multi-head (10 heads) ---
    cfg10 = Config.get_config_dict()
    cfg10["MODEL"]["face_stream"]["rgb_backbone"] = "simple_cnn"
    cfg10["MODEL"]["global_stream"]["backbone"] = "simple_cnn"
    cfg10["MULTI_HEAD"] = True
    cfg10["ATTRIBUTE_HEAD_NAMES"] = ATTRIBUTES
    model_10h = create_model(cfg10, use_attention=True, model_variant="v3")
    t10, tr10, b10 = count_params(model_10h)

    print("\n--- Multi-head V3 (10 heads) ---")
    for k, v in b10.items():
        if k.endswith("_sub"):
            for sk, sv in v.items():
                print(f"  {sk}: {sv:,} ({sv/1e6:.4f}M)")
        else:
            print(f"  {k}: {v:,} ({v/1e6:.4f}M)")
    print(f"  TOTAL: {t10:,} ({t10/1e6:.4f}M)")

    # Extract thesis numbers
    face_t = sum(p.numel() for p in model_10h.face_stream.parameters())
    global_t = sum(p.numel() for p in model_10h.global_stream.parameters())
    fusion_t = sum(p.numel() for p in model_10h.fusion.parameters())
    heads_t = sum(p.numel() for p in model_10h.score_head.parameters())
    per_head = heads_t / 10

    print(f"\n=== THESIS PARAM BREAKDOWN ===")
    print(f"  人脸分支 (SimpleCNN):         {face_t:>10,}  ({face_t/1e6:.4f}M)")
    print(f"  全局分支 (SimpleCNN):         {global_t:>10,}  ({global_t/1e6:.4f}M)")
    print(f"  门控加权融合模块:             {fusion_t:>10,}  ({fusion_t/1e6:.4f}M)")
    print(f"  10个预测头 (每个):            {per_head:>10,.0f}  ({per_head/1e6:.4f}M)")
    print(f"  10个预测头 (合计):            {heads_t:>10,}  ({heads_t/1e6:.4f}M)")
    print(f"  完整模型可训练参数:           {t10:>10,}  ({t10/1e6:.4f}M)")

    # --- Move to GPU ---
    model_10h = model_10h.to(device)

    # ========================================
    # 2. TRAINING EFFICIENCY
    # ========================================
    print("\n" + "=" * 70)
    print("2. TRAINING EFFICIENCY (batch_size=16)")
    print("=" * 70)

    loss_cfg = copy.deepcopy(cfg10["LOSS"])
    base_loss = ScoreOnlyLoss({"LOSS": loss_cfg}).to(device)
    opt = torch.optim.AdamW(model_10h.parameters(), lr=7e-4)

    ms_iter = bench_train_step(model_10h, base_loss, opt, device, bs=16, warmup=5, repeats=30)
    print(f"  Fwd+Bwd per iteration (bs=16): {ms_iter:.2f} ms")

    # Batch counts from cloud data
    # AS/CA: train=5709, bs=16 -> 357 batch/epoch
    # AF/SA: train=3399, bs=16 -> 213 batch/epoch
    batches_as_ca = 5709 // 16 + 1
    batches_af_sa = 3399 // 16 + 1
    epoch_as_ca = batches_as_ca * ms_iter / 1000
    epoch_af_sa = batches_af_sa * ms_iter / 1000

    print(f"\n  Per-epoch:")
    print(f"    AS/CA: {batches_as_ca} batches × {ms_iter:.1f}ms = {epoch_as_ca:.1f}s")
    print(f"    AF/SA: {batches_af_sa} batches × {ms_iter:.1f}ms = {epoch_af_sa:.1f}s")

    # Total training time (from cloud checkpoint data)
    total_ep = {"AS": 170, "CA": 228, "AF": 190, "SA": 570}
    print(f"\n  Total training (patience=100):")
    for race, ep in total_ep.items():
        sec_per = epoch_as_ca if race in ("AS","CA") else epoch_af_sa
        min_t = ep * sec_per / 60
        print(f"    {race}: {ep} ep × {sec_per:.1f}s = {min_t:.1f} min")

    # ========================================
    # 3. INFERENCE EFFICIENCY
    # ========================================
    print("\n" + "=" * 70)
    print("3. INFERENCE EFFICIENCY (RTX 4080 SUPER)")
    print("=" * 70)

    # Single image
    ms_b, ms_i, fps_i = bench_inference(model_10h, device, bs=1, warmup=30, repeats=500)
    print(f"\n  Batch=1 (single image):")
    print(f"    {ms_b:.2f} ms/batch  |  {ms_i:.2f} ms/image  |  {fps_i:.1f} FPS")

    # Batch scaling
    print(f"\n  Batch scaling:")
    print(f"    {'BS':>4s}  {'ms/batch':>9s}  {'ms/img':>8s}  {'FPS':>8s}  {'img/s':>8s}")
    print(f"    {'-'*4}  {'-'*9}  {'-'*8}  {'-'*8}  {'-'*8}")
    for bs in [1, 4, 8, 16, 32, 64]:
        ms_bat, ms_img, _ = bench_inference(model_10h, device, bs=bs, warmup=10, repeats=100)
        imgs_s = bs * 1000.0 / ms_bat
        print(f"    {bs:>4d}  {ms_bat:>9.2f}  {ms_img:>8.2f}  {1000/ms_img:>8.0f}  {imgs_s:>8.0f}")

    # ========================================
    # SUMMARY
    # ========================================
    print("\n" + "=" * 70)
    print("THESIS SUMMARY (copy-paste ready)")
    print("=" * 70)
    print(f"""
参数量:
  人脸分支与全局分支（轻量级CNN骨干）参数各约:    {face_t/1e6:.2f}M / {global_t/1e6:.2f}M
  门控加权融合模块额外参数量约:                    {fusion_t/1000:.1f}K
  10个多属性预测头各由三层MLP组成, 每个参数量约:   {per_head/1e6:.4f}M
  10个预测头合计参数量约:                           {heads_t/1000:.1f}K
  完整模型的可训练参数量约为:                       {t10/1e6:.2f}M

训练效率 (单卡 RTX 4080 SUPER):
  batch size:                                                            16
  前向+反向传播单次迭代耗时约:                                           {ms_iter:.0f}ms
  AS/CA 单轮epoch（约{batches_as_ca}个batch）耗时约:                     {epoch_as_ca:.0f}s
  AF/SA 单轮epoch（约{batches_af_sa}个batch）耗时约:                     {epoch_af_sa:.0f}s
  AS 早停收敛 (~{total_ep['AS']} epoch) 总耗时:                          {total_ep['AS']*epoch_as_ca/60:.0f} min
  CA 早停收敛 (~{total_ep['CA']} epoch) 总耗时:                          {total_ep['CA']*epoch_as_ca/60:.0f} min
  AF 早停收敛 (~{total_ep['AF']} epoch) 总耗时:                          {total_ep['AF']*epoch_af_sa/60:.0f} min
  SA 早停收敛 (~{total_ep['SA']} epoch) 总耗时:                          {total_ep['SA']*epoch_af_sa/60:.0f} min

推理效率 (单卡 RTX 4080 SUPER, 224x224):
  单张推理耗时约:                        {ms_i:.1f}ms
  GPU推理速度 (batch=1):                {fps_i:.0f} FPS
""")
    return 0


if __name__ == "__main__":
    main()
