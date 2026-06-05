import pandas as pd
import os

GT_PATH = "/root/autodl-tmp/gt/toMax_gt_01Preference.xlsx"
IMG_ROOT = "/root/autodl-tmp/rendered_2max"
OUT_CSV = "/root/autodl-tmp/hyperIQA/data/deepskin_01pref.csv"

def find_image(original_name):
    subject_prefix = original_name[:4]
    img_path = os.path.join(IMG_ROOT, subject_prefix, original_name + ".jpg")
    if os.path.exists(img_path):
        return img_path
    return None

def main():
    df = pd.read_excel(GT_PATH)
    print(f"[INFO] Read GT: {GT_PATH}")
    print(f"       rows={len(df)}, cols={list(df.columns)}")

    rows = []
    found = 0
    missing = 0

    for _, row in df.iterrows():
        name = row['original_name']
        score = row['preference_score']
        path = find_image(name)
        if path:
            rows.append({'img_path': path, 'score': score})
            found += 1
        else:
            print(f"  [WARN] Missing: {name}")
            missing += 1

    csv_df = pd.DataFrame(rows)
    csv_df.to_csv(OUT_CSV, index=False)
    print(f"\n[OK] CSV saved: {OUT_CSV}")
    print(f"      Found: {found}, Missing: {missing}")
    print(f"      Score range: [{csv_df['score'].min():.2f}, {csv_df['score'].max():.2f}]")
    print(f"      First 5:\n{csv_df.head().to_string()}")

if __name__ == '__main__':
    main()
