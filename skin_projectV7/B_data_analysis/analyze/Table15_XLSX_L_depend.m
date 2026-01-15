% 1. 设置路径和属性名
source_folder = 'D:\work\VIVOskinExpe\analyze\AnalyseResults_p\efit_p\unscaled\model_fullpara\i\non_model'; % 您的.mat文件所在的文件夹
attribute_names_new = ["Preference", "Attractiveness", "Feminine", "Cooperative", ...
    "Youth", "Healthy", "Fidelity", "Harmony", "Fair", "Ruddy"];

% 2. 指定输出的Excel文件名
output_excel_file = 'D:\work\VIVOskinExpe\analyze\AnalyseResults_p\efit_p\unscaled\model_fullpara\i\aggregated_data.xlsx';

% 检查输出文件是否已存在，如果存在则删除
if exist(output_excel_file, 'file')
    delete(output_excel_file);
end

% 定义行标签，与您图片中的格式一致
row_labels = ["Asian"; "Caucasian"; "South Asian"; "African"];

% 3. 循环处理每个属性
for i_attr = 1:length(attribute_names_new)
    % 4. 构建并加载.mat文件
    file_name = strcat(sprintf("%02d",i_attr),attribute_names_new(i_attr), "_all_curve_params.mat");
    file_path = fullfile(source_folder, file_name);

    % 检查文件是否存在
    if ~exist(file_path, 'file')
        fprintf('警告: 文件 %s 未找到，跳过此属性。\n', file_path);
        continue;
    end

    load(file_path);

    % 5. 构建数据表
    % 定义变量名，与.mat文件中的变量名一致
    param_vars = {'a_CL_all', 'a_long_axis_all', 'a_short_axis_all', ...
                  'a_hue_angle_all', 'a_theta_all', 'a_alpha_all'};
    rmse_vars = {'rmse_CL_all', 'rmse_long_axis_all', 'rmse_short_axis_all', ...
                 'rmse_hue_angle_all', 'rmse_theta_all', 'rmse_alpha_all'};
    table_headers = {'C*', 'long_axis', 'short_axis', 'h', 'theta', 'alpha'};
    % --- 对 a_theta_all 进行修改 ---
    % 将 a_theta_all 的第二列值加上90
    a_theta_all(:, 2) = a_theta_all(:, 2) + 90;
    % 将结果调整到 [0, 180) 范围内
    a_theta_all(:, 2) = mod(a_theta_all(:, 2), 180);
    % --- 结束修改 ---
    
    % 创建一个单元格数组来存储所有表格数据
    all_tables = cell(1, length(param_vars));
    
    % 遍历每个参数类型，构建子表格
    for i_param = 1:length(param_vars)
        param_data = eval(param_vars{i_param});
        rmse_data = eval(rmse_vars{i_param});
        
        % 动态生成列名，例如 a_1, a_2, ..., a_n
        num_cols = size(param_data, 2);
        param_cols = cell(1, num_cols);
        for i_col = 1:num_cols
            param_cols{i_col} = ['a_' num2str(i_col)];
        end
        
        % 构建当前参数的表格
        sub_table_data = [cellstr(row_labels), num2cell(param_data), num2cell(rmse_data)];
        sub_table_col_names = [{' '}, param_cols, {'MAPE'}]; % 第一个单元格为空，用于对齐
        
        % 将数据转换为 MATLAB table
        current_table = cell2table(sub_table_data, 'VariableNames', sub_table_col_names);
        % 插入一个空行和标题行，用于分隔不同的参数
        % 这部分需要特别处理，因为writetable不能直接写入多个表头
        % 这里我们将每个小表格作为一个整体来处理
        
        % 使用单元格数组存储，以便后续写入
        num_cols = size(current_table, 2);
        title_row = cell(1, num_cols);
        title_row{1} = table_headers{i_param};
        
        all_tables{i_param} = [title_row; ...
            cell(1, num_cols); ...
            current_table.Properties.VariableNames; ...
            table2cell(current_table)];
    end
    
    % 6. 将所有子表格合并为一个大的单元格数组，并解决列数不一致的问题
    final_cell_array = [];
    max_cols = 6; % 定义最大列数，因为long_axis和short_axis有4个a_*参数，加上行标签和MAPE共6列
    
    for i = 1:length(all_tables)
        current_table_data = all_tables{i};
        current_cols = size(current_table_data, 2);
        
        % 如果当前表格列数小于最大列数，用空单元格填充
        if current_cols < max_cols
            padding = cell(size(current_table_data, 1), max_cols - current_cols);
            current_table_data = [current_table_data, padding];
        end
        
        final_cell_array = [final_cell_array; current_table_data];
        
        % 在每个表格之间插入空行
        if i < length(all_tables)
            final_cell_array = [final_cell_array; cell(2, max_cols)];
        end
    end

    % 6. 写入Excel工作表
    sheet_name = char(attribute_names_new(i_attr));
    % writematrix(final_cell_array, output_excel_file, 'Sheet', sheet_name);
    writecell(final_cell_array, output_excel_file, 'Sheet', sheet_name);
    
    fprintf('已成功处理并写入工作表: %s\n', sheet_name);
end

fprintf('\n所有属性数据已成功整合到 %s。\n', output_excel_file);