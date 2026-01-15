clear;
%%
% A=load("Z:\homes\Peggy\Toolbox\ColorDifferenceEquation\WYSZECKI.mat");
%%
%------------对比所有手机数据------------------------
n_phones=5;

dir_96data=dir("Z:\homes\Peggy\VIVOskinExpe\calibResults\96p3\*.mat");
XYZ_96=[];
for i=1:n_phones
    SPDname = 380:1:780;SPDname = SPDname';
    load(fullfile(dir_96data(i).folder,dir_96data(i).name));
    DATAs(1,:) = [];
    SPD = reshape(cell2mat(DATAs(:,4)),401,length(DATAs));
    XYZ10 = spd2xyz([SPDname SPD],10);
    interp=zeros(length(XYZ10),1);
    XYZ_96=[XYZ_96,interp,XYZ10];
end

dir_729data=dir("Z:\homes\Peggy\VIVOskinExpe\calibResults\729p3\*.mat");
XYZ_729=[];
for i=1:n_phones
    SPDname = 380:1:780;SPDname = SPDname';
    load(fullfile(dir_729data(i).folder,dir_729data(i).name));
    DATAs(1,:) = [];
    SPD = reshape(cell2mat(DATAs(:,4)),401,length(DATAs));
    XYZ10 = spd2xyz([SPDname SPD],10);
    interp=zeros(length(XYZ10),1);
    XYZ_729=[XYZ_729,interp,XYZ10];
