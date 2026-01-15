function [center,mu,chi2_val,List,covariance_matrix,covariance_matrix_r] = fit95ellip_my(Lab, alpha, dof)
    % Lab: 输入的样本数据，Lab(:,1)为L通道，Lab(:,2)为a通道，Lab(:,3)为b通道
    % alpha: 显著性水平，默认 0.05 表示 95% 置信区间
    % dof: 自由度，2表示拟合二维椭圆，3表示拟合三维椭球
    
    % 计算 L,a,b 数据
    L = Lab(:, 1);  % L 通道
    a = Lab(:, 2);  % a 通道
    b = Lab(:, 3);  % b 通道
    
    % 1. 计算样本均值
    center(1) = mean(L);
    center(2) = mean(a);
    center(3) = mean(b);
    
    % 2. 计算样本协方差矩阵
    if dof == 2
        % 仅使用 a 和 b
        data = [a, b];
        covariance_matrix = cov(data);
    elseif dof == 3
        % 使用 L, a 和 b
        data = [L, a, b];
        covariance_matrix = cov(data);

    else
        error('Invalid dof. Please use dof = 2 for ellipse or dof = 3 for ellipsoid.');
    end
    
    % 3. 计算卡方分布的临界值 r (根据自由度 dof 计算)
    chi2_val = chi2inv(1 - alpha, dof);  % 卡方分布临界值
    
    % 4. 计算 mu(0) 到 mu(5)
    % 根据给定公式计算协方差参数 mu(0) 到 mu(5)
    if dof == 2
        % 计算二维的 mu 参数（仅关注 a 和 b）
        covariance_matrix_r=inv(covariance_matrix);
        % 方差
        mu(1) = covariance_matrix_r(1, 1);  % a 的方差
        mu(2) = covariance_matrix_r(1, 2);  % a 与 b 的协方差
        mu(3) = covariance_matrix_r(2, 2);  % b 的方差

    elseif dof == 3
        
        % 计算 mu(0) 到 mu(5)
        covariance_matrix_r=inv(covariance_matrix);
        mu(1) = covariance_matrix_r(1, 1);  % L 对应的方差
        mu(2) = covariance_matrix_r(1, 2);  % L 与 a 的协方差
        mu(3) = covariance_matrix_r(1, 3);  % L 与 b 的协方差
        mu(4) = covariance_matrix_r(2, 2);  % a 对应的方差
        mu(5) = covariance_matrix_r(2, 3);  % a 与 b 的协方差
        mu(6) = covariance_matrix_r(3, 3);  % b 对应的方差
    end
    
    % 5. 计算椭圆或椭球的参数（长轴、短轴方向及比例）
    [eigvecs, eigvals] = eig(covariance_matrix);  % 特征向量和特征值
    axes_lengths = sqrt(chi2_val * diag(eigvals));  % 计算长轴和短轴

    % 6. 计算旋转角度 (计算特征向量与标准坐标轴的夹角)
    rotation_angles = zeros(1, 3);  % 初始化旋转角度
    
    if dof == 2
        % 对二维椭圆，计算a与b方向的旋转角度
        % 特征向量对应二维空间中的主轴方向
        rotation_angles(1) = atan2(eigvecs(2, 1), eigvecs(1, 1));  % 第一主轴相对于x轴的旋转角度
        rotation_angles(2) = atan2(eigvecs(2, 2), eigvecs(1, 2));  % 第二主轴相对于y轴的旋转角度
    elseif dof == 3
        % 对三维椭球，计算L、a、b三个方向的旋转角度
        % 特征向量对应三维空间中的主轴方向
        rotation_angles(1) = atan2(eigvecs(3, 1), eigvecs(1, 1));  % L方向相对于x轴的旋转角度
        rotation_angles(2) = atan2(eigvecs(3, 2), eigvecs(1, 2));  % a方向相对于y轴的旋转角度
        rotation_angles(3) = atan2(eigvecs(3, 3), eigvecs(1, 3));  % b方向相对于z轴的旋转角度
    end

    % 7. 绘制椭圆或椭球
    if dof == 2
        % 绘制二维椭圆
        theta = linspace(0, 2 * pi, 100);  % 角度参数，用于绘制椭圆
        ellipse_points = [cos(theta); sin(theta)];  % 单位圆的点

        % 旋转并缩放单位圆，以得到椭圆
        ellipse_points = eigvecs * diag(axes_lengths) * ellipse_points;

        % 绘制椭圆
        % hold on;
        % plot(center(2) + ellipse_points(1,:), center(3) + ellipse_points(2,:), 'r-', 'LineWidth', 2);
        % plot(a, b, 'bo', 'MarkerSize', 5);  % 绘制样本点
        % plot(center(2), center(3), 'kx', 'MarkerSize', 10, 'LineWidth', 2);  % 绘制均值点
        % axis equal;
        % xlabel('a');
        % ylabel('b');
        % title('Confidence Ellipse (95%)');
    elseif dof == 3
        % 绘制三维椭球
        [phi, theta] = meshgrid(linspace(0, 2*pi, 100), linspace(0, pi, 50));  % 球面参数
        x = sin(theta) .* cos(phi);  % 球面坐标
        y = sin(theta) .* sin(phi);  % 球面坐标
        z = cos(theta);  % 球面坐标

        % 旋转并缩放单位球面，以得到椭球
        ellipsoid_points = [z(:),x(:), y(:) ] * diag(axes_lengths);

        % 将椭球中心平移到均值位置
        ellipsoid_points = ellipsoid_points + [center(1),center(2), center(3) ];
        % 
        % % 绘制三维椭球
        % figure();
        % hold on;
        % scatter3( a, b,L, 50, 'bo');  % 绘制样本数据点
        % plot3( center(2), center(3),center(1), 'kx', 'MarkerSize', 10, 'LineWidth', 2);  % 绘制均值点
        % 
        % % 绘制椭球
        % surf(reshape(ellipsoid_points(:, 2), 100, 50), ...
        %     reshape(ellipsoid_points(:, 3), 100, 50), ...
        %     reshape(ellipsoid_points(:, 1), 100, 50));
        % axis equal;
        % xlabel('a');
        % ylabel('b');
        % zlabel('L');
        % title('Confidence Ellipsoid (95%)');


    else
        error('Invalid dof. Please use dof = 2 for ellipse or dof = 3 for ellipsoid.');
    end
    %生成List
    C=sqrt(center(2).^2+center(3).^2);
    h=atan2d(center(3),center(2));
    List=[center,axes_lengths',rotation_angles,C,h];
    grid on;
    hold off;
end
