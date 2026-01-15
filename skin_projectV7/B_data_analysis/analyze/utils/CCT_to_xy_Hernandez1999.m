function xy = CCT_to_xy_Hernandez1999(cct, optimisation_kwargs)
% CCT_to_xy_Hernandez1999 使用Hernandez-Andres等(1999)方法从相关色温计算CIE xy坐标
%   参数:
%       cct - 相关色温值 [N×1] 向量
%       optimisation_kwargs - 优化参数设置(可选)
%   返回:
%       xy - 计算得到的CIE xy色度坐标 [N×2] 矩阵

    % 显示警告信息
    warning('"Hernandez-Andres et al. (1999)"方法从相关色温计算CIE xy坐标不是双射函数，可能产生意外结果。');
    warning('此实现仅为与其他色温计算方法保持一致，实际应用中应避免使用。');
    
    % 处理输入参数
    if nargin < 2
        optimisation_kwargs = struct();
    end
    
    % 确保输入为列向量
    cct = reshape(cct, [], 1);
    [n, ~] = size(cct);
    xy = zeros(n, 2);
    
    % 设置默认优化参数
    options = optimset('Display', 'off', 'TolX', 1e-10, 'MaxIter', 1000);
    method = 'Nelder-Mead';
    
    % 合并用户自定义优化参数
    if isfield(optimisation_kwargs, 'options')
        options = optimset(options, fieldnames(optimisation_kwargs.options), ...
                          struct2cell(optimisation_kwargs.options));
    end
    if isfield(optimisation_kwargs, 'method')
        method = optimisation_kwargs.method;
    end
    
    % 获取D65的xy坐标作为初始值
    xy_D65 = [0.3127, 0.3290]; % CIE 1931标准观察者D65的xy坐标
    
    % 对每个CCT值进行优化求解
    for i = 1:n
        cct_i = cct(i);
        
        % 定义目标函数：计算预测的CCT与实际CCT的差值
        objective = @(xy_i) norm(xy_to_CCT_Hernandez1999(xy_i) - cct_i);
        
        % 使用fminsearch进行优化(对应Python的Nelder-Mead方法)
        if strcmpi(method, 'Nelder-Mead')
            [xy(i, :), ~] = fminsearch(objective, xy_D65, options);
        else
            error('目前只支持Nelder-Mead优化方法');
        end
    end
end