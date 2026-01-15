close all; % 关闭所有图窗
clc;       % 清空命令窗口
clear;     % 清除工作区所有变量
%% 
% img_file="D:\work\VIVOskinExpe\renderCode\dsp\femaleVIVO\r\jpg\card\discarded\rs09.jpg";
% img=imread(img_file);
% downsampled_img = imresize(img, 1/4);
% 
% % 旋转90度
% rotated_img = imrotate(downsampled_img, 90);
% 
% % 显示结果
% imshow(rotated_img);
% 
% % 保存结果（可选）
% imwrite(rotated_img, 'D:\work\VIVOskinExpe\renderCode\dsp\femaleVIVO\r\jpg\card\rs09.jpg');
%% 创建mask文件夹

% % 定义主文件夹路径
% dspFolder = 'dsp';
% maskFolder = 'mask';
% 
% % 获取所有以 'female' 或 'male' 开头的子文件夹
% subfolders = dir(fullfile(dspFolder, 'female*'));
% subfolders = [subfolders; dir(fullfile(dspFolder, 'male*'))];
% 
% % 遍历每个子文件夹
% for k = 1:length(subfolders)
%     % 获取当前子文件夹的名称
%     subfolderName = subfolders(k).name;
% 
%     % 构建对应的 i 子文件夹路径
%     iFolderPath = fullfile(dspFolder, subfolderName, 'i');
% 
%     % 构建目标文件夹路径
%     targetFolderName = strcat(subfolderName, 'i');
%     targetFolderPath = fullfile(maskFolder, targetFolderName);
%     if exist(targetFolderPath, 'dir')
%         disp([targetFolderPath,"already exist"])
%     end
%     % 检查目标文件夹是否存在，如果不存在则创建
%     if ~exist(targetFolderPath, 'dir')
%         mkdir(targetFolderPath);
%             % 复制每个 .jpg 文件到目标文件夹
%         for j = 1:length(jpgFiles)
%             sourceFilePath = fullfile(iFolderPath, jpgFiles(j).name);
%             destinationFilePath = fullfile(targetFolderPath, jpgFiles(j).name);
%             copyfile(sourceFilePath, destinationFilePath);
%         end
%     end
% 
%     % 获取 i 子文件夹中的所有 .jpg 文件
%     jpgFiles = dir(fullfile(iFolderPath, '*.jpg'));
% 
% 
% end
% 
% disp('文件复制完成。');

