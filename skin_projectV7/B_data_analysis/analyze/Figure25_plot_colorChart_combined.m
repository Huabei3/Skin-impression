close all; % 关闭所有图窗
clc;       % 清空命令窗口
clear;     % 清除工作区所有变量
addpath("utils\")
%%
%-------------i-----------------
nations=["AS","CA","SA","AF"];
colors=hsv(4);
% Move figure creation and settings outside the main loops
h1=figure(1);
hold on;
h2=figure(2);
hold on;
lastPart_types=[1,2];
scale_type_origin="unscaled";
for i_lastParts=lastPart_types
    clear("target_indices");
    if i_lastParts==1
        lastParts = {'f04i', 'f05i', 'f06i', 'm04i', 'm05i', 'm06i',...
        'f01i', 'f02i', 'f03i', 'm01i', 'm02i', 'm03i',...
        'f07i', 'f08i','m07i', 'm08i',...
        'f09i', 'f10i','m09i', 'm10i'};n_para = 21;iOr='i';
    else
        %-------------rs----------------
        lastParts = {'f04r', 'f05r', 'f06r', 'm04r', 'm05r', 'm06r',...
        'f01r', 'f02r', 'f03r', 'm01r', 'm02r', 'm03r',...
        'f07r', 'f08r','m07r', 'm08r',...
        'f09r', 'f10r','m09r', 'm10r'};n_para = 14;iOr='r';
    end
    iOr=lastParts{1}(end);
    Dtype = 'efit_p';
    attributes=[1,2,3,4,5,6,7,8,9];
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
        target_indices{1}=5;
        target_indices{2}=12;
        target_indices{3}=19;
        % target_indices{4}=[5,12,19];
        CT = CCT_combi;
        XYZwpre=XYZ_combi;
    elseif iOr=='r'
        picnames_groups = ["rs01","rs02","rs03","rs04","rs05","rs06","rs07", ...
                 "rs08","rs09","rs10","rs11","rs12","rs13","rs14"];
        picnames_groups1=["1负一楼商场" ,"2负一楼vivo" ,"3下沉广场", "4学校饭堂" ,"5学校小卖部",...
        "6学校星巴克", "7草地顺光" ,"8草地侧光", "9草地逆光", "10阴天场景" ,...
        "11夕阳草地逆光", "12夕阳草地侧光", "13夜景小卖部门口", "14 极夜小卖部对面"];
        target_indices{1}=1:14;
    end
    load(fullfile("documents",iOr,"render_data2.mat"),"render_map");
    Keys = keys(render_map);
    datai_file = 'D:\work\VIVOskinExpe\renderCode\calibResults\datai_ipv18_3.mat';
    LUT=load(datai_file);
    XYZw_LUT=LUT.XYZw;
    scale_type="scaled";
    hmls=["H","M","L","all"];
    
    % 预定义颜色和标记样式
    colors = lines(length(attributes)); % 使用内置颜色图
    for i_obs=1:length(obs_types)
        obs_type=obs_types(i_obs);
        
        % 定义保存的汇总 Excel 文件名
        outputFolder=fullfile( "AnalyseResults_p",Dtype,scale_type_origin,"sum_list");
        if ~exist(outputFolder,"dir")
            mkdir(outputFolder);
        end
        
        summary_filename = fullfile( outputFolder, ...
            strcat('characteristic_para_',iOr,'_',obs_type,'.xlsx'));  
        if exist(summary_filename, 'file')
            delete(summary_filename);
        end
        summary_filename1 = fullfile( outputFolder, ...
        strcat('average_',iOr,'.xlsx'));    
        if exist(summary_filename1, 'file')
            delete(summary_filename1);
        end
        % for i_indice=length(target_indices):length(target_indices)
        figure(h1);
        figure(h2);
        for i_indice=1:length(target_indices)
            
            % ⚠️ Move figure settings to be called just once
            figure(h1);
            if iOr=='i'
                title(["All Attributes",hmls(i_indice),"a-b"])
            else
                title(["All Attributes","a-b"])
            end
            grid on;
            axis equal;
            if iOr=="i"
                max_lim_ab=25;
            else
                max_lim_ab=40;
            end
            min_lim_ab=0;
            xticks(min_lim_ab:5:max_lim_ab)
            yticks(min_lim_ab:5:max_lim_ab)
            xlim([min_lim_ab,max_lim_ab])
            ylim([min_lim_ab,max_lim_ab])

            figure(h2);
            if iOr=='i'
                title(["All Attributes",hmls(i_indice),"L-C"])
            else
                title(["All Attributes","L-C"])
            end
            grid on;
            axis equal;
            if iOr=="i"
                max_lim_lc=80;
                min_lim_lc=25;
            else
                max_lim_lc=90;
                min_lim_lc=15;
            end
            xticks(0:5:40)
            yticks(min_lim_lc:5:max_lim_lc)
            xlim([0,40])
            ylim([min_lim_lc,max_lim_lc])
    
            
            % Initialize arrays to hold data for vectorized plotting
            all_a = [];
            all_b = [];
            all_L = [];
            all_C = [];
            all_E = [];
            
            % 遍历所有 attribute
            for attribute = attributes
                attribute_serial = strcat(sprintf("%02d", attribute), attribute_names_new(attribute));
                
                % 遍历每个 lastPart
                for lastPartIdx = 1:length(lastParts)
                    lastPart = lastParts{lastPartIdx};
                    if strcmp(lastPart(end),"i")||contains(lastPart,"add")
                        n_para=21;
                    elseif strcmp(lastPart(end),"r")
                        n_para=14;
                    end
                    if iOr=='r'
                        white_file = fullfile("optimizedD\card_0830",...
                            strcat(lastPart, ".mat"));
                    elseif iOr=='i'
                        white_file = fullfile("optimizedD\whiteSquare\XYZw_white", ...
                        strcat(lastPart, ".mat"));
                    end
                    load(white_file,"XYZw_white");
                    
                    % 定义保存的 Excel 文件名
                    output_folder=fullfile("sum_list", Dtype,obs_type,lastPart);
                    if ~exist(output_folder,"dir")
                        mkdir(output_folder);
                    end
                    output_filename = fullfile(output_folder, 'ellip_list_all.xlsx');
                    % 如果文件已存在，删除它们以确保新数据写入
                    if exist(output_filename, 'file')
                        delete(output_filename);
                    end
                 
                    % 初始化汇总数据
                    concatenated_table = table();
                    concatenated_table1 = table();
                
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
                    
                    save_folder = fullfile("ellip_pic_p", Dtype );
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
                    for i_para=1:length(picnames_groups)
                        curr_struct=render_map(strcat(lastPart,picnames_groups(i_para)));
                        CT(i_para,1) =curr_struct.CCT_val;
                        XYZwpre(i_para,:)=curr_struct.XYZw_pre_val;
        
                        D_pre(i_para,1)= calculateD(CT(i_para,1), 0, "efit_p");
                        XYZt(i_para,:) = CAT16_D(XYZ_bf(i_para,:), ...
                            XYZwpre(i_para,:), wd65, D_pre(i_para,1));                
                    end
                    average = xyz2lab(XYZt, 'd65_64');
                    L = average(:, 1);
                    labCh(:, 1) = L;
                    par_all=[par_all;...
                                nan(size(labCh,1)-size(par_all,1),size(par_all,2))];
                    labCh(:, 2:3) = par_all(:, 4:5);
                    labCh(:, 4) = sqrt(par_all(:, 4).^2 + par_all(:, 5).^2);
                    labCh(:, 5) = atan2d_360(par_all(:, 5), par_all(:, 4));
                    
                    if strcmp(scale_type,"scaled")
                        for i_para=1:length(picnames_groups)
                            xyz_fit(i_para,:)=lab2xyz2(labCh(i_para,1:3),"user",wd65./wd65(2).*XYZw_LUT(2));
                            lab_scaled(i_para,1:3)=xyz2lab(xyz_fit(i_para,:),"user",wd65./wd65(2).*XYZw_white(i_para,2));
                        end
                    else
                        lab_scaled=labCh;
                    end
                    lab_scaled(:,4)=sqrt(lab_scaled(:,2).^2+lab_scaled(:,3).^2)';
                    lab_scaled(:,5)=atan2d(lab_scaled(:,3),lab_scaled(:,2));
                    
                    % ⚠️ Collect data into arrays instead of plotting here
                    for i_para=target_indices{i_indice}    
                        if i_para==13
                            continue
                        end
                        curr_struct=render_map(strcat(lastPart,picnames_groups(i_para)));
                        E =curr_struct.E_val;
                        
                        all_a = [all_a; lab_scaled(i_para,2)];
                        all_b = [all_b; lab_scaled(i_para,3)];
                        all_L = [all_L; lab_scaled(i_para,1)];
                        all_C = [all_C; lab_scaled(i_para,4)];
                        all_E = [all_E; E];
                    end
                end
            end
            
            % ⚠️ Perform vectorized plotting after the loops
            figure(h1);
            % scatter(all_a, all_b, 10, all_E, 'filled');
            scatter(all_a, all_b, 10,colors(i_indice+i_lastParts*3,:) , 'filled');
            
            figure(h2);
            % scatter(all_C, all_L, 10, all_E, 'filled');
            scatter(all_C, all_L, 10, colors(i_indice+i_lastParts*3,:), 'filled');
            
            % ⚠️ Add colorbar and colormap just once
            figure(h1);
            colorbar;
            colormap(h1, 'gray');
            
            figure(h2);
            colorbar;
            colormap(h2, 'gray');

        end

    end
end
figure(h1);
legend('show','Location','bestoutside');
hold off;
if isscalar(lastPart_types)
    output_folder = fullfile(save_folder,"color_chart_combined",iOr,obs_type,"a_b");
else
    output_folder = fullfile(save_folder,"color_chart_combined",obs_type,"a_b");
end
if ~exist(output_folder, "dir")
    mkdir(output_folder);
end
exportgraphics(h1, fullfile(output_folder, ...
    strcat('all_attributes_a_b.jpg')),"resolution",150);
close(h1)

figure(h2);
legend('show','Location','bestoutside');
hold off;
if isscalar(lastPart_types)
    output_folder = fullfile(save_folder,"color_chart_combined",iOr,obs_type,"L_C");
else
    output_folder = fullfile(save_folder,"color_chart_combined",obs_type,"L_C");
end
if ~exist(output_folder, "dir")
    mkdir(output_folder);
end
exportgraphics(h2, fullfile(output_folder, ...
    strcat('all_attributes_L_C.jpg')),"resolution",150);
close(h2)

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
    elseif angle < -90
        angle = angle + 180;
    end
end