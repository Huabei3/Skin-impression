"""
train_race.py - Per-race hyperIQA training with subject-level split
使用方式: python train_race.py --race CA --epochs 16 --batch_size 96
          python train_race.py --all --epochs 16 --batch_size 96
"""
import os, sys, json, time, argparse, re
import numpy as np
import pandas as pd
import torch
from pathlib import Path

# Add hyperIQA to path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from HyerIQASolver import HyperIQASolver

# ============================================================
# Config
# ============================================================
GT_XLSX = "/root/autodl-tmp/gt/toMax_gt_01Preference.xlsx"
IMG_ROOT = "/root/autodl-tmp/rendered_2max"
OUT_DIR = "/root/autodl-tmp/hyperIQA/output_race"
CKPT_DIR = "/root/autodl-tmp/hyperIQA/checkpoints_race"
os.makedirs(OUT_DIR, exist_ok=True)
os.makedirs(CKPT_DIR, exist_ok=True)

RACE_MAP = {n: "CA" if n <= 3 else "AS" if n <= 6 else "SA" if n <= 8 else "AF" for n in range(1, 11)}
TEST_SUBJECTS = {"m02", "m05", "m08", "m09"}
VALID_CONFIG = {sb: {"rs02", "rs04"} for sb in ["f02", "f05", "f08", "f09"]}

TOTAL_IMAGES = 23100
EXPECTED_FILES = {f"{g}{n:02d}{e}": 462 if e == "r" else 693 for g in "fm" for n in range(1, 11) for e in "ir"}


def integrity_check():
    """Checklist 3: 数据集完整性"""
    print("=" * 60)
    print("  CHECKLIST 3: Dataset Integrity Check")
    print("=" * 60)
    checks = []
    xl = pd.ExcelFile(GT_XLSX)
    total = 0

    for sheet in xl.sheet_names:
        df = pd.read_excel(GT_XLSX, sheet_name=sheet)
        n = len(df)
        total += n
        img_dir = os.path.join(IMG_ROOT, sheet)
        expected = EXPECTED_FILES.get(sheet, 0)
        actual = len(os.listdir(img_dir)) if os.path.exists(img_dir) else 0

        checks.append({
            "sheet": sheet, "gt_rows": n, "expected_files": expected,
            "actual_files": actual, "ok": (n == expected == actual)
        })
        if n != expected or expected != actual:
            checks[-1]["note"] = f"MISMATCH: gt={n}, exp={expected}, actual={actual}"

    df_checks = pd.DataFrame(checks)
    df_checks.to_excel(os.path.join(OUT_DIR, "integrity_check.xlsx"), index=False)

    all_ok = df_checks["ok"].all()
    print(f"  GT sheets: {len(xl.sheet_names)}")
    print(f"  Total records: {total} / {TOTAL_IMAGES}")
    print(f"  All matched: {all_ok}")
    if not all_ok:
        bad = df_checks[~df_checks["ok"]]
        print(f"  MISMATCHES: {len(bad)}")
        for _, r in bad.iterrows():
            print(f"    {r['sheet']}: {r.get('note', '')}")
    return all_ok


def build_split(race):
    """Checklist 1: 数据集划分"""
    print(f"\n{'=' * 60}")
    print(f"  CHECKLIST 1: Build split for {race}")
    print(f"{'=' * 60}")

    xl = pd.ExcelFile(GT_XLSX)
    train_rows, valid_rows, test_rows = [], [], []

    for sheet in xl.sheet_names:
        subject_base = sheet[:3]
        env = sheet[3]
        num = int(sheet[1:3])
        sheet_race = RACE_MAP[num]

        if sheet_race != race:
            continue

        df = pd.read_excel(GT_XLSX, sheet_name=sheet)

        for _, row in df.iterrows():
            name = row["original_name"]
            score = row["preference_score"]
            img_path = os.path.join(IMG_ROOT, sheet, f"{name}.jpg")

            record = {"img_path": img_path, "score": score,
                       "subject_base": subject_base, "env": env, "name": name}

            if subject_base in TEST_SUBJECTS:
                test_rows.append(record)
            elif subject_base in VALID_CONFIG and env == "r":
                m = re.search(r"(rs\d+)", name)
                scene = m.group(1) if m else None
                if scene in VALID_CONFIG[subject_base]:
                    valid_rows.append(record)
                else:
                    train_rows.append(record)
            else:
                train_rows.append(record)

    print(f"  Train: {len(train_rows)}")
    print(f"  Valid: {len(valid_rows)}")
    print(f"  Test:  {len(test_rows)}")

    # Subject-level isolation check
    train_subs = {r["subject_base"] for r in train_rows}
    test_subs = {r["subject_base"] for r in test_rows}
    overlap = train_subs & test_subs
    print(f"  Subject isolation: {'PASS' if not overlap else f'FAIL (overlap: {overlap})'}")

    return train_rows, valid_rows, test_rows


