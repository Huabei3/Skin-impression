clc; clear; close all;

%%
% % 定义 females 和 males 列表
% females = ["female01", "female04", "female06", "female78", "female41", ...
%            "femaleVIVO", "female23", "female51", "female25", "female69"];
% males = ["male92", "male97", "male48", "male59", "male39", ...
%          "maleVIVO", "male21", "male46", "male22", "male28"];
% 
% % 指定文件夹路径
% folderPath = 'D:\work\VIVOskinExpe\camera model-20240924\whiteSquare'; % 替换为你的文件夹路径
% 
% % 获取文件夹下的所有子文件夹和文件
% contents = dir(folderPath);
% contents = contents(~ismember({contents.name}, {'.', '..'})); % 去掉 . 和 ..
% 
% % 生成时间戳
% timestamp = datestr(now, 'yyyymmdd_HHMM'); % 格式：20231025_1530
% 
% % 初始化日志内容
% logContent = sprintf('Renaming log - %s\n\n', timestamp);
% 
% % 遍历所有内容（包括文件和文件夹）
% for i = 1:length(contents)
%     itemName = contents(i).name; % 当前文件或文件夹名称
%     oldPath = fullfile(folderPath, itemName); % 当前文件或文件夹完整路径
% 
%     % 检查是否是文件夹
%     isFolder = contents(i).isdir;
% 
%     % 检查是否包含 females 列表中的元素
%     for j = 1:length(females)
%         if contains(itemName, females(j))
%             % 替换为 f%02d
%             newName = strrep(itemName, females(j), sprintf('f%02d', j));
%             newPath = fullfile(folderPath, newName); % 构建新路径
%             movefile(oldPath, newPath);
% 
%             % 记录日志
%             logEntry = sprintf('Renamed: %s -> %s\n', itemName, newName);
%             logContent = [logContent, logEntry];
%             break;
%         end
%     end
% 
%     % 检查是否包含 males 列表中的元素
%     for j = 1:length(males)
%         if contains(itemName, males(j))
%             % 替换为 m%02d
%             newName = strrep(itemName, males(j), sprintf('m%02d', j));
%             newPath = fullfile(folderPath, newName); % 构建新路径
%             movefile(oldPath, newPath);
% 
%             % 记录日志
%             logEntry = sprintf('Renamed: %s -> %s\n', itemName, newName);
%             logContent = [logContent, logEntry];
%             break;
%         end
%     end
% end
% 
% % 保存日志文件
% logFileName = fullfile(folderPath, sprintf('renamelog_%s.txt', timestamp));
% fid = fopen(logFileName, 'w');
% fprintf(fid, '%s', logContent);
% fclose(fid);
% 
% disp('重命名完成！日志文件已保存。');
%%
% % 定义 females 和 males 列表
females = ["female01", "female04", "female06", "female78", "female41", ...
           "femaleVIVO", "female23", "female51", "female25", "female69"];
males = ["male92", "male97", "male48", "male59", "male39", ...
         "maleVIVO", "male21", "male46", "male22", "male28"];

% 指定文件夹路径
folderPath = 'Z:\homes\Peggy\VIVOskinExpe\imageCapture\20240718 哈苏相机删减整理\20240723 肤色'; % 替换为你的文件夹路径

% 获取文件夹下的所有子文件夹
subFolders = dir(folderPath);
subFolders = subFolders([subFolders.isdir]); % 只保留文件夹
subFolders = subFolders(~ismember({subFolders.name}, {'.', '..'})); % 去掉 . 和 ..

% 生成时间戳
timestamp = datestr(now, 'yyyymmdd_HHMM'); % 格式：20231025_1530

% 初始化日志内容
logContent = sprintf('Renaming log - %s\n\n', timestamp);

