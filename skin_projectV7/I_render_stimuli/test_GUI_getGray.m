clear; clc; close all;
%%
new_names = [ "f04", "f05","f06", "m04", "m05","m06"];
ct=["H3K","H4K","H5K","H6K","HD65","H7K","H8K",...
   "M3K","M4K","M5K","M6K","MD65","M7K","M8K", ...
"L3K","L4K","L5K","L6K","LD65","L7K","L8K"];
datai_file = 'calibResults\datai_ipv35_3.mat';
wd65=[94.813  100.000  107.262];
LUT=load(datai_file);
XYZw_LUT=LUT.XYZw;
wd65_scaled=wd65./100.*XYZw_LUT(2);

for i_model =1:length(new_names)
    for i_ct=1:length(ct)
        
        dir_XYZfile=dir(strcat("XYZ\i\",strrep(lastPart,"add",""),"\*.mat"));
        XYZ=load(fullfile('XYZ\i',strcat(new_names(i_model),'i'), ...
            strcat(ct(i_ct),".mat")));
        XYZ=XYZ.XYZ_cropped;
        XYZ=XYZ./XYZw_LUT(2).*100;
        folderPath = 'D:\work\VIVOskinExpe\renderCode\dsp\i';
        img = xyz2srgb(XYZ);

        
        imageFiles = dir(fullfile(folderPath, '*.jpg'));
        numImages = length(imageFiles);
        
        % 初始化矩阵来存储每张图片中正方形区域的裁剪信息
        crop_rect_info = zeros(numImages, 4); % [x, y, width, height]
        
        fig = figure('Name', 'RGB Selection', 'NumberTitle', 'off');
        
        for i_pic = 1:numImages
            imageFile = fullfile(folderPath, imageFiles(i_pic).name);
            img = imread(imageFile);
        
            imshow(img);
            title(['Image: ', imageFiles(i_pic).name, ' - Select 1 point']);
            
            [height, width, ~] = size(img);
            
            h = impoint;
            position = wait(h);
            
            if isempty(position)
                continue;
            end
            
            x = round(position(1));
            y = round(position(2));
            
            if x < 1 || x > width || y < 1 || y > height
                disp('Selected point is out of bounds, please select a point within the image.');
                continue;
            end
            
            % 计算正方形的边界
            sideLength = 30; % 正方形边长
            halfSideLength = sideLength / 2;
            xMin = max(1, x - halfSideLength);
            xMax = min(width, x + halfSideLength);
            yMin = max(1, y - halfSideLength);
            yMax = min(height, y + halfSideLength);
            
            % 保存正方形区域的裁剪信息
            picname(i_pic,1)={imageFiles(i_pic).name};
            crop_rect_info(i_pic, :) = [xMin, yMin, sideLength, sideLength];
        end
        
        close(fig);
        
        % 保存crop_rect_info到MATLAB文件
        % outputFolder = fullfile(output_folder, "crop_rect_info");
        % if ~exist(outputFolder, "dir")
        %     mkdir(outputFolder);
        % end
    end
end
% outputFolder="whiteSquare";
outputFolder="skinSquare";
if ~exist(outputFolder, "dir")
    mkdir(outputFolder);
end
filename = fullfile(outputFolder, strcat('crop_rect_info_white_',lastPart,'.mat'));
save(filename, 'crop_rect_info','picname');