%% 自动检查是否有缺失的文件夹
% 
% % 指定 source 文件夹路径
% sourceFolder = 'E:\toVIVO\RealScene';
% 
% % 定义预期的文件名和后缀
% expectedFileNames = arrayfun(@(x) sprintf('rs%02d', x), 1:14, 'UniformOutput', false);  % rs01 到 rs14
% expectedJpgSuffix = '.jpg';  % jpg 文件夹下的文件后缀
% expectedRawSuffix = '.3fr';  % raw 文件夹下的文件后缀
% 
% % 创建总的日志文件
% logFile = fullfile(sourceFolder, 'total_log.txt');
% fid = fopen(logFile, 'w');  % 打开文件用于写入
% if fid == -1
%     error('无法创建日志文件');
% end
% 
% % 获取 source 文件夹下的所有一级子文件夹
% subFolders = dir(sourceFolder);
% subFolders = subFolders([subFolders.isdir]);  % 仅保留文件夹
% subFolders = subFolders(~ismember({subFolders.name}, {'.', '..'}));  % 排除 '.' 和 '..'
% 
% % 遍历每个一级子文件夹
% for i = 1:length(subFolders)
%     % 获取当前一级子文件夹名称和路径
%     currentFolderName = subFolders(i).name;
%     currentFolderPath = fullfile(sourceFolder, currentFolderName);
% 
%     % 检查一级子文件夹名称是否以 'female' 或 'male' 开头
%     if startsWith(currentFolderName, 'female') || startsWith(currentFolderName, 'male')
%         fprintf(fid, '检查文件夹: %s\n', currentFolderName);
% 
%         % 检查二级子文件夹（jpg 和 raw）
%         secondLevelFolders = {'jpg', 'raw'};
%         for j = 1:length(secondLevelFolders)
%             secondLevelFolderName = secondLevelFolders{j};
%             secondLevelFolderPath = fullfile(currentFolderPath, secondLevelFolderName);
% 
%             % 检查二级子文件夹是否存在
%             if ~isfolder(secondLevelFolderPath)
%                 fprintf(fid, '  缺失二级子文件夹: %s\n', secondLevelFolderName);
%                 continue;
%             end
% 
%             % 检查三级子文件夹（card 和 noCard）
%             thirdLevelFolders = {'card', 'noCard'};
%             for k = 1:length(thirdLevelFolders)
%                 thirdLevelFolderName = thirdLevelFolders{k};
%                 thirdLevelFolderPath = fullfile(secondLevelFolderPath, thirdLevelFolderName);
% 
%                 % 检查三级子文件夹是否存在
%                 if ~isfolder(thirdLevelFolderPath)
%                     fprintf(fid, '  缺失三级子文件夹: %s/%s\n', secondLevelFolderName, thirdLevelFolderName);
%                     continue;
%                 end
% 
%                 % 获取三级子文件夹下的所有文件
%                 files = dir(fullfile(thirdLevelFolderPath, '*'));
%                 files = files(~[files.isdir]);  % 仅保留文件，排除文件夹
% 
%                 % 检查文件数量是否为 14
%                 if length(files) ~= 14
%                     fprintf(fid, '  文件夹 %s/%s 下的文件数量不是 14 个，实际数量: %d\n', ...
%                         secondLevelFolderName, thirdLevelFolderName, length(files));
%                 end
% 
%                 % 检查文件名和后缀
%                 for m = 1:length(files)
%                     fileName = files(m).name;
%                     [~, name, ext] = fileparts(fileName);  % 分离文件名和后缀
% 
%                     % 检查文件名是否在预期列表中
%                     if ~ismember(name, expectedFileNames)
%                         fprintf(fid, '  多余文件: %s/%s/%s\n', ...
%                             secondLevelFolderName, thirdLevelFolderName, fileName);
%                     end
% 
%                     % 检查文件后缀是否正确（不区分大小写）
%                     if strcmp(secondLevelFolderName, 'jpg') && ~strcmpi(ext, expectedJpgSuffix)
%                         fprintf(fid, '  文件后缀错误: %s/%s/%s (应为 %s)\n', ...
%                             secondLevelFolderName, thirdLevelFolderName, fileName, expectedJpgSuffix);
%                     elseif strcmp(secondLevelFolderName, 'raw') && ~strcmpi(ext, expectedRawSuffix)
%                         fprintf(fid, '  文件后缀错误: %s/%s/%s (应为 %s)\n', ...
%                             secondLevelFolderName, thirdLevelFolderName, fileName, expectedRawSuffix);
%                     end
%                 end
% 
%                 % 检查是否有缺失的文件
%                 for m = 1:length(expectedFileNames)
%                     if strcmp(secondLevelFolderName, 'jpg')
%                         expectedFileName = [expectedFileNames{m}, expectedJpgSuffix];
%                     else
%                         expectedFileName = [expectedFileNames{m}, expectedRawSuffix];
%                     end
% 
%                     if ~exist(fullfile(thirdLevelFolderPath, expectedFileName), 'file')
%                         fprintf(fid, '  缺失文件: %s/%s/%s\n', ...
%                             secondLevelFolderName, thirdLevelFolderName, expectedFileName);
%                     end
%                 end
%             end
%         end
%     else
%         fprintf(fid, '多余的一级子文件夹: %s\n', currentFolderName);
%     end
% end
% 
% % 关闭日志文件
% fclose(fid);
% disp('检查完成！日志文件已生成。');

