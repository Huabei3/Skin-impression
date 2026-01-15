close all; clc; clear;
addpath("..\..\utils\")
%% 定义参数
attributes = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
attribute_names_new = ["Preference", "Attractiveness", "Feminine", "Cooperative", ...
    "Youth", "Healthy", "Fidelity", "Harmony", "Fair", "Ruddy"];
nations = ["AS", "CA", "SA", "AF"];
nation_names=["Asian","Caucasian","South Asian","African"];

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
% output_folder = fullfile("ellip_pic_p", Dtype,"ANOVA");
load(fullfile(output_folder, strcat("data_reshaped_", iOr, ".mat")), "lab_fit_reshaped");
% 创建存储检验结果的单元格数组
anova_results = cell(length(obs_types), length(nations), length(attributes));
%% 执行ANOVA检验
obs_types = ["non_model"];
for i_obs = 1:length(obs_types)
    obs_type = obs_types(i_obs);
    
    for i_nation = 1:length(nations)
        nation = nations(i_nation);
        
        % 获取当前人种的lastPart索引
        curr_nation_indices = nation_indices{i_nation};
        n_lastParts = length(curr_nation_indices);
        
        % 检查样本量
        if n_lastParts < 2
            fprintf('警告: %s 人种的lastPart数量不足，跳过检验\n', char(nation));
            continue;
        end
        
        % 计算性别分组边界
        n_female = floor(n_lastParts / 2);
        
        for i_attr = 1:length(attributes)
            attribute = attributes(i_attr);
            attribute_name = attribute_names_new(attribute);
            
            % 初始化检验结果
            p_values = [1, 1, 1]; % For L, C, h
            significant = [false, false, false];
            group_labels = {'Female', 'Male'};
            
            % 提取性别组别的有效数据
            female_L = []; female_C = []; female_h = [];
            male_L = [];   male_C = [];   male_h = [];
            
            % 按性别分组收集数据
            for i_lastPart = 1:n_lastParts
                lastPart_idx = curr_nation_indices(i_lastPart);
                lastPart = lastParts{lastPart_idx};
                
                % 提取L*, a*, b*值并去除NaN
                if i_attr==7
                    i_obs_used=2;
                    continue
                else
                    i_obs_used=i_obs;
                end
                
                L_data = lab_fit_reshaped{i_obs_used, i_nation}(:, 1, i_lastPart, attribute);
                a_data = lab_fit_reshaped{i_obs_used, i_nation}(:, 2, i_lastPart, attribute);
                b_data = lab_fit_reshaped{i_obs_used, i_nation}(:, 3, i_lastPart, attribute);
                
                % Convert a* and b* to C* and h*
                C_data = sqrt(a_data.^2 + b_data.^2);
                h_data = atan2d(b_data, a_data);
                
                % Ensure h is within [0, 360)
                h_data(h_data < 0) = h_data(h_data < 0) + 360;
                
                % Filter out NaNs across all three dimensions simultaneously
                valid_indices = ~isnan(L_data) & ~isnan(C_data) & ~isnan(h_data);
                
                valid_L = L_data(valid_indices);
                valid_C = C_data(valid_indices);
                valid_h = h_data(valid_indices);
                
                % 按性别分组
                if i_lastPart <= n_female
                    female_L = [female_L; valid_L];
                    female_C = [female_C; valid_C];
                    female_h = [female_h; valid_h];
                else
                    male_L = [male_L; valid_L];
                    male_C = [male_C; valid_C];
                    male_h = [male_h; valid_h];
                end
            end
            
            % 确保每组有足够样本
            if length(female_L) < 2 || length(male_L) < 2
                continue;
            end
            
            % 执行ANOVA检验 (L, C, h)
            dimensions = {'L', 'C', 'h'};
            for i_dim = 1:3
                if i_dim == 1 % L*
                    group1 = female_L;
                    group2 = male_L;
                elseif i_dim == 2 % C*
                    group1 = female_C;
                    group2 = male_C;
                else % h*
                    group1 = female_h;
                    group2 = male_h;
                end
                
                [p, ~, ~] = anovan([group1; group2], [ones(size(group1)); 2*ones(size(group2))]);
                close all force;
                p_values(i_dim) = p;
                significant(i_dim) = p < 0.05;
                if isempty(group1)||isempty(group2)
                    significant(i_dim) = nan;
                end
            end
            
            % 存储检验结果
            anova_results{i_obs, i_nation, i_attr} = struct( ...
                'p_value_L', p_values(1), ...
                'p_value_C', p_values(2), ...
                'p_value_h', p_values(3), ...
                'significant_L', significant(1), ...
                'significant_C', significant(2), ...
                'significant_h', significant(3), ...
                'group_labels', {group_labels});
        end
        
        % 显示进度
        fprintf('完成检验: %s, %s (属性: %d/%d)\n', ...
                char(obs_type), char(nation), i_attr, length(attributes));
    end
    
    % ********** 使用cell数组收集结果 **********
    results_cell = {};
    
    % 填充结果数据
    for i_nation = 1:length(nations)
        nation = nations(i_nation);
        nation_name=nation_names(i_nation);
        for i_attr = 1:length(attributes)
            attribute = attributes(i_attr);
            attribute_name = attribute_names_new(attribute);
            
            result = anova_results{i_obs, i_nation, i_attr};
            results_cell{end+1, 1} = char(obs_type);
            results_cell{end, 2} = char(nation_name);
            results_cell{end, 3} = attribute;
            results_cell{end, 4} = char(attribute_name);
            if isempty(anova_results{i_obs, i_nation, i_attr}) || ...
               ~isfield(anova_results{i_obs, i_nation, i_attr}, 'p_value_L')
                results_cell{end, 5} = NaN;  % p_value_L
                results_cell{end, 6} = NaN;  % p_value_C
                results_cell{end, 7} = NaN;  % p_value_h
                results_cell{end, 8} = NaN; % significant_L
                results_cell{end, 9} = NaN; % significant_C
                results_cell{end, 10} = NaN; % significant_h
                results_cell{end, 11} = NaN; % significant
            else
                results_cell{end, 5} = result.p_value_L;
                results_cell{end, 6} = result.p_value_C;
                results_cell{end, 7} = result.p_value_h;
                results_cell{end, 8} = result.significant_L;
                results_cell{end, 9} = result.significant_C;
                results_cell{end, 10} = result.significant_h;
                results_cell{end, 11} = result.significant_L | result.significant_C | result.significant_h; % significant if any dimension is significant
            end
        end
    end
    
    % 添加表头
    header = {'ObserverType', 'Nation', 'AttributeID', 'AttributeName', 'PValue_L', 'PValue_C', 'PValue_h', 'Significant_L', 'Significant_C', 'Significant_h', 'Significant_any'};
    results_with_header = [header; results_cell];
    
    
    % 保存为Excel文件
    xlsx_file = fullfile(output_folder, strcat(iOr, '_', obs_type, '_gender_ANOVA_LCh.xlsx'));
    xlswrite(xlsx_file, results_with_header);
    fprintf('结果已保存至: %s\n', xlsx_file);
end