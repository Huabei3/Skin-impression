clear;

%729pre96
%RGB->XYZ

load("RGB.mat");

%from csv
% XYZ_table=readtable("Z:\homes\Peggy\oppoSkinExperi\LUT3d\results\" + ...
%     "test-color-patch-1-96.csv");
% XYZ_spd=table2array(XYZ_table(:,1:end));
% SPDname = 380:1:780;
% SPDname = SPDname';
% XYZ_mea1 = spd2xyz([SPDname XYZ_spd'],10);
folder_std_data="D:\work\VIVOskinExpe\renderCode\calibResults\std";
if ~exist(folder_std_data,"dir")
    mkdir(folder_std_data);
end
dir_std_data=dir(fullfile(folder_std_data,"*.mat"));

% dir_std_data=dir("D:\work\VIVOskinExpe\renderCode\calibResults\96_350_1deg_realP3\*.mat");
n_phones=5;
%from mat
for i=1:n_phones
    SPDname = 380:1:780;SPDname = SPDname';

    dir_std_data1=dir(fullfile(dir_std_data(i).folder, ...
        strcat("VIVO_CS2000_4_p3_x200_",num2str(i),"_1deg_realP3","*.mat")));
    dir_std_file=fullfile(dir_std_data1(1).folder,dir_std_data1(1).name);
    load(dir_std_file);
    % load(fullfile(dir_std_data(i).folder,dir_std_data(i).name));
    salshes=find(dir_std_data(i).name=='_');
    serial_num(i,1)=str2double(dir_std_data(i).name(salshes(4)+1:salshes(5)-1));
%     load(strcat("Z:\homes\Peggy\VIVOskinExpe\calibResults\96\" + ...
%         "VIVO_CS2000_96_",num2str(i),".mat"));
    DATAs(1,:) = [];
    SPD = reshape(cell2mat(DATAs(:,4)),401,length(DATAs));
    XYZ10 = spd2xyz([SPDname SPD],10);
    XYZ_mea{i}=XYZ10;
    white_xyY_std(i,1:3)=xyz2xyY(XYZ10(4,:));
    white_xyY_std(i,4:6)=xyz2xyY(XYZ10(3,:));
    white_xyY_std(i,7:9)=xyz2xyY(XYZ10(2,:));
    white_xyY_std(i,10:12)=xyz2xyY(XYZ10(1,:));



    SPDname = 380:1:780;SPDname = SPDname';
    folder_pro_data=fullfile("D:\work\VIVOskinExpe\renderCode\" + ...
        "calibResults\pro");
    if ~exist(folder_pro_data,"dir")
    mkdir(folder_pro_data);
    end
    dir_pro_data=dir(fullfile(folder_pro_data,strcat("VIVO_CS2000_4_p3_x200_", ...
        num2str(i),"_1deg_realP3_","*.mat")));
    load(fullfile(dir_pro_data(1).folder,dir_pro_data(1).name));
    
    DATAs(1,:) = [];
    SPD = reshape(cell2mat(DATAs(:,4)),401,length(DATAs));
    XYZ10_pro = spd2xyz([SPDname SPD],10);

    white_xyY_pro(i,1:3)=xyz2xyY(XYZ10_pro(4,:));
    white_xyY_pro(i,4:6)=xyz2xyY(XYZ10_pro(3,:));
    white_xyY_pro(i,7:9)=xyz2xyY(XYZ10_pro(2,:));
    white_xyY_pro(i,10:12)=xyz2xyY(XYZ10_pro(1,:));

    % save("XYZ10_pro_data.mat","XYZ10_pro")
end