%% 对单个cube文件夹整理命名
%
% % 指定 source 文件夹路径
% sourceFolder = 'F:\cube\male97';
% 
% % 定义第一种规则的新名称
% newNames_cube = {'H3K', 'H4K', 'H5K', 'H6K', 'HD65', 'H7K', 'H8K', ...
%                  'mixH3KH8K', 'mixH3KHD65', 'mixH4KH8K', ...
%                  'mixH4KHD65', 'mixHL3K', 'mixHLD65', 'mixHL8K'};
% 
% % 定义第二种规则的名称映射
% oldNames_H = {'H3KH8K', 'H3KHD65', 'H4KH8K', 'H4KHD65', 'H3KL3K', 'HD65LD65', 'H8KL8K'};
% newNames_H = {'mixH3KH8K', 'mixH3KHD65', 'mixH4KH8K', 'mixH4KHD65', 'mixHL3K', 'mixHLD65', 'mixHL8K'};
% 
% % 在 source 文件夹下创建日志文件
% logFile = fullfile(sourceFolder, 'renameLog.txt');
% fid = fopen(logFile, 'w');  % 打开文件用于写入
% if fid == -1
%     error('无法创建日志文件');
% end
% 
% % 获取 source 文件夹下的所有二级子文件夹
% secondLevelFolders = dir(sourceFolder);
% secondLevelFolders = secondLevelFolders([secondLevelFolders.isdir]);  % 仅保留文件夹
% secondLevelFolders = secondLevelFolders(~ismember({secondLevelFolders.name}, {'.', '..'}));  % 排除 '.' 和 '..'
% 
% % 检查二级子文件夹数量是否为 14
% if length(secondLevelFolders) ~= 14
%     fprintf(fid, 'source 文件夹下的二级子文件夹数量不是 14 个，跳过处理。\n');
%     fclose(fid);  % 关闭日志文件
%     return;
% end
% 
% % 检查二级子文件夹名称是否以 'cube' 打头
% if all(startsWith({secondLevelFolders.name}, 'cube'))
%     % 按照第一种规则重命名
%     for j = 1:length(secondLevelFolders)
%         oldName = secondLevelFolders(j).name;  % 获取当前二级子文件夹名称
%         newName = newNames_cube{j};  % 获取新名称
% 
%         % 旧路径和新路径
%         oldPath = fullfile(sourceFolder, oldName);
%         newPath = fullfile(sourceFolder, newName);
% 
%         % 重命名文件夹
%         movefile(oldPath, newPath);
% 
%         % 记录日志
%         fprintf(fid, '已将文件夹 "%s" 重命名为 "%s"\n', oldName, newName);
%         fprintf( '已将文件夹 "%s" 重命名为 "%s"\n', oldName, newName);
%     end
% elseif all(startsWith({secondLevelFolders.name}, 'H'))
%     % 按照第二种规则重命名
%     for j = 1:length(secondLevelFolders)
%         oldName = secondLevelFolders(j).name;  % 获取当前二级子文件夹名称
% 
%         % 查找当前名称是否在映射表中
%         idx = find(strcmp(oldName, oldNames_H));
%         if ~isempty(idx)
%             newName = newNames_H{idx};  % 获取新名称
%         else
%             newName = oldName;  % 如果不在映射表中，保持原名称
%         end
% 
%         % 如果名称有变化，则重命名文件夹
%         if ~strcmp(oldName, newName)
%             oldPath = fullfile(sourceFolder, oldName);
%             newPath = fullfile(sourceFolder, newName);
%             movefile(oldPath, newPath);  % 重命名文件夹
%             fprintf(fid, '已将文件夹 "%s" 重命名为 "%s"\n', oldName, newName);
%             fprintf( '已将文件夹 "%s" 重命名为 "%s"\n', oldName, newName);
%         end
%     end
% else
%     % 如果文件夹名称既不以 'cube' 也不以 'H' 打头，记录日志
%     fprintf(fid, '二级子文件夹名称不符合规则，跳过处理。\n');
% end
% 
% % 关闭日志文件
% fclose(fid);
% disp('重命名完成！日志文件已生成。');
% %% 对多个cube文件夹整理命名
% 
% 
% % 指定 source 文件夹路径
% sourceFolder = 'E:\toVIVO\cube';
% 
% % 定义第一种规则的新名称
% newNames_cube = {'H3K', 'H4K', 'H5K', 'H6K', 'HD65', 'H7K', 'H8K', ...
%                  'mixH3KH8K', 'mixH3KHD65', 'mixH4KH8K', ...
%                  'mixH4KHD65', 'mixHL3K', 'mixHLD65', 'mixHL8K'};
% 
% % 定义第二种规则的名称映射
% oldNames_H = {'H3KH8K', 'H3KHD65', 'H4KH8K', 'H4KHD65', 'H3KL3K', 'HD65LD65', 'H8KL8K'};
% newNames_H = {'mixH3KH8K', 'mixH3KHD65', 'mixH4KH8K', 'mixH4KHD65', 'mixHL3K', 'mixHLD65', 'mixHL8K'};
% 
% % 获取 source 文件夹下的所有一级子文件夹
% subFolders = dir(sourceFolder);
% subFolders = subFolders([subFolders.isdir]);  % 仅保留文件夹
% subFolders = subFolders(~ismember({subFolders.name}, {'.', '..'}));  % 排除 '.' 和 '..'
% 
% % 遍历每个一级子文件夹
% for i = 1:length(subFolders)
%     % 获取当前一级子文件夹名称和路径
%     currentFolderName = subFolders(i).name;
%     currentFolderPath = fullfile(sourceFolder, currentFolderName);
% 
%     % 检查一级子文件夹名称是否以 'female' 或 'male' 打头
%     if startsWith(currentFolderName, 'female') || startsWith(currentFolderName, 'male')
%         % 在当前一级子文件夹下创建日志文件
%         logFile = fullfile(currentFolderPath, 'renameLog.txt');
%         fid = fopen(logFile, 'w');  % 打开文件用于写入
%         if fid == -1
%             error('无法创建日志文件');
%         end
% 
%         % 获取当前一级子文件夹下的所有二级子文件夹
%         secondLevelFolders = dir(currentFolderPath);
%         secondLevelFolders = secondLevelFolders([secondLevelFolders.isdir]);  % 仅保留文件夹
%         secondLevelFolders = secondLevelFolders(~ismember({secondLevelFolders.name}, {'.', '..'}));  % 排除 '.' 和 '..'
% 
%         % 检查二级子文件夹数量是否为 14
%         if length(secondLevelFolders) ~= 14
%             fprintf(fid, '文件夹 "%s" 下的二级子文件夹数量不是 14 个，跳过处理。\n', currentFolderName);
%             fclose(fid);  % 关闭日志文件
%             continue;
%         end
% 
%         % 检查二级子文件夹名称是否以 'cube' 打头
%         if all(startsWith({secondLevelFolders.name}, 'cube'))
%             % 按照第一种规则重命名
%             for j = 1:length(secondLevelFolders)
%                 oldName = secondLevelFolders(j).name;  % 获取当前二级子文件夹名称
%                 newName = newNames_cube{j};  % 获取新名称
% 
%                 % 旧路径和新路径
%                 oldPath = fullfile(currentFolderPath, oldName);
%                 newPath = fullfile(currentFolderPath, newName);
% 
%                 % 重命名文件夹
%                 movefile(oldPath, newPath);
% 
%                 % 记录日志
%                 fprintf(fid, '已将文件夹 "%s" 重命名为 "%s"\n', oldName, newName);
%             end
%         elseif all(startsWith({secondLevelFolders.name}, 'H'))
%             % 按照第二种规则重命名
%             for j = 1:length(secondLevelFolders)
%                 oldName = secondLevelFolders(j).name;  % 获取当前二级子文件夹名称
% 
%                 % 查找当前名称是否在映射表中
%                 idx = find(strcmp(oldName, oldNames_H));
%                 if ~isempty(idx)
%                     newName = newNames_H{idx};  % 获取新名称
%                 else
%                     newName = oldName;  % 如果不在映射表中，保持原名称
%                 end
% 
%                 % 如果名称有变化，则重命名文件夹
%                 if ~strcmp(oldName, newName)
%                     oldPath = fullfile(currentFolderPath, oldName);
%                     newPath = fullfile(currentFolderPath, newName);
%                     movefile(oldPath, newPath);  % 重命名文件夹
%                     fprintf(fid, '已将文件夹 "%s" 重命名为 "%s"\n', oldName, newName);
%                 end
%             end
%         else
%             % 如果二级子文件夹名称既不以 'cube' 也不以 'H' 打头，记录日志
%             fprintf(fid, '二级子文件夹名称不符合规则，跳过处理。\n');
%         end
% 
%         % 关闭日志文件
%         fclose(fid);
%         fprintf('文件夹 "%s" 的重命名完成，日志文件已生成。\n', currentFolderName);
%     end
% end
% 
% disp('所有文件夹重命名完成！');
%%
% % % %分离3fr和jpg
% % % % % % % 源文件夹路径，包含.3FR和.jpg文件
% sourceFolderPath = 'F:\20241202 第二轮肤色采集素材\哈苏\male97';
% 
% % 创建子文件夹路径
% destination3FRFolderPath = fullfile(sourceFolderPath, 'raw');
% destinationJPGFolderPath = fullfile(sourceFolderPath, 'jpg');
% 
% % 如果3FR子文件夹不存在，则创建它
% if ~exist(destination3FRFolderPath, 'dir')
%     mkdir(destination3FRFolderPath);
% end
% 
% % 如果jpg子文件夹不存在，则创建它
% if ~exist(destinationJPGFolderPath, 'dir')
%     mkdir(destinationJPGFolderPath);
% end
% 
% % 获取源文件夹中所有.3FR文件的列表
% fileList3FR = dir(fullfile(sourceFolderPath, '*.3FR'));
% 
% % 复制所有.3FR文件到3FR子文件夹
% for i = 1:length(fileList3FR)
%     % 构建源文件和目标文件的完整路径
%     sourceFile = fullfile(sourceFolderPath, fileList3FR(i).name);
%     destinationFile = fullfile(destination3FRFolderPath, fileList3FR(i).name);
%     if exist(destinationFile,"file")
%         continue
%     end
%     % 复制文件
%     % copyfile(sourceFile, destinationFile);
%     movefile(sourceFile, destinationFile);
% end
% 
% % 获取源文件夹中所有.jpg文件的列表
% fileListJPG = dir(fullfile(sourceFolderPath, '*.jpg'));
% 
% % 复制所有.jpg文件到jpg子文件夹
% for i = 1:length(fileListJPG)
%     % 构建源文件和目标文件的完整路径
%     sourceFile = fullfile(sourceFolderPath, fileListJPG(i).name);
%     destinationFile = fullfile(destinationJPGFolderPath, fileListJPG(i).name);
% 
%     % 复制文件
%     % copyfile(sourceFile, destinationFile);
%     movefile(sourceFile, destinationFile);
% end



