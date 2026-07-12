
import sys, os
sys.path.insert(0, '/root/autodl-tmp/deepskin')
from predict_p.config import Config
# Try to load dataset info
import pandas as pd
import glob

# Find Excel files
for f in glob.glob('/root/autodl-tmp/deepskin/*.xlsx') + glob.glob('/root/autodl-tmp/gt/*.xlsx'):
    print(f"Excel: {f}")
    try:
        df = pd.read_excel(f, sheet_name=None)
        for sheet, data in df.items():
            print(f"  Sheet '{sheet}': {data.shape}")
            if 'AF' in str(sheet) or 'race' in str(sheet).lower():
                print(f"    Columns: {list(data.columns)[:10]}")
    except Exception as e:
        print(f"  Error: {e}")
