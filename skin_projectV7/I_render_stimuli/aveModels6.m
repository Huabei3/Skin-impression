clear;clc;close all;
%%


% models{1,1}=["male92","male91","male48","female01","female04","female06"];
% models{2,1}=["male59","male39","maleVIVO","female78","female41","femaleVIVO"];
% models{3,1}=["male21","male46","female23","female51"];
% models{4,1}=["male22","male28","female25","female69"];

models{1,1}=["m01","m02","m03","f01","f02","f03"];
models{2,1}=["m04","m05","m06","f04","f05","f06"];
models{3,1}=["m07","m08","f07","f08"];
models{4,1}=["m09","m10","f09","f10"];

types=["Caucasian","Oriental","South Asian","African"];

ct=["H3K","H4K","H5K","H6K","H7K","H8K","HD65",...
"L3K","L4K","L5K","L6K","L7K","L8K","LD65",...
"M3K","M4K","M5K","M6K","M7K","M8K","MD65"];

a_LC=[4.459300459802465,-47.488828958697376];

ave_folder="aveSkinByHand2";
lab_cell_all=[];picname_check_all=[];labC_HD65_all=[];
for i_type=[2]
% for i_type=1:length(models)
    lab_cell=[];picname_check=[];
    for i_model=1:length(models{i_type,1})    
        file_ave=fullfile(ave_folder,strcat(models{i_type,1}(i_model),'i'),"autoNhand_scaleoverLUT.mat");
        picname_check{i_model,1}=models{i_type,1}(i_model);
        ave_data=load(file_ave);
        for i_ct=1:length(ave_data.average_lab_all)
            if sum(ave_data.average_lab_all(i_ct,:))~=0
                lab_cell{i_ct,i_model}=ave_data.average_lab_all(i_ct,:);
            end
        end
        lab_data{i_type,i_model}=ave_data.average_lab_all;
    end
    ave_temp=zeros(1,3);
    figure();
    hold on;
    for i_model=1:length(models{i_type,1}) 
        ave_temp=ave_temp+lab_cell{7,i_model}./length(models{i_type,1});
        scatter(lab_cell{7,i_model}(1,2),lab_cell{7,i_model}(1,3),'b');
        % ave_temp=ave_temp+lab_cell{1,i_model}./length(models{i_type,1});
        % scatter(lab_cell{1,i_model}(1,2),lab_cell{1,i_model}(1,3),'b');
    end
    labC_HD65(1,1:3)=ave_temp;
    scatter(labC_HD65(1,2),labC_HD65(1,3),'r');
    labC_H3k(1,1:3)=ave_temp;
    scatter(labC_H3k(1,2),labC_H3k(1,3),'r');
    lab_cell_all{i_type,1}=lab_cell;
    picname_check_all{1,1}=picname_check;

    labC_HD65(1,4)=sqrt(labC_HD65(1,2).^2+ ...
        labC_HD65(1,3).^2);
    labC_HD65_all(i_type,:)=labC_HD65;
    %     labC_H3k(1,4)=sqrt(labC_H3k(1,2).^2+ ...
    %     labC_H3k(1,3).^2);
    % labC_H3k_all(i_type,:)=labC_H3k;
% save(fullfile("aveSkinByHand2","i",strcat("aveLab_D65_",num2str(i_type),".mat")), ...
%     "labC_HD65","lab_cell","picname_check");

% save(fullfile("aveSkinByHand2","i",strcat("aveLab_H3k_",num2str(i_type),".mat")), ...
%     "labC_H3k","lab_cell","picname_check");
end
% save(fullfile("aveSkinByHand2","i","aveLab_4types_D65.mat"), ...
%     "labC_HD65_all","lab_cell_all","picname_check_all","lab_data");


disp("d")