clear;
%%
%729pre96 back-KD phase2
%仅13~18台（phase2 1~5）之间的色差

n_phones=5;  % phase2: 1~5

for i_device=1:n_phones
    SPDname = 380:1:780;SPDname = SPDname';
    
    % 96色数据 —— 仅 x200 路径
    dir_96data=dir(fullfile("D:\work\VIVOskinExpe\renderCode\calibResults\x200", ...
        strcat("VIVO_CS2000_96_x200_",num2str(i_device),"_","*.mat")));
    file_96data=fullfile(dir_96data(1).folder,dir_96data(1).name);
    if ~exist(file_96data,"file")
        continue
    end
    load(file_96data);

    DATAs(1,:) = [];
    SPD = reshape(cell2mat(DATAs(:,4)),401,96);
    XYZ10 = spd2xyz([SPDname SPD],10);
    XYZ_mea{i_device}=XYZ10;
end

[val, ind]=max(XYZ_mea{1});
XYZw=XYZ_mea{1}(ind(2),:);

load("RGB.mat");
RGB=RGB*255;

% Load RGB_729 (729x3) from csv, same as in model_lut3dVIVO2.m
RGB_729 = readtable("D:\work\VIVOskinExpe\3D MODEL\rgb_values1.csv");
RGB_729 = table2array(RGB_729(:,2:4));

for i_device=1:n_phones
    % 加载 phase2 逆向模型: data_ipv30_phase2_{}.mat
    dir_LUTback_file=dir(fullfile("D:\work\VIVOskinExpe\renderCode\calibResults\" + ...
    "model_interp",strcat("data_ipv30_phase2_",num2str(i_device),"*.mat")));
    LUTback_file=fullfile(dir_LUTback_file(1).folder,dir_LUTback_file(1).name);

    % 加载 phase2 正向模型: datai_ipv30_phase2_{}.mat
    dir_LUTfore_file=dir(fullfile("D:\work\VIVOskinExpe\renderCode\calibResults\" + ...
    "model_interp",strcat("datai_ipv30_phase2_",num2str(i_device),"*.mat")));
    LUTfore_file=fullfile(dir_LUTfore_file(1).folder,dir_LUTfore_file(1).name);

    if ~exist(LUTback_file,"file")||~exist(LUTfore_file,"file")
        continue
    end
    
    RGB_r{i_device}= lut3d_xyz2rgbNoParitp(XYZ_mea{i_device},LUTback_file); 
    
    % Store horizontal concat: RGB_729 (729x3) + RGB_r{i_device} (96x3)
    cat_cell{i_device,1} = [RGB_729, RGB_r{i_device}];
    
    XYZ_r{i_device}=lut3d_rgb2xyz1(RGB_r{i_device},LUTfore_file);
    XYZ_pre{i_device} = lut3d_rgb2xyz1(RGB,LUTfore_file);

    % [val, ind]=max(XYZ_pre{i_device});
    % XYZw_pre=XYZ_pre{i_device}(ind(2),:);
    [val, ind]=max(XYZ_pre{1});
    XYZw_pre=XYZ_pre{1}(ind(2),:);

    [lab_pre{i_device}] = xyz2lab(XYZ_pre{i_device},'user',XYZw_pre);

    [lab_r{i_device}] = xyz2lab(XYZ_r{i_device},'user',XYZw);
    [lab_mea{i_device}] = xyz2lab(XYZ_mea{i_device},'user',XYZw);

    de_fore(i_device,:)=mean(deltaE2000(lab_pre{i_device}(73:end,:), ...
        lab_r{i_device}(73:end,:)));
    de_fore1(i_device,:)=mean(deltaE2000(lab_pre{i_device}(73:end,:), ...
        lab_mea{i_device}(73:end,:)));
    de_fore_cell{i_device}=deltaE2000(lab_pre{i_device}(73:end,:), ...
        lab_r{i_device}(73:end,:));

end

% 计算两两之间的平均色差值
for i = 1:n_phones
    for j=1:n_phones
        if isempty(lab_mea{j})||isempty(lab_r{i})
            continue
        end
        [de00,de00c] = deltaE2000(lab_mea{j},lab_r{i});
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
if exist('j','var')
    result_matrix24(:,j+2)=mean(result_matrix24(:,1:j),2);
end

result_5phones=result_matrix24(1,1:5);
[mean(result_5phones),max(result_5phones),min(result_5phones)]
