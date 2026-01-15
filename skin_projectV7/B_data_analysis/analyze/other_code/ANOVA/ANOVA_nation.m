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
load(fullfile(output_folder, strcat("data_reshaped_", iOr, ".mat")), "lab_fit_reshaped");
% 创建存储检验结果的单元格数组
anova_results = cell(length(obs_types), length(attributes));
%% 执行ANOVA检验
obs_types = ["non_model"];
% obs_types = ["non_model","model_group"];
for i_obs = 1:length(obs_types)
    obs_type = obs_types(i_obs);
    % for i_attr = 1
    for i_attr = 1:length(attributes)
        attribute = attributes(i_attr);
        attribute_name = attribute_names_new(attribute);
        
        % 初始化检验结果
        p_values = [1, 1, 1]; % L, C, h
        significant = [false, false, false]; % L, C, h
        group_labels = nation_names;
        
        % 提取各个人种组别的有效数据
        nation_L_data = cell(length(nations), 1);
        nation_C_data = cell(length(nations), 1);
        nation_h_data = cell(length(nations), 1);
        
        % 按人种分组收集数据
        for i_nation = 1:length(nations)
            % 获取当前人种的lastPart索引
            curr_nation_indices = nation_indices{i_nation};
            n_lastParts = length(curr_nation_indices);
            
            % 初始化当前人种的数据
            curr_nation_L = [];
            curr_nation_C = [];
            curr_nation_h = [];
            
            % 收集当前人种的所有样本数据
            for i_lastPart = 1:n_lastParts
                lastPart_idx = curr_nation_indices(i_lastPart);
                lastPart = lastParts{lastPart_idx};
                
                % 提取L*, a* and b* values and remove NaN
                % if i_attr==7
                %     i_obs_used=2;
                % else
                    i_obs_used=i_obs;
                % end
                
                L_data = lab_fit_reshaped{i_obs_used, i_nation}(:, 1, i_lastPart, attribute);
                a_data = lab_fit_reshaped{i_obs_used, i_nation}(:, 2, i_lastPart, attribute);
                b_data = lab_fit_reshaped{i_obs_used, i_nation}(:, 3, i_lastPart, attribute);
                
                % Calculate C and h
                C_data = sqrt(a_data.^2 + b_data.^2);
                h_data = atan2d(b_data, a_data);
                
                % Remove NaNs from all three L, C, h simultaneously
                valid_indices = ~isnan(L_data) & ~isnan(C_data) & ~isnan(h_data);
                
                curr_nation_L = [curr_nation_L; L_data(valid_indices)];
                curr_nation_C = [curr_nation_C; C_data(valid_indices)];
                curr_nation_h = [curr_nation_h; h_data(valid_indices)];
            end
            
            % Store current nation's data
            nation_L_data{i_nation} = curr_nation_L;
            nation_C_data{i_nation} = curr_nation_C;
            nation_h_data{i_nation} = curr_nation_h;
        end
        
        % Ensure each group has enough samples
        all_valid = true;
        for i_nation = 1:length(nations)
            if length(nation_L_data{i_nation}) < 2 || length(nation_C_data{i_nation}) < 2 || length(nation_h_data{i_nation}) < 2
                all_valid = false;
                break;
            end
        end
        
        if ~all_valid
            continue;
        end
        
        % Initialize multiple comparison results
        comp_L = [];
        comp_C = [];
        comp_h = [];
        
        % Perform ANOVA for L, C, and h
        for i_dim = 1:3 % 1 for L, 2 for C, 3 for h
            if i_dim == 1
                group_data = nation_L_data;
            elseif i_dim == 2
                group_data = nation_C_data;
            else
                group_data = nation_h_data;
            end
            
            % Combine data from all groups
            all_data = [];
            group_labels_num = [];
            
            for i_nation = 1:length(nations)
                curr_data = group_data{i_nation};
                all_data = [all_data; curr_data];
                group_labels_num = [group_labels_num; i_nation*ones(size(curr_data))];
            end
            
            % Perform one-way ANOVA
            [p, ~, stats] = anovan(all_data, group_labels_num);
            close all force;
            p_values(i_dim) = p;
            significant(i_dim) = p < 0.05;
            
            % Perform multiple comparisons (if ANOVA is significant)
            if significant(i_dim)
                if i_dim == 1
                    comp_L = multcompare(stats);
                elseif i_dim == 2
                    comp_C = multcompare(stats);
                else
                    comp_h = multcompare(stats);
                end
            end
        end
        
        % Store results
        anova_results{i_obs, i_attr} = struct( ...
            'p_value_L', p_values(1), ...
            'p_value_C', p_values(2), ...
            'p_value_h', p_values(3), ...
            'significant_L', significant(1), ...
            'significant_C', significant(2), ...
            'significant_h', significant(3), ...
            'group_labels', group_labels, ...
            'comparison_L', comp_L, ...
            'comparison_C', comp_C, ...
            'comparison_h', comp_h);
    end
    
    % ********** Collect results into a cell array **********
    results_cell = {};
    
    % Populate result data
    for i_attr = 1:length(attributes)
        attribute = attributes(i_attr);
        attribute_name = attribute_names_new(attribute);
        
        for i_nation = 1:length(nations)
            nation = nations(i_nation);
            nation_name = nation_names(i_nation);
            
            result = anova_results{i_obs, i_attr};
            results_cell{end+1, 1} = char(obs_type);
            results_cell{end, 2} = char(nation_name);
            results_cell{end, 3} = attribute;
            results_cell{end, 4} = char(attribute_name);
            
            if isempty(anova_results{i_obs, i_attr}) || ...
               ~isfield(anova_results{i_obs, i_attr}, 'p_value_L')
                
                results_cell{end, 5} = NaN;  % p_value_L
                results_cell{end, 6} = NaN;  % p_value_C
                results_cell{end, 7} = NaN;  % p_value_h
                results_cell{end, 8} = NaN;  % significant_L
                results_cell{end, 9} = NaN;  % significant_C
                results_cell{end, 10} = NaN; % significant_h
                results_cell{end, 11} = NaN; % significant (overall)
            else
                results_cell{end, 5} = result.p_value_L;
                results_cell{end, 6} = result.p_value_C;
                results_cell{end, 7} = result.p_value_h;
                results_cell{end, 8} = result.significant_L;
                results_cell{end, 9} = result.significant_C;
                results_cell{end, 10} = result.significant_h;
                results_cell{end, 11} = result.significant_L | result.significant_C | result.significant_h; % significant
            end
        end
    end
    
    % Add header
    header = {'ObserverType', 'Nation', 'AttributeID', 'AttributeName', 'PValue_L', 'PValue_C', 'PValue_h', 'Significant_L', 'Significant_C', 'Significant_h', 'Significant'};
    results_with_header = [header; results_cell];
    
    % ********** Data processing: Remove specified columns and merge nation data **********
    % Keep column indices: 4(AttributeName), 5(PValue_L), 6(PValue_C), 7(PValue_h), 8(Significant_L), 9(Significant_C), 10(Significant_h)
    keepCols = [4,5,6,7,8,9,10];
    results_processed = results_with_header(:, keepCols);
    
    % Merge nation data (every 4 rows correspond to different nations for the same attribute)
    n_attr = length(attributes);
    n_nation = length(nations);
    processed_data = cell(n_attr + 1, length(keepCols)); % +1 for header
    
    % Set new header
    new_header = {'AttributeName', 'PValue_L', 'PValue_C', 'PValue_h', 'Significant_L', 'Significant_C', 'Significant_h'};
    processed_data(1,:) = new_header; % Header occupies the first row
    
    % Merge data
    row_idx = 2;
    for i_attr = 1:n_attr
        % Extract data for all nations for the same attribute (4 rows)
        attr_data = results_processed(row_idx:row_idx+n_nation-1, :);
        
        % Verify data consistency (assuming all rows are identical for the same attribute after processing)
        is_consistent = all(cellfun(@(x) strcmp(x, attr_data(1,1)), attr_data(:,1)));
        if ~is_consistent
            warning(['Attribute ', num2str(i_attr), ' data is inconsistent, manual check might be needed.']);
        end
        
        % Extract the first row as representative (since all rows should be identical)
        processed_data(i_attr+1, :) = attr_data(1, :);
        row_idx = row_idx + n_nation;
    end
    
    % Save processed data
    output_folder1=fullfile(output_folder,"nation");
    if ~exist(output_folder1,"dir")
        mkdir(output_folder1);
    end
    xlsx_file_processed = fullfile(output_folder1, strcat(iOr, '_', obs_type, '_nation_ANOVA_LCh.xlsx'));
    xlswrite(xlsx_file_processed, processed_data);
    fprintf('Processed results saved to: %s\n', xlsx_file_processed);
end