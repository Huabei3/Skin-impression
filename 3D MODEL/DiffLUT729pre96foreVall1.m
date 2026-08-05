clear;

%729pre96
%RGB->XYZ

load("RGB.mat");
RGB=RGB*255;
% dir_model=dir("D:\work\VIVOskinExpe\renderCode\calibResults\model3d_file_350_1deg_realP3\datai_ipv40_*.mat");
dir_96data=dir("D:\work\VIVOskinExpe\renderCode\calibResults\96\*.mat");
n_phones=18;
% n_phones=length(dir_model);
for i=1:n_phones
    %datai_file=(strcat("Z:\homes\Peggy\VIVOskinExpe\calibResults\model3d_file\datai_ipv40_",num2str(i),".mat"));
    % datai_file=(strcat("Z:\homes\Peggy\VIVOskinExpe\calibResults\model3d_file_p3\datai_ipv40_",num2str(i),".mat"));
    
    dir_model=dir(fullfile("D:\work\VIVOskinExpe\renderCode\calibResults\" + ...
    "model_interp",strcat("datai_ipv30_",num2str(i),".mat")));
    
    datai_file=fullfile(dir_model(1).folder,dir_model(1).name);
    load(datai_file);
    
    XYZ_pre{i} = lut3d_rgb2xyz1(RGB,datai_file);
    XYZ_pre_file{i} = dir_model(1).name;
    
% end

%from csv
% XYZ_table=readtable("Z:\homes\Peggy\oppoSkinExperi\LUT3d\results\" + ...
%     "test-color-patch-1-96.csv");
% XYZ_spd=table2array(XYZ_table(:,1:end));
% SPDname = 380:1:780;
% SPDname = SPDname';
% XYZ_mea1 = spd2xyz([SPDname XYZ_spd'],10);


% dir_96data=dir("D:\work\VIVOskinExpe\renderCode\calibResults\96_350_1deg_realP3\*.mat");

%from mat
% for i=1:n_phones
    SPDname = 380:1:780;SPDname = SPDname';

    % dir_96data1=dir(fullfile(dir_96data(i).folder, ...
    %     strcat("VIVO_CS2000_96_p3_",num2str(i),"*.mat")));
    if i<=13
        dir_96data1=dir(fullfile("D:\work\VIVOskinExpe\renderCode\calibResults\96", ...
            strcat("VIVO_CS2000_96_p3_",num2str(i),"*.mat")));
    else
        dir_96data1=dir(fullfile("D:\work\VIVOskinExpe\renderCode\calibResults\x200", ...
        strcat("VIVO_CS2000_96_x200_",num2str(i-13),"_1deg_P3","*.mat")));
    end

    dir_96_file=fullfile(dir_96data1(1).folder,dir_96data1(1).name);
    load(dir_96_file);
    % load(fullfile(dir_96data(i).folder,dir_96data(i).name));
    % salshes=find(dir_96data1(i).name=='_');
    % serial_num(i,1)=str2double(dir_96data(i).name(salshes(4)+1:salshes(5)-1));
%     load(strcat("Z:\homes\Peggy\VIVOskinExpe\calibResults\96\" + ...
%         "VIVO_CS2000_96_",num2str(i),".mat"));
    DATAs(1,:) = [];
    SPD = reshape(cell2mat(DATAs(:,4)),401,96);
    XYZ10 = spd2xyz([SPDname SPD],10);
    XYZ_mea{i}=XYZ10;
    XYZ_mea_file{i}=dir_96data1(1).name;
    % ② 最后24个色块的RGB + XYZ预测值 + XYZ测量值 (24x9矩阵)
    cell_last24{i} = [RGB(73:end,:), XYZ_pre{i}(73:end,:), XYZ_mea{i}(73:end,:)];
    white_96(i,:)=XYZ10(72,:);
    white_xyY_96(i,1:3)=xyz2xyY(XYZ10(72,:));
    white_xyY_96(i,4:6)=xyz2xyY(XYZ10(18,:));
    white_xyY_96(i,7:9)=xyz2xyY(XYZ10(36,:));
    white_xyY_96(i,10:12)=xyz2xyY(XYZ10(54,:));


    SPDname = 380:1:780;SPDname = SPDname';

    if i<=13
    dir_729data=dir(fullfile("D:\work\VIVOskinExpe\renderCode\" + ...
        "calibResults\729",strcat("VIVO_CS2000_729_p3_", ...
        num2str(i),"*.mat")));
    else
    dir_729data=dir(fullfile("D:\work\VIVOskinExpe\renderCode\" + ...
        "calibResults\x200",strcat("VIVO_CS2000_729_x200_", ...
        num2str(i-13),"_1deg_P3*.mat")));
    end
    load(fullfile(dir_729data(1).folder,dir_729data(1).name));
    
    DATAs(1,:) = [];
    SPD = reshape(cell2mat(DATAs(:,4)),401,length(DATAs));
    XYZ10_729 = spd2xyz([SPDname SPD],10);
    XYZ729_mea{i} = XYZ10_729;  % ③ 存储729测量值供de729_matrix使用
    white_729(i,:)=XYZ10_729(729,:);
    white_xyY_729(i,1:3)=xyz2xyY(XYZ10_729(729,:));
    white_xyY_729(i,4:6)=xyz2xyY(XYZ10_729(649,:));
    white_xyY_729(i,7:9)=xyz2xyY(XYZ10_729(73,:));
    white_xyY_729(i,10:12)=xyz2xyY(XYZ10_729(9,:));
    % save("XYZ10_729_data.mat","XYZ10_729")
end
[val, ind]=max(XYZ_mea{1});
XYZw=XYZ_mea{1}(ind(2),:);
for i=1:n_phones
    [lab_pre{i}] = xyz2lab(XYZ_pre{i},'user',XYZw);
    [lab_mea{i}] = xyz2lab(XYZ_mea{i},'user',XYZw);
end

% [serial_sorted,index] = sortrows(serial_num,1,'ascend');
% for i=1:length(index)
%     lab_mea_sorted{i}=lab_mea{index(i)};
%     lab_pre_sorted{i}=lab_pre{index(i)};
%     % check_serial_num{i,1}=
% end


% 计算两两之间的平均色差值
for i = 1:n_phones
    for j=1:n_phones

        % 计算 i 组和 j 组之间的色差
        % [de,~,~,~] = cielabde(lab_mea{j},lab_pre{i});
        [de00,de00c] = deltaE2000(lab_mea{j},lab_pre{i});
        % [de00,de00c] = deltaE2000(lab_mea_sorted{j},lab_pre_sorted{i});
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

% ③ 计算729色测量值两两之间的deltaE2000矩阵
[val729, ind729] = max(XYZ729_mea{1});
XYZw_729 = XYZ729_mea{1}(ind729(2),:);
for i = 1:n_phones
    [lab_729_mea{i}] = xyz2lab(XYZ729_mea{i}, 'user', XYZw_729);
end
de729_matrix = zeros(n_phones, n_phones);
for i = 1:n_phones
    for j = 1:n_phones
        [de00_729, ~] = deltaE2000(lab_729_mea{i}, lab_729_mea{j});
        de729_matrix(i,j) = mean(de00_729);
    end
end

disp("done");




