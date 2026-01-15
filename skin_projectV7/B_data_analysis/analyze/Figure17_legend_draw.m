function create_legend( output_folder,legend_type)
    % 输入参数：
    % tables - 字符串数组，包含图例文本
    % output_folder - 输出文件夹路径
    if strcmp(legend_type,"nation")||strcmp(legend_type,"gender")||strcmp(legend_type,"lightness")
        tables=["Asian","Caucasian","South Asian","African"];
    elseif strcmp(legend_type,"skin_Caucasian")
        tables = ["m01", "f01", "m02", "f02","m03", "f03"];  
    elseif strcmp(legend_type,"skin_Asian")
        tables = ["m04", "f04", "m05", "f05","m06", "f06"];  
    elseif strcmp(legend_type,"skin_South_Asian")
        tables = ["m07", "f07", "m08", "f08"];  
    elseif strcmp(legend_type,"skin_African")
        tables = ["m09", "f09", "m10", "f10"];  
    elseif strcmp(legend_type,"CT")
        tables = ["3000k", "4000k", "5000k", "6000k","6500k","7000k","8000k"];  
    elseif strcmp(legend_type,"optimized_D")
        % tables = ["this experiment", "cherry", "zhai", "summer","grace"];
        tables = ["this experiment", "Cao et al.", "Zhai et al.", "Peng et al.","Zhu et al."];
    elseif strcmp(legend_type,"attr")||strcmp(legend_type,"attr_black")
    % tables =  ["Preference", "Attractiveness", "Feminine", "Cooperative", ...
    %     "Youth"];
        tables = ["Preference", "Attractiveness", "Feminine", "Cooperative", ...
    "Youth", "Healthy", "Fidelity", "Harmony", "Fair", "Ruddy"];        
    elseif strcmp(legend_type,"MCDM")||strcmp(legend_type,"attr_MCDM")
        tables = ["Preference", "Attractiveness", "Feminine", "Cooperative", ...
    "Youth", "Healthy",  "Harmony", "Fair", "Ruddy"];
    elseif strcmp(legend_type,"obs")
        tables = ["stranger", "acquaitance","model", "original"];
    elseif strcmp(legend_type,"hml")
        tables = ["high", "medium", "low"];
    elseif strcmp(legend_type,"scenes2")
        tables = ["indoor", "outdoor", "night"];
    elseif strcmp(legend_type,"compare")
        tables = ["Peng et al.", "Cao et al.", "Zeng et al.","Qin et al."];
    elseif strcmp(legend_type,"compare_scene")
        tables = ["indoor", "outdoor", "sunset","night"];
    elseif strcmp(legend_type,"mini attr")

        tables =  ["Preference", "Attractiveness", "Feminine", "Cooperative", ...
        "Youth", "Healthy", "Fidelity","Harmony", "Fair"];
    elseif strcmp(legend_type,"mini model")
        tables = ["f04", "f05", "f06", "m04", "m05", "m06",...
        "f01", "f02", "f03", "m01", "m02", "m03",...
        "f07", "f08","m07", "m08",...
        "f09", "f10","m09", "m10"];
    elseif strcmp(legend_type,"region")
        tables = ["forehead", "cheek", "neck"];
    elseif strcmp(legend_type,"mini scene")
        tables = ["H", "M", "L","rs01","rs02","rs03","rs04","rs05","rs06","rs07", ...
                 "rs08","rs09","rs10","rs11","rs12","rs13","rs14"];
    elseif strcmp(legend_type,"VIVOskin")
        tables=["Asian","Caucasian","South Asian","African"];
    end
    num_colors=length(tables);


    if ~isfolder(output_folder)
        error('output_folder 不是一个有效的文件夹路径');
    end

    % 创建一个新的图形窗口

    figure('Position', [0 0 1200 200]); % 设置图形窗口大小
    hold on;

    % 设置颜色映射
    if strcmp(legend_type,"attr")
        % colors=hsv(length(tables));
        num_attributes = 10;
        hue_values = linspace(0, 1, num_attributes + 1);
        hue_values = hue_values(1:end-1); 
        hsv_matrix = [hue_values', 0.8 * ones(num_attributes, 1), 0.8 * ones(num_attributes, 1)];
        colors = hsv2rgb(hsv_matrix);
    elseif strcmp(legend_type,"MCDM")
        num_attributes = 9;
        hue_values = linspace(0, 1, num_attributes + 1);
        hue_values = hue_values(1:end-1); 
        hsv_matrix = [hue_values', 0.8 * ones(num_attributes, 1), 0.8 * ones(num_attributes, 1)];
        colors = hsv2rgb(hsv_matrix);
    elseif strcmp(legend_type,"hml")
        hue_values = linspace(0, 1, 4 + 1);hue_values = hue_values(1:end-1); 
        hsv_matrix = [hue_values', 0.8 * ones(4, 1), 0.8 * ones(4, 1)];
        colors = hsv2rgb(hsv_matrix);
    elseif strcmp(legend_type,"scenes2")
        n_scenetype=3;
        hue_values = linspace(0, 1, n_scenetype + 1);hue_values = hue_values(1:end-1);
        hsv_matrix = [hue_values', 0.8*ones(n_scenetype, 1),  0.8*ones(n_scenetype, 1)];
        colors = hsv2rgb(hsv_matrix);
    elseif strcmp(legend_type,"compare")
        n_scenetype=6;
        hue_values = linspace(0, 1, n_scenetype + 1);hue_values = hue_values(1:end-1);
        hsv_matrix = [hue_values', 0.8*ones(n_scenetype, 1),  0.8*ones(n_scenetype, 1)];
        colors = hsv2rgb(hsv_matrix);
    elseif strcmp(legend_type,"compare_scene")||strcmp(legend_type,"region")
        n_scenetype=4;
        hue_values = linspace(0, 1, n_scenetype + 1);hue_values = hue_values(1:end-1);
        hsv_matrix = [hue_values', 0.8*ones(n_scenetype, 1),  0.8*ones(n_scenetype, 1)];
        colors = hsv2rgb(hsv_matrix);
    else
        hue_values = linspace(0, 1, length(tables) + 1);hue_values = hue_values(1:end-1); 
        hsv_matrix = [hue_values', 0.8 * ones(length(tables), 1), 0.8 * ones(length(tables), 1)];
        colors = hsv2rgb(hsv_matrix);


    end


%% 绘制圆点和文本
    

if strcmp(legend_type,"obs")
    tables = ["stranger", "acquaitance", "original"];
    num_colors=length(tables);
end
if strcmp(legend_type,"attr")||strcmp(legend_type,"attr_black")||strcmp(legend_type,"attr_MCDM")
    tables =  ["Preference", "Attractiveness", "Feminine", "Cooperative", ...
        "Youth"];
    num_colors=length(tables);
end
for i = 1:num_colors
    if strcmp(legend_type,"obs")&&i==3
        i_used=4;
    else
        i_used=i;
    end
    text_size=15;
    if strcmp(legend_type,"compare")

        scatter(50 + (i - 1) * 500, 50, 100, colors(i+1, :), '^',  'LineWidth', 1);  
        
    elseif strcmp(legend_type,"attr")
        % scatter(50 + (i - 1) * 500, 50,100,  colors(i_used, :),'' ,'filled');
        text(10 + (i - 1) * 500, 50, ...
        num2str(i), 'FontSize', text_size, ...
        'VerticalAlignment', 'middle','Color',colors(i,:), ...
        'FontWeight', 'bold');
    elseif strcmp(legend_type,"attr_black")
        text(10 + (i - 1) * 500, 50, ...
        num2str(i), 'FontSize', text_size, ...
        'VerticalAlignment', 'middle','Color','k', ...
        'FontWeight', 'bold');
    else
        scatter(50 + (i - 1) * 500, 50,200,  colors(i_used, :),'' ,'filled');
    end% 减小圆点大小


    % 添加文本
    % if strcmp(legend_type,"attr")||strcmp(legend_type,"attr_black")
    %     text(50 + (i - 1) * 500 + 40, 50, tables(i), ... % 增加文本的水平偏移量
    %         'HorizontalAlignment', 'left', ...
    %         'VerticalAlignment', 'middle', ...30
    %         'FontSize', text_size, ...
    %         'Color', 'k'); % 设置文本颜色为黑色
    % else
        text(50 + (i - 1) * 500 + 40, 50, tables(i), ... % 增加文本的水平偏移量
        'HorizontalAlignment', 'left', ...
        'VerticalAlignment', 'middle', ...30
        'FontSize', text_size, ...
        'Color', 'k'); % 设置文本颜色为黑色
    % end
end


if strcmp(legend_type,"attr")||strcmp(legend_type,"attr_black")||strcmp(legend_type,"attr_MCDM")
    tables = ["Healthy", "Fidelity", "Harmony", "Fair", "Ruddy"];
    if strcmp(legend_type,"attr_MCDM")
        tables = ["Healthy",  "Harmony", "Fair", "Ruddy"];
    end

    for i = 1:length(tables)
        % 绘制圆点
        if strcmp(legend_type,"attr_black")
            color_used='k';
        else
            color_used=colors(i+5,:);
        end
        if strcmp(legend_type,"attr_MCDM")
            scatter(50 + (i - 1) * 500, 30,200,  colors(i+5, :),'' ,'filled');
        else
            text(10 + (i - 1) * 500, 30, ...
            num2str(i+5), 'FontSize', text_size, ...
            'VerticalAlignment', 'middle','Color',color_used, ...
            'FontWeight', 'bold');
        end

        

        % 添加文本
        text_size=15;
        text(50 + (i - 1) * 500 + 40, 30, tables(i), ... % 增加文本的水平偏移量
            'HorizontalAlignment', 'left', ...
            'VerticalAlignment', 'middle', ...30
            'FontSize', text_size, ...
            'Color', 'k'); % 设置文本颜色为黑色
    end
end
%% 
    % 绘制圆点
    if strcmp(legend_type,"VIVOskin")
        x1=(50 + (num_colors - 1) * 500)/100;
        x2=(50 + (num_colors - 1) * 500)/100*50;
        x3=(50 + (num_colors - 1) * 500)/100*100;
        plot(x1, 30, 'o', 'MarkerSize', 10,'MarkerFaceColor', 'none', 'Color', 'k','LineWidth', 1.5);    
        plot(x3, 30, 'x', 'MarkerSize', 16,'MarkerFaceColor', 'k', 'Color', 'k','LineWidth', 1.5);

        % 添加文本
        text(x1 + 40, 30, "female", ... % 增加文本的水平偏移量
            'HorizontalAlignment', 'left', ...
            'VerticalAlignment', 'middle', ...
            'FontSize', 12, ...
            'Color', 'k'); % 设置文本颜色为黑色
            % 添加文本

        text(x3 + 40, 30, "male", ... % 增加文本的水平偏移量
            'HorizontalAlignment', 'left', ...
            'VerticalAlignment', 'middle', ...
            'FontSize', 12, ...
            'Color', 'k'); % 设置文本颜色为黑色


    elseif strcmp(legend_type,"gender")
        x1=(50 + (num_colors - 1) * 500)/100;
        x2=(50 + (num_colors - 1) * 500)/100*50;
        x3=(50 + (num_colors - 1) * 500)/100*100;
        plot(x1, 30, 'v', 'MarkerSize', 10,'MarkerFaceColor', 'k', 'Color', 'k');    
        plot([x2-100, x2], [30, 30], '-', 'LineWidth', 2, 'Color', 'k');
        plot(x3, 30, 's', 'MarkerSize', 10,'MarkerFaceColor', 'k', 'Color', 'k');
        plot(x1, 10, '^', 'MarkerSize', 10,'MarkerFaceColor', 'k', 'Color', 'k');    
        plot([x2-100, x2], [10, 10], '--', 'LineWidth', 2, 'Color', 'k');
        plot(x3, 10, 's', 'MarkerSize', 10,'MarkerFaceColor', 'k', 'Color', 'k');
        % 添加文本
        text(x1 + 40, 30, "female center", ... % 增加文本的水平偏移量
            'HorizontalAlignment', 'left', ...
            'VerticalAlignment', 'middle', ...
            'FontSize', 12, ...
            'Color', 'k'); % 设置文本颜色为黑色
            % 添加文本
        text(x2 + 40, 30, "female boundary", ... % 增加文本的水平偏移量
            'HorizontalAlignment', 'left', ...
            'VerticalAlignment', 'middle', ...
            'FontSize', 12, ...
            'Color', 'k'); % 设置文本颜色为黑色
        text(x3 + 40, 30, "PMC chart", ... % 增加文本的水平偏移量
            'HorizontalAlignment', 'left', ...
            'VerticalAlignment', 'middle', ...
            'FontSize', 12, ...
            'Color', 'k'); % 设置文本颜色为黑色

        text(x1 + 40, 10, "male center", ... % 增加文本的水平偏移量
            'HorizontalAlignment', 'left', ...
            'VerticalAlignment', 'middle', ...
            'FontSize', 12, ...
            'Color', 'k'); % 设置文本颜色为黑色
            % 添加文本
        text(x2 + 40, 10, "male boundary", ... % 增加文本的水平偏移量
            'HorizontalAlignment', 'left', ...
            'VerticalAlignment', 'middle', ...
            'FontSize', 12, ...
            'Color', 'k'); % 设置文本颜色为黑色
        text(x3 + 40, 10, "scaled PMC chart", ... % 增加文本的水平偏移量
            'HorizontalAlignment', 'left', ...
            'VerticalAlignment', 'middle', ...
            'FontSize', 12, ...
            'Color', 'k'); % 设置文本颜色为黑色
    elseif strcmp(legend_type,"skin_Caucasian")||strcmp(legend_type,"skin_Asian")||strcmp(legend_type,"skin_South_Asian")||strcmp(legend_type,"skin_African")
        x1=(50 + (num_colors - 1) * 500)/100;
        x2=(50 + (num_colors - 1) * 500)/100*50;
        x3=(50 + (num_colors - 1) * 500)/100*100;
        plot(x1, 30, 'o', 'MarkerSize', 15,'MarkerFaceColor', 'k', 'Color',  'k');    
        plot(x2, 30, 's', 'MarkerSize', 15,'MarkerFaceColor', 'k', 'Color',  'k');    
        plot(x3, 30, '^', 'MarkerSize', 15,'MarkerFaceColor', 'k', 'Color', 'k');
        text(x1 + 40, 30, "forehead", ... % 增加文本的水平偏移量
            'HorizontalAlignment', 'left', ...
            'VerticalAlignment', 'middle', ...
            'FontSize', text_size, ...
            'Color', 'k'); % 设置文本颜色为黑色
            % 添加文本
        text(x2 + 40, 30, "cheek", ... % 增加文本的水平偏移量
            'HorizontalAlignment', 'left', ...
            'VerticalAlignment', 'middle', ...
            'FontSize', text_size, ...
            'Color', 'k'); % 设置文本颜色为黑色
            % 添加文本
        text(x3 + 40, 30, "neck", ... % 增加文本的水平偏移量
            'HorizontalAlignment', 'left', ...
            'VerticalAlignment', 'middle', ...
            'FontSize', text_size, ...
            'Color', 'k'); % 设置文本颜色为黑色

    elseif strcmp(legend_type,"compare")
        x1=(50 + (num_colors - 1) * 500)/100;
        x2=(50 + (num_colors - 1) * 500)/100*50;
        x3=(50 + (num_colors - 1) * 500)/100*100;
        plot(x1, 30, 'o', 'MarkerSize', 10,'MarkerFaceColor', colors(1,:), 'Color',  colors(1,:));    
        plot(x3, 30, 's', 'MarkerSize', 10,'MarkerFaceColor', 'm', 'Color', 'm');
        text(x1 + 40, 30, "this experiment", ... % 增加文本的水平偏移量
            'HorizontalAlignment', 'left', ...
            'VerticalAlignment', 'middle', ...
            'FontSize', 12, ...
            'Color', 'k'); % 设置文本颜色为黑色
            % 添加文本

        text(x3 + 40, 30, "PMC chart", ... % 增加文本的水平偏移量
            'HorizontalAlignment', 'left', ...
            'VerticalAlignment', 'middle', ...
            'FontSize', 12, ...
            'Color', 'k'); % 设置文本颜色为黑色
    elseif strcmp(legend_type,"compare_scene")
        x1=(50 + (num_colors - 1) * 500)/100;
        x2=(50 + (num_colors - 1) * 500)/100*50;
        x3=(50 + (num_colors - 1) * 500)/100*100;
        plot(x1, 30, 'o', 'MarkerSize', 10,'MarkerFaceColor', 'k', 'Color', 'k');    
        plot(x2, 30, '^', 'MarkerSize', 10,'MarkerFaceColor', 'k', 'Color', 'k');
        plot(x3, 30, 's', 'MarkerSize', 10,'MarkerFaceColor', 'm', 'Color', 'm');
        text(x1 + 40, 30, "current study", ... % 增加文本的水平偏移量
            'HorizontalAlignment', 'left', ...
            'VerticalAlignment', 'middle', ...
            'FontSize', 15, ...
            'Color', 'k'); % 设置文本颜色为黑色
            % 添加文本
        text(x2 + 40, 30, "previous study", ... % 增加文本的水平偏移量
            'HorizontalAlignment', 'left', ...
            'VerticalAlignment', 'middle', ...
            'FontSize', 15, ...
            'Color', 'k'); % 设置文本颜色为黑色
        text(x3 + 40, 30, "PMC chart", ... % 增加文本的水平偏移量
            'HorizontalAlignment', 'left', ...
            'VerticalAlignment', 'middle', ...
            'FontSize', 15, ...
            'Color', 'k'); % 设置文本颜色为黑色

    elseif strcmp(legend_type,"nation")
        x1=(50 + (num_colors - 1) * 500)/100;
        x2=(50 + (num_colors - 1) * 500)/100*50;
        x3=(50 + (num_colors - 1) * 500)/100*100;
        % plot(x1, 30, 'o', 'MarkerSize', 10,'MarkerFaceColor', 'k', 'Color', 'k');    
        % plot(x2, 30, 's', 'MarkerSize', 10,'MarkerFaceColor', 'k', 'Color', 'k');    
        % plot(x3, 30, 's', 'MarkerSize', 10,'MarkerFaceColor', 'none', 'Color', 'k');
        % text(x1 + 40, 30, "fit center", ... % 增加文本的水平偏移量
        %     'HorizontalAlignment', 'left', ...
        %     'VerticalAlignment', 'middle', ...
        %     'FontSize', 12, ...
        %     'Color', 'k'); % 设置文本颜色为黑色
        %     % 添加文本
        % text(x2 + 40, 30, "PMC chart", ... % 增加文本的水平偏移量
        %     'HorizontalAlignment', 'left', ...
        %     'VerticalAlignment', 'middle', ...
        %     'FontSize', 12, ...
        %     'Color', 'k'); % 设置文本颜色为黑色
        % text(x3 + 40, 30, "scaled PMC chart", ... % 增加文本的水平偏移量
        %     'HorizontalAlignment', 'left', ...
        %     'VerticalAlignment', 'middle', ...
        %     'FontSize', 12, ...
        %     'Color', 'k'); % 设置文本颜色为黑色
    elseif strcmp(legend_type,"CT")
        x1=(50 + (num_colors - 1) * 500)/100*20;
        x2=(50 + (num_colors - 1) * 500)/100*60;
        x3=(50 + (num_colors - 1) * 500)/100*100;
        plot([x1-100, x1], [10, 10], '-', 'LineWidth', 2, 'Color', 'k');    
        plot([x2-100, x2], [10, 10], '-.', 'LineWidth', 2, 'Color', 'k');
        plot([x3-100, x3], [10, 10], ':', 'LineWidth', 2, 'Color', 'k');
        % 添加文本
        text(x1 + 40, 10, "H", ... % 增加文本的水平偏移量
            'HorizontalAlignment', 'left', ...
            'VerticalAlignment', 'middle', ...
            'FontSize', 12, ...
            'Color', 'k'); % 设置文本颜色为黑色
            % 添加文本
        text(x2 + 40, 10, "M", ... % 增加文本的水平偏移量
            'HorizontalAlignment', 'left', ...
            'VerticalAlignment', 'middle', ...
            'FontSize', 12, ...
            'Color', 'k'); % 设置文本颜色为黑色
        text(x3 + 40, 10, "L", ... % 增加文本的水平偏移量
            'HorizontalAlignment', 'left', ...
            'VerticalAlignment', 'middle', ...
            'FontSize', 12, ...
            'Color', 'k'); % 设置文本颜色为黑色
    elseif strcmp(legend_type,"attr")
        x1=(50 + (num_colors - 1) * 500)/100;
        x2=(50 + (num_colors - 1) * 500)/100*50;
        x3=(50 + (num_colors - 1) * 500)/100*100;
        % plot(x1, 30, 's', 'MarkerSize', 10,'MarkerFaceColor', 'none', 'Color', 'm');    
        % plot(x1, 30, 's', 'MarkerSize', 10,'MarkerFaceColor', 'm', 'Color', 'm');

        % text(x1 + 40, 30, "scaled PMC chart", ... % 增加文本的水平偏移量
        %     'HorizontalAlignment', 'left', ...
        %     'VerticalAlignment', 'middle', ...
        %     'FontSize', 12, ...
        %     'Color', 'k'); % 设置文本颜色为黑色
        % text(x1 + 40, 30, "PMC chart", ... % 增加文本的水平偏移量
        % 'HorizontalAlignment', 'left', ...
        % 'VerticalAlignment', 'middle', ...
        % 'FontSize', 12, ...
        % 'Color', 'k'); % 设置文本颜色为黑色
    elseif strcmp(legend_type,"lightness")
        x1=(100 + (num_colors - 1) * 500)/100+100;
        x2=(100 + (num_colors - 1) * 500)/100*50+50;
        x3=(100 + (num_colors - 1) * 500)/100*100;
        plot([x1-100, x1], [30, 30], '-', 'LineWidth', 2, 'Color', 'k');
        text(x1 + 40, 30, "stranger", ... % 增加文本的水平偏移量
            'HorizontalAlignment', 'left', ...
            'VerticalAlignment', 'middle', ...
            'FontSize', 12, ...
            'Color', 'k'); % 设置文本颜色为黑色
        plot([x2-100, x2], [30, 30], '--', 'LineWidth', 2, 'Color', 'k');
        text(x2 + 40, 30, "acquaintance", ... % 增加文本的水平偏移量
            'HorizontalAlignment', 'left', ...
            'VerticalAlignment', 'middle', ...
            'FontSize', 12, ...
            'Color', 'k'); % 设置文本颜色为黑色
        plot([x3-100, x3], [30, 30], ':', 'LineWidth', 2, 'Color', 'k');
        text(x3 + 40, 30, "previous study", ... % 增加文本的水平偏移量
            'HorizontalAlignment', 'left', ...
            'VerticalAlignment', 'middle', ...
            'FontSize', 12, ...
            'Color', 'k'); % 设置文本颜色为黑色
    end

    axis off; % 关闭坐标轴
    xlim([0,30 + i * 500+80])
    ylim([0,100])
%%
    % 保存为 JPG 文件
    output_file = fullfile(output_folder, strcat("z_",legend_type,'.jpg'));
    exportgraphics(gcf, output_file, 'Resolution', 150, 'ContentType', 'image');
    
    
    % frame = getframe(gcf);  % 捕获当前窗口
    % img = frame.cdata;      % 获取图像数据
    % imwrite(img, output_file);  % 直接保存
    % disp("保存完成");
    % 方法A：使用copygraphics（R2020b引入，R2025a优化）
    % frame = getframe(gcf);
    % imwrite(frame.cdata, output_file, 'Quality', 95);
    % disp("d")
    % print(gcf, output_file, '-djpeg', '-r150');
    close(gcf);
end


% 测试代码

% legend_type="nation";
% legend_type="gender";
% legend_type="CT";
% legend_type="optimized_D";
% legend_type="attr";
% legend_type="attr_black";
% legend_type="lightness";
% legend_type="obs";
% legend_type="hml";
% legend_type="scenes2";
% legend_type="MCDM";
% legend_type="attr_MCDM";
% legend_type="compare";
% legend_type="compare_scene";
% legend_type="mini attr";
% legend_type="mini scene";
% legend_type="compare";
% legend_type="VIVOskin";
% legend_type="region";
% 
% 
% Dtype = "efit_p";
% output_folder = fullfile('ellip_pic_p', Dtype, 'legend');
% if ~exist(output_folder, 'dir')
%     mkdir(output_folder);
% end
% create_legend(output_folder,legend_type);
%%
Dtype = "efit_p";
output_folder = fullfile('ellip_pic_p', Dtype, 'legend');
if ~exist(output_folder, 'dir')
    mkdir(output_folder);
end

nations=["skin_Caucasian","skin_Asian","skin_South_Asian","skin_African"];
for i_nation =1:length(nations)
    nation=nations(i_nation);
    
    create_legend(output_folder,nation);
end

%%
% % 简洁版本 - 直接指定文件夹路径
% folder_path = 'D:\work\VIVOskinExpe\analyze\ellip_pic_p\efit_p\hml\rela\non_model\r\concatenated'; % 请修改为实际路径
% 
% % 获取图片文件
% image_files = dir(fullfile(folder_path, '*.jpg'));
% if length(image_files) < 2
%     image_files = [image_files; dir(fullfile(folder_path, '*.png'))];
% end
% 
% if length(image_files) < 2
%     error('需要至少2张图片');
% end
% 
% % 读取图片
% img1 = imread(fullfile(folder_path, image_files(1).name));
% img2 = imread(fullfile(folder_path, image_files(2).name));
% 
% % 确定需要缩放的图片
% aspect_ratio1 = size(img1, 2) / size(img1, 1);
% aspect_ratio2 = size(img2, 2) / size(img2, 1);
% 
% % if aspect_ratio1 > aspect_ratio2
%     % 缩放图片1到图片2的宽度
%     % scale_factor = size(img2, 2) / size(img1, 2);
%     % img1_resized = imresize(img1, scale_factor);
%     % combined_img = [img1_resized;img2];
% % else
% %     % 缩放图片2到图片1的宽度
%     scale_factor = size(img1, 2) / size(img2, 2);
% 
%     img2_resized = imresize(img2, scale_factor);
%     combined_img = [img1; img2_resized];
% % end
% 
% % 保存结果
% folderPath=fullfile(folder_path,"combined");
% if ~exist(folderPath,"dir")
%     mkdir(folderPath);
% end
% imwrite(combined_img, fullfile(folderPath, 'combined_result.jpg'));
% fprintf('拼接完成！输出文件: combined_result.jpg\n');
% 
% % 显示结果
% figure;
% imshow(combined_img);
