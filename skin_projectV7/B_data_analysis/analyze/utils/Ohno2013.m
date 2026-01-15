function [cct, D_uv] = XYZ_to_CCT_Ohno2013(XYZ, cmfs, start, endTemp, spacing)
% XYZ_to_CCT_Ohno2013 使用Ohno(2013)方法将CIE XYZ三刺激值转换为相关色温(CCT)和Δuv
%   参数:
%       XYZ - CIE XYZ三刺激值 [N×3] 矩阵
%       cmfs - 标准观察者颜色匹配函数 (可选)
%       start - 色温范围起始值 (默认: 1000K)
%       endTemp - 色温范围结束值 (默认: 100000K)
%       spacing - 普朗克表间距乘数 (默认: 1.001)
%   返回:
%       cct - 相关色温值 [N×1] 向量
%       D_uv - Δuv值 [N×1] 向量

    % 处理输入参数
    if nargin < 2
        cmfs = []; % 使用默认的CIE 1931 2°观察者
    end
    if nargin < 3
        start = 1000;
    end
    if nargin < 4
        endTemp = 100000;
    end
    if nargin < 5
        spacing = 1.001;
    end
    
    % 确保输入为二维矩阵
    XYZ = reshape(XYZ, [], 3);
    [n, ~] = size(XYZ);
    cct = zeros(n, 1);
    D_uv = zeros(n, 1);
    
    % 加载默认的颜色匹配函数(CIE 1931 2°观察者)
    if isempty(cmfs)
        cmfs = load_cie_1931_2degree();
    end
    
    % 转换XYZ到CIE UCS颜色空间
    ucs = XYZ_to_UCS(XYZ);
    
    % 转换UCS到uv坐标
    uv = UCS_to_uv(ucs);
    
    % 调用uv_to_CCT_Ohno2013函数进行计算
    [cct, D_uv] = uv_to_CCT_Ohno2013(uv, cmfs, start, endTemp, spacing);
end

function ucs = XYZ_to_UCS(XYZ)
% XYZ_to_UCS 将CIE XYZ三刺激值转换为CIE UCS颜色空间坐标
%   参数:
%       XYZ - CIE XYZ三刺激值 [N×3] 矩阵
%   返回:
%       ucs - CIE UCS颜色空间坐标 [N×3] 矩阵

    % CIE UCS转换矩阵
    M = [4  -4  0;
         1   2  1;
         0  -4  5];
    
    % 确保XYZ为二维矩阵
    XYZ = reshape(XYZ, [], 3);
    [n, ~] = size(XYZ);
    
    % 计算总和用于归一化
    sum_XYZ = sum(XYZ, 2);
    sum_XYZ = max(sum_XYZ, 1e-10); % 避免除零
    
    % 归一化XYZ
    XYZ_norm = bsxfun(@rdivide, XYZ, sum_XYZ);
    
    % 应用转换矩阵
    ucs = XYZ_norm * M';
end

function uv = UCS_to_uv(ucs)
% UCS_to_uv 将CIE UCS颜色空间坐标转换为uv坐标
%   参数:
%       ucs - CIE UCS颜色空间坐标 [N×3] 矩阵
%   返回:
%       uv - uv色度坐标 [N×2] 矩阵

    % 确保ucs为二维矩阵
    ucs = reshape(ucs, [], 3);
    [n, ~] = size(ucs);
    
    % 计算总和用于归一化
    sum_ucs = sum(ucs, 2);
    sum_ucs = max(sum_ucs, 1e-10); % 避免除零
    
    % 计算u和v坐标
    u = ucs(:, 1) ./ sum_ucs;
    v = ucs(:, 2) ./ sum_ucs;
    
    % 组合成uv矩阵
    uv = [u, v];
end