% 遍历子文件夹
for i = 1:length(subFolders)
    folderName = subFolders(i).name; % 当前文件夹名称
    oldName = fullfile(folderPath, folderName); % 当前文件夹完整路径

    % 检查是否包含 females 列表中的元素
    for j = 1:length(females)
        if contains(folderName, females(j))
            % 替换为 f%02d
            newName = strrep(folderName, females(j), sprintf('f%02d', j));
            newPath = fullfile(fileparts(oldName), newName); % 基于父文件夹路径构建新路径
            movefile(oldName, newPath);

            % 记录日志
            logEntry = sprintf('Renamed: %s -> %s\n', folderName, newName);
            logContent = [logContent, logEntry];
            break;
        end
    end

    % 检查是否包含 males 列表中的元素
    for j = 1:length(males)
        if contains(folderName, males(j))
            % 替换为 m%02d
            newName = strrep(folderName, males(j), sprintf('m%02d', j));
            newPath = fullfile(fileparts(oldName), newName); % 基于父文件夹路径构建新路径
            movefile(oldName, newPath);

            % 记录日志
            logEntry = sprintf('Renamed: %s -> %s\n', folderName, newName);
            logContent = [logContent, logEntry];
            break;
        end
    end
end

% 保存日志文件
logFileName = fullfile(folderPath, sprintf('renamelog_%s.txt', timestamp));
fid = fopen(logFileName, 'w');
fprintf(fid, '%s', logContent);
fclose(fid);

disp('重命名完成！日志文件已保存。');


