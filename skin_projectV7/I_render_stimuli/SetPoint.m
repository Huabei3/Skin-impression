close all; % 关闭所有图窗
clc;       % 清空命令窗口
clear;     % 清除工作区所有变量
%%
% dir_cenfiles=dir("Z:\homes\Peggy\oppoSkinExperi\picked40\iphone\" + ...
%     "cropped\aveSkinColor\*.mat");
dir_cenfiles=dir("Z:\homes\Peggy\oppoSkinExperi\HasselCropped\aveSkinColor*.mat");
filename = 'Z:\homes\Peggy\oppoSkinExperi\points48.xlsx';                               %文件名
num_points = readmatrix(filename); 
num_center = num_points(53,:); 
num_points(50:53,:)=[];

inner=zeros(49,1);
inner(1:8,1)=1;inner(17:24,1)=1;inner(33:40,1)=1;

for i_cenfiles=1:length(dir_cenfiles)
    load(strcat(dir_cenfiles(i_cenfiles).folder,'\',dir_cenfiles(i_cenfiles).name));
    centers=zeros(49,3);    delta_Lab=zeros(49,3);    delta_Lab1=zeros(49,3);
    for i_points=1:length(num_points)
        delta_Lab(i_points,:)=num_points(i_points,:)-num_center;
        % if inner(i_points,1)==1
            delta_Lab1(i_points,:)=0.7*delta_Lab(i_points,:);
        % else
        %     delta_Lab1(i_points,:)=delta_Lab(i_points,:);
        % end
        centers(i_points,:)=delta_Lab1(i_points,:)+center0;
    end
% save(strcat("Z:\homes\Peggy\oppoSkinExperi\picked40\iphone\cropped\setPoints_sRGBchoose\setPoints09_1" + ...
%     "\setPoints0.9_1",dir_cenfiles(i_cenfiles).name(13:end-4),".mat"), ...
%     'center0','centers','delta_Lab','delta_Lab1');
save(strcat("Z:\homes\Peggy\oppoSkinExperi\HasselCropped\setPoints07new" + ...
    "\setPoints0.7",dir_cenfiles(i_cenfiles).name(13:end-4),".mat"), ...
    'center0','centers','delta_Lab','delta_Lab1');

end
%%
% dir_cenfiles=dir("Z:\homes\Peggy\oppoSkinExperi\picked40\iphone\" + ...
%     "cropped\aveSkinColor\*.mat");
% % dir_cenfiles=dir("Z:\homes\Peggy\oppoSkinExperi\HasselCropped\aveSkinColor*.mat");
% filename = 'Z:\homes\Peggy\oppoSkinExperi\points48.xlsx';                               %文件名
% num_points = readmatrix(filename); 
% num_center = num_points(53,:); 
% num_points(50:53,:)=[];
% 
% for i_cenfiles=1:length(dir_cenfiles)
%     load(strcat(dir_cenfiles(i_cenfiles).folder,'\',dir_cenfiles(i_cenfiles).name));
%     centers=zeros(49,3);
%     for i_points=1:length(num_points)
%         delta_Lab(i_points,:)=num_points(i_points,:)-num_center;
% %         centers(i_points,:)=num_points(i_points,:)-num_center+center0;
%         delta_Lab1=0.6*delta_Lab;
%         centers(i_points,:)=delta_Lab1(i_points,:)+center0;
%     end
% save(strcat("Z:\homes\Peggy\oppoSkinExperi\picked40\iphone\cropped\setPoints_sRGBchoose\setPoints06" + ...
%     "\setPoints0.6",dir_cenfiles(i_cenfiles).name(13:end-4),".mat"), ...
%     'center0','centers','delta_Lab','delta_Lab1');
% %     save(strcat("Z:\homes\Peggy\oppoSkinExperi\picked40\iphone\cropped\setPoints\setPoints08" + ...
% %             "\setPoints0.8",dir_cenfiles(i_cenfiles).name(13:end-4),".mat"), ...
% %             'center0','centers','delta_Lab','delta_Lab1');
% %     save(strcat("Z:\homes\Peggy\oppoSkinExperi\HasselCropped\setPoints" + ...
% %             "\setPoints0.8",dir_cenfiles(i_cenfiles).name(13:end-4),".mat"), ...
% %             'center0','centers','delta_Lab');
% end