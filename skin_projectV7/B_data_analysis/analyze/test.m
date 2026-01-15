clc;clear;close all;
addpath("utils\")
%%
attributes = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];

attribute_names_new = ["Preference", "Attractiveness", "Feminine", "Cooperative", ...
    "Youth", "Healthy", "Fidelity", "Harmony", "Fair", "Ruddy"];
% nations = ["AS", "CA", "DA", "all"];
nations = ["AS", "CA", "SA", "AF"];
obs_type = "non_model";iOr='r';
Dtype="efit_p";
scale_type="scaled";
scale_type_origin="unscaled";
res_matrix=[];
curr=1;
for attribute = [1]
% for attribute = 1:length(attributes)
    attribute_serial = strcat(sprintf("%02d", attribute), ...
    attribute_names_new(attribute));
    for i_nation = 1:length(nations)
        % 获取当前人种的所有索引
        nation = nations(i_nation);
        nation_serial=strcat(num2str(i_nation),nation);

        fitRes_folder=fullfile("AnalyseResults_p",Dtype,"50", ...
        scale_type_origin,"nation1", scale_type,...
        obs_type,iOr,attribute_serial,nation_serial);
        dir_file=dir(fullfile(fitRes_folder,"*.mat"));
        for i_indices = 1:length(dir_file)


            data=load(fullfile(fitRes_folder,strcat(num2str(i_indices),".mat")), ...
            "par","r","y","average_indices_curr");
            res_matrix=[res_matrix;[data.par,data.r]];
            res_cell{curr,1}=[data.par,data.r];
            res_cell{curr,2}=strcat(iOr,nation_serial,num2str(i_indices));
            curr=curr+1;
        end
    end
end
output_folder=fullfile("AnalyseResults_p",Dtype,"50", ...
        scale_type_origin,"nation1", scale_type,...
        obs_type,iOr);
save(fullfile(output_folder,"fit_para_XLSX.mat"),"res_cell","res_matrix");
disp("d")