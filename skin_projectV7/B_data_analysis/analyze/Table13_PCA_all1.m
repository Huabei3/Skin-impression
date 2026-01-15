close all; % 关闭所有图窗
clc;       % 清空命令窗口
clear;     % 清除工作区所有变量
%% 定义所有需要处理的 attribute
attributes = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
attribute_names_new = ["Preference", "Attractiveness", "Feminine", "Cooperative", ...
    "Youth", "Healthy", "Fidelity","Harmony", "Fair", "Ruddy"];
% Define lastParts and picname_group for 'i' and 'r' separately
lastParts_i = {'f04i', 'f05i', 'f06i', 'm04i', 'm05i', 'm06i',...
'f01i', 'f02i', 'f03i', 'm01i', 'm02i', 'm03i',...
'f07i', 'f08i','m07i', 'm08i',...
'f09i', 'f10i','m09i', 'm10i'};
picname_group_i = ["h3k", "h4k", "h5k", "h6k", "hd65", "h7k", "h8k",...
"m3k", "m4k", "m5k", "m6k", "md65", "m7k", "m8k",...
 "l3k", "l4k", "l5k", "l6k", "ld65", "l7k", "l8k"];
lastParts_r = {'f04r', 'f05r', 'f06r', 'm04r', 'm05r', 'm06r', ...
'f01r', 'f02r', 'f03r', 'm01r', 'm02r', 'm03r', ...
'f07r', 'f08r','m07r', 'm08r', ...
'f09r', 'f10r','m09r', 'm10r'};
picname_group_r = ["rs01","rs02","rs03","rs04","rs05","rs06","rs07", ...
                 "rs08","rs09","rs10","rs11","rs12","rs13","rs14"];
% --- 修改点 1: 增加 "all" nation ---
nations = ["AS","CA","SA","AF", "all"]; % 增加 "all"
nations_new=["Asian","Caucasian","South Asian","African", "All Nations"]; % 增加对应的显示名称
% Define nation indices for both 'i' and 'r' based on the combined lastParts
nation_indices_i = cell(5, 1);
nation_indices_i{1} = 1:6;   % AS
nation_indices_i{2} = 7:12;  % CA
nation_indices_i{3} = 13:16; % SA
nation_indices_i{4} = 17:20; % AF
nation_indices_i{5} = 1:20;  % all
nation_indices_r = cell(5, 1);
nation_indices_r{1} = 1:6;   % AS
nation_indices_r{2} = 7:12;  % CA
nation_indices_r{3} = 13:16; % SA
nation_indices_r{4} = 17:20; % AF
nation_indices_r{5} = 1:20;  % all
Dtype = 'efit_p';

if strcmp(Dtype,"efit_p_free")
    AnalyseResults_folder="AnalyseResults_p_free";
elseif strcmp(Dtype,"efit_p")
    AnalyseResults_folder="AnalyseResults_p";
end

