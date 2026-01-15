% 相机模型处理脚本 - 用于处理3FR格式的RAW图像并进行色彩空间转换
% 功能：读取RAW图像，应用相机模型转换为XYZ色彩空间，进行亮度校正，保存处理结果
% 依赖：raw2xyz函数、cameramodel_poly函数、xyz2srgb函数、相关.mat数据文件
% 使用说明：
% 1. 修改source_folder为你的RAW图像所在目录
% 2. 确保whiteSquare文件夹中存在对应的crop_rect_info_white_*.mat文件
% 3. 确保display_model文件夹中存在datai_ipv35_3.mat文件
% 4. 运行脚本，处理结果将保存在maxw_i文件夹中

clear
close all
addpath('..\..\utils\')  % 添加工具函数路径
%%

% 设置输入输出路径
source_folder='E:\Peggy\work\VIVOskinExpe\Hassel\Hassel\f05\raw'; % 原始RAW文件所在文件夹
dir_pic=dir(fullfile(source_folder,"*.3FR"));  % 获取所有3FR格式文件

% 提取文件夹名称作为标识
slashes = strfind(source_folder, '\');
if ~isempty(slashes)
    lastPart = source_folder(slashes(1,end-1)+1:slashes(1,end)-1);
end
lastPart=strcat(lastPart,"i");  % 构建输出文件夹名称

% 创建保存结果的文件夹
save_folder=fullfile("maxw_i",lastPart);
if ~exist(save_folder,"dir")
    mkdir(save_folder);
end

XYZw_all=[];  % 存储所有图像的白点信息
file_whiteSquare=(strcat("whiteSquare\crop_rect_info_white_",lastPart,".mat"));  % 加载白色方块区域信息

% 主循环：处理所有RAW图像
for i_pic=1:length(dir_pic)
    % 获取完整的文件路径
    imagename = fullfile(dir_pic(i_pic).folder, dir_pic(i_pic).name);
    
    % 提取文件名并根据首字母判断光照级别
    [~, name, ~] = fileparts(imagename);
    first_char = name(1);
    % 判断打头的字符是'M'、'H'还是'L'，对应不同光照强度
    if first_char == 'H'  % 场景光照度 1代表1000lux，2代表500lux，3代表100lux
        lux_level = 1;    
    elseif first_char == 'M'
        lux_level = 2;
    elseif first_char == 'L'||first_char == 'b'
        lux_level = 3;
    end

    % 定义建模图像的参数（参考值）
    model_image_shutterspeed = [1/90,1/45,1/10];  % 建模图像的快门速度
    model_image_FNumber = 4;
    model_image_iso = 400;
    
    % 获取目标图像的拍摄参数
    cfaInfo = rawinfo(imagename);
    target_image_shutterspeed = cfaInfo.ExifTags.ExposureTime;
    target_image_FNumber = cfaInfo.ExifTags.FNumber;
    target_image_iso = cfaInfo.ExifTags.ISOSpeedRatings;
    
    % 计算曝光补偿因子（基于ISO、快门速度和光圈）
    iso_scale = model_image_iso/target_image_iso;
    time_scale = model_image_shutterspeed(lux_level)/target_image_shutterspeed;
    Fnumber_scale=(model_image_FNumber/target_image_FNumber).^2;
    scalefactor = iso_scale*time_scale*(1/Fnumber_scale);
    
    %% 图像读取与处理
    [~,linrgb] = raw2xyz(imagename);  % 将RAW图像转换为线性RGB（已缩小为原始尺寸的0.25倍）
    
    %% 应用相机模型进行色彩空间转换
    sz = size(linrgb);
    RGB = reshape(double(linrgb),sz(1)*sz(2),sz(3));  % 重塑为二维数组进行处理
    
    XYZ = cameramodel_poly(RGB,lux_level);  % 应用相机模型转换为XYZ色彩空间
    XYZ = XYZ*scalefactor;  % 应用曝光补偿因子
    li_XYZ=XYZ;
    XYZ=reshape(XYZ,sz);  % 重塑回三维图像格式
    XYZ_raw=XYZ;

    % 加载白色方块区域信息（用于色彩校正）
    load(file_whiteSquare);
    gray_pos = crop_rect_info(i_pic,:);

    % 裁剪图像（去除边缘噪声）
    XYZ=XYZ(25:2210,33:2946,:);

    % 中心裁剪
    crop_width = 1640;
    start_x = (2914 - 1640) / 2;
    XYZ_cropped = XYZ(:, start_x+1:start_x+crop_width, :);
    
    % 计算白色区域的XYZ值（用于归一化）
    XYZw_white(1,:) = mean(mean(XYZ_cropped(gray_pos(2): gray_pos(2)+30,gray_pos(1) :gray_pos(1)+30,:)));
    XYZw = XYZw_white;

    %% 色彩校正与显示转换
    sz2=size(XYZ_cropped);
    XYZ_cpd_rspd=reshape(XYZ_cropped,[sz2(1)*sz2(2),sz2(3)]);
    
    % 加载显示模型数据
    datai_file = '..\display_model\datai_ipv35_3.mat';
    LUT=load(datai_file);
    XYZw_LUT=LUT.XYZw;

    % 色彩归一化处理：如果白色区域亮度高于参考值，则进行归一化
    if XYZw(2)>XYZw_LUT(2)
        XYZ_cpd_rspd=XYZ_cpd_rspd./XYZw(2).*XYZw_LUT(2);
        XYZw=XYZw_LUT;
    end
    
    % 像素值截断处理（确保在有效范围内）
    XYZ_cpd_rspd=min(XYZw_LUT(2),max(0,XYZ_cpd_rspd));
    XYZ_cropped=reshape(XYZ_cpd_rspd,[sz2(1),sz2(2),sz2(3)]);

    % 转换为sRGB色彩空间并显示
    RGB_cropped = xyz2srgb(XYZ_cpd_rspd);
    RGB_cropped = uint8(RGB_cropped);
    RGB_cropped = reshape(RGB_cropped,sz2);
    
    % 显示结果图像并标记白色方块区域
    figure(1)
    hold on;
    imshow(RGB_cropped)
    rectangle('Position', [gray_pos(1), gray_pos(2), 30, 30], ...
          'EdgeColor', 'r', ...       
          'LineWidth', 2);            
%----------

    % 保存当前图像的白色区域信息
    XYZw_all=[XYZw_all;XYZw];

    % 保存处理后的图像数据
    save(fullfile(save_folder,strcat(dir_pic(i_pic).name(1:end-4),".mat")), ...
        "XYZ_cropped","XYZw");
end

% 保存所有图像的白色区域信息
output_folder=fullfile(save_folder,"XYZw_all");
if ~exist(output_folder,"dir")
    mkdir(output_folder);
end
save(fullfile(output_folder,strcat(lastPart,"_XYZw_all.mat")), ...
        "XYZw_all");