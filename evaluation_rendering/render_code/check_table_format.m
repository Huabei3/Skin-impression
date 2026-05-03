% check_table_format.m
% 检查两个 table 的字段格式

clear; clc;

load('D:\work\VIVOskinExpe\analyze\AnalyseResults_p\efit_p\scaled\resTable\Peggy_VIVO_table.mat', 'fit_table');
VIVO_table = fit_table;

load('D:\work\VIVOskinExpe\analyze\AnalyseResults_p\noCAT\scaled\no_fit\resTable\original_unscaled\Peggy_VIVO_table.mat', 'fit_table');
VIVO_noCAT_table = fit_table;

fprintf('===== VIVO_table =====\n');
fprintf('行数: %d\n', height(VIVO_table));
fprintf('变量名: %s\n', strjoin(VIVO_table.Properties.VariableNames, ', '));

fields = {'model_id', 'scene', 'observer_type', 'attribute'};
for i = 1:length(fields)
    f = fields{i};
    fprintf('\n--- %s ---\n', f);
    fprintf('  类别: %s\n', class(VIVO_table.(f)));
    if iscell(VIVO_table.(f))
        fprintf('  cell 元素类别(前3): ');
        for j = 1:min(3, height(VIVO_table))
            fprintf('%s ', class(VIVO_table.(f){j}));
        end
        fprintf('\n');
        % 显示前3个值
        for j = 1:min(3, height(VIVO_table))
            fprintf('  行%d: %s\n', j, string(VIVO_table.(f)(j)));
        end
    elseif isstring(VIVO_table.(f))
        for j = 1:min(3, height(VIVO_table))
            fprintf('  行%d: %s\n', j, VIVO_table.(f)(j));
        end
    else
        fprintf('  前3个值: %s\n', mat2str(VIVO_table.(f)(1:min(3,height(VIVO_table)))));
    end
end

fprintf('\n===== VIVO_noCAT_table =====\n');
fprintf('行数: %d\n', height(VIVO_noCAT_table));

for i = 1:length(fields)
    f = fields{i};
    fprintf('\n--- %s ---\n', f);
    fprintf('  类别: %s\n', class(VIVO_noCAT_table.(f)));
    if iscell(VIVO_noCAT_table.(f))
        for j = 1:min(3, height(VIVO_noCAT_table))
            fprintf('  行%d: %s\n', j, string(VIVO_noCAT_table.(f)(j)));
        end
    elseif isstring(VIVO_noCAT_table.(f))
        for j = 1:min(3, height(VIVO_noCAT_table))
            fprintf('  行%d: %s\n', j, VIVO_noCAT_table.(f)(j));
        end
    else
        fprintf('  前3个值: %s\n', mat2str(VIVO_noCAT_table.(f)(1:min(3,height(VIVO_noCAT_table)))));
    end
end

fprintf('\n格式检查完成。\n');
