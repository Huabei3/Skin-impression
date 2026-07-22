"""
pyiqa CSV generator - subject-level per-race split
"""
import pandas as pd, os, re

GT_XLSX = "/root/autodl-tmp/gt/toMax_gt_01Preference.xlsx"
IMG_ROOT = "/root/autodl-tmp/rendered_2max"
OUT_DIR = "/root/autodl-tmp/iqa_pytorch_train/datasets/deepskin"

RACE_MAP = {n: "CA" if n<=3 else "AS" if n<=6 else "SA" if n<=8 else "AF" for n in range(1,11)}
TEST_SUBJECTS = {"m02","m05","m08","m09"}
VALID_CONFIG = {"f02":{"rs02","rs04"},"f05":{"rs02","rs04"},"f08":{"rs02","rs04"},"f09":{"rs02","rs04"}}

xl = pd.ExcelFile(GT_XLSX)
print(f"GT sheets: {len(xl.sheet_names)}")

all_rows = []
missing = 0

for sheet in xl.sheet_names:
    subject_base = sheet[:3]   # "f02"
    env = sheet[3]             # "i" or "r"
    num = int(sheet[1:3])      # 2
    race = RACE_MAP[num]
    df = pd.read_excel(GT_XLSX, sheet_name=sheet)

    for _, row in df.iterrows():
        name = row["original_name"]
        score = row["preference_score"]
        img_path = os.path.join(IMG_ROOT, sheet, name + ".jpg")
        if not os.path.exists(img_path):
            missing += 1
            continue

        # Split logic (same as train_race.py)
        if subject_base in TEST_SUBJECTS:
            split = "test"
        elif subject_base in VALID_CONFIG and env == "r":
            m = re.search(r"(rs\d+)", name)
            scene = m.group(1) if m else ""
            split = "val" if scene in VALID_CONFIG[subject_base] else "train"
        else:
            split = "train"

        all_rows.append({
            "race": race, "name": img_path.split("/")[-2] + "/" + os.path.basename(img_path),
            "img_path": img_path, "mos": score, "std": 0.0,
            "split_name": split, "subject": subject_base, "env": env,
        })

data = pd.DataFrame(all_rows)
print(f"Total: {len(data)}, Missing: {missing}")

# Per-race outputs
for race in ["CA","AS","SA","AF"]:
    rd = data[data["race"]==race].copy()
    out_subdir = os.path.join(OUT_DIR, race)
    os.makedirs(out_subdir, exist_ok=True)

    # pyiqa CSV
    csv_path = os.path.join(out_subdir, "meta_info.csv")
    rd[["name","mos","std","split_name"]].to_csv(csv_path, index=False)

    # Debug: check split distribution
    split_counts = rd["split_name"].value_counts()
    print(f"[{race}] T:{split_counts.get('train',0)} V:{split_counts.get('valid',0)} T:{split_counts.get('test',0)} -> {csv_path}")

    # Check valid rows exist
    valid_rows = rd[rd["split_name"]=="val"]
    if len(valid_rows) > 0:
        print(f"  Sample valid: {valid_rows[['name','subject','env']].head(3).to_string(index=False)}")
    else:
        print(f"  WARNING: No valid rows for {race}!")

print("DONE")
