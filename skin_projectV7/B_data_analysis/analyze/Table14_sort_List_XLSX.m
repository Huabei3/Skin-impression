close all; % 关闭所有图窗
clc;       % 清空命令窗口
clear;     % 清除工作区所有变量
addpath("utils\")
%%
%-------------i-----------------
nations=["AS","CA","SA","AF"];

% lastParts = {'f04i', 'f05i', 'f06i', ...
% 'm04i', 'm05i', 'm06i'};nation=nations(1);

% lastParts = {'f01i', 'f02i', 'f03i', ...
% 'm01i', 'm02i', 'm03i'};nation=nations(2);

% lastParts = {'f07i', 'f08i', ...
% 'm07i', 'm08i'};nation=nations(3);
% 
% lastParts = {'f09i', 'f10i', ...
% 'm09i', 'm10i'};nation=nations(4);

% lastParts = {'f04i', 'f05i', 'f06i', 'm04i', 'm05i', 'm06i',...
% 'f01i', 'f02i', 'f03i', 'm01i', 'm02i', 'm03i',...
% 'f07i', 'f08i','m07i', 'm08i',...
% 'f09i', 'f10i','m09i', 'm10i'};n_para = 21;iOr='i';
%-------------rs----------------

lastParts = {'f04r', 'f05r', 'f06r', 'm04r', 'm05r', 'm06r',...
'f01r', 'f02r', 'f03r', 'm01r', 'm02r', 'm03r',...
'f07r', 'f08r','m07r', 'm08r',...
'f09r', 'f10r','m09r', 'm10r'};n_para = 14;iOr='r';
iOr=lastParts{1}(end);
Dtype = 'efit_p';
scale_type_origin="unscaled";
attribute_names = ["Preference", "Attractiveness", "Feminine", "Cooperative", ...
    "Youth", "Healthy", "Precise reproduction", "suit the environment or not",...
    "white-skinned", "ruddyadd"];
attribute_names_new = ["Preference", "Attractiveness", "Feminine", "Cooperative", ...
    "Youth", "Healthy", "Fidelity","Harmony", "Fair", "Ruddy"];
obs_types=["non_model"];
% obs_types=["non_model","model_group","model"];
wd65 = [94.811, 100.00, 107.304];

if iOr =='i'
    picnames_groups = ["h3k","h4k","h5k","h6k","hd65","h7k","h8k",...
                    "m3k","m4k","m5k","m6k","md65","m7k","m8k",...
                     "l3k","l4k","l5k","l6k","ld65","l7k","l8k"];
    load('optimizedD\neutral_gray\combi_XYZw_i.mat', 'XYZ_combi',"CCT_combi");
    CT = CCT_combi;
    XYZwpre=XYZ_combi;
elseif iOr=='r'
    picnames_groups = ["rs01","rs02","rs03","rs04","rs05","rs06","rs07", ...
             "rs08","rs09","rs10","rs11","rs12","rs13","rs14"];
    picnames_groups1=["1负一楼商场" ,"2负一楼vivo" ,"3下沉广场", "4学校饭堂" ,"5学校小卖部",...
    "6学校星巴克", "7草地顺光" ,"8草地侧光", "9草地逆光", "10阴天场景" ,...
    "11夕阳草地逆光", "12夕阳草地侧光", "13夜景小卖部门口", "14 极夜小卖部对面"];

end
load(fullfile("documents",iOr,"render_data.mat"),"render_map");
Keys = keys(render_map);

for i_obs=1:length(obs_types)
    obs_type=obs_types(i_obs);
    % 定义保存的汇总 Excel 文件名
    outputFolder=fullfile( "AnalyseResults_p",Dtype,scale_type_origin,"sum_list");
    if ~exist(outputFolder,"dir")
        mkdir(outputFolder);
    end
    summary_filename = fullfile( outputFolder, ...
        strcat('characteristic_para_',iOr,'_',obs_type,'_pos_rate.xlsx'));  
    if exist(summary_filename, 'file')
        delete(summary_filename);
    end

    summary_filename1 = fullfile( outputFolder, ...
    strcat('average_',iOr,'.xlsx'));    
    if exist(summary_filename1, 'file')
        delete(summary_filename1);
    end
    
    % 遍历每个 lastPart
    for lastPartIdx = 1:length(lastParts)
        lastPart = lastParts{lastPartIdx};
        if strcmp(lastPart(end),"i")||contains(lastPart,"add")
            n_para=21;
        elseif strcmp(lastPart(end),"r")
            n_para=14;
        end
        % 定义保存的 Excel 文件名
        output_folder=fullfile("sum_list", Dtype,obs_type);
        if ~exist(output_folder,"dir")
            mkdir(output_folder);
        end
        output_filename = fullfile(output_folder, 'ellip_list_all1.xlsx');
        % 如果文件已存在，删除它们以确保新数据写入
        if exist(output_filename, 'file')
            delete(output_filename);
        end
    
        
        % 初始化汇总数据
        concatenated_table = table();
        concatenated_table1 = table();
        
        % 遍历所有 attribute
        for attribute = [1, 2, 3, 4, 5, 6,7, 8, 9, 10]
            attribute_serial = strcat(sprintf("%02d", attribute), attribute_names_new(attribute));
            source_file = fullfile('AnalyseResults_p', Dtype,scale_type_origin, lastPart, obs_type, ...
                attribute_serial, 'ellipPara', 'fitRes.mat');

            par_all=[];
            if exist(source_file, 'file') % 新增 source_file4 的加载
                load(source_file,"parNr_all","par_all","picname_check");
            else                
                par_all(1:n_para,1:6)=NaN;
                parNr_all(1:n_para,1:7)=NaN;
            end
    
            slashes = strfind(source_file, '\');
            
            save_folder = fullfile("AnalyseResults_p", Dtype, scale_type_origin,lastPart,"all", attribute_serial, "list");
            if ~exist(save_folder, "dir")
                mkdir(save_folder);
            end
            
            model = lastPart(1:end-1);
            
            [lastPart1, model1] = gen_lastPart1(lastPart);
            lastPart_new = gen_lastPart_new(lastPart1);
            
            average_file = fullfile("aveSkin", strrep(lastPart_new,"add",""), ...
                "autoNhand_scaleoverLUT.mat");
            average = load(average_file);
            average_bf = average.average_lab_all(:, 1:3);
            %late CAT
            XYZ_bf=lab2xyz2(average_bf,'d65_64');
            for i_para=1:n_para
                curr_cell=render_map(strcat(lastPart,picnames_groups(i_para)));
                CT(i_para,1) =curr_cell{1,8};
                XYZwpre(i_para,:)=curr_cell{1,9};

                D_pre(i_para,1)= calculateD(CT(i_para,1), 0, "efit_p");
                XYZt(i_para,:) = CAT16_D(XYZ_bf(i_para,:), ...
                    XYZwpre(i_para,:), wd65, D_pre(i_para,1));                
            end
            average = xyz2lab(XYZt, 'd65_64');
            list = zeros(n_para, 9); % 分别是 L、a、b、C、h、A、A/B、theta、coefficients
            L = average(:, 1);

            L = [L; nan(size(list,1)-size(L,1),1)];
            par_all = [par_all; nan(size(list,1)-size(par_all,1), size(par_all,2))];

            list(:, 1) = L;
            par_all=[par_all;...
                        nan(size(list,1)-size(par_all,1),size(par_all,2))];
            list(:, 2:3) = par_all(:, 4:5);
            list(:, 4) = sqrt(par_all(:, 4).^2 + par_all(:, 5).^2);
            list(:, 5) = atan2d_360(par_all(:, 5), par_all(:, 4));
            if lastPartIdx>=17
                disp("d")
            end
            y_target=0.5;
            denominator=(log((1/y_target-1)./par_all(:,6)).^2);
            lambda00 = par_all(:, 1)./denominator;
            lambda01 = par_all(:, 3)./denominator / 2;
            lambda10 = par_all(:, 3) ./denominator/ 2;
            lambda11 = par_all(:, 2)./denominator;
            theta = 0.5 * atan2d_360(2 * lambda01, (lambda00 - lambda11));
    
            
            A = lambda00 .* cosd(theta).^2 - lambda01 .* sind(2 * theta) + lambda11 .* sind(theta).^2;
            B = lambda00 .* sind(theta).^2 + lambda01 .* sind(2 * theta) + lambda11 .* cosd(theta).^2;
            aabb(:, 1) = sqrt(1 ./ A);
            aabb(:, 2) = sqrt(1 ./ B);
    
            for i_para=1:size(aabb,1)
                if aabb(i_para, 1) < aabb(i_para, 2)
                    temp = aabb(i_para, 1);
                    aabb(i_para, 1) = aabb(i_para, 2);
                    aabb(i_para, 2) = temp;
                    % 调整 theta
                    theta(i_para,:) = theta(i_para,:) + 90;
                    theta(i_para,:)=convertAngleTo90Interval(theta(i_para,:));
                end
            end
            
            
            list(:, 6) = aabb(:, 1);
            list(:, 7) = aabb(:, 1) ./ aabb(:, 2);
            list(:, 8) = theta;  
            parNr_all=[parNr_all;...
                nan(size(list,1)-size(parNr_all,1),size(parNr_all,2))];
            list(:, 9) = parNr_all(:, end);
            if attribute==7
                obs_type_used="model_group";
            else
                obs_type_used=obs_type;
            end
            labNscore_folder = fullfile('AnalyseResults_p', Dtype,scale_type_origin, lastPart, obs_type_used, ...
                attribute_serial, 'labNscore');
            for i_para=1:n_para
                curr_cell=render_map(strcat(lastPart,picnames_groups(i_para)));
                list(i_para, 10) =curr_cell{1,8};
                list(i_para, 11) =curr_cell{1,10};
                labNscore_file=fullfile(labNscore_folder, ...
                    strcat("labNscore_group",strcat(lastPart,picnames_groups(i_para)),".mat"));
                
                if exist(labNscore_file,"file")
                    clear("p_group","lab_group")
                    load(labNscore_file);    
                    p_ratio=sum(p_group>0.5)./length(p_group);
                    list(i_para, 12) =p_ratio;
                else
                    list(i_para, 12) =nan;
                end

            end
            % 创建一个 cell 数组来存储 picname_group
            if iOr=='i'
                picname_group = cell(n_para, 1);
                for i_para = 1:n_para
                    if i_para<=n_para
                        picname_group{i_para} = strcat(lastPart,picnames_groups(i_para));
                    else
                        picname_group{i_para}="";
                    end
                end
            else
                picname_group=picnames_groups1';
            end
            
            % 将 list 转换为 table
            list_table = array2table(list, 'VariableNames', ...
                {'L', 'a', 'b', 'C', 'h', 'A', 'A_over_B', 'theta', 'coefficients','CCT','E','pos_point_rate'});
            
            average(:, 4) = sqrt(average(:, 2).^2 + average(:, 3).^2);
            average(:, 5) = atan2d_360(average(:, 3), average(:, 2));
            list_table1 = array2table(average, 'VariableNames', ...
                {'L', 'a', 'b', 'C', 'h'});
            % 将 picname_group 添加到 table 中
            list_table.picname_group = picname_group ;
            list_table1.picname_group = picname_group ;
            
            % 添加一列 attribute
            list_table.attribute = repmat(attribute_names_new(attribute), height(list_table), 1);
            list_table1.attribute = repmat(attribute_names_new(attribute), height(list_table1), 1);
    
            % list_table(:, 'A') = [];
            % list_table(:,'A_over_B') = [];
            % list_table(:,'theta') = [];
            % list_table(:,'coefficients') = [];
    
    
            % 保存包含 theta 的文件
            writetable(list_table, output_filename, 'Sheet', gen_attribute_new(attribute_serial) );
            
    
            
            % 将当前 attribute 的 table 纵向拼接到汇总 table 中
            concatenated_table = [concatenated_table; list_table];
            concatenated_table1 = [concatenated_table1; list_table1];
        end
        
        % 将汇总 table 写入汇总 Excel 文件
        writetable(concatenated_table, summary_filename, 'Sheet', gen_lastPart_new(lastPart));
        writetable(concatenated_table1, summary_filename1, 'Sheet', gen_lastPart_new(lastPart));
    end
    mean_list(summary_filename,n_para);
    if i_obs==1
        mean_list(summary_filename1,n_para);
    end
    disp('所有 lastPart 的结果已写入汇总 Excel 文件。');
end
%%

% %-------------i-----------------
% nations=["AS","CA","SA","AF"];
% 
% % lastParts = {'f04i', 'f05i', 'f06i', ...
% % 'm04i', 'm05i', 'm06i'};nation=nations(1);
% 
% % lastParts = {'f01i', 'f02i', 'f03i', ...
% % 'm01i', 'm02i', 'm03i'};nation=nations(2);
% 
% % lastParts = {'f07i', 'f08i', ...
% % 'm07i', 'm08i'};nation=nations(3);
% % 
% % lastParts = {'f09i', 'f10i', ...
% % 'm09i', 'm10i'};nation=nations(4);
% 
% lastParts = {'f04i', 'f05i', 'f06i', 'm04i', 'm05i', 'm06i',...
% 'f01i', 'f02i', 'f03i', 'm01i', 'm02i', 'm03i',...
% 'f07i', 'f08i','m07i', 'm08i',...
% 'f09i', 'f10i','m09i', 'm10i'};n_para = 21;iOr='i';
% %-------------rs----------------
% 
% % lastParts = {'f04r', 'f05r', 'f06r', 'm04r', 'm05r', 'm06r',...
% % 'f01r', 'f02r', 'f03r', 'm01r', 'm02r', 'm03r',...
% % 'f07r', 'f08r','m07r', 'm08r',...
% % 'f09r', 'f10r','m09r', 'm10r'};n_para = 14;iOr='r';
% iOr=lastParts{1}(end);
% Dtype = 'efit_p';
% scale_type_origin="unscaled";
% attribute_names = ["Preference", "Attractiveness", "Feminine", "Cooperative", ...
%     "Youth", "Healthy", "Precise reproduction", "suit the environment or not",...
%     "white-skinned", "ruddyadd"];
% attribute_names_new = ["Preference", "Attractiveness", "Feminine", "Cooperative", ...
%     "Youth", "Healthy", "Fidelity","Harmony", "Fair", "Ruddy"];
% obs_types=["non_model"];
% % obs_types=["non_model","model_group","model"];
% wd65 = [94.811, 100.00, 107.304];
% 
% if iOr =='i'
%     picnames_groups = ["h3k","h4k","h5k","h6k","hd65","h7k","h8k",...
%                     "m3k","m4k","m5k","m6k","md65","m7k","m8k",...
%                      "l3k","l4k","l5k","l6k","ld65","l7k","l8k"];
%     load('optimizedD\neutral_gray\combi_XYZw_i.mat', 'XYZ_combi',"CCT_combi");
%     CT = CCT_combi;
%     XYZwpre=XYZ_combi;
% elseif iOr=='r'
%     picnames_groups = ["rs01","rs02","rs03","rs04","rs05","rs06","rs07", ...
%              "rs08","rs09","rs10","rs11","rs12","rs13","rs14"];
%     picnames_groups1=["1负一楼商场" ,"2负一楼vivo" ,"3下沉广场", "4学校饭堂" ,"5学校小卖部",...
%     "6学校星巴克", "7草地顺光" ,"8草地侧光", "9草地逆光", "10阴天场景" ,...
%     "11夕阳草地逆光", "12夕阳草地侧光", "13夜景小卖部门口", "14 极夜小卖部对面"];
% 
% end
% load(fullfile("documents",iOr,"render_data.mat"),"render_map");
% Keys = keys(render_map);
% 
% for i_obs=1:length(obs_types)
%     obs_type=obs_types(i_obs);
%     % 定义保存的汇总 Excel 文件名
%     outputFolder=fullfile( "AnalyseResults_p",Dtype,scale_type_origin,"sum_list");
%     if ~exist(outputFolder,"dir")
%         mkdir(outputFolder);
%     end
%     summary_filename = fullfile( outputFolder, ...
%         strcat('characteristic_para_',iOr,'_',obs_type,'.xlsx'));  
%     if exist(summary_filename, 'file')
%         delete(summary_filename);
%     end
% 
%     summary_filename1 = fullfile( outputFolder, ...
%     strcat('average_',iOr,'.xlsx'));    
%     if exist(summary_filename1, 'file')
%         delete(summary_filename1);
%     end
% 
%     % 遍历每个 lastPart
%     for lastPartIdx = 1:length(lastParts)
%         lastPart = lastParts{lastPartIdx};
%         if strcmp(lastPart(end),"i")||contains(lastPart,"add")
%             n_para=21;
%         elseif strcmp(lastPart(end),"r")
%             n_para=14;
%         end
%         % 定义保存的 Excel 文件名
%         output_folder=fullfile("sum_list", Dtype,obs_type);
%         if ~exist(output_folder,"dir")
%             mkdir(output_folder);
%         end
%         output_filename = fullfile(output_folder, 'ellip_list_all.xlsx');
%         % 如果文件已存在，删除它们以确保新数据写入
%         if exist(output_filename, 'file')
%             delete(output_filename);
%         end
% 
% 
%         % 初始化汇总数据
%         concatenated_table = table();
%         concatenated_table1 = table();
% 
%         % 遍历所有 attribute
%         for attribute = [1, 2, 3, 4, 5, 6,7, 8, 9, 10]
%             attribute_serial = strcat(sprintf("%02d", attribute), attribute_names_new(attribute));
%             source_file = fullfile('AnalyseResults_p', Dtype,scale_type_origin, lastPart, obs_type, ...
%                 attribute_serial, 'ellipPara', 'fitRes.mat');
%             par_all=[];
%             if exist(source_file, 'file') % 新增 source_file4 的加载
%                 load(source_file,"parNr_all","par_all","picname_check");
%             else                
%                 par_all(1:n_para,1:6)=NaN;
%                 parNr_all(1:n_para,1:7)=NaN;
%             end
% 
%             slashes = strfind(source_file, '\');
% 
%             save_folder = fullfile("AnalyseResults_p", Dtype, scale_type_origin,lastPart,"all", attribute_serial, "list");
%             if ~exist(save_folder, "dir")
%                 mkdir(save_folder);
%             end
% 
%             model = lastPart(1:end-1);
% 
%             [lastPart1, model1] = gen_lastPart1(lastPart);
%             lastPart_new = gen_lastPart_new(lastPart1);
% 
%             average_file = fullfile("aveSkin", strrep(lastPart_new,"add",""), ...
%                 "autoNhand_scaleoverLUT.mat");
%             average = load(average_file);
%             average_bf = average.average_lab_all(:, 1:3);
%             %late CAT
%             XYZ_bf=lab2xyz2(average_bf,'d65_64');
%             for i_para=1:length(picname_check)
%                 curr_cell=render_map(picname_check{i_para, 1});
%                 CT(i_para,1) =curr_cell{1,8};
%                 XYZwpre(i_para,:)=curr_cell{1,9};
% 
%                 D_pre(i_para,1)= calculateD(CT(i_para,1), 0, "efit_p");
%                 XYZt(i_para,:) = CAT16_D(XYZ_bf(i_para,:), ...
%                     XYZwpre(i_para,:), wd65, D_pre(i_para,1));                
%             end
%             average = xyz2lab(XYZt, 'd65_64');
%             list = zeros(n_para, 9); % 分别是 L、a、b、C、h、A、A/B、theta、coefficients
%             L = average(:, 1);
% 
%             list(:, 1) = L;
%             par_all=[par_all;...
%                         nan(size(list,1)-size(par_all,1),size(par_all,2))];
%             list(:, 2:3) = par_all(:, 4:5);
%             list(:, 4) = sqrt(par_all(:, 4).^2 + par_all(:, 5).^2);
%             list(:, 5) = atan2d_360(par_all(:, 5), par_all(:, 4));
% 
%             y_target=0.5;
%             denominator=(log((1/y_target-1)./par_all(:,6)).^2);
%             lambda00 = par_all(:, 1)./denominator;
%             lambda01 = par_all(:, 3)./denominator / 2;
%             lambda10 = par_all(:, 3) ./denominator/ 2;
%             lambda11 = par_all(:, 2)./denominator;
%             theta = 0.5 * atan2d_360(2 * lambda01, (lambda00 - lambda11));
% 
% 
%             A = lambda00 .* cosd(theta).^2 - lambda01 .* sind(2 * theta) + lambda11 .* sind(theta).^2;
%             B = lambda00 .* sind(theta).^2 + lambda01 .* sind(2 * theta) + lambda11 .* cosd(theta).^2;
%             aabb(:, 1) = sqrt(1 ./ A);
%             aabb(:, 2) = sqrt(1 ./ B);
% 
%             for i_para=1:size(aabb,1)
%                 if aabb(i_para, 1) < aabb(i_para, 2)
%                     temp = aabb(i_para, 1);
%                     aabb(i_para, 1) = aabb(i_para, 2);
%                     aabb(i_para, 2) = temp;
%                     % 调整 theta
%                     theta(i_para,:) = theta(i_para,:) + 90;
%                     theta(i_para,:)=convertAngleTo90Interval(theta(i_para,:));
%                 end
%             end
% 
% 
%             list(:, 6) = aabb(:, 1);
%             list(:, 7) = aabb(:, 1) ./ aabb(:, 2);
%             list(:, 8) = theta;  
%             parNr_all=[parNr_all;...
%                 nan(size(list,1)-size(parNr_all,1),size(parNr_all,2))];
%             list(:, 9) = parNr_all(:, end);
%             for i_para=1:length(picname_check)
%                 curr_cell=render_map(picname_check{i_para, 1});
%                 list(i_para, 10) =curr_cell{1,8};
%                 list(i_para, 11) =curr_cell{1,10};
%             end
%             % 创建一个 cell 数组来存储 picname_group
%             if iOr=='i'
%                 picname_group = cell(n_para, 1);
%                 for i_para = 1:n_para
%                     if i_para<=size(picname_check,1)
%                         picname_group{i_para} = picname_check{i_para, 1};
%                     else
%                         picname_group{i_para}="";
%                     end
%                 end
%             else
%                 picname_group=picnames_groups1';
%             end
% 
%             % 将 list 转换为 table
%             list_table = array2table(list, 'VariableNames', ...
%                 {'L', 'a', 'b', 'C', 'h', 'A', 'A_over_B', 'theta', 'coefficients','CCT','E'});
% 
%             average(:, 4) = sqrt(average(:, 2).^2 + average(:, 3).^2);
%             average(:, 5) = atan2d_360(average(:, 3), average(:, 2));
%             list_table1 = array2table(average, 'VariableNames', ...
%                 {'L', 'a', 'b', 'C', 'h'});
%             % 将 picname_group 添加到 table 中
%             list_table.picname_group = picname_group ;
%             list_table1.picname_group = picname_group ;
% 
%             % 添加一列 attribute
%             list_table.attribute = repmat(attribute_names_new(attribute), height(list_table), 1);
%             list_table1.attribute = repmat(attribute_names_new(attribute), height(list_table1), 1);
% 
%             % list_table(:, 'A') = [];
%             % list_table(:,'A_over_B') = [];
%             % list_table(:,'theta') = [];
%             % list_table(:,'coefficients') = [];
% 
% 
%             % 保存包含 theta 的文件
%             writetable(list_table, output_filename, 'Sheet', gen_attribute_new(attribute_serial) );
% 
% 
% 
%             % 将当前 attribute 的 table 纵向拼接到汇总 table 中
%             concatenated_table = [concatenated_table; list_table];
%             concatenated_table1 = [concatenated_table1; list_table1];
%         end
% 
%         % 将汇总 table 写入汇总 Excel 文件
%         writetable(concatenated_table, summary_filename, 'Sheet', gen_lastPart_new(lastPart));
%         writetable(concatenated_table1, summary_filename1, 'Sheet', gen_lastPart_new(lastPart));
%     end
%     mean_list(summary_filename,n_para);
%     if i_obs==1
%         mean_list(summary_filename1,n_para);
%     end
%     disp('所有 lastPart 的结果已写入汇总 Excel 文件。');
% end



%%
function degree = atan2d_360(y, x)
    degree = atan2d(y, x);
    if degree < 0
        degree = degree + 360;
    end
end


function angle = convertAngleTo90Interval(angle)
    % 将角度转换到 [-180, 180] 区间内
    angle = mod(angle, 360);
    if angle > 180
        angle = angle - 360;
    end
    
    % 将角度转换到 [-90, 90] 区间内
    if angle > 90
        angle = angle - 180;
    elseif angle < -90
        angle = angle + 180;
    end
end





