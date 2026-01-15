% --- 新增目标函数：用于最大化皮尔逊相关系数 ---
function neg_correlation = objective_function_for_corr_max(scale_factor_val, f1_base_func, xdata, y_true)
% objective_function_for_corr_max 计算负皮尔逊相关系数，用于最小化优化。
%
%   输入:
%     scale_factor_val: 待优化的缩放因子。
%     f1_base_func: 不带 scale_factor 的基准模型函数。
%     xdata: 独立变量数据 (lab_group_current_hml(:, 2:3))。
%     y_true: 真实因变量数据 (y_f_pred)。
%
%   输出:
%     neg_correlation: 皮尔逊相关系数的负值。

    % 1. 计算当前 scale_factor_val 下的模型预测值
    y_predicted = f1_base_func(xdata) .* scale_factor_val;

    % 2. 处理 NaN 或 Inf 值，确保 corr 函数的鲁棒性
    % 筛选掉 y_predicted 或 y_true 中包含 NaN 或 Inf 的数据点
    valid_indices = ~isnan(y_predicted) & ~isinf(y_predicted) & ...
                    ~isnan(y_true) & ~isinf(y_true);
    
    y_predicted_valid = y_predicted(valid_indices);
    y_true_valid = y_true(valid_indices);

    % 确保有足够的数据点来计算相关系数
    if length(y_predicted_valid) < 2 || length(y_true_valid) < 2
        % 如果数据点不足，返回一个非常大的值，表示拟合很差
        neg_correlation = 1e10; 
        return;
    end

    % 检查经过筛选后数据是否全为常数（这会导致相关系数为 NaN）
    if std(y_predicted_valid) == 0 && std(y_true_valid) == 0
        % 如果两者都是常数，且它们相等，则认为是完美相关（相关系数1），但如果有一个不同，则视为无法计算。
        if y_predicted_valid(1) == y_true_valid(1)
            neg_correlation = -1; % 完美相关
        else
            neg_correlation = 1; % 理论上应该返回 NaN，但为了优化稳定，返回差值
        end
        return;
    elseif std(y_predicted_valid) == 0 || std(y_true_valid) == 0
        % 如果其中一个变量是常数，则皮尔逊相关系数为 NaN
        neg_correlation = 1; % 表示相关性很差
        return;
    end

    % 3. 计算皮尔逊相关系数
    correlation = corr(y_predicted_valid, y_true_valid, 'Type', 'Pearson');
    
    % 4. 返回负相关系数（因为 fminbnd/fminsearch 是最小化函数）
    neg_correlation = -correlation;
    
    % 检查结果是否是 NaN，如果是，则返回一个惩罚值
    if isnan(neg_correlation)
        neg_correlation = 1; % 惩罚值，表示相关性差
    end
end