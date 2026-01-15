function [rho, p_value] = spearman_correlation(x, y)
    % SPEARMAN_CORRELATION 计算两个向量的Spearman相关系数
    %   输入:
    %       x - 第一个向量
    %       y - 第二个向量
    %   输出:
    %       rho - Spearman相关系数，范围[-1, 1]
    %       p_value - 显著性水平（p值）
    
    % 检查输入是否为向量且长度相同
    if ~isvector(x) || ~isvector(y)
        error('输入必须是向量');
    end
    
    x = x(:);  % 转换为列向量
    y = y(:);  % 转换为列向量
    
    if length(x) ~= length(y)
        error('两个向量必须具有相同的长度');
    end
    
    % 使用MATLAB内置函数计算Spearman相关系数
    % 'Type'指定为'Spearman'，'Rows'指定为'complete'表示删除含有NaN的行
    [rho, p_value] = corr(x, y, 'Type', 'Spearman', 'Rows', 'complete');
end
