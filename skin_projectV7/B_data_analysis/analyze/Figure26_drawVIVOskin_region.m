clear; close all;
%%
save_folder = fullfile("ellip_pic_p\ellipse", "VIVOskin\regions");
if ~exist(save_folder, "dir")
    mkdir(save_folder);
end

nations=["AS","CA","SA","AF"];
% 定义固定的饱和度和亮度值
FIXED_SATURATION = 0.8;  % 固定饱和度
FIXED_VALUE = 0.8;       % 固定亮度

% 定义人种对应的lastParts索引
nation_indices = cell(5, 1); % 5个人种（包括"all"）
% AS (Asian): f04i, f05i, f06i, m04i, m05i, m06i (索引1-6)
nation_indices{1} = 1:6;
% CA (Caucasian): f01i, f02i, f03i, m01i, m02i, m03i (索引7-12)  
nation_indices{2} = 7:12;
% SA (South Asian): f07i, f08i, m07i, m08i (索引13-16)
nation_indices{3} = 13:16;
% AF (African): f09i, f10i, m09i, m10i (索引17-20)
nation_indices{4} = 17:20;
% all: 所有索引 (索引1-20)
nation_indices{5} = 1:20;
% 读取数据
data_table = readtable(fullfile("documents\skinColorofModels\已选模特数据汇总1.xlsx"), 'Sheet', "删除鼻尖下巴", 'ReadVariableNames', false);
% 提取第一列为 'mean' 的行
meanRows = data_table(strcmp(data_table{:, 1}, 'mean'), :);
%%

% 提取第一列内容含有'male'的行
% 假设第一列是文本类型，列名根据实际情况调整
first_col_name = data_table.Properties.VariableNames{1};  % 获取第一列列名
start_rows=[5,33,63,91,119,148,176,203,230,258];
start_rows=start_rows-4;
% 定义起始列 - A列和I列
% 注意：MATLAB中table列索引从1开始
% A列对应第1列，I列对应第9列
start_cols = [1, 9];  % A列和I列的索引

% 创建cell数组来存储每个matrix
result_cell = cell(length(start_rows), length(start_cols));
lab_region = cell(length(start_rows), length(start_cols),3);
% 遍历每个start_row和start_col
for i = 1:length(start_rows)
    row_idx = start_rows(i);
    
    for j = 1:length(start_cols)
        col_idx = start_cols(j);
        
        % 提取15行3列的数据
        % 确保不会超出表格边界
        end_row = min(row_idx + 14, height(data_table));
        
        % 提取数据区域
        data_region = data_table(row_idx:end_row, col_idx:col_idx+2);
        
        % 将table转换为matrix
        % 先转换为数组，确保处理数值数据
        % 尝试直接转换为数值矩阵
        temp_matrix = table2array(data_region);
        
        % 如果包含非数值数据，尝试转换
        if any(isnan(temp_matrix(:)))
            % 使用str2double处理可能的文本数字
            temp_cell = table2cell(data_region);
            temp_matrix = zeros(size(temp_cell));
            
            for r = 1:size(temp_cell, 1)
                for c = 1:size(temp_cell, 2)
                    if isnumeric(temp_cell{r,c})
                        temp_matrix(r,c) = temp_cell{r,c};
                    else
                        temp_matrix(r,c) = str2double(temp_cell{r,c});
                    end
                end
            end
        end
        
        % 存储到result_cell
        result_cell{i, j} = temp_matrix;
        lab_region{i, j,1} = mean(temp_matrix(1:3,:),1);
        lab_region{i, j,2} = mean(temp_matrix(4:9,:),1);
        lab_region{i, j,3} = mean(temp_matrix(10:15,:),1);

    end
end


disp("d")

%%
nation_rows{1}=4:6;
nation_rows{2}=1:3;
nation_rows{3}=7:8;
nation_rows{4}=9:10;
regions=["forehead","cheek","neck"];

% 定义不同区域的标记样式
plot_stypes = {'o', 's', '^'};  % forehead: 圆圈, cheek: 方块, neck: 三角形

% 提取第 2 到第 5 列并转换为矩阵
hue_indices = [1, 2, 3, 4]; % AS:1, CA:2, SA:3, AF:4

