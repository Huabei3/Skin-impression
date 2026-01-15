% rehash toolboxcache % 解决无法访问以前可以访问的文件，重新处理工具箱缓存
close all; % 关闭所有图窗
clc;       % 清空命令窗口
clear;     % 清除工作区所有变量
addpath("..\..\utils\")
%%
lastPart='f01i';
iOr=lastPart(end);
attribute_serial="01Preference";
obs_type="non_model";
output_folder=fullfile("..\lab_and_p",lastPart,obs_type,attribute_serial);

outputFolder = fullfile(output_folder, "new",'ellipPara');
if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end

if lastPart(end) == 'i' ||contains(lastPart,"add")
    picnames_groups = ["h3k","h4k","h5k","h6k","hd65","h7k","h8k", ...
                    "m3k","m4k","m5k","m6k","md65","m7k","m8k",...
                     "l3k","l4k","l5k","l6k","ld65","l7k","l8k"];
elseif lastPart(end) == 'r'
    picnames_groups = ["rs01","rs02","rs03","rs04","rs05","rs06","rs07", ...
                 "rs08","rs09","rs10","rs11","rs12","rs13","rs14"];
end
par_all = [];
r_all = [];
parNr_all = [];
for i_group = 1:length(picnames_groups)

    % 加载数据
    dir_labNgroup = dir(fullfile(output_folder, 'labNscore', ...
        strcat('labNscore_group',strrep(lastPart,"add",""), picnames_groups(i_group),'*.mat')));
    if isempty(dir_labNgroup)
        continue
    end
    MSVNlab = load(fullfile(dir_labNgroup(1).folder, dir_labNgroup(1).name));
    picname_check{i_group,1}=strcat(lastPart, picnames_groups(i_group));  
    
    % 复制一份用于修改
    lab_group = MSVNlab.lab_group;
    p_group = MSVNlab.p_group;

    % 初始化 row_delete 和对应的 lab_group 数据
    row_delete = [];
    row_delete_lab_group = [];
    
    while true
        % 拟合椭圆
        [par_mean, r_mean] = calculate_weighted_or_simple_mean( p_group, lab_group);

        mean_cen(1)=mean(lab_group(:,1));
        mean_cen(2:3)=par_mean(1,4:5);

        [par, r, y] = ellipsoidfit_single(lab_group, p_group,mean_cen);

        
        [A, B, ~] = calculate_ellipse_axes_from_par(par);
        if (4*par(1)*par(2)-par(3)^2)>0&&r>=0.75
            break;
        end

        % 找到最大误差的索引
        [~, max_ind] = max(abs(y - p_group));
        
        % 记录原始 lab_group 中的索引
        original_index = find(ismember(lab_group_original, lab_group(max_ind, :), 'rows'));
        
        % 将原始索引加入 row_delete
        row_delete = [row_delete; original_index];
        
        % 将对应的 lab_group 数据加入 row_delete_lab_group
        row_delete_lab_group = [row_delete_lab_group; lab_group_original(original_index, :)];
        
        % 删除异常数据点
        lab_group(max_ind, :) = [];
        p_group(max_ind, :) = [];
        figure('Visible','off');
        plot_contour_with_scatter(par, lab_group, p_group);
    end
    % 存储 row_delete 和对应的 lab_group 数据
    row_delete_all{i_group,1} = {row_delete, row_delete_lab_group};
    
    % 存储拟合结果
    par_all = [par_all; par];
    r_all = [r_all; r];
    parNr_all = [parNr_all; [par, r]];
    

    figure(1);
    plot_contour_with_scatter(par, lab_group, p_group);
    title(strrep(dir_labNgroup(1).name,'labNscore_group',''));
end


% 保存拟合结果
save(fullfile(outputFolder, "fitRes.mat"), ...
    'par_all', 'r_all', 'parNr_all','picname_check');


