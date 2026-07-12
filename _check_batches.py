import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from predict_p.data.dataset import MultiAttributeDataset
from predict_p.config import Config

cfg = Config()
cfg.DATA_ROOT = '/root/autodl-tmp/deepskin/data'
cfg.GT_EXCEL_PATH = '/root/autodl-tmp/deepskin/nan_mask_report_v2.xlsx'
cfg.BATCH_SIZE = 16
cfg.MULTI_HEAD = True
cfg.NAN_HANDLING = 'loss_mask'
cfg.SPLIT_STRATEGY = 'stable_by_id_hash'

for race in ['AF', 'AS', 'CA', 'SA']:
    cfg.RACE = race
    print(f"\n=== {race} ===")
    for split_name in ['train', 'val', 'test']:
        ds = MultiAttributeDataset(cfg, split=split_name)
        n = len(ds)
        print(f"  {split_name}: {n} samples, {n // 16 + (1 if n % 16 else 0)} batches (bs=16)")