for i_nation=1:length(nations)
    clear("model_names","model_colors");
    genders=["m";"f"];
    curr=1;
    
    for i_row=nation_rows{i_nation}
        for i_col=1:2
            model_names{curr,1}=strcat(genders(i_col),sprintf("%02d",i_row));
            curr=curr+1;
        end
    end
    model_nations{i_nation}=model_names;
    
    nation = nations(i_nation);
    nation_serial=sprintf("%02d%s",i_nation,nation);
    
    % 为当前人种的所有模型生成不同色相的颜色
    num_models_in_nation = length(model_names);
    % 生成均匀分布的色相值
    hue_values_nation = linspace(0, 1, num_models_in_nation + 1);
    hue_values_nation = hue_values_nation(1:end-1);  % 去掉最后一个重复点
    
    % 生成固定饱和度和亮度的颜色
    model_colors = zeros(num_models_in_nation, 3);
    for i_model = 1:num_models_in_nation
        hsv_color = [hue_values_nation(i_model), FIXED_SATURATION, FIXED_VALUE];
        model_colors(i_model, :) = hsv2rgb(hsv_color);
    end

    for i_region=1:3
        region=regions(i_region);
        region_serial=sprintf("%02d%s",i_region,region);
        lab_mean=[];
        
        % 根据i_region选择标记样式
        plot_stype = plot_stypes{i_region};
        
        for i_row=nation_rows{i_nation}
            for i_col=1:2
                lab_mean=[lab_mean;lab_region{i_row, i_col,i_region}];
            end
        end
        
        % 提取 L, a, b, C 数据
        all_L = lab_mean(:, 1);
        all_a = lab_mean(:, 2);
        all_b = lab_mean(:, 3);
        lab_mean(:, 4) = sqrt(lab_mean(:, 2).^2+lab_mean(:, 3).^2);
        C = lab_mean(:, 4);
        h = atan2d(all_b, all_a);
        h_table=[mean(h),max(h),min(h)];
        all_LabCh = [all_L, all_a, all_b, C, h];
        % 保存数据
        save(fullfile(save_folder, "VIVOskin.mat"), "all_LabCh", "model_names");
        % 设置坐标轴范围
        L_limits = [25,75];
        a_limits = [0,15];
        b_limits = [0,25];
        C_limits = [0,30];
        h_limits = [45,65];
        ab_limits = [min(min(all_a), min(all_b)) - 5, max(max(all_a), max(all_b)) + 5];
        
        outputFolder = fullfile(save_folder, nation_serial);
        if ~exist(outputFolder, 'dir')
            mkdir(outputFolder);
        end
        
        
        % a-b 图 (h0)
        h0=figure(5);
        hold on;
        
        % 为每个模型绘制点，使用预先生成的颜色
        for i_skin=1:num_models_in_nation
            plot(lab_mean(i_skin, 2), lab_mean(i_skin, 3), ...
                plot_stype, ...
                'Color', model_colors(i_skin, :), ...
                'MarkerFaceColor', model_colors(i_skin, :), ...
                'MarkerSize', 10);
        end
        
        % 添加45°线
        x = linspace(ab_limits(1), ab_limits(2), 1000);
        y = x; 
        plot(x, y, 'k--', 'LineWidth', 1);
        
        xlabel('$a^*$', 'Interpreter', 'latex', 'FontSize', 12*2);
        ylabel('$b^*$', 'Interpreter', 'latex', 'FontSize', 12*2);
        axis equal;
        xlim(ab_limits);
        ylim(ab_limits);
        exportgraphics(h0, fullfile(outputFolder, strcat(nation_serial,'all_a_b.jpg')), 'Resolution', 300);
        
        % L-C 图 (h3)
        h3=figure(3);
        hold on;
        
        for i_skin=1:num_models_in_nation
            plot(lab_mean(i_skin, 4), lab_mean(i_skin, 1), ...
                plot_stype, ...
                'Color', model_colors(i_skin, :), ...
                'MarkerFaceColor', model_colors(i_skin, :), ...
                'MarkerSize', 10);
        end
        
        xlabel('$C_{ab}^*$', 'Interpreter', 'latex', 'FontSize', 12*2);
        ylabel('$L^*$', 'Interpreter', 'latex', 'FontSize', 12*2);
        axis equal;
        xlim(C_limits);
        ylim(L_limits);
        exportgraphics(h3, fullfile(outputFolder, strcat(nation_serial,'all_L_C.jpg')), 'Resolution', 300);
    end
    close all;
    concatenate_images1(outputFolder, 5);
end


