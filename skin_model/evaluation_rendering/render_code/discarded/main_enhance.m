% ======================================
% 代码功能：基于颜色渲染的属性评分模拟系统
% 适用场景：图像处理、颜色科学、属性评分预测
% 依赖工具：MATLAB R2020+、Image Processing Toolbox、自定义工具包
% 作者：XXX
% 版本：V1.0（2025-05-19）
% ======================================
% 依赖工具说明：
% 1. Godel计算工具：用于数值计算（若有计算步骤）
% 2. 自定义工具包：
%    - utils文件夹需包含：
%      - xyz2lab.m, lab2xyz2.m       （颜色空间转换）
%      - read_bull.m                 （读取遮罩）
%      - calculate_target_ab.m       （计算目标ab值）
%      - deltaE2000.m                （色差计算）
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
enhance_type="cherry";
iOr='i'; % 'i' for input, 'r' for render

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

%% Main Processing Loop
for i_model=1:length(new_names)
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
    save_folder=fullfile('rendered',enhance_type,render_type,obs_type,target_score_str,lastPart);
    if ~exist(save_folder, 'dir')
        mkdir(save_folder);
    end
    
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
            
            % Re-load mask and XYZ data based on filenames stored in the map
            % Assuming mask and XYZ files are still in their original locations
            bull = imread(fullfile("mask", lastPart, bull_name));
            bull_nosd = imread(fullfile("Shadow", "mask", lastPart, "nosd", bull_nosd_name)); % Corrected path based on previous script
            
            xyz_data_path = fullfile("..\..\..\renderCode\XYZ",iOr,lastPart,XYZ_filename);
            loaded_xyz = load(xyz_data_path);
            XYZ = loaded_xyz.XYZ_cropped;

            % Retrieve pre-calculated LAB values and CCT/XYZw_pre/E
            average = data_from_map.average;
            CCT = data_from_map.CCT_val;
            XYZw_pre = data_from_map.XYZw_pre_val;
            % E_val = data_from_map.E_val; % E_val is not used directly in this loop from the previous version, but can be retrieved if needed
        else
            warning(strcat('Skipping file: ', files(i).name, ' (Data not found in render_map for key: ', current_id_str, ')'));
            continue; % Skip to the next file if data is not found in the map
        end

        img=im2double(img0);
        [m, n, p] = size(img);
        
        % Formula source: Empirical model based on brightness experiments
        % C_pre = 6.7421 * ln(L) - 9.9816, where L is the brightness value of the input Lab (0-100)
        % Function: Convert input brightness to a brightness factor matching the standard light source (HD65)
        C_pre=6.7421*log(average(1))-9.9816; % average(1) is the average L value of the current image
        factor(i,:)=C_pre./labC_HD65(1,4);
        labC_PMCCpre(i, 1) = average(1);
        labC_PMCCpre(i, 2:3) = lab_PMCC(1, 2:3) ./ labC_PMCC(1, 4) .* C_pre;
        labC_PMCCpre(i, 4) = C_pre;

        % --- Render attributes ---
        for attribute = [1,7,8,9,10] % Process selected attributes
            attribute_serial = strcat(sprintf("%02d", attribute), attribute_names(attribute));
            [nation,i_nation,nation_serial]=find_nation(model); % Assuming find_nation is defined
            [corr_picname]= find_corr_res(files(i).name(1:end-4)); % Assuming find_corr_res is defined
            
            fit_center_data_file = fullfile('D:\work\VIVOskinExpe\analyze\AnalyseResults1', ...
                Dtype,"nation", 'scale_factor_fit_results', obs_type,"i", nation);
            
            full_fit_center_file = fullfile(fit_center_data_file, ...
                                    strcat("a_scale_",attribute_serial,".mat"));
            
            if exist(full_fit_center_file,'file') == 2
                [~,i_par]=ismember(files(i).name(1:end-4),pcn);
                load(full_fit_center_file, ...
                            'a_scale', "a_CL","all_ave_curr_z","all_par");
                if iOr == 'r'
                    source_folder = fullfile('D:\work\VIVOskinExpe\analyze\AnalyseResults1', ...
                        Dtype,'50','cluster_50',obs_type, ...
                        iOr,attribute_serial,nation_serial);
                    cluster=find_cluster(pcn(i_par),i_nation);
                    full_path=fullfile(source_folder,strcat(cluster,".mat"));
                    data = load(full_path);                    
                    par = get_par_fr_SF(average(1), a_scale, a_CL, data.par); 
                else
                    par = get_par_fr_SF(average(1), a_scale, a_CL, all_par{1});
                end
                target_ab=[];
                % Calculate target ab values (based on hue and chroma)
                [target_ab(1,1),target_ab(1,2),target_ab(2,1),target_ab(2,2)] = ...
                    calculate_target_ab( par,target_score,"hue",score_type); % Assuming calculate_target_ab is defined
                [target_ab(3,1),target_ab(3,2),target_ab(4,1),target_ab(4,2)] = ...
                    calculate_target_ab( par,target_score,"chroma",score_type);
                
                % Filter invalid values (NaN rows, possibly due to failed fitting or ellipse too close to origin)
                nan_rows = any(isnan(target_ab), 2);
                target_ab = target_ab(~nan_rows, :);
                [target_ab, ~, ~] = unique(target_ab, 'rows');
                
                if isempty(target_ab)
                    warning(strcat('Skipping file: ', files(i).name,' (No valid target ab values for attribute ', attribute_serial, ')'));
                    continue; % Skip current image for this attribute
                end
                
                % Plotting target score preview
                figure(1);
                % figure("Visible","off"); % Use this for headless plotting
                plot_target_score(par,target_ab,target_score,score_type); % Assuming plot_target_score is defined
                title(files(i).name(1:end-4));
                if ~exist(fullfile(save_folder,"90pre_draw"),"dir")
                    mkdir(fullfile(save_folder,"90pre_draw"));
                end
                exportgraphics(gcf, fullfile(save_folder,"90pre_draw", ...
                    strcat(files(i).name(1:end-4),attribute_serial,".jpg")), ...
                    'Resolution', 300);
                % close(gcf); % Close figure if using "Visible","off"
                
                % --- Calculate center ---
                if ~isempty(target_ab)
                    dlabs_90=[repmat(average(1),size(target_ab,1),1),target_ab(:,1),target_ab(:,2)];
                    for i_dlabs_90=1:size(dlabs_90,1)
                        dlab=CAT_lab2lab_combi(dlabs_90(i_dlabs_90,:),"ZJUCAT",CCT,XYZw_pre,"fore"); % Assuming CAT_lab2lab_combi is defined
                        % delta_Lab=dlab-average; % Use average retrieved from map
                        
                        % Check if the rendered image already exists
                        dir_img_file=dir(fullfile(save_folder,files(i).name(1:end-4), ...
                            strcat(files(i).name(1:end-4),'_',attribute_serial,sprintf("%02d",i_dlabs_90),'*.jpg')));
                        if ~isempty(dir_img_file)
                            continue % Skip rendering if file already exists
                        end
                        
                        noFaceRGB_folder=fullfile(save_folder,"noFaceRGB");
                        if ~exist(noFaceRGB_folder,"dir")
                            mkdir(noFaceRGB_folder);
                        end
                        noFaceRGB_file=fullfile(noFaceRGB_folder, ...
                            strcat(files(i).name(1:end-4),".mat"));
                        
                        disp(strcat(model,files(i).name,attribute_serial, ...
                            sprintf("%02d",i_dlabs_90),' begin'));
                        startTime = datetime('now');
                        
                        % --- Rendering ---
                        % Main rendering function (inputs: original image, mask, no-shadow mask, LUT parameters, target Lab difference)
                        [out_rendering]=...
                            skin_enhance(img, bull,average, "srgb", ...
                            dlab,XYZ,noFaceRGB_file,if_wei,par,enhance_type); 
                        
                        % deltaE2000(dest_lab,dlab); 
                        % --- End Rendering ---
                        
                        imshow(out_rendering);
                        disp([files(i).name,' was done']);
                        
                        % Save rendered image
                        if ~exist(fullfile(save_folder,files(i).name(1:end-4)),"dir")
                            mkdir(fullfile(save_folder,files(i).name(1:end-4)));
                        end
                        imwrite(out_rendering,fullfile(save_folder,files(i).name(1:end-4), ...
                            strcat(files(i).name(1:end-4),'_',attribute_serial, ...
                            sprintf("%02d",i_dlabs_90),'[',num2str(dlab(1,1)),',' ,...
                            num2str(dlab(1,2)),',',num2str(dlab(1,3)),'].jpg')) );
                        
                        % Save dlab data
                        dlab_folder=fullfile(save_folder,files(i).name(1:end-4),'dlab',target_score_str);
                        if ~exist(dlab_folder,"dir")
                            mkdir(dlab_folder);
                        end
                        save(fullfile(dlab_folder, strcat(files(i).name(1:end-4), ...
                            '_',attribute_serial,sprintf("%02d",i_dlabs_90),".mat")),"dlab");
                        
                        currentTime = datetime('now');
                        fprintf('Time difference: %s\n', currentTime - startTime);
                    end
                end
            else
                warning(strcat('Missing file: ', fit_center_data_file, ' (Skipping attribute ', attribute_serial, ')'));
            end
        end
    end
end