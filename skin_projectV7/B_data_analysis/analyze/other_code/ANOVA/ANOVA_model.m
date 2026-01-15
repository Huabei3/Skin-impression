close all; clc; clear;
addpath("..\..\utils\")
%% 定义参数
attributes = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
attribute_names_new = ["Preference", "Attractiveness", "Feminine", "Cooperative", ...
    "Youth", "Healthy", "Fidelity", "Harmony", "Fair", "Ruddy"];
nations = ["AS", "CA", "SA", "AF"];
nation_names = ["Asian","Caucasian","South Asian","African"];
lastParts = {'f04i', 'f05i', 'f06i', 'm04i', 'm05i', 'm06i',...
'f01i', 'f02i', 'f03i', 'm01i', 'm02i', 'm03i',...
'f07i', 'f08i','m07i', 'm08i',...
'f09i', 'f10i','m09i', 'm10i'};n_para = 21;iOr='i';
% lastParts = {'f04r', 'f05r', 'f06r', 'm04r', 'm05r', 'm06r',...
% 'f01r', 'f02r', 'f03r', 'm01r', 'm02r', 'm03r',...
% 'f07r', 'f08r','m07r', 'm08r',...
% 'f09r', 'f10r','m09r', 'm10r'};n_para = 14;iOr='r';
load("..\..\documents\valid_attr.mat", "map");
wd65 = [94.811, 100.00, 107.304];
datai_file = '..\..\..\..\A_characterization\display_model\datai_ipv18_3.mat';
LUT = load(datai_file);
XYZw_LUT = LUT.XYZw;
colors = hsv(length(attributes));
obs_types = ["non_model", "model_group", "model"];
% 定义人种对应的lastParts索引
nation_indices = cell(5, 1);
nation_indices{1} = 1:6;     % AS (Asian)
nation_indices{2} = 7:12;    % CA (Caucasian)
nation_indices{3} = 13:16;   % SA (South Asian)
nation_indices{4} = 17:20;   % AF (African)
nation_indices{5} = 1:20;    % all
% 加载数据
Dtype = "efit_p";
output_folder = fullfile("..\..\ellip_pic_p", Dtype);
load(fullfile(output_folder, strcat("data_reshaped_", iOr, ".mat")), "lab_fit_reshaped");
%% 执行ANOVA检验
obs_types_to_use = ["non_model"];
% 创建存储所有结果的单元格数组
all_results_cell = {};
header_written = false;
for i_obs = 1:length(obs_types_to_use)
    obs_type = obs_types_to_use(i_obs);
    for i_nation = 1:length(nations)
        curr_nation_indices = nation_indices{i_nation};
        curr_nation_lastParts = lastParts(curr_nation_indices);
        
        % 用于存储当前人种所有属性的所有数据
        all_L_data = [];
        all_C_data = [];
        all_h_data = [];
        group_labels_num = [];
        
        % 遍历当前人种下的所有lastParts（即所有模特）
        for i_lastPart_idx = 1:length(curr_nation_lastParts)
            
            % 遍历所有属性
            for i_attr = 1:length(attributes)
                attribute = attributes(i_attr);
                
                % 提取L*, a* and b* values
                if attribute == 7
                    i_obs_used = 2;
                    continue
                else
                    i_obs_used = i_obs;
                end
                
                % 注意：i_lastPart_idx 现在是该人种内部的索引
                L_data = lab_fit_reshaped{i_obs_used, i_nation}(:, 1, i_lastPart_idx, attribute);
                a_data = lab_fit_reshaped{i_obs_used, i_nation}(:, 2, i_lastPart_idx, attribute);
                b_data = lab_fit_reshaped{i_obs_used, i_nation}(:, 3, i_lastPart_idx, attribute);
                
                % 计算C和h
                C_data = sqrt(a_data.^2 + b_data.^2);
                h_data = atan2d(b_data, a_data);
                
                % 移除NaN
                valid_indices = ~isnan(L_data) & ~isnan(C_data) & ~isnan(h_data);
                L_data = L_data(valid_indices);
                C_data = C_data(valid_indices);
                h_data = h_data(valid_indices);
                
                % 将数据添加到总数据集中，并创建分组标签
                all_L_data = [all_L_data; L_data];
                all_C_data = [all_C_data; C_data];
                all_h_data = [all_h_data; h_data];
                
                % 分组标签使用属性ID
                group_labels_num = [group_labels_num; attribute*ones(size(L_data))];
            end % End of i_attr loop
        end % End of i_lastPart_idx loop
        
        % 初始化ANOVA结果
        p_values = [1, 1, 1]; % L, C, h
        significant = [false, false, false]; % L, C, h
        
        % 执行ANOVA检验
        if length(unique(group_labels_num)) > 1 && length(group_labels_num) > length(attributes)
            % ANOVA for L*
            [p, ~, ~] = anovan(all_L_data, group_labels_num, 'display','off');
            close all force;
            p_values(1) = p;
            significant(1) = p < 0.05;
            
            % ANOVA for C
            [p, ~, ~] = anovan(all_C_data, group_labels_num, 'display','off');
            close all force;
            p_values(2) = p;
            significant(2) = p < 0.05;
            
            % ANOVA for h
            [p, ~, ~] = anovan(all_h_data, group_labels_num, 'display','off');
            close all force;
            p_values(3) = p;
            significant(3) = p < 0.05;
        end
        
        % 填充结果行
        new_row = {
            char(obs_type), ...
            char(nations(i_nation)), ...
            -1, ... % 属性ID在此处不适用
            'All_Attributes_Grouped', ... % 将所有属性作为一个整体进行分析
            p_values(1), ...
            p_values(2), ...
            p_values(3), ...
            significant(1), ...
            significant(2), ...
            significant(3), ...
            significant(1) | significant(2) | significant(3)
        };
        
        all_results_cell(end+1, :) = new_row;
    end % End of i_nation loop
end % End of i_obs loop
%% 保存最终结果到单个文件
header = {'ObserverType', 'Nation', 'AttributeID', 'AttributeName', 'PValue_L', 'PValue_C', 'PValue_h', 'Significant_L', 'Significant_C', 'Significant_h', 'Significant'};
results_with_header = [header; all_results_cell];
output_folder1 = fullfile(output_folder, "model");
if ~exist(output_folder1, "dir")
    mkdir(output_folder1);
end
xlsx_file_processed = fullfile(output_folder1, strcat(iOr, '_AllNations_AllAttributes_ANOVA_LCh.xlsx'));
xlswrite(xlsx_file_processed, results_with_header);
fprintf('All ANOVA results saved to: %s\n', xlsx_file_processed);