def save_split_xlsx(train_rows, valid_rows, test_rows, race):
    """Save split validation xlsx"""
    all_data = []
    for split_name, rows in [("train", train_rows), ("valid", valid_rows), ("test", test_rows)]:
        for r in rows:
            all_data.append({**r, "split": split_name})

    df = pd.DataFrame(all_data)
    path = os.path.join(OUT_DIR, f"split_{race}.xlsx")
    df.to_excel(path, index=False)
    print(f"  Split xlsx saved: {path}")


def write_csv(train_rows, valid_rows, test_rows, race):
    """Write CSV for DeepskinFolder"""
    csv_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "data")
    os.makedirs(csv_dir, exist_ok=True)

    for split_name, rows in [("train", train_rows), ("test", test_rows),
                               ("valid", valid_rows)]:
        csv_path = os.path.join(csv_dir, f"deepskin_{race}_{split_name}.csv")
        with open(csv_path, "w") as f:
            f.write("img_path,score\n")
            for r in rows:
                f.write(f'{r["img_path"]},{r["score"]}\n')
        print(f"  CSV: {csv_path} ({len(rows)} rows)")

    # 合并 train+valid 用于训练
    csv_path = os.path.join(csv_dir, f"deepskin_{race}_trainval.csv")
    all_train = train_rows + valid_rows
    with open(csv_path, "w") as f:
        f.write("img_path,score\n")
        for r in all_train:
            f.write(f'{r["img_path"]},{r["score"]}\n')
    print(f"  CSV: {csv_path} ({len(all_train)} rows)")

    return csv_path


