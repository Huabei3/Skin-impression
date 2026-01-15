clear;

%729pre96
%RGB->XYZ

load("RGB.mat");
RGB=RGB*255;
% dir_model=dir("D:\work\VIVOskinExpe\renderCode\calibResults\model3d_file_350_1deg_realP3\datai_ipv40_*.mat");
dir_model=dir("D:\work\VIVOskinExpe\renderCode\calibResults\" + ...
    "model_interp\datai_ipv35_*.mat");
n_phones=length(dir_model);
for i=1:n_phones
%     datai_file=(strcat("Z:\homes\Peggy\VIVOskinExpe\calibResults\model3d_file\datai_ipv40_",num2str(i),".mat"));
    % datai_file=(strcat("Z:\homes\Peggy\VIVOskinExpe\calibResults\model3d_file_p3\datai_ipv40_",num2str(i),".mat"));
    datai_file=fullfile(dir_model(i).folder,dir_model(i).name);
    load(datai_file);
    
    XYZ_pre{i} = lut3d_rgb2xyz1(RGB,datai_file);
end

%from csv
% XYZ_table=readtable("Z:\homes\Peggy\oppoSkinExperi\LUT3d\results\" + ...
%     "test-color-patch-1-96.csv");
% XYZ_spd=table2array(XYZ_table(:,1:end));
% SPDname = 380:1:780;
% SPDname = SPDname';
% XYZ_mea1 = spd2xyz([SPDname XYZ_spd'],10);

dir_96data=dir("D:\work\VIVOskinExpe\renderCode\calibResults\96\*.mat");
% dir_96data=dir("D:\work\VIVOskinExpe\renderCode\calibResults\96_350_1deg_realP3\*.mat");

%from mat
for i=1:n_phones
    SPDname = 380:1:780;SPDname = SPDname';
    load(fullfile(dir_96data(i).folder,dir_96data(i).name));
    salshes=find(dir_96data(i).name=='_');
    serial_num(i,1)=str2double(dir_96data(i).name(salshes(4)+1:salshes(5)-1));
%     load(strcat("Z:\homes\Peggy\VIVOskinExpe\calibResults\96\" + ...
%         "VIVO_CS2000_96_",num2str(i),".mat"));
    DATAs(1,:) = [];
    SPD = reshape(cell2mat(DATAs(:,4)),401,96);
    XYZ10 = spd2xyz([SPDname SPD],10);
    XYZ_mea{i}=XYZ10;
end

for i=1:n_phones
    [lab_pre{i}] = xyz2lab(XYZ_pre{i},'user',XYZw);
    [lab_mea{i}] = xyz2lab(XYZ_mea{i},'user',XYZw);
end

[serial_sorted,index] = sortrows(serial_num,1,'ascend');
for i=1:length(index)
    lab_mea_sorted{i}=lab_mea{index(i)};
    lab_pre_sorted{i}=lab_pre{index(i)};
    % check_serial_num{i,1}=
end


% 计算两两之间的平均色差值
for i = 1:n_phones
    for j=1:n_phones

        % 计算 i 组和 j 组之间的色差
        % [de,~,~,~] = cielabde(XYZ_mea{j},lab_pre{i});
        [de00,de00c] = deltaE2000(lab_mea_sorted{j},lab_pre_sorted{i});
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

        % 使用sort函数进行降序排列，第二个输出参数是排序后的索引
        [sorted_values, sorted_indices] = sort(de00, 'descend');
        
        % 创建一个96x2的数组，第一列放索引，第二列放对应的值
        cell_sorted{i,j} = [sorted_indices', sorted_values'];
    end        
end


disp("done");