%%
%rename i
% % 指定目录路径
% folderPath = 'F:\Hassel\Hassel\male97\jpg';  % 替换为你的文件夹路径
% % folderPath ='F:\Hassel\dsp\female97\i';
% % 获取目录中的所有jpg和3fr文件
% fileList = dir(fullfile(folderPath, '*.jpg')); 
% % fileList =  dir(fullfile(folderPath, '*.3fr'));
% 
% % 定义标签列表
% labels = {'H3K', 'H4K', 'H5K', 'H6K', 'HD65', 'H7K', 'H8K', ...
%           'M3K', 'M4K', 'M5K', 'M6K', 'MD65', 'M7K', 'M8K', ...
%           'L3K', 'L4K', 'L5K', 'L6K', 'LD65', 'L7K', 'L8K', ...
%           'BLUE', 'mixH3KH8K', 'mixH3KHD65', 'mixH4KH8K', ...
%           'mixH4KHD65', 'mixHL3K', 'mixHLD65', 'mixHL8K'};
% 
% % 检查文件数量是否与标签数量匹配
% if length(fileList) ~= length(labels)
%     error('文件数量与标签数量不匹配');
% end
% 
% % 创建对比文档
% logFile = fullfile(folderPath, 'rename_log.txt');
% fid = fopen(logFile, 'w');
% fprintf(fid, '原文件名\t新文件名\n');
% 
% % 遍历文件列表并重命名
% for i = 1:length(fileList)
%     % 获取原文件名
%     oldFileName = fileList(i).name;
% 
%     % 获取文件扩展名
%     [~, ~, fileExtension] = fileparts(oldFileName);
% 
%     % 获取新文件名
%     newFileName = [labels{i} fileExtension];
% 
%     % 记录原文件名和新文件名
%     fprintf(fid, '%s\t%s\n', oldFileName, newFileName);
% 
%     % 构建原文件和目标文件的完整路径
%     oldFilePath = fullfile(folderPath, oldFileName);
%     newFilePath = fullfile(folderPath, newFileName);
% 
%     % 重命名文件
%     movefile(oldFilePath, newFilePath);
% end
% 
% % 关闭对比文档
% fclose(fid);
% 
% disp('文件重命名完成，对比文档已生成。');