%%
% 指定文件夹路径
% folderPath = 'G:\toVIVO\skinColorOfModels\cm700d'; % 替换为你的文件夹路径
% 
% % 获取文件夹下所有 .csv 文件
% fileList = dir(fullfile(folderPath, '*.csv')); % 获取所有 .csv 文件
% numFiles = length(fileList); % 文件数量
% 
% % 初始化元胞数组，用于存储每个文件的内容
% fileData = cell(numFiles, 1);
% 
% % 遍历每个文件
% for i_file = 1:numFiles
%     % 获取当前文件的完整路径
%     filePath = fullfile(folderPath, fileList(i_file).name);
% 
%     % 读取当前文件的所有工作表
%     [~, sheetNames] = xlsfinfo(filePath); % 获取工作表名称
%     numSheets = length(sheetNames); % 工作表数量
% 
%     % 初始化一个元胞数组，用于存储当前文件的所有工作表数据
%     sheetData = cell(numSheets, 1);
% 
%     % 遍历每个工作表
%     for i_sheet = 1:numSheets
%         sheetName = sheetNames{i_sheet};
% 
%         % 读取当前工作表的数据
%         [~, ~, rawData] = xlsread(filePath, sheetName); % 使用 xlsread 读取原始数据
% 
%         % 将当前工作表的数据存储到 sheetData 中
%         sheetData{i_sheet, 1} = rawData;
%     end
% 
%     % 将当前文件的所有工作表数据存储到 fileData 中
%     fileData{i_file, 1} = rawData;
% end
% 
% % 初始化 labC 和 ref 的单元格数组
% labC = cell(numFiles, 1);
% ref = cell(numFiles, 1);
% 
% % 处理 labC 数据
% for i_file = 1:numFiles
%     labC_ind = cell2mat(fileData{i_file, 1}([2:10,17:22],12:14));
%     labC_ind(:,4) = sqrt(labC_ind(:,2).^2 + labC_ind(:,3).^2); % 修正公式
%     labC_ind(end+1,:) = mean(labC_ind,1);
%     labC_ind_cell = mat2cell(labC_ind, ones(size(labC_ind, 1), 1), ones(size(labC_ind, 2), 1));
%     regionNames = ["forehead"; "forehead"; "forehead"; ...
%                    "rightcheek"; "rightcheek"; "rightcheek"; ...
%                    "leftcheek"; "leftcheek"; "leftcheek"; ...
%                    "rightneck"; "rightneck"; "rightneck"; ...
%                    "leftneck"; "leftneck"; "leftneck"; ...
%                    "mean"];
%     labC_ind_cell = [regionNames, labC_ind_cell];
%     headerRow = ["Region", "L*", "a*", "b*", "C*"];
%     labC_ind_cell = [headerRow; labC_ind_cell];
%     % 在 labC_ind_cell 上方加上一行文件名（去掉 .csv 后缀）
%     fileNameRow = [fileList(i_file).name(1:end-4), repmat("", 1, size(labC_ind_cell, 2)-1)]; % 去掉 .csv 后缀
%     labC_ind_cell = [fileNameRow; labC_ind_cell];
%     % 将处理后的数据存储到 labC 中
%     labC{i_file, 1} = labC_ind_cell;
%     labC_mean(1, i_file)=labC_ind_cell(18,2);
%     labC_mean(2, i_file)=labC_ind_cell(18,5);
%     headerRow_model{1,i_file}=fileList(i_file).name(1:end-4);
% end
% 
% labC_mean_cell = mat2cell(labC_mean, ones(size(labC_mean, 1), 1), ones(size(labC_mean, 2), 1));
% labC_mean_cell = [headerRow_model; labC_mean_cell];
% 
% % 处理 ref 数据
% for i_file = 1:numFiles
%     ref_ind = cell2mat(fileData{i_file, 1}([2:10,17:22],15:end));
%     ref_ind(end+1,:) = mean(ref_ind,1);
%     ref_ind_cell = mat2cell(ref_ind, ones(size(ref_ind, 1), 1), ones(size(ref_ind, 2), 1));
% 
%     regionNames = ["forehead"; "forehead"; "forehead"; ...
%                    "rightcheek"; "rightcheek"; "rightcheek"; ...
%                    "leftcheek"; "leftcheek"; "leftcheek"; ...
%                    "rightneck"; "rightneck"; "rightneck"; ...
%                    "leftneck"; "leftneck"; "leftneck"; ...
%                    "mean"];
%     ref_ind_cell = [regionNames, ref_ind_cell];
%     headerRow = 400:10:700;
%     headerRow = mat2cell(headerRow, ones(size(headerRow, 1), 1), ones(size(headerRow, 2), 1));
%     headerRow = ["Region", headerRow];
%     ref_ind_cell = [headerRow; ref_ind_cell];
%     fileNameRow = [fileList(i_file).name(1:end-4), repmat("", 1, size(ref_ind_cell, 2)-1)];
%     ref_ind_cell = [fileNameRow; ref_ind_cell];
%     % 将处理后的数据存储到 ref 中
%     ref{i_file, 1} = ref_ind_cell;
% end
% 
% % 将 labC 和 ref 的数据分别拼接成一个大的单元格数组
% labC_all = vertcat(labC{:});
% ref_all = vertcat(ref{:});
% % 将 string 类型转换为 cell 类型
% labC_all = cellstr(labC_all); % 将 string 转换为 cell
% ref_all = cellstr(ref_all);   % 将 string 转换为 cell
% 
% % 将拼接后的数据写入 Excel 文件
% outputFilePath = fullfile(folderPath, 'combined_data1.xlsx'); % 输出文件路径
% writecell(labC_all, outputFilePath, 'Sheet', 'labC'); % 写入 labC 数据到工作表 'labC'
% writecell(ref_all, outputFilePath, 'Sheet', 'ref'); % 写入 ref 数据到工作表 'ref'
% writecell(labC_mean_cell, outputFilePath, 'Sheet', 'labC_mean'); % 写入 ref 数据到工作表 'ref'
% disp('文件读取和写入完成！');
%%

