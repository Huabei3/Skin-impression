% ======================================
% 代码功能：基于颜色渲染的属性评分模拟系统
% 适用场景：图像处理、颜色科学、属性评分预测
% 依赖工具：MATLAB R2020+、Image Processing Toolbox、自定义工具包
% 作者：XXX
% 版本：V1.0（2025-05-19）- Modified for par calculation logic
% ======================================
% 依赖工具说明：
% 1. Godel计算工具：用于数值计算（若有计算步骤）
% 2. 自定义工具包：
%    - utils文件夹需包含：
%      - xyz2lab.m, lab2xyz2.m       （颜色空间转换）
%      - read_bull.m                 （读取遮罩）
%      - calculate_target_ab.m       （计算目标ab值）
%      - deltaE2000.m                （色差计算）
%      - calculate_par_from_ellipse.m (新添加或确保存在，用于计算椭圆参数)
%      - find_cluster.m              (新添加或确保存在，用于找到渲染模式下的聚类)
% 3. 外部数据：
%    - calibration文件夹：显示模型校准数据（.mat文件）
%    - mask/Shadow文件夹：遮罩图像（.jpg格式）
%    - data/ellipse_para：椭圆拟合参数（用于属性评分模型）
close all;
clc;
clear;
addpath("..\..\utils\");
%% Initialization and Data Loading
% Model and color tag lists (unchanged)
new_names = [ "f04", "f05", "f06", "m04", "m05", "m06",...
"f01", "f02", "f03", "m01", "m02", "m03",...
"f07", "f08","m07", "m08",...
"f09", "f10","m09", "m10"];
% Calibration data path
datai_file = '..\..\calibration\display_model\datai_ipv35_3.mat';
wd65=[94.813  100.000  107.262];
LUT=load(datai_file);
XYZw_LUT=LUT.XYZw;
wd65_scaled=wd65./100.*XYZw_LUT(2);
% Attributes and scoring configuration
attributes = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
attribute_names = ["Preference", "Attractiveness", "Feminine", "Cooperative", ...
    "Youth", "Healthy", "Fidelity","Harmony", "Fair", "Ruddy"];
target_score=1; % Target score value (0-1, converted to percentage)
target_score_str=num2str(target_score*100); % Stringified score for path naming
score_type="rela"; % Scoring type
render_type="srgb";
% enhance_type="cherry";
enhance_type="None";
iOr='r'; % 'i' for input, 'r' for render
if iOr=='i'
    pcn = ["H3K", "H4K", "H5K", "H6K", "HD65", "H7K", "H8K", ...
           "M3K", "M4K", "M5K", "M6K", "MD65", "M7K", "M8K", ...
           "L3K", "L4K", "L5K", "L6K", "LD65", "L7K", "L8K"];
else
    pcn = ["rs01","rs02","rs03","rs04","rs05","rs06","rs07", ...
                 "rs08","rs09","rs10","rs11","rs12","rs13","rs14"];
end
Dtype="efit2";
obs_type="non_model";
% --- Load pre-processed render_map ---
% This is the crucial change: loading all pre-processed data once
render_data_path = fullfile("documents", iOr, 'render_data1.mat'); % Assuming 'render_data.mat' contains the struct map
if exist(render_data_path, 'file')
    loaded_map_data = load(render_data_path, 'render_map');
    render_map = loaded_map_data.render_map;
    disp(['Successfully loaded render_map from: ', render_data_path]);
else
    error(['Error: render_map file not found at ', render_data_path, '. Please run the data preprocessing script first.']);
end
% Load standard Lab values
load("aveLab_D65_Asian.mat","labC_HD65");
lab_PMCC = [62.11, 18.96, 19.76];
labC_PMCC = [lab_PMCC, sqrt(lab_PMCC(1, 2)^2 + lab_PMCC(1, 3)^2)];


wd65_64 = [94.811, 100.00, 107.304];
datai_file = '..\..\calibration\display_model\datai_ipv35_3.mat';
LUT=load(datai_file);
XYZw_LUT=LUT.XYZw;




%% Main Processing Loop
for i_model=17:length(new_names)
    source_folder=fullfile('mask',strcat(new_names(i_model),iOr));
    source_folder=char(source_folder);
    slashes = strfind(source_folder, '\');
    lastPart=source_folder(slashes(1,end)+1:end);
    model = lastPart(1:end-1);
    
    % Weighting and mask flags
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
    
    i_type=select_type(model); % Assuming select_type is a defined function
    
    files = dir(strcat(source_folder,'\*.jpg')); % Read all .jpg files in the folder
    
    % Saving path rule
    save_folder=fullfile('rendered',"CATed_ori",lastPart);
    if ~exist(save_folder, 'dir')
        mkdir(save_folder);
    end

    % Load average Lab values for the current model, used for par calculation
    % This is aligned with how the second script gets 'average' for parameter calculation
    average_file_for_par = fullfile("aveSkin", lastPart, "autoNhand_scaleoverLUT.mat");
    average_data_for_par = load(average_file_for_par);
    average_lab_per_pcn = average_data_for_par.average_lab_all(:, 1:3); % L, a, b for each PCN
    load(fullfile("D:\work\VIVOskinExpe\analyze\optimizedD\backGroundGray", ...
    strcat(lastPart,".mat")),"xyz_gray");
    for i = 1:numel(files)
        filename = fullfile(files(i).folder, files(i).name);
        img0=imread(filename); % Original image
        
        % Construct the unique identifier for render_map lookup
        current_id_str = lower(strcat(lastPart,files(i).name(1:end-4)));
        
        % --- Directly retrieve data from render_map ---
        if isKey(render_map, current_id_str)
            data_from_map = render_map(current_id_str);
            bull_name = data_from_map.bull_name;
            bull_nosd_name = data_from_map.bull_nosd_name;
            XYZ_filename = data_from_map.XYZ_filename;

            xyz_data_path = fullfile("..\..\..\renderCode\XYZ",iOr,lastPart,XYZ_filename);
            loaded_xyz = load(xyz_data_path);
            XYZ = loaded_xyz.XYZ_cropped;
            XYZw=loaded_xyz.XYZw;
            % Retrieve pre-calculated LAB values and CCT/XYZw_pre/E
            average_render_map = data_from_map.average; % This 'average' is for the current image's overall Lab
            CCT = data_from_map.CCT_val;
            XYZw_pre = data_from_map.XYZw_pre_val;
            % E_val = data_from_map.E_val; % E_val is not used directly in this loop from the previous version, but can be retrieved if needed
        else
            warning(strcat('Skipping file: ', files(i).name, ' (Data not found in render_map for key: ', current_id_str, ')'));
            continue; % Skip to the next file if data is not found in the map
        end
        [CCT,XYZw_pre(i, :)] = find_CCT_combi(strcat(lastPart,pcn(i)));
        E=xyz_gray(i,2);
        D(i,1) = calculateD(CCT, 0, Dtype,E);
        [m, n, p] = size(XYZ);
        xyz1=reshape(XYZ, [m * n, p]);
        XYZ_bf=xyz1./XYZw_LUT(2).*wd65_64(2);
        % XYZ_bf=xyz1./XYZw(2).*wd65_64(2);
        XYZ_aft = CAT16_D(XYZ_bf,  XYZw_pre(i, :),wd65_64, D(i,1));
        rgbnew=xyz2srgb(XYZ_aft);
        rgbnew=rgbnew./255;
        outnew = reshape(rgbnew, [m, n, p]);
        % --- ADDED CODE START ---
        % Display the image
        figure(1); % Create a new figure for each image
        imshow(outnew);
        title(sprintf('Rendered Image: %s', files(i).name)); % Add a title

        % Save the image
        [~, name, ext] = fileparts(files(i).name);
        save_path = fullfile(save_folder,files(i).name);
        imwrite(outnew, save_path);
        close(1)
        % --- ADDED CODE END ---

    end
end