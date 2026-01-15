close all; % 关闭所有图窗
clc;       % 清空命令窗口
clear;     % 清除工作区所有变量
%% 定义所有需要处理的 attribute
attributes = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
attribute_names_new = ["Preference", "Attractiveness", "Feminine", "Cooperative", ...
    "Youth", "Healthy", "Fidelity","Harmony", "Fair", "Ruddy"];

% lastParts = {'f04i', 'f05i', 'f06i', 'm04i', 'm05i', 'm06i',...
% 'f01i', 'f02i', 'f03i', 'm01i', 'm02i', 'm03i',...
% 'f07i', 'f08i','m07i', 'm08i',...
% 'f09i', 'f10i','m09i', 'm10i'};nation="all";n_para = 21;iOr='i';
%-------------rs----------------
lastParts = {'f04r', 'f05r', 'f06r', 'm04r', 'm05r', 'm06r',...
'f01r', 'f02r', 'f03r', 'm01r', 'm02r', 'm03r',...
'f07r', 'f08r','m07r', 'm08r',...
'f09r', 'f10r','m09r', 'm10r'};n_para = 14;iOr='r';
nations=["AS","CA","SA","AF"];
nation="all";
if contains(lastParts{1},'i')
    iOr='i';
    picname_group = ["h3k", "h4k", "h5k", "h6k", "hd65", "h7k", "h8k",...
    "m3k", "m4k", "m5k", "m6k", "md65", "m7k", "m8k",...
     "l3k", "l4k", "l5k", "l6k", "ld65", "l7k", "l8k"];
elseif contains(lastParts{1},'r')
    iOr='r';
    picname_group = ["rs01","rs02","rs03","rs04","rs05","rs06","rs07", ...
                     "rs08","rs09","rs10","rs11","rs12","rs13","rs14"];
end
scale_type_origin="unscaled";

Dtype = 'efit_p';obs_type="non_model";
% 定义人种对应的lastParts索引
nation_indices = cell(5, 1); % 5个人种（包括"all"）
% AS (Asian): f04i, f05i, f06i, m04i, m05i, m06i (索引1-6)
nation_indices{1} = 1:6;
% CA (Caucasian): f01i, f02i, f03i, m01i, m02i, m03i (索引7-12)  
nation_indices{2} = 7:12;
% SA (South Asian): f07i, f08i, m07i, m08i (索引13-16)
nation_indices{3} = 13:16;
% AF (African): f09i, f10i, m09i, m10i (索引17-20)
nation_indices{4} = 17:20;
% all: 所有索引 (索引1-20)
nation_indices{5} = 1:20; % 假设 "all" 包含所有 lastParts

%%
save_folder = fullfile("AnalyseResults_p", Dtype,scale_type_origin,"sum_list",obs_type );
% 创建保存文件夹
if ~exist(save_folder, "dir")
    mkdir(save_folder);
