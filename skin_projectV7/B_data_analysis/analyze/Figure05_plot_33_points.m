% 读取Excel文件中的数据
% 假设Excel文件名为 'data.xlsx'，数据在Sheet1中
filename = 'documents\points_added_33.xlsx';  % 修改为您的文件名
sheet = 1;  % 或者使用工作表名称，如 'Sheet1'

% 读取Excel文件中的两列数据
% 这里假设读取A列和B列，您可以根据实际情况调整列范围
data = xlsread(filename, sheet, 'A:B');

% 提取两列数据
x_data = data(:, 1);  % 第一列作为x数据
y_data = data(:, 2);  % 第二列作为y数据

% 创建图形窗口
figure('Position', [100, 100, 800, 600]);  % 设置图形窗口大小

% 绘制散点图
scatter(x_data, y_data, 'filled', 'MarkerFaceColor', 'b', 'MarkerEdgeColor', 'k', 'SizeData', 50);

% 设置坐标轴标签和标题
xlabel('$\Delta$\textit{a*}', 'Interpreter', 'latex', 'FontSize', 12*2);
ylabel('$\Delta$\textit{b*}', 'Interpreter', 'latex', 'FontSize', 12*2);
% title('散点图', 'FontSize', 14*2, 'FontWeight', 'bold');

% 设置坐标轴范围
lim_max = 25;
lim_min = -25;

% 添加 x=0 和 y=0 的轴
hold on;
line([0, 0], [lim_min, lim_max], 'Color', 'k', 'LineStyle', '--', 'LineWidth', 1.5); % x=0
line([lim_min, lim_max], [0, 0], 'Color', 'k', 'LineStyle', '--', 'LineWidth', 1.5); % y=0

% 添加 45 度线
href = refline(1, 0);  % 创建参考线对象
set(href, 'Color', 'k', 'LineStyle', '--', 'LineWidth', 1.5);  % 设置属性

% 设置图形属性
grid on;
grid minor;
axis equal;
xlim([lim_min, lim_max]);
ylim([lim_min, lim_max]);

% 设置坐标轴刻度字体
% set(gca, 'FontSize', 12, 'FontWeight', 'bold');

% 添加图例（可选）
% legend('数据点', 'Location', 'best');

% 如果需要保存图形
exportgraphics(gcf,"documents\points_added_33.jpg","Resolution",150);
% saveas(gcf, 'scatter_plot.png');
% print(gcf, 'scatter_plot', '-dpng', '-r300');

hold off;