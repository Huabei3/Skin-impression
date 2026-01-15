close all; clc; clear;
addpath("..\..\utils\")
addpath("..\..\")
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
nation_indices{1} = 1:6;      % AS (Asian)
nation_indices{2} = 7:12;     % CA (Caucasian)  
nation_indices{3} = 13:16;    % SA (South Asian)
nation_indices{4} = 17:20;    % AF (African)
nation_indices{5} = 1:20;     % all
% 加载数据
Dtype = "efit_p";
output_folder = fullfile("..\..\ellip_pic_p", Dtype);
load(fullfile(output_folder, strcat("data_unscaled_reshaped_", iOr, ".mat")), "lab_fit_reshaped");
% 创建存储检验结果的单元格数组
% Now anova_results will store results for each nation and observer type
anova_results = cell(length(nations), length(obs_types)); 
%% 执行ANOVA检验 (Changed to group by Attribute within each Nation)
obs_types_for_loop = ["non_model","model_group"]; % Limit observer types for this analysis
for i_nation = 1:length(nations) % Outer loop: Iterate through nations
    nation = nations(i_nation);
    nation_name = nation_names(i_nation);
    curr_nation_lastParts_indices = nation_indices{i_nation}; % This is used to get the actual lastPart string

    for i_obs = 1:length(obs_types_for_loop) % Inner loop: Iterate through observer types
        obs_type = obs_types_for_loop(i_obs);
        
        % Initialize p_values and significant flags for L, C, h
        p_values = [1, 1, 1]; 
        significant = [false, false, false]; 
        group_labels = attribute_names_new; % Groups are now attributes

        % Extract valid data for the current nation and observer type, grouped by attribute
        attr_L_data = cell(length(attributes), 1);
        attr_C_data = cell(length(attributes), 1);
        attr_h_data = cell(length(attributes), 1);

        % Collect data for all attributes within the current nation and observer type
        for i_attr = 1:length(attributes)
            attribute = attributes(i_attr);
            
            % Initialize current attribute's data
            curr_attr_L = [];
            curr_attr_C = [];
            curr_attr_h = [];

            % Loop through the *internal* indices for the third dimension of lab_fit_reshaped
            % which corresponds to the lastParts for the CURRENT nation
            for j_lastPart_internal_idx = 1:length(curr_nation_lastParts_indices) 
                % lastPart_global_idx = curr_nation_lastParts_indices(j_lastPart_internal_idx); % This variable is not directly used for indexing lab_fit_reshaped
                
                % Determine which observation data to use based on attribute 7 condition
                i_obs_used = i_obs; % Default to current observer type index
                if attribute == 7
                    % Note: If attribute is 7, original code used i_obs_used=2 (model_group).
                    % If "model_group" is always the 2nd element in obs_types, this is fine.
                    % Otherwise, ensure i_obs_used points to the correct index for "model_group".
                    % Assuming obs_types_for_loop = ["non_model", "model_group"] means 2 is model_group.
                    i_obs_used_idx_in_full_list = find(strcmp(obs_types, "model_group"));
                    if ~isempty(i_obs_used_idx_in_full_list)
                        i_obs_used = i_obs_used_idx_in_full_list;
                    else
                        warning('Model group not found in full obs_types list for attribute 7 adjustment.');
                    end
                end

                % CORRECTED LINE: Use j_lastPart_internal_idx for the third dimension
                L_data_temp = lab_fit_reshaped{i_obs_used, i_nation}(:, 1, j_lastPart_internal_idx, attribute);
                a_data_temp = lab_fit_reshaped{i_obs_used, i_nation}(:, 2, j_lastPart_internal_idx, attribute);
                b_data_temp = lab_fit_reshaped{i_obs_used, i_nation}(:, 3, j_lastPart_internal_idx, attribute);
                
                C_data_temp = sqrt(a_data_temp.^2 + b_data_temp.^2);
                h_data_temp = atan2d(b_data_temp, a_data_temp);

                valid_indices = ~isnan(L_data_temp) & ~isnan(C_data_temp) & ~isnan(h_data_temp);
                
                curr_attr_L = [curr_attr_L; L_data_temp(valid_indices)];
                curr_attr_C = [curr_attr_C; C_data_temp(valid_indices)];
                curr_attr_h = [curr_attr_h; h_data_temp(valid_indices)];
            end
            
            attr_L_data{i_attr} = curr_attr_L;
            attr_C_data{i_attr} = curr_attr_C;
            attr_h_data{i_attr} = curr_attr_h;
        end

        % Ensure each attribute group has enough samples for ANOVA
        all_valid_for_anova = true;
        for i_attr = 1:length(attributes)
            if length(attr_L_data{i_attr}) < 2 || length(attr_C_data{i_attr}) < 2 || length(attr_h_data{i_attr}) < 2
                all_valid_for_anova = false;
                break;
            end
        end
        
        if ~all_valid_for_anova
            % Store empty result or skip if not enough data for ANOVA
            anova_results{i_nation, i_obs} = struct( ...
                'p_value_L', NaN, 'p_value_C', NaN, 'p_value_h', NaN, ...
                'significant_L', false, 'significant_C', false, 'significant_h', false, ...
                'group_labels', attribute_names_new, ...
                'comparison_L', [], 'comparison_C', [], 'comparison_h', []);
            continue; 
        end

        % Initialize multiple comparison results
        comp_L = [];
        comp_C = [];
        comp_h = [];
        
        % Perform ANOVA for L, C, and h
        for i_dim = 1:3 % 1 for L, 2 for C, 3 for h
            if i_dim == 1
                group_data = attr_L_data;
            elseif i_dim == 2
                group_data = attr_C_data;
            else
                group_data = attr_h_data;
            end
            
            % Combine data from all groups (attributes)
            all_data = [];
            group_labels_num = [];
            
            for i_attr_group = 1:length(attributes) % Renamed i_attr to avoid conflict with outer loop
                curr_data = group_data{i_attr_group};
                all_data = [all_data; curr_data];
                group_labels_num = [group_labels_num; i_attr_group*ones(size(curr_data))];
            end
            
            % Perform one-way ANOVA
            % FIX: Wrap group_labels_num in a cell array for anovan
            [p, ~, stats] = anovan(all_data, {group_labels_num}); % 'off' to suppress display
            close all force; % Close the ANOVA figure
            
            p_values(i_dim) = p;
            significant(i_dim) = p < 0.05;
            
            % Perform multiple comparisons (if ANOVA is significant)
            if significant(i_dim)
                % It's good practice to close figures generated by multcompare if not needed
                if i_dim == 1
                    comp_L = multcompare(stats, 'Display', 'off');
                elseif i_dim == 2
                    comp_C = multcompare(stats, 'Display', 'off');
                else
                    comp_h = multcompare(stats, 'Display', 'off');
                end
                close all force; % Close multcompare figure
            end
        end
        
        % Store results for current nation and observer type
        anova_results{i_nation, i_obs} = struct( ...
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
end

% ********** Collect results into a cell array for Excel export **********
results_cell = {};

% Populate result data
for i_nation = 1:length(nations)
    nation_name = nation_names(i_nation);
    
    for i_obs = 1:length(obs_types_for_loop)
        obs_type = obs_types_for_loop(i_obs);
        
        result = anova_results{i_nation, i_obs};
        
        results_cell{end+1, 1} = char(nation_name);
        results_cell{end, 2} = char(obs_type);
        
        if isempty(result) || ~isfield(result, 'p_value_L')
            results_cell{end, 3} = NaN;  % p_value_L
            results_cell{end, 4} = NaN;  % p_value_C
            results_cell{end, 5} = NaN;  % p_value_h
            results_cell{end, 6} = NaN;  % significant_L
            results_cell{end, 7} = NaN;  % significant_C
            results_cell{end, 8} = NaN;  % significant_h
            results_cell{end, 9} = NaN;  % significant (overall)
        else
            results_cell{end, 3} = result.p_value_L;
            results_cell{end, 4} = result.p_value_C;
            results_cell{end, 5} = result.p_value_h;
            results_cell{end, 6} = result.significant_L;
            results_cell{end, 7} = result.significant_C;
            results_cell{end, 8} = result.significant_h;
            results_cell{end, 9} = result.significant_L || result.significant_C || result.significant_h; % significant overall
        end
    end
end

% Add header
header = {'Nation', 'ObserverType', 'PValue_L', 'PValue_C', 'PValue_h', ...
          'Significant_L', 'Significant_C', 'Significant_h', 'Significant_Overall'};
results_with_header = [header; results_cell];

% ********** Save processed data **********
output_folder_attr = fullfile(output_folder, "attribute");
if ~exist(output_folder_attr, "dir")
    mkdir(output_folder_attr);
end

xlsx_file_processed_attr = fullfile(output_folder_attr, strcat(iOr, '_attribute_ANOVA_LCh.xlsx'));
xlswrite(xlsx_file_processed_attr, results_with_header);
fprintf('Processed results saved to: %s\n', xlsx_file_processed_attr);