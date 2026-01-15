close all; % 关闭所有图窗
clc;       % 清空命令窗口
clear;     % 清除工作区所有变量
addpath("utils\");
%%


%-----------i--------------
% source_folder='D:\work\VIVOskinExpe\renderCode\dsp\maleVIVO\i';
source_folder='dsp\f02\i';
% source_folder='Z:\homes\Peggy\VIVOskinExpe\imageCapture\Hassel\dsp\femaleVIVO\i';
slashe1 = find(source_folder=='\',2,'last');
slashe2 = find(source_folder=='\',1,'last');
lastPart = source_folder(slashe1+1:slashe2-1);
lastPart=[lastPart,'i'];
%--------------

files = dir(strcat(source_folder,'\*.jpg'));  % 读取文件夹中的所有.jpg文件
for i = 1:numel(files)
    if strcmp(files(i).name,"blue.jpg")
        files(i)=[];
    end
end
dir_mask=dir(fullfile("mask",lastPart,"*.jpg"));
dir_mask_sd=dir(fullfile("Shadow\mask",lastPart,"nosd\*.jpg"));
dir_XYZ=dir(strcat("XYZ\i\",lastPart,"\*.mat"));
% dir_XYZ=dir(strcat("XYZ\maxw_i_discarded\",lastPart,"\*.mat"));
if ismember(lastPart,["f04i","f05i","f06i","m04i","m06i"]) 
    if_wei=0;
else
    if_wei=1;
end
% if ismember(lastPart,["m02i","m03i"]) 
%     dir_mask_used=dir_mask_sd;
% else
    dir_mask_used=dir_mask;
% end
wd65=[94.813  100.000  107.262];

save_folder=fullfile('..\analyze\aveSkin_old',lastPart);
% save_folder=fullfile('aveSkinByHand',lastPart);
if ~exist(save_folder,"dir")
    mkdir(save_folder);
end
average_rgb_all=[];average_xyz_all=[];average_lab_all=[];average_lab1_all=[];
de_all=[];de00_all=[];de00c_all=[];
XYZ_all=[];XYZw_all=[];
% for i = 16:16
for i = 1:numel(files) 
    
    img=imread(fullfile(files(i).folder, files(i).name));
    [m, n, p] = size(img);
    flag=0;
    for i_mask=1:length(dir_mask_used)
        if strcmp(files(i).name(1:end-4),dir_mask_used(i_mask).name(1:end-4))
            picname_check{i,1}=files(i).name(1:end-4);
            picname_check{i,2}=dir_mask_used(i_mask).name(1:end-4);
            bull=imread(strcat(dir_mask_used(i_mask).folder,'\',dir_mask_used(i_mask).name));
            flag=1;
            break
        end
    end
    if flag==1

        for i_xyz=1:length(dir_XYZ)
            if strcmp(dir_XYZ(i_xyz).name(1:end-4),files(i).name(1:end-4))
                picname_check{i,3}=dir_XYZ(i_xyz).name(1:end-4);
                XYZdata=load(strcat(dir_XYZ(i_xyz).folder,'\',dir_XYZ(i_xyz).name));
                % XYZdata=load("D:\work\VIVOskinExpe\camera model-20240924\check.mat");
                XYZ=XYZdata.XYZ_cropped;
                XYZw=XYZdata.XYZw;
                % XYZw_max=XYZdata.XYZw_max;

                XYZw_all(i,:)=XYZw;
                % XYZw_max_all(i,:)=XYZw_max;

                % maxY=XYZdata.maxY;
                % XYZw=wd65./100.*maxY;
                break
            end
        end
        % bull=double(bull);
        bull_reshaped=reshape(bull, [m * n, size(bull,3)])./255;
        % bull_reshaped = double(bull_reshaped);
        bull_weight=mean(bull_reshaped,2);
        disp(min(bull_weight))
        logicalIndex = all(bull_reshaped == 0, 2);

        xyz = reshape(XYZ, [m * n, p]);         

        datai_file = 'calibResults\datai_ipv18_3.mat';
        LUT=load(datai_file);
        XYZw_LUT=LUT.XYZw;
        wd65_scaled=wd65./100.*XYZw_LUT(2);
        out=reshape(xyz2srgb(xyz./XYZw_LUT(2).*100), [m * n, p]);
        
        [lab] = xyz2lab(xyz,'user',wd65_scaled);
        %test
        [lab_rela_w] = xyz2lab(xyz,'user',XYZw);
        [labw(i,:)] = xyz2lab(XYZw,'user',wd65_scaled);

        average_lab=get_average(lab,bull,if_wei);
        average_lab_rela_w(i,:)=get_average(lab_rela_w,bull,if_wei);
        % average_lab=sum(lab.*bull_weight)./sum(bull_weight);
        % average_lab_rela_w(i,:)=mean(lab_rela_w(~logicalIndex, :));

%-----画mask区域肤色预览图-----------
        out=out.*repmat(bull_weight,1,size(out,2));
        figure(1);
        imshow(reshape(out,[m,n,p]));
        output_folder=fullfile(save_folder,"cropped_area_skin");
        if ~exist(output_folder,"dir")
            mkdir(output_folder);
        end
        imwrite(reshape(out,[m,n,p]),fullfile(output_folder,strcat(files(i).name(1:end-4),".jpg")));

        [average_xyz] = lab2xyz2(average_lab,'user',wd65_scaled);
        xyz_mean=mean(xyz(~logicalIndex, :));
        [lab_mean] = xyz2lab(xyz_mean,'user',wd65_scaled);

    else

        average_xyz=[0 0 0];
        average_lab=[0 0 0];
    end

    average_xyz_all=[average_xyz_all;average_xyz];
    average_lab_all=[average_lab_all;average_lab];
    % XYZw_all=[XYZw_all;[{files(i).name(1:end-4)},XYZw]];
    XYZ_all=[XYZ_all;[{files(i).name(1:end-4)},XYZ]];
    XYZw_all(i,:)=XYZw;
end


save(fullfile(save_folder,'autoNhand_scaleoverLUT.mat'), ...
'average_lab_all','average_xyz_all','XYZw_all','-v7.3');
disp("done");

