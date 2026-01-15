% test camera model
%原名main_model_scaled1
clear
close all
%%
% lastParts_train=["male91","female02","female19","female63"];
% substitudes_train=[];
source_folder='..\..\H_raw_images\Hassel\f01\raw';
dir_pic=dir(fullfile(source_folder,"*.3FR"));

slashes = strfind(source_folder, '\');
if ~isempty(slashes)
    lastPart = source_folder(slashes(1,end-1)+1:slashes(1,end)-1);
end
lastPart=strcat(lastPart,"i");

save_folder=fullfile("D:\work\VIVOskinExpe\renderCode\XYZ\i",lastPart);
if ~exist(save_folder,"dir")
    mkdir(save_folder);
end
XYZw_all=[];
file_whiteSquare=(strcat("whiteSquare\crop_rect_info_white_",lastPart,".mat"));
%删去蓝色
% for i_pic=[1]
for i_pic=1:length(dir_pic)
        % 获取完整的文件路径
    imagename = fullfile(dir_pic(i_pic).folder, dir_pic(i_pic).name);
    
    % 提取文件名
    [~, name, ~] = fileparts(imagename);
    first_char = name(1);
    % 判断打头的字符是'M'、'H'还是'L'
    if first_char == 'H'% 场景光照度 1代表1000lux，2代表500lux，3代表100lux
        lux_level = 1;    
    elseif first_char == 'M'
        lux_level = 2;
    elseif first_char == 'L'||first_char == 'b'
        lux_level = 3;
    end

    model_image_shutterspeed = [1/90,1/45,1/10]; % 建模图像的快门速度
    model_image_FNumber = 4;
    model_image_iso = 400;
    % target image info
    %算无卡的scalefactor
    cfaInfo = rawinfo(imagename);
    target_image_shutterspeed = cfaInfo.ExifTags.ExposureTime;
    target_image_FNumber = cfaInfo.ExifTags.FNumber;
    target_image_iso = cfaInfo.ExifTags.ISOSpeedRatings;
    %
    iso_scale = model_image_iso/target_image_iso;
    time_scale = model_image_shutterspeed(lux_level)/target_image_shutterspeed;
    Fnumber_scale=(model_image_FNumber/target_image_FNumber).^2;
    scalefactor = iso_scale*time_scale*(1/Fnumber_scale);
    
    %% image read
    % imagename = 'B0001084.3FR';
    [~,linrgb] = raw2xyz(imagename); % raw图线性rgb（imresize-0.25,缩小16倍图像尺寸，可以在函数内修改）
    
    %% camera model
    sz = size(linrgb);
    RGB = reshape(double(linrgb),sz(1)*sz(2),sz(3));
    
    XYZ = cameramodel_poly(RGB,lux_level); % 这里就是XYZ数据！！！
    XYZ = XYZ*scalefactor;
    % 转到srgb

    XYZ=reshape(XYZ,sz);
    XYZ_raw=XYZ;

    %% 裁剪，提取白色块
    
    load(file_whiteSquare);
    gray_pos = crop_rect_info(i_pic,:);
    XYZ=XYZ(25:2210,33:2946,:);
    crop_width = 1640;
    start_x = (2914 - 1640) / 2;
    XYZ_cropped = XYZ(:, start_x+1:start_x+crop_width, :);
    XYZw_white(1,:) = mean(mean(XYZ_cropped(gray_pos(2): gray_pos(2)+30,gray_pos(1) :gray_pos(1)+30,:)));
    XYZw = XYZw_white ;
    

    %% Lab 公式
    
    sz2=size(XYZ_cropped);
    XYZ_cpd_rspd=reshape(XYZ_cropped,[sz2(1)*sz2(2),sz2(3)]);
    datai_file = 'D:\work\VIVOskinExpe\renderCode\calibResults\datai_ipv18_3.mat';
    LUT=load(datai_file);
    XYZw_LUT=LUT.XYZw;

    %归一化
    if XYZw(2)>XYZw_LUT(2)
        XYZ_cpd_rspd=XYZ_cpd_rspd./XYZw(2).*XYZw_LUT(2);
        XYZw=XYZw_LUT;
    end
    %截断
    XYZ_cpd_rspd=min(XYZw_LUT(2),max(0,XYZ_cpd_rspd));
    %reshape回来
    XYZ_cropped=reshape(XYZ_cpd_rspd,[sz2(1),sz2(2),sz2(3)]);

  
    RGB_cropped = xyz2srgb(XYZ_cpd_rspd);
    RGB_cropped = uint8(RGB_cropped);
    RGB_cropped = reshape(RGB_cropped,sz2);
    figure(1)
    hold on;
    imshow(RGB_cropped)
    rectangle('Position', [gray_pos(1), gray_pos(2), 30, 30], ...
          'EdgeColor', 'r', ...        % 矩形框的边缘颜色为红色
          'LineWidth', 2);             % 矩形框的线宽为 2 像素
%----------

    XYZw_all=[XYZw_all;XYZw];

    % save(fullfile(save_folder,strcat(dir_pic(i_pic).name(1:end-4),".mat")), ...
    %     "XYZ_cropped","XYZw","XYZw_white");


end
output_folder=fullfile(save_folder,"XYZw_all");
if ~exist(output_folder,"dir")
    mkdir(output_folder);
end
% save(fullfile(output_folder,strcat(lastPart,"_XYZw_all.mat")), ...
%         "XYZw_all");