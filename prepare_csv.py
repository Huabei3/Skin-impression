import pandas as pd
import os
from sklearn.model_selection import train_test_split

GT_PATH = "/root/autodl-tmp/gt/toMax_gt_01Preference.xlsx"
IMG_ROOT = "/root/autodl-tmp/rendered_2max"
OUT_DIR = "/root/autodl-tmp/iqa_pytorch_train/datasets/deepskin_01pref"

os.makedirs(OUT_DIR, exist_ok=True)

df = pd.read_excel(GT_PATH)
print(f"[INFO] Loaded {len(df)} records")

rows = []
for _, row in df.iterrows():
    name = row['original_name']
    subject = name[:4]
    img_path = os.path.join(IMG_ROOT, subject, f"{name}.jpg")
    if os.path.exists(img_path):
        rows.append({'name': img_path, 'mos': row['preference_score'], 'std': 0.0})

data = pd.DataFrame(rows)
print(f"[INFO] Found {len(data)} images")

train_idx, test_idx = train_test_split(range(len(data)), test_size=0.2, random_state=42)
data['split_name'] = 'train'
data.loc[test_idx, 'split_name'] = 'test'

csv_path = os.path.join(OUT_DIR, 'meta_info.csv')
data.to_csv(csv_path, index=False)
print(f"[DONE] CSV: {csv_path}")
print(f"  Train: {(data['split_name']=='train').sum()}, Test: {(data['split_name']=='test').sum()}")
print(f"  MOS: [{data['mos'].min():.3f}, {data['mos'].max():.3f}]")
