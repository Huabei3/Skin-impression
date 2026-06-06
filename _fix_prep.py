import re

path = "/root/autodl-tmp/iqa_pytorch_train/prepare_deepskin_full.py"
with open(path) as f:
    c = f.read()

# 检查 valid 逻辑是否正确
# 当前: valid_rows 只在 env=="r" 时检查 scene
# 问题可能在: valid 行确实写入了 CSV，但 split 列的值是 "valid"
# 让我验证原始脚本

# 找到写入 CSV 的行
lines = c.split("\n")
for i, line in enumerate(lines):
    if "name","mos","std" in line:
        print(f"  CSV write line {i+1}: {line.strip()}")

# 强制替换所有 split 列名相关
c = c.replace('"split"]', '"split_name"]')
c = c.replace("'split']", "'split_name']")
c = c.replace('["name","mos","std","split_name"]', '["name","mos","std","split_name"]')  # already fixed

with open(path, "w") as f:
    f.write(c)
print("Prep script fixed")
