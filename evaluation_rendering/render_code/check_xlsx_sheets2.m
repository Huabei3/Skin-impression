% check_xlsx_sheets2.m
% 用 readmatrix 直接读每个 model sheet

clear; clc;

base_path = 'D:\work\VIVOskinExpe\skin_model\data\correlation_results\fullpara\efit_p\new\ACSA\each_self';

ablation_types = {'scene_types', 'no_scene_types', 'full_CAT', 'no_nation', 'no_L_depend'};

expected_models = {'f04', 'f05', 'f06', 'm04', 'm05', 'm06', ...
                   'f01', 'f02', 'f03', 'm01', 'm02', 'm03', ...
                   'f07', 'f08', 'm07', 'm08', ...
                   'f09', 'f10', 'm09', 'm10'};

attribute_names = {'Preference', 'Attractiveness', 'Feminine', 'Cooperative', ...
                   'Youth', 'Healthy', 'Fidelity', 'Harmony', 'Fair', 'Ruddy'};

for a = 1:length(ablation_types)
    at = ablation_types{a};
    folder = fullfile(base_path, at);
    
    fprintf('\n================================================================\n');
    fprintf('ablation_type: %s\n', at);
    fprintf('================================================================\n');
    
    if ~exist(folder, 'dir')
        fprintf('  folder not found, skip\n');
        continue;
    end
    
    xlsx_files = dir(fullfile(folder, '*.xlsx'));
    
    for f = 1:length(xlsx_files)
        fname = xlsx_files(f).name;
        fpath = fullfile(folder, fname);
        
        fprintf('\n  --- %s ---\n', fname);
        
        % 逐个尝试读取每个 model 的 sheet
        found_sheets = {};
        missing_sheets = {};
        
        for m = 1:length(expected_models)
            mn = expected_models{m};
            try
                data = readmatrix(fpath, 'Sheet', mn);
                found_sheets{end+1} = mn; %#ok<AGROW>
                [nrows, ncols] = size(data);
                
                % 跳过第一行(header)和第一列(光源名)
                if nrows <= 1 || ncols <= 1
                    fprintf('    Sheet %s: 数据不足 (%d rows, %d cols)\n', mn, nrows, ncols);
                    continue;
                end
                
                % 数据区域：去掉 header 行
                data_body = data(2:end, :);
                % 去掉第一列（光源名可能被读为NaN）
                data_body = data_body(:, 2:min(11, end));
                
                [nr, nc] = size(data_body);
                
                % 每列的 NaN 数量
                nan_per_col = sum(isnan(data_body), 1);
                % 每列的非 NaN 数量
                valid_per_col = nr - nan_per_col;
                
                % Preference 是第1列
                pref_valid = valid_per_col(1);
                pref_total = nr;
                
                % 有多少 attribute 列有至少1个有效值
                n_attrs_with_data = sum(valid_per_col > 0);
                % 全 NaN 的 attribute 列数
                n_attrs_all_nan = sum(valid_per_col == 0);
                
                % 哪些 attr 全 NaN
                all_nan_attrs = {};
                for c = 1:length(valid_per_col)
                    if c <= length(attribute_names) && valid_per_col(c) == 0
                        all_nan_attrs{end+1} = attribute_names{c}; %#ok<AGROW>
                    end
                end
                
                pref_pct = pref_valid / pref_total * 100;
                
                fprintf('    Sheet %s: %d rows, Preference %d/%d (%.0f%%), attrs有数据: %d/10', ...
                    mn, nr, pref_valid, pref_total, pref_pct, n_attrs_with_data);
                if ~isempty(all_nan_attrs)
                    fprintf(', 全NaN: %s', strjoin(all_nan_attrs, ','));
                end
                fprintf('\n');
                
            catch
                missing_sheets{end+1} = mn; %#ok<AGROW>
            end
        end
        
        fprintf('    ---- Summary: %d/%d sheets found', length(found_sheets), length(expected_models));
        if ~isempty(missing_sheets)
            fprintf(', missing: %s', strjoin(missing_sheets, ','));
        end
        fprintf('\n');
    end
end

fprintf('\nDone.\n');
