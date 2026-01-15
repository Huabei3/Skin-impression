clc;clear;
xyz_small = readmatrix("brightness-color-patch-2024-05-26-16.csv");
xyz_large = readmatrix('brightness-color-patch-large-2024-05-26-16.csv');

CCT_small = zeros(20, 1);
CCT_large = zeros(20, 1);
[CCT_out,duv_out,S_out] = XYZ2CCT(xyz_small(:, 1:3));
[CCT_out0,duv_out,S_out] = XYZ2CCT(xyz_large(:, 1:3));
x = 5:5:100;
% hold on 
% plot(x, CCT_out, '-.');
% plot(x, CCT_out0, '-.');
% axis([5, 100, 6500, 7800])
% xlabel('Brightness(%)')
% ylabel('CCT(K)')
% line([0, 100], [7400, 7400], linewidth=1, color='k')


hold on 
plot(x, xyz_small(:,2), '-.');
plot(x, xyz_large(:,2), '-.');
axis([5, 100, 0, 1000])
xlabel('Brightness(%)')
ylabel('Luminance(cd/m^2)')
% line([0, 1000], [7400, 7400], linewidth=1, color='k')
legend('small', 'large', Location='southeast')


% Gamma拟合
ft = fittype('a*x^b + c'); % Gamma函数形式
options = fitoptions('Method', 'NonlinearLeastSquares', 'StartPoint', [1, 1, 0]);

% 拟合xyz_small数据
[fitresult_small, gof_small] = fit(x', xyz_small(:,2), ft, options);

% 拟合xyz_large数据
[fitresult_large, gof_large] = fit(x', xyz_large(:,2), ft, options);

% 手动生成拟合曲线
x_fit = linspace(min(x), max(x), 100);
y_fit_small = feval(fitresult_small, x_fit);
y_fit_large = feval(fitresult_large, x_fit);

% 绘制拟合结果
plot(x_fit, y_fit_small, 'r--', 'DisplayName', 'small fit');
plot(x_fit, y_fit_large, 'b--', 'DisplayName', 'large fit');

% 设置图形属性
axis([5, 100, 0, 1000]);
xlabel('Brightness(%)');
ylabel('Luminance(cd/m^2)');
legend('show', 'Location', 'southeast');

% 显示拟合参数
disp('Gamma Fit Parameters for Small:');
disp(fitresult_small);

disp('Gamma Fit Parameters for Large:');
disp(fitresult_large);

hold off;

% 计算Luminance = 200时的Brightness percentage
target_luminance = 530;

% 定义小尺寸显示屏亮度与百分比的关系函数
small_fit_func = @(b) fitresult_small.a * b^fitresult_small.b + fitresult_small.c - target_luminance;

% 使用fzero寻找使亮度为200的Brightness percentage
brightness_small = fzero(small_fit_func, [min(x), max(x)]);

% 定义大尺寸显示屏亮度与百分比的关系函数
large_fit_func = @(b) fitresult_large.a * b^fitresult_large.b + fitresult_large.c - target_luminance;

% 使用fzero寻找使亮度为200的Brightness percentage
brightness_large = fzero(large_fit_func, [min(x), max(x)]);

% 显示结果
fprintf('Brightness percentage for small screen at Luminance = 500: %.2f%%\n', brightness_small);
fprintf('Brightness percentage for large screen at Luminance = 500: %.2f%%\n', brightness_large);