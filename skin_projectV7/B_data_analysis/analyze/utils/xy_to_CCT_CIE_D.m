function CCT = xy_to_CCT_CIE_D(xy, optimisation_kwargs)
% xy_to_CCT_CIE_D 将CIE xy色度坐标转换为相关色温(CCT)
%   参数:
%       xy - CIE xy色度坐标 [N×2] 矩阵或向量
%       optimisation_kwargs - 优化参数设置(可选)
%   返回:
%       CCT - 计算得到的相关色温 [N×1] 向量

    % 处理输入参数
    if nargin < 2
        optimisation_kwargs = struct();
    end
    
    % 确保输入是矩阵形式
    [rows, cols] = size(xy);
    if cols ~= 2
        error('输入必须是N×2的矩阵，每行为一个(x,y)坐标对');
    end
    
    % 设置默认优化参数
    options = optimset('Display', 'off', 'TolX', 1e-10, 'MaxIter', 1000);
    method = 'Nelder-Mead';
    
    % 合并用户自定义优化参数
    if isfield(optimisation_kwargs, 'options')
        options = optimset(options, optimisation_kwargs.options);
    end
    if isfield(optimisation_kwargs, 'method')
        method = optimisation_kwargs.method;
    end
    
    % 初始化结果数组
    CCT = zeros(rows, 1);
    
    % 对每个xy坐标对进行优化求解
    for i = 1:rows
        xy_i = xy(i, :);
        
        % 定义目标函数：计算预测的xy与实际xy的欧氏距离
        objective = @(cct) norm(CCT_to_xy_CIE_D(cct) - xy_i);
        
        % 使用fminsearch进行优化(对应Python的Nelder-Mead方法)
        if strcmpi(method, 'Nelder-Mead')
            [CCT(i), ~] = fminsearch(objective, 6500, options);
        else
            % 其他优化方法可以在这里扩展
            error('目前只支持Nelder-Mead优化方法');
        end
    end
end

