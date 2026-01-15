close all; 
clc;       
clear;     

%%
%------------i--------------

source_folder = 'mask\male39i';
slashes = strfind(source_folder, '\');
lastPart = source_folder(slashes(1,end)+1:end);
model = lastPart(1:end-1);

i_type = select_type(model);

files = dir(strcat(source_folder, '\*.jpg'));  % 读取文件夹中的所有.jpg文件

dir_mask = dir(strcat("mask\", lastPart, "\*.jpg"));
dir_XYZfile = dir(strcat("XYZ\maxw_i\", lastPart, "\*.mat"));

ct = ["H3K","H4K","H5K","H6K","H7K","H8K","HD65",...
    "L3K","L4K","L5K","L6K","L7K","L8K","LD65",...
    "M3K","M4K","M5K","M6K","M7K","M8K","MD65"];

load(fullfile("aveSkinByHand2", "i", strcat("aveLab_D65_", num2str(i_type), ".mat")), ...
    "labC_HD65");

average_file = strcat("aveSkinByHand2\", lastPart, "\autoNhand_scaleoverLUT.mat");
average = load(average_file);
average = average.average_lab_all(:, 1:3);

save_folder = fullfile('rendered\check_aveNnosd', lastPart);
if ~exist(save_folder, 'dir')
    mkdir(save_folder);
end
nosh_folder = fullfile(save_folder, "nosd_mask");
if ~exist(nosh_folder, 'dir')
    mkdir(nosh_folder);
end

num_points = readmatrix('points_added_33.xlsx'); 
num_points = [zeros(length(num_points), 1), num_points];

for i = 1:numel(files)
    filename = fullfile(files(i).folder, files(i).name);      
    img0 = imread(filename);
    img = im2double(img0);
    [m, n, p] = size(img);

    startCenter = 1;
    endCenter = length(num_points);

    for i_mask = 1:length(dir_mask)
        if strcmp(files(i).name(1:end-4), dir_mask(i_mask).name(1:end-4))
            picname_check{i, 1} = files(i).name(1:end-4);
            picname_check{i, 2} = dir_mask(i_mask).name(1:end-4);
            break
        end
    end

    C_pre = 6.7421 * log(average(i, 1)) - 9.9816; % 亮度实验
    factor(i, :) = C_pre ./ labC_HD65(1, 4);
    dlabs = repmat([average(i, 1), labC_HD65(1, 2:3)], length(num_points), 1) + num_points;
    dlabs(:, 2:3) = dlabs(:, 2:3) .* factor(i, :);
    shadow_pos=[];
    for i_points = 33:33
        dlab = dlabs(i_points, :);
        delta_Lab = dlab - average(i, :); 
        delta_Lab0 = dlabs(33, :) - average(i, :); 

        dir_img_file = dir(fullfile(save_folder ...
            , strcat(files(i).name(1:end-4), '_', sprintf('%02d', i_points), '*.jpg')));
        if ~isempty(dir_img_file)
            continue
        end

        bull = imread(strcat(dir_mask(i_mask).folder, '\', dir_mask(i_mask).name));
        bull=double(bull)./255;
        bull_reshaped = reshape(bull, [m * n, p]) ;
        bull_reshaped = double(bull_reshaped);
        bull_weight = mean(bull_reshaped, 2);
        logicalIndex = all(bull_reshaped == 0, 2);

        for i_xyz = 1:length(dir_XYZfile)
            if strcmp(dir_XYZfile(i_xyz).name(1:end-4), files(i).name(1:end-4))
                picname_check{i, 4} = dir_XYZfile(i_xyz).name(1:end-4);
                XYZ = load(fullfile(dir_XYZfile(i_xyz).folder, dir_XYZfile(i_xyz).name));
                XYZ = XYZ.XYZ_cropped;
                break
            end
        end

        noFaceRGB_folder = fullfile(save_folder, "noFaceRGB");
        if ~exist(noFaceRGB_folder, "dir")
            mkdir(noFaceRGB_folder);
        end
        noFaceRGB_file = fullfile(noFaceRGB_folder, ...
            strcat(files(i).name(1:end-4), ".mat"));

        disp([num2str(i_points), '/', num2str(endCenter), 'of', ...
            num2str(i), '/', num2str(numel(files)), ' ', files(i).name, ' begin']);
        startTime = datetime('now'); 

        %---------计算 dest_lab 和 bull_nosd-----------
        datai_file = 'calibResults\model3d_file_350_1deg_realP3\datai_ipv40_3.mat';
        wd65 = [94.813  100.000  107.262];
        LUT = load(datai_file);
        XYZw_LUT = LUT.XYZw;
        wd65_scaled = wd65 ./ 100 .* XYZw_LUT(2);

        xyz1 = reshape(XYZ, [m * n, p]);
        lab1 = xyz2lab(xyz1, 'user', wd65_scaled);
        lab2 = lab1 + repmat(delta_Lab, length(lab1), 1) .* bull_weight;
        lab3 = lab1 + repmat(delta_Lab0, length(lab1), 1) .* bull_weight;

        lab1_face = lab1(~logicalIndex, :);
        lab2_face = lab2(~logicalIndex, :);
        lab3_face = lab3(~logicalIndex, :);

        shadow_index1 = lab1_face(:, 2) < 0 | lab1_face(:, 3) < 0;
        shadow_index3 = lab3_face(:, 2) < 0 | lab3_face(:, 3) < 0;
        shadow_index = (~shadow_index1) & shadow_index3;

        lab2_face(:, 2) = max(0, lab2_face(:, 2));
        lab2_face(:, 3) = max(0, lab2_face(:, 3));
        lab2_face(shadow_index, 2) = 0;
        lab2_face(shadow_index, 3) = 0;
        lab2(~logicalIndex, :) = lab2_face;

        xyz2 = lab2xyz2(lab2, 'user', wd65_scaled);

        face_positions = find(~logicalIndex); % 找到非逻辑索引的位置
        negative_positions = face_positions(shadow_index); % 筛选出 negative_index 对应的位置
        [shadow_pos(:, 1), shadow_pos(:, 2)] = ind2sub([m, n], negative_positions);
        bull_nosd = mean(bull, 3);
        bull_nosd(sub2ind([m, n], shadow_pos(:, 1), shadow_pos(:, 2))) = 0;

        bull_nosd_rspd = reshape(bull_nosd, [m * n, 1]);
        logicalIndex1 = all(bull_nosd_rspd == 0, 2);

        bull_weight(negative_positions) = 0;
        lab2_wei = lab2 .* repmat(bull_weight, 1, size(lab2, 2));
        lab1_wei = lab1 .* repmat(bull_weight, 1, size(lab2, 2));

        dest_lab = sum(lab2_wei(~logicalIndex1, :)) ./ sum(bull_weight);
        average1(i,:)=sum(lab1_wei(~logicalIndex1, :)) ./ sum(bull_weight);

        % 保存 dest_lab 和 bull_nosd

        imwrite(bull_nosd, fullfile(nosh_folder, files(i).name));

        currentTime = datetime('now');   
        formattedTime = datestr(currentTime, 'yyyy-mm-dd HH:MM:SS');
        disp([files(i).name(1:end-4), '_', num2str(i_points), 'finished: ', formattedTime]);
        time_diff = currentTime - startTime;
        fprintf('时间差: %s\n', time_diff);
    end

    save(fullfile(save_folder, strcat(files(i).name(1:end-4),'.mat')), ...
        'average1');
    currentTime = datetime('now');  
    formattedTime = datestr(currentTime, 'yyyy-mm-dd HH:MM:SS');
    disp([files(i).name(1:end-4), 'finished: ', formattedTime]);
end

function i_type = select_type(model)
    models{1, 1} = ["male92", "male91", "male48", "female01", "female04", "female06", "male97"];
    models{2, 1} = ["male59", "male39", "male39aftPS", "maleVIVO", "female78", "female02", "female41", "femaleVIVO"];
    models{3, 1} = ["male21", "male46", "female23", "female51"];
    models{4, 1} = ["male22", "male28", "female25", "female69"];
    if ismember(model, models{1, 1})
        i_type = 1;
    elseif ismember(model, models{2, 1})
        i_type = 2;
    elseif ismember(model, models{3, 1})
        i_type = 3;
    elseif ismember(model, models{4, 1})
        i_type = 4;
    else
        error("model doesn't exist");
    end
end