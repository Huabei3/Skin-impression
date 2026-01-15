function table = planckian_table(cmfs, start, endTemp, spacing)
% planckian_table 生成普朗克表
%   参数:
%       cmfs - 标准观察者颜色匹配函数
%       start - 温度范围起始值
%       endTemp - 温度范围结束值
%       spacing - 间距乘数
%   返回:
%       table - 普朗克表 [N×3] 矩阵，包含温度、u和v坐标

    % 检查间距是否大于1
    if spacing <= 1
        error('间距值必须大于1!');
    end
    
    % 生成温度序列
    Ti = [start, start + 1];
    next_ti = start + 1;
    next_spacing = spacing;
    while (next_ti = next_ti * next_spacing) < endTemp
        Ti = [Ti; next_ti];
        
        % 为更高的CCT略微减小步长
        D = (next_ti - 1000) / (100000 - 1000);
        D = min(max(D, 0), 1);
        next_spacing = spacing * (1 - D) + (1 + (spacing - 1) / 10) * D;
    end
    Ti = [Ti; endTemp - 1; endTemp];
    
    % 计算每个温度对应的uv坐标
    n = length(Ti);
    table = zeros(n, 3);
    table(:, 1) = Ti';
    
    for i = 1:n
        table(i, 2:3) = CCT_to_uv_Planck1900(Ti(i), cmfs);
    end
end