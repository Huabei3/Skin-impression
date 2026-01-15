% 定义函数 y
function [target_a1,target_b1,target_a2,target_b2] = calculate_target_ab( par,target_score,constrain)


    % 生成一系列 data2 的值
    data2_values = par(4) + (-50:0.01:50);  % 假设 data2 在 [0, 10] 范围内
    if strcmp(constrain,"hue")
        data3_values = (par(5) / par(4)) * data2_values;  % 根据条件 data3 / data32 = par(5) / par(4)
    elseif strcmp(constrain,"chroma")
        % data3_values=-(par(4)/par(5)).*(data2_values-par(4))+par(5);
        data3_values=sqrt((par(4).^2+par(5).^2)-data2_values.^2);
    end
    % 计算每个点的 y 值
    y_center=calculate_y(par(4), par(5), par);
    target_y=target_score*y_center;
    y_values = arrayfun(@(data2, data3) calculate_y(data2, data3, par), data2_values, data3_values);
    
    
    % 区域 1: data2_values < par(4) 且 data3_values < par(5)
    region1_mask = (data2_values < par(4)) ;
    y_values_region1 = y_values(region1_mask);
    data2_values_region1 = data2_values(region1_mask);
    data3_values_region1 = data3_values(region1_mask);
    
    [~, idx1] = min(abs(y_values_region1 - target_y));  % 找到最接近的索引
    target_a1 = data2_values_region1(idx1);
    target_b1 = data3_values_region1(idx1);
    
    % 区域 2: data2_values > par(4) 且 data3_values > par(5)
    region2_mask = (data2_values > par(4));
    y_values_region2 = y_values(region2_mask);
    data2_values_region2 = data2_values(region2_mask);
    data3_values_region2 = data3_values(region2_mask);
    
    [~, idx2] = min(abs(y_values_region2 - target_y));  % 找到最接近的索引
    target_a2 = data2_values_region2(idx2);
    target_b2 = data3_values_region2(idx2);

end