end
lab_PMCC = [62.11, 18.96, 19.76];
labC_PMCC = [lab_PMCC, sqrt(lab_PMCC(1, 2)^2 + lab_PMCC(1, 3)^2)];
% 初始化 corr_attr_all 用于存储所有 i_para 的 corr_attr
corr_attr_all = cell(length(picname_group), 2);
% 初始化用于存储所有 lastPart 的 corr_attr_all
all_corr_attr = cell(length(lastParts), length(picname_group));
%% 循环处理每个 lastPart
for lastPart_idx = 1:length(lastParts)
    lastPart = lastParts{lastPart_idx};
    lastPart=strrep(lastPart,"add","");
    dir_labNgroup=dir(fullfile("AnalyseResults_p",Dtype,scale_type_origin,lastPart,obs_type, ...
        "01Preference\labNscore\","labNscore*.mat"));
    % 循环处理每个 i_para（即每个 light）
    for i_para = 1:length(picname_group)
        fprintf('Processing lastPart: %s, light: %s\n', lastPart, picname_group{i_para}); % 更新提示信息
        data2=[];data3=[];
        MSVNlab = load(fullfile(dir_labNgroup(i_para).folder, ...
           strcat("labNscore_group",lastPart,picname_group(i_para),".mat")));
        data2=MSVNlab.lab_group(:,2);
        data3=MSVNlab.lab_group(:,3);
        picname_check_temp{i_para,1}=picname_group(i_para);
        picname_check_temp{i_para,2}=dir_labNgroup(i_para).name;
        picname_check{lastPart_idx}=picname_check_temp;
        % 初始化 y 用于存储每个 attribute 的 y 值
        y = cell(length(attributes), 1);
        % 循环处理每个 attribute
        for attribute = attributes
            % 生成 attribute_serial
            attribute_serial = strcat(sprintf("%02d", attribute), attribute_names_new(attribute));
            if attribute==7
                obs_type_used="model_group";
            else
                obs_type_used=obs_type;
            end
            source_file4 = fullfile('AnalyseResults_p', Dtype,scale_type_origin, lastPart, ...
                obs_type_used, attribute_serial, 'ellipPara', 'fitRes.mat');
            % 加载 source_file4
            if exist(source_file4, 'file')
                load(source_file4);
                if size(par_all,1)>=i_para
                    par = par_all(i_para, :);
                else
                    par=nan([1,size(par_all,2)]);
                end
                y{attribute} = (1 ./ (1 + par(6) * exp(sqrt(par(1) * (data2 - par(4)).^2 + par(2) * (data3 - par(5)).^2 + ...
                    par(3) * (data2 - par(4)) .* (data3 - par(5)))))) .* ((par(1) * (data2 - par(4)).^2 + ...
                    par(2) * (data3 - par(5)).^2 + par(3) * (data2 - par(4)) .* (data3 - par(5))) >= 0);
            end
        end
        % 计算 corr_attr
        corr_attr = zeros(length(attributes), length(attributes));
        for i_attr = attributes
            for j_attr = attributes
                if isempty(y{i_attr}) || isempty(y{j_attr})
                    corr_attr(i_attr, j_attr) = NaN;
                elseif std(y{i_attr}(:)) == 0 || std(y{j_attr}(:)) == 0
                    corr_attr(i_attr, j_attr) = NaN;
                else
                    corr_attr(i_attr, j_attr) = corr(y{i_attr}(:), y{j_attr}(:));
                end
            end
        end
        % 存储 corr_attr
        corr_attr_all{i_para, 1} = corr_attr;
        corr_attr_all{i_para, 2} = picname_group(i_para);
        % 将当前 lastPart 的 corr_attr 存储到 all_corr_attr
        all_corr_attr{lastPart_idx, i_para} = corr_attr;
    end
    % 将 corr_attr_all 写入 Excel 文件
    if ~exist(fullfile(save_folder, lastPart), "dir")
        mkdir(fullfile(save_folder, lastPart));
    end
    excel_file = fullfile(save_folder, lastPart, 'corr_attr_summary.xlsx');
    for i_para = 1:length(picname_group)
        sheet_name = picname_group{i_para};
        writematrix(corr_attr_all{i_para, 1}, excel_file, 'Sheet', sheet_name);
    end
end
%% 计算不同 lastPart 的 corr_attr_all 的平均值
% 初始化用于存储所有 corr_attr 的三维数组
corr_attr_3d = zeros(length(attributes), length(attributes), length(lastParts), length(picname_group));
% 将每个 lastPart 的 corr_attr 存储到三维数组中
for lastPart_idx = 1:length(lastParts)
    for i_para = 1:length(picname_group)
        corr_attr_3d(:, :, lastPart_idx, i_para) = all_corr_attr{lastPart_idx, i_para};
    end
end

% 将 attribute_names_new 转换为 cell 类型
attribute_names_cell = cellstr(attribute_names_new);
avg_excel_file = fullfile("AnalyseResults_p", Dtype,scale_type_origin,"sum_list", ...
    strcat(iOr,obs_type,'avg_corr_attr.xlsx'));

% 计算并写入所有 lastPart 的平均值 (原有的 "Average_Corr_Attr" 工作表)
avg_corr_attr_all_lastParts = nanmean(nanmean(corr_attr_3d, 4), 3);
avg_corr_attr_all_lastParts(end+1,:)=nanmean(avg_corr_attr_all_lastParts,1);
avg_corr_attr_with_header_all = [["", attribute_names_cell]; [[attribute_names_cell,"mean"]', num2cell(avg_corr_attr_all_lastParts)]];
writematrix(avg_corr_attr_with_header_all, avg_excel_file, 'Sheet', 'Average_Corr_Attr');
%%
% 循环处理每个 nation，计算并写入对应人种的平均值
for i_nation = 1:length(nations)
    current_nation_indices = nation_indices{i_nation};
    
    % 检查当前 nation 的索引是否有效，并且包含在 lastParts 的范围内
    if ~isempty(current_nation_indices) && max(current_nation_indices) <= length(lastParts)
        % 提取当前 nation 对应的数据
        corr_attr_nation_subset = corr_attr_3d(:,:,current_nation_indices,:);
        
        % 计算当前 nation 的平均值
        avg_corr_attr_nation = nanmean(nanmean(corr_attr_nation_subset, 4), 3);
        avg_corr_attr_nation(end+1,:)=nanmean(avg_corr_attr_nation,1);
        
        % 构建带表头的矩阵
        avg_corr_attr_with_header_nation = [["", attribute_names_cell]; [[attribute_names_cell,"mean"]', num2cell(avg_corr_attr_nation)]];
        
        % 写入 Excel 文件，工作表名称为 nation
        writematrix(avg_corr_attr_with_header_nation, avg_excel_file, 'Sheet', nations{i_nation});
        fprintf('已将 %s 的平均相关性矩阵写入 Excel 文件。\n', nations{i_nation});
    else
        fprintf('警告：人种 %s 的索引无效或超出 lastParts 范围，跳过处理。\n', nations{i_nation});
    end
end

%% 将每个 lastPart_idx 和 i_para 对应的 corr_attr_3d 写入 Excel 文件
% 创建一个新的 Excel 文件

% 初始化一个空的单元格数组用于存储所有数据
combined_data = {};

% 遍历每个 lastPart_idx 和 i_para
for lastPart_idx = 1:length(lastParts)
    for i_para = 1:length(picname_group)
        % 获取当前 lastPart 和 i_para 的 corr_attr
        corr_attr = corr_attr_3d(:, :, lastPart_idx, i_para);

        % 在行首和列首添加 attribute_serial
        corr_attr_with_header = [["", attribute_names_new]; [attribute_names_new', num2cell(corr_attr)]];

        % 在前面添加一列 picname_group(i_para)
        corr_attr_with_header = [[lastParts{lastPart_idx}, repmat({''}, 1, length(attribute_names_new))]; ...
            [picname_group(i_para), repmat({''}, 1, length(attribute_names_new))]; ...
            corr_attr_with_header];

        % 将当前数据添加到 combined_data
        combined_data = [combined_data; corr_attr_with_header; repmat({''}, 1, size(corr_attr_with_header, 2))];
    end
end
output_folder=fullfile("AnalyseResults_p",Dtype,scale_type_origin,"sum_list");
if ~exist(output_folder,"dir")
    mkdir(output_folder);
end
% 将 combined_data 写入 Excel 文件
combined_excel_file = fullfile(output_folder, strcat(nation,iOr,'combined_corr_attr_summary.xlsx'));
writematrix(combined_data, combined_excel_file, 'Sheet', 'Combined_Corr_Attr');

disp("Processing complete.");

%%
% 读取 Excel 文件

data = readmatrix(avg_excel_file); % 读取数据部分（10x10 矩阵）

% 找到 <1 的值
less_than_one = data(data < 1);

% 找到最大的前 20% 的值
num_values = numel(less_than_one); % <1 的总数量
top_20_percent = floor(0.2 * num_values); % 前 20% 的数量
[~, sorted_indices] = sort(less_than_one, 'descend'); % 降序排序
top_indices = sorted_indices(1:top_20_percent); % 前 20% 的索引

% 在对应数据后面加上 "high"
modified_data = num2cell(data); % 将矩阵转换为 cell 数组
[row, col] = find(data < 1); % 找到 <1 的值的位置
for i = 1:length(row)
    if ismember(data(row(i), col(i)), less_than_one(top_indices)) % 如果是前 20%
        modified_data{row(i), col(i)} = [num2str(data(row(i), col(i))), ' high']; % 加上 "high"
    else
        modified_data{row(i), col(i)} = num2str(data(row(i), col(i))); % 其他 <1 的值转换为字符串
    end
end

% 将修改后的表格写入新的 Excel 文件
output_filename = fullfile(output_folder,strcat(nation,iOr,'corr.xlsx')); % 输出文件名
writecell(modified_data, output_filename); % 写入 Excel 文件

disp(strcat("处理完成，结果已保存到",output_folder));