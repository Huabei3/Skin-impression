close all;
clc;
clear;
addpath("..\..\utils\"); % 确保路径正确指向您的utils文件夹
%%
% 模特名称列表（f=女性，m=男性，数字为编号）
new_names = [ "f04", "f05", "f06", "m04", "m05", "m06",...
              "f01", "f02", "f03", "m01", "m02", "m03",...
              "f07", "f08","m07", "m08",...
              "f09", "f10","m09", "m10"];
% iOr='i';
iOr='i';
% 颜色标签列表（H=高照度，M=中照度，L=低照度，D65=标准光源）
if iOr=='i'
    % 颜色标签列表（H=高照度，M=中照度，L=低照度，D65=标准光源）
    pcn = ["H3K", "H4K", "H5K", "H6K", "HD65", "H7K", "H8K", ...
           "M3K", "M4K", "M5K", "M6K", "MD65", "M7K", "M8K", ...
           "L3K", "L4K", "L5K", "L6K", "LD65", "L7K", "L8K"];
else
    pcn = ["rs01","rs02","rs03","rs04","rs05","rs06","rs07", ...
                 "rs08","rs09","rs10","rs11","rs12","rs13","rs14"];
end
nations = ["AS", "CA", "SA", "AF"];
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
nation_indices{5} = 1:20;
% 校准数据路径（datai_ipv35_3.mat：LUT模型 显示模型的XYZ白点数据）
datai_file = '..\..\calibration\display_model\datai_ipv35_3.mat';
wd65=[94.813  100.000  107.262];
LUT=load(datai_file);
XYZw_LUT=LUT.XYZw;
wd65_scaled=wd65./100.*XYZw_LUT(2);
attributes_to_process = [1,6,7,8,9,10]; % 只处理这些属性
% 评估属性列表（1-10对应不同感知属性，需与attribute_names一一对应）
attribute_names = ["Preference", "Attractiveness", "Feminine", "Cooperative", ...
                   "Youth", "Healthy", "Fidelity","Harmony", "Fair", "Ruddy"];
% 过滤出需要处理的属性名称，用于Excel列标题
filtered_attribute_names = attribute_names(attributes_to_process);

% **新增检查：确保 filtered_attribute_names 不包含空字符串且非空**
% 移除可能存在的空字符串
filtered_attribute_names = filtered_attribute_names(strlength(filtered_attribute_names) > 0);
if isempty(filtered_attribute_names)
    error('错误: 过滤后的属性名称为空。请检查 attributes_to_process 或 attribute_names。');
end

% 目标评分配置（rela=相对评分，abs=绝对评分；1=满分）
target_score=1; % 目标评分值（0-1之间，转换为百分比）
target_score_str=num2str(target_score*100); % 字符串化评分（用于路径命名）
score_type="rela"; % 评分类型
render_type="srgb";

Dtype="efit2";
obs_type="non_model";
% 定义输出Excel文件的完整路径
excel_output_path = fullfile('..\..\data', ...
    'correlation_results',strcat(iOr,obs_type,'.xlsx'));
% 确保输出目录存在
[output_dir,~,~] = fileparts(excel_output_path);
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end
% 如果文件已存在，则删除，确保每次都是新的开始
if exist(excel_output_path, 'file')
    delete(excel_output_path);
end
% 加载标准Lab值（aveLab_D65_Asian.mat：亚洲人肤色在D65下的平均Lab值）
load("aveLab_D65_Asian.mat","labC_HD65");
lab_PMCC = [62.11, 18.96, 19.76];
labC_PMCC = [lab_PMCC, sqrt(lab_PMCC(1, 2)^2 + lab_PMCC(1, 3)^2)];
for i_model=1:length(new_names)
    current_model_name = new_names(i_model);
    source_folder=fullfile('mask',strcat(current_model_name,iOr));
    source_folder=char(source_folder);
    slashes = strfind(source_folder, '\');
    lastPart=source_folder(slashes(1,end)+1:end);
    model = lastPart(1:end-1);
    
    % 提取肤色时是否给边缘像素赋予透明度
    % 权重开关（判断是否为特定模型，需说明模型差异：如f04i等模型不使用权重）
    if ismember(lastPart,["f04i","f05i","f06i","m04i","m06i"])
        if_wei=0;
    else
        if_wei=1;
    end
    if ismember(lastPart,["m02i","m03i"])
        if_2mask=1;
    else
        if_2mask=0;
    end
    
    i_type=select_type(model); % 假设 select_type 函数已定义
    
    % 创建一个用于存储当前model所有相关性的表格数据
    % 行是pcn，列是attribute
    correlation_table_data = cell(length(pcn) + 1, length(filtered_attribute_names) + 1);
    
    % **修改：设置表格的左上角单元格标题**
    correlation_table_data{1, 1} = '光源/属性'; % 或者 'PCN_Name', 'Light_Attribute' 等
    
    % 设置第一列为pcn名称
    correlation_table_data(2:end, 1) = cellstr(pcn');
    % 设置第一行为attribute名称
    correlation_table_data(1, 2:end) = cellstr(filtered_attribute_names);
    
    % 保存路径规则：
    % rendered/[观察者组别类]/[目标评分百分比]/[模特编号]/[光源]/[属性编号_序号]/[L*a*b*坐标].jpg
    save_folder=fullfile('rendered',render_type,obs_type,target_score_str,lastPart);
    if ~exist(save_folder, 'dir')
        mkdir(save_folder);
    end
    fprintf('--- 正在处理模特: %s ---\n', current_model_name);
    for i_par = 1:length(pcn)
        current_pcn_name = pcn(i_par);
        
        % 获取当前光源（pcn）对应的行索引
        row_idx_in_table = i_par + 1; % +1 是因为第一行是表头
        
        for attribute_idx_in_list = 1:length(attributes_to_process)
            attribute = attributes_to_process(attribute_idx_in_list);
            current_attribute_name = attribute_names(attribute);
            attribute_serial = strcat(sprintf("%02d", attribute), current_attribute_name);
            [nation,i_nation,nation_serial]=find_nation(model); % 假设 find_nation 函数已定义
            
            labNscore_file=fullfile("D:\work\VIVOskinExpe\analyze\AnalyseResults1\" ,...
                Dtype,lastPart,obs_type,attribute_serial,"labNscore", ...
                strcat("labNscore_group",lower(lastPart),lower(current_pcn_name),".mat")); % 修改这里，lastPart应该在lower之前

            average_file = fullfile("aveSkin", lastPart, "autoNhand_scaleoverLUT.mat");
            average_data = load(average_file);
            average = average_data.average_lab_all(:, 1:3);
            lab_group = [];
            MSV_group = [];
            
            if exist(labNscore_file,'file') == 2
                load(labNscore_file,  "lab_group","MSV_group","picname_group");
            else
                fprintf('警告: 找不到文件 %s，跳过此组合。\n', labNscore_file);
                correlation_table_data{row_idx_in_table, attribute_idx_in_list + 1} = NaN; % 标记为NaN
                continue;
            end
            
            fit_center_data_file = fullfile('D:\work\VIVOskinExpe\analyze\AnalyseResults1', ...
                Dtype, 'scale_factor_fit_results', obs_type,"i", nation, model(1));
            
            full_fit_center_file = fullfile(fit_center_data_file, ...
                                    strcat("a_scale_",attribute_serial,".mat"));
            a_scale = [];
            a_CL = [];
            all_par = [];
            par = [];
            if exist(full_fit_center_file,'file') == 2
                load(full_fit_center_file, ...
                            'a_scale', "a_CL","all_ave_curr_z","all_par");
                if iOr == 'r'
                    source_folder = fullfile('D:\work\VIVOskinExpe\analyze\AnalyseResults1', ...
                        Dtype,'50',obs_type, ...
                        iOr,attribute_serial,nation_serial);
                    full_path=fullfile(source_folder,strcat(pcn(i_par),".mat"));
                    data = load(full_path);                    
                    par = get_par_fr_SF(average(i_par,1), a_scale, a_CL, data.par); 
                else
                    par = get_par_fr_SF(average(i_par,1), a_scale, a_CL, all_par{1});
                end
            end            
            y=calculate_y(lab_group(:,2),lab_group(:,3),par); % 假设 calculate_y 函数已定义

            
            % ======================================
            % 计算 y 和 MSV_group 之间的相关系数
            % ======================================
            if ~isempty(y) && ~isempty(MSV_group) && numel(y) == numel(MSV_group) && numel(y) > 1
                correlation_coefficient = corr(y, MSV_group, 'Type', 'Pearson');
                correlation_table_data{row_idx_in_table, attribute_idx_in_list + 1} = correlation_coefficient;
                % fprintf('  - 光源: %s, 属性: %s, 相关系数 = %.4f\n', current_pcn_name, current_attribute_name, correlation_coefficient);
            else
                fprintf('警告: 无法计算模特 %s, 光源 %s, 属性 %s 的相关性。原因：y或MSV_group为空或大小不匹配或数据不足。\n', ...
                        current_model_name, current_pcn_name, current_attribute_name);
                correlation_table_data{row_idx_in_table, attribute_idx_in_list + 1} = NaN; % 标记为NaN
            end
        end % end for attribute
    end % end for i_par
    numeric_data = cell2mat(correlation_table_data(2:end, 2:end));
    numeric_data(row_idx_in_table,:) = nanmean(numeric_data, 1);
    numeric_data(:,attribute_idx_in_list + 1) = nanmean(numeric_data, 2);
    result_cell=[[correlation_table_data(2:end,1);"mean"],numeric_data];
    result_cell=[[correlation_table_data(1,:),"mean"];result_cell];
    % 将当前模特的数据写入Excel的一个新Sheet
    % **修改：cell2table 的 VariableNames 参数直接使用 correlation_table_data 的第一行**
    writematrix(result_cell, ...
               excel_output_path, 'Sheet', char(current_model_name));
    fprintf('模特 %s 的相关性结果已写入Excel的Sheet: %s\n', current_model_name, current_model_name);
end % end for i_model
fprintf('\n所有相关性结果已保存到 %s\n', excel_output_path);


%%

write_mean_summary(excel_output_path, new_names, nation_indices(1:4), nations);
