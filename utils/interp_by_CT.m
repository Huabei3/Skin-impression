function value_interp = interp_by_CT(CT_input, CT_values, values)
    % 检查输入参数是否有效
    if length(CT_values) ~= length(values)
        error('色温值和chroma值的数量必须相同');
    end
    if length(CT_values) < 2
        error('至少需要2组已知的色温与chroma值');
    end
    
    % 计算色温的倒数 (1/T)，单位为1/K
    inv_T = 1./CT_values;
    inv_CT_input = 1./CT_input;
    
    % 基于色温倒数进行线性插值
    value_interp = interp1(inv_T, values, inv_CT_input, 'linear', 'extrap');
end