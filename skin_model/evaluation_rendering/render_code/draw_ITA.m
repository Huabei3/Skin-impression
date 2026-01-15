% 1. Load the data from your Excel file, specifying no headers.
T = readtable('documents\i\ITA_Skin_Classification_Results.xlsx', 'ReadVariableNames', false);
% Access columns by their default names: Var1, Var2, ..., Var14, Var15, Var16
lastParts = T.Var1; % 第一列为lastPart
Lab_data = [T.Var14, T.Var15, T.Var16]; % 第14、15、16列为Lab数据

% 2. Define the race groups and all models
all_lastParts = {'f04i', 'f05i', 'f06i', 'm04i', 'm05i', 'm06i', ...
                 'f01i', 'f02i', 'f03i', 'm01i', 'm02i', 'm03i', ...
                 'f07i', 'f08i', 'm07i', 'm08i', ...
                 'f09i', 'f10i', 'm09i', 'm10i'};
num_models = length(all_lastParts);

% --- 修改颜色生成逻辑: 为每个模特分配一个独特的色调 ---
% Generate distinct colors for each of the 20 models
hue_values = linspace(0, 1, num_models + 1);
hue_values = hue_values(1:end-1);
hsv_matrix = [hue_values', 0.8 * ones(num_models, 1), 0.8 * ones(num_models, 1)];
model_colors = hsv2rgb(hsv_matrix);
% -----------------------------------------------------------------

% --- 加载并处理第二个文件的数据 ---
T_mea_m = readtable('documents\ita_skin_classification.xlsx', 'ReadVariableNames', false, 'Range', 'B3:K5');
T_mea_f = readtable('documents\ita_skin_classification.xlsx', 'ReadVariableNames', false, 'Range', 'B21:K23');
% 提取并转置男模特数据
m_lab_mea = T_mea_m{:,:}.';
% 提取并转置女模特数据
f_lab_mea = T_mea_f{:,:}.';
% 将所有Lab_mea数据按lastParts顺序排列
lab_mea_data = zeros(num_models, 3);
% AS (Asian): f04i, f05i, f06i, m04i, m05i, m06i
lab_mea_data(1:3,:) = f_lab_mea(4:6,:); 
lab_mea_data(4:6,:) = m_lab_mea(4:6,:);
% CA (Caucasian): f01i, f02i, f03i, m01i, m02i, m03i
lab_mea_data(7:9,:) = f_lab_mea(1:3,:);
lab_mea_data(10:12,:) = m_lab_mea(1:3,:);
% SA (South Asian): f07i, f08i, m07i, m08i
lab_mea_data(13:14,:) = f_lab_mea(7:8,:);
lab_mea_data(15:16,:) = m_lab_mea(7:8,:);
% AF (African): f09i, f10i, m09i, m10i
lab_mea_data(17:18,:) = f_lab_mea(9:10,:);
lab_mea_data(19:20,:) = m_lab_mea(9:10,:);
% --- 加载处理结束 ---

% 3. Plot L* vs. b*
figure(1);
hold on;
title('L* vs. b*');
xlabel('b*');
ylabel('L*');
grid on;
box on;
max_L = 0;
max_b = 0;

% --- 修改绘图循环逻辑: 遍历所有模特，使用独特的颜色 ---
for i = 1:num_models
    model_name = all_lastParts{i};
    current_color = model_colors(i, :);
    
    % Find data for the current model
    model_rows = strcmp(lastParts, model_name);
    model_Lab = Lab_data(model_rows, :);
    
    scatter(model_Lab(:, 3), model_Lab(:, 1), 5, current_color, 'filled', 'MarkerFaceAlpha', 0.6);
    
    % 计算数据点簇的中心位置
    mean_L = mean(model_Lab(:, 1));
    mean_b = mean(model_Lab(:, 3));
    % 文本标签颜色为黑色
    text(mean_b+2, mean_L, model_name, 'Color', 'k', 'FontSize', 4, 'FontWeight', 'bold', 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom');
    
    % Update max values for axis limits
    max_b = max(max_b, max(model_Lab(:, 3)));
    max_L = max(max_L, max(model_Lab(:, 1)));
end
% ------------------------------------------------------------

% --- 叠加绘制Lab_mea数据，颜色与模特对应，文本为黑色 ---
for i = 1:num_models
    model_name = all_lastParts{i};
    Lab_mea = lab_mea_data(i, :);

    
    % --- 提取简短名称，例如 'f04i' -> 'f4' ---
    short_name = strcat(strrep(model_name(1:2),"0",""),model_name(3));
    % ---------------------------------------------------

    % 使用text函数代替plot绘制点
    text(Lab_mea(3), Lab_mea(1), short_name, 'Color', 'r', 'FontSize',4, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');

    % 更新最大值
    max_b = max(max_b, Lab_mea(3));
    max_L = max(max_L, Lab_mea(1));
end
% ------------------------------------------------------------

% Draw the rays
ray_angles = [-30, 10, 28, 41, 55];
ray_length = 50;
start_point = [0, 50];
for angle = ray_angles
    angle_rad = deg2rad(angle);
    end_point = start_point + ray_length * [cos(angle_rad), sin(angle_rad)];
    plot([start_point(1), end_point(1)], [start_point(2), end_point(2)], '--k', 'LineWidth', 0.5);
end
axis equal;
% Set axis properties based on data
xlim([0, ceil(max_b) + 5]);
ylim([0, ceil(max_L) + 5]);
xticks(0:10:ceil(max_b) + 5);
yticks(0:10:ceil(max_L) + 5);
save_folder=fullfile("ITA");
if ~exist(save_folder,"dir")
    mkdir(save_folder);
end
saveas(gcf, fullfile(save_folder, ...
    strcat('L-b.jpg')));

% ---
% 4. Plot L* vs. Chroma (sqrt(a*^2 + b*^2))
figure(2);
hold on;
title('L* vs. Chroma (C*)');
xlabel('Chroma (C*)');
ylabel('L*');
grid on;
box on;
max_L = 0;
max_C = 0;

% --- 修改绘图循环逻辑: 遍历所有模特，使用独特的颜色 ---
for i = 1:num_models
    model_name = all_lastParts{i};
    current_color = model_colors(i, :);
    
    model_rows = strcmp(lastParts, model_name);
    model_Lab = Lab_data(model_rows, :);
    
    % Calculate Chroma
    Chroma = sqrt(model_Lab(:, 2).^2 + model_Lab(:, 3).^2);
    
    scatter(Chroma, model_Lab(:, 1), 5, current_color, 'filled', 'MarkerFaceAlpha', 0.6);
    
    % 计算数据点簇的中心位置
    mean_L = mean(model_Lab(:, 1));
    mean_C = mean(Chroma);
    % 文本标签颜色为黑色
    text(mean_C+2, mean_L, model_name, 'Color', 'k', 'FontSize', 4, 'FontWeight', 'bold', 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom');
    
    % Update max values for axis limits
    max_C = max(max_C, max(Chroma));
    max_L = max(max_L, max(model_Lab(:, 1)));
end
% ------------------------------------------------------------

% --- 叠加绘制Lab_mea数据，颜色与模特对应，文本为黑色 ---
for i = 1:num_models
    model_name = all_lastParts{i};
    Lab_mea = lab_mea_data(i, :);
    Chroma_mea = sqrt(Lab_mea(2)^2 + Lab_mea(3)^2);
    
    % --- 提取简短名称，例如 'f04i' -> 'f4' ---
    short_name = strcat(strrep(model_name(1:2),"0",""),model_name(3));
    % ---------------------------------------------------

    % 使用text函数代替plot绘制点
    text(Chroma_mea, Lab_mea(1), short_name, 'Color', 'r', 'FontSize', 4, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');

    % 更新最大值
    max_C = max(max_C, Chroma_mea);
    max_L = max(max_L, Lab_mea(1));
end
% ------------------------------------------------------------

axis equal;
% Set axis properties based on data
xlim([0, ceil(max_C) + 5]);
ylim([0, ceil(max_L) + 5]);
xticks(0:10:ceil(max_C) + 5);
yticks(0:10:ceil(max_L) + 5);

save_folder=fullfile("ITA");
if ~exist(save_folder,"dir")
    mkdir(save_folder);
end
saveas(gcf, fullfile(save_folder, ...
    strcat('L-C.jpg')));

save(fullfile("documents",strcat("modelSkinColor.mat")),"lab_mea_data","all_lastParts");