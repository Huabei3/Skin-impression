function [model, performance] = forward_mapping_model(emotion_vectors, cielab_values, regression_type)
    % 正向映射模型：从情感词汇语义向量预测肤色CIELAB值
    % 输入：
    %   emotion_vectors: N×D矩阵，N个情感词汇的D维语义向量
    %   cielab_values: N×3矩阵，对应的CIELAB值(L*, a*, b*)
    %   regression_type: 字符串，指定回归类型，可选'ridge'、'pls'、'krr'、'gpr'
    % 输出：
    %   model: 训练好的模型
    %   performance: 模型性能指标，包括平均CIEDE2000色差值和R²
    
    % 默认参数设置
    if nargin < 3
        regression_type = 'ridge';  % 默认使用岭回归
    end
    
    % 数据预处理：标准化输入特征
    [X, mu_X, sigma_X] = zscore(emotion_vectors);  % 语义向量标准化
    Y = cielab_values;  % CIELAB值保持原始范围
    
    % 交叉验证划分训练集和测试集(80%训练，20%测试)
    rng(42);  % 设置随机种子，保证结果可重复
    N = size(X, 1);
    idx = randperm(N);
    train_idx = idx(1:round(0.8*N));
    test_idx = idx(round(0.8*N)+1:end);
    
    X_train = X(train_idx, :);
    Y_train = Y(train_idx, :);
    X_test = X(test_idx, :);
    Y_test = Y(test_idx, :);
    
    % 训练模型
    switch lower(regression_type)
        case 'ridge'
            % 岭回归
            lambda = 10.^linspace(-3, 3, 20);  % 正则化参数候选值
            cv_model = fitrridge(X_train, Y_train, 'Lambda', lambda, 'CV', 5);
            [~, best_idx] = min(cv_model.CVLoss);
            model = fitrridge(X_train, Y_train, 'Lambda', lambda(best_idx));
            
        case 'pls'
            % 偏最小二乘回归
            ncomps = 1:min(size(X_train,2), 10);  % 主成分数量候选
            cv_loss = zeros(length(ncomps), 1);
            
            for i = 1:length(ncomps)
                pls_model = fitpls(X_train, Y_train, 'NumComponents', ncomps(i));
                cv_loss(i) = kfoldLoss(crossval(pls_model, 'KFold', 5));
            end
            [~, best_idx] = min(cv_loss);
            model = fitpls(X_train, Y_train, 'NumComponents', ncomps(best_idx));
            
        case 'krr'
            % 核岭回归
            sigma = 10.^linspace(-2, 2, 10);  % 核宽度参数
            lambda = 10.^linspace(-4, 0, 10); % 正则化参数
            best_loss = Inf;
            best_sigma = 1;
            best_lambda = 0.01;
            
            % 网格搜索最优参数
            for s = sigma
                for l = lambda
                    krr_model = fitrkernel(X_train, Y_train, 'KernelFunction', 'RBF', ...
                        'KernelScale', s, 'Lambda', l);
                    loss = kfoldLoss(crossval(krr_model, 'KFold', 5));
                    if loss < best_loss
                        best_loss = loss;
                        best_sigma = s;
                        best_lambda = l;
                    end
                end
            end
            model = fitrkernel(X_train, Y_train, 'KernelFunction', 'RBF', ...
                'KernelScale', best_sigma, 'Lambda', best_lambda);
            
        case 'gpr'
            % 高斯过程回归
            model = fitrgp(X_train, Y_train, 'KernelFunction', 'ardsquaredexponential', ...
                'FitMethod', 'exact', 'PredictMethod', 'exact', 'CV', 5);
            
        otherwise
            error('不支持的回归类型，请选择''ridge''、''pls''、''krr''或''gpr''');
    end
    
    % 模型预测
    Y_pred = predict(model, X_test);
    
    % 性能评估
    % 1. 计算平均CIEDE2000色差值
    deltaE = zeros(size(Y_test, 1), 1);
    for i = 1:size(Y_test, 1)
        deltaE(i) = deltaE2000(Y_test(i,:), Y_pred(i,:));
    end
    performance.mean_deltaE = mean(deltaE);
    
    % 2. 计算R²决定系数
    performance.R2 = [1 - sum((Y_test(:,1) - Y_pred(:,1)).^2)/sum((Y_test(:,1) - mean(Y_test(:,1))).^2);
                      1 - sum((Y_test(:,2) - Y_pred(:,2)).^2)/sum((Y_test(:,2) - mean(Y_test(:,2))).^2);
                      1 - sum((Y_test(:,3) - Y_pred(:,3)).^2)/sum((Y_test(:,3) - mean(Y_test(:,3))).^2)];
    
    % 存储预处理参数
    model.mu_X = mu_X;
    model.sigma_X = sigma_X;
    model.regression_type = regression_type;
    
    % 显示结果
    fprintf('回归模型: %s\n', regression_type);
    fprintf('平均CIEDE2000色差值: %.4f\n', performance.mean_deltaE);
    fprintf('L*通道R²: %.4f\n', performance.R2(1));
    fprintf('a*通道R²: %.4f\n', performance.R2(2));
    fprintf('b*通道R²: %.4f\n', performance.R2(3));
