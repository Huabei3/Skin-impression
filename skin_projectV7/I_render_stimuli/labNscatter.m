clear;clc;close all;
%%
average_file=['D:\work\VIVOskinExpe\Hassel_downsampled\male59\cropped\' ...
    'CardMasked\aveSkinByHand\autoNhandVtest.mat'];
average=load(average_file);
average=average.average_lab_all(:,1:3);

dir_picname=dir("D:\work\VIVOskinExpe\Hassel_downsampled\male59\cropped\CardMasked\*.jpg");

delta_points = readtable("Z:\homes\Peggy\VIVOskinExpe\points25_delta.xlsx");
delta_points=table2array(delta_points);

save_folder="D:\work\VIVOskinExpe\Hassel_downsampled\male59\cropped\CardMasked";
output_folder=fullfile(save_folder,"lab_group");
if ~exist(output_folder,"dir")
    mkdir(output_folder);
end

picnameNlab=[];
for i_ave=1:length(average)

    lab_group=repmat(average(i_ave,:),1,length(delta_points))+delta_points;
    picnameNlab=[picnameNlab;[{dir_picname(i_ave).name(1:end-4)},lab_group]];
    save(fullfile(output_folder,strcat(dir_picname(i_ave).name(1:end-4),".mat")), ...
        "lab_group");
end

outputFolder=fullfile(output_folder,"average");
if ~exist(outputFolder,"dir")
    mkdir(outputFolder);
end
save(fullfile(output_folder,"averageLab.mat"), ...
    "picnameNlab");