%% XLSX_predict.m
% 从 inon_model_r.xlsx 和 rnon_model_r.xlsx 提取各人种sheet的r值统计量
% 输出：STIM性能评估表（max / min / 平均值），按 iOr="i"/"r" 分组
%
% 格式：
%   列: iOr / 人种 / max / min / 平均值
%   行: 4个人种 × 2种iOr = 8行数据

clear; clc;

%% 路径配置
src_dir  = 'D:\work\VIVOskinExpe\skin_model\data\correlation_results\fullpara\efit_p\new\ACSA\each_self\scene_types';
out_path = fullfile(src_dir, 'STIM_performance_r.xlsx');

%% 配置
nation_sheets = {'Asian', 'Caucasian', 'South Asian', 'African'};
nation_cn     = {'亚洲人', '高加索人', '南亚人', '非洲人'};
ior_cfg       = {'i', 'inon_model_r.xlsx';
                 'r', 'rnon_model_r.xlsx'};
n_nation = numel(nation_sheets);

%% 构造输出数据
out = {};

for oi = 1:2
    ior_tag = ior_cfg{oi, 1};
    xlsx_fn = ior_cfg{oi, 2};
    xlsx_path = fullfile(src_dir, xlsx_fn);

    if ~exist(xlsx_path, 'file')
        fprintf('[WARN] %s not found, skipping.\n', xlsx_fn);
        continue;
    end

    fprintf('Reading %s ...\n', xlsx_fn);

    for ni = 1:n_nation
        sheet_name = nation_sheets{ni};
        cn_name    = nation_cn{ni};

        % 读取sheet全部数据
        [~, ~, raw] = xlsread(xlsx_path, sheet_name);
        % raw: cell array, row1=header, col1=row labels

        % 提取数值区域：去掉第1行(表头) + 第1列(行标签)
        % 同时去掉名为 'mean' 的行和列
        [~, txt_cols, raw_cols] = xlsread(xlsx_path, sheet_name);
        % raw_cols 包含所有列（含表头行）

        % 重新读整个sheet为cell
        all_data = raw;
        header_row = all_data(1, :);
        label_col  = all_data(2:end, 1);

        % 找到哪些列不是 'mean'
        col_keep = true(1, size(all_data, 2));
        for ci = 1:length(header_row)
            if ischar(header_row{ci}) || isstring(header_row{ci})
                if strcmpi(strtrim(header_row{ci}), 'mean')
                    col_keep(ci) = false;
                end
            end
        end

        % 找到哪些行不是 'mean'（行标签）
        row_keep = true(size(all_data, 1) - 1, 1);
        for ri = 1:length(label_col)
            if ischar(label_col{ri}) || isstring(label_col{ri})
                if strcmpi(strtrim(label_col{ri}), 'mean')
                    row_keep(ri) = false;
                end
            end
        end

        % 提取数值子矩阵：去掉第1行(表头)、第1列(标签)、mean行和mean列
        val_matrix = all_data(2:end, 2:end);
        val_matrix = val_matrix(row_keep, col_keep);

        % 收集所有非空数值
        all_vals = [];
        for r = 1:size(val_matrix, 1)
            for c = 1:size(val_matrix, 2)
                v = val_matrix{r, c};
                if isnumeric(v) && ~isnan(v)
                    all_vals(end+1) = v;
                end
            end
        end

        if isempty(all_vals)
            v_max = NaN;
            v_min = NaN;
            v_mean = NaN;
        else
            v_max  = max(all_vals);
            v_min  = min(all_vals);
            v_mean = mean(all_vals);
        end

        fprintf('  %s (%s): max=%.4f, min=%.4f, mean=%.4f (n=%d)\n', ...
                cn_name, ior_tag, v_max, v_min, v_mean, length(all_vals));

        out = [out; {ior_tag, cn_name, v_max, v_min, v_mean}];
    end
end

%% 写入xlsx
header = {'iOr', '人种', 'max', 'min', '平均值'};
out = [header; out];

writecell(out, out_path);

%% COM格式美化
xl = actxserver('Excel.Application');
xl.Visible = false;
xl.DisplayAlerts = false;
xlWorkbook = xl.Workbooks.Open(out_path);
xlSheet = xlWorkbook.Sheets.Item(1);

% 表头加粗居中
xlSheet.Range('A1:E1').Font.Bold = true;
xlSheet.Range('A1:E1').HorizontalAlignment = 3; % xlCenter

% 列宽
xlSheet.Columns.Item(1).ColumnWidth = 8;
xlSheet.Columns.Item(2).ColumnWidth = 12;
xlSheet.Columns.Item(3).ColumnWidth = 10;
xlSheet.Columns.Item(4).ColumnWidth = 10;
xlSheet.Columns.Item(5).ColumnWidth = 12;

% 数值保留2位小数
nRows = xlSheet.UsedRange.Rows.Count;
for ri = 2:nRows
    for ci = 3:5
        addr = sprintf('%c%d', 'A' + ci - 1, ri);
        cell = xlSheet.Range(addr);
        val = cell.Value;
        if ~isempty(val) && isnumeric(val) && ~isnan(val)
            cell.NumberFormat = '0.00';
        end
    end
end

xlWorkbook.Save;
xlWorkbook.Close;
xl.Quit;
xl.delete();

fprintf('\nDone! Saved: %s\n', out_path);
