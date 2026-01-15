function [CCT] = xy_to_CCT_Kang2002(xy)
% XY_TO_CCT_KANG2002 计算给定CIE xy色度坐标的相关色温(CCT)
% 使用Kang et al. (2002)方法
% 输入:
%   xy - CIE xy色度坐标 [x, y]
% 输出:
%   CCT - 相关色温，单位为开尔文(K)

    % 初始化优化设置
    % options = optimset('Display', 'off', 'Algorithm', 'Nelder-Mead', 'TolX', 1e-10);
    options = optimset('Display', 'off', 'Algorithm', 'quasi-newton', 'TolX', 1e-10);
    
    % 如果输入是多行，则逐行处理
    if size(xy, 1) > 1
        CCT = zeros(size(xy, 1), 1);
        for i = 1:size(xy, 1)
            CCT(i) = fminsearch(@(cct) objective_function(cct, xy(i,:)), 6500, options);
        end
    else
        % 单行输入
        CCT = fminsearch(@(cct) objective_function(cct, xy), 6500, options);
    end
    
    function [obj] = objective_function(cct, target_xy)
        % 目标函数：计算当前CCT对应的xy与目标xy之间的欧氏距离
        current_xy = CCT_to_xy_Kang2002(cct);
        obj = norm(current_xy - target_xy);
    end
end