% % 指定文件路径
% filePath = 'D:\work\VIVOskinExpe\renderCode\light_r\whole_withDiscard1.xlsx'; % 替换为你的文件路径
% 
% % 获取文件的工作表名称
% [~, sheetNames] = xlsfinfo(filePath);
% 
% % 生成新文件名
% [fileDir, fileName, fileExt] = fileparts(filePath);
% newFilePath = fullfile(fileDir, [fileName, '_modified', fileExt]);
% 
% % 遍历每个工作表
% for i_sheet = 1:length(sheetNames)
%     sheetName = sheetNames{i_sheet};
% 
%     % 读取当前工作表的数据
%     [~, ~, rawData] = xlsread(filePath, sheetName); % 使用 xlsread 读取原始数据
% 
%     % 检查首行是否有内容为 '弃用' 的列
%     discardCols = []; % 用于存储需要删除的列索引
%     for col = 1:size(rawData, 2)
%         if strcmp(rawData{1, col}, '弃用')
%             % 记录需要删除的列及其左边一列
%             discardCols = [discardCols, col - 1, col]; % 左边一列和当前列
%         end
%     end
% 
%     % 如果有需要删除的列
%     if ~isempty(discardCols)
%         % 去重并排序
%         discardCols = unique(discardCols);
%         discardCols = sort(discardCols, 'descend'); % 从右到左删除，避免索引错位
% 
%         % 删除列
%         for col = discardCols
%             rawData(:, col) = []; % 删除指定列
%         end
%     end
% 
%     % 将修改后的数据写入新文件的工作表
%     xlswrite(newFilePath, rawData, sheetName);
% end
% 
% disp('列删除完成！');
% disp(['新文件已保存为: ', newFilePath]);
%% 查看每个sheet大小
% 
% filePath = 'D:\work\VIVOskinExpe\renderCode\light_r\whole_20250115_233044_modified.xlsx'; % 替换为你的文件路径
% 
% 
% % 获取文件的工作表名称
% [~, sheetNames] = xlsfinfo(filePath);
% 
% % 生成新文件名
% [fileDir, fileName, fileExt] = fileparts(filePath);
% newFilePath = fullfile(fileDir, [fileName, '_modified', fileExt]);
% 
% % 遍历每个工作表
% for i_sheet = 1:length(sheetNames)
%     sheetName = sheetNames{i_sheet};
% 
%     % 读取当前工作表的数据
%     [~, ~, rawData{i_sheet,1}] = xlsread(filePath, sheetName); % 使用 xlsread 读取原始数据
% end
%% 更改日期格式
% 
% filePath = 'D:\work\VIVOskinExpe\renderCode\light_r\whole_20250115_233044.xlsx'; % 替换为你的文件路径
% 
% 
% % 获取文件的工作表名称
% [~, sheetNames] = xlsfinfo(filePath);
% 
% % 生成新文件名
% [fileDir, fileName, fileExt] = fileparts(filePath);
% newFilePath = fullfile(fileDir, [fileName, '_modified', fileExt]);
% 
% % 遍历每个工作表
% for i_sheet = 1:length(sheetNames)
%     sheetName = sheetNames{i_sheet};
% 
%     % 读取当前工作表的数据
%     [~, ~, rawData] = xlsread(filePath, sheetName); % 使用 xlsread 读取原始数据
% 
%     % 遍历每一行和每一列，查找内容为 '日期时间' 的单元格
%     for row = 1:size(rawData, 1)
%         for col = 1:size(rawData, 2)
%             % 检查当前单元格内容是否为 '日期时间'
%             if strcmp(rawData{row, col}, '日期时间')
%                 % 获取右侧单元格的内容（即 Excel 日期时间序列号）
%                 if col + 1 <= size(rawData, 2) % 确保右侧单元格存在
%                     excelDate = rawData{row, col + 1};
% 
%                     % 检查是否为数值（Excel 日期时间序列号）
%                     if isnumeric(excelDate)
%                         % 将 Excel 日期时间序列号转换为 MATLAB 日期时间
%                         matlabDate = datetime(excelDate, 'ConvertFrom', 'excel');
% 
%                         % 将日期时间格式化为 'YYYY/MM/DD HH:MM:SS'
%                         formattedDate = datestr(matlabDate, 'yyyy/mm/dd HH:MM:SS');
% 
%                         % 将格式化后的日期时间写回右侧单元格
%                         rawData{row, col + 1} = formattedDate;
%                     end
%                 end
%             end
%         end
%     end
% 
%     % 将修改后的数据写入新文件的工作表
%     xlswrite(newFilePath, rawData, sheetName);
% end
% 
% disp('日期时间转换完成！');
% disp(['新文件已保存为: ', newFilePath]);

