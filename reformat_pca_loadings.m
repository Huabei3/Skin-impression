%% reformat_pca_loadings.m
% 工具函数: 读取 PCA 载荷表, 重新排列并写入新 sheet
%
% 输入: loadings_path — pca_loadings.xlsx 的完整路径
%
% 功能:
%   1. 读取原始载荷表 (行=attribute, 列=PC, 值=loading)
%   2. 每个 PC 列内, 按 loading 绝对值降序排列
%   3. 每格格式: {attribute_name} ({loading*100:.1f}%)
%   4. 写入同一 xlsx 的新 sheet "Sorted_by_AbsLoading"
%
% 用法: reformat_pca_loadings('D:\...\pca_loadings.xlsx')
%
% Kenzie, 2026-06-16

function reformat_pca_loadings(loadings_path)
    % 检查文件存在
    if ~exist(loadings_path, 'file')
        error('文件不存在: %s', loadings_path);
    end
    
    % 读取载荷表 (第一列为 row names)
    T = readtable(loadings_path, 'ReadRowNames', true);
    
    attr_names = T.Properties.RowNames;
    pc_names = T.Properties.VariableNames;
    n_attr = length(attr_names);
    n_pc = length(pc_names);
    
    fprintf('=== reformat_pca_loadings ===\n');
    fprintf('  输入: %s\n', loadings_path);
    fprintf('  Attribute 数: %d, PC 数: %d\n', n_attr, n_pc);
    
    % 构建重排后的表格
    out_data = cell(n_attr, n_pc);
    
    for pc = 1:n_pc
        loadings = T{:, pc};
        
        % 按绝对值降序排列
        [~, sort_idx] = sort(abs(loadings), 'descend');
        
        sorted_attrs = attr_names(sort_idx);
        sorted_loads = loadings(sort_idx);
        
        % 格式: "AttributeName (XX.X%)"
        for i = 1:n_attr
            out_data{i, pc} = sprintf('%s (%.1f%%)', ...
                sorted_attrs{i}, sorted_loads(i) * 100);
        end
    end
    
    % 转换为 table
    out_table = cell2table(out_data, ...
        'VariableNames', matlab.lang.makeValidName(pc_names));
    
    % 写入新 sheet
    writetable(out_table, loadings_path, 'Sheet', 'Sorted_by_AbsLoading');
    
    fprintf('  已写入 sheet: Sorted_by_AbsLoading\n');
    
    % 同时打印到命令行, 方便快速查看
    fprintf('\n--- 载荷排序表预览 (前3行) ---\n');
    for pc = 1:n_pc
        fprintf('  %s:\n', pc_names{pc});
        for i = 1:min(3, n_attr)
            fprintf('    %d. %s\n', i, out_data{i, pc});
        end
    end
    
    fprintf('  完成\n');
end
