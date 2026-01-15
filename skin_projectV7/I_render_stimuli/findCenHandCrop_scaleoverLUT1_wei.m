close all; % 关闭所有图窗
clc;       % 清空命令窗口
clear;     % 清除工作区所有变量
%%
%-----------rs----------
lastParts = {'f04r', 'f05r', 'f06r', 'm04r', 'm05r', 'm06r',...
'f01r', 'f02r', 'f03r', 'm01r', 'm02r', 'm03r',...
'f07r', 'f08r','m07r', 'm08r',...
'f09r', 'f10r','m09r', 'm10r'};nation="all";
for i_lastPart = 13:13
% for i_lastPart = 14:length(lastParts)
    lastPart = lastParts{i_lastPart};
    model=lastPart(1:end-1);
    iOr=lastPart(end);
    source_folder=fullfile('dsp',model,iOr,'jpg\noCard');
    % slashes = strfind(source_folder, '\');
    % model = source_folder(slashes(end-3)+1:slashes(end-2)-1);
    
    % lastPart=strcat(model,iOr);
    
    files = dir(strcat(source_folder,'\*.jpg'));  % 读取文件夹中的所有.jpg文件
    
    dir_mask=dir(strcat("mask\",lastPart,"\*.jpg"));
    % dir_XYZ=dir(strcat("XYZ\D651227_r\",lastPart,"\*.mat"));
    dir_XYZ=dir(strcat("XYZ\rs\",lastPart,"\*.mat"));
    if ismember(lastPart,["f04i","f05i","f06i","m04i","m06i"]) 
        if_wei=0;
    else
        if_wei=1;
    end
    wd65=[94.813  100.000  107.262];
    save_folder=fullfile('aveSkinByHand2',lastPart);
    if ~exist(save_folder,"dir")
        mkdir(save_folder);
    end
    average_rgb_all=[];average_xyz_all=[];average_lab_all=[];average_lab1_all=[];
    de_all=[];de00_all=[];de00c_all=[];
    XYZ_all=[];XYZw_all=[];
    for i = 1:numel(files) 
        
        img=imread(fullfile(files(i).folder, files(i).name));
    
        [m, n, p] = size(img);
        flag=0;
        for i_mask=1:length(dir_mask)
            if contains(files(i).name(1:end-4),dir_mask(i_mask).name(1:end-4))
                disp([files(i).name(1:end-4),dir_mask(i_mask).name(1:end-4)]);
                bull=imread(strcat(dir_mask(i_mask).folder,'\',dir_mask(i_mask).name));
                flag=1;
                break
            end
        end
        if flag==1
    
            for i_xyz=1:length(dir_XYZ)
                if contains(dir_XYZ(i_xyz).name(1:end-4),files(i).name(1:end-4))
                    disp([dir_XYZ(i_xyz).name(1:end-4),files(i).name(1:end-4)]);
                    XYZdata=load(strcat(dir_XYZ(i_xyz).folder,'\',dir_XYZ(i_xyz).name));
                    % XYZdata=load("D:\work\VIVOskinExpe\camera model-20240924\check.mat");
                    XYZ=XYZdata.XYZ_cropped;
                    XYZw=XYZdata.XYZw;
                    XYZw_max=XYZdata.XYZw_max;
    
                    XYZw_all(i,:)=XYZw;
                    XYZw_max_all(i,:)=XYZw_max;
    
                    % maxY=XYZdata.maxY;
                    % XYZw=wd65./100.*maxY;
                    break
                end
            end
    
            [logicalIndex,bull_weight]=read_bull(bull,if_wei);
            xyz = reshape(XYZ, [m * n, p]); 
    
            out=reshape(img, [m * n, p]);
    
            datai_file = 'calibResults\datai_ipv35_3.mat';
            LUT=load(datai_file);
            XYZw_LUT=LUT.XYZw;
            wd65_scaled=wd65./100.*XYZw_LUT(2);
            
            [lab] = xyz2lab(xyz,'user',wd65_scaled);
            % lab_wei=lab.*bull_weight;
            %test
            [lab_rela_w] = xyz2lab(xyz,'user',XYZw);
            [lab_rela_wmax] = xyz2lab(xyz,'user',XYZw_max);
            [labw(i,:)] = xyz2lab(XYZw,'user',wd65_scaled);
            [labwmax(i,:)] = xyz2lab(XYZw_max,'user',wd65_scaled);
            average_lab=get_average(lab,bull,if_wei);
            average_lab_rela_w(i,:)=get_average(lab_rela_w,bull,if_wei);
            % average_lab=sum(lab_wei(~logicalIndex, :))./sum(bull_weight);
            % average_lab_rela_w(i,:)=mean(lab_rela_w(~logicalIndex, :));
            % average_lab_rela_wmax(i,:)=mean(lab_rela_wmax(~logicalIndex, :));
    
    %-----画mask区域肤色预览图-----------
            out=uint8(double(out).*bull_weight);
    
            imshow(reshape(out,[m,n,p]));
            output_folder=fullfile(save_folder,"cropped_area_skin");
            if ~exist(output_folder,"dir")
                mkdir(output_folder);
            end
    
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
    end
    
    save(fullfile(save_folder,'autoNhand_scaleoverLUT.mat'), ...
    'average_lab_all','XYZw_all','-v7.3');
    % save(fullfile(save_folder,'XYZdata_all.mat'), ...
    % 'XYZ_all',"XYZw_all",'-v7.3');
    % 
    % save(fullfile(save_folder,'XYZw_all.mat'), ...
    % "XYZw_all",'-v7.3');
    disp("done");
end