%%
% %rename r
% % % % 设置文件夹路径
% folderPath = 'F:\20241202 第二轮肤色采集素材\哈苏\male97\raw\card'; % 请替换为你的文件夹路径
% filePattern = fullfile(folderPath, '*.3fr');
% % filePattern = fullfile(folderPath, '*.jpg'); % 搜索所有jpg文件
% 
% % 获取文件夹中所有jpg文件的列表
% files = dir(filePattern);
% 
% % % %'1负一楼商场'% '2负一楼vivo'% '3下沉广场'% '4学校饭堂'% '5学校小卖部'
% % % % '6学校星巴克'% '7草地顺光'% '8草地侧光'% '9草地逆光'% '10阴天场景'
% % % % '11夕阳草地逆光'% '12夕阳草地侧光'% '13夜景小卖部门口'% '14 极夜小卖部对面'
% % 创建新的文件名数组（不包含后缀）
% % picname = ["rs02", "rs01", "rs03", "rs06", "rs05",  ...
% %            "rs07", "rs08", "rs09", "rs10","rs11", "rs12", "rs04", "rs13", "rs14"];
% picname = ["rs06","rs08","rs07",  "rs09","rs10","rs11", ...
%     "rs12", "rs13", "rs14","rs02", "rs01", "rs03",  ...
%              "rs04",  "rs05"];
% % 确保文件数量匹配
% if length(files) ~= length(picname)
%     error('文件数量与指定的文件名数量不匹配');
% end
% 
% % 打开日志文件
% logFile = fullfile(folderPath, 'rename_log.txt');
% fileID = fopen(logFile, 'w'); % 以写入模式打开文件
% 
% % 检查文件是否成功打开
% if fileID == -1
%     error('无法创建或打开日志文件');
% end
% 
% % 写入日志文件的头部信息
% fprintf(fileID, 'Rename Log\n');
% fprintf(fileID, 'Date: %s\n', datestr(now));
% fprintf(fileID, 'Folder: %s\n', folderPath);
% fprintf(fileID, '----------------------------------------\n');
% fprintf(fileID, 'Old Name\t\tNew Name\n');
% fprintf(fileID, '----------------------------------------\n');
% 
% % 重命名文件
% for i = 1:length(files)
%     oldFilename = files(i).name;
%     [~, name, ext] = fileparts(oldFilename); % 分离文件名和后缀
%     newFilename = fullfile(folderPath, strcat(picname(i) , ext)); % 构造新的文件名
%         % 记录旧名称和新名称到日志文件
%     fprintf(fileID, '%s\t\t%s\n', oldFilename, strcat(picname(i), ext));
%     movefile(fullfile(folderPath, oldFilename), newFilename); % 重命名文件
% end
% disp([folderPath,"d"]);

