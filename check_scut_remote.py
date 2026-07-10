import paramiko
import sys

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect('connect.westc.seetacloud.com', port=26143, username='root', password='Zy6Aw8Wd')

# Check for SCUT dataset
stdin, stdout, stderr = ssh.exec_command('find /root -type d -name "*SCUT*" -o -name "*FBP*" 2>/dev/null | head -10')
result = stdout.read().decode()
print("=== SCUT Dataset Search ===")
print(result)

# Check BeautyPredict dataset directory
stdin, stdout, stderr = ssh.exec_command('ls -la /root/BeautyPredict-master/dataset/ 2>/dev/null')
result = stdout.read().decode()
print("\n=== BeautyPredict dataset directory ===")
print(result)

ssh.close()
