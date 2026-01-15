close all; clc; clear;
addpath("..\..\utils\")
%% 定义参数
attributes = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
attribute_names_new = ["Preference", "Attractiveness", "Feminine", "Cooperative", ...
    "Youth", "Healthy", "Fidelity", "Harmony", "Fair", "Ruddy"];
nations = ["AS", "CA", "SA", "AF"];
nation_names = ["Asian","Caucasian","South Asian","African"];
lastParts = {'f04r', 'f05r', 'f06r', 'm04r', 'm05r', 'm06r',...
'f01r', 'f02r', 'f03r', 'm01r', 'm02r', 'm03r',...
'f07r', 'f08r','m07r', 'm08r',...
'f09r', 'f10r','m09r', 'm10r'};n_para = 14;iOr='r';
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
obs_types_to_use = ["non_model","model_group"];
all_results_cell = {};

for i_obs = 1:length(obs_types_to_use)
    obs_type = obs_types_to_use(i_obs);

    for i_nation = 1:length(nations)
        nation_name = nation_names(i_nation);
        curr_nation_indices = nation_indices{i_nation};
        
        % 初始化一个空的单元格数组，用于存储当前人种的所有数据
        % 数据将按照i_para分组
        para_L_data = cell(n_para, 1);
        para_C_data = cell(n_para, 1);
        para_h_data = cell(n_para, 1);
        
        % 遍历当前人种下的所有lastPart和所有attribute
        for i_lastPart = 1:length(curr_nation_indices)
            for i_attr = 1:length(attributes)
                
                if attributes(i_attr) == 7
                    i_obs_used = 2;
                else
                    i_obs_used = i_obs;
                end
                
                % 提取当前lastPart和attribute的所有i_para数据
                L_data_all = squeeze(lab_fit_reshaped{i_obs_used, i_nation}(:, 1, i_lastPart, attributes(i_attr)));
                a_data_all = squeeze(lab_fit_reshaped{i_obs_used, i_nation}(:, 2, i_lastPart, attributes(i_attr)));
                b_data_all = squeeze(lab_fit_reshaped{i_obs_used, i_nation}(:, 3, i_lastPart, attributes(i_attr)));

                % 计算C和h
                C_data_all = sqrt(a_data_all.^2 + b_data_all.^2);
                h_data_all = atan2d(b_data_all, a_data_all);
                
                % 将数据按i_para分组并追加到对应的单元格中
                for i_para = 1:n_para
                    if ~isnan(L_data_all(i_para))
                        para_L_data{i_para} = [para_L_data{i_para}; L_data_all(i_para)];
                        para_C_data{i_para} = [para_C_data{i_para}; C_data_all(i_para)];
                        para_h_data{i_para} = [para_h_data{i_para}; h_data_all(i_para)];
                    end
                end
            end % End of i_attr loop
        end % End of i_lastPart loop

        % 初始化检验结果
        p_values = [1, 1, 1]; % L, C, h
        significant = [false, false, false]; % L, C, h
        
        % 准备用于ANOVA的数据
        all_L_data = vertcat(para_L_data{:});
        all_C_data = vertcat(para_C_data{:});
        all_h_data = vertcat(para_h_data{:});
        
        group_labels_num = [];
        for i_para = 1:n_para
            group_labels_num = [group_labels_num; i_para * ones(length(para_L_data{i_para}), 1)];
        end

        % 检查是否能进行ANOVA
        % 至少需要2个非空组，且总样本数大于组数
        if length(unique(group_labels_num)) > 1 && length(all_L_data) > length(unique(group_labels_num))
            
            % 执行ANOVA for L, C, h
            data_dims = {all_L_data, all_C_data, all_h_data};
            
            for i_dim = 1:3
                curr_data = data_dims{i_dim};
                [p, ~, ~] = anovan(curr_data, group_labels_num, 'display','off');
                close all force;
                p_values(i_dim) = p;
                significant(i_dim) = p < 0.05;
            end
        end

        % 填充结果数据
        new_row = {
            char(obs_type), ...
            char(nation_name), ...
            -1, ... % lastPart和attribute不再单独列出
            -1, ... % AttributeID不再单独列出
            'All_Models_and_Attributes', ...
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
header = {'ObserverType', 'Nation', 'LastPartID', 'AttributeID', 'AnalysisScope', ...
          'PValue_L', 'PValue_C', 'PValue_h', 'Significant_L', 'Significant_C', ...
          'Significant_h', 'Significant_Overall'};
results_with_header = [header; all_results_cell];
output_folder1 = fullfile(output_folder, "ANOVA","scene");
if ~exist(output_folder1, "dir")
    mkdir(output_folder1);
end
xlsx_file_processed = fullfile(output_folder1, strcat(iOr, '_Nation_Para_ANOVA_LCh.xlsx'));
xlswrite(xlsx_file_processed, results_with_header);
fprintf('All ANOVA results saved to: %s\n', xlsx_file_processed);