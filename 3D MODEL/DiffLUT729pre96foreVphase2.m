clear;

%729pre96 phase2
%RGB->XYZ 仅13~18台（phase2 1~5）

load("RGB.mat");
RGB=RGB*255;

n_phones=5;  % phase2: 1~5

for i_device=1:n_phones
    
    % 加载 model_interp 中的 datai_ipv30_phase2_{}.mat
    dir_model=dir(fullfile("D:\work\VIVOskinExpe\renderCode\calibResults\" + ...
    "model_interp",strcat("datai_ipv30_phase2_",num2str(i_device),".mat")));
    
    datai_file=fullfile(dir_model(1).folder,dir_model(1).name);
    load(datai_file);
    
    XYZ_pre{i_device} = lut3d_rgb2xyz1(RGB,datai_file);
    XYZ_pre_file{i_device} = dir_model(1).name;
    
    SPDname = 380:1:780;SPDname = SPDname';
    
    % 96色数据 —— 仅 x200 路径
    dir_96data1=dir(fullfile("D:\work\VIVOskinExpe\renderCode\calibResults\x200", ...
        strcat("VIVO_CS2000_96_x200_",num2str(i_device),"_1deg_P3","*.mat")));

    dir_96_file=fullfile(dir_96data1(1).folder,dir_96data1(1).name);
    load(dir_96_file);
    
    DATAs(1,:) = [];
    SPD = reshape(cell2mat(DATAs(:,4)),401,96);
    XYZ10 = spd2xyz([SPDname SPD],10);
    XYZ_mea{i_device}=XYZ10;
    XYZ_mea_file{i_device}=dir_96data1(1).name;
    white_96(i_device,:)=XYZ10(72,:);
    white_xyY_96(i_device,1:3)=xyz2xyY(XYZ10(72,:));
    white_xyY_96(i_device,4:6)=xyz2xyY(XYZ10(18,:));
    white_xyY_96(i_device,7:9)=xyz2xyY(XYZ10(36,:));
    white_xyY_96(i_device,10:12)=xyz2xyY(XYZ10(54,:));

    % 729色数据 —— 仅 x200 路径
    SPDname = 380:1:780;SPDname = SPDname';

    dir_729data=dir(fullfile("D:\work\VIVOskinExpe\renderCode\" + ...
        "calibResults\x200",strcat("VIVO_CS2000_729_x200_", ...
        num2str(i_device),"_1deg_P3*.mat")));
    load(fullfile(dir_729data(1).folder,dir_729data(1).name));
    
    DATAs(1,:) = [];
    SPD = reshape(cell2mat(DATAs(:,4)),401,length(DATAs));
    XYZ10_729 = spd2xyz([SPDname SPD],10);
    white_729(i_device,:)=XYZ10_729(729,:);
    white_xyY_729(i_device,1:3)=xyz2xyY(XYZ10_729(729,:));
    white_xyY_729(i_device,4:6)=xyz2xyY(XYZ10_729(649,:));
    white_xyY_729(i_device,7:9)=xyz2xyY(XYZ10_729(73,:));
    white_xyY_729(i_device,10:12)=xyz2xyY(XYZ10_729(9,:));
end

[val, ind]=max(XYZ_mea{1});
XYZw=XYZ_mea{1}(ind(2),:);
for i=1:n_phones
    [lab_pre{i}] = xyz2lab(XYZ_pre{i},'user',XYZw);
    [lab_mea{i}] = xyz2lab(XYZ_mea{i},'user',XYZw);
end

% 计算两两之间的平均色差值
for i = 1:n_phones
    for j=1:n_phones
        [de00,de00c] = deltaE2000(lab_mea{j},lab_pre{i});
        de0024=de00(73:end);
        average_deltaE = mean(de00);
        average_deltaE24 = mean(de0024);
        % 存储在结果矩阵中
        result_matrix(i,j) = average_deltaE;
        result_matrix24(i,j) = average_deltaE24;
    
        % 存储在元胞矩阵中
        cell_matrix{i,j} = de00;
        cell_matrix24{i,j} = de0024;

        % 降序排列
        [sorted_values, sorted_indices] = sort(de00, 'descend');
        cell_sorted{i,j} = [sorted_indices', sorted_values'];
    end        
end

disp("done");
