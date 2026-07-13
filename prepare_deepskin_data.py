"""
DeepSkin 数据准备脚本 — 生成 split_result + loss_mask xlsx + pyiqa meta_info CSV

复用 pyiqa 训练时的数据加载逻辑（GeneralNRDataset 的 init_path_mos + get_split）：
- dataroot_target + name -> 完整路径
- meta_info.csv 的 split_name 列做 train/val/test 筛选

用法（在 inst5 上运行）:
  python prepare_deepskin_data.py --data-root /root/autodl-tmp --output-dir /root/autodl-tmp/iqa_pytorch_train/datasets/deepskin --all-races
"""
import os, argparse, re
import pandas as pd

GT_DIR = "/root/autodl-tmp/gt"
IMG_ROOT = "/root/autodl-tmp/rendered_2max"

RACE_MAP = {n: "CA" if n <= 3 else "AS" if n <= 6 else "SA" if n <= 8 else "AF"
            for n in range(1, 11)}
TEST_SUBJECTS = {"m02", "m05", "m08", "m09"}
VALID_CONFIG = {
    "f02": {"rs02", "rs04"}, "f05": {"rs02", "rs04"},
    "f08": {"rs02", "rs04"}, "f09": {"rs02", "rs04"},
}
ALL_ATTRS = [
    "01Preference", "02Attractiveness", "03Feminine",
    "04Cooperative", "05Youth", "06Healthy",
    "07Fidelity", "08Harmony", "09Fair", "10Ruddy",
]
RACES = ["CA", "AS", "SA", "AF"]


def load_gt_scores(attr_name):
    """Load GT scores from toMax_gt_{attr}.xlsx -> {original_name: score}"""
    xlsx_path = os.path.join(GT_DIR, f"toMax_gt_{attr_name}.xlsx")
    if not os.path.exists(xlsx_path):
        return {}
    lookup = {}
    xl = pd.ExcelFile(xlsx_path)
    for sheet in xl.sheet_names:
        df = pd.read_excel(xl, sheet_name=sheet)
        for _, row in df.iterrows():
            oname = str(row.iloc[0])
            score = float(row.iloc[1])
            if pd.notna(score):
                lookup[oname] = score
    return lookup


def extract_oname(path_name):
    """Extract original_name from 'f07i/f07ih3k_01.jpg' -> 'f07ih3k_01'"""
    fname = os.path.basename(str(path_name))
    return os.path.splitext(fname)[0]


def get_scene_name(path_name):
    """Extract scene name from 'f07i/f07ih3k_01.jpg' -> 'f07ih3k'"""
    oname = extract_oname(path_name)
    m = re.match(r"(.+?)_\d+$", oname)
    return m.group(1) if m else oname


def get_split(subject_base, env, name):
    """Subject-level split logic, same as pyiqa training."""
    if subject_base in TEST_SUBJECTS:
        return "test"
    elif subject_base in VALID_CONFIG and env == "r":
        m = re.search(r"(rs\d+)", name)
        scene = m.group(1) if m else ""
        return "val" if scene in VALID_CONFIG[subject_base] else "train"
    else:
        return "train"


def build_per_race_data(race, img_root=None, face_mode=False):
    """Build per-race DataFrame.

    Args:
        race: one of CA/AS/SA/AF
        img_root: image root dir (rendered_2max or rendered_face)
        face_mode: if True, use _face.jpg suffix for rendered_face images
    """
    if img_root is None:
        img_root = IMG_ROOT
    suffix = "_face.jpg" if face_mode else ".jpg"
    rows = []
    for sheet, subject_base, env, num in _iter_sheets(race):
        df = pd.read_excel(os.path.join(GT_DIR, "toMax_gt_01Preference.xlsx"), sheet_name=sheet)
        for _, row in df.iterrows():
            name = row["original_name"]
            score = row["preference_score"]
            img_path = os.path.join(img_root, sheet, name + suffix)
            if not os.path.exists(img_path):
                continue
            rel_name = sheet + "/" + name + suffix
            split = get_split(subject_base, env, name)
            scene = get_scene_name(rel_name)
            rows.append({
                "name": rel_name, "mos": score, "std": 0.0,
                "split_name": split,
                "subject": subject_base, "env": env, "scene": scene,
                "original_name": name,
            })
    return pd.DataFrame(rows)


def _iter_sheets(race):
    """Iterate sheet names for a given race."""
    race_nums = [n for n, r in RACE_MAP.items() if r == race]
    sheets = []
    for n in race_nums:
        prefix = f"f{n:02d}" if n < 10 else f"f{n}"
        for env in ["i", "r"]:
            sheets.append((f"{prefix}{env}", prefix, env, n))
    for n in race_nums:
        prefix = f"m{n:02d}" if n < 10 else f"m{n}"
        for env in ["i", "r"]:
            sheets.append((f"{prefix}{env}", prefix, env, n))
    return sheets


