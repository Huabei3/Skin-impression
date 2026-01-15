% rehash toolboxcache % 解决无法访问以前可以访问的文件，重新处理工具箱缓存
close all; % 关闭所有图窗
clc;       % 清空命令窗口
clear;     % 清除工作区所有变量
addpath("utils\")
%% 生成目录

lastParts = {'f04i', 'f05i', 'f06i', 'm04i', 'm05i', 'm06i',...
'f01i', 'f02i', 'f03i', 'm01i', 'm02i', 'm03i',...
'f07i', 'f08i','m07i', 'm08i',...
'f09i', 'f10i','m09i', 'm10i'};iOr='i';n_para=21;

% lastParts = {'f04r', 'f05r', 'f06r', 'm04r', 'm05r', 'm06r',...
% 'f01r', 'f02r', 'f03r', 'm01r', 'm02r', 'm03r',...
% 'f07r', 'f08r','m07r', 'm08r',...
% 'f09r', 'f10r','m09r', 'm10r'};iOr='r';n_para=14;

% Dtype='noCAT';
% Dtype='efit_p_free';
Dtype='efit_p';
scale_type_origin="unscaled";
MCDM_global=zeros(20,10,n_para,20);
%%
for i_lastPart = 1:length(lastParts)
    lastPart = lastParts{i_lastPart};
    %--------non-model-group-------------
    % source_folder = fullfile('D:\work\VIVOskinExpe\analyze\expRes\renamed', ...
    %     lastPart,'non_model'); 
    % group_type=1;
    % 
    %--------model-group-------------
    source_folder =  fullfile('D:\work\VIVOskinExpe\analyze\expRes\renamed', ...
        lastPart,'model_group');
    group_type=2;
    %--------model-------------
    % source_folder =  fullfile('D:\work\VIVOskinExpe\analyze\expRes\renamed', ...
    %     lastPart,'model');    
    % group_type=3;
    % %--------model-------------
    % source_folder = 'D:\work\VIVOskinExpe\analyze\expRes\female41i\all'; 
    % group_type=4;
    %--------all_ruddy_normal-------------
    % source_folder = 'D:\work\VIVOskinExpe\analyze\expRes\female78i\all_ruddy_normal'; 
    % group_type=5;
    %------------------------
    
    

    
    source_folder1 = char(strrep(source_folder,"renamed\",""));
    slashes = strfind(source_folder1, '\');
    obs_type=source_folder1(slashes(end) + 1:end);
    model=lastPart(1:end-1);
    nations=["AS","CA","SA","AF"];
    if ismember(model,["f04", "f05", "f06","m04", "m05", "m06"])
        nation=nations(1);
    elseif ismember(model,["f01", "f02", "f03","m01", "m02", "m03"])
        nation=nations(2);
    elseif ismember(model,["f07", "f08","m07", "m08"])
        nation=nations(3);
    elseif ismember(model,["f09", "f10", "m09", "m10"])
        nation=nations(4);
    end

    if strcmp(nation,"AS")
        attributes = [1, 2, 3, 4, 5, 6, 7,8, 9,10];
    elseif strcmp(nation,"CA")
        attributes = [1, 3, 5, 6, 7,8, 9,10];
    else
        attributes = [1, 3, 5, 6,7, 8];
    end
    if ~strcmp(nation,"AS")&&strcmp(lastPart(1),'m')
        attributes(attributes==3)=[];
    end
    if strcmp(obs_type,"non_model")
        attributes(attributes==7)=[];
    end
    % attributes = [1];
    
    % 定义所有需要处理的 attribute
    attribute_names_new = ["Preference", "Attractiveness", "Feminine", "Cooperative", ...
        "Youth", "Healthy", "Fidelity","Harmony", "Fair", "Ruddy"];
    
    [lastPart1]= gen_lastPart1(lastPart);
    
    average_file=fullfile("aveSkin",strrep(lastPart1,"add",""),"autoNhand_scaleoverLUT.mat");
    average=load(average_file);
    average=average.average_lab_all(:,1:3);
    
    % 循环处理每个 attribute
    startTime = datetime('now'); 
    for attribute = attributes
        % if attribute==1
        %     continue
        % end
        fprintf('Processing savesavttribute: %d\n', attribute);
        
        % 生成 attribute_serial
        attribute_serial = strcat(sprintf("%02d", attribute), attribute_names_new(attribute));
        
       
        % 获取所有格式为 obs%02d 的子文件夹
    
        dir_res = findSpecificFiles(source_folder, attribute);
        if isempty(dir_res)
            continue
        end
        
        if strcmp(Dtype,"efit_p_free")
            save_folder=fullfile('AnalyseResults_p_free',Dtype,scale_type_origin);
        elseif strcmp(Dtype,"efit_p")
            save_folder=fullfile('AnalyseResults_p',Dtype,scale_type_origin);
        end
    
        % 定义输出目录
        
        if group_type==1        
            output_folder = fullfile(save_folder, strrep(lastPart,"add",""), ...
            'non_model', attribute_serial);        
        elseif group_type==2
            output_folder = fullfile(save_folder, strrep(lastPart,"add",""), ...
            "model_group" ,attribute_serial);
        elseif group_type==3
            output_folder = fullfile(save_folder, strrep(lastPart,"add",""), ...
            "model" ,attribute_serial);
        elseif group_type==4
            output_folder = fullfile(save_folder, strrep(lastPart,"add",""), ...
            "all" ,attribute_serial);
        end
    
    
        if ~exist(output_folder, 'dir')
            mkdir(output_folder);
        end
    
        % 处理数据并保存
        [MCDM]=process_data_MCDM(dir_res, output_folder, strrep(lastPart,"add",""),Dtype);

        nanPadding = NaN(size(MCDM, 1), 20-size(MCDM, 2));        
        MCDM_expanded = [MCDM, nanPadding];
        nanPadding = NaN(size(MCDM_global, 3)-size(MCDM_expanded, 1), size(MCDM_expanded, 2));  
        MCDM_expanded = [MCDM_expanded; nanPadding];
        MCDM_global(i_lastPart,attribute,:,:)=MCDM_expanded;
    
    end
    disp("d")

end
%%
MCDM_global(MCDM_global == 0) = NaN;
MCDM_global_mean=mean(mean(mean(mean(MCDM_global,"omitnan"),"omitnan"),"omitnan"),"omitnan");
output_Folder=fullfile(save_folder,"sum_list","MCDM",obs_type,iOr);
if ~exist(output_Folder,"dir")
    mkdir(output_Folder);
end
save(fullfile(output_Folder,"MCDMdata.mat"),"MCDM_global","MCDM_global_mean");
%%
lastParts = {'f04r', 'f05r', 'f06r', 'm04r', 'm05r', 'm06r',...
'f01r', 'f02r', 'f03r', 'm01r', 'm02r', 'm03r',...
'f07r', 'f08r','m07r', 'm08r',...
'f09r', 'f10r','m09r', 'm10r'};iOr='r';n_para=14;

nation_indices = cell(5, 1); % 5个人种（包括"all"）
% AS (Asian): f04i, f05i, f06i, m04i, m05i, m06i (索引1-6)
nation_indices{1} = 1:6;
% CA (Caucasian): f01i, f02i, f03i, m01i, m02i, m03i (索引7-12)  
nation_indices{2} = 7:12;
% SA (South Asian): f07i, f08i, m07i, m08i (索引13-16)
nation_indices{3} = 13:16;
% AF (African): f09i, f10i, m09i, m10i (索引17-20)
nation_indices{4} = 17:20;
% all: 所有索引 (索引1-20)
nation_indices{5} = 1:20;


nations=["Asian","Caucasian","South Aisan","African"];
if strcmp(Dtype,"efit_p_free")
    AnalyseResults_folder="AnalyseResults_p_free";
elseif strcmp(Dtype,"efit_p")
    AnalyseResults_folder="AnalyseResults_p";
end
MCDM_folder=fullfile(AnalyseResults_folder,Dtype,scale_type_origin,"sum_list\MCDM\non_model",'i');
load(fullfile(MCDM_folder,"MCDMdata.mat"),"MCDM_global");
MCDM_global_1=MCDM_global;
MCDM_folder=fullfile(AnalyseResults_folder,Dtype,scale_type_origin,"sum_list\MCDM\non_model",'r');
load(fullfile(MCDM_folder,"MCDMdata.mat"),"MCDM_global");
MCDM_global_2=MCDM_global;
MCDM_folder=fullfile(AnalyseResults_folder,Dtype,scale_type_origin,"sum_list\MCDM\model_group",'i');
load(fullfile(MCDM_folder,"MCDMdata.mat"),"MCDM_global");
MCDM_global_3=MCDM_global;
MCDM_folder=fullfile(AnalyseResults_folder,Dtype,scale_type_origin,"sum_list\MCDM\model_group",'r');
load(fullfile(MCDM_folder,"MCDMdata.mat"),"MCDM_global");
MCDM_global_4=MCDM_global;

for i_lastPart = 1:length(lastParts)
    for attribute = 1:10
        if attribute==7
            MCDM_curr=[squeeze(MCDM_global_3(i_lastPart,attribute,:,:));...
                squeeze(MCDM_global_4(i_lastPart,attribute,:,:))];
        else
            MCDM_curr=[squeeze(MCDM_global_1(i_lastPart,attribute,:,:));...
                squeeze(MCDM_global_2(i_lastPart,attribute,:,:))];
        end
        MCDM_global_3(i_lastPart,attribute)=mean(mean(MCDM_curr,"omitnan"),"omitnan");
    end
end
for i_nation=1:size(nation_indices,1)
    for attribute = 1:10
        MCDM_nation(i_nation,attribute)=mean(mean(MCDM_global_3(nation_indices{i_nation},attribute),"omitnan"),"omitnan");
    end
end

% 画图
figure(1);
hold on;
num_attributes = size(MCDM_global_1, 2);
hue_values = linspace(0, 1, num_attributes + 1);
hue_values = hue_values(1:end-1); 
hsv_matrix = [hue_values', 0.8 * ones(num_attributes, 1), 0.8 * ones(num_attributes, 1)];
colors = hsv2rgb(hsv_matrix);

bar_width = 0.8 / size(MCDM_global_1, 2); % 计算每个 bar 的宽度

for attribute = 1:size(MCDM_global_1, 2)
    x = (1:size(nation_indices, 1)) + (attribute - 1) * bar_width - bar_width * (size(MCDM_global_1, 2) - 1) / 2;
    bar(x, MCDM_nation(:, attribute), bar_width, 'FaceColor', colors(attribute, :));
end
ylim([1,3]);
% 设置横坐标
set(gca, 'XTick', 1:size(nation_indices, 1));
set(gca, 'XTickLabel', {'Asian','Caucasian','South Aisan','African', 'All'});


% 添加标题和标签
title('MCDM by Nation and Attribute');
xlabel('Nation');
ylabel('MCDM Value');
if strcmp(Dtype,"efit_p_free")
    ellip_pic_folder="ellip_pic_p_free";
elseif strcmp(Dtype,"efit_p")
    ellip_pic_folder="ellip_pic_p";
end

MCDM_folder=fullfile(ellip_pic_folder,Dtype,"MCDM");
if ~exist(MCDM_folder,"dir")
    mkdir(MCDM_folder)
end
saveas(gcf,fullfile(MCDM_folder,"MCDM.jpg"));
min(min(MCDM_nation)),max(max(MCDM_nation)),nanmean(nanmean(MCDM_nation))

% 画图
nation_indices(5,:)=[];
MCDM_nation(5,:)=[];
figure(2);
hold on;
MCDM_nation(:,7)=[];
num_attributes = size(MCDM_nation, 2);
hue_values = linspace(0, 1, num_attributes + 1);
hue_values = hue_values(1:end-1); 
hsv_matrix = [hue_values', 0.8 * ones(num_attributes, 1), 0.8 * ones(num_attributes, 1)];
colors = hsv2rgb(hsv_matrix);
n_nation=4;
bar_width = 0.8 /num_attributes; % 计算每个 bar 的宽度

for attribute = 1:num_attributes
    x = (1:size(nation_indices, 1)) + (attribute - 1) * bar_width - bar_width * (size(MCDM_global_1, 2) - 1) / 2;
    bar(x, MCDM_nation(:, attribute), bar_width, 'FaceColor', colors(attribute, :));
end
ylim([1,3]);
% 设置横坐标
set(gca, 'XTick', 1:size(nation_indices, 1));
set(gca, 'XTickLabel', {'Asian','Caucasian','South Aisan','African'});
% set(gca, 'XTickLabel', {'Asian','Caucasian','South Aisan','African', 'All'});


% 添加标题和标签
% title('MCDM by Ethnic Groups and Attribute');
% xlabel('Nation');
% ylabel('MCDM Value');
MCDM_folder=fullfile(ellip_pic_folder,Dtype,"MCDM");
if ~exist(MCDM_folder,"dir")
    mkdir(MCDM_folder)
end
saveas(gcf,fullfile(MCDM_folder,"MCDM.jpg"));
statistics_MCDM=[min(min(MCDM_nation)),max(max(MCDM_nation)),nanmean(nanmean(MCDM_nation))]
%% 辅助函数

function [lastPart1]= gen_lastPart1(lastPart)
    lastParts1=["femaleVIVO","maleVIVO"];
    lastParts=["femalevivo","malevivo"];
    lastPart1=lastPart;
    for i=length(lastParts)
        lastPart1=strrep(lastPart1,lastParts(i),lastParts1(i));

    end
end




