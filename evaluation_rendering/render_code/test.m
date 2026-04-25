
close all;
clc;
clear;
addpath("..\..\utils\");
%%
% data_A=load("D:\work\VIVOskinExpe\skin_model\evaluation_rendering\render_code\documents\noCAT\discarded\CT_interpolation.mat");
% data_B=load("D:\work\VIVOskinExpe\skin_model\evaluation_rendering\render_code\documents\noCAT\discarded\CT_interpolation2.mat");
%%

% iOr='r';
% % Define the path to your existing .mat file containing render_map
% input_filename_mat = fullfile("documents", iOr, 'render_data.mat'); % Assuming 'r' for this example
% 
% % Load the existing render_map
% if exist(input_filename_mat, 'file')
%     loaded_data = load(input_filename_mat, 'render_map');
%     original_render_map = loaded_data.render_map;
%     disp(['Successfully loaded render_map from: ', input_filename_mat]);
% else
%     error(['Error: The file ', input_filename_mat, ' does not exist. Please ensure the path is correct.']);
% end
% 
% % Initialize a new containers.Map for storing data as structs
% new_render_map = containers.Map;
% 
% % Iterate through the keys of the original map and convert data to struct format
% keys = original_render_map.keys;
% for i = 1:length(keys)
%     current_key = keys{i};
%     current_cell_data = original_render_map(current_key);
%     load(fullfile("documents",strcat("modelSkinColor.mat")),"lab_mea_data","all_lastParts");
%     for i_lastPart=1:length(all_lastParts)
%         curr_lastPart=all_lastParts(i_lastPart);
%         if iOr=='r'
%             curr_lastPart=strrep(curr_lastPart,"i","r");
%         end
% 
%         if contains(current_key,curr_lastPart)
%             curr_skin_mea=lab_mea_data(i_lastPart,:);
%             break
%         end
%     end
%     curr_skin_mea
%     % Ensure the cell array has the expected number of elements before conversion
%     if length(current_cell_data) == 12 % Based on your previous code's 12 elements
%         % Create a struct from the cell array data
%         current_struct_data = struct(...
%             'bull_name', current_cell_data{1}, ...
%             'bull_nosd_name', current_cell_data{2}, ...
%             'XYZ_filename', current_cell_data{3}, ...
%             'XYZw_white_val', current_cell_data{4}, ...
%             'average', current_cell_data{5}, ...
%             'ave_scaled_val', current_cell_data{6}, ...
%             'average_aft_val', current_cell_data{7}, ...
%             'CCT_val', current_cell_data{8}, ...
%             'XYZw_pre_val', current_cell_data{9}, ...
%             'E_val', current_cell_data{10}, ...
%             'ITA_val', current_cell_data{11}, ...
%             'skin_classification_val', current_cell_data{12}, ...
%             "curr_model_skin" ,curr_skin_mea...
%         );
% 
%         % Store the struct in the new map
%         new_render_map(current_key) = current_struct_data;
%     else
%         warning(['Skipping key ''', current_key, ''' due to unexpected number of elements in cell array.']);
%     end
% end
% 
% % Define the output path for the new .mat file
% output_folder = fullfile("documents", iOr); % Assuming 'r'
% if ~exist(output_folder, "dir")
%     mkdir(output_folder);
% end
% output_filename_mat_struct = fullfile(output_folder, 'render_data2.mat');
% 
% % Save the new struct-based map to a MAT file
% render_map = new_render_map; % Rename for saving
% save(output_filename_mat_struct, 'render_map');
% disp(['Converted data saved to: ', output_filename_mat_struct]);

%%
% % 模特名称列表（f=女性，m=男性，数字为编号）
% new_names = [ "f04", "f05", "f06", "m04", "m05", "m06",...
% "f01", "f02", "f03", "m01", "m02", "m03",...
% "f07", "f08","m07", "m08",...
% "f09", "f10","m09", "m10"];
% % 颜色标签列表（H=高照度，M=中照度，L=低照度，D65=标准光源）
% %------------i--------------
% % 校准数据路径（datai_ipv35_3.mat：LUT模型 显示模型的XYZ白点数据）
% datai_file = '..\..\calibration\display_model\datai_ipv35_3.mat';
% wd65=[94.813  100.000  107.262];
% LUT=load(datai_file);
% XYZw_LUT=LUT.XYZw;
% wd65_scaled=wd65./100.*XYZw_LUT(2);
% 
% % --- New: Initialize table for results ---
% results_table = table();
% 
% iOr='i';
% if iOr=='i'
%     pcn = ["H3K", "H4K", "H5K", "H6K", "HD65", "H7K", "H8K", ...
%            "M3K", "M4K", "M5K", "M6K", "MD65", "M7K", "M8K", ...
%            "L3K", "L4K", "L5K", "L6K", "LD65", "L7K", "L8K"];
% else
%     pcn = ["rs01","rs02","rs03","rs04","rs05","rs06","rs07", ...
%                  "rs08","rs09","rs10","rs11","rs12","rs13","rs14"];
% end
% 
% for i_model=1:length(new_names)
%     source_folder=fullfile('mask',strcat(new_names(i_model),iOr));
%     source_folder=char(source_folder);
%     slashes = strfind(source_folder, '\');
%     lastPart=source_folder(slashes(1,end)+1:end);
%     model = lastPart(1:end-1);
% 
%     if ismember(lastPart,["f04i","f05i","f06i","m04i","m06i"]) 
%         if_wei=0;
%     else
%         if_wei=1;
%     end
%     if ismember(lastPart,["m02i","m03i"]) 
%         if_2mask=1;
%     else
%         if_2mask=0;
%     end
% 
%     files = dir(strcat(source_folder,'\*.jpg'));  % 读取文件夹中的所有.jpg文件
% 
%     dir_mask=dir(fullfile("mask\",lastPart,"\*.jpg"));
%     dir_mask_nosd=dir(fullfile("Shadow\mask",lastPart,"nosd\*.jpg"));
%     dir_XYZfile=dir(fullfile("..\..\..\renderCode\XYZ",iOr,lastPart,"\*.mat"));
% 
%     for i = 1:numel(files)
%         filename = fullfile(files(i).folder, files(i).name);      
%         img0=imread(filename);
% 
%         bull = []; % Initialize bull
%         bull_nosd = []; % Initialize bull_nosd
%         XYZ = []; % Initialize XYZ
% 
%         for i_mask=1:length(dir_mask)
%             if strcmp(files(i).name(1:end-4),dir_mask(i_mask).name(1:end-4))
%                 bull=imread(strcat(dir_mask(i_mask).folder,'\',dir_mask(i_mask).name));
%                 bull_nosd=bull; % This line assigns bull to bull_nosd, consider if it's always intended
%                 break
%             end
%         end
%         for i_mask=1:length(dir_mask_nosd)
%             if strcmp(files(i).name(1:end-4),dir_mask_nosd(i_mask).name(1:end-4))
%                 bull_nosd=imread(strcat(dir_mask_nosd(i_mask).folder,'\',dir_mask_nosd(i_mask).name));
%                 break
%             end
%         end
%         for i_xyz=1:length(dir_XYZfile)
%             slash=find(dir_XYZfile(i_xyz).name=='_');
%             if isempty(slash)
%                 slash=0;
%             end
%             if strcmp(dir_XYZfile(i_xyz).name(slash+1 : end-4), files(i).name(1:end-4))                
%                 XYZ_data=load(fullfile(dir_XYZfile(i_xyz).folder,dir_XYZfile(i_xyz).name));
%                 XYZ=XYZ_data.XYZ_cropped;
%                 break
%             end
%         end
% 
%         % Check if necessary data is loaded
%         if isempty(bull) || isempty(XYZ)
%             warning(strcat('Skipping file: ', files(i).name, ' (Missing mask or XYZ data)'));
%             continue; 
%         end
% 
%         img=im2double(img0);
%         [m, n, p] = size(img);
%         xyz1= reshape(XYZ, [m * n, p]);
%         [lab1] = xyz2lab(xyz1,'user',wd65_scaled);
% 
%         average=get_average(lab1,bull,if_wei);
%         strcat(lastPart,files(i).name(1:end-4))
%         XYZw_white(i,:) = find_white(strcat(lastPart,files(i).name(1:end-4)));
%         wd65_64 = [94.811, 100.00, 107.304];
%         xyz_ave=lab2xyz2(average,"user",wd65_64./wd65_64(2).*XYZw_LUT(2));
%         ave_scaled(i,:)=xyz2lab(xyz_ave,"user",wd65_64./wd65_64(2).*XYZw_white(i,2));
% 
% 
%         [CCT,XYZw_pre] = find_CCT_combi(strcat(lastPart,files(i).name(1:end-4)));
%         E = find_E(strcat(lastPart,files(i).name(1:end-4)));
%         XYZ_bf = lab2xyz2(ave_scaled(i,:), 'd65_64'); 
%         D = calculateD(CCT, 0, "CAT16",E);
%         XYZ_aft = CAT16_D(XYZ_bf,  XYZw_pre,wd65_64, D);
%         average_aft(i,:) = xyz2lab(XYZ_aft, 'd65_64');
% 
%         % --- Calculate ITA ---
%         ITA = atand((average_aft(i,1)-50)/average_aft(i,3));
%         ITA
% 
%         % --- Classify Skin Type based on ITA ---
%         skin_classification = '';
%         if ITA > 55
%             skin_classification = 'Very light';
%         elseif ITA > 41 && ITA <= 55
%             skin_classification = 'Light';
%         elseif ITA > 28 && ITA <= 41
%             skin_classification = 'Intermediate';
%         elseif ITA > 10 && ITA <= 28
%             skin_classification = 'Tan';
%         elseif ITA > -30 && ITA <= 10
%             skin_classification = 'Brown';
%         elseif ITA <= -30
%             skin_classification = 'Dark';
%         end
% 
%         % --- Add results to table ---
%         new_row = table({lastPart}, {files(i).name}, ITA, {skin_classification}, ...
%                         'VariableNames', {'ModelName', 'FileName', 'ITA_Value', 'SkinClassification'});
%         results_table = [results_table; new_row];
% 
%         disp(strcat('Processed: ', lastPart, ' - ', files(i).name));
%     end
%     disp("d")
% end
% 
% % --- Save results to XLSX ---
% output_filename = 'ITA_Skin_Classification_Results.xlsx';
% writetable(results_table, output_filename);
% disp(strcat('Results saved to: ', output_filename));