end

% 辅助函数：计算CIEDE2000色差值
function deltaE = ciede2000(Lab1, Lab2)
    % 输入: Lab1和Lab2为1×3向量，分别表示两个颜色的CIELAB值
    % 输出: 两个颜色之间的CIEDE2000色差值
    
    L1 = Lab1(1); a1 = Lab1(2); b1 = Lab1(3);
    L2 = Lab2(1); a2 = Lab2(2); b2 = Lab2(3);
    
    % 常量定义
    kL = 1; kC = 1; kH = 1;
    
    % 计算CIEDE2000公式所需的各项参数
    L_bar = (L1 + L2) / 2;
    C1 = sqrt(a1^2 + b1^2);
    C2 = sqrt(a2^2 + b2^2);
    C_bar = (C1 + C2) / 2;
    
    G = (1 - sqrt(C_bar^7 / (C_bar^7 + 25^7))) / 2;
    a1_prime = a1 * (1 + G);
    a2_prime = a2 * (1 + G);
    
    C1_prime = sqrt(a1_prime^2 + b1^2);
    C2_prime = sqrt(a2_prime^2 + b2^2);
    C_bar_prime = (C1_prime + C2_prime) / 2;
    
    % 计算色相角
    h1_prime = atan2(b1, a1_prime) * 180 / pi;
    h2_prime = atan2(b2, a2_prime) * 180 / pi;
    h1_prime = h1_prime + (h1_prime < 0) * 360;
    h2_prime = h2_prime + (h2_prime < 0) * 360;
    
    % 计算色相差
    if abs(h1_prime - h2_prime) <= 180
        delta_h_prime = h2_prime - h1_prime;
    else
        delta_h_prime = (h2_prime - h1_prime) - 360 * sign(h2_prime - h1_prime);
    end
    
    delta_L_prime = L2 - L1;
    delta_C_prime = C2_prime - C1_prime;
    delta_H_prime = 2 * sqrt(C1_prime * C2_prime) * sin(delta_h_prime * pi / 360);
    
    % 计算加权函数
    L_bar_prime = (L1 + L2) / 2;
    C_bar_prime = (C1_prime + C2_prime) / 2;
    
    % 计算平均色相角
    if abs(h1_prime - h2_prime) > 180
        h_bar_prime = (h1_prime + h2_prime + 360) / 2;
    else
        h_bar_prime = (h1_prime + h2_prime) / 2;
    end
    
    T = 1 - 0.17 * cosd(h_bar_prime - 30) + 0.24 * cosd(2 * h_bar_prime) ...
        + 0.32 * cosd(3 * h_bar_prime + 6) - 0.2 * cosd(4 * h_bar_prime - 63);
    
    % 计算各项权重因子
    SL = 1 + (0.015 * (L_bar_prime - 50)^2) / sqrt(20 + (L_bar_prime - 50)^2);
    SC = 1 + 0.045 * C_bar_prime;
    SH = 1 + 0.015 * C_bar_prime * T;
    
    % 计算旋转因子
    RT = -2 * sqrt(C_bar_prime^7 / (C_bar_prime^7 + 25^7)) * sind(60 * exp(-((h_bar_prime - 275)/25)^2));
    
    % 计算最终的CIEDE2000色差值
    deltaE = sqrt( ...
        (delta_L_prime / (kL * SL))^2 + ...
        (delta_C_prime / (kC * SC))^2 + ...
        (delta_H_prime / (kH * SH))^2 + ...
        RT * (delta_C_prime / (kC * SC)) * (delta_H_prime / (kH * SH)) ...
    );
end
