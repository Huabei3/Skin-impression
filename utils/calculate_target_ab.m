% calculate_target_ab - 计算满足特定颜色分数条件的两对a*b*坐标值
%
% 该函数通过在特定约束条件下搜索，找到两对a*b*坐标值，使得对应的颜色分数接近目标分数。
% 支持色相(hue)、彩度(chroma)和45度直线(45)三种约束条件，以及绝对(abs)和相对(rela)两种分数类型。
%
% 语法:
%   [target_a1,target_b1,target_a2,target_b2] = calculate_target_ab(par,target_score,constrain,score_type)
%
% 输入参数:
%   par - 包含模型参数的向量，至少包含5个元素，其中par(4)和par(5)通常表示a*和b*坐标
%   target_score - 目标颜色分数值
%   constrain - 约束条件类型，字符串，可选值为:
%               'hue' - 沿色相方向搜索
%               'chroma' - 沿彩度圆搜索
%               '45' - 沿45度直线搜索
%   score_type - 分数类型，字符串，可选值为:
%                'abs' - 绝对分数
%                'rela' - 相对分数(相对于中心点分数)
%
% 输出参数:
%   target_a1,target_b1 - 第一对满足条件的a*和b*坐标值
%   target_a2,target_b2 - 第二对满足条件的a*和b*坐标值
%                         如果无法找到两个解，对应的输出将为NaN
%
% 算法说明:
%   1. 根据约束条件生成a*b*平面上的搜索路径
%   2. 计算路径上每个点的颜色分数
%   3. 找到分数值接近目标分数的两个点
%
% 示例:
%   par = [1 2 3 4 5];
%   target_score = 0.8;
%   [a1,b1,a2,b2] = calculate_target_ab(par,target_score,'hue','rela');
%
% 依赖函数:
%   calculate_y - 计算颜色分数的函数，需提前定义
%
% 注意事项:
%   - 函数依赖于外部定义的calculate_y函数
%   - 搜索范围和精度由代码中的步长参数决定(如-50:0.01:50)
%   - 当无法找到两个解时，函数返回NaN
%
function [target_a1,target_b1,target_a2,target_b2] = calculate_target_ab( par,target_score,constrain,score_type)
    if target_score == 1
        target_a1=par(4);target_b1=par(5);target_a2=NaN;target_b2=NaN;
    else
        % 根据约束条件生成a*b*平面上的搜索路径
        if strcmp(constrain,"hue")
            % 沿色相方向搜索：在a*方向上从par(4)-50到par(4)+50，步长0.01
            % b*值根据a*值和色相比例计算
            data2_values = par(4) + (-50:0.01:50);  
            data3_values = (par(5) / par(4)) * data2_values;  
        elseif strcmp(constrain,"chroma")
            % 沿彩度圆搜索：在a*b*平面上以原点为中心，以par(4)和par(5)确定的半径画圆
            theta = linspace(0, 2*pi, 10000);
            R=sqrt((par(4).^2+par(5).^2));
            data2_values=R*cos(theta);
            data3_values=R*sin(theta);
        elseif strcmp(constrain,"45") 
            % 沿45度直线搜索：a*和b*值相等
            data2_values=par(4) + (-50:0.01:50);
            data3_values=data2_values;
        end
    
        % 过滤掉复数解，确保只保留实数坐标
        valid_mask = (imag(data2_values) == 0) & (imag(data3_values) == 0); 
        data2_values = data2_values(valid_mask);
        data3_values = data3_values(valid_mask);
    
        % 根据分数类型确定目标分数值
        if strcmp(score_type,"abs")
            % 绝对分数：直接使用目标分数
            target_y=target_score;
        elseif strcmp(score_type,"rela")
            % 相对分数：相对于中心点的分数
            y_center=calculate_y(par(4), par(5), par);
            target_y=target_score*y_center;
        end
        
        % 计算搜索路径上每个点的颜色分数
        y_values = arrayfun(@(data2, data3) calculate_y(data2, data3, par), data2_values, data3_values);
    
        % 寻找分数值接近目标分数的点
        % 通过检测分数值与目标值差异的符号变化来确定零点附近的点
        differences = y_values - target_y;
        sign_changes = [0; diff(sign(differences))'];  % 计算符号变化
        change_indices = find(sign_changes ~= 0);  % 找到符号变化的索引
        
        % 调整索引以选择更接近目标值的点
        for i_change=1:size(change_indices,1)
            if abs(y_values(change_indices(i_change)-1)-target_y)<abs(y_values(change_indices(i_change))-target_y)
                change_indices(i_change)=change_indices(i_change)-1;
            end
        end
        
        % 提取两个根
        if length(change_indices) >= 2
            % 第一个根
            idx1 = change_indices(1);
            target_a1 = data2_values(idx1);
            target_b1 = data3_values(idx1);
    
            % 第二个根
            idx2 = change_indices(2);
            target_a2 = data2_values(idx2);
            target_b2 = data3_values(idx2);
        else
            % 如果找不到两个解，返回NaN
            target_a1=NaN;target_b1=NaN;target_a2=NaN;target_b2=NaN;
        end
    end
end