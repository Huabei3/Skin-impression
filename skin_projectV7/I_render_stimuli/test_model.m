clc;clear;close all;
addpath("utils\");
%%
wd65=[94.813  100.000  107.262];
ct=["H3K","H4K","H5K","H6K","H7K","H8K","HD65",...
"L3K","L4K","L5K","L6K","L7K","L8K","LD65",...
"M3K","M4K","M5K","M6K","M7K","M8K","MD65"];
CT = [3000, 4000, 5000, 6000, 7000, 8000, 6500, ...
  3000, 4000, 5000, 6000, 7000, 8000, 6500, ...
  3000, 4000, 5000, 6000, 7000, 8000, 6500]';
attribute_names = ["Preference", "Attractiveness", "Feminine", "Cooperative", ...
"Youth", "Healthy", "Precise reproduction", "suit the environment or not",...
"white-skinned", "ruddy"]; 
Dtype="summer";
datai_file = 'calibResults\model3d_file_350_1deg_realP3\datai_ipv40_3.mat';
wd65_64=[94.813  100.000  107.262];
LUT=load(datai_file);
XYZw_LUT=LUT.XYZw;
wd65_scaled=wd65_64./100.*XYZw_LUT(2);

source_folder='D:\work\VIVOskinExpe\renderCode\rendered\33_i_lL_C\female78i';
files = dir(strcat(source_folder,'\*.jpg'));  % 读取文件夹中的所有.jpg文件
slashes=find(source_folder=='\');
lastPart=source_folder(slashes(end)+1:end);
lastPart=gen_lastPart_new(lastPart);
lastPart=char(lastPart);
lastPart_old=gen_lastPart_old(lastPart);
skin_type=lastPart(1:end-1);

dir_mask=dir(strcat("mask\",lastPart,"\*.jpg"));

if ismember(lastPart,["f04i","f05i","f06i","m04i","m06i"]) 
    if_wei=0;
else
    if_wei=1;
end

save_folder=fullfile(source_folder,'check_lab','fromPics');
if ~exist(save_folder,"dir")
    mkdir(save_folder);
end
%%
% 初始化 Map
groupMap = containers.Map('KeyType', 'char', 'ValueType', 'any');
i_y=1;
for i = 1:numel(files) 
    slashes0 = find(files(i).name == '_');
    slashes1 = find(files(i).name == '[');
    slashes2 = find(files(i).name == ',');
    slashes3 = find(files(i).name == ']');
    light_name=files(i).name(1:slashes0-1);
    dlab(i,1) = str2double(files(i).name(slashes1+1:slashes2(1)-1));
    dlab(i,2) = str2double(files(i).name(slashes2(1)+1:slashes2(2)-1));
    dlab(i,3) = str2double(files(i).name(slashes2(2)+1:slashes3-1));

    picname_group=files(i).name(1:slashes0-1);
    serial=str2num(files(i).name(slashes0+1:slashes1-1));
    % 将文件索引 i 添加到对应的 CT 组
    for i_CT = 1:length(ct)
        if contains(files(i).name, num2str(ct(i_CT)))
            key = ct{i_CT}; % 使用 ct 中的元素作为键
            if isKey(groupMap, key)
                groupMap(key) = [groupMap(key); i]; % 添加索引 i
            else
                groupMap(key) = i; % 初始化键值对
            end
            break;
        end
    end

    [CCT,i_light] = find_CCT_i(picname_group);
    for i_mask=1:length(dir_mask)
        if strcmp(picname_group,dir_mask(i_mask).name(1:end-4))
            picname_check{i,1}=files(i).name(1:end-4);
            picname_check{i,2}=dir_mask(i_mask).name(1:end-4);
            bull=imread(strcat(dir_mask(i_mask).folder,'\',dir_mask(i_mask).name));
            % bull = imresize(bull, [size(bull,1)./6, size(bull,2)./6]);%先跑小图看问题
            break
        end
    end
    img=imread(fullfile(files(i).folder,files(i).name));
    [m ,n, p]=size(img);
    img=double(img);
    rgb = reshape(img, [m * n, p]); % 灞曞紑
    [average_rgb]=get_average(rgb,bull,if_wei);
    if max(rgb(:,2))<=1
        rgb_vi=rgb.*255;
    else
        rgb_vi=rgb;
    end
    xyz_vi=lut3d_rgb2xyz1(rgb_vi, datai_file);
    lab_vi=xyz2lab(xyz_vi,'user',wd65_scaled);
    [average_lab]=get_average(lab_vi,bull,if_wei);
    
    for attribute=1:10
        attribute_serial = strcat(sprintf("%02d", attribute), ...
            attribute_names(attribute));
        dir_labNscore=dir(fullfile("..\analyze\AnalyseResults",Dtype,lastPart_old,  ...
            "all",attribute_serial,"labNscore","*.mat"));
        for i_lNs=1:length(dir_labNscore)
            %加载真实分数
            labNscore_name=dir_labNscore(i_lNs).name(1:end-4);
            labNscore_name=strrep(labNscore_name,"labNscore_group","");
            picname_ind_group=lower(strcat(lastPart_old,picname_group));
            if strcmp(labNscore_name,picname_ind_group)
                MSVNlab=load(fullfile(dir_labNscore(i_lNs).folder, ...
                    dir_labNscore(i_lNs).name));
                lab_group = MSVNlab.lab_group; % 原始 lab_group
                MSV_group = MSVNlab.MSV_group; % 原始 MSV_group
                y_vi{i_y,attribute}=MSV_group(serial);
                lab_save{i_y,attribute}=lab_group(serial,:);
                break
            end          

        end
        %预测
        [y,lab_rgb]=predict_score(skin_type,average_rgb,"RGB",attribute,CCT);
        y_pre{i_y,attribute}=y;
        % [y1,lab_lab]=predict_score(skin_type,average_lab,"lab",attribute,CCT);
        % y_pre_lab{i_y,attribute}=y1;
        % dE(i_y,attribute)=deltaE2000(lab_rgb,lab_lab);
        % dE_viNsave(i_y,attribute)=deltaE2000(lab_save{i_y,attribute},lab_lab);
    end
    y_pre{i_y,end+1}=files(i).name;
    % y_pre_lab{i_y,11}=files(i).name;
    y_vi{i_y,end+1}=files(i).name;
    
    i_y=i_y+1;
end
%%
y_pre_mat=cell2mat(y_pre(:,1:10));
% y_pre_lab_mat=cell2mat(y_pre_lab(:,1:10));
for i = 1:size(y_vi, 2)
    empty_indices = cellfun(@isempty, y_vi(:, i)); % 找到空单元的索引
    y_vi(empty_indices, i) = {NaN}; % 替换为空单元
end

y_vi_mat=cell2mat(y_vi(:,1:10));

r = corr(y_pre_mat,y_vi_mat);
for i_CT = 1:length(CT)
    for attribute=1:10
        key = ct{i_CT};
        CT_idx=groupMap(key);
        r_mat(i_CT,attribute)=corr(y_pre_mat(CT_idx,attribute), ...
            y_vi_mat(CT_idx,attribute));
        % r_mat_lab(i_CT,attribute)=corr(y_pre_lab_mat(CT_idx,attribute), ...
        %     y_vi_mat(CT_idx,attribute));
    end
end
% r_mat(end+1,:)=mean(r_mat(1:end,:),1);
% r_mat(:,end+1)=mean(r_mat(:,1:end),2);
% % 创建一个空的单元格数组，用于存储最终结果
% r_cell = cell(size(r_mat, 1) + 1, size(r_mat, 2) + 1);
% r_cell(1, 2:end) = cellstr([attribute_names,"mean"]);
% r_cell(2:end, 1) = cellstr([ct',"mean"]);
% r_cell(2:end, 2:end) = double2cell(r_mat);

save_folder=fullfile(source_folder,"y_pre_10attr");
if ~exist(save_folder)
    mkdir(save_folder);
end
save(fullfile(save_folder,"y_pre_10attr.mat"), ...
    "y_pre","r_mat",'groupMap');

disp("d")
%%
% source_folder='D:\work\VIVOskinExpe\renderCode\rendered\33_i_lL_C\female78i';
load(fullfile(source_folder,"y_pre_10attr","y_pre_10attr.mat"), ...
    "y_pre","r_mat",'groupMap');
y_pre_mat=cell2mat(y_pre(:,1:10));
% 定义目标文件夹
destFolder1 = fullfile(source_folder, 'best_images');
if ~exist(destFolder1, 'dir')
    mkdir(destFolder1);
end

text_color_number = [255, 0, 0]; % 橙色 (R, G, B) - 用于图像编号
% 遍历每个 CT 和每个属性
for i_CT = 1:length(CT)
    key = ct(i_CT);
    CT_idx = groupMap(key);
    for attribute = 1:10
        attribute_serial = strcat(sprintf("%02d", attribute), attribute_names(attribute));
        attribute_serial_new = gen_attribute_new(attribute_serial);

        % 找到最佳图片索引
        [max_val, max_idx] = max(y_pre_mat(CT_idx, attribute));
        idx_best = CT_idx(max_idx);

        % 读取最佳图片
        img = imread(fullfile(files(idx_best).folder, files(idx_best).name));
        % 在图片上添加文本
        text_str = sprintf('%.2f', max_val);  % 格式化文本
        sz=size(img);
        font_size=round(sz(2)./15);
        text_position=[sz(2) - font_size * 6, sz(1) - font_size * 1.5];
        img_with_text = insertText(img, text_position, text_str, ...
            'FontSize', font_size,'TextColor', text_color_number, 'BoxOpacity', 0);

        % 修改文件名并保存到 destFolder1
        [~, name, ext] = fileparts(files(idx_best).name);
        slash=find(name=='_');
        new_name = strcat(name(1:slash-1), '_', ...
            attribute_serial_new,name(slash+1:end), ext);
        imwrite(img_with_text, fullfile(destFolder1, new_name));

    end
end
%%
font_size=round(sz(2)./30);
destFolder2 = fullfile(source_folder, 'special_groups');
if ~exist(destFolder2, 'dir')
    mkdir(destFolder2);
end
% 第二个循环：处理特殊组（i_CT = 7, 14, 21），将所有图片保存到 destFolder2
special_groups = [7, 14, 21];
for i_CT = special_groups
    key = ct(i_CT);
    CT_idx = groupMap(key);
    for i_ing = 1:length(CT_idx)
        idx = CT_idx(i_ing);
        img = imread(fullfile(files(idx).folder, files(idx).name));
        img_with_text=img;
        for attribute = 1:10
            attribute_serial = strcat(sprintf("%02d", attribute), attribute_names(attribute));
            attribute_serial_new = gen_attribute_new(attribute_serial);
    
            text_str=strcat(attribute_serial_new, ...
                sprintf('%.2f', y_pre_mat(idx, attribute)));
            img_with_text = insertText(img_with_text, ...
                [10, 10 + (attribute - 1) * font_size], text_str, ...
                'FontSize', font_size, 'TextColor', text_color_number, ...
                'BoxOpacity', 0);
            
        end
        imwrite(img_with_text, fullfile(destFolder2, files(idx).name));
    end
end
disp("d")