%% 汇总
% % 指定文件夹路径
% folderPath = 'D:\work\VIVOskinExpe\renderCode\light_r';
% 
% % 获取文件夹下所有以 'rspd' 结尾的 .xlsx 文件
% fileList = dir(fullfile(folderPath, '2024*rspd.xlsx'));
% 
% % 获取第一个文件的工作表名称（假设所有文件的工作表名称一致）
% [~, sheetNames] = xlsfinfo(fullfile(folderPath, fileList(1).name));
% 
% % 初始化一个 cell 数组来存储每个工作表的数据
% sheetData = cell(length(sheetNames), 1);
% 
% % 遍历每个工作表
% for i_sheet = 1:length(sheetNames)
%     sheetName = sheetNames{i_sheet};
% 
%     % 初始化一个空元胞数组来存储当前工作表的数据
%     combinedCell = {};
% 
%     % 初始化最大行数
%     maxRows = 0;
% 
%     % 第一次遍历：获取最大行数
%     for i_file = 1:length(fileList)
%         fileName = fullfile(folderPath, fileList(i_file).name);
%         data = readtable(fileName, 'Sheet', sheetName);
%         maxRows = max(maxRows, height(data));
%     end
% 
%     % 第二次遍历：填充空缺行并横向拼接
%     for i_file = 1:length(fileList)
%         fileName = fullfile(folderPath, fileList(i_file).name);
% 
%         % 读取当前工作表的数据
%         data = readtable(fileName, 'Sheet', sheetName);
% 
%         % 将表格转换为元胞数组
%         dataCell = table2cell(data);
% 
%         % 检查并转换日期时间单元格为字符串
%         for row = 1:size(dataCell, 1)
%             for col = 1:size(dataCell, 2)
%                 if isdatetime(dataCell{row, col}) % 如果当前单元格是日期时间类型
%                     dataCell{row, col} = datestr(dataCell{row, col}, 'yyyy/mm/dd HH:MM:SS'); % 转换为字符串
%                 end
%             end
%         end
% 
%         % 如果当前文件的行数小于最大行数，填充空缺行
%         if height(data) < maxRows
%             missingRows = maxRows - height(data);
%             dataCell = [dataCell; cell(missingRows, width(dataCell))]; % 用空元胞填充
%         end
% 
%         % 将当前文件的数据横向拼接到 combinedCell 中
%         combinedCell = [combinedCell, dataCell];
%     end
% 
%     % 将当前工作表的数据存储到 sheetData 中
%     sheetData{i_sheet} = combinedCell;
% end
% 
% % 生成带时间戳的文件名
% timestamp = datestr(now, 'yyyymmdd_HHMMSS'); % 获取当前时间戳，格式为 'yyyymmdd_HHMMSS'
% outputFileName = fullfile(folderPath, ['whole_', timestamp, '.xlsx']);
% 
% % 遍历每个工作表，将数据写入汇总文件
% for k = 1:length(sheetNames)
%     sheetName = sheetNames{k};
% 
%     % 获取当前工作表的元胞数组数据
%     currentData = sheetData{k};
% 
%     % 使用 writecell 将元胞数组写入 Excel 文件
%     writecell(currentData, outputFileName, 'Sheet', sheetName);
% end
% 
% disp('汇总完成！');
% disp(['生成的文件名为: ', outputFileName]);