def train_race(race, train_rows, valid_rows, test_rows, config):
    """Train hyperIQA for a single race"""
    print(f"\n{'=' * 60}")
    print(f"  TRAINING: {race}")
    print(f"{'=' * 60}")

    csv_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "data")

    # CSV路径
    train_csv = os.path.join(csv_dir, f"deepskin_{race}_trainval.csv")
    test_csv = os.path.join(csv_dir, f"deepskin_{race}_test.csv")

    # 建立 index range (DeepskinFolder 用 index 从0开始的list)
    n_trainval = len(train_rows) + len(valid_rows)
    n_test = len(test_rows)

    from HyerIQASolver import HyperIQASolver

    # 临时搭 config 对象
    class Cfg:
        pass

    cfg = Cfg()
    cfg.dataset = "deepskin"
    cfg.epochs = config.get("epochs", 16)
    cfg.train_patch_num = config.get("train_patch_num", 25)
    cfg.test_patch_num = config.get("test_patch_num", 25)
    cfg.batch_size = config.get("batch_size", 96)
    cfg.patch_size = config.get("patch_size", 224)
    cfg.lr = config.get("lr", 2e-5)
    cfg.lr_ratio = config.get("lr_ratio", 10)
    cfg.weight_decay = config.get("weight_decay", 5e-4)

    # ===== Validation-aware training loop =====
    import data_loader, models
    from scipy import stats

    # Build train/val/test loaders
    train_idx = list(range(n_trainval - len(valid_rows)))
    val_idx = list(range(n_trainval - len(valid_rows), n_trainval))
    test_idx = list(range(n_test))

    # 用两个CSV分别加载
    train_loader = data_loader.DataLoader(
        "deepskin", train_csv, train_idx, cfg.patch_size,
        cfg.train_patch_num, batch_size=cfg.batch_size, istrain=True)
    val_loader = data_loader.DataLoader(
        "deepskin", train_csv, val_idx, cfg.patch_size,
        cfg.test_patch_num, batch_size=1, istrain=False)
    test_loader = data_loader.DataLoader(
        "deepskin", test_csv, test_idx, cfg.patch_size,
        cfg.test_patch_num, batch_size=1, istrain=False)

    train_data = train_loader.get_data()
    val_data = val_loader.get_data()
    test_data = test_loader.get_data()

    # Model
    model_hyper = models.HyperNet(16, 112, 224, 112, 56, 28, 14, 7).cuda()
    model_hyper.train(True)

    l1_loss = torch.nn.L1Loss().cuda()
    backbone_params = list(map(id, model_hyper.res.parameters()))
    hypernet_params = filter(lambda p: id(p) not in backbone_params, model_hyper.parameters())

    paras = [
        {"params": hypernet_params, "lr": cfg.lr * cfg.lr_ratio},
        {"params": model_hyper.res.parameters(), "lr": cfg.lr},
    ]
    solver = torch.optim.Adam(paras, weight_decay=cfg.weight_decay)

    best_val_srcc = -1.0
    best_test_srcc = 0.0
    best_test_plcc = 0.0
    best_epoch = 0
    no_improve = 0
    results_log = []

    print(f"{'Epoch':<6} {'TrainLoss':<10} {'ValSRCC':<10} {'ValPLCC':<10} {'TestSRCC':<10} {'TestPLCC':<10}")
    print("-" * 60)

    for epoch in range(cfg.epochs):
        # === Train ===
        epoch_loss = []
        pred_scores = []
        gt_scores = []

        for img, label in train_data:
            img = torch.tensor(img.cuda())
            label = torch.tensor(label.cuda())
            solver.zero_grad()

            paras_out = model_hyper(img)
            model_target = models.TargetNet(paras_out).cuda()
            for param in model_target.parameters():
                param.requires_grad = False

            pred = model_target(paras_out["target_in_vec"])
            pred_scores += pred.cpu().tolist()
            gt_scores += label.cpu().tolist()

            loss = l1_loss(pred.squeeze(), label.float().detach())
            epoch_loss.append(loss.item())
            loss.backward()
            solver.step()

        train_loss = sum(epoch_loss) / len(epoch_loss)

        # === Validate ===
        model_hyper.train(False)
        val_preds, val_gts = [], []
        for img, label in val_data:
            img = torch.tensor(img.cuda())
            label = torch.tensor(label.cuda())
            paras_out = model_hyper(img)
            model_target = models.TargetNet(paras_out).cuda()
            model_target.train(False)
            pred = model_target(paras_out["target_in_vec"])
            val_preds.append(float(pred.item()))
            val_gts += label.cpu().tolist()

        val_preds = np.mean(np.reshape(np.array(val_preds), (-1, cfg.test_patch_num)), axis=1)
        val_gts = np.mean(np.reshape(np.array(val_gts), (-1, cfg.test_patch_num)), axis=1)

        val_srcc, _ = stats.spearmanr(val_preds, val_gts)
        val_plcc, _ = stats.pearsonr(val_preds, val_gts)

        # === Test ===
        test_preds, test_gts = [], []
        for img, label in test_data:
            img = torch.tensor(img.cuda())
            label = torch.tensor(label.cuda())
            paras_out = model_hyper(img)
            model_target = models.TargetNet(paras_out).cuda()
            model_target.train(False)
            pred = model_target(paras_out["target_in_vec"])
            test_preds.append(float(pred.item()))
            test_gts += label.cpu().tolist()

        test_preds = np.mean(np.reshape(np.array(test_preds), (-1, cfg.test_patch_num)), axis=1)
        test_gts = np.mean(np.reshape(np.array(test_gts), (-1, cfg.test_patch_num)), axis=1)

        test_srcc, _ = stats.spearmanr(test_preds, test_gts)
        test_plcc, _ = stats.pearsonr(test_preds, test_gts)

        model_hyper.train(True)

        print(f"{epoch+1:<6} {train_loss:<10.4f} {val_srcc:<10.4f} {val_plcc:<10.4f} {test_srcc:<10.4f} {test_plcc:<10.4f}")

        results_log.append({
            "epoch": epoch + 1, "train_loss": train_loss,
            "val_srcc": val_srcc, "val_plcc": val_plcc,
            "test_srcc": test_srcc, "test_plcc": test_plcc,
        })

        # Early stopping on val SRCC
        if val_srcc > best_val_srcc:
            best_val_srcc = val_srcc
            best_test_srcc = test_srcc
            best_test_plcc = test_plcc
            best_epoch = epoch + 1
            no_improve = 0

            # CHECKLIST 2: Save checkpoint
            ckpt_path = os.path.join(CKPT_DIR, f"{race}_best.pth")
            torch.save({
                "epoch": epoch + 1,
                "model_state_dict": model_hyper.state_dict(),
                "best_val_srcc": best_val_srcc,
                "best_test_srcc": best_test_srcc,
                "best_test_plcc": best_test_plcc,
                "race": race,
            }, ckpt_path)
            print(f"  >> Checkpoint saved: {ckpt_path}")
        else:
            no_improve += 1
            if no_improve >= config.get("patience", 8):
                print(f"  Early stopping at epoch {epoch + 1}")
                break

        # LR decay
        lr = cfg.lr / pow(10, (epoch // 6))
        if epoch > 8:
            cfg.lr_ratio = 1
        paras = [
            {"params": hypernet_params, "lr": lr * cfg.lr_ratio},
            {"params": model_hyper.res.parameters(), "lr": lr},
        ]
        solver = torch.optim.Adam(paras, weight_decay=cfg.weight_decay)

    # Save results
    result = {
        "race": race,
        "best_epoch": best_epoch,
        "best_val_srcc": float(best_val_srcc),
        "best_test_srcc": float(best_test_srcc),
        "best_test_plcc": float(best_test_plcc),
        "train_size": len(train_rows),
        "valid_size": len(valid_rows),
        "test_size": len(test_rows),
        "config": config,
        "epoch_log": results_log,
    }

    result_path = os.path.join(OUT_DIR, f"result_{race}.json")
    with open(result_path, "w") as f:
        json.dump(result, f, indent=2)
    print(f"\n  Results saved: {result_path}")
    print(f"  Best: epoch={best_epoch}, val_SRCC={best_val_srcc:.4f}, test_SRCC={best_test_srcc:.4f}, test_PLCC={best_test_plcc:.4f}")

    return result


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--race", type=str, help="Single race: CA/AS/SA/AF")
    parser.add_argument("--all", action="store_true", help="Train all 4 races")
    parser.add_argument("--epochs", type=int, default=30)
    parser.add_argument("--batch_size", type=int, default=96)
    parser.add_argument("--lr", type=float, default=2e-5)
    parser.add_argument("--patience", type=int, default=10)
    args = parser.parse_args()

    # === CHECKLIST 3: Integrity ===
    integrity_check()

    races = ["SA", "CA", "AS", "AF"] if args.all else [args.race]

    config = {
        "epochs": args.epochs,
        "batch_size": args.batch_size,
        "lr": args.lr,
        "patience": args.patience,
        "train_patch_num": 25,
        "test_patch_num": 25,
        "patch_size": 224,
        "lr_ratio": 10,
        "weight_decay": 5e-4,
    }

    all_results = {}

    for race in races:
        # CHECKLIST 1: Split
        train_rows, valid_rows, test_rows = build_split(race)
        save_split_xlsx(train_rows, valid_rows, test_rows, race)

        # Write CSVs
        write_csv(train_rows, valid_rows, test_rows, race)

        # Train
        result = train_race(race, train_rows, valid_rows, test_rows, config)
        all_results[race] = result

    # Final summary
    print(f"\n{'=' * 60}")
    print("  FINAL SUMMARY")
    print(f"{'=' * 60}")
    for race, r in all_results.items():
        print(f"  {race}: val_SRCC={r['best_val_srcc']:.4f}, test_SRCC={r['best_test_srcc']:.4f}, test_PLCC={r['best_test_plcc']:.4f} (epoch {r['best_epoch']})")

    # Save summary
    summary_path = os.path.join(OUT_DIR, "summary_all.json")
    with open(summary_path, "w") as f:
        json.dump(all_results, f, indent=2)
    print(f"\nSummary saved: {summary_path}")

if __name__ == "__main__":
    main()
