close all; % 关闭所有图窗
clc;       % 清空命令窗口
clear;     % 清除工作区所有变量
%%
% dir_cropped=dir("Z:\homes\Peggy\oppoSkinExperi\picked40\Hassel\downSampled1\cropped\*.jpg");
% cenfile="Z:\homes\Peggy\oppoSkinExperi\picked40\Hassel\downSampled1\cropped\aveSkinByHand\autoNhand.mat";
dir_cropped=dir("Z:\homes\Peggy\oppoSkinExperi\picked40\iphone\cropped\*.jpg");
cenfile="Z:\homes\Peggy\oppoSkinExperi\picked40\iphone\cropped\aveSkinByHand\autoNhand.mat";
average_lab_all=load(cenfile);
average_lab_all=average_lab_all.average_lab_all(:,5:7);
filename = 'Z:\homes\Peggy\oppoSkinExperi\points48.xlsx';                               %文件名
num_points = readmatrix(filename); 
num_center = num_points(53,:); 
num_points(50:53,:)=[];

% inner=zeros(49,1);
% inner(1:8,1)=1;inner(17:24,1)=1;inner(33:40,1)=1;

for i_aveLab=1:length(average_lab_all)
    centers=zeros(49,3);    
    delta_Lab=zeros(49,3);    
    delta_Lab1=zeros(49,3);
    center0=average_lab_all(i_aveLab,:);
    for i_points=1:length(num_points)
        delta_Lab(i_points,:)=num_points(i_points,:)-num_center;
        % centers(i_points,:)=0.7*delta_Lab(i_points,:)+center0;
        centers(i_points,:)=0.7*delta_Lab(i_points,:)+center0;
    end
save(strcat("Z:\homes\Peggy\oppoSkinExperi\picked40\iphone\cropped\setPointsUseMask\setPointsUseMask07" + ...
    "\setPoints",dir_cropped(i_aveLab).name(9:end-4),".mat"), ...
    'center0','centers','delta_Lab','delta_Lab1');
% save(strcat("Z:\homes\Peggy\oppoSkinExperi\picked40\Hassel\downSampled1\cropped\setPoints\setPoints07" + ...
%     "\setPoints0.7",dir_cropped(i_aveLab).name(1:end-4),".mat"), ...
%     'center0','centers','delta_Lab','delta_Lab1');

end
disp("done");


%%
load("Z:\homes\Peggy\oppoSkinExperi\picked40\iphone\cropped\" + ...
    "setPointsUseMask\setPointsUseMask07\setPointsnight01.mat");