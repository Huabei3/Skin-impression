% Compute average Lab values for pixels where mask ~= 255
clc;clear;close all;
addpath("..\utils\");
%% 提取肤色以外点的像素平均来做白平衡
% david_table_file=fullfile("D:\work\ZJU_entire_skin\David\Naturalness model\Jason's final project\data analysis\res\separate_skin_methods\resTable\quality\David_table.mat");
% david_table_data=load(david_table_file);
% david_table=david_table_data.fit_table;
% 
% baseFolder = "D:\work\ZJU_entire_skin\ZJU_skin_database\A_images\David\rendered_imgs";
% 
% imgFiles = dir(fullfile(baseFolder, "skin_*.jpg"));
% 
% mask_folder=fullfile(baseFolder,"mask");
% cat_folder=fullfile(baseFolder,"cat");
% if ~exist(cat_folder,"dir")
%     mkdir(cat_folder);
% end
% 
% 
% idx_imgs=[1,5,7,9,10,2,3,4,6,8];
% lab_ave_all_cell = cell(length(idx_imgs), 2);
% for i = 1:length(idx_imgs)
%     idx_img=idx_imgs(i);
%     baseName=sprintf("skin_%d",idx_img);
%     dir_idx_img=dir(fullfile(baseFolder, sprintf("skin_%d_*.jpg",idx_img)));
%     lab_ave_cell = cell(length(dir_idx_img), 2);
%     for i_point=1:length(dir_idx_img)
%         imgPath = fullfile(dir_idx_img(i_point).folder,dir_idx_img(i_point).name);    
%         maskPath = fullfile(mask_folder, strcat(baseName , "_mask.jpg"));
% 
%         img_ = imread(imgPath);
%         mask = imread(maskPath);
% 
%         if ndims(mask) == 3
%             mask = mask(:, :, 1);
%         end
% 
%         img_ = im2double(img_);
%         sz_mask=size(mask);
%         sz_img=size(img_);
%         if sz_img(1)~=sz_mask(1)
%             img_=imresize(img_,[sz_mask(1) , sz_mask(2)]);
%         end
% 
%         img = reshape(img_, [sz_mask(1) * sz_mask(2), 3]);    
%         mask=reshape(mask, [sz_mask(1) * sz_mask(2),1]);
% 
% 
%         xyz = srgb2xyz(img.*255);
%         lab = xyz2lab(xyz, "d65_64");
% 
%         idx = mask ~= 255;
%         if ~any(idx)
%             idx = true(size(mask));
%         end
% 
%         img2=img;
%         img2(~idx,:)=0;
%         img2_2d=reshape(img2,[sz_mask(1) , sz_mask(2), 3]);
%         imshow(img2_2d);    
% 
%         rgb_ave_cell{i_point, 1} = mean(img(idx, :));
%         rgb_ave_cell{i_point, 2} = dir_idx_img(i_point).name;
% 
%         xyz_ave_cell{i_point, 1} = mean(xyz(idx, :));
%         xyz_ave_cell{i_point, 2} = dir_idx_img(i_point).name;
% 
%         lab_ave_cell{i_point, 1} = mean(lab(idx, :));
%         lab_ave_cell{i_point, 2} = dir_idx_img(i_point).name;
% 
%         % White balance using mean RGB of non-skin pixels (gray-world)
% 
%         mean_rgb = rgb_ave_cell{i_point, 1};
%         CAT02
%         target = mean(mean_rgb);
%         gains = target ./ mean_rgb;
%         wb_img = img_ .* reshape(gains, 1, 1, 3);
%         wb_img = min(max(wb_img, 0), 1);
%         imwrite(wb_img, fullfile(cat_folder, dir_idx_img(i_point).name));
% 
% 
%         xyz_ori=srgb2xyz(rgb_ori);
%         XYZ_CATed = SimpleTwostepCAT_Dt (xyz_ori,Dt);
%         rgb_CATed=display_r(XYZ_CATed./100,savefile);
%         rgb_CATed1=reshape(rgb_CATed, [sz(1) , sz(2), sz(3)]);
%         XYZ_CATed1=reshape(XYZ_CATed, [sz(1) , sz(2), sz(3)]);
% 
%     end
% 
% 
%     rgb_ave_all_cell{i, 1} = rgb_ave_cell;
%     rgb_ave_all_cell{i, 2} = baseName;
% 
%     xyz_ave_all_cell{i, 1} = xyz_ave_cell;
%     xyz_ave_all_cell{i, 2} = baseName;
% 
%     lab_ave_all_cell{i, 1} = lab_ave_cell;
%     lab_ave_all_cell{i, 2} = baseName;
% end
% 
% output_folder="res";
% if ~exist(output_folder,"dir")
%     mkdir(output_folder);
% end
% save(fullfile(output_folder,"extracted_white.mat"),"lab_ave_all_cell","rgb_ave_all_cell","xyz_ave_all_cell");
%% david拟合椭圆的渲染点 和 图片提取的渲染点 的排列顺序
% lab_ave_file = fullfile("res", "lab_ave_extracted.mat");
% 
% lab_ave_data = load(lab_ave_file, "lab_ave_all_cell");
% lab_ave_all_cell = lab_ave_data.lab_ave_all_cell;
% 
% 
% david_table_file=fullfile("D:\work\ZJU_entire_skin\David\Naturalness model\Jason's final project\data analysis\res\separate_skin_methods\resTable\quality\David_table.mat");
% david_table_data=load(david_table_file);
% david_table=david_table_data.fit_table;
% 
% figure(1); hold on; 
% for i_row = 1:16
%     lab_val = lab_ave_all_cell{1,1}{i_row, 1};
%     % scatter(lab_val(:,2), lab_val(:,3));
%     plot(lab_val(1,2), lab_val(1,3), 'o', 'Color', 'b', 'MarkerSize', 6);
%     text(lab_val(1,2), lab_val(1,3), num2str(i_row));
% 
% end
% for i_row = 2:17
%     lab_david=david_table.lab_values{1}(i_row,:);
%     plot(lab_david(1,2), lab_david(1,3), 'o', 'Color', 'r', 'MarkerSize', 6);
%     text(lab_david(1,2), lab_david(1,3), num2str(i_row));
% end
% figure(2); hold on; 
% for i_row = 17:32
%     lab_val = lab_ave_all_cell{1,1}{i_row, 1};
%     % scatter(lab_val(:,2), lab_val(:,3));
%     plot(lab_val(1,2),lab_val(1,1),  'o', 'Color', 'b', 'MarkerSize', 6);
%     text(lab_val(1,2),lab_val(1,1),  num2str(i_row));
%     % disp(lab_val)
% end
% for i_row = 18:33
%     lab_david=david_table.lab_values{1}(i_row,:);
%     plot(lab_david(1,2), lab_david(1,1), 'o', 'Color', 'r', 'MarkerSize', 6);
%     text(lab_david(1,2), lab_david(1,1), num2str(i_row));
% end
% figure(3); hold on; 
% for i_row = 33:48
%     lab_val = lab_ave_all_cell{1,1}{i_row, 1};
%     % scatter(lab_val(:,2), lab_val(:,3));
%     plot(lab_val(1,3),lab_val(1,1),  'o', 'Color', 'b', 'MarkerSize', 6);
%     text(lab_val(1,3),lab_val(1,1),  num2str(i_row));
%     % disp(lab_val)
% end
% for i_row = 34:49
%     lab_david=david_table.lab_values{1}(i_row,:);
%     plot(lab_david(1,3), lab_david(1,1), 'o', 'Color', 'r', 'MarkerSize', 6);
%     text(lab_david(1,3), lab_david(1,1), num2str(i_row));
% end
% disp("d")
%% AWB original images

wd65=[94.813  100.000  107.262];
david_table_file=fullfile("D:\work\ZJU_entire_skin\David\Naturalness model\Jason's final project\data analysis\res\separate_skin_methods\resTable\quality\David_table.mat");
david_table_data=load(david_table_file);
david_table=david_table_data.fit_table;

baseFolder = "D:\work\ZJU_entire_skin\ZJU_skin_database\A_images\David\rendered_imgs";

imgFiles = dir(fullfile(baseFolder, "skin_*.jpg"));

mask_folder=fullfile(baseFolder,"mask");

wb_pic_folder="res\wb\pic";
if ~exist(wb_pic_folder,"dir")
    mkdir(wb_pic_folder);
end
idx_imgs=[1,5,7,9,10,2,3,4,6,8];
lab_ave_all_cell = cell(length(idx_imgs), 2);
for i_img = 1:length(idx_imgs)
    idx_img=idx_imgs(i_img);
    baseName=sprintf("skin_%d",idx_img);
    dir_idx_img=dir(fullfile(baseFolder, sprintf("skin_%d_*.jpg",idx_img)));
    % lab_ave_cell = cell(length(dir_idx_img), 2);

    i_point=49;
    imgPath = fullfile(dir_idx_img(i_point).folder,dir_idx_img(i_point).name);    
    maskPath = fullfile(mask_folder, strcat(baseName , "_mask.jpg"));

    img_ = imread(imgPath);
    mask = imread(maskPath);

    if ndims(mask) == 3
        mask = mask(:, :, 1);
    end

    img_ = im2double(img_);
    sz_mask=size(mask);
    sz_img=size(img_);
    if sz_img(1)~=sz_mask(1)
        img_=imresize(img_,[sz_mask(1) , sz_mask(2)]);
    end
    % [Iwb,gain] = grayEdgeWB2(img_, 2, 6);
    % imwrite(Iwb,fullfile(wb_pic_folder,dir_idx_img(i_point).name));

    img = reshape(img_, [sz_mask(1) * sz_mask(2), 3]);    
    % img_wb = reshape(Iwb, [sz_mask(1) * sz_mask(2), 3]);    
    mask=reshape(mask, [sz_mask(1) * sz_mask(2),1]);


    xyz = srgb2xyz(img.*255);
    % xyz_wb = srgb2xyz(img_wb.*255);
    lab = xyz2lab(xyz, "d65_64");
    % lab_wb = xyz2lab(xyz_wb, "d65_64");

    idx = mask ~= 255;
    rgb_white = mean(img(idx,:));
    rgb_white=rgb_white./rgb_white(2);
    rgb_d65=xyz2srgb(wd65)./255;
    gain=rgb_d65./rgb_white;
    img_wb=img.*gain;
    Iwb=reshape(img_wb,[sz_mask(1) , sz_mask(2), 3]);
    imwrite(Iwb,fullfile(wb_pic_folder,dir_idx_img(i_point).name));
    xyz_wb = srgb2xyz(img_wb.*255);
    lab_wb = xyz2lab(xyz_wb, "d65_64");
    % img2=img;
    img2=img_wb;
    img2(idx,:)=0;
    img2_2d=reshape(img2,[sz_mask(1) , sz_mask(2), 3]);
    imshow(img2_2d);    

    lab_ave_cell{idx_img, 1} = mean(lab(~idx, :));
    lab_ave_cell{idx_img, 2} = mean(lab_wb(~idx, :));
    lab_ave_cell{idx_img, 3} = dir_idx_img(i_point).name;
 
end

output_folder="res\wb";
if ~exist(output_folder,"dir")
    mkdir(output_folder);
end
save(fullfile(output_folder,"lab_ave_extracted.mat"),"lab_ave_cell");
%% 提取渲染图平均肤色

% 
% david_table_file=fullfile("D:\work\ZJU_entire_skin\David\Naturalness model\Jason's final project\data analysis\res\separate_skin_methods\resTable\quality\David_table.mat");
% david_table_data=load(david_table_file);
% david_table=david_table_data.fit_table;
% 
% baseFolder = "D:\work\ZJU_entire_skin\ZJU_skin_database\A_images\David\rendered_imgs";
% 
% imgFiles = dir(fullfile(baseFolder, "skin_*.jpg"));
% 
% mask_folder=fullfile(baseFolder,"mask");
% 
% 
% idx_imgs=[1,5,7,9,10,2,3,4,6,8];
% lab_ave_all_cell = cell(length(idx_imgs), 2);
% for i = 1:length(idx_imgs)
%     idx_img=idx_imgs(i);
%     baseName=sprintf("skin_%d",idx_img);
%     dir_idx_img=dir(fullfile(baseFolder, sprintf("skin_%d_*.jpg",idx_img)));
%     lab_ave_cell = cell(length(dir_idx_img), 2);
%     for i_point=1:length(dir_idx_img)
%         imgPath = fullfile(dir_idx_img(i_point).folder,dir_idx_img(i_point).name);    
%         maskPath = fullfile(mask_folder, strcat(baseName , "_mask.jpg"));
% 
%         img_ = imread(imgPath);
%         mask = imread(maskPath);
% 
%         if ndims(mask) == 3
%             mask = mask(:, :, 1);
%         end
% 
%         img_ = im2double(img_);
%         sz_mask=size(mask);
%         sz_img=size(img_);
%         if sz_img(1)~=sz_mask(1)
%             img_=imresize(img_,[sz_mask(1) , sz_mask(2)]);
%         end
% 
%         img = reshape(img_, [sz_mask(1) * sz_mask(2), 3]);    
%         mask=reshape(mask, [sz_mask(1) * sz_mask(2),1]);
% 
% 
%         xyz = srgb2xyz(img.*255);
%         lab = xyz2lab(xyz, "d65_64");
% 
%         idx = mask ~= 255;
% 
%         img2=img;
%         img2(idx,:)=0;
%         img2_2d=reshape(img2,[sz_mask(1) , sz_mask(2), 3]);
%         imshow(img2_2d);    
% 
%         lab_ave_cell{i_point, 1} = mean(lab(~idx, :));
%         lab_ave_cell{i_point, 2} = dir_idx_img(i_point).name;
%     end
%     lab_ave_all_cell{i, 1} = lab_ave_cell;
%     lab_ave_all_cell{i, 2} = baseName;
% end
% 
% output_folder="res";
% if ~exist(output_folder,"dir")
%     mkdir(output_folder);
% end
% save(fullfile(output_folder,"lab_ave_extracted.mat"),"lab_ave_all_cell");
%% 提取原图平均肤色

% david_table_file=fullfile("D:\work\ZJU_entire_skin\David\Naturalness model\Jason's final project\data analysis\res\separate_skin_methods\resTable\quality\David_table.mat");
% david_table_data=load(david_table_file);
% david_table=david_table_data.fit_table;
% 
% baseFolder = "D:\work\ZJU_entire_skin\ZJU_skin_database\A_images\David\rendered_imgs";
% 
% imgFiles = dir(fullfile(baseFolder,"ori", "skin_*.jpg"));
% if isempty(imgFiles)
%     error('No skin_*.jpg found in: %s', baseFolder);
% end
% mask_folder=fullfile(baseFolder,"mask");
% 
% file_names = strings(numel(imgFiles), 1);
% avg_lab = nan(numel(imgFiles), 3);
% 
% idx_imgs=[1,5,7,9,10,2,3,4,6,8];
% for i = 1:numel(imgFiles)
%     baseName=sprintf("skin_%d",idx_imgs(i));
%     imgPath = fullfile(imgFiles(i).folder, strcat(baseName,".jpg"));
%     % imgPath = fullfile(imgFiles(i).folder, imgFiles(i).name);
%     % [~, baseName, ~] = fileparts(iimgFiles(i).name);
%     maskPath = fullfile(mask_folder, strcat(baseName , "_mask.jpg"));
% 
%     if ~exist(maskPath, 'file')
%         fprintf('Mask not found, skip: %s\n', maskPath);
%         continue;
%     end
% 
%     img_ = imread(imgPath);
%     mask = imread(maskPath);
% 
% 
%     if ndims(mask) == 3
%         mask = mask(:, :, 1);
%     end
% 
%     img_ = im2double(img_);
% 
%     img_=imresize(img_,[size(img_,1)/2 , size(img_,2)/2]);
% 
%     sz = size(img_);
% 
%     img = reshape(img_, [sz(1) * sz(2), 3]);    
%     mask=reshape(mask, [sz(1) * sz(2),1]);
% 
% 
%     xyz = srgb2xyz(img.*255);
%     lab = xyz2lab(xyz, "d65_64");
% 
%     idx = mask ~= 255;
% 
%     img2=img;
%     img2(idx,:)=0;
%     img2_2d=reshape(img2,[sz(1) , sz(2), 3]);
%     imshow(img2_2d);
% 
% 
%     avg_lab(i, :) = mean(lab(~idx,:));
%     file_names(i) = strcat(baseName,".jpg");
% end
% 
% avg_lab_table = table(file_names, avg_lab(:, 1), avg_lab(:, 2), avg_lab(:, 3), ...
%     'VariableNames', {'file', 'L', 'a', 'b'});
% 
% disp(avg_lab_table);
