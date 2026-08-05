clear;
%%
n_phones=18;
% n_phones=13;
for i=1:n_phones
    SPDname = 380:1:780;SPDname = SPDname';
    if i<=13
        dir_96data=dir(fullfile("D:\work\VIVOskinExpe\renderCode\calibResults\96", ...
            strcat("VIVO_CS2000_96_p3_",num2str(i),"*.mat")));
    else
        dir_96data=dir(fullfile("D:\work\VIVOskinExpe\renderCode\calibResults\x200", ...
        strcat("VIVO_CS2000_96_x200_",num2str(i-13),"_1deg_P3","*.mat")));
    end
    file_96data=fullfile(dir_96data(1).folder,dir_96data(1).name);
    if ~exist(file_96data,"file")
        continue
    end
    load(file_96data);

    DATAs(1,:) = [];
    SPD = reshape(cell2mat(DATAs(:,4)),401,96);
    XYZ10 = spd2xyz([SPDname SPD],10);
    XYZ_mea{i}=XYZ10;
end

[val, ind]=max(XYZ_mea{1});
XYZw=XYZ_mea{1}(ind(2),:);


load("RGB.mat");
RGB=RGB*255;
for i=1:n_phones
    dir_LUTback_file=dir(fullfile("D:\work\VIVOskinExpe\renderCode\calibResults\" + ...
    "model_interp",strcat("data_ipv30_",num2str(i),"*.mat")));
    LUTback_file=fullfile(dir_LUTback_file(1).folder,dir_LUTback_file(1).name);

    dir_LUTfore_file=dir(fullfile("D:\work\VIVOskinExpe\renderCode\calibResults\" + ...
    "model_interp",strcat("datai_ipv30_",num2str(i),"*.mat")));
    LUTfore_file=fullfile(dir_LUTfore_file(1).folder,dir_LUTfore_file(1).name);
 


    if ~exist(LUTback_file,"file")||~exist(LUTfore_file,"file")
        continue
    end
    
    RGB_r{i}= lut3d_xyz2rgbNoParitp(XYZ_mea{i},LUTback_file); 
    XYZ_r{i}=lut3d_rgb2xyz1(RGB_r{i},LUTfore_file);
    XYZ_pre{i} = lut3d_rgb2xyz1(RGB,LUTfore_file);

    [val, ind]=max(XYZ_pre{i});
    XYZw_pre=XYZ_pre{i}(ind(2),:);

    [lab_pre{i}] = xyz2lab(XYZ_pre{i},'user',XYZw_pre);

    [lab_r{i}] = xyz2lab(XYZ_r{i},'user',XYZw);
    [lab_mea{i}] = xyz2lab(XYZ_mea{i},'user',XYZw);

    de_fore(i,:)=mean(deltaE2000(XYZ_pre{i},XYZ_r{i}));
    de_fore_cell{i}=deltaE2000(XYZ_pre{i},XYZ_r{i});
end



% 计算两两之间的平均色差值
for i = 1:n_phones
    for j=1:n_phones
        % 计算 i 组和 j 组之间的色差
        % [de,~,~,~] = cielabde(XYZ_mea{j},lab_pre{i});
        if isempty(lab_mea{j})||isempty(lab_r{i})
            continue
        end
        [de00,de00c] = deltaE2000(lab_mea{j},lab_r{i});
        % 计算平均色差
        de0024=de00(73:end);
        average_deltaE = mean(de00);
        average_deltaE24 = mean(de0024);
        % 存储在结果矩阵中
        result_matrix(i,j) = average_deltaE;
        result_matrix24(i,j) = average_deltaE24;
    
        % 存储在元胞矩阵中
        cell_matrix{i,j} = de00;
        cell_matrix24{i,j} = de0024;
    end        
end

disp("done");
result_matrix24(:,j+2)=mean(result_matrix24(:,1:j),2);

result_10phones=result_matrix24(3,1:10);
[mean(result_10phones),max(result_10phones),min(result_10phones)]




