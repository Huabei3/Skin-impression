clear all;
% Load the XYZ data from csv
% Only modeling x200/729 data, output as phase2_{1~5}

n_phones = 5;  % phase2: 1~5 (corresponding to original i_device 14~18)

for i_device = 1:5
    
    SPDname = 380:1:780;
    SPDname = SPDname';
    
    % Only load from x200 directory
    dir_729data = dir(fullfile("D:\work\VIVOskinExpe\renderCode\calibResults\x200", ...
        strcat("VIVO_CS2000_729_x200_", num2str(i_device), "_1deg_P3*.mat")));
    
    load(fullfile(dir_729data(1).folder, dir_729data(1).name));
    
    DATAs(1,:) = [];
    SPD = reshape(cell2mat(DATAs(:,4)), 401, length(DATAs));
    XYZ10 = spd2xyz([SPDname SPD], 10);
    
    load("Rgb729.mat");
    RGB_729 = readtable("rgb_values1.csv");
    RGB_729 = table2array(RGB_729(:,2:4));
    
    if size(RGB729, 1) ~= 729 || size(RGB729, 2) ~= 3 || size(RGB_729, 1) ~= 729 || size(RGB_729, 2) ~= 3
        error('矩阵必须是 729x3 大小');
    end
    
    [~, indices] = ismember(RGB729, RGB_729, 'rows');
    
    if any(indices == 0)
        error('有些 RGB 值在 RGB_729 中没有找到对应的行');
    end
    
    for i = 1:length(RGB_729)
        RGB_729_1(i,:) = RGB_729(indices(i),:);
        XYZ9(i,:) = XYZ10(indices(i),:);
    end
    
    % 设置LUT和采样参数
    cubeLoriginal = 9;
    cubeL_ext = 30;
    [r, g, b] = meshgrid(linspace(0, 255, cubeL_ext));
    rgb = [r(:), g(:), b(:)];
    
    [val, ind] = max(XYZ9);
    XYZw = XYZ9(ind(2), :);
    method = 'linear';  % 使用更高效的线性插值方法
    
    lablut = xyz2lab(XYZ9, 'user', XYZw);
    
    % LUT 自适应采样
    cubeL = cubeLoriginal;
    [P_labs] = lut3d(r(:), g(:), b(:), lablut, method, cubeLoriginal);
    
    save_folder = 'D:\work\VIVOskinExpe\renderCode\calibResults\model_interp';
    if ~exist(save_folder, "dir")
        mkdir(save_folder);
    end
    
    % 保存正向数据 → datai_ipv30_phase2_{1~5}.mat
    save(fullfile(save_folder, strcat('datai_ipv', num2str(cubeL_ext), ...
        '_phase2_', num2str(i_device), '.mat')), ...
        'lablut', 'cubeL', 'XYZw', 'method', 'indices', 'XYZ9', "cubeL_ext");
    
    % 保存逆向数据 → data_ipv30_phase2_{1~5}.mat
    save(fullfile(save_folder, strcat('data_ipv', num2str(cubeL_ext), ...
        '_phase2_', num2str(i_device), '.mat')), ...
        'P_labs', 'rgb', 'cubeL', 'XYZw', 'method', 'indices', 'XYZ9', "cubeL_ext");
end

disp("done");