end
%%
% data = load("Z:\homes\Peggy\oppoSkinExperi\gog\GOG\RGB96.mat"); 
% data=data.RGB;
% % indices=0:1:(length(data)-1);
% % data=[indices',data];
% % 指定输出文件名
% output_folder='Z:\homes\Peggy\pycharm\calibrationforOPPO';
% filename = 'rgb_values_96.csv';
% 
% % 将矩阵数据保存为 CSV 文件
% writematrix(data, fullfile(output_folder,filename));

%%
% %图像交互界面2.0
% % 清理环境
% clc; clear; close all;
% 
% % 读取指定图像
% image = imread("Z:\homes\Peggy\oppoSkinExperi\picked40\iphone\cropped\findRdQst\" + ...
%     "withDots_1.jpg");
% 
% % 显示图像
% figure;
% imshow(image);
% title('点击图像以记录像素值，按回车键结束');
% 
% % 初始化存储点击位置和像素值的数组
% click_positions = [];
% pixel_values = [];
% 
% % 标志交互是否结束
% interaction_ended = false;
% 
% % 设置按键回调函数
% set(gcf, 'KeyPressFcn', @(src, event) set_end_interaction(event));
% 
% % 开始交互
% while ~interaction_ended
%     [x, y, button] = ginput(1);
% 
%     if isempty(button) % 如果按回车键，button为空
%         interaction_ended = true;
%         break;
%     end
% 
%     % 确保点击位置在图像范围内
%     x = round(x);
%     y = round(y);
%     if x > 0 && x <= size(image, 2) && y > 0 && y <= size(image, 1)
%         % 记录点击位置和对应的像素值
%         click_positions = [click_positions; x, y];
%         pixel_values = [pixel_values; squeeze(image(y, x, :))'];
% 
%         % 在命令行窗口显示点击位置
%         disp(['点击位置: (', num2str(x), ', ', num2str(y), ')']);
%         disp(['像素值: R=', num2str(pixel_values(end, 1)), ...
%               ', G=', num2str(pixel_values(end, 2)), ...
%               ', B=', num2str(pixel_values(end, 3))]);
% 
%         % 在图像上标注点击位置
%         hold on;
%         plot(x, y, 'r+', 'MarkerSize', 10, 'LineWidth', 2);
%         hold off;
%     end
% end
% 
% % 将点击位置和像素值写入Excel文件
% output_filename = fullfile('Z:\homes\Peggy\oppoSkinExperi\picked40\iphone\cropped\rendered_LUTipv40_3_1\', 'click_positions_and_pixel_values.xlsx');
% data_table = array2table([click_positions, pixel_values], ...
%     'VariableNames', {'X', 'Y', 'R', 'G', 'B'});
% writetable(data_table, output_filename);
% 
% disp(['点击位置和像素值已保存到 ' output_filename]);
% 
% function set_end_interaction(event)
%     if strcmp(event.Key, 'return') % 检查是否按回车键
%         assignin('base', 'interaction_ended', true); % 设置交互结束标志
%     end
% end


%%
% %保存indices_matrix

% % 初始化一个 41x41 的矩阵来保存索引
% [m, n, p] = size(img);
% indices_matrix = zeros(m, n);
% 
% % 生成索引矩阵
% for row = 1:m
%     for col = 1:n
%         index = (col - 1) * m + row;
%         indices_matrix(row, col) = index;
%     end
% end
% 
% % 将索引矩阵保存为一个文件
% save('fdRdQst_matrix.mat', 'indices_matrix');
%%
% 裁剪图片选点及附近，保存

% % 读取指定图像
% image_path = "Z:\homes\Peggy\oppoSkinExperi\picked40\iphone\cropped\" + ...
%     "cropped_indoor06.jpg";
% image = imread(image_path);
% 
% % 定义两个坐标
% coords = [526, 312; 504, 322];
% 
% % 获取图片的尺寸
% [m, n, ~] = size(image);
% 
% % 定义上下左右扩展的范围
% range = 20;
% 
% for i = 1:size(coords, 1)
%     x = coords(i, 1);
%     y = coords(i, 2);
% 
%     % 确定矩形区域的边界
%     x_min = max(x - range, 1);
%     x_max = min(x + range, n);
%     y_min = max(y - range, 1);
%     y_max = min(y + range, m);
% 
%     % 提取指定范围内的像素
%     cropped_image = image(y_min:y_max, x_min:x_max, :);
% 
%     % 保存裁剪后的图像
%     imwrite(cropped_image, sprintf('OriWithDots_%d.jpg', i));
% end
% 
% % 显示提示信息
% disp('两张裁剪后的图片已保存');


%%
% save("save_cell_matrixs.mat",'xyz1','xyz2','rgbnew','outnew', ...
%     'cell_matrix_xyz1','cell_matrix_xyz2', 'cell_matrix_rgbnew','cell_matrix_outnew');
%%
% % 定义点击位置
% click_positions = [
%     441, 543;
%     427, 547;
%     418, 533;
%     412, 540
% ];
% 
% % 初始化一个 4x3 的 cell 矩阵
% cell_matrix_rgbnew = cell(4, 3);
% m=1345;n=1009;p=3;
% reshaped_rgbnew=reshape(rgbnew, [m, n, p]);
% 
% % 填充 cell 矩阵
% for k = 1:size(click_positions, 1)
%     x = click_positions(k, 1);
%     y = click_positions(k, 2);
%     
%     % 确定 11x11 范围内的边界
%     x_min = max(x - 5, 1);
%     x_max = min(x + 5, m);
%     y_min = max(y - 5, 1);
%     y_max = min(y + 5, n);
%     
%     % 获取 11x11 范围内的像素值
%     for channel = 1:3
%         % 提取通道数据，并填充到 11x11 矩阵中
%         region = nan(11, 11);
%         x_range = x_min:x_max;
%         y_range = y_min:y_max;
%         
%         for i = 1:length(y_range)
%             for j = 1:length(x_range)
%                 region(i, j) = reshaped_rgbnew(y_range(i), x_range(j), channel);
%             end
%         end
%         
%         % 将结果存储到 cell 矩阵中
%         cell_matrix_rgbnew{k, channel} = region;
%     end
% end

%%
%

% % 加载 neighbor_indices.mat 文件
% load('neighbor_indices1.mat', 'neighbor_indices');
% rgbnew1=rgbnew.*255;
% % 初始化一个 4x3 的 cell 矩阵
% cell_matrix_rgbnew1 = cell(4, 3);
% 
% % 填充 cell 矩阵
% for k = 1:4
%     index_matrix = neighbor_indices{k};
%     for channel = 1:3
%         % 获取每个通道对应索引的值
%         channel_values = rgbnew1(index_matrix, channel);
%         % 将通道值重塑为 10x10 矩阵
%         cell_matrix_rgbnew1{k, channel} = reshape(channel_values, 10, 10);
%     end
% end

%%
% % 图片的尺寸
% m = 1345; % 行数
% n = 1009; % 列数
% 
% % 定义点击位置
% click_positions = [
%     441, 543;
%     427, 547;
%     418, 533;
%     412, 540
% ];
% 
% % 计算展开后的索引
% indices = (click_positions(:,2) - 1) * m + click_positions(:,1);
% 
% % 初始化存储邻近 10x10 范围内的像素点的索引
% neighbor_indices = cell(size(click_positions, 1), 1);
% 
% % 计算邻近 10x10 范围内的像素点的索引
% for k = 1:size(click_positions, 1)
%     x = click_positions(k, 1);
%     y = click_positions(k, 2);
%     
%     % 确定 10x10 范围内的边界
%     x_min = max(x - 5, 1);
%     x_max = min(x + 4, m);
%     y_min = max(y - 5, 1);
%     y_max = min(y + 4, n);
%     
%     % 获取 10x10 范围内的坐标
%     [X, Y] = meshgrid(x_min:x_max, y_min:y_max);
%     X = X(:);
%     Y = Y(:);
%     
%     % 计算这些坐标在展开后的索引
%     neighbor_idx = (Y - 1) * m + X;
%     
%     % 创建一个 10x10 的矩阵来存储这些索引
%     index_matrix = nan(10, 10);
%     x_range = x_min:x_max;
%     y_range = y_min:y_max;
%     
%     % 填充 10x10 矩阵
%     for i = 1:length(y_range)
%         for j = 1:length(x_range)
%             index_matrix(i, j) = (y_range(i) - 1) * m + x_range(j);
%         end
%     end
%     
%     % 保存矩阵
%     neighbor_indices{k} = index_matrix;
% end
% % 保存 neighbor_indices 到 MAT 文件
% save('neighbor_indices1.mat', 'neighbor_indices');



%%
%
% XYZ_table=readtable("F:\FirstYearMaster\oppoSkinExperi\LUT3d\results\" + ...
%     "test-color-patch-729-1-2024-06-03-19-23.csv");
% XYZ_spd=table2array(XYZ_table(:,1:end));
% SPDname = 380:1:780;
% SPDname = SPDname';
% XYZ1 = spd2xyz([SPDname XYZ_spd'],10);
% XYZ_table=readtable("F:\FirstYearMaster\oppoSkinExperi\LUT3d\results\" + ...
%     "test-color-patch-2-729-2024-06-06-14-07.csv");
% XYZ_spd=table2array(XYZ_table(:,1:end));
% SPDname = 380:1:780;
% SPDname = SPDname';
% XYZ2 = spd2xyz([SPDname XYZ_spd'],10);
% [val, ind]=max(XYZ1);
% XYZw=XYZ1(ind(2),:);
% [lab1] = xyz2lab(XYZ1,'user',XYZw);
% [lab2] = xyz2lab(XYZ2,'user',XYZw);
% [de,~,~,~] = cielabde(lab1,lab2);
% [de00,de00c] = deltaE2000(lab1,lab2);
% de00=de00';de00c=de00c';
% de00grey=de00(55:72,:);
% de0024=de00(73:96,:);
% 
% mean_de=mean(de);
% mean_de00=mean(de00);
% mean_de00c=mean(de00c);
% mean_de00grey=mean(de00grey);
% mean_de0024=mean(de0024);
%%
%spd->xyz
% 
% XYZ_table=readtable("F:\FirstYearMaster\oppoSkinExperi\LUT3d\results\" + ...
%     "test-color-patch-1-96-2024-06-04-10-09.csv");
% XYZ_spd=table2array(XYZ_table(:,1:end));
% SPDname = 380:1:780;
% SPDname = SPDname';
% XYZ_mea = spd2xyz([SPDname XYZ_spd'],10);
% save("F:\FirstYearMaster\oppoSkinExperi\LUT3d\results\" + ...
%     "XYZ_mea_1.mat","XYZ_mea");

% load("F:\FirstYearMaster\oppoSkinExperi\LUT3d\results\SPD5.mat");
% SPDname = 380:1:780;
% SPDname = SPDname';
% XYZ_mea = spd2xyz([SPDname SPD(2:end,:)'],10);
% save("F:\FirstYearMaster\oppoSkinExperi\LUT3d\results\" + ...
%     "XYZ_mea_5.mat",'XYZ_mea');

%%
%contrast
% 
% folder_xyz='F:\FirstYearMaster\oppoSkinExperi\LUT3d\results';
% xyz1 = load(strcat(folder_xyz,'\',"XYZ_mea_1.mat")); 
% xyz1=xyz1.XYZ_mea;
% xyz2 = load(strcat(folder_xyz,'\',"XYZ_mea_2.mat")); 
% xyz2=xyz2.XYZ_mea;
% xyz3 = load(strcat(folder_xyz,'\',"XYZ_mea_3.mat")); 
% xyz3=xyz3.XYZ_mea;
% xyz5 = load(strcat(folder_xyz,'\',"XYZ_mea_5.mat")); 
% xyz5=xyz5.XYZ_mea;
% 
% [val, ind]=max(xyz1);
% XYZw=xyz1(ind(2),:);
% 
% [lab1] = xyz2lab(xyz1,'user',XYZw);
% [lab2] = xyz2lab(xyz2,'user',XYZw);
% [lab3] = xyz2lab(xyz3,'user',XYZw);
% [lab5] = xyz2lab(xyz5,'user',XYZw);
% % 初始化结果矩阵
% result_matrix = zeros(4, 4);
% cell_matrix = cell(4, 4);
% 
% 
% % 定义所有的 Lab 组
% lab_groups = {lab1, lab2, lab3, lab5};
% 
% % 计算两两之间的平均色差值
% for i = 1:4
%     for j = i+1:4
%         % 计算 i 组和 j 组之间的色差
%         [de,~,~,~] = cielabde(lab_groups{i},lab_groups{j});
%         [de00,de00c] = deltaE2000(lab_groups{i}, lab_groups{j});
%         % 计算平均色差
%         average_deltaE = mean(de00);
%         % 存储在结果矩阵中
%         result_matrix(i, j) = average_deltaE;
%         result_matrix(j, i) = average_deltaE;
% 
%         % 存储在元胞矩阵中
%         cell_matrix{i, j} = de00;
%         cell_matrix{j, i} = de00; % 对称存储
%         
%     end
% end
% 
% result_matrix24 = zeros(4, 4);
% cell_matrix24 = cell(4, 4);
% 
% for i = 1:4
%     for j = 1:4
%         cell_matrix24{i, j}=cell_matrix{i, j}(73:end);
% %         cell_matrix24{j, j}=cell_matrix{j, i}(73:end);
%         result_matrix24(i, j)=mean(cell_matrix24{i, j});
% %         result_matrix24(j, i)=mean(cell_matrix24{j, i});
%     end
% end
% 
% save(strcat(folder_xyz,'\',"InterColorDiff_matrix.mat"), ...
%     'result_matrix','cell_matrix','result_matrix24','cell_matrix24');