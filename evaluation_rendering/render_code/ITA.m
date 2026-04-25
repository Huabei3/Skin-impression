close all;
clc;
clear;

addpath("..\..\utils\");

%% 模特名称列表（f=女性，m=男性，数字为编号）
new_names = [ "f04", "f05", "f06", "m04", "m05", "m06",...
"f01", "f02", "f03", "m01", "m02", "m03",...
"f07", "f08","m07", "m08",...
"f09", "f10","m09", "m10"];

% 颜色标签列表（H=高照度，M=中照度，L=低照度，D65=标准光源）
%------------i--------------
% 校准数据路径（datai_ipv35_3.mat：LUT模型 显示模型的XYZ白点数据）
datai_file = '..\..\calibration\display_model\datai_ipv35_3.mat';
wd65=[94.813 100.000 107.262];
LUT=load(datai_file);
XYZw_LUT=LUT.XYZw;
wd65_scaled=wd65./100.*XYZw_LUT(2);

% --- Initialize table for results ---
% Add new columns for the additional data
results_table = table(...
cell(0,1), cell(0,1), zeros(0,1), cell(0,1), ... % Existing columns
zeros(0,3), zeros(0,3), zeros(0,3), zeros(0,3), ... % XYZw_white_val, average, ave_scaled_val, average_aft_val
zeros(0,1), zeros(0,3), zeros(0,1), ... % CCT_val, XYZw_pre_val, E_val
'VariableNames', {'ModelName', 'FileName', 'ITA_Value', 'SkinClassification', ...
'XYZw_White', 'Average_LAB', 'Ave_Scaled_LAB', 'Average_Aft_LAB', ...
'CCT', 'XYZw_Pre', 'E_Val'});

% --- Initialize a containers.Map for storing processed data ---
render_map = containers.Map;

iOr='r';
if iOr=='i'
    pcn = ["H3K", "H4K", "H5K", "H6K", "HD65", "H7K", "H8K", ...
        "M3K", "M4K", "M5K", "M6K", "MD65", "M7K", "M8K", ...
        "L3K", "L4K", "L5K", "L6K", "LD65", "L7K", "L8K"];
else
    pcn = ["rs01","rs02","rs03","rs04","rs05","rs06","rs07", ...
        "rs08","rs09","rs10","rs11","rs12","rs13","rs14"];
end

% 创建保存图片的目录
figures_dir = fullfile("documents", iOr, "scatter_plots");
if ~exist(figures_dir, "dir")
    mkdir(figures_dir);
end
max_lim_x=0;
max_lim_y=0;
colors=hsv(length(new_names));
for i_model=1:length(new_names)
    source_folder=fullfile('mask',strcat(new_names(i_model),iOr));
    source_folder=char(source_folder);
    slashes = strfind(source_folder, '\');
    lastPart=source_folder(slashes(1,end)+1:end);
    model = lastPart(1:end-1);
    
    if ismember(lastPart,["f04i","f05i","f06i","m04i","m06i"])
        if_wei=0;
    else
        if_wei=1;
    end
    
    if ismember(lastPart,["m02i","m03i"])
        if_2mask=1;
    else
        if_2mask=0;
    end
    
    files = dir(strcat(source_folder,'\*.jpg')); % 读取文件夹中的所有.jpg文件
    dir_mask=dir(fullfile("mask\",lastPart,"\*.jpg"));
    dir_mask_nosd=dir(fullfile("Shadow\mask",lastPart,"nosd\*.jpg"));
    dir_XYZfile=dir(fullfile("..\..\..\renderCode\XYZ",iOr,lastPart,"\*.mat"));
    
    % 存储当前模特的所有average_aft_val(2:3)数据
    scatter_data = [];
    scatter_data_scaled = [];
    filenames_list = {};
    
    for i = 1:numel(files)
        filename = fullfile(files(i).folder, files(i).name);
        img0=imread(filename);
        
        bull_name = ''; % Store mask filename
        bull_nosd_name = '';% Store no-shadow mask filename
        XYZ_filename = ''; % Store XYZ filename
        bull = []; % Initialize bull
        bull_nosd = []; % Initialize bull_nosd
        XYZ = []; % Initialize XYZ
        
        for i_mask=1:length(dir_mask)
            if strcmp(files(i).name(1:end-4),dir_mask(i_mask).name(1:end-4))
                bull=imread(strcat(dir_mask(i_mask).folder,'\',dir_mask(i_mask).name));
                bull_name = dir_mask(i_mask).name;
                bull_nosd=bull; % This line assigns bull to bull_nosd, consider if it's always intended
                bull_nosd_name = bull_name; % Initialize with bull_name
                break
            end
        end
        
        for i_mask=1:length(dir_mask_nosd)
            if strcmp(files(i).name(1:end-4),dir_mask_nosd(i_mask).name(1:end-4))
                bull_nosd=imread(strcat(dir_mask_nosd(i_mask).folder,'\',dir_mask_nosd(i_mask).name));
                bull_nosd_name = dir_mask_nosd(i_mask).name;
                break
            end
        end
        
        for i_xyz=1:length(dir_XYZfile)
            slash=find(dir_XYZfile(i_xyz).name=='_');
            if isempty(slash)
                slash=0;
            end
            if strcmp(dir_XYZfile(i_xyz).name(slash+1 : end-4), files(i).name(1:end-4))
                XYZ_data=load(fullfile(dir_XYZfile(i_xyz).folder,dir_XYZfile(i_xyz).name));
                XYZ=XYZ_data.XYZ_cropped;
                XYZ_filename = dir_XYZfile(i_xyz).name;
                break
            end
        end
        
        % Check if necessary data is loaded
        if isempty(bull) || isempty(XYZ)
            warning(strcat('Skipping file: ', files(i).name, ' (Missing mask or XYZ data)'));
            continue;
        end
        
        img=im2double(img0);
        [m, n, p] = size(img);
        xyz1= reshape(XYZ, [m * n, p]);
        [lab1] = xyz2lab(xyz1,'user',wd65_scaled);
        
        current_id_str = lower(strcat(lastPart,files(i).name(1:end-4)));
        average=get_average(lab1,bull,if_wei);
        
        % Call find_white with the correct current_id_str
        XYZw_white_val = find_white(current_id_str);
        
        wd65_64 = [94.811, 100.00, 107.304];
        xyz_ave=lab2xyz2(average,"user",wd65_64./wd65_64(2).*XYZw_LUT(2));
        ave_scaled_val=xyz2lab(xyz_ave,"user",wd65_64./wd65_64(2).*XYZw_white_val(2));
        
        % Call find_CCT_combi and find_E with the correct current_id_str
        [CCT_val,XYZw_pre_val] = find_CCT_combi(current_id_str);
        E_val = find_E(current_id_str);
        
        XYZ_bf = lab2xyz2(ave_scaled_val, 'd65_64');
        % D = calculateD(CCT_val, 0, "CAT16",E_val);
        D=1;
        XYZ_aft = CAT16_D(XYZ_bf, XYZw_pre_val,wd65_64, D);
        average_aft_val = xyz2lab(XYZ_aft, 'd65_64');
        
        % 存储当前文件的average_aft_val(2:3)数据
        scatter_data = [scatter_data; average_aft_val];
        scatter_data_scaled = [scatter_data_scaled; ave_scaled_val];
        filenames_list{end+1} = files(i).name;
        
        % --- Calculate ITA ---
        ITA_val = atand((average_aft_val(1)-50)/average_aft_val(3));
        
        % --- Classify Skin Type based on ITA ---
        skin_classification_val = '';
        if ITA_val > 55
            skin_classification_val = 'Very light';
        elseif ITA_val > 41 && ITA_val <= 55
            skin_classification_val = 'Light';
        elseif ITA_val > 28 && ITA_val <= 41
            skin_classification_val = 'Intermediate';
        elseif ITA_val > 10 && ITA_val <= 28
            skin_classification_val = 'Tan';
        elseif ITA_val > -30 && ITA_val <= 10
            skin_classification_val = 'Brown';
        elseif ITA_val <= -30
            skin_classification_val = 'Dark';
        end
        
        disp([num2str(ITA_val), ' ', skin_classification_val]) % Display ITA and classification
        
        % --- Add results to table ---
        new_row = table({lastPart}, {files(i).name}, ITA_val, {skin_classification_val}, ...
            XYZw_white_val, average, ave_scaled_val, average_aft_val, ...
            CCT_val, XYZw_pre_val, E_val, ...
            'VariableNames', {'ModelName', 'FileName', 'ITA_Value', 'SkinClassification', ...
            'XYZw_White', 'Average_LAB', 'Ave_Scaled_LAB', 'Average_Aft_LAB', ...
            'CCT', 'XYZw_Pre', 'E_Val'});
        
        results_table = [results_table; new_row];
        
        % --- Store data in the hashmap ---
        curr_cell= {
            bull_name, ...
            bull_nosd_name, ...
            XYZ_filename, ...
            XYZw_white_val, ...
            average, ...
            ave_scaled_val, ...
            average_aft_val, ...
            CCT_val, ...
            XYZw_pre_val, ...
            E_val,...
            ITA_val, ...
            skin_classification_val
        };
        
        render_map(current_id_str)=curr_cell;
        disp(strcat('Processed: ', lastPart, ' - ', files(i).name));
    end
%%
    figure(1);hold on;
    for j=1:size(scatter_data,1)
        text(scatter_data(j,2), scatter_data(j,3), ...
            filenames_list{j}(1:end-4),'Color',colors(i_model,:), ...
            'FontSize', 6);    
        text(scatter_data_scaled(j,2), scatter_data_scaled(j,3), ...
            filenames_list{j}(1:end-4),'Color','k', ...
            'FontSize', 6);    
    end
    scatter(scatter_data(:,2), scatter_data(:,3), 50, '^',...
        'filled', 'MarkerEdgeColor', colors(i_model,:));
    scatter(scatter_data_scaled(:,2), scatter_data_scaled(:,3), 50, ...
        'filled', 'MarkerEdgeColor', colors(i_model,:));
    xlabel('a* value');
    ylabel('b* value');
    title(['Average a* vs b* Values for ', lastPart]);
    grid on;    
    box on;

    max_lim_x=max(max_lim_x,max(scatter_data(:,2))+25);
    max_lim_y=max(max_lim_y,max(scatter_data(:,3))+25);
    xlim([-5,max_lim_x]);
    ylim([-5,max_lim_y]);
    axis equal;
    % 保存图片
    fig_filename = fullfile(figures_dir, strcat(lastPart, '_scatter.jpg'));
    print(fig_filename, '-dpng', '-r300');
    disp(strcat('Scatter plot saved: ', fig_filename));

%%

disp("d")
end

% --- Save results to XLSX ---
if ~exist(fullfile("documents",iOr),"dir")
    mkdir(fullfile("documents",iOr))
end
output_filename_xlsx = fullfile("documents",iOr,'ITA_Skin_Classification_Results.xlsx');
writetable(results_table, output_filename_xlsx);
disp(strcat('Results saved to: ', output_filename_xlsx));
