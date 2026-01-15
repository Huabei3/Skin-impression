% close all; % 关闭所有图窗
% clc;       % 清空命令窗口
% clear;     % 清除工作区所有变量
addpath("utils\");
%% 对于AS rs
% % % %-----------i----------
% % % 
source_folder='D:\work\VIVOskinExpe\AndroidStudio1\female41r65\app\src\main\res\drawable';

files=dir(fullfile(source_folder,"*.jpg"));

wd65=[94.813  100.000  107.262];

save_folder="D:\work\VIVOskinExpe\analyze\dlabsNpicname";
i_mask=1;
for i = 1:numel(files)
    img=imread(fullfile(files(i).folder, files(i).name));
    slash=find(files(i).name=='_');
    lastPart=files(i).name(1:slash-5);
    lastPart=gen_lastPart_new(lastPart);

    if ismember(lastPart,["m02i","m03i"]) 
        if_2mask=1;
    else
        if_2mask=0;
    end
    dir_mask=dir(fullfile("mask",lastPart,"*.jpg"));
    dir_mask_nosd=dir(fullfile("Shadow\mask",lastPart,"nosd\*.jpg"));


    [m, n, p] = size(img); 
    flag=0;
    if if_2mask
        dir_mask_used=dir_mask_nosd;
    else
        dir_mask_used=dir_mask;
    end

    while ~contains(lower(files(i).name(1:end-4)),lower(dir_mask_used(i_mask).name(1:end-4)))
        i_mask = i_mask + 1;
    end
    flag=0;
    if contains(lower(files(i).name(1:end-4)),lower(dir_mask_used(i_mask).name(1:end-4)))
        disp([files(i).name(1:end-4),dir_mask_used(i_mask).name(1:end-4)]);
        bull=imread(strcat(dir_mask_used(i_mask).folder,'\',dir_mask_used(i_mask).name));
        % bull = imresize(bull, [size(bull,1)./6, size(bull,2)./6]);%先跑小图看问题
        flag=1;
    end

    if flag==1
        if ismember(lastPart,["f04i","f05i","f06i","m04i","m06i"]) 
            if_wei=0;
        else
            if_wei=1;
        end
        [logicalIndex,bull_weight]=read_bull(bull,if_wei);
        img=im2double(img);
        out=reshape(img, [m * n, p]);
        out = out * 255;

        datai_file = 'calibResults\datai_ipv18_3.mat';
        xyz = lut3d_rgb2xyz1(out, datai_file);     

        LUT=load(datai_file);
        XYZw_LUT=LUT.XYZw;
        wd65_scaled=wd65./100.*XYZw_LUT(2);

        [lab] = xyz2lab(xyz,'user',wd65_scaled);

        [average_lab]=get_average(lab,bull,if_wei);
        disp(average_lab);
        dlabsNpicname{i,1}=average_lab;
        dlabsNpicname{i,2}=files(i).name(1:end-4);

% -----画mask区域肤色预览图-----------
        if if_wei
            out=out.*bull_weight;
        else
            for i_out=1:length(out)
                if logicalIndex(i_out)==1
                    out(i_out,:)=[0,0,0];
                end
            end        
        end

        imshow(reshape(out,[m,n,p])./255);
        output_folder=fullfile(save_folder,"cropped_area_skin",lastPart);
        if ~exist(output_folder,"dir")
            mkdir(output_folder);
        end
        if mod(i,33)==0
            imwrite(reshape(out,[m,n,p])./255, ...
                fullfile(output_folder,files(i).name));
        end

    else
        average_lab=[0 0 0];
    end

end
save(fullfile(save_folder,strcat(lastPart,".mat")),"dlabsNpicname");