scale_type_origin="unscaled";
obs_types = ["non_model"];
% obs_types = ["non_model", "model_group", "model"];
for i_obs = 1:length(obs_types)
    obs_type = obs_types(i_obs);
    save_folder = fullfile(AnalyseResults_folder, Dtype,scale_type_origin, "sum_list");
    
    % 创建保存文件夹
    if ~exist(save_folder, "dir")
        mkdir(save_folder);
    end
    
    %% 初始化用于存储PCA结果的变量
    pca_results = cell(length(nations), 1);
    pcn_nations = cell(length(nations), 1); % To store max_attribute for each PC
    %% 循环处理每个 nation
    for i_nation = 1:length(nations)
        % Get current nation indices for both 'i' and 'r'
        current_nation_indices_i = nation_indices_i{i_nation};
        current_nation_indices_r = nation_indices_r{i_nation};
        
        % Initialize y for storing combined 'i' and 'r' data
        y = cell(length(attributes), 1);
        
        for attribute = attributes
            attribute_serial = strcat(sprintf("%02d", attribute), attribute_names_new(attribute));
            if attribute == 7
                obs_type_used = "model_group";
            else
                obs_type_used = obs_type;
            end
            
            y_i = []; % Data for 'i' images
            y_r = []; % Data for 'r' images
            % Load data for 'i' images
            for i_lastPart_i = current_nation_indices_i
                lastPart = lastParts_i{i_lastPart_i};
                lastPart = strrep(lastPart, "add", "");              
                for i_para = 1:length(picname_group_i)

                    labNgroup_file = fullfile(AnalyseResults_folder, Dtype,scale_type_origin, lastPart, obs_type_used, ...
                        attribute_serial, "labNscore", ...
                        strcat("labNscore_group", lastPart, picname_group_i(i_para), ".mat"));
                    if exist(labNgroup_file, 'file')
                        pNlab = load(labNgroup_file);
                        y_temp = pNlab.p_group;  
                    else
                        y_temp = NaN([33,1]);
                    end
                    y_i = [y_i; y_temp];
                end
            end
            % Load data for 'r' images
            for i_lastPart_r = current_nation_indices_r
                lastPart = lastParts_r{i_lastPart_r};
                lastPart = strrep(lastPart, "add", "");              
                for i_para = 1:length(picname_group_r)
                    labNgroup_file = fullfile(AnalyseResults_folder, Dtype, scale_type_origin,lastPart, obs_type_used, ...
                        attribute_serial, "labNscore", ...
                        strcat("labNscore_group", lastPart, picname_group_r(i_para), ".mat"));
                    if exist(labNgroup_file, 'file')
                        pNlab = load(labNgroup_file);
                        y_temp = pNlab.p_group;  
                    else
                        y_temp = NaN([33,1]);
                        disp(strcat("no such file:",labNgroup_file));
                    end
                    y_r = [y_r; y_temp];
                end
            end
            
            % Vertically concatenate 'i' and 'r' results for the current attribute
            y{attribute} = [y_i; y_r];
        end
        
        % PCA分析：以十个y{attribute}为十个维度
        % 构建10维数据矩阵
        data_matrix = []; pcn = [];
        for attribute = 1:length(attributes)
            if ~isempty(y{attribute})
                data_matrix = [data_matrix, y{attribute}];
            else
                % 如果某个属性的数据为空，则填充NaN
                % Ensure size consistency - use the size of the first non-empty attribute
                if ~isempty(y{find(~cellfun('isempty', y), 1)})
                    data_matrix = [data_matrix, NaN(size(y{find(~cellfun('isempty', y), 1)}))];
                else
                    data_matrix = [data_matrix, NaN(size(y{1}))]; % Fallback if all are empty initially
                end
            end
            attribute_serial = strcat(sprintf("%02d", attribute), attribute_names_new(attribute));
            pcn = [pcn; attribute_serial];
        end
        
        % 检查数据有效性
        if ~isempty(data_matrix) && size(data_matrix, 2) == length(attributes)
            
            % 计算每列NaN值的比例，删除超过1/5的列
            col_nan_ratio = mean(isnan(data_matrix), 1);
            valid_cols = col_nan_ratio <= 1/5;
            valid_data = data_matrix(:, valid_cols);
            
            % 计算每行NaN值的比例，删除超过1/5的行
            row_nan_ratio = mean(isnan(valid_data), 2);
            valid_rows = row_nan_ratio <= 1/5;
            valid_data = valid_data(valid_rows, :);
            
            % 统计并显示删除后仍存在缺失值的行数和列数
            nan_rows = sum(any(isnan(valid_data), 2));
            nan_cols = sum(any(isnan(valid_data), 1));
            disp(['删除后仍存在缺失值的行数: ', num2str(nan_rows)]);
            disp(['删除后仍存在缺失值的列数: ', num2str(nan_cols)]);
            
            % 对剩余缺失值进行插值处理
            valid_data = fillmissing(valid_data, 'nearest');
            pcn_valid = pcn(valid_cols, :); % Store valid PC names
            
            % 仅当有足够的有效数据时进行PCA
            if size(valid_data, 1) > size(valid_data, 2) && size(valid_data, 2) > 1 % Need more observations than variables, and more than 1 variable
                % 执行PCA
                [coeff, score, latent, ~, explained] = pca(valid_data);
                % 存储PCA结果
                pca_results{i_nation} = struct(...
                    'coeff', coeff, ...
                    'score', score, ...
                    'latent', latent, ...
                    'explained', explained, ...
                    'data', valid_data, ...
                    'pcn_valid', pcn_valid); 
                
                % New field: record attribute_serial with the largest proportion of principal components
                [~, maxPC_idx] = max(abs(coeff), [], 1); 
                max_attribute = pcn_valid(maxPC_idx); 
                pcn_nations{i_nation}=pcn_valid(maxPC_idx); 
                
                % Add a new column to pca_results to save the attribute_serial of the largest principal component
                pca_results{i_nation}.max_attribute = max_attribute;
                
                % PCA result visualization
                figure('Position', [100, 100, 1200, 500]);
                % Scatter plot of the first and second principal components
                % subplot(1, 2, 1);
                h1=figure(1);hold on;
                scatter(score(:,1), score(:,2), 30, 'filled');
                title(sprintf('PCA Results: %s (Combined i and r)', nations_new(i_nation)));
                xlabel(['Principal Component 1 (', num2str(explained(1), '%.1f'), '%)']);
                ylabel(['Principal Component 2 (', num2str(explained(2), '%.1f'), '%)']);
                grid on;
                close(gcf);
                
                % Explained variance ratio plot
                % subplot(1, 2, 2);
                h2=figure(2);hold on;
                bar(1:length(explained), explained);
                title('Explained Variance Ratio of Each Principal Component');
                xlabel('Principal Component');
                ylabel('Explained Variance Ratio (%)');
                xticks(1:length(explained));
                grid on;
                
                % Save PCA result image
                pca_img_folder = fullfile(save_folder, 'PCA_images',obs_type);
                if ~exist(pca_img_folder, 'dir')
                    mkdir(pca_img_folder);
                end
                saveas(h2, fullfile(pca_img_folder, sprintf('PCA_%s_combined.jpg', nations(i_nation))));
                close(gcf);
            else
                fprintf('Skipping PCA for %s (Combined i and r) due to insufficient valid data.\n', nations_new(i_nation));
            end
        else
            fprintf('Skipping PCA for %s (Combined i and r) due to empty or incomplete data matrix.\n', nations_new(i_nation));
        end
    end
    
    %% Save PCA results
    pca_save_folder = fullfile(save_folder, 'PCA_results',obs_type);
    if ~exist(pca_save_folder, 'dir')
        mkdir(pca_save_folder);
    end
    
    % Save all PCA results to a mat file
    save(fullfile(pca_save_folder, 'all_pca_results_combined.mat'), 'pca_results');
    
    % Create PCA results summary table
    max_pcs = 0;
    for i_nation = 1:length(pca_results)
        if ~isempty(pca_results{i_nation})
            max_pcs = max(max_pcs, length(pca_results{i_nation}.explained));
        end
    end
    % Initialize pca_summary table
    pca_summary = cell(length(nations) + 1, 2 * max_pcs + 1);
    
    % Set table header
    header = {'Nation'};
    for i_pc = 1:max_pcs
        header = [header, {sprintf('PC%d_Explained', i_pc), sprintf('PC%d_Max_Attribute', i_pc)}];
    end
    pca_summary(1, :) = header;
    
    idx = 2;
    for i_nation = 1:length(nations)
        if ~isempty(pca_results{i_nation})
            pca_data = pca_results{i_nation};
            row = {nations_new(i_nation)};
            
            num_pcs_current = length(pca_data.explained);
            
            for i_pc = 1:max_pcs
                if i_pc <= num_pcs_current
                    row = [row, pca_data.explained(i_pc), pca_data.max_attribute{i_pc}];
                else
                    row = [row, NaN, 'NaN'];
                end
            end
            pca_summary(idx, :) = row;
            idx = idx + 1;
        end
    end
    
    % Save PCA result summary table
    writecell(pca_summary, fullfile(pca_save_folder, strcat('combined_i_r_', obs_type, '_pca_summary.csv')));
    disp("Processing complete.");
    
    %% Save max_attribute, explained data, and coeff for each nation to different worksheets
    pca_summary_file = fullfile(pca_save_folder, strcat('combined_i_r_', obs_type, '_pca_summary.xlsx'));
    coeff_file = fullfile(pca_save_folder, strcat('combined_i_r_', obs_type, '_pca_coeff.xlsx')); 
    
    for i_nation = 1:length(nations)
        if ~isempty(pca_results{i_nation})
            pca_data = pca_results{i_nation};
            pcn_valid = pca_data.pcn_valid; 
            explained = pca_data.explained;
            coeff = pca_data.coeff; 
            
            % --- 修改这部分代码：创建包含explained和max_attribute的表格 ---
            % 创建主成分的名称，例如 "PC1", "PC2", ...
            pc_names = arrayfun(@(x) sprintf('PC%d', x), 1:length(explained), 'UniformOutput', false);
            % 创建表格，第一列是PC名称，第二列是ExplainedVariance，第三列是MaxAttribute
            max_attribute_table = table(pc_names(:), explained(:), pca_data.max_attribute(:), ...
                                        'VariableNames', {'PrincipalComponent', 'ExplainedVariance', 'MaxLoadingAttribute'});
    
            % 写入到对应的工作表中
            sheet_name = nations(i_nation);
            writetable(max_attribute_table, pca_summary_file, 'Sheet', sheet_name);
            % --- 保存 coeff 矩阵到单独的 Excel 文件，并添加占比最大的属性 ---
            if ~isempty(coeff)
                % 创建 coeff 表格的列头 (PC1, PC2...)
                pc_headers = arrayfun(@(x) sprintf('PC%d', x), 1:size(coeff, 2), 'UniformOutput', false);
                
                % 获取每个PC中载荷绝对值最大的属性的索引
                [~, max_coeff_row_idx] = max(abs(coeff), [], 1); 
                
                % 获取对应的 pcn
                max_loading_pcn = pcn_valid(max_coeff_row_idx);
                
                % 将 pcn_valid 转换为 cell 数组，以便和 coeff 拼接
                coeff_table_data = [cellstr(pcn_valid), num2cell(coeff)];
                
                % 创建表头：第一个是空，然后是 PC 名称
                coeff_table_headers = [{' '}, pc_headers];
                
                % 创建新的行，用于存放占比最大的pcn
                % 第一列为标签，后续为对应的 pcn 字符串
                max_pcn_row = [{'Max Loading Attribute'}, cellstr(max_loading_pcn)']; % 转置 max_loading_pcn 使其成为一行
                
                % --- 新增：创建一行，用于存放 Explained Variance ---
                explained_row = [{'Explained Variance (%)'}, num2cell(explained')];
                
                % 将表头、Explained Variance、数据和新增的行合并
                coeff_output_data = [coeff_table_headers; explained_row; coeff_table_data; max_pcn_row];

                % 写入到 coeff_file 的对应工作表
                writecell(coeff_output_data, coeff_file, 'Sheet', sheet_name);
            end
        end
    end
end