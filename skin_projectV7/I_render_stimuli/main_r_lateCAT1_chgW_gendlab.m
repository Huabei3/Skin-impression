close all; 
clc;       
clear;     

%%
%------------r--------------
source_folder='mask\f04r';

slashes = strfind(source_folder, '\');
lastPart=source_folder(slashes(1,end)+1:end);
model = lastPart(1:end-1);
model=gen_lastPart_old(model);
i_type=select_type(model);

files = dir(strcat(source_folder,'\*.jpg'));  % 读取文件夹中的所有.jpg文件

dir_mask=dir(strcat("mask\",lastPart,"\*.jpg"));
dir_XYZfile=dir(fullfile("XYZ\1227_r_chgW",lastPart,"*.mat"));


%----------------------
ct=["H3K","H4K","H5K","H6K","H7K","H8K","HD65",...
"L3K","L4K","L5K","L6K","L7K","L8K","LD65",...
"M3K","M4K","M5K","M6K","M7K","M8K","MD65"];


load(fullfile("aveSkinByHand2","i",strcat("aveLab_D65_",num2str(i_type),".mat")), ...
    "labC_HD65");


average_file=fullfile("aveSkinColor",lastPart,"autoNhand_scaleoverLUT.mat");
average=load(average_file);
average=average.average_lab_all(:,1:3);


save_folder=fullfile('rendered\33_r_lateCAT1_chgW',lastPart);
if ~exist(save_folder, 'dir')
    mkdir(save_folder);
end

num_points = readmatrix('points_added_33.xlsx'); 
num_points=[zeros(length(num_points),1),num_points];
model=gen_lastPart_new(model);
load(fullfile("light_r\model_tcp",strcat(model,".mat")));

i_the=1;
for i = 1:length(files)

    filename = fullfile(files(i).folder, files(i).name);      
    img0=imread(filename);
%--------先跑小图看问题--------
    % img0 = imresize(img0, [size(img0,1)./6, size(img0,2)./6]);

    img=im2double(img0);
    [m,n,p]=size(img);

    startCenter=1;
    endCenter=length(num_points);

    for i_mask=1:length(dir_mask)
        if strcmp(files(i).name(1:end-4),dir_mask(i_mask).name(1:end-4))
            picname_check{i,1}=files(i).name(1:end-4);
            picname_check{i,2}=dir_mask(i_mask).name(1:end-4);
            bull=imread(strcat(dir_mask(i_mask).folder,'\',dir_mask(i_mask).name));
            % bull = imresize(bull, [size(bull,1)./6, size(bull,2)./6]);%先跑小图看问题
            break
        end
    end
    for i_xyz=1:length(dir_XYZfile)
        if strcmp(dir_XYZfile(i_xyz).name(end-7:end-4),files(i).name(1:end-4))
            picname_check{i,4}=dir_XYZfile(i_xyz).name(1:end-4);
            XYZ=load(fullfile(dir_XYZfile(i_xyz).folder,dir_XYZfile(i_xyz).name));
            XYZ=XYZ.XYZ_cropped;
            % XYZ = imresize(XYZ, [size(XYZ,1)./6, size(XYZ,2)./6]);
            break
        end
    end
    if average(i,1)<=60
        C_pre=6.7421*log(average(i,1))-9.9816;%亮度实验
    else
        C_pre=6.7421*log(60)-9.9816;%亮度实验
    end
    factor(i,:)=C_pre./labC_HD65(1,4);
    dlabs=repmat([average(i,1),labC_HD65(1,2:3)],length(num_points),1)+num_points;
    dlabs(:,2:3)=dlabs(:,2:3).*factor(i,:);
    %-----------后CAT-----------
    wd65_64=[94.813  100.000  107.262];
    CCT=model_tcp_mean(i,1);
    XYZw_pre=CCT2xyz(CCT);
    [CCT1,duv,S_out] = xyz2CCT(XYZw_pre,10);
    
    for i_dlab=1:length(dlabs)
        XYZ_bf(i_dlab,:)=lab2xyz2(dlabs(i_dlab,:),"d65_64");   
        XYZ_aft(i_dlab,:) = CAT16_D(XYZ_bf(i_dlab,:),wd65_64, XYZw_pre,1);
        dlabs(i_dlab,:)=xyz2lab(XYZ_aft(i_dlab,:),"d65_64");
    end

    for i_points=endCenter:-1:startCenter

        %--------算中心-------

        dlab=dlabs(i_points,:);
        delta_Lab=dlab-average(i,:);
        dlab_theo{i_the,1}=strcat(files(i).name(1:end-4),'_', ...
            sprintf('%02d', i_points));
        dlab_theo{i_the,2}=dlab;
        i_the=i_the+1;


    end

end
output_folder=fullfile(save_folder,"theo_dlab");
if ~exist(output_folder,"dir")
    mkdir(output_folder);
end
save(fullfile(output_folder,'theo_dlab.mat') ,"dlab_theo");
mean(cell2mat(dlab_theo(:,2)))

%% test


%% 辅助函数

function [ de1, dest_lab_1, dest_lab2] = cal_de1(out_rendering, bull_nosd, lab2,xyz1,xyz2)

    % 将 out_rendering 转换为 uint8 并重塑
    out_rendering=double(out_rendering).*255;
    [m,n,p]=size(out_rendering);
    out1 = reshape(out_rendering , [m * n, p]);
    datai_file = 'calibResults\model3d_file_350_1deg_realP3\datai_ipv40_3.mat';
    wd65=[94.813  100.000  107.262];
    LUT=load(datai_file);
    XYZw_LUT=LUT.XYZw;
    wd65_scaled=wd65./100.*XYZw_LUT(2);


    % 将 RGB 转换为 XYZ
    xyz_1 = lut3d_rgb2xyz1(out1, datai_file);

    % 对 XYZ 数据进行截断
    xyz_1(xyz_1 > XYZw_LUT(2)) = XYZw_LUT(2);

    % 将 XYZ 转换为 Lab
    lab_1 = xyz2lab(xyz_1, 'user', wd65_scaled);

    % 处理 bull 图像
    % bull_nosd=double(bull_nosd)./255;
    % bull_reshaped=reshape(bull_nosd, [m * n, size(bull_nosd,3)]);
    bull_reshaped = reshape(bull_nosd, [m * n, size(bull_nosd,3)]) ./ 255;
    bull_reshaped = double(bull_reshaped);

    % 找到所有像素值为 0 的位置
    logicalIndex = all(bull_reshaped == 0, 2);
    
    % 提取非零像素的 Lab 值
    dest_lab_1 = lab_1(~logicalIndex, :);
    dest_lab2 = lab2(~logicalIndex, :);
    % nan1_indices = find(any(isnan(dest_lab_1), 2)); 
    % nan2_indices = find(any(isnan(dest_lab2), 2)); 
    % 计算 Delta E 2000
    de1 = deltaE2000(dest_lab_1, dest_lab2);
    means_dlab=[mean(dest_lab_1),mean(dest_lab2)];
    % de1=deltaE2000(mean(dest_lab_1),mean(dest_lab2));
    de1 = de1';
    de_mean1=deltaE2000(mean(dest_lab_1), mean(dest_lab2));
    disp(["dest_lab_1&dest_lab2:",mean(de1),de_mean1])
end

function[light_str]= select_light_r(model,pic_name_r)
    %---------读取cct---------
    ct_base=[3000,4000,5000,6000,7000,8000,6500];
    ct_base_name=["3K","4K","5K","6K","7K","8K","D65"];
    lightdata_i=load("pmcc\lightbox\Caucasion.mat", ...
        "XYZ_white_unscaled");
    intensity_i=lightdata_i.XYZ_white_unscaled;
    intensity_i(22,:)=[];
    load(strcat("light_r\model_light\",model,".mat"), ...
    "XYZ_white_unscaled","ind_light");
    ind_sheet = cellfun(@(x) strcmp(x, pic_name_r), ind_light(:,1));
    cct=ind_light{ind_sheet,4};
    %--------获得ct_str---------
    [~, ind_cct] = min(abs(ct_base - cct));
    ct_str=ct_base_name(ind_cct);  
    %---------读取intensity--------------------------------
    XYZ_ind=XYZ_white_unscaled(ind_sheet,:);
    [~, closest_index] = min(abs(intensity_i(:,2) - repmat(XYZ_ind(1,2),length(intensity_i),1)));
    if closest_index<=7
        hml_str="H";
    elseif closest_index>=8&&closest_index<=14
        hml_str="L";
    elseif closest_index>=15&&closest_index<=21
        hml_str="M";
    end
    light_str=strcat(hml_str,ct_str);


end




