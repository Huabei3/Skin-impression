"""CFD 3.0.1 纯推理入口（无 GT），按 dskin_nation 分组输出 toMax 同格式结果。

关键对齐（CFD 族裔 → deepskin 族裔）
------------------------------------
    CFD AF / AM (Asian F/M)      → dskin AS (Asian)
    CFD BF / BM (Black F/M)      → dskin AF (African)
    CFD LF / LM (Latino F/M)     → dskin SA (South Asian)
    CFD WF / WM (White F/M)      → dskin CA (Caucasian)

so 每个 dskin_nation 只用**它自己那个族的 ckpt**，跑对应 CFD 子集。

输出
----
    {out_root}/{exp_name}/predict_p_{dskin_nation}/cfd_predictions.xlsx       逐样本明细
    {out_root}/{exp_name}/predict_p_{dskin_nation}/results/test_results.xlsx  toMax 同格式
（CFD 没有 GT，所以 Overall/DeltaE 里的指标是 NaN，RawData 里的 pred 是有效值）

用法
----
python predict_p/infer_cfd.py \
  --cfd-root /root/autodl-tmp/cfd/Images/CFD \
  --exp-name ablation_lab_vec_v3 --race-ckpt AS --cfd-nations AF,AM \
  --ablation-lab-vec \
  --output-root /root/autodl-tmp/deepskin/predict_p/output_cfd \
  --resume .../ablation_lab_vec_v3/predict_p_AS/checkpoints/best_model.pth
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

import numpy as np
import pandas as pd
import torch
import torchvision.transforms as T
from PIL import Image
from torch.utils.data import DataLoader, Dataset

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

import predict_p.models.network as N  # noqa: E402
from predict_p.config import Config  # noqa: E402
from predict_p.test_only import (ALL_ATTRIBUTES, _apply_model_variant_overrides,  # noqa: E402
                                 export_to_xlsx)

IMG_EXTS = (".png", ".jpg", ".jpeg")

# CFD 族裔 → deepskin 族裔
CFD_TO_DSKIN = {"AF": "AS", "AM": "AS", "BF": "AF", "BM": "AF",
                "LF": "SA", "LM": "SA", "WF": "CA", "WM": "CA"}


# ----------------------------------------------------------------- 图像工具
def resolve_image(base: Path, stem: str) -> Path | None:
    for ext in IMG_EXTS:
        p = base / f"{stem}{ext}"
        if p.exists():
            return p
    return None


def srgb_to_lab(rgb: np.ndarray) -> np.ndarray:
    """(H,W,3) uint8 sRGB → CIELAB(D65)，L∈[0,100]。"""
    x = rgb.astype(np.float32) / 255.0
    x = np.where(x <= 0.04045, x / 12.92, ((x + 0.055) / 1.055) ** 2.4)
    m = np.array([[0.4124564, 0.3575761, 0.1804375],
                  [0.2126729, 0.7151522, 0.0721750],
                  [0.0193339, 0.1191920, 0.9503041]], dtype=np.float32)
    xyz = x @ m.T
    white = np.array([0.95047, 1.0, 1.08883], dtype=np.float32)
    t = xyz / white
    f = np.where(t > 0.008856, np.cbrt(t), 7.787 * t + 16.0 / 116.0)
    return np.stack([116.0 * f[..., 1] - 16.0,
                     500.0 * (f[..., 0] - f[..., 1]),
                     200.0 * (f[..., 1] - f[..., 2])], axis=-1)


def lab_to_srgb(lab: np.ndarray) -> np.ndarray:
    """CIELAB(D65) → sRGB(0~255)，与 srgb_to_lab 互逆。"""
    L = lab[..., 0]
    a = lab[..., 1]
    b = lab[..., 2]
    fy = (L + 16.0) / 116.0
    fx = fy + a / 500.0
    fz = fy - b / 200.0

    def inv(f):
        return np.where(f ** 3 > 0.008856, f ** 3, (f - 16.0 / 116.0) / 7.787)

    xyz = np.stack([inv(fx) * 0.95047, inv(fy), inv(fz) * 1.08883], axis=-1)
    m_inv = np.linalg.inv(np.array([[0.4124564, 0.3575761, 0.1804375],
                                    [0.2126729, 0.7151522, 0.0721750],
                                    [0.0193339, 0.1191920, 0.9503041]], dtype=np.float32))
    rgb = xyz @ m_inv.T
    rgb = np.where(rgb <= 0.0031308, 12.92 * rgb, 1.055 * np.power(np.clip(rgb, 0, None), 1 / 2.4) - 0.055)
    return np.clip(rgb * 255.0, 0, 255)


def mean_lab_of(img: Image.Image) -> tuple[float, float, float]:
    lab = srgb_to_lab(np.asarray(img.convert("RGB")))
    return tuple(float(v) for v in lab.reshape(-1, 3).mean(axis=0))


def mean_lab_masked(orig_img: Image.Image, mask_path: Path) -> tuple[float, float, float] | None:
    """原图在 mask 覆盖区域（mask>0）内的 CIELAB 均值 —— CFD 的 ori_Lab。

    mask 与 CFD 原图同尺寸（uint8，取值 0/255）；尺寸不一致时按最近邻缩放。
    """
    rgb = np.asarray(orig_img.convert("RGB"))
    try:
        m = Image.open(mask_path).convert("L")
    except Exception:
        return None
    if m.size != (rgb.shape[1], rgb.shape[0]):
        m = m.resize((rgb.shape[1], rgb.shape[0]), Image.NEAREST)
    sel = np.asarray(m) > 0
    if sel.sum() < 16:
        return None
    lab = srgb_to_lab(rgb)[sel]
    return tuple(float(v) for v in lab.mean(axis=0))


# ----------------------------------------------------------------- 数据
def collect_samples(cfd_root: Path, cfd_nations: set[str] | None, expr: str | None):
    out = []
    for subj_dir in sorted(p for p in cfd_root.iterdir() if p.is_dir()):
        subj = subj_dir.name
        nation = subj.split("-")[0]
        if cfd_nations and nation not in cfd_nations:
            continue
        for f in sorted(subj_dir.iterdir()):
            if not f.is_file() or f.suffix.lower() not in IMG_EXTS:
                continue
            stem = f.stem
            if stem.endswith(("-face", "-mask")):
                continue
            if expr and not stem.endswith(f"-{expr}"):
                continue
            out.append((nation, subj, stem,
                        resolve_image(subj_dir, stem),
                        resolve_image(subj_dir, f"{stem}-face")))
    return out


class CFDDataset(Dataset):
    def __init__(self, samples, transform, lab_mode):
        self.samples, self.tf, self.lab_mode = samples, transform, lab_mode

    def __len__(self):
        return len(self.samples)

    def __getitem__(self, i):
        _, _, stem, orig, face = self.samples[i]
        try:
            img_f = Image.open(face).convert("RGB")
            img_g = Image.open(orig).convert("RGB")
        except Exception:
            return None
        # ori_Lab：优先用「原图 ∩ mask>0」的 Lab 均值；无 mask 时退回 face 裁剪均值
        lp = None
        if self.lab_mode == "face-mean":
            mask_path = resolve_image(orig.parent, f"{stem}-mask")
            if mask_path is not None:
                lp = mean_lab_masked(img_g, mask_path)
            if lp is None:
                lp = mean_lab_of(img_f)
        else:
            lp = (0.0, 0.0, 0.0)
        return self.tf(img_f), self.tf(img_g), torch.tensor(lp, dtype=torch.float32), i


def collate_drop_none(batch):
    batch = [b for b in batch if b is not None]
    if not batch:
        return None
    return (torch.stack([b[0] for b in batch]), torch.stack([b[1] for b in batch]),
            torch.stack([b[2] for b in batch]),
            torch.tensor([b[3] for b in batch], dtype=torch.long))


def _render_pics(samples, lab_pred_all, ori_all, out_dir: Path, attrs, limit: int = 0) -> None:
    """--if_render：

    pred_pics/{stem}_{attr}.jpg  —— 把原图 mask 区域在 CIELAB 里整体平移 (pred_Lab - ori_Lab)，
                                    使其平均色 = 预测色（保留纹理）。
    check_pics/{stem}.jpg        —— global 图 × mask（mask=0 处置 0），用于核对 mask 对位。
    """
    import cv2

    pdir = out_dir / "pred_pics"
    cdir = out_dir / "check_pics"
    pdir.mkdir(parents=True, exist_ok=True)
    cdir.mkdir(parents=True, exist_ok=True)

    n = min(limit or len(samples), len(samples))
    for i in range(n):
        _, _, stem, orig, _ = samples[i]
        try:
            img = np.asarray(Image.open(orig).convert("RGB"))
        except Exception:
            continue
        mask_p = resolve_image(orig.parent, f"{stem}-mask")
        if mask_p is not None:
            m = np.asarray(Image.open(mask_p).convert("L"))
            if m.shape[:2] != img.shape[:2]:
                m = np.asarray(Image.fromarray(m).resize((img.shape[1], img.shape[0]), Image.NEAREST))
            sel = m > 0
        else:
            sel = np.ones(img.shape[:2], dtype=bool)

        # check_pics：global × mask
        chk = np.zeros_like(img)
        chk[sel] = img[sel]
        cv2.imwrite(str(cdir / f"{stem}.jpg"), chk[:, :, ::-1],
                    [int(cv2.IMWRITE_JPEG_QUALITY), 92])

        # pred_pics：按属性渲染
        lab = srgb_to_lab(img)
        ori = np.asarray(ori_all[i, :3], dtype=np.float32)
        for ai, an in enumerate(attrs):
            p = np.asarray(lab_pred_all[i, ai * 3:ai * 3 + 3], dtype=np.float32)
            if not (np.isfinite(p).all() and np.isfinite(ori).all()):
                continue
            shifted = lab.copy()
            shifted[sel] = lab[sel] + (p - ori)
            rgb = lab_to_srgb(shifted).astype(np.uint8)
            cv2.imwrite(str(pdir / f"{stem}_{an}.jpg"), rgb[:, :, ::-1],
                        [int(cv2.IMWRITE_JPEG_QUALITY), 92])
        if i % 50 == 0:
            print(f"[render] {i}/{n}")

    print(f"[render] pred_pics={pdir}  check_pics={cdir}")


def _augment_rawdata_with_lab(xlsx_path: Path, attrs, lab_pred_all: np.ndarray,
                              lab_ori_all: np.ndarray | None,
                              lab_tgt_all: np.ndarray | None) -> None:
    """给每个 RawData_{attr} sheet 追加 pred_L/pred_a/pred_b、target_L/target_a/target_b、de2000。

    lab_pred_all: (N, 3*A)，按属性块排列（第 j 个属性用 [:, 3j:3j+3]）。
    每个属性都有自己的 center head，所以必须按属性切片 —— 全部用第 0 个属性是错的。
    CFD 没有 GT → target_* 与 de2000 留空；以后有 GT 时传 lab_tgt_all 即自动填。
    """
    from openpyxl import load_workbook
    from openpyxl.utils import get_column_letter

    from predict_p.test_only import compute_deltae_ciede2000

    wb = load_workbook(xlsx_path)
    new_heads = ["pred_L", "pred_a", "pred_b",
                 "ori_L", "ori_a", "ori_b", "de00_ori",
                 "target_L", "target_a", "target_b", "de00_target"]
    for ai, an in enumerate(attrs):
        sheet = f"RawData_{an}"
        if sheet not in wb.sheetnames:
            continue
        s = ai * 3
        pred_lab = np.asarray(lab_pred_all[:, s:s + 3], dtype=float)
        ori_lab = np.asarray(lab_ori_all[:, s:s + 3], dtype=float) if lab_ori_all is not None else None
        if lab_tgt_all is not None:
            tgt_lab = np.asarray(lab_tgt_all[:, s:s + 3], dtype=float)
            de_tgt = compute_deltae_ciede2000(pred_lab, tgt_lab)
        else:
            tgt_lab = None
            de_tgt = np.full(len(pred_lab), np.nan)
        de_ori = (compute_deltae_ciede2000(pred_lab, ori_lab)
                  if ori_lab is not None else np.full(len(pred_lab), np.nan))

        ws = wb[sheet]
        c0 = ws.max_column + 1                      # 追加在最后，不动原有 8 列
        for j, h in enumerate(new_heads):
            ws.cell(row=1, column=c0 + j, value=h)
            ws.column_dimensions[get_column_letter(c0 + j)].width = 11
        for i in range(len(pred_lab)):
            r = i + 2
            vals = [round(float(pred_lab[i, 0]), 4), round(float(pred_lab[i, 1]), 4),
                    round(float(pred_lab[i, 2]), 4)]
            vals += ([round(float(v), 4) if np.isfinite(v) else None for v in ori_lab[i]]
                     if ori_lab is not None else [None] * 3)
            vals.append(round(float(de_ori[i]), 4) if np.isfinite(de_ori[i]) else None)
            vals += ([round(float(v), 4) if np.isfinite(v) else None for v in tgt_lab[i]]
                     if tgt_lab is not None else [None] * 3)
            vals.append(round(float(de_tgt[i]), 4) if np.isfinite(de_tgt[i]) else None)
            for j, v in enumerate(vals):
                ws.cell(row=r, column=c0 + j, value=v)
    wb.save(xlsx_path)


# ----------------------------------------------------------------- main
def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--cfd-root", default="/root/autodl-tmp/cfd/Images/CFD")
    ap.add_argument("--exp-name", required=True)
    ap.add_argument("--race-ckpt", default="SA", help="ckpt 所属 deepskin 族裔")
    ap.add_argument("--cfd-nations", default=None,
                    help="逗号分隔的 CFD 族裔（AF,AM,BF,BM,LF,LM,WF,WM）；默认全部")
    ap.add_argument("--resume", required=True)
    ap.add_argument("--model-variant", default="v3")
    ap.add_argument("--attributes", default="all")
    ap.add_argument("--ablation-lab-vec", action="store_true", default=False)
    ap.add_argument("--ablation-delta-lab", action="store_true", default=False)
    ap.add_argument("--lab-delta-channels", default="none", choices=["none", "L", "ab", "Lab"])
    ap.add_argument("--lab-delta-scale", default=None,
                    help="仅为与训练命令兼容；推理不做归一化")
    ap.add_argument("--lab-point-mode", default="face-mean", choices=["face-mean", "zero"])
    ap.add_argument("--rgb-backbone", default="simple_cnn")
    ap.add_argument("--global-backbone", default="simple_cnn")
    ap.add_argument("--output-root", default="/root/autodl-tmp/deepskin/predict_p/output_cfd")
    ap.add_argument("--batch-size", type=int, default=16)
    ap.add_argument("--num-workers", type=int, default=8)
    ap.add_argument("--expr", default=None)
    ap.add_argument("--limit", type=int, default=0)
    ap.add_argument("--no-tomax-format", action="store_true", help="不写 results/test_results.xlsx")
    ap.add_argument("--if_render", action="store_true", default=False,
                    help="额外输出 pred_pics（把原图 skin 区渲染到 pred_Lab）与 check_pics（global×mask）")
    ap.add_argument("--render-limit", type=int, default=0, help="只渲染前 N 张（0=全部，调试用）")
    a = ap.parse_args()

    cfd_root, ckpt = Path(a.cfd_root), Path(a.resume)
    if not cfd_root.is_dir():
        raise SystemExit(f"cfd-root 不存在: {cfd_root}")
    if not ckpt.is_file():
        raise SystemExit(f"ckpt 不存在: {ckpt}")

    cfd_nations = {s.strip().upper() for s in a.cfd_nations.split(",")} if a.cfd_nations else None
    if cfd_nations:
        bad = cfd_nations - set(CFD_TO_DSKIN)
        if bad:
            raise SystemExit(f"未知 CFD 族裔: {sorted(bad)}")
        for n in cfd_nations:
            if CFD_TO_DSKIN[n] != a.race_ckpt:
                raise SystemExit(f"对齐错误：CFD {n} 应使用 dskin {CFD_TO_DSKIN[n]} 的 ckpt，"
                                 f"但你给的是 {a.race_ckpt}")

    out_dir = Path(a.output_root) / a.exp_name / f"predict_p_{a.race_ckpt}"
    (out_dir / "results").mkdir(parents=True, exist_ok=True)

    # ---------------- config / model
    attrs = list(ALL_ATTRIBUTES) if str(a.attributes).lower() == "all" else \
        [s.strip() for s in str(a.attributes).split(",") if s.strip()]
    cfg = Config.get_config_dict()
    cfg.update({
        "MODEL_VARIANT": a.model_variant, "MULTI_HEAD": True,
        "ATTRIBUTE_HEAD_NAMES": attrs, "ABLATION_LAB_CENTER": True,
        "ABLATION_LAB_VEC": bool(a.ablation_lab_vec),
        "ABLATION_DELTA_LAB": bool(a.ablation_delta_lab),
        "LAB_DELTA_CHANNELS": str(a.lab_delta_channels).lower(),
        "FACE_INPUT_SIZE": (224, 224),
    })
    cfg.setdefault("MODEL", {}).setdefault("face_stream", {})["rgb_backbone"] = a.rgb_backbone
    cfg["MODEL"].setdefault("global_stream", {})["backbone"] = a.global_backbone
    if a.rgb_backbone == "simple_cnn":
        cfg["MODEL"]["face_stream"]["rgb_pretrained"] = False
    if a.global_backbone == "simple_cnn":
        cfg["MODEL"]["global_stream"]["pretrained"] = False
    _apply_model_variant_overrides(cfg)

    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    model = N.create_model(cfg, model_variant=a.model_variant).to(device)
    state = torch.load(str(ckpt), map_location="cpu")
    sd = state.get("model_state_dict", state)
    missing, unexpected = model.load_state_dict(sd, strict=False)
    missing = [k for k in missing if not k.startswith("criterion")]
    print(f"[ckpt] {ckpt.parent.parent.name}  epoch={state.get('epoch')}  "
          f"missing={len(missing)} unexpected={len(unexpected)}")
    if missing or unexpected:
        print("  missing[:6]   :", missing[:6])
        print("  unexpected[:6]:", unexpected[:6])
        raise SystemExit("ckpt 与 flag 不匹配，结果会无效，已中止")
    model.eval()

    # ---------------- data
    samples = collect_samples(cfd_root, cfd_nations, a.expr)
    n_miss = sum(1 for *_, f in samples if f is None)
    samples = [s for s in samples if s[3] is not None and s[4] is not None]
    if a.limit:
        samples = samples[:a.limit]
    tag = a.cfd_nations or "ALL"
    print(f"[data] {tag} -> predict_p_{a.race_ckpt}  可用 {len(samples)} 张（缺失 {n_miss}）")

    tf = T.Compose([T.Resize(tuple(cfg["FACE_INPUT_SIZE"])), T.ToTensor(),
                    T.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])])
    loader = DataLoader(CFDDataset(samples, tf, a.lab_point_mode), batch_size=a.batch_size,
                        shuffle=False, num_workers=a.num_workers, pin_memory=True,
                        collate_fn=collate_drop_none)

    dm = np.array({"none": (0, 0, 0), "l": (1, 0, 0), "ab": (0, 1, 1), "lab": (1, 1, 1)}[
        str(a.lab_delta_channels).lower()], dtype=np.float32)

    n = len(samples)
    probs = np.full((n, len(attrs)), np.nan, dtype=np.float32)
    cents = np.full((n, len(attrs) * 3), np.nan, dtype=np.float32)
    lps_all = np.zeros((n, 3), dtype=np.float32)

    with torch.no_grad():
        for packed in loader:
            if packed is None:
                continue
            faces, globs_, lps, idxs = packed
            out = model(faces.to(device), None, globs_.to(device),
                        stat_features=None, lab_point=lps.to(device))
            scores, centers = out if isinstance(out, tuple) else (out, None)
            idx = idxs.numpy()
            probs[idx, :scores.shape[1]] = torch.sigmoid(scores).float().cpu().numpy()
            if centers is not None:
                cents[idx] = centers.float().cpu().numpy()
            lps_all[idx] = lps.numpy()
    ok = np.isfinite(probs).any(axis=1)
    n_ok = int(ok.sum())
    print(f"[prog] 完成 {n_ok}/{n}")

    # ---------------- 明细 xlsx
    # 10 个属性各有独立 center head → 按属性展开 (N, 3*A) 后再加回先验
    n_attr = len(attrs)
    # 注意用 tile 而不是 repeat：需要整块 (L,a,b) 按属性重复，repeat 会变成 L,L,L...
    lp_expand = np.tile(lps_all, (1, n_attr))                   # (N, 3A)
    dm_tile = np.tile(dm, n_attr)                               # (3A,)
    lab_all = cents + lp_expand * dm_tile                       # (N, 3A)

    df = pd.DataFrame({
        "图片名": [s[2] for s in samples],
        "原图": [str(s[3]) for s in samples],
        "face": [str(s[4]) for s in samples],
        "cfd_nation": [s[0] for s in samples],
    })
    for j, an in enumerate(attrs):
        df[f"score_{an}"] = probs[:, j]
    for j, an in enumerate(attrs):
        df[f"L*_{an}"] = lab_all[:, j * 3 + 0]
        df[f"a*_{an}"] = lab_all[:, j * 3 + 1]
        df[f"b*_{an}"] = lab_all[:, j * 3 + 2]
    df["lab_point_L"], df["lab_point_a"], df["lab_point_b"] = lps_all[:, 0], lps_all[:, 1], lps_all[:, 2]
    detail = out_dir / "cfd_predictions.xlsx"
    with pd.ExcelWriter(detail, engine="openpyxl") as w:
        for nation, sub in df.groupby("cfd_nation", sort=True):
            sub.drop(columns=["cfd_nation"]).to_excel(w, sheet_name=str(nation)[:31], index=False)
    print(f"[out] {detail}  行数 {len(df)}  sheets={sorted(df['cfd_nation'].unique())}")

    # ---------------- toMax 同格式 test_results.xlsx
    if not a.no_tomax_format:
        result = {
            "predictions": probs,
            "metadata": [{"original_name": s[2], "scene_person": s[1]} for s in samples],
            "centers": cents,
        }
        if str(a.lab_delta_channels).lower() != "none":
            result["lab_point"] = lps_all
            result["lab_delta_channels"] = str(a.lab_delta_channels).lower()
        out_xlsx = out_dir / "results" / "test_results.xlsx"
        export_to_xlsx(str(out_xlsx), argparse.Namespace(), result, None, None)
        _augment_rawdata_with_lab(out_xlsx, attrs, lab_all, lp_expand, None)
        print(f"[out] {out_xlsx}")

    # ---------------- ③ --if_render：pred_pics / check_pics
    if a.if_render:
        _render_pics(samples, lab_all, lp_expand, out_dir, attrs, a.render_limit)

    s = df["score_01Preference"]
    print(f"[stat] score_01Preference min={s.min():.4f} mean={s.mean():.4f} "
          f"max={s.max():.4f} std={s.std():.4f}   "
          f"L*_01Preference mean={df['L*_01Preference'].mean():.2f}   "
          f"L*_10Ruddy mean={df['L*_10Ruddy'].mean():.2f}")


if __name__ == "__main__":
    main()
