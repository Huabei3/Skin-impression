function plot_scatter_with_45line(x, y, output_file)
% PLOT_SCATTER_WITH_45LINE 绘制散点图并添加45°参考线，并保存图片
%   输入参数:
%   x - 第一列数据
%   y - 第二列数据
%   output_file - 输出文件名（可包含路径）

    % 创建图形
    figure;
    
    % 绘制散点图
    scatter(x, y, 'filled', 'SizeData', 50);
    hold on;
    
    % 绘制45°线
    plot([0, 1], [0, 1], 'r--', 'LineWidth', 1.5);
    
    % 设置图形属性
    axis equal;
    grid on;
    
    % 设置坐标轴范围
    xlim([0, 1]);
    ylim([0, 1]);
    
    % 设置刻度间隔
    xticks(0:0.1:1);
    yticks(0:0.1:1);
    
    % 添加标签和标题
    xlabel('visual p');
    ylabel('predicted p');
    
    % title('散点图与45°参考线');
    
    % 添加图例
    % legend('数据点', '45°参考线', 'Location', 'best');
    [~, name, ~] = fileparts(output_file);
    title(name);
    
    % 保存图片
    exportgraphics(gcf, output_file, 'Resolution', 300);
    
    close(gcf);
    
end