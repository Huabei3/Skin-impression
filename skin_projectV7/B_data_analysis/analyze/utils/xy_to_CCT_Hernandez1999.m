function cct = xy_to_CCT_Hernandez1999(xy)
% xy_to_CCT_Hernandez1999 使用Hernandez-Andres等(1999)方法从CIE xy坐标计算相关色温
%   参数:
%       xy - CIE xy色度坐标 [N×2] 矩阵，每行包含x和y值
%   返回:
%       cct - 计算得到的相关色温值 [N×1] 向量

    % 确保输入为二维矩阵
    xy = reshape(xy, [], 2);
    [n, ~] = size(xy);
    cct = zeros(n, 1);
    
    % 提取x和y分量
    x = xy(:, 1);
    y = xy(:, 2);
    
    % 计算中间变量n
    n = (x - 0.3366) ./ (y - 0.1735);
    
    % 计算初始CCT值
    cct = -949.86315 + 6253.80338 * exp(-n / 0.92159) + ...
          28.70599 * exp(-n / 0.20039) + 0.00004 * exp(-n / 0.07125);
    
    % 处理高色温情况
    highCCTIdx = cct > 50000;
    if any(highCCTIdx)
        n_high = (x(highCCTIdx) - 0.3356) ./ (y(highCCTIdx) - 0.1691);
        cct(highCCTIdx) = 36284.48953 + 0.00228 * exp(-n_high / 0.07861) + ...
                         5.4535e-36 * exp(-n_high / 0.01543);
    end
end

