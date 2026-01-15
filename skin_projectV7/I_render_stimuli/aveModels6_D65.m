clear;clc;close all;
%%


% models{1,1}=["male92","male91","male48","female01","female04","female06"];
% models{2,1}=["male59","male39","maleVIVO","female78","female41","femaleVIVO"];
% models{3,1}=["male21","male46","female23","female51"];
% models{4,1}=["male22","male28","female25","female69"];

models{1,1}=["f01","f02","f03","m01","m02","m03"];
models{2,1}=["f04","f05","f06","m04","m05","m06"];
models{3,1}=["f07","f08","m07","m08"];
models{4,1}=["f09","f10","m09","m10"];

types=["Caucasian","Oriental","South Asian","African"];

ct=["H3K","H4K","H5K","H6K","H7K","H8K","HD65",...
"L3K","L4K","L5K","L6K","L7K","L8K","LD65",...
"M3K","M4K","M5K","M6K","M7K","M8K","MD65"];


ave_folder="aveSkinByHand2";
lab_cell_all=[];picname_check_all=[];labC_HD65_all=[];
for i_type=[1,3,4]
% for i_type=1:length(models)
    lab_cell=[];picname_check=[];
    for i_model=1:length(models{i_type,1})    
        file_ave=fullfile(ave_folder,strcat(models{i_type,1}(i_model),'i'),"autoNhand_scaleoverLUT.mat");
        % file_ave=fullfile(ave_folder,strcat(models{i_type,1}(i_model),'i'),"autoNhand_scaleoverLUT_D65.mat");
        picname_check{i_model,1}=models{i_type,1}(i_model);
        ave_data=load(file_ave);
        for i_ct=1:size(ave_data.average_lab_all,1)
            if sum(ave_data.average_lab_all(i_ct,:))~=0
                lab_cell{i_ct,i_model}=ave_data.average_lab_all(i_ct,:);
            end
        end
        lab_data{i_type,i_model}=ave_data.average_lab_all;
    end
    ave_temp=zeros(1,4);
    figure();
    hold on;
    labC_inds=[];
    for i_model=1:length(models{i_type,1}) 
        labC_ind=lab_cell{7,i_model};
        labC_ind(1,4)=sqrt(labC_ind(1,2).^2+labC_ind(1,3).^2);
        ave_temp=ave_temp+labC_ind./length(models{i_type,1});
        
        labC_inds=[labC_inds;labC_ind];
        

        scatter(labC_ind(1,2),labC_ind(1,3),'b');
        text(labC_ind(1,2),labC_ind(1,3), ...
            strcat(models{i_type,1}{1,i_model},' ',num2str(labC_ind(1,4))));
    end
    
    labC_HD65(1,:)=ave_temp;
    scatter(labC_HD65(1,2),labC_HD65(1,3),'r');
    text(labC_HD65(1,2),labC_HD65(1,3), ...
            strcat(num2str(labC_HD65(1,4))));

    lab_cell_all{i_type,1}=lab_cell;
    picname_check_all{1,1}=picname_check;


    labC_HD65_all(i_type,:)=labC_HD65;
    disp("d")
% save(fullfile("aveSkinByHand2","i",strcat("aveLab_D65_",num2str(i_type),".mat")), ...
%     "labC_HD65","lab_cell","picname_check");

end
% save(fullfile("aveSkinByHand2","i","aveLab_4types_D65.mat"), ...
%     "labC_HD65_all","lab_cell_all","picname_check_all","lab_data");


disp("d")