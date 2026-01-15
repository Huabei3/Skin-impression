close all; % 关闭所有图窗
clc;       % 清空命令窗口
clear;     % 清除工作区所有变量
addpath("utils\")
%%
%-----------rs----------

source_folder='dsp\f05\r\jpg\noCard';

slashe1 = find(source_folder=='\',4,'last');
slashe2 = find(source_folder=='\',3,'last');
lastPart = source_folder(slashe1+1:slashe2-1);
lastPart=[lastPart,'r'];

%-----------i--------------

% source_folder='dsp\maleVIVO\i';
% slashe1 = find(source_folder=='\',2,'last');
% slashe2 = find(source_folder=='\',1,'last');
% lastPart = source_folder(slashe1+1:slashe2-1);
% lastPart=[lastPart,'i'];
%--------------

files = dir(fullfile(source_folder,'*.jpg'));  % 读取文件夹中的所有.jpg文件
for i = 1:numel(files)
    if strcmp(files(i).name,"blue.jpg")
        files(i)=[];
    end
end
% dir_XYZ=dir("D:\work\VIVOskinExpe\renderCode\XYZ\maxw1\maleVIVOr\*.mat");

% dir_XYZ=dir(strcat("XYZ",lastPart,"\*.mat"));

wd65=[94.813  100.000  107.262];



for i = 1:numel(files) 
        dir_XYZ=dir(strcat("XYZ\rs\",lastPart,"\*.mat"));


        for i_xyz=1:length(dir_XYZ)
            if strcmp(dir_XYZ(i_xyz).name(end-7:end-4),files(i).name(1:end-4))
                picname_check{i,3}=dir_XYZ(i_xyz).name(1:end-4);
                XYZdata=load(strcat(dir_XYZ(i_xyz).folder,'\',dir_XYZ(i_xyz).name));
                XYZ=XYZdata.XYZ_cropped;
                XYZw=XYZdata.XYZw;


                XYZw_all(i,:)=XYZw;

                break
            end
        end
        
        xyz = reshape(XYZ, [size(XYZ,1) * size(XYZ,2), size(XYZ,3)]); 
        xyz_mean=mean(xyz);


        datafile = 'calibResults\data_ipv35_3.mat';
        LUT=load(datafile);
        XYZw_LUT=LUT.XYZw;
        wd65_scaled=wd65./100.*XYZw_LUT(2);
        
        [lab_mean(i,:)] = xyz2lab(xyz_mean,'user',wd65_scaled);
        lab_gray(i,:)=[lab_mean(i,1),0,0];
        xyz_gray(i,:)=lab2xyz2(lab_gray(i,:),'user',wd65_scaled);
        [rgb_gray(i,:),out_of_gamut_ratio] = lut3d_xyz2rgbNoPar(xyz_gray(i,:), datafile);
        hex_gray{i,1}=rgb2hex(rgb_gray(i,:)./255);
        hex_gray{i,2}=files(i).name(1:end-4);


end
save_folder="backgroundGray\r";
save(fullfile(save_folder,strcat("backGroundGray",lastPart,".mat")), ...
    "rgb_gray","lab_gray","xyz_gray","hex_gray");

disp("done");

%%

function hexColor = rgb2hex(rgb)
    % RGB2HEX Convert RGB values to a hexadecimal color string
    %   hexColor = rgb2hex(rgb) converts the RGB values in the range [0, 1]
    %   to a hexadecimal color string.
    
    % Ensure the RGB values are in the range [0, 1]
    if any(rgb < 0) || any(rgb > 1)
        error('RGB values must be in the range [0, 1].');
    end
    
    % Scale the RGB values to the range [0, 255]
    rgb = round(rgb * 255);
    
    % Convert each RGB component to a two-digit hexadecimal string
    hexColor = sprintf('#%02X%02X%02X', rgb(1), rgb(2), rgb(3));
end