%%
% % % % 设置文件夹路径
% % folderPath='F:\20241202 第二轮肤色采集素材\哈苏\female78\jpg\noCard';
% folderPath = ['F:\Hassel\20240718 哈苏相机删减整理\20240724 肤色\male59\jpg\noCard']; 
% % folderPath = ['D:\work\VIVOskinExpe\renderCode\mask\male59r']; 
% slashes = strfind(folderPath, '\');
% model = folderPath((slashes(1,end-2)+1:slashes(1,end-1)-1));
% lastPart=strcat(model,"r");
% % dest_folder=fullfile("D:\work\VIVOskinExpe\renderCode\mask\male59r");
% dest_folder=fullfile("D:\work\VIVOskinExpe\renderCode\dsp\male59\r\jpg\noCard");
% % dest_folder=fullfile('F:\Hassel\dsp',model,'r\jpg\card');
% if ~exist(dest_folder,"dir")
%     mkdir(dest_folder);
% end
% % 获取文件夹中所有.jpg文件
% files = dir(fullfile(folderPath, '*.jpg'));
% 
% % 遍历文件
% for i = 1:length(files)
%     % 读取图像
%     filename = fullfile(folderPath, files(i).name);
%     img = imread(filename);
%     img=imrotate(img,90);
%     % 调整图像大小
%     imgResized = imresize(img, [2914 2185]);
% 
%     % 保存调整后的图像
%     dest_filename=fullfile(dest_folder, files(i).name);
%     imwrite(imgResized, dest_filename);
% end
% 
% disp('所有图像已调整大小并保存。');