%%
% clear; close all;
% %%
% save_folder = fullfile("ellip_pic_p\ellipse", "VIVOskin\regions");
% if ~exist(save_folder, "dir")
%     mkdir(save_folder);
% end
% 
% nations=["AS","CA","SA","AF"];
% num_colors=4;
% hue_values = linspace(0, 1, num_colors + 1);
% hue_values = hue_values(1:end-1); 
% hsv_matrix = [hue_values', 0.8 * ones(num_colors, 1), 0.8 * ones(num_colors, 1)];
% colors = hsv2rgb(hsv_matrix);
% % 定义人种对应的lastParts索引
% nation_indices = cell(5, 1); % 5个人种（包括"all"）
% % AS (Asian): f04i, f05i, f06i, m04i, m05i, m06i (索引1-6)
% nation_indices{1} = 1:6;
% % CA (Caucasian): f01i, f02i, f03i, m01i, m02i, m03i (索引7-12)  
% nation_indices{2} = 7:12;
% % SA (South Asian): f07i, f08i, m07i, m08i (索引13-16)
% nation_indices{3} = 13:16;
% % AF (African): f09i, f10i, m09i, m10i (索引17-20)
% nation_indices{4} = 17:20;
% % all: 所有索引 (索引1-20)
% nation_indices{5} = 1:20;
% % 读取数据
% data_table = readtable(fullfile("documents\skinColorofModels\已选模特数据汇总1.xlsx"), 'Sheet', "删除鼻尖下巴", 'ReadVariableNames', false);
% % 提取第一列为 'mean' 的行
% meanRows = data_table(strcmp(data_table{:, 1}, 'mean'), :);
% %%
% 
% 
% % 提取第一列内容含有'male'的行
% % 假设第一列是文本类型，列名根据实际情况调整
% first_col_name = data_table.Properties.VariableNames{1};  % 获取第一列列名
% % male_rows = contains(string(data_table.(first_col_name)), 'male', 'IgnoreCase', true);
% % start_rows = find(male_rows);  % 获取行索引
% start_rows=[5,33,63,91,119,148,176,203,230,258];
% start_rows=start_rows-4;
% % 定义起始列 - A列和I列
% % 注意：MATLAB中table列索引从1开始
% % A列对应第1列，I列对应第9列
% start_cols = [1, 9];  % A列和I列的索引
% 
% % 创建cell数组来存储每个matrix
% result_cell = cell(length(start_rows), length(start_cols));
% lab_region = cell(length(start_rows), length(start_cols),3);
% % 遍历每个start_row和start_col
% for i = 1:length(start_rows)
%     row_idx = start_rows(i);
% 
%     for j = 1:length(start_cols)
%         col_idx = start_cols(j);
% 
%         % 提取15行3列的数据
%         % 确保不会超出表格边界
%         end_row = min(row_idx + 14, height(data_table));
% 
%         % 提取数据区域
%         data_region = data_table(row_idx:end_row, col_idx:col_idx+2);
% 
%         % 将table转换为matrix
%         % 先转换为数组，确保处理数值数据
%         % 尝试直接转换为数值矩阵
%         temp_matrix = table2array(data_region);
% 
%         % 如果包含非数值数据，尝试转换
%         if any(isnan(temp_matrix(:)))
%             % 使用str2double处理可能的文本数字
%             temp_cell = table2cell(data_region);
%             temp_matrix = zeros(size(temp_cell));
% 
%             for r = 1:size(temp_cell, 1)
%                 for c = 1:size(temp_cell, 2)
%                     if isnumeric(temp_cell{r,c})
%                         temp_matrix(r,c) = temp_cell{r,c};
%                     else
%                         temp_matrix(r,c) = str2double(temp_cell{r,c});
%                     end
%                 end
%             end
%         end
% 
%         % 存储到result_cell
%         result_cell{i, j} = temp_matrix;
%         lab_region{i, j,1} = mean(temp_matrix(1:3,:),1);
%         lab_region{i, j,2} = mean(temp_matrix(4:9,:),1);
%         lab_region{i, j,3} = mean(temp_matrix(10:15,:),1);
% 
%     end
% end
% 
% 
% disp("d")
% 
% %%
% nation_rows{1}=4:6;
% nation_rows{2}=1:3;
% nation_rows{3}=7:8;
% nation_rows{4}=9:10;
% regions=["forehead","cheek","neck"];
% 
% 
% 
% 
% % 提取第 2 到第 5 列并转换为矩阵
% for i_nation=4
% % for i_nation=1:length(nations)
% % for i_nation=2:2
%     genders=["m";"f"];
%     curr=1;
%     for i_row=nation_rows{i_nation}
%         for i_col=1:2
%             model_names{curr,1}=strcat(genders(i_col),sprintf("%02d",i_row));
%             curr=curr+1;
%         end
%     end
% 
% 
%     nation = nations(i_nation);
%     nation_serial=sprintf("%02d%s",i_nation,nation);
% 
%     for i_region=1:3
%         region=regions(i_region);
%         region_serial=sprintf("%02d%s",i_region,region);
%         lab_mean=[];
%         if i_region==1
%             plot_stype=plot_stypes{1};
%         elseif i_region==2
%             plot_stype=colors(2,:);
%         elseif i_region==3
%             plot_stype=colors(3,:);
% 
%         end
%         for i_row=nation_rows{i_nation}
%             for i_col=1:2
%                 lab_mean=[lab_mean;lab_region{i_row, i_col,i_region}];
%             end
%         end
% 
%         % 提取 L, a, b, C 数据
%         all_L = lab_mean(:, 1);
%         all_a = lab_mean(:, 2);
%         all_b = lab_mean(:, 3);
%         lab_mean(:, 4) = sqrt(lab_mean(:, 2).^2+lab_mean(:, 3).^2);
%         C = lab_mean(:, 4);
%         h = atan2d(all_b, all_a);
%         h_table=[mean(h),max(h),min(h)];
%         all_LabCh = [all_L, all_a, all_b, C, h];
%         % 保存数据
%         save(fullfile(save_folder, "VIVOskin.mat"), "all_LabCh", "model_names");
%         % 设置坐标轴范围
%         L_limits = [25,75];
%         a_limits = [0,15];
%         b_limits = [0,25];
%         C_limits = [0,30];
%         h_limits = [45,65];
%         % L_limits = [min(all_L) - 5, max(all_L) + 5];
%         % a_limits = [min(all_a) - 5, max(all_a) + 5];
%         % b_limits = [min(all_b) - 5, max(all_b) + 5];
%         % C_limits = [min(C) - 5, max(C) + 5];
%         % h_limits = [min(h) - 5, max(h) + 5];
%         ab_limits = [min(min(all_a), min(all_b)) - 5, max(max(all_a), max(all_b)) + 5];
% 
%         if i_region==1
%             color=colors(1,:);
%         elseif i_region==2
%             color=colors(2,:);
%         elseif i_region==3
%             color=colors(3,:);
% 
%         end
%         outputFolder = fullfile(save_folder, nation_serial);
%         if ~exist(outputFolder, 'dir')
%             mkdir(outputFolder);
%         end
% 
% 
%         % % a-b 图
%         % h0=figure(5);
%         % set(h0, 'Visible', 'off');  % 再单独设置属性
%         % hold on;
% 
%         % % 根据 i_skin 的值选择颜色和样式
%         % 
%         % for i_skin=1:length(lab_mean)
%         % text(lab_mean(i_skin, 2), lab_mean(i_skin, 3), model_names(i_skin), ...
%         %     'Color', color, 'FontSize', 12);
%         % end
%         % % 添加45°线
%         % x = linspace(ab_limits(1), ab_limits(2), 1000);
%         % y = x; 
%         % plot(x, y, 'k--', 'LineWidth', 1);
%         % 
%         % % title('$a^*-b^*$', 'Interpreter', 'latex', 'FontSize', 12*2);
%         % xlabel('$a^*$', 'Interpreter', 'latex', 'FontSize', 12*2);
%         % ylabel('$b^*$', 'Interpreter', 'latex', 'FontSize', 12*2);
%         % axis equal;
%         % xlim(ab_limits);
%         % ylim(ab_limits);
%         % % saveas(gcf, fullfile(outputFolder, strcat(nation_serial, 'all_a_b.jpg')));
%         % exportgraphics(h0, fullfile(outputFolder, strcat(nation_serial,'all_a_b.jpg')), 'Resolution', 300);
%         % close(gcf)
%         % L-a 图
%         h1=figure(1);
%         set(h1,'Visible', 'off');
%         hold on;
%         for i_skin=1:length(lab_mean)
%         text(lab_mean(i_skin, 2), lab_mean(i_skin, 1), model_names(i_skin), ...
%             'Color', color, 'FontSize', 12);
%         end
% 
%         % title('$L^*-a^*$', 'Interpreter', 'latex', 'FontSize', 12*2);
%         xlabel('$a^*$', 'Interpreter', 'latex', 'FontSize', 12*2);
%         ylabel('$L^*$', 'Interpreter', 'latex', 'FontSize', 12*2);
%         axis equal;
%         xlim(a_limits);
%         ylim(L_limits);
% 
%         % print(gcf, fullfile(outputFolder, strcat(nation_serial, 'all_L_a.jpg')), '-djpeg', '-r300');
%         % saveas(h1, fullfile(outputFolder, strcat(nation_serial, 'all_L_a.jpg')));
%         exportgraphics(h1, fullfile(outputFolder, strcat(nation_serial,'all_L_a.jpg')), 'Resolution', 300);
%         % close(gcf)
%         % L-b 图
%         h2=figure(2);
%         set(h2,'Visible', 'off');
%         hold on;
%         for i_skin = 1:length(lab_mean)
%             for i_skin=1:length(lab_mean)
%             text(lab_mean(i_skin, 3), lab_mean(i_skin, 1), model_names(i_skin), ...
%                 'Color', color, 'FontSize', 12);
%             end
% 
%         end
%         % title('$L^*-b^*$', 'Interpreter', 'latex', 'FontSize', 12*2);
%         xlabel('$b^*$', 'Interpreter', 'latex', 'FontSize', 12*2);
%         ylabel('$L^*$', 'Interpreter', 'latex', 'FontSize', 12*2);
%         axis equal;
%         xlim(b_limits);
%         ylim(L_limits);
% 
%         % print(h2, fullfile(outputFolder, strcat(nation_serial, 'all_L_b.jpg')), '-djpeg', '-r300');
%         % saveas(h2, fullfile(outputFolder, strcat(nation_serial, 'all_L_b.jpg')));
%         exportgraphics(h2, fullfile(outputFolder,strcat(nation_serial,'all_L_b.jpg')), 'Resolution', 300);
%         % close(gcf)
%         % L-C 图
%         h3=figure(3);
%         set(h3,'Visible', 'off')
%         hold on;
%         for i_skin = 1:length(lab_mean)
%             for i_skin=1:length(lab_mean)
%             text(lab_mean(i_skin, 4), lab_mean(i_skin, 1), model_names(i_skin), ...
%                 'Color', color, 'FontSize', 12);
%             end
% 
%         end
%         % title('$L^*-C_{ab}^*$', 'Interpreter', 'latex', 'FontSize', 12*2);
%         xlabel('$C_{ab}^*$', 'Interpreter', 'latex', 'FontSize', 12*2);
%         ylabel('$L^*$', 'Interpreter', 'latex', 'FontSize', 12*2);
%         axis equal;
%         xlim(C_limits);
%         ylim(L_limits);
%         % print(h3, fullfile(outputFolder, strcat(nation_serial, 'all_L_C.jpg')), '-djpeg', '-r300');
%         exportgraphics(h3, fullfile(outputFolder, strcat(nation_serial,'all_L_C.jpg')), 'Resolution', 300);
%         % close(gcf)
%         % L-h 图
%         h4=figure(4);
%         set(h4,'Visible', 'off');
%         hold on;
%         for i_skin = 1:length(lab_mean)
% 
%         for i_skin=1:length(lab_mean)
%         text(h(i_skin), lab_mean(i_skin, 1), model_names(i_skin), ...
%             'Color', color, 'FontSize', 12);
%         end
%         end
%         % title('$L^*-h_{ab}$', 'Interpreter', 'latex', 'FontSize', 24);
%         xlabel('$h_{ab}$', 'Interpreter', 'latex', 'FontSize', 12*2);
%         ylabel('$L^*$', 'Interpreter', 'latex', 'FontSize', 12*2);
%         axis equal;
%         xlim(h_limits);
%         ylim(L_limits);
%         % print(h4, fullfile(outputFolder, strcat(nation_serial, 'all_L_h.jpg')), '-djpeg', '-r300');
%         exportgraphics(h4, fullfile(outputFolder,strcat(nation_serial,'all_L_h.jpg')), 'Resolution', 300);
%         % close(gcf)
%         concatenate_images1noSerial(outputFolder, 5);
%     end
%     close all;
% end
