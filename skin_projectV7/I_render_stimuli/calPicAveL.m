close all; % 关闭所有图窗
clc;       % 清空命令窗口
clear;     % 清除工作区所有变量
%%

source_folder="Z:\homes\Peggy\VIVOskinExpe\Hassel_downsampled\MD65\cropped\CardMasked";
files = dir(fullfile(source_folder,'*.jpg'));  % 读取文件夹中的所有.jpg文件

save_folder=fullfile(source_folder,'PicAveLab');
if ~exist(save_folder,"dir")
    mkdir(save_folder);
end

average_rgb_all=[];average_xyz_all=[];average_lab_all=[];
de_all=[];de00_all=[];de00c_all=[];

for i = 1:numel(files) 
    
    img=imread(fullfile(files(i).folder, files(i).name));
    [m, n, p] = size(img);

    img=im2double(img);

    % 计算每个通道的平均值
    avg_r = mean(mean(img(:,:,1)));
    avg_g = mean(mean(img(:,:,2)));
    avg_b = mean(mean(img(:,:,3)));
    % 合并成一个RGB向量
    average_rgb1 = [avg_r, avg_g, avg_b];

    average_xyz1 = srgb2xyz(average_rgb1);
    [average_lab1] = xyz2lab(average_xyz1,'d65_64');

    %%
    %先算lab再平均
    

    out = reshape(img, [m * n, p]);   
    xyz = srgb2xyz(out);
    [lab] = xyz2lab(xyz,'d65_64');
    average_lab2=mean(lab);
    [average_xyz2] = lab2xyz2(average_lab2,'d65_64');


%%
    % load(fullfile(dir_setPoints(i).folder,dir_setPoints(i).name));
    % [de1,~,~,~] = cielabde(average_lab1,center0);
    % [de2,~,~,~] = cielabde(average_lab2,center0);
    % [de001,de00c1] = deltaE2000(average_lab1,center0);
    % [de002,de00c2] = deltaE2000(average_lab2,center0);
    % 
    average_rgb_all=[average_rgb_all;average_rgb1];
    average_xyz_all=[average_xyz_all;[average_xyz1,0,average_xyz2]];
    average_lab_all=[average_lab_all;[average_lab1,0,average_lab2]];
    % de_all=[de_all;[de1,de2]];
    % de00_all=[de00_all;[de001,de002]];
    % de00c_all=[de00c_all;[de00c1,de00c2]];
end
lab2_mean=mean(average_lab_all(:,5:7));
save(fullfile(save_folder,strcat('PicAveLab.mat')), ...
'average_lab_all','lab2_mean');
disp("done");