function [cct, D_uv] = uv_to_CCT_Ohno2013(uv, cmfs, start, endTemp, spacing)
% uv_to_CCT_Ohno2013 使用Ohno(2013)方法从uv坐标计算CCT和Δuv
%   参数:
%       uv - uv色度坐标 [N×2] 矩阵
%       cmfs - 标准观察者颜色匹配函数
%       start - 色温范围起始值
%       endTemp - 色温范围结束值
%       spacing - 普朗克表间距乘数
%   返回:
%       cct - 相关色温值 [N×1] 向量
%       D_uv - Δuv值 [N×1] 向量

    % 确保输入为二维矩阵
    uv = reshape(uv, [], 2);
    [n, ~] = size(uv);
    cct = zeros(n, 1);
    D_uv = zeros(n, 1);
    
    % 生成普朗克表
    table = planckian_table(cmfs, start, endTemp, spacing);
    
    % 对每个uv坐标进行处理
    for i = 1:n
        uv_i = uv(i, :);
        
        % 计算uv_i到普朗克表中各点的距离
        dists = zeros(size(table, 1), 1);
        for j = 1:size(table, 1)
            dists(j) = norm(uv_i - table(j, 2:3));
        end
        
        % 找到最小距离的索引
        [~, index] = min(dists);
        
        % 处理边界情况
        if index == 1
            warning('最小距离索引位于普朗克表的最低边界，可能产生不可预测的结果!');
            index = 2;
        elseif index == size(table, 1)
            warning('最小距离索引位于普朗克表的最高边界，可能产生不可预测的结果!');
            index = index - 1;
        end
        
        % 提取相邻三点的数据
        p_prev = table(index-1, :);
        p_cur = table(index, :);
        p_next = table(index+1, :);
        
        % 构建三点数据矩阵
        table_points = [p_prev; p_cur; p_next];
        
        % 提取温度和距离
        Tip = table_points(1, 1); uip = table_points(1, 2); vip = table_points(1, 3); dip = dists(index-1);
        Ti = table_points(2, 1); ui = table_points(2, 2); vi = table_points(2, 3); di = dists(index);
        Tin = table_points(3, 1); uin = table_points(3, 2); vin = table_points(3, 3); din = dists(index+1);
        
        % 三角解法
        l = hypot(uin - uip, vin - vip); % 计算边长
        x = (dip^2 - din^2 + l^2) / (2 * l); % 计算投影长度
        T_t = Tip + (Tin - Tip) * (x / l); % 线性插值温度
        
        vtx = vip + (vin - vip) * (x / l); % 计算投影点的v坐标
        sign = sign(uv_i(2) - vtx); % 确定符号
        D_uv_t = sqrt(dip^2 - x^2) * sign; % 计算Δuv
        
        % 抛物线解法
        X = (Tin - Ti) * (Tip - Tin) * (Ti - Tip);
        a = (Tip * (din - di) + Ti * (dip - din) + Tin * (di - dip)) / X;
        b = (-(Tip^2 * (din - di) + Ti^2 * (dip - din) + Tin^2 * (di - dip))) / X;
        c = (-(dip * (Tin - Ti) * Ti * Tin + di * (Tip - Tin) * Tip * Tin + din * (Ti - Tip) * Tip * Ti)) / X;
        
        T_p = -b / (2 * a); % 抛物线顶点温度
        D_uv_p = (a * T_p^2 + b * T_p + c) * sign; % 抛物线顶点Δuv
        
        % 根据Δuv_t的大小选择解法
        if abs(D_uv_t) >= 0.002
            cct(i) = T_p;
            D_uv(i) = D_uv_p;
        else
            cct(i) = T_t;
            D_uv(i) = D_uv_t;
        end
    end
end

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

function uv = CCT_to_uv_Planck1900(cct, cmfs)
% CCT_to_uv_Planck1900 计算普朗克辐射体的uv坐标(简化实现)
%   参数:
%       cct - 色温值
%       cmfs - 颜色匹配函数
%   返回:
%       uv - uv色度坐标 [1×2] 向量

    % 注意: 此为简化实现，实际应使用精确的普朗克辐射体计算
    % 这里使用近似公式以便示例

    T = cct;
    if T < 5000
        x = -0.2661239e9/T^3 -0.2343589e6/T^2 +0.8776956e3/T +0.179910;
    else
        x = -3.0258469e9/T^3 +2.1070379e6/T^2 +0.2226347e3/T +0.240390;
    end
    y = -3.000*x^2 +2.870*x -0.275;
    
    % 转换xy到uv
    u = 4*x / (-2*x + 12*y + 3);
    v = 6*y / (-2*x + 12*y + 3);
    
    uv = [u, v];
end

function cmfs = load_cie_1931_2degree()
% load_cie_1931_2degree 加载CIE 1931 2°观察者颜色匹配函数(简化实现)
%   返回:
%       cmfs - 颜色匹配函数结构(简化表示)

    % 注意: 此为简化实现，实际应加载完整的CMF数据
    cmfs = struct('lambda', [380:780], 'x', zeros(401, 1), 'y', zeros(401, 1), 'z', zeros(401, 1));
    % 这里应填充实际的CIE 1931 2° CMF数据
    % 简化起见，使用空矩阵，实际应用中需替换为真实数据
end