def build_scene_level_split(df):
    """Build scene-level split_result DataFrame (same format as Gao's split_result_CA.xlsx)"""
    rows = []
    for scene, group in df.groupby("scene"):
        subject = group.iloc[0]["subject"]
        env = group.iloc[0]["env"]
        split = group.iloc[0]["split_name"]
        # Determine iOr: 'i' or 'r'
        i_or = env  # 'i' or 'r'
        # Get model: subject without env
        model = subject
        rows.append({
            "Set": split, "Model": model, "iOr": i_or,
            "Scene": scene, "original_name": scene,
            "scene_person": f"{subject}{env}",
        })
    return pd.DataFrame(rows).sort_values(["Set", "Model", "Scene"]).reset_index(drop=True)


def build_loss_mask(df, all_attr_scores):
    """Build scene-level loss_mask DataFrame (same format as Gao's data_integrity_CA.xlsx)

    A scene is TRUE for an attribute if ALL 33 variants have GT scores.
    """
    rows = []
    for scene, group in df.groupby("scene"):
        subject = group.iloc[0]["subject"]
        env = group.iloc[0]["env"]
        folder = f"{subject}{env}"

        row = {"folder": folder, "subject": subject, "scene": scene}
        valid_count = 0
        for attr in ALL_ATTRS:
            scores = all_attr_scores.get(attr, {})
            # Check all 33 variants
            all_valid = True
            for _, img_row in group.iterrows():
                oname = img_row["original_name"]
                if oname not in scores:
                    all_valid = False
                    break
            col_name = f"{attr}_valid"
            row[col_name] = all_valid
            if all_valid:
                valid_count += 1
        row["valid_attrs"] = valid_count
        rows.append(row)

    result = pd.DataFrame(rows)
    # Sort by folder, scene
    result = result.sort_values(["folder", "scene"]).reset_index(drop=True)
    return result


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--data-root", default="/root/autodl-tmp")
    parser.add_argument("--output-dir", default="/root/autodl-tmp/iqa_pytorch_train/datasets/deepskin")
    parser.add_argument("--all-races", action="store_true")
    parser.add_argument("--race", default=None, choices=RACES)
    args = parser.parse_args()

    global GT_DIR, IMG_ROOT
    GT_DIR = os.path.join(args.data_root, "gt")
    IMG_ROOT = os.path.join(args.data_root, "rendered_2max")

    races = RACES if args.all_races else [args.race] if args.race else RACES

    # Pre-load all 10 attribute GTs (for loss mask)
    print("[INFO] Loading 10 attribute GTs for loss mask...")
    all_attr_scores = {}
    for attr in ALL_ATTRS:
        all_attr_scores[attr] = load_gt_scores(attr)
        print(f"  {attr}: {len(all_attr_scores[attr])} entries")

    # Two modes: face (rendered_face, _face.jpg) and global (rendered_2max, .jpg)
    modes = [
        ("face", os.path.join(args.data_root, "rendered_face"), True),
        ("global", os.path.join(args.data_root, "rendered_2max"), False),
    ]

    for mode_name, img_root, face_mode in modes:
        print(f"\n{'#'*60}")
        print(f"  MODE: {mode_name} ({img_root})")
        print(f"{'#'*60}")

        for race in races:
            print(f"\n  --- {race} ---")

            df = build_per_race_data(race, img_root=img_root, face_mode=face_mode)
            print(f"  Total images: {len(df)}")
            print(f"  Split distribution: {dict(df['split_name'].value_counts())}")

            # 1. Save meta_info CSV
            out_subdir = os.path.join(args.output_dir, mode_name, race)
            os.makedirs(out_subdir, exist_ok=True)
            csv_path = os.path.join(out_subdir, "meta_info.csv")
            df[["name", "mos", "std", "split_name"]].to_csv(csv_path, index=False)
            print(f"  Saved: {csv_path}")

            # 2. Generate split_result xlsx
            split_df = build_scene_level_split(df)
            split_path = os.path.join(out_subdir, f"split_result_{race}.xlsx")
            split_df.to_excel(split_path, index=False)
            print(f"  Saved: {split_path}")

            # 3. Generate loss_mask xlsx
            mask_df = build_loss_mask(df, all_attr_scores)
            mask_path = os.path.join(out_subdir, f"loss_mask_{race}.xlsx")
            mask_df.to_excel(mask_path, index=False)
            print(f"  Saved: {mask_path}")
            for attr in ALL_ATTRS:
                col = f"{attr}_valid"
                print(f"    {attr}: {mask_df[col].sum()}/{len(mask_df)}")
    print("\n[DONE]")


if __name__ == "__main__":
    main()
