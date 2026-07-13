"""Fix TOPIQ_NR_Face YAML files: replace network.type with CFANet."""
import os

base = "/root/autodl-tmp/iqa_pytorch_train/options/train/deepskin/TOPIQ_NR_Face"

for race in ["SA", "CA", "AS", "AF"]:
    f = os.path.join(base, f"train_TOPIQ_NR_Face_{race}.yml")
    with open(f) as fh:
        content = fh.read()
    # Fix: replace TOPIQ_NR_Face -> CFANet with model_name
    content = content.replace(
        "type: TOPIQ_NR_Face",
        "type: CFANet\n  model_name: topiq_nr_gfiqa_res50\n  use_ref: false"
    )
    with open(f, "w") as fh:
        fh.write(content)
    print(f"=== {race} ===")
    with open(f) as fh:
        for line in fh:
            if any(kw in line for kw in ["network:", "type:", "model_name:", "use_ref:"]):
                print(line.rstrip())
    print()
