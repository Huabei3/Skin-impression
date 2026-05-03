% check_xlsx_sheets.m
% 检查各 ablation_type 下的 xlsx 文件：sheet数、Preference行满不满、各attribute是否有数据

clear; clc;

base_path = 'D:\work\VIVOskinExpe\skin_model\data\correlation_results\fullpara\efit_p\new\ACSA\each_self';

% 需要检查的 ablation_type 文件夹
ablation_types = {'scene_types', 'no_scene_types', 'full_CAT', 'no_nation', 'no_L_depend'};

% 预期的 20 个 model 名称
expected_models = ["f04", "f05", "f06", "m04", "m05", "m06", ...
                   "f01", "f02", "f03", "m01", "m02", "m03", ...
                   "f07", "f08", "m07", "m08", ...
                   "f09", "f10", "m09", "m10"];

% 10 个 attribute
attribute_names = {"Preference", "Attractiveness", "Feminine", "Cooperative", ...
                   "Youth", "Healthy", "Fidelity", "Harmony", "Fair", "Ruddy"};

for a = 1:length(ablation_types)
    at = ablation_types{a};
    folder = fullfile(base_path, at);
    
    fprintf('\n================================================================\n');
    fprintf('ablation_type: %s\n', at);
    fprintf('================================================================\n');
    
    if ~exist(folder, 'dir')
        fprintf('  文件夹不存在，跳过\n');
        continue;
    end
    
    % 找到该文件夹下的 xlsx 文件（非子目录中的）
    xlsx_files = dir(fullfile(folder, '*.xlsx'));
    
    for f = 1:length(xlsx_files)
        fname = xlsx_files(f).name;
        fpath = fullfile(folder, fname);
        
        fprintf('\n  --- %s ---\n', fname);
        
        % 获取 sheet 名
        try
            [sheets, ~] = xlsfinfo(fpath);
        catch
            fprintf('    无法读取文件\n');
            continue;
        end
        
        if ischar(sheets)
            sheets = {sheets};
        end
        
        fprintf('    Sheet数: %d\n', length(sheets));
        
        % 检查是否有 20 个 model 的 sheet
        sheet_names = {};
        for s = 1:length(sheets)
            if iscell(sheets)
                sheet_names{s} = char(sheets{s});
            else
                sheet_names{s} = char(sheets(s,:));
            end
        end
        
        % 检查哪些 expected_models 存在
        missing_models = {};
        for m = 1:length(expected_models)
            found = false;
            for s = 1:length(sheet_names)
                if strcmp(sheet_names{s}, char(expected_models(m)))
                    found = true;
                    break;
                end
            end
            if ~found
                missing_models{end+1} = char(expected_models(m)); %#ok<AGROW>
            end
        end
        
        if isempty(missing_models)
            fprintf('    所有20个model sheet都存在\n');
        else
            fprintf('    缺少以下model sheet: %s\n', strjoin(missing_models, ', '));
        end
        
        % 对每个 sheet 检查数据
        for s = 1:length(sheet_names)
            sname = sheet_names{s};
            try
                T = readtable(fpath, 'Sheet', sname, 'ReadVariableNames', false);
            catch
                fprintf('    Sheet %s: 读取失败\n', sname);
                continue;
            end
            
            [nrows, ncols] = size(T);
            
            % 检查各列的 NaN 比例
            % 第1列是光源名，第2-11列是10个attribute
            nan_counts = zeros(1, min(10, ncols-1));
            for c = 1:min(10, ncols-1)
                col_data = T{:, c+1};
                if isnumeric(col_data)
                    nan_counts(c) = sum(isnan(col_data));
                elseif iscell(col_data)
                    nan_counts(c) = sum(cellfun(@(x) isempty(x) || (isnumeric(x) && isnan(x)), col_data));
                end
            end
            
            % 只对 Preference 和总体情况汇报
            pref_nan = nan_counts(1);
            pref_total = nrows;
            total_nan = sum(nan_counts);
            total_cells = nrows * min(10, ncols-1);
            
            if pref_nan == 0
                pref_status = '全满';
            elseif pref_nan == pref_total
                pref_status = '全空';
            else
                pref_status = sprintf('部分空(%d/%d NaN)', pref_nan, pref_total);
            end
            
            % 哪些 attribute 有数据（非全 NaN）
            attrs_with_data = {};
            attrs_all_nan = {};
            for c = 1:min(10, ncols-1)
                if nan_counts(c) < nrows
                    attrs_with_data{end+1} = char(attribute_names(c)); %#ok<AGROW>
                else
                    attrs_all_nan{end+1} = char(attribute_names(c)); %#ok<AGROW>
                end
            end
            
            fprintf('    Sheet %s: %d行x%d列 | Preference: %s | 有数据的attr(%d): %s', ...
                sname, nrows, ncols, pref_status, length(attrs_with_data), ...
                strjoin(attrs_with_data, ','));
            if ~isempty(attrs_all_nan)
                fprintf(' | 全NaN的attr(%d): %s', length(attrs_all_nan), strjoin(attrs_all_nan, ','));
            end
            fprintf('\n');
        end
    end
end

fprintf('\n检查完成。\n');
