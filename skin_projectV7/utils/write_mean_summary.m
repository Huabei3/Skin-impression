function write_mean_summary(excel_path, model_names, nation_indices, nation_labels)
    % 获取所有 sheet 名
    [~, sheets] = xlsfinfo(excel_path);

    % 初始化：所有model的数据
    all_model_data = {};
    row_labels = {};
    column_labels = {};

    % 初始化民族分类数据
    nation_data = cell(length(nation_labels), 1);
    for i = 1:length(nation_labels)
        nation_data{i} = {};
    end

    for i_model = 1:length(model_names)
        model_name = char(model_names(i_model));
        
        if ~ismember(model_name, sheets)
            fprintf('跳过：未找到 sheet %s\n', model_name);
            continue;
        end

        T = readtable(excel_path, 'Sheet', model_name, 'ReadVariableNames', true);

        % 提取表头（首次提取）
        if isempty(row_labels)
            row_labels = T{:,1};
            column_labels = T.Properties.VariableNames(2:end);
        end

        % 强制提取数值数据并转为 double，非法字符转为 NaN
        raw = table2cell(T(:, 2:end));
        numeric_data = nan(size(raw));
        for r = 1:size(raw, 1)
            for c = 1:size(raw, 2)
                val = raw{r, c};
                if isnumeric(val)
                    numeric_data(r, c) = val;
                elseif ischar(val) || isstring(val)
                    num = str2double(val);
                    if ~isnan(num)
                        numeric_data(r, c) = num;
                    end
                end
                % 否则保留为 NaN
            end
        end

        all_model_data{end+1} = numeric_data;

        % 分类到民族数据
        for i_nation = 1:length(nation_indices)
            if ismember(i_model, nation_indices{i_nation})
                nation_data{i_nation}{end+1} = numeric_data;
                break;
            end
        end
    end

    % ===== 写入所有 model 的 nanmean 到 "mean" Sheet =====
    stacked_all = cat(3, all_model_data{:});
    mean_all = nanmean(stacked_all, 3);

    mean_table = array2table(mean_all, 'VariableNames', column_labels, 'RowNames', cellstr(row_labels));
    writetable(mean_table, excel_path, 'Sheet', 'mean', 'WriteRowNames', true);

    % ===== 写入各民族的 nanmean 到对应 Sheet =====
    for i_nation = 1:length(nation_data)
        curr_group = nation_data{i_nation};
        if isempty(curr_group)
            continue;
        end
        stacked_nation = cat(3, curr_group{:});
        mean_nation = nanmean(stacked_nation, 3);

        nation_table = array2table(mean_nation, 'VariableNames', column_labels, 'RowNames', cellstr(row_labels));
        writetable(nation_table, excel_path, 'Sheet', nation_labels(i_nation), 'WriteRowNames', true);
    end

    fprintf('✅ 成功写入 mean 及每个民族汇总数据到 Excel：%s\n', excel_path);
end
