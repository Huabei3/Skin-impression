%% generate_parameters_table.m
% 从 *_all_curve_params.mat 提取参数，按草稿5.3.xlsx格式生成xlsx
% 10个attribute各一个sheet，输出到 parameters_table/ 子目录
%
% 格式：
%   列 B-F: 亚洲人 / 高加索人 / 南亚人 / 非洲人 / 混合人种
%   行: 分6个区块 (C* / 长轴长 / 短轴长 / hab / θ / α)
%   hab/θ/α 分区只列一行"平均值"（a1），C*/长轴长/短轴长列完整参数+指标
%   θ显示值 = raw + 90 - 360（即 raw - 270）

clear; clc;

%% 路径配置
script_dir = fileparts(mfilename('fullpath'));
% mat文件所在目录（与脚本不在同一目录时请修改下面一行）
mat_dir = 'D:\work\VIVOskinExpe\analyze\AnalyseResults_p\efit_p\unscaled\model_fullpara\d65\new\i\non_model';
% 输出xlsx目录
out_dir  = fullfile(mat_dir, 'parameters_table');
if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end
out_path = fullfile(out_dir, 'all_parameters.xlsx');

%% 配置
nations = {'亚洲人', '高加索人', '南亚人', '非洲人', '混合人种'};
n_nation = numel(nations);

attr_names = {'Preference', 'Attractiveness', 'Feminine', 'Cooperative', ...
              'Youth', 'Healthy', 'Fidelity', 'Harmony', 'Fair', 'Ruddy'};

% 各区块定义: {区块标题, mat变量名(拟合参数), mat变量名(r), mat变量名(rmse), 子参数标签, 是否只取平均值}
sections = {
    {'C*',     'a_CL_all',       'r_CL_all',       'rmse_CL_all',       {'a1','a2'},             false};
    {'长轴长', 'a_long_axis_all', 'r_long_axis_all', 'rmse_long_axis_all', {'a1','a2','a3','a4'}, false};
    {'短轴长', 'a_short_axis_all','r_short_axis_all','rmse_short_axis_all',{'a1','a2','a3','a4'}, false};
    {'α',   'a_alpha_all',    'r_alpha_all',    'rmse_alpha_all',    {'a1','a2'},             true};
    {'hab',    'a_hue_angle_all','r_hue_angle_all','rmse_hue_angle_all',{'a1','a2'},             true};
    {'θ',    'a_theta_all',    'r_theta_all',    'rmse_theta_all',    {'a1','a2'},             true};
};

%% 第一遍：用writecell逐sheet写入数据
for ai = 1:10
    if ai < 10
        mat_fn = sprintf('0%d%s_all_curve_params.mat', ai, attr_names{ai});
    else
        mat_fn = sprintf('%d%s_all_curve_params.mat', ai, attr_names{ai});
    end
    mat_path = fullfile(mat_dir, mat_fn);
    
    if ~exist(mat_path, 'file')
        fprintf('[WARN] %s not found, skipping.\n', mat_fn);
        continue;
    end
    
    fprintf('Processing %s ...\n', mat_fn);
    data = load(mat_path);
    
    % 构造数据
    data_mat = {};
    data_mat = [data_mat; {''} nations(:)'];
    
    for si = 1:length(sections)
        sec = sections{si};
        sec_title    = sec{1};
        a_var        = sec{2};
        r_var        = sec{3};
        rmse_var     = sec{4};
        param_labels = sec{5};
        avg_only     = sec{6};
        
        data_mat = [data_mat; {sec_title, NaN, NaN, NaN, NaN, NaN}];
        
        a_vals = data.(a_var);
        
        if avg_only
            % hab / θ / α：只写一行"平均值"，取 a1 的值
            row = {'平均值'};
            for ni = 1:n_nation
                v = a_vals(ni, 1);
                % θ 分区：值 + 90 - 360
                if strcmp(sec_title, 'θ')
                    v = v + 90 - 360;
                end
                row{end+1} = v;
            end
            data_mat = [data_mat; row];
        else
            % C* / 长轴长 / 短轴长：完整参数 + r + rmse
            for pi = 1:length(param_labels)
                row = {param_labels{pi}};
                for ni = 1:n_nation
                    row{end+1} = a_vals(ni, pi);
                end
                data_mat = [data_mat; row];
            end
            
            r_vals = data.(r_var);
            row = {'r'};
            for ni = 1:n_nation
                row{end+1} = r_vals(ni);
            end
            data_mat = [data_mat; row];
            
            rmse_vals = data.(rmse_var);
            row = {'rmse'};
            for ni = 1:n_nation
                row{end+1} = rmse_vals(ni);
            end
            data_mat = [data_mat; row];
        end
    end
    if ai==3
        disp("d")
    end
    % 写入: 第一个sheet用写入模式，后续用追加sheet
    if ai == 1
        writecell(data_mat, out_path, 'Sheet', attr_names{ai});
    else
        writecell(data_mat, out_path, 'Sheet', attr_names{ai}, 'WriteMode', 'append');
    end
end

%% 第二遍：用COM统一做格式美化
fprintf('Formatting ...\n');
xl = actxserver('Excel.Application');
xl.Visible = false;
xl.DisplayAlerts = false;
xlWorkbook = xl.Workbooks.Open(out_path);

for ai = 1:10
    sheet_name = attr_names{ai};
    try
        xlSheet = xlWorkbook.Sheets.Item(sheet_name);
    catch
        fprintf('[WARN] Sheet "%s" not found, skipping.\n', sheet_name);
        continue;
    end
    
    % 列标题加粗
    xlSheet.Range('A1:F1').Font.Bold = true;
    
    % 列宽
    xlSheet.Columns.Item(1).ColumnWidth = 12;
    for ni = 1:n_nation
        xlSheet.Columns.Item(ni+1).ColumnWidth = 16;
    end
    
    % 找合并行并格式化
    usedRange = xlSheet.UsedRange;
    nRows = usedRange.Rows.Count;
    row = 2;
    while row <= nRows
        is_title = true;
        for ci = 2:6
            addr = sprintf('%c%d', 'A' + ci - 1, row);
            val = xlSheet.Range(addr).Value;
            if ~isempty(val) && isnumeric(val) && ~isnan(val)
                is_title = false;
                break;
            end
        end
        if is_title
            rng = xlSheet.Range(sprintf('A%d:F%d', row, row));
            rng.Merge;
            rng.Font.Bold = true;
        end
        row = row + 1;
    end
    
    % 数值格式：统一保留2位小数
    for ri = 2:nRows
        for ci = 2:6
            addr = sprintf('%c%d', 'A' + ci - 1, ri);
            cell = xlSheet.Range(addr);
            val = cell.Value;
            if ~isempty(val) && isnumeric(val) && ~isnan(val)
                cell.NumberFormat = '0.00';
            end
        end
    end
end

xlWorkbook.Save;
xlWorkbook.Close;
xl.Quit;
xl.delete();

fprintf('\nAll done! Saved: %s\n', out_path);
