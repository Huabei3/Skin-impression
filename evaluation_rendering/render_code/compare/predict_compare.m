clc;clear;close all;
addpath("..\utils\");
%%
% sources=["david","cherry","summer","OPPO","peggy"];
sources=["peggy"];
%% 评价summer的
if ismember("summer",sources)
clear("de_david","de_cherry","de_summer","de_OPPO","de_peggy")
clear("de_david1","de_cherry1","de_summer1","de_OPPO1","de_peggy1")
cherry_fitRes_file=fullfile("D:\work\ZJU_entire_skin\Cherry\software\skin colour\数据分析\分析过程\res\nation\weighted\fitRes\ellipPara.mat");
cherry_fitRes_data=load(cherry_fitRes_file);

summer_table_file=fullfile("D:\work\ZJU_entire_skin\Summer\Data\Haisi skin\3. Test experiment\4. Model\res\resTable\Summer_table.mat");
summer_table_data=load(summer_table_file);
summer_table=summer_table_data.fit_table;
cct_values = cell2mat(summer_table.CCT);  
idx_cct = cct_values == 6500;
if iscell(summer_table.scene)
    scene_chars = cellfun(@char, summer_table.scene, 'UniformOutput', false);
    idx_scene = cellfun(@(x) contains(x, "cat"), scene_chars);
else
    % 若scene是字符串/字符数组
    idx_scene = contains(summer_table.scene, "cat");
end
idx = idx_cct & idx_scene;
summer_table = summer_table(idx, :);

david_table_file=fullfile("D:\work\ZJU_entire_skin\David\Naturalness model\Jason's final project\data analysis\res\separate_skin_methods\resTable\quality\David_table.mat");
david_table_data=load(david_table_file);
david_table=david_table_data.fit_table;

% David_fitRes_folder=fullfile("D:\work\ZJU_entire_skin\David\Naturalness model\Jason's final project\data analysis\res\separate_skin_methods\quality\fitRes\ellipsoidfit4");
David_fitRes_folder=fullfile("D:\work\ZJU_entire_skin\David\Naturalness model\Jason's final project\data analysis\res\CATed\fitRes");

David_fitRes_file=fullfile(David_fitRes_folder,"fitRes.mat");
David_fitRes_data=load(David_fitRes_file);



output_folder=fullfile("res","pic","on_summer");
if ~exist(output_folder,"dir")
    mkdir(output_folder);
end

%OPPO

for i_img=1:size(summer_table,1)

    source_name=summer_table.model_ethnicity{i_img};
    if strcmp(summer_table.model_ethnicity{i_img},"Oriental")
        i_david=4;
        i_cherry=3;
    elseif strcmp(summer_table.model_ethnicity{i_img},"Caucasian")
        i_david=5;
        i_cherry=4;
    elseif strcmp(summer_table.model_ethnicity{i_img},"African")
        i_david=0;
        i_cherry=1;
    elseif strcmp(summer_table.model_ethnicity{i_img},"South Asian")
        i_david=0;
        i_cherry=2;
    end

    %david
    if i_david>0
        par_david=David_fitRes_data.par(i_david,:);
        cen_david=par_david(1,5:7);        
    else
        par_david=nan(1,8);
        cen_david=nan(1,3);
    end

    %summer
    par_summer=summer_table.par{i_img};
    cen_summer=summer_table.lab_center{i_img};
    points_summer=summer_table.lab_values{i_img};
    scores_summer=summer_table.opinion_scores{i_img};
    xyz_cen_summer=lab2xyz(cen_summer,"d65_64");


    y_summer=cal_y(par_summer,points_summer,"ellipsoidfit5");
    [r_summer(i_img,1)] = corr(y_summer(1:17,1), scores_summer(1:17,1), 'Type', 'Pearson'); 
    de_summer(i_img,1)=deltaE2000(cen_summer,cen_summer);

    %david
    lab_cen_david=cen_david;
    xyz_cen_david=lab2xyz2(lab_cen_david,"d65_64");
    xyz_cen_david1=xyz_cen_david./xyz_cen_david(2).*xyz_cen_summer(2);
    lab_cen_david1=xyz2lab(xyz_cen_david1,"d65_64");
    par_david(1,5:7)=lab_cen_david1;
    cen_david=par_david(1,5:7);

    y_david=cal_y(par_david,points_summer,"ellipsoidfit4");
    r_david(i_img,1) = corr(y_david, scores_summer, 'Type', 'Pearson');
    de_david(i_img,1)=deltaE2000(cen_david,cen_summer);
    % de_david1=[cen_david,cen_summer,de_david(i_img,1)];

    %cherry
    par_cherry=cherry_fitRes_data.par_all(i_cherry,:);
    cen_cherry=par_cherry(1,5:7);

    lab_cen_cherry=cen_cherry;
    xyz_cen_cherry=lab2xyz2(lab_cen_cherry,"d65_64");
    xyz_cen_cherry1=xyz_cen_cherry./xyz_cen_cherry(2).*xyz_cen_summer(2);
    lab_cen_cherry1=xyz2lab(xyz_cen_cherry1,"d65_64");
    par_cherry(1,5:7)=lab_cen_cherry1;
    cen_cherry=par_cherry(1,5:7);

    y_cherry=cal_y(par_cherry,points_summer,"ellipsoidfit3_1");
    r_cherry(i_img,1) = corr(y_cherry, scores_summer, 'Type', 'Pearson');
    de_cherry(i_img,1)=deltaE2000(cen_cherry,cen_summer);

    %peggy
    [y_peggy,par_peggy,characteristics(i_img,:)]=predict_my(points_summer(1,1),points_summer,1,"01Preference");
    cen_peggy=[points_summer(1,1),par_peggy(1,4:5)];
    [r_peggy(i_img,1)] = corr(y_peggy, scores_summer, 'Type', 'Pearson');    
    de_peggy(i_img,1)=deltaE2000(cen_peggy,cen_summer);
    par_peggy_all(i_img,:)=par_peggy;

    %OPPO
    lastPart_OPPO="inLab";
    OPPO_folder=fullfile("D:\work\project_code_backup\OPPOskinExpe\analyzeResult_scaled\" + ...
        "AnalyseResults_p\display\rela\efit_p\scene",lastPart_OPPO,"ellipPara_scaled");
    OPPO_data=load(fullfile(OPPO_folder,"fitRes_level.mat"));
    par_OPPO=OPPO_data.par;
    cen_OPPO=par_OPPO(1,5:7);

    lab_cen_OPPO=cen_OPPO;
    xyz_cen_OPPO=lab2xyz2(lab_cen_OPPO,"d65_64");
    xyz_cen_OPPO1=xyz_cen_OPPO./xyz_cen_OPPO(2).*xyz_cen_summer(2);
    lab_cen_OPPO1=xyz2lab(xyz_cen_OPPO1,"d65_64");
    par_OPPO(1,5:7)=lab_cen_OPPO1;
    cen_OPPO=par_OPPO(1,5:7);

    y_OPPO=cal_y(par_OPPO,points_summer,"ellipsoidfit5");
    [r_OPPO(i_img,1)] = corr(y_OPPO, scores_summer, 'Type', 'Pearson'); 
    de_OPPO(i_img,1)=deltaE2000(cen_OPPO,cen_summer);
    de_OPPO1(i_img,:)=[cen_OPPO,cen_summer,de_OPPO(i_img,1)];

    cens(:,:,i_img)=[cen_david;cen_cherry;cen_summer;cen_OPPO;cen_peggy];

    % figure(1);hold on;
    % plot(points_summer(:,2),points_summer(:,3),  'o', 'Color', 'b', 'MarkerSize', 6);
    % plot(cen_peggy(1,2),cen_peggy(1,3),  's', 'Color', 'r','MarkerFaceColor','r', 'MarkerSize', 6);
    % plot(cen_cherry(1,2),cen_cherry(1,3),  'p', 'Color', 'b','MarkerFaceColor','b', 'MarkerSize', 6);
    % plot(cen_summer(1,2),cen_summer(1,3),  '^', 'Color', 'g','MarkerFaceColor','g', 'MarkerSize', 6);    
    % plot(cen_david(1,2),cen_david(1,3),  'p', 'Color', 'r','MarkerFaceColor','r', 'MarkerSize', 6);
    % outputFolder=fullfile(output_folder,"a_b");
    % if ~exist(outputFolder,"dir")
    %     mkdir(outputFolder);
    % end
    % exportgraphics(gcf,fullfile(outputFolder,strcat(source_name,".jpg")));
    % close(gcf)



end
disp("d")
result_summer=[nanmean(de_david),mean(de_cherry),...
    nanmean(de_summer),mean(de_OPPO),mean(de_peggy)]
end
%% 评价cherry的
if ismember("cherry",sources)
clear("de_david","de_cherry","de_summer","de_OPPO","de_peggy")
clear("de_david1","de_cherry1","de_summer1","de_OPPO1","de_peggy1")
dim_idxs_david=[2:17;18:33;34:49];
dim_idxs_cherry=[1:16;33:48;17:32];
summer_ethnicities=["African","Caucasian","Oriental","South Asian"];
order = [1, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, ...
    2, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, ...
    3, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, ...
    4, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 5, 6, 7, 8, 9];
for idx=1:length(order)
    idx_used(idx,1)=find(order==idx);
end

cherry_table_file=fullfile("D:\work\ZJU_entire_skin\Cherry\software\skin colour\数据分析\分析过程\resTable\manual\cherry_ellipse_fits.mat");
cherry_table_data=load(cherry_table_file);
cherry_table=cherry_table_data.fit_table;
idx = strcmp(cherry_table.observer_type, "weighted(o:30,s:30,c:31)");
cherry_table = cherry_table(idx, :);

cherry_fitRes_file=fullfile("D:\work\ZJU_entire_skin\Cherry\software\skin colour\数据分析\分析过程\res\nation\weighted\fitRes\ellipPara.mat");
cherry_fitRes_data=load(cherry_fitRes_file);

summer_table_file=fullfile("D:\work\ZJU_entire_skin\Summer\Data\Haisi skin\3. Test experiment\4. Model\res\resTable\Summer_table.mat");
summer_table_data=load(summer_table_file);
summer_table=summer_table_data.fit_table;

david_fitRes_folder=fullfile("D:\work\ZJU_entire_skin\David\Naturalness model\Jason's final project\data analysis\res\CATed\fitRes");
% david_fitRes_folder="D:\work\ZJU_entire_skin\David\Naturalness model\Jason's final project\data analysis\res\fitRes";
david_fitRes_file=fullfile(david_fitRes_folder,"fitRes.mat");
david_fitRes_data=load(david_fitRes_file);


cct_values = cell2mat(summer_table.CCT);  
idx_cct = cct_values == 6500;
if iscell(summer_table.scene)
    scene_chars = cellfun(@char, summer_table.scene, 'UniformOutput', false);
    idx_scene = cellfun(@(x) contains(x, "cat"), scene_chars);
else
    % 若scene是字符串/字符数组
    idx_scene = contains(summer_table.scene, "cat");
end
idx = idx_cct & idx_scene;
summer_table = summer_table(idx, :);


output_folder=fullfile("res","pic","on_cherry");
if ~exist(output_folder,"dir")
    mkdir(output_folder);
end
for i_img=1:size(cherry_table,1)

    cherry_ethnicity=cherry_table.model_ethnicity{i_img};
    source_name=cherry_table.model_ethnicity{i_img};
    cherry_ethnicity=strrep(cherry_ethnicity,"(YY)","");
    cherry_ethnicity=strrep(cherry_ethnicity,"(YO)","");

    if strcmp(cherry_ethnicity,"African")
        i_cherry=1;
    elseif strcmp(cherry_ethnicity,"South Asian")
        i_cherry=2;
    elseif strcmp(cherry_ethnicity,"Oriental")
        i_cherry=3;
    elseif strcmp(cherry_ethnicity,"Caucasian")
        i_cherry=4;
    end
    %cherry
    par_base=cherry_table.par{i_img};par_base=par_base';
    cen_base=par_base(1,5:7);
    xyz_cen_base=lab2xyz2(cen_base,"d65_64");
    ave_base=cherry_table.average_lab{i_img};
    par_cherry=cherry_fitRes_data.par_all(i_cherry,:);
    cen_cherry=par_cherry(1,5:7);

    lab_cen_cherry=cen_cherry;
    xyz_cen_cherry=lab2xyz2(lab_cen_cherry,"d65_64");
    xyz_cen_cherry1=xyz_cen_cherry./xyz_cen_cherry(2).*xyz_cen_base(2);
    lab_cen_cherry1=xyz2lab(xyz_cen_cherry1,"d65_64");
    par_cherry(1,5:7)=lab_cen_cherry1;
    cen_cherry=par_cherry(1,5:7);

    points_cherry=cherry_table.lab_values{i_img};
    scores_cherry=cherry_table.opinion_scores{i_img};
    points_cherry=points_cherry(idx_used,:);
    scores_cherry=scores_cherry(idx_used,:);
    

    y_cherry=cal_y(par_cherry,points_cherry,"ellipsoidfit3_1");
    r_cherry(i_img,1) = corr(y_cherry, scores_cherry, 'Type', 'Pearson');
    de_cherry(i_img,1)=deltaE2000(cen_cherry,cen_base);
    de_cherry1(i_img,:)=[cen_cherry,cen_base,de_cherry(i_img,1)];


    if strcmp(cherry_ethnicity,"Caucasian")
        par_david=david_fitRes_data.par(5,:);
        cen_david=david_fitRes_data.par(5,5:7);
    elseif strcmp(cherry_ethnicity,"Asian")||strcmp(cherry_ethnicity,"Oriental")
        par_david=david_fitRes_data.par(4,:);
        cen_david=david_fitRes_data.par(4,5:7);
    else
        par_david=nan(1,8);
        cen_david=nan(1,3);
    end
    lab_cen_david=cen_david;
    xyz_cen_david=lab2xyz2(lab_cen_david,"d65_64");
    xyz_cen_david1=xyz_cen_david./xyz_cen_david(2).*xyz_cen_base(2);
    lab_cen_david1=xyz2lab(xyz_cen_david1,"d65_64");
    par_david(1,5:7)=lab_cen_david1;
    cen_david=par_david(1,5:7);

    y_david=cal_y(par_david,points_cherry,"ellipsoidfit4");
    r_david(i_img,1) = corr(y_david(dim_idxs_cherry(1,:),1), scores_cherry(dim_idxs_cherry(1,:),1), 'Type', 'Pearson');
    de_david(i_img,1)=deltaE2000(cen_david,cen_base);
    de_david1(i_img,:)=[cen_david,cen_base,de_david(i_img,1)];

    %summer

    for i_match=1:length(summer_ethnicities)
        if strcmp(cherry_ethnicity,summer_ethnicities(i_match))
            break
        end
    end
    par_summer=summer_table.par{i_match};
    cen_summer=summer_table.lab_center{i_match};

    lab_cen_summer=cen_summer;
    xyz_cen_summer=lab2xyz2(lab_cen_summer,"d65_64");
    xyz_cen_summer1=xyz_cen_summer./xyz_cen_summer(2).*xyz_cen_base(2);
    lab_cen_summer1=xyz2lab(xyz_cen_summer1,"d65_64");
    par_summer(1,5:7)=lab_cen_summer1;
    cen_summer=par_summer(1,5:7);

    y_summer=cal_y(par_summer,points_cherry,"ellipsoidfit5");
    [r_summer(i_img,1)] = corr(y_summer(dim_idxs_cherry(1,:),1), scores_cherry(dim_idxs_cherry(1,:),1), 'Type', 'Pearson'); 
    de_summer(i_img,1)=deltaE2000(cen_summer,cen_base);
    de_summer1(i_img,:)=[cen_summer,cen_base,de_summer(i_img,1)];

    %peggy
    [y_peggy,par_peggy,characteristics(i_img,:)]=predict_my(ave_base(1,1),points_cherry,1,"01Preference");
    cen_peggy=[ave_base(1,1),par_peggy(1,4:5)];
    [r_peggy(i_img,1)] = corr(y_peggy(dim_idxs_cherry(1,:),1), scores_cherry(dim_idxs_cherry(1,:),1), 'Type', 'Pearson');    
    de_peggy(i_img,1)=deltaE2000(cen_peggy,cen_base);
    de_peggy1(i_img,:)=[cen_peggy,cen_base,de_peggy(i_img,1)];
    par_peggy_all(i_img,:)=par_peggy;
    

    %OPPO
    lastPart_OPPO="inLab";
    OPPO_folder=fullfile("D:\work\project_code_backup\OPPOskinExpe\analyzeResult_scaled\" + ...
        "AnalyseResults_p\display\rela\efit_p\scene",lastPart_OPPO,"ellipPara_scaled");
    OPPO_data=load(fullfile(OPPO_folder,"fitRes_level.mat"));
    par_OPPO=OPPO_data.par;
    cen_OPPO=par_OPPO(1,5:7);

    lab_cen_OPPO=cen_OPPO;
    xyz_cen_OPPO=lab2xyz2(lab_cen_OPPO,"d65_64");
    xyz_cen_OPPO1=xyz_cen_OPPO./xyz_cen_OPPO(2).*xyz_cen_base(2);
    lab_cen_OPPO1=xyz2lab(xyz_cen_OPPO1,"d65_64");
    par_OPPO(1,5:7)=lab_cen_OPPO1;
    cen_OPPO=par_OPPO(1,5:7);


    y_OPPO=cal_y(par_OPPO,points_cherry,"ellipsoidfit5");
    [r_OPPO(i_img,1)] = corr(y_OPPO, scores_cherry, 'Type', 'Pearson'); 
    de_OPPO(i_img,1)=deltaE2000(cen_OPPO,cen_base);
    de_OPPO1(i_img,:)=[cen_OPPO,cen_base,de_OPPO(i_img,1)];


    cens(:,:,i_img)=[cen_david;cen_cherry;cen_summer;cen_OPPO;cen_peggy];  


    % figure(1);hold on;
    % plot(points_cherry(dim_idxs_cherry(1,:),2),points_cherry(dim_idxs_cherry(1,:),3),  'o', 'Color', 'b', 'MarkerSize', 6);
    % plot(cen_peggy(1,2),cen_peggy(1,3),  's', 'Color', 'r','MarkerFaceColor','r', 'MarkerSize', 6);
    % plot(cen_david(1,2),cen_david(1,3),  'p', 'Color', 'r','MarkerFaceColor','g', 'MarkerSize', 6);
    % plot(cen_summer(1,2),cen_summer(1,3),  'p', 'Color', 'g','MarkerFaceColor','k', 'MarkerSize', 6);    
    % plot(cen_cherry(1,2),cen_cherry(1,3),  '^', 'Color', 'b','MarkerFaceColor','b', 'MarkerSize', 6);
    % outputFolder=fullfile(output_folder,"a_b");
    % if ~exist(outputFolder,"dir")
    %     mkdir(outputFolder);
    % end
    % exportgraphics(gcf,fullfile(outputFolder,strcat(source_name,".jpg")));
    % close(gcf)
    % 
    % figure(2);hold on;
    % plot(points_cherry(dim_idxs_cherry(2,:),2),points_cherry(dim_idxs_cherry(2,:),1),  'o', 'Color', 'b', 'MarkerSize', 6);
    % plot(cen_peggy(1,2),cen_peggy(1,1),  's', 'Color', 'r', 'MarkerFaceColor','r','MarkerSize', 6);
    % plot(cen_david(1,2),cen_david(1,1),  'p', 'Color', 'r','MarkerFaceColor','g', 'MarkerSize', 6);
    % plot(cen_summer(1,2),cen_summer(1,1),  'p', 'Color', 'g','MarkerFaceColor','k', 'MarkerSize', 6);    
    % plot(cen_cherry(1,2),cen_cherry(1,1),  '^', 'Color', 'b','MarkerFaceColor','b', 'MarkerSize', 6);
    % outputFolder=fullfile(output_folder,"L_a");
    % if ~exist(outputFolder,"dir")
    %     mkdir(outputFolder);
    % end
    % exportgraphics(gcf,fullfile(outputFolder,strcat(source_name,".jpg")));
    % close(gcf)
    % 
    % figure(3);hold on;
    % plot(points_cherry(dim_idxs_cherry(3,:),3),points_cherry(dim_idxs_cherry(3,:),1),  'o', 'Color', 'b', 'MarkerSize', 6);
    % plot(cen_peggy(1,3),cen_peggy(1,1),  's', 'Color', 'r', 'MarkerFaceColor','r','MarkerSize', 6);
    % plot(cen_david(1,3),cen_david(1,1),  'p', 'Color', 'r', 'MarkerFaceColor','g','MarkerSize', 6);
    % plot(cen_summer(1,3),cen_summer(1,1),  'p', 'Color', 'g','MarkerFaceColor','k', 'MarkerSize', 6);    
    % plot(cen_cherry(1,3),cen_cherry(1,1),  '^', 'Color', 'b','MarkerFaceColor','b', 'MarkerSize', 6);
    % outputFolder=fullfile(output_folder,"L_b");
    % if ~exist(outputFolder,"dir")
    %     mkdir(outputFolder);
    % end
    % exportgraphics(gcf,fullfile(outputFolder,strcat(source_name,".jpg")));
    % close(gcf)



end


disp("d")
r_all=[r_david,r_cherry,r_summer,r_OPPO,r_peggy];
de_all=[de_david,de_cherry,de_summer,de_OPPO,de_peggy];
result_cherry=nanmean(de_all,1)
end

%% 计算CAT后的lab_values
% 用渲染中心那一张 图片提取肤色 与 设置肤色 亮度矫正后 算Dt 用这个Dt把渲染中心那一张 CAT回D65
%然后再把cherry，David，Summer和Peggy的center 渲染到图上
% 
% lab_extracted_folder="D:\work\VIVOskinExpe\skin_model\evaluation_rendering\render_code\compare\res";
% lab_extracted_file=fullfile(lab_extracted_folder,"lab_ave_extracted.mat");
% lab_extracted_data=load(lab_extracted_file);
% lab_ave_all_cell=lab_extracted_data.lab_ave_all_cell;
% 
% david_table_folder="D:\work\ZJU_entire_skin\David\Naturalness model\Jason's final project\data analysis\res\separate_skin_methods\resTable\quality";
% david_table_file=fullfile(david_table_folder,"David_table.mat");
% david_table_data=load(david_table_file);
% david_table=david_table_data.fit_table;
% 
% img_folder="D:\work\ZJU_entire_skin\ZJU_skin_database\A_images\David\original_imgs";
% save_folder=fullfile(img_folder,"D65");
% if ~exist(save_folder,"dir")
%     mkdir(save_folder);
% end
% david_table.lab_values_CATed = cell(height(david_table), 1); % 初始化元胞数组列
% for i_img=1:size(david_table,1)
%     for i_match=1:size(lab_ave_all_cell,1)
%         filename=char(david_table.source{i_img});
%         if strcmp(lab_ave_all_cell{i_match,2},filename(7:end))
%             break
%         end
%     end
%     labs_theory=david_table.lab_values{i_img};
%     lab_theory=labs_theory(1,:);
%     labNscore=lab_ave_all_cell{i_match,1};
%     lab_extract=labNscore{end,1};
%     lab_theoNext{i_img,1}=lab_theory;
%     lab_theoNext{i_img,2}=lab_extract;
%     xyz_theory=lab2xyz2(lab_theory,"d65_64");
%     xyz_extract=lab2xyz2(lab_extract,"d65_64");
%     % scale=xyz_theory(2)./xyz_extract(2);
%     % xyz_extract_scaled=xyz_extract.*scale;
%     xyz_theory=xyz_theory./xyz_theory(2);
%     xyz_extract=xyz_extract./xyz_extract(2);
% 
%     M_CAT02 = [0.401288 0.650173 -0.051461; ...
%         -0.250268 1.204414 0.045854;...
%         -0.002079 0.048952 0.953127];
% 
%     Inv_M_CAT02 = M_CAT02^-1;
% 
%     lms_theory = M_CAT02*xyz_theory';
%     lms_extract = M_CAT02*xyz_extract';
%     Dt_fore=lms_extract./lms_theory;Dt_fore=Dt_fore';
%     Dt_back=lms_theory./lms_extract;Dt_back=Dt_back';
%     xyz_values=lab2xyz2(labs_theory,"d65_64");
%     lms_values=M_CAT02*xyz_values';
%     lms_values=lms_values';
%     lms_values_CATed=lms_values.*repmat(Dt_fore,size(lms_values,1),1);
%     lms_values_CATed=lms_values_CATed';
%     xyz_values_CATed=(Inv_M_CAT02*lms_values_CATed)';
% 
%     % xyz_values_CATed = SimpleTwostepCAT_Dt(xyz_values,Dt_fore);
%     david_table.lab_values_CATed{i_img}=xyz2lab(xyz_values_CATed,"d65_64");
% 
% 
% 
% 
%     %-----------CAT图片从extracted到theory---------------
%     % img=imread(fullfile(img_folder,sprintf("skin_%d.jpg",i_img)));
%     % img=double(img);
%     % sz=size(img);
%     % img_lin=reshape(img,[sz(1)*sz(2),sz(3)]);
%     % img_xyz=srgb2xyz(img_lin);
%     % img_xyz=img_xyz./img_xyz(2);
%     % img_lms=M_CAT02*img_xyz';
%     % img_lms=img_lms';
%     % img_D65_lms=img_lms.*repmat(Dt_back,size(img_lms,1),1);
%     % img_D65_lms=img_D65_lms';
%     % img_D65_xyz=(Inv_M_CAT02*img_D65_lms)';
%     % img_D65_xyz=img_D65_xyz./img_D65_xyz(2).*100;
%     % img_D65_rgb=xyz2srgb(img_D65_xyz);
%     % 
%     % img_D65=reshape(img_D65_rgb,[sz(1),sz(2),sz(3)]);
%     % figure(3)
%     % imshow(img_D65./255);
%     % 
%     % imwrite(img_D65,fullfile(save_folder,sprintf("skin_%d.jpg",i_img)));
%     fprintf("skin_%d.jpg\n",i_img);
% end
% save(fullfile(david_table_folder,"David_table_CATed.mat"),"david_table");

%% 评价OPPO 纯净版
if ismember("OPPO",sources)
clear("de_david","de_cherry","de_summer","de_OPPO","de_peggy")
clear("de_david1","de_cherry1","de_summer1","de_OPPO1","de_peggy1")
dims_OPPO=[1:16;33:48;17:32];
Peggy_OPPO_folder="D:\work\project_code_backup\OPPOskinExpe\analyzeResult_scaled\AnalyseResults_p\display\rela\efit_p\resTable";
Peggy_OPPO_file=fullfile(Peggy_OPPO_folder,"Peggy_OPPO_table.mat");
Peggy_OPPO_data=load(Peggy_OPPO_file);
Peggy_OPPO_table=Peggy_OPPO_data.fit_table(1:52,:);

cherry_fitRes_file=fullfile("D:\work\ZJU_entire_skin\Cherry\software\skin colour\数据分析\分析过程\res\nation\weighted\fitRes\ellipPara.mat");
cherry_fitRes_data=load(cherry_fitRes_file);
par_YY=cherry_fitRes_data.par_all(3,:);

summer_table_file=fullfile("D:\work\ZJU_entire_skin\Summer\Data\Haisi skin\3. Test experiment\4. Model\res\resTable\Summer_table.mat");
summer_table_data=load(summer_table_file);
summer_table=summer_table_data.fit_table;



David_fitRes_folder=fullfile("D:\work\ZJU_entire_skin\David\Naturalness model\Jason's final project\data analysis\res\CATed\fitRes");


David_fitRes_file=fullfile(David_fitRes_folder,"fitRes.mat");
David_fitRes_data=load(David_fitRes_file);
par_david=David_fitRes_data.par(4,:);
cen_david=par_david(1,5:7);

OPPO_ori_img_folder="D:\work\ZJU_entire_skin\ZJU_skin_database\A_images\Peggy_OPPO\original_imgs\i";
OPPO_mask_folder=fullfile(OPPO_ori_img_folder,"mask");
dir_OPPO_ori_img=dir(fullfile(OPPO_ori_img_folder,"*.jpg"));
dir_OPPO_mask=dir(fullfile(OPPO_mask_folder,"*.jpg"));
OPPO_ori_img_folder="D:\work\ZJU_entire_skin\ZJU_skin_database\A_images\Peggy_OPPO\original_imgs\r\cropped";
OPPO_mask_folder=fullfile(OPPO_ori_img_folder,"mask");
dir_OPPO_ori_img=[dir_OPPO_ori_img;dir(fullfile(OPPO_ori_img_folder,"*.jpg"))];
dir_OPPO_mask=[dir_OPPO_mask;dir(fullfile(OPPO_mask_folder,"*.jpg"))];

display_folder="D:\work\project_code_backup\OPPOskinExpe\display_calibration";
datai_file=fullfile(display_folder,"datai_sorted40_3.mat");
data_file=fullfile(display_folder,"data_sorted40_3.mat");

lastParts_OPPO=["inLab","indoorAdd","outdoorAdd","sunsetAdd","nightAdd"];
output_folder=fullfile("res","pic","on_Peggy_OPPO");
if ~exist(output_folder,"dir")
    mkdir(output_folder);
end
output_folder1=fullfile("res","pic","on_Peggy_OPPO1");
if ~exist(output_folder1,"dir")
    mkdir(output_folder1);
end
for i_img=1:size(Peggy_OPPO_table,1)
    points_OPPO=Peggy_OPPO_table.lab_values{i_img};
    scores_OPPO=Peggy_OPPO_table.opinion_scores{i_img};
    source_name=Peggy_OPPO_table.source{i_img};
    par_OPPO=Peggy_OPPO_table.par{i_img};
    cen_OPPO=par_OPPO(1,5:7);
    source_name1=strrep(source_name,"Peggy_OPPO_","");


    cen_OPPO=par_OPPO(1,5:7);

    for i_OPPO=1:length(lastParts_OPPO)
        if contains(Peggy_OPPO_table.scene{i_img},lastParts_OPPO(i_OPPO))
            break
        end
    end
    lastPart_OPPO=char(lastParts_OPPO(i_OPPO));
    OPPO_folder=fullfile("D:\work\project_code_backup\OPPOskinExpe\analyzeResult_scaled\" + ...
        "AnalyseResults_p\display\rela\efit_p\scene",lastPart_OPPO,"ellipPara_scaled");
    OPPO_data=load(fullfile(OPPO_folder,"fitRes_level.mat"));
    par_OPPO_scene=OPPO_data.par;
    cen_OPPO_scene=par_OPPO_scene(1,5:7);
    xyz_cen_OPPO_scene=lab2xyz2(cen_OPPO_scene,"d65_64");
    %----------------------------------------

    %OPPO

    %scale
    lab_cen_OPPO=cen_OPPO;
    xyz_cen_OPPO=lab2xyz2(lab_cen_OPPO,"d65_64");
    xyz_cen_OPPO1=xyz_cen_OPPO_scene./xyz_cen_OPPO_scene(2).*xyz_cen_OPPO(2);
    lab_cen_OPPO1=xyz2lab(xyz_cen_OPPO1,"d65_64");
    par_OPPO_scene1(1,5:7)=lab_cen_OPPO1;
    cen_OPPO_scene=par_OPPO_scene1(1,5:7);


    y_OPPO=cal_y(par_OPPO,points_OPPO,"ellipsoidfit5");
    [r_OPPO(i_img,1)] = corr(y_OPPO, scores_OPPO, 'Type', 'Pearson'); 
    de_OPPO(i_img,1)=deltaE2000(cen_OPPO,cen_OPPO_scene);
    de_OPPO1(i_img,:)=[cen_OPPO,cen_OPPO_scene,de_OPPO(i_img,1)];


    %david
    %scale
    lab_cen_david=cen_david;
    xyz_cen_david=lab2xyz2(lab_cen_david,"d65_64");
    xyz_cen_david1=xyz_cen_david./xyz_cen_david(2).*xyz_cen_OPPO(2);
    lab_cen_david1=xyz2lab(xyz_cen_david1,"d65_64");
    par_david(1,5:7)=lab_cen_david1;
    cen_david=par_david(1,5:7);

    y_david=cal_y(par_david,points_OPPO,"ellipsoidfit4");
    r_david(i_img,1) = corr(y_david, scores_OPPO, 'Type', 'Pearson');
    de_david(i_img,1)=deltaE2000(cen_david,cen_OPPO);
    de_david1(i_img,:)=[cen_david,cen_OPPO,de_david(i_img,1)];

    %cherry
    par_cherry=par_YY;
    cen_cherry=par_cherry(1,5:7);

    %scale
    lab_cen_cherry=cen_cherry;
    xyz_cen_cherry=lab2xyz2(lab_cen_cherry,"d65_64");
    xyz_cen_cherry1=xyz_cen_cherry./xyz_cen_cherry(2).*xyz_cen_OPPO(2);
    lab_cen_cherry1=xyz2lab(xyz_cen_cherry1,"d65_64");
    par_cherry(1,5:7)=lab_cen_cherry1;
    cen_cherry=par_cherry(1,5:7);

    y_cherry=cal_y(par_cherry,points_OPPO,"ellipsoidfit3_1");
    r_cherry(i_img,1) = corr(y_cherry(1:17,1), scores_OPPO(1:17,1), 'Type', 'Pearson');
    de_cherry(i_img,1)=deltaE2000(cen_cherry,cen_OPPO);


    %summer
    par_summer=summer_table.par{14}';
    cen_summer=summer_table.lab_center{14}; 

    %scale
    lab_cen_summer=cen_summer;
    xyz_cen_summer=lab2xyz2(lab_cen_summer,"d65_64");
    xyz_cen_summer1=xyz_cen_summer./xyz_cen_summer(2).*xyz_cen_OPPO(2);
    lab_cen_summer1=xyz2lab(xyz_cen_summer1,"d65_64");
    par_summer(1,5:7)=lab_cen_summer1;
    cen_summer=par_summer(1,5:7);

    y_summer=cal_y(par_summer,points_OPPO,"ellipsoidfit5");
    [r_summer(i_img,1)] = corr(y_summer, scores_OPPO, 'Type', 'Pearson'); 
    de_summer(i_img,1)=deltaE2000(cen_summer,cen_OPPO);


    %peggy
    [y_peggy,par_peggy,characteristics(i_img,:)]=predict_my(points_OPPO(1,1),points_OPPO,1,"01Preference");
    [r_peggy(i_img,1)] = corr(y_peggy(dims_OPPO(1,:),1), scores_OPPO(dims_OPPO(1,:),1), 'Type', 'Pearson');    
    cen_peggy=[par_OPPO(1,5),par_peggy(1,4:5)];
    de_peggy(i_img,1)=deltaE2000(cen_peggy,par_OPPO(1,5:7));
    par_peggy_all(i_img,:)=par_peggy;

    cens(:,:,i_img)=[cen_david;cen_cherry;cen_summer;cen_OPPO;cen_peggy];   

    % figure(1);hold on;
    % plot(points_Peggy_OPPO(dims_OPPO(1,:),2),points_Peggy_OPPO(dims_OPPO(1,:),3),  'o', 'Color', 'b', 'MarkerSize', 6);
    % plot(par_peggy(1,4),par_peggy(1,5),  's', 'Color', 'r','MarkerFaceColor','r', 'MarkerSize', 6);
    % plot(cen_david_scaled(1,2),cen_david_scaled(1,3),  'p', 'Color', 'r','MarkerFaceColor','k', 'MarkerSize', 6); 
    % plot(cen_cherry_scaled(1,2),cen_cherry_scaled(1,3),  'p', 'Color', 'g','MarkerFaceColor','k', 'MarkerSize', 6); 
    % plot(cen_summer_scaled(1,2),cen_summer_scaled(1,3),  'p', 'Color', 'b','MarkerFaceColor','k', 'MarkerSize', 6);    
    % plot(par_Peggy_OPPO(1,6),par_Peggy_OPPO(1,7),  '^', 'Color', 'b','MarkerFaceColor','b', 'MarkerSize', 6);
    % outputFolder=fullfile(output_folder,"a_b");
    % if ~exist(outputFolder,"dir")
    %     mkdir(outputFolder);
    % end
    % exportgraphics(gcf,fullfile(outputFolder,strcat(source_name,".jpg")));
    % close(gcf)
    % 
    % figure(2);hold on;
    % plot(points_Peggy_OPPO(dims_OPPO(2,:),2),points_Peggy_OPPO(dims_OPPO(2,:),1),  'o', 'Color', 'b', 'MarkerSize', 6);
    % plot(par_peggy(1,4),points_Peggy_OPPO(1,1),  's', 'Color', 'r', 'MarkerFaceColor','r','MarkerSize', 6);
    % plot(cen_david_scaled(1,2),cen_david_scaled(1,1),  'p', 'Color', 'r','MarkerFaceColor','k', 'MarkerSize', 6); 
    % plot(cen_cherry_scaled(1,2),cen_cherry_scaled(1,1),  'p', 'Color', 'g','MarkerFaceColor','k', 'MarkerSize', 6); 
    % plot(cen_summer_scaled(1,2),cen_summer_scaled(1,1),  'p', 'Color', 'b','MarkerFaceColor','k', 'MarkerSize', 6);    
    % plot(par_Peggy_OPPO(1,6),par_Peggy_OPPO(1,5),  '^', 'Color', 'b','MarkerFaceColor','b', 'MarkerSize', 6);
    % outputFolder=fullfile(output_folder,"L_a");
    % if ~exist(outputFolder,"dir")
    %     mkdir(outputFolder);
    % end
    % exportgraphics(gcf,fullfile(outputFolder,strcat(source_name,".jpg")));
    % close(gcf)
    % 
    % figure(3);hold on;
    % plot(points_Peggy_OPPO(dims_OPPO(3,:),3),points_Peggy_OPPO(dims_OPPO(3,:),1),  'o', 'Color', 'b', 'MarkerSize', 6);
    % plot(par_peggy(1,5),points_Peggy_OPPO(1,1),  's', 'Color', 'r', 'MarkerFaceColor','r','MarkerSize', 6);
    % plot(cen_david_scaled(1,3),cen_david_scaled(1,1),  'p', 'Color', 'r','MarkerFaceColor','k', 'MarkerSize', 6); 
    % plot(cen_cherry_scaled(1,3),cen_cherry_scaled(1,1),  'p', 'Color', 'g','MarkerFaceColor','k', 'MarkerSize', 6); 
    % plot(cen_summer_scaled(1,3),cen_summer_scaled(1,1),  'p', 'Color', 'b','MarkerFaceColor','k', 'MarkerSize', 6);   
    % plot(par_Peggy_OPPO(1,7),par_Peggy_OPPO(1,5),  '^', 'Color', 'b','MarkerFaceColor','b', 'MarkerSize', 6);
    % outputFolder=fullfile(output_folder,"L_b");
    % if ~exist(outputFolder,"dir")
    %     mkdir(outputFolder);
    % end
    % exportgraphics(gcf,fullfile(outputFolder,strcat(source_name,".jpg")));
    % close(gcf)

end
for i_img=1:size(Peggy_OPPO_table)
    for i_row=1:size(cens,1)
        for i_col=1:size(cens,1)
            de_cens(i_row,i_col,i_img)=deltaE2000(cens(i_row,:,i_img),cens(i_col,:,i_img));
        end
    end

end
de_cens_mean=mean(de_cens,3);

disp("d")

result_OPPO=[mean(de_david),mean(de_cherry),mean(de_summer),mean(de_OPPO),mean(de_peggy)]
end
%% 评OPPO+渲染
% dims_OPPO=[1:16;33:48;17:32];
% Peggy_OPPO_folder="D:\work\project_code_backup\OPPOskinExpe\analyzeResult_scaled\AnalyseResults_p\display\rela\efit_p\resTable";
% Peggy_OPPO_file=fullfile(Peggy_OPPO_folder,"Peggy_OPPO_table.mat");
% Peggy_OPPO_data=load(Peggy_OPPO_file);
% Peggy_OPPO_table=Peggy_OPPO_data.fit_table(1:52,:);
% 
% cherry_fitRes_file=fullfile("D:\work\ZJU_entire_skin\Cherry\software\skin colour\数据分析\分析过程\res\nation\weighted\fitRes\ellipPara.mat");
% cherry_fitRes_data=load(cherry_fitRes_file);
% par_YY=cherry_fitRes_data.par_all(3,:);
% 
% summer_table_file=fullfile("D:\work\ZJU_entire_skin\Summer\Data\Haisi skin\3. Test experiment\4. Model\res\resTable\Summer_table.mat");
% summer_table_data=load(summer_table_file);
% summer_table=summer_table_data.fit_table;
% 
% 
% % david_table_file=fullfile("D:\work\ZJU_entire_skin\David\Naturalness model\Jason's final project\data analysis\res\separate_skin_methods\resTable\quality\David_table.mat");
% % david_table_data=load(david_table_file);
% % david_table=david_table_data.fit_table;
% 
% % David_fitRes_folder=fullfile("D:\work\ZJU_entire_skin\David\Naturalness model\Jason's final project\data analysis\res\separate_skin_methods\quality\fitRes\ellipsoidfit4");
% David_fitRes_folder=fullfile("D:\work\ZJU_entire_skin\David\Naturalness model\Jason's final project\data analysis\res\CATed\fitRes");
% 
% 
% David_fitRes_file=fullfile(David_fitRes_folder,"fitRes.mat");
% David_fitRes_data=load(David_fitRes_file);
% par_david=David_fitRes_data.par(4,:);
% cen_david=par_david(1,5:7);
% 
% OPPO_ori_img_folder="D:\work\ZJU_entire_skin\ZJU_skin_database\A_images\Peggy_OPPO\original_imgs\i";
% OPPO_mask_folder=fullfile(OPPO_ori_img_folder,"mask");
% dir_OPPO_ori_img=dir(fullfile(OPPO_ori_img_folder,"*.jpg"));
% dir_OPPO_mask=dir(fullfile(OPPO_mask_folder,"*.jpg"));
% OPPO_ori_img_folder="D:\work\ZJU_entire_skin\ZJU_skin_database\A_images\Peggy_OPPO\original_imgs\r\cropped";
% OPPO_mask_folder=fullfile(OPPO_ori_img_folder,"mask");
% dir_OPPO_ori_img=[dir_OPPO_ori_img;dir(fullfile(OPPO_ori_img_folder,"*.jpg"))];
% dir_OPPO_mask=[dir_OPPO_mask;dir(fullfile(OPPO_mask_folder,"*.jpg"))];
% 
% display_folder="D:\work\project_code_backup\OPPOskinExpe\display_calibration";
% datai_file=fullfile(display_folder,"datai_sorted40_3.mat");
% data_file=fullfile(display_folder,"data_sorted40_3.mat");
% 
% lastParts_OPPO=["inLab","indoorAdd","outdoorAdd","sunsetAdd","nightAdd"];
% output_folder=fullfile("res","pic","on_Peggy_OPPO");
% if ~exist(output_folder,"dir")
%     mkdir(output_folder);
% end
% output_folder1=fullfile("res","pic","on_Peggy_OPPO1");
% if ~exist(output_folder1,"dir")
%     mkdir(output_folder1);
% end
% for i_img=1:size(Peggy_OPPO_table,1)
%     points_OPPO=Peggy_OPPO_table.lab_values{i_img};
%     scores_OPPO=Peggy_OPPO_table.opinion_scores{i_img};
%     source_name=Peggy_OPPO_table.source{i_img};
%     par_OPPO=Peggy_OPPO_table.par{i_img};
%     cen_OPPO=par_OPPO(1,5:7);
%     source_name1=strrep(source_name,"Peggy_OPPO_","");
%     % for i_match=1:length(dir_OPPO_ori_img)
%     %     img_name=strrep(dir_OPPO_ori_img(i_match).name,".jpg","");
%     %     img_name=strrep(img_name,".JPG","");
%     %     img_name=strrep(img_name,"cropped_","");
%     %     if strcmp(img_name,source_name1)
%     %         check_name{i_img}=strcat(img_name,"_",source_name1);
%     %         break
%     %     end
%     % end
%     % ori_img=imread(fullfile(dir_OPPO_ori_img(i_match).folder,dir_OPPO_ori_img(i_match).name));
%     % mask=imread(fullfile(dir_OPPO_mask(i_match).folder,dir_OPPO_mask(i_match).name));
% 
%     % ori_img=double(ori_img);
%     % sz=size(ori_img);
%     % ori_img_lin=reshape(ori_img,[sz(1)*sz(2),sz(3)]);
%     % xyz_img_lin=srgb2xyz(ori_img_lin);
%     % % xyz_img_lin = lut3d_rgb2xyz1(ori_img_lin, datai_file);
%     % lab_img_lin=xyz2lab(xyz_img_lin,"d65_64");
%     % [logicalIndex,bull_weight]=read_bull(mask,0);
%     % average=mean(lab_img_lin(~logicalIndex, :));
%     % % [average]=get_average(lab_img_lin,mask,0);
%     % % figure(1)
%     % % imshow(reshape(xyz_img_lin./50,[sz(1),sz(2),sz(3)]));
% 
% 
%     cen_OPPO=par_OPPO(1,5:7);
%     % cen_xyz=lab2xyz2(cen_peggy_OPPO,"d65_64");
%     % [cen_rgb,~] = lut3d_xyz2rgbNoPar(cen_xyz, data_file);
%     % cen_xyz1=srgb2xyz(cen_rgb);
%     % cen_peggy_OPPO1=xyz2lab(cen_xyz1,"d65_64");
%     for i_OPPO=1:length(lastParts_OPPO)
%         if contains(Peggy_OPPO_table.scene{i_img},lastParts_OPPO(i_OPPO))
%             break
%         end
%     end
%     lastPart_OPPO=char(lastParts_OPPO(i_OPPO));
%     OPPO_folder=fullfile("D:\work\project_code_backup\OPPOskinExpe\analyzeResult_scaled\" + ...
%         "AnalyseResults_p\display\rela\efit_p\scene",lastPart_OPPO,"ellipPara_scaled");
%     OPPO_data=load(fullfile(OPPO_folder,"fitRes_level.mat"));
%     par_OPPO_scene=OPPO_data.par;
%     cen_OPPO_scene=par_OPPO_scene(1,5:7);
%     xyz_cen_OPPO_scene=lab2xyz2(cen_OPPO_scene,"d65_64");
% %----------------------------------------
% 
%     % outputFolder=fullfile(output_folder,"ori_img");
%     % figure(4)
%     % imshow(rgb_peggy_OPPO);
%     % if ~exist(outputFolder,"dir")
%     %     mkdir(outputFolder);
%     % end
%     % imwrite(ori_img./255,fullfile(outputFolder,strcat(img_name,".jpg")));
% 
% 
%     ref_scale_lab = points_OPPO(end,:);
% 
% 
%     %OPPO
% 
%     %scale
%     lab_cen_OPPO=cen_OPPO;
%     xyz_cen_OPPO=lab2xyz2(lab_cen_OPPO,"d65_64");
%     xyz_cen_OPPO1=xyz_cen_OPPO_scene./xyz_cen_OPPO_scene(2).*xyz_cen_OPPO(2);
%     lab_cen_OPPO1=xyz2lab(xyz_cen_OPPO1,"d65_64");
%     par_OPPO_scene1(1,5:7)=lab_cen_OPPO1;
%     cen_OPPO_scene=par_OPPO_scene1(1,5:7);
% 
% 
%     y_OPPO=cal_y(par_OPPO,points_OPPO,"ellipsoidfit5");
%     [r_OPPO(i_img,1)] = corr(y_OPPO, scores_OPPO, 'Type', 'Pearson'); 
%     de_OPPO(i_img,1)=deltaE2000(cen_OPPO,cen_OPPO_scene);
%     de_OPPO1(i_img,:)=[cen_OPPO,cen_OPPO_scene,de_OPPO(i_img,1)];
% 
% 
%     %david
%     %scale
%     lab_cen_david=cen_david;
%     xyz_cen_david=lab2xyz2(lab_cen_david,"d65_64");
%     xyz_cen_david1=xyz_cen_david./xyz_cen_david(2).*xyz_cen_OPPO(2);
%     lab_cen_david1=xyz2lab(xyz_cen_david1,"d65_64");
%     par_david(1,5:7)=lab_cen_david1;
%     cen_david=par_david(1,5:7);
% 
%     y_david=cal_y(par_david,points_OPPO,"ellipsoidfit4");
%     r_david(i_img,1) = corr(y_david, scores_OPPO, 'Type', 'Pearson');
%     de_david(i_img,1)=deltaE2000(cen_david,cen_OPPO);
%     de_david1(i_img,:)=[cen_david,cen_OPPO,de_david(i_img,1)];
%     %--------------渲染david效果----------------
%     % lab_david=lab_img_lin;
%     % lab_face=lab_david(~logicalIndex, :);
%     % delta_lab=cen_david-average;
%     % lab_face=lab_face+repmat(delta_lab,size(lab_face,1),1);
%     % lab_david(~logicalIndex, :)=lab_face;
%     % xyz_david=lab2xyz2(lab_david,"d65_64");
%     % % [rgb_david,~] = lut3d_xyz2rgbKDitp1(xyz_david, datafile);
%     % rgb_david = xyz2srgb(xyz_david)./255;
%     % rgb_david=reshape(rgb_david,[sz(1),sz(2),sz(3)]);
%     % % figure(1)
%     % % imshow(rgb_david);
%     % outputFolder=fullfile(output_folder,"cen_david");
%     % if ~exist(outputFolder,"dir")
%     %     mkdir(outputFolder);
%     % end
%     % imwrite(rgb_david,fullfile(outputFolder,strcat(img_name,".jpg")));
% 
% 
%     %cherry
%     par_cherry=par_YY;
%     cen_cherry=par_cherry(1,5:7);
% 
%     %scale
%     lab_cen_cherry=cen_cherry;
%     xyz_cen_cherry=lab2xyz2(lab_cen_cherry,"d65_64");
%     xyz_cen_cherry1=xyz_cen_cherry./xyz_cen_cherry(2).*xyz_cen_OPPO(2);
%     lab_cen_cherry1=xyz2lab(xyz_cen_cherry1,"d65_64");
%     par_cherry(1,5:7)=lab_cen_cherry1;
%     cen_cherry=par_cherry(1,5:7);
% 
%     y_cherry=cal_y(par_cherry,points_OPPO,"ellipsoidfit3_1");
%     r_cherry(i_img,1) = corr(y_cherry(1:17,1), scores_OPPO(1:17,1), 'Type', 'Pearson');
%     de_cherry(i_img,1)=deltaE2000(cen_cherry,cen_OPPO);
% 
%     %--------------渲染cherry效果----------------
%     % lab_cherry=lab_img_lin;
%     % lab_face=lab_cherry(~logicalIndex, :);
%     % delta_lab=cen_cherry-average;
%     % lab_face=lab_face+repmat(delta_lab,size(lab_face,1),1);
%     % lab_cherry(~logicalIndex, :)=lab_face;
%     % xyz_cherry=lab2xyz2(lab_cherry,"d65_64");
%     % % [rgb_cherry,~] = lut3d_xyz2rgbKDitp1(xyz_cherry, datafile);
%     % % figure(2)
%     % % imshow(reshape(xyz_cherry./50,[sz(1),sz(2),sz(3)]));
%     % 
%     % rgb_cherry = xyz2srgb(xyz_cherry)./255;
%     % rgb_cherry=reshape(rgb_cherry,[sz(1),sz(2),sz(3)]);
%     % outputFolder=fullfile(output_folder,"cen_cherry");
%     % % figure(2)
%     % % imshow(rgb_cherry);
%     % if ~exist(outputFolder,"dir")
%     %     mkdir(outputFolder);
%     % end
%     % imwrite(rgb_cherry,fullfile(outputFolder,strcat(img_name,".jpg")));
% 
% 
%     %summer
%     par_summer=summer_table.par{14}';
%     cen_summer=summer_table.lab_center{14}; 
% 
%     %scale
%     lab_cen_summer=cen_summer;
%     xyz_cen_summer=lab2xyz2(lab_cen_summer,"d65_64");
%     xyz_cen_summer1=xyz_cen_summer./xyz_cen_summer(2).*xyz_cen_OPPO(2);
%     lab_cen_summer1=xyz2lab(xyz_cen_summer1,"d65_64");
%     par_summer(1,5:7)=lab_cen_summer1;
%     cen_summer=par_summer(1,5:7);
% 
%     y_summer=cal_y(par_summer,points_OPPO,"ellipsoidfit5");
%     [r_summer(i_img,1)] = corr(y_summer, scores_OPPO, 'Type', 'Pearson'); 
%     de_summer(i_img,1)=deltaE2000(cen_summer,cen_OPPO);
%     %--------------渲染summer效果----------------
%     % lab_summer=lab_img_lin;
%     % lab_face=lab_summer(~logicalIndex, :);
%     % delta_lab=cen_summer-average;
%     % lab_face=lab_face+repmat(delta_lab,size(lab_face,1),1);
%     % lab_summer(~logicalIndex, :)=lab_face;
%     % xyz_summer=lab2xyz2(lab_summer,"d65_64");
%     % % [rgb_summer,~] = lut3d_xyz2rgbKDitp1(xyz_summer, datafile);
%     % rgb_summer = xyz2srgb(xyz_summer)./255;
%     % rgb_summer=reshape(rgb_summer,[sz(1),sz(2),sz(3)]);
%     % outputFolder=fullfile(output_folder,"cen_summer");
%     % % figure(3)
%     % % imshow(rgb_summer);
%     % if ~exist(outputFolder,"dir")
%     %     mkdir(outputFolder);
%     % end
%     % imwrite(rgb_summer,fullfile(outputFolder,strcat(img_name,".jpg")));
% 
% 
%     %peggy
%     [y_peggy,par_peggy,characteristics(i_img,:)]=predict_my(points_OPPO(1,1),points_OPPO,1,"01Preference");
%     [r_peggy(i_img,1)] = corr(y_peggy(dims_OPPO(1,:),1), scores_OPPO(dims_OPPO(1,:),1), 'Type', 'Pearson');    
%     cen_peggy=[par_OPPO(1,5),par_peggy(1,4:5)];
%     de_peggy(i_img,1)=deltaE2000(cen_peggy,par_OPPO(1,5:7));
%     par_peggy_all(i_img,:)=par_peggy;
% 
%     %--------------渲染peggy效果----------------
%     % lab_peggy=lab_img_lin;
%     % lab_face=lab_peggy(~logicalIndex, :);
%     % delta_lab=cen_peggy-average;
%     % lab_face=lab_face+repmat(delta_lab,size(lab_face,1),1);
%     % lab_peggy(~logicalIndex, :)=lab_face;
%     % xyz_peggy=lab2xyz2(lab_peggy,"d65_64");
%     % % [rgb_peggy,~] = lut3d_xyz2rgbKDitp1(xyz_peggy, datafile);
%     % rgb_peggy = xyz2srgb(xyz_peggy)./255;
%     % rgb_peggy=reshape(rgb_peggy,[sz(1),sz(2),sz(3)]);
%     % outputFolder=fullfile(output_folder,"cen_peggy");
%     % % figure(4)
%     % % imshow(rgb_peggy);
%     % if ~exist(outputFolder,"dir")
%     %     mkdir(outputFolder);
%     % end
%     % imwrite(rgb_peggy,fullfile(outputFolder,strcat(img_name,".jpg")));
% 
% 
% 
% 
% 
%     %--------------渲染peggy_OPPO效果----------------
%     % cen_peggy_OPPO=par_OPPO(1,5:7);
%     % % cen_xyz=lab2xyz2(cen_peggy_OPPO,"d65_64");
%     % % [cen_rgb,~] = lut3d_xyz2rgbNoPar(cen_xyz, data_file);
%     % % cen_xyz1=srgb2xyz(cen_rgb);
%     % % cen_peggy_OPPO1=xyz2lab(cen_xyz1,"d65_64");
%     % 
%     % 
%     % lab_peggy_OPPO=lab_img_lin;
%     % lab_face=lab_peggy_OPPO(~logicalIndex, :);
%     % delta_lab=cen_peggy_OPPO-average;
%     % lab_face=lab_face+repmat(delta_lab,size(lab_face,1),1);
%     % lab_peggy_OPPO(~logicalIndex, :)=lab_face;
%     % xyz_peggy_OPPO=lab2xyz2(lab_peggy_OPPO,"d65_64");
%     % % [rgb_peggy_OPPO,~] = lut3d_xyz2rgbKDitp1(xyz_peggy_OPPO, datafile);
%     % rgb_peggy_OPPO = xyz2srgb(xyz_peggy_OPPO)./255;
%     % rgb_peggy_OPPO=reshape(rgb_peggy_OPPO,[sz(1),sz(2),sz(3)]);
%     % outputFolder=fullfile(output_folder,"cen_peggy_OPPO_srgb");
%     % % figure(4)
%     % % imshow(rgb_peggy_OPPO);
%     % if ~exist(outputFolder,"dir")
%     %     mkdir(outputFolder);
%     % end
%     % imwrite(rgb_peggy_OPPO,fullfile(outputFolder,strcat(img_name,".jpg")));
% 
% 
%     cens(:,:,i_img)=[cen_david;cen_cherry;cen_summer;cen_OPPO;cen_peggy];   
%     % cens_scaled(:,:,i_img)=[cen_david_scaled;cen_cherry_scaled;...
%     %     cen_summer_scaled;cen_peggy];
% 
%     % figure(1);hold on;
%     % plot(points_Peggy_OPPO(dims_OPPO(1,:),2),points_Peggy_OPPO(dims_OPPO(1,:),3),  'o', 'Color', 'b', 'MarkerSize', 6);
%     % plot(par_peggy(1,4),par_peggy(1,5),  's', 'Color', 'r','MarkerFaceColor','r', 'MarkerSize', 6);
%     % plot(cen_david_scaled(1,2),cen_david_scaled(1,3),  'p', 'Color', 'r','MarkerFaceColor','k', 'MarkerSize', 6); 
%     % plot(cen_cherry_scaled(1,2),cen_cherry_scaled(1,3),  'p', 'Color', 'g','MarkerFaceColor','k', 'MarkerSize', 6); 
%     % plot(cen_summer_scaled(1,2),cen_summer_scaled(1,3),  'p', 'Color', 'b','MarkerFaceColor','k', 'MarkerSize', 6);    
%     % plot(par_Peggy_OPPO(1,6),par_Peggy_OPPO(1,7),  '^', 'Color', 'b','MarkerFaceColor','b', 'MarkerSize', 6);
%     % outputFolder=fullfile(output_folder,"a_b");
%     % if ~exist(outputFolder,"dir")
%     %     mkdir(outputFolder);
%     % end
%     % exportgraphics(gcf,fullfile(outputFolder,strcat(source_name,".jpg")));
%     % close(gcf)
%     % 
%     % figure(2);hold on;
%     % plot(points_Peggy_OPPO(dims_OPPO(2,:),2),points_Peggy_OPPO(dims_OPPO(2,:),1),  'o', 'Color', 'b', 'MarkerSize', 6);
%     % plot(par_peggy(1,4),points_Peggy_OPPO(1,1),  's', 'Color', 'r', 'MarkerFaceColor','r','MarkerSize', 6);
%     % plot(cen_david_scaled(1,2),cen_david_scaled(1,1),  'p', 'Color', 'r','MarkerFaceColor','k', 'MarkerSize', 6); 
%     % plot(cen_cherry_scaled(1,2),cen_cherry_scaled(1,1),  'p', 'Color', 'g','MarkerFaceColor','k', 'MarkerSize', 6); 
%     % plot(cen_summer_scaled(1,2),cen_summer_scaled(1,1),  'p', 'Color', 'b','MarkerFaceColor','k', 'MarkerSize', 6);    
%     % plot(par_Peggy_OPPO(1,6),par_Peggy_OPPO(1,5),  '^', 'Color', 'b','MarkerFaceColor','b', 'MarkerSize', 6);
%     % outputFolder=fullfile(output_folder,"L_a");
%     % if ~exist(outputFolder,"dir")
%     %     mkdir(outputFolder);
%     % end
%     % exportgraphics(gcf,fullfile(outputFolder,strcat(source_name,".jpg")));
%     % close(gcf)
%     % 
%     % figure(3);hold on;
%     % plot(points_Peggy_OPPO(dims_OPPO(3,:),3),points_Peggy_OPPO(dims_OPPO(3,:),1),  'o', 'Color', 'b', 'MarkerSize', 6);
%     % plot(par_peggy(1,5),points_Peggy_OPPO(1,1),  's', 'Color', 'r', 'MarkerFaceColor','r','MarkerSize', 6);
%     % plot(cen_david_scaled(1,3),cen_david_scaled(1,1),  'p', 'Color', 'r','MarkerFaceColor','k', 'MarkerSize', 6); 
%     % plot(cen_cherry_scaled(1,3),cen_cherry_scaled(1,1),  'p', 'Color', 'g','MarkerFaceColor','k', 'MarkerSize', 6); 
%     % plot(cen_summer_scaled(1,3),cen_summer_scaled(1,1),  'p', 'Color', 'b','MarkerFaceColor','k', 'MarkerSize', 6);   
%     % plot(par_Peggy_OPPO(1,7),par_Peggy_OPPO(1,5),  '^', 'Color', 'b','MarkerFaceColor','b', 'MarkerSize', 6);
%     % outputFolder=fullfile(output_folder,"L_b");
%     % if ~exist(outputFolder,"dir")
%     %     mkdir(outputFolder);
%     % end
%     % exportgraphics(gcf,fullfile(outputFolder,strcat(source_name,".jpg")));
%     % close(gcf)
% 
% end
% for i_img=1:size(Peggy_OPPO_table)
%     for i_row=1:size(cens,1)
%         for i_col=1:size(cens,1)
%             de_cens(i_row,i_col,i_img)=deltaE2000(cens(i_row,:,i_img),cens(i_col,:,i_img));
%         end
%     end
%     % for i_row=1:size(cens_scaled,1)
%     %     for i_col=1:size(cens_scaled,1)
%     %         de_cens_scaled(i_row,i_col,i_img)=deltaE2000(cens_scaled(i_row,:,i_img),cens_scaled(i_col,:,i_img));
%     %     end
%     % end
% end
% de_cens_mean=mean(de_cens,3);
% % de_cens_scaled_mean=mean(de_cens_scaled,3);
% 
% 
% 
% disp("d")
% 
% result_OPPO=[mean(de_david),mean(de_cherry),mean(de_summer),mean(de_OPPO),mean(de_peggy)]

%% 评价david的
if ismember("david",sources)
clear("de_david","de_cherry","de_summer","de_OPPO","de_peggy")
clear("de_david1","de_cherry1","de_summer1","de_OPPO1","de_peggy1")
cherry_fitRes_file=fullfile("D:\work\ZJU_entire_skin\Cherry\software\skin colour\数据分析\分析过程\res\nation\weighted\fitRes\ellipPara.mat");
cherry_fitRes_data=load(cherry_fitRes_file);


summer_table_file=fullfile("D:\work\ZJU_entire_skin\Summer\Data\Haisi skin\3. Test experiment\4. Model\res\resTable\Summer_table.mat");
summer_table_data=load(summer_table_file);
summer_table=summer_table_data.fit_table;
cct_values = cell2mat(summer_table.CCT);  
idx_cct = cct_values == 6500;
if iscell(summer_table.scene)
    scene_chars = cellfun(@char, summer_table.scene, 'UniformOutput', false);
    idx_scene = cellfun(@(x) contains(x, "cat"), scene_chars);
else
    % 若scene是字符串/字符数组
    idx_scene = contains(summer_table.scene, "cat");
end
idx = idx_cct & idx_scene;
summer_table = summer_table(idx, :);

lastParts_OPPO=["inLab","indoorAdd","outdoorAdd","sunsetAdd","nightAdd"];

david_table_file=fullfile("D:\work\ZJU_entire_skin\David\Naturalness model\Jason's final project\data analysis\res\separate_skin_methods\resTable\quality\David_table.mat");
david_table_data=load(david_table_file);
david_table=david_table_data.fit_table;


David_fitRes_folder=fullfile("D:\work\ZJU_entire_skin\David\Naturalness model\Jason's final project\data analysis\res\CATed\fitRes");

David_fitRes_file=fullfile(David_fitRes_folder,"fitRes.mat");
David_fitRes_data=load(David_fitRes_file);


output_folder=fullfile("res","pic","on_david");
if ~exist(output_folder,"dir")
    mkdir(output_folder);
end
for i_img=1:size(david_table,1)
    points_david=david_table.lab_values{i_img};
    scores_david=david_table.opinion_scores{i_img};
    source_name=david_table.source{i_img};
    if ismember(david_table.model_id{i_img},["skin_1","skin_5","skin_7","skin_9","skin_10"])
        i_cherry=3;
        i_summer=3;
        i_david=4;
    else
        i_cherry=4;
        i_summer=2;
        i_david=5;
    end
    if ismember(david_table.model_id{i_img},["skin_9","skin_10"])
        i_OPPO=4;
    else
        i_OPPO=2;
    end


    %david        
    if i_david>0
        par_david=David_fitRes_data.par(i_david,:);
        cen_david=par_david(1,5:7);        
    else
        par_david=nan(1,8);
        cen_david=nan(1,3);
    end
    par_base=david_table.par{i_img};
    cen_base=par_base(1,5:7);
    xyz_base=lab2xyz2(cen_base,"d65_64");
    ave_base=david_table.average_lab{i_img};

    %scale
    lab_cen_david=cen_david;
    xyz_cen_david=lab2xyz2(lab_cen_david,"d65_64");
    xyz_cen_david=xyz_cen_david./xyz_cen_david(2).*xyz_base(2);
    lab_cen_david=xyz2lab(xyz_cen_david,"d65_64");
    par_david(1,5:7)=lab_cen_david;
    cen_david=par_david(1,5:7);

    y_david=cal_y(par_david,points_david,"ellipsoidfit4");
    r_david(i_img,1) = corr(y_david, scores_david, 'Type', 'Pearson');
    de_david(i_img,1)=deltaE2000(cen_david,cen_base);
    de_david1(i_img,:)=[cen_david,cen_base,de_david(i_img,1)];


    %cherry
    par_cherry=cherry_fitRes_data.par_all(i_cherry,:);
    cen_cherry=par_cherry(1,5:7);

    %scale
    lab_cen_cherry=cen_cherry;
    xyz_cen_cherry=lab2xyz2(lab_cen_cherry,"d65_64");
    xyz_cen_cherry1=xyz_cen_cherry./xyz_cen_cherry(2).*xyz_base(2);
    lab_cen_cherry1=xyz2lab(xyz_cen_cherry1,"d65_64");
    par_cherry(1,5:7)=lab_cen_cherry1;
    cen_cherry=par_cherry(1,5:7);

    y_cherry=cal_y(par_cherry,points_david,"ellipsoidfit3_1");
    r_cherry(i_img,1) = corr(y_cherry(1:17,1), scores_david(1:17,1), 'Type', 'Pearson');
    de_cherry(i_img,1)=deltaE2000(cen_cherry,cen_base);
    de_cherry1(i_img,:)=[cen_cherry,cen_base,de_cherry(i_img,1)];

    %summer
    par_summer=summer_table.par{i_summer};par_summer=par_summer';
    cen_summer=summer_table.lab_center{i_summer};
    %scale
    lab_cen_summer=cen_summer;
    xyz_cen_summer=lab2xyz2(lab_cen_summer,"d65_64");
    xyz_cen_summer1=xyz_cen_summer./xyz_cen_summer(2).*xyz_base(2);
    lab_cen_summer1=xyz2lab(xyz_cen_summer1,"d65_64");
    cen_summer=[ave_base(1),lab_cen_summer1(1,2:3)];
    par_summer(1,5:6)=cen_summer(1,2:3);

    y_summer=cal_y(par_summer,points_david,"ellipsoidfit5");
    [r_summer(i_img,1)] = corr(y_summer(1:17,1), scores_david(1:17,1), 'Type', 'Pearson'); 
    de_summer(i_img,1)=deltaE2000(cen_summer,cen_base);
    de_summer1(i_img,:)=[cen_summer,cen_base,de_summer(i_img,1)];

    %peggy
    [y_peggy,par_peggy,characteristics(i_img,:)]=predict_my(ave_base(1),points_david,1,"01Preference");
    cen_peggy=[ave_base(1),par_peggy(1,4:5)];
    [r_peggy(i_img,1)] = corr(y_peggy(1:17,1), scores_david(1:17,1), 'Type', 'Pearson');    
    de_peggy(i_img,1)=deltaE2000(cen_peggy,cen_base);
    de_peggy1(i_img,:)=[cen_peggy,cen_base,de_peggy(i_img,1)];
    par_peggy_all(i_img,:)=par_peggy;

    %OPPO
    lastPart_OPPO=char(lastParts_OPPO(i_OPPO));
    OPPO_folder=fullfile("D:\work\project_code_backup\OPPOskinExpe\analyzeResult_scaled\" + ...
        "AnalyseResults_p\display\rela\efit_p\scene",lastPart_OPPO,"ellipPara_scaled");
    OPPO_data=load(fullfile(OPPO_folder,"fitRes_level.mat"));
    par_OPPO=OPPO_data.par;
    cen_OPPO=par_OPPO(1,5:7);
    %scale
    lab_cen_OPPO=cen_OPPO;
    xyz_cen_OPPO=lab2xyz2(lab_cen_OPPO,"d65_64");
    xyz_cen_OPPO1=xyz_cen_OPPO./xyz_cen_OPPO(2).*xyz_base(2);
    lab_cen_OPPO1=xyz2lab(xyz_cen_OPPO1,"d65_64");
    par_OPPO(1,5:7)=lab_cen_OPPO1;
    cen_OPPO=par_OPPO(1,5:7);


    y_OPPO=cal_y(par_OPPO,points_david,"ellipsoidfit5");
    [r_OPPO(i_img,1)] = corr(y_OPPO, scores_david, 'Type', 'Pearson'); 
    de_OPPO(i_img,1)=deltaE2000(cen_OPPO,cen_base);
    de_OPPO1(i_img,:)=[cen_OPPO,cen_base,de_OPPO(i_img,1)];

    cens(:,:,i_img)=[cen_david;cen_cherry;cen_summer;cen_OPPO;cen_peggy];

    % figure(1);hold on;
    % plot(points_david(2:17,2),points_david(2:17,3),  'o', 'Color', 'b', 'MarkerSize', 6);
    % plot(cen_peggy(1,2),cen_peggy(1,3),  's', 'Color', 'r','MarkerFaceColor','r', 'MarkerSize', 6);
    % plot(cen_cherry(1,2),cen_cherry(1,3),  'p', 'Color', 'b','MarkerFaceColor','b', 'MarkerSize', 6);
    % plot(cen_summer(1,2),cen_summer(1,3),  'p', 'Color', 'g','MarkerFaceColor','g', 'MarkerSize', 6);    
    % plot(cen_david(1,2),cen_david(1,3),  '^', 'Color', 'r','MarkerFaceColor','r', 'MarkerSize', 6);
    % outputFolder=fullfile(output_folder,"a_b");
    % if ~exist(outputFolder,"dir")
    %     mkdir(outputFolder);
    % end
    % exportgraphics(gcf,fullfile(outputFolder,strcat(source_name,".jpg")));
    % close(gcf)
    % 
    % figure(2);hold on;
    % plot(points_david(18:33,2),points_david(18:33,1),  'o', 'Color', 'b', 'MarkerSize', 6);
    % plot(cen_peggy(1,2),cen_peggy(1,1),  's', 'Color', 'r', 'MarkerFaceColor','r','MarkerSize', 6);
    % plot(cen_cherry(1,2),cen_cherry(1,1),  'p', 'Color', 'b','MarkerFaceColor','b', 'MarkerSize', 6);
    % plot(cen_summer(1,2),cen_summer(1,1),  'p', 'Color', 'g','MarkerFaceColor','g', 'MarkerSize', 6);    
    % plot(cen_david(1,2),cen_david(1,1),  '^', 'Color', 'r','MarkerFaceColor','r', 'MarkerSize', 6);
    % outputFolder=fullfile(output_folder,"L_a");
    % if ~exist(outputFolder,"dir")
    %     mkdir(outputFolder);
    % end
    % exportgraphics(gcf,fullfile(outputFolder,strcat(source_name,".jpg")));
    % close(gcf)
    % 
    % figure(3);hold on;
    % plot(points_david(34:49,3),points_david(34:49,1),  'o', 'Color', 'b', 'MarkerSize', 6);
    % plot(cen_peggy(1,3),cen_peggy(1,1),  's', 'Color', 'r', 'MarkerFaceColor','r','MarkerSize', 6);
    % plot(cen_cherry(1,3),cen_cherry(1,1),  'p', 'Color', 'b', 'MarkerFaceColor','b','MarkerSize', 6);
    % plot(cen_summer(1,3),cen_summer(1,1),  'p', 'Color', 'g','MarkerFaceColor','g', 'MarkerSize', 6);    
    % plot(cen_david(1,3),cen_david(1,1),  '^', 'Color', 'r','MarkerFaceColor','r', 'MarkerSize', 6);
    % outputFolder=fullfile(output_folder,"L_b");
    % if ~exist(outputFolder,"dir")
    %     mkdir(outputFolder);
    % end
    % exportgraphics(gcf,fullfile(outputFolder,strcat(source_name,".jpg")));
    % close(gcf)

end
disp("d")
result_david=[nanmean(de_david),mean(de_cherry),mean(de_summer),mean(de_OPPO),mean(de_peggy)]

end
%% 评价VIVO
if ismember("peggy",sources)

clear("de_david","de_cherry","de_summer","de_OPPO","de_peggy")
clear("de_david1","de_cherry1","de_summer1","de_OPPO1","de_peggy1")
VIVO_table_folder="D:\work\VIVOskinExpe\analyze\AnalyseResults_p\efit_p\scaled\resTable";
VIVO_table_file=fullfile(VIVO_table_folder,"Peggy_VIVO_table.mat");
VIVO_table_data=load(VIVO_table_file);
VIVO_table=VIVO_table_data.fit_table;
idx=[];
for i_img=1:size(VIVO_table,1)
    if contains(VIVO_table.attribute{i_img}, "Preference")&&contains(VIVO_table.observer_type{i_img}, "non_model")
        idx=[idx;i_img];
    end
end
VIVO_table = VIVO_table(idx, :);

cherry_fitRes_file=fullfile("D:\work\ZJU_entire_skin\Cherry\software\skin colour\数据分析\分析过程\res\nation\weighted\fitRes\ellipPara.mat");
cherry_fitRes_data=load(cherry_fitRes_file);

lastParts_OPPO=["inLab","indoorAdd","outdoorAdd","sunsetAdd","nightAdd"];

summer_table_file=fullfile("D:\work\ZJU_entire_skin\Summer\Data\Haisi skin\3. Test experiment\4. Model\res\resTable\Summer_table.mat");
summer_table_data=load(summer_table_file);
summer_table=summer_table_data.fit_table;
cct_values = cell2mat(summer_table.CCT);  
idx_cct = cct_values == 6500;
if iscell(summer_table.scene)
    scene_chars = cellfun(@char, summer_table.scene, 'UniformOutput', false);
    idx_scene = cellfun(@(x) contains(x, "cat"), scene_chars);
else
    % 若scene是字符串/字符数组
    idx_scene = contains(summer_table.scene, "cat");
end
idx = idx_cct & idx_scene;
summer_table = summer_table(idx, :);

david_table_file=fullfile("D:\work\ZJU_entire_skin\David\Naturalness model\Jason's final project\data analysis\res\separate_skin_methods\resTable\quality\David_table.mat");
david_table_data=load(david_table_file);
david_table=david_table_data.fit_table;


David_fitRes_folder=fullfile("D:\work\ZJU_entire_skin\David\Naturalness model\Jason's final project\data analysis\res\CATed\fitRes");

David_fitRes_file=fullfile(David_fitRes_folder,"fitRes.mat");
David_fitRes_data=load(David_fitRes_file);


output_folder=fullfile("res","pic","on_VIVO");
if ~exist(output_folder,"dir")
    mkdir(output_folder);
end
for i_img=1:size(VIVO_table,1)
    if strcmp(VIVO_table.model_ethnicity{i_img},"Asian")
        i_cherry=3;
        i_summer=3;
        i_david=4;
        i_OPPO=1;
    elseif strcmp(VIVO_table.model_ethnicity{i_img},"Caucasian")
        i_cherry=4;
        i_summer=2;
        i_david=5;
        i_OPPO=0;
    elseif strcmp(VIVO_table.model_ethnicity{i_img},"South Asian")
        i_cherry=2;
        i_summer=4;
        i_david=0;
        i_OPPO=0;
    elseif strcmp(VIVO_table.model_ethnicity{i_img},"African")
        i_cherry=1;
        i_summer=1;
        i_david=0;
        i_OPPO=0;
    end
    source_name=strcat(VIVO_table.scene{i_img}, ...
        VIVO_table.model_id{i_img},VIVO_table.observer_type{i_img});
    %VIVO
    par_VIVO=VIVO_table.par{i_img};
    ave_VIVO=VIVO_table.average_lab{i_img};
    cen_VIVO=[ave_VIVO(1),par_VIVO(1,4:5)];
    scores_VIVO=VIVO_table.opinion_scores{i_img};
    points_VIVO=VIVO_table.lab_values{i_img};
    xyz_cen_VIVO=lab2xyz2(cen_VIVO,"d65_64");

    %peggy
    [y_peggy,par_peggy,characteristics(i_img,:)]=predict_my(ave_VIVO(1),points_VIVO,1,"01Preference");
    cen_peggy=[ave_VIVO(1),par_peggy(1,4:5)];
    [r_peggy(i_img,1)] = corr(y_peggy, scores_VIVO, 'Type', 'Pearson');    
    de_peggy(i_img,1)=deltaE2000(cen_peggy,cen_VIVO);
    par_peggy_all(i_img,:)=par_peggy;

    %david        
    if i_david>0
        par_david=David_fitRes_data.par(i_david,:);
        cen_david=par_david(1,5:7);        
    else
        par_david=nan(1,8);
        cen_david=nan(1,3);
    end
    %scale
    lab_cen_david=cen_david;
    xyz_cen_David=lab2xyz2(lab_cen_david,"d65_64");
    xyz_cen_david1=xyz_cen_David./xyz_cen_David(2).*xyz_cen_VIVO(2);
    lab_cen_david1=xyz2lab(xyz_cen_david1,"d65_64");
    par_david(1,5:7)=lab_cen_david1;
    cen_david=par_david(1,5:7);

    y_david=cal_y(par_david,points_VIVO,"ellipsoidfit4");
    r_david(i_img,1) = corr(y_david, scores_VIVO, 'Type', 'Pearson');
    de_david(i_img,1)=deltaE2000(cen_david,cen_VIVO);
    de_david1(i_img,:)=[cen_david,cen_VIVO,de_david(i_img,1)];


    %cherry
    par_cherry=cherry_fitRes_data.par_all(i_cherry,:);
    cen_cherry=par_cherry(1,5:7);

    lab_cen_cherry=cen_cherry;
    xyz_cen_cherry=lab2xyz2(lab_cen_cherry,"d65_64");
    xyz_cen_cherry1=xyz_cen_cherry./xyz_cen_cherry(2).*xyz_cen_VIVO(2);
    lab_cen_cherry1=xyz2lab(xyz_cen_cherry1,"d65_64");
    par_cherry(1,5:7)=lab_cen_cherry1;
    cen_cherry=par_cherry(1,5:7);


    y_cherry=cal_y(par_cherry,points_VIVO,"ellipsoidfit3_1");
    r_cherry(i_img,1) = corr(y_cherry, scores_VIVO, 'Type', 'Pearson');
    de_cherry(i_img,1)=deltaE2000(cen_cherry,cen_VIVO);
    de_cherry1(i_img,:)=[cen_cherry,cen_VIVO,de_cherry(i_img,1)];

    %summer
    par_summer=summer_table.par{i_summer};
    cen_summer=summer_table.lab_center{i_summer};

    
    lab_cen_summer=cen_summer;
    xyz_cen_summer=lab2xyz2(lab_cen_summer,"d65_64");
    xyz_cen_summer1=xyz_cen_summer./xyz_cen_summer(2).*xyz_cen_VIVO(2);
    lab_cen_summer1=xyz2lab(xyz_cen_summer1,"d65_64");
    par_summer(1,5:6)=lab_cen_summer1(1,2:3);
    cen_summer=lab_cen_summer1;

    y_summer=cal_y(par_summer,points_VIVO,"ellipsoidfit5");
    [r_summer(i_img,1)] = corr(y_summer, scores_VIVO, 'Type', 'Pearson'); 
    de_summer(i_img,1)=deltaE2000(cen_summer,cen_VIVO);
    de_summer1(i_img,:)=[cen_summer,cen_VIVO,de_summer(i_img,1)];


    %OPPO
    scene_char=char(VIVO_table.scene{i_img});
    blank=find(scene_char==' ');
    lastPart_char=scene_char(1:blank-1);
    if strcmp(lastPart_char,"inLab")
        lastPart_OPPO=lastPart_char;
    else
        lastPart_OPPO=strcat(lastPart_char,"Add");
    end
    OPPO_folder=fullfile("D:\work\project_code_backup\OPPOskinExpe\analyzeResult_scaled\" + ...
        "AnalyseResults_p\display\rela\efit_p\scene",lastPart_OPPO,"ellipPara_scaled");
    OPPO_data=load(fullfile(OPPO_folder,"fitRes_level.mat"));
    par_OPPO=OPPO_data.par;
    cen_OPPO=par_OPPO(1,5:7);

    lab_cen_OPPO=cen_OPPO;
    xyz_cen_OPPO=lab2xyz2(lab_cen_OPPO,"d65_64");
    xyz_cen_OPPO1=xyz_cen_OPPO./xyz_cen_OPPO(2).*xyz_cen_VIVO(2);
    lab_cen_OPPO1=xyz2lab(xyz_cen_OPPO1,"d65_64");
    par_OPPO(1,5:7)=lab_cen_OPPO1;
    cen_OPPO=par_OPPO(1,5:7);


    y_OPPO=cal_y(par_OPPO,points_VIVO,"ellipsoidfit5");
    [r_OPPO(i_img,1)] = corr(y_OPPO, scores_VIVO, 'Type', 'Pearson'); 
    de_OPPO(i_img,1)=deltaE2000(cen_OPPO,cen_VIVO);
    de_OPPO1(i_img,:)=[cen_OPPO,cen_VIVO,de_OPPO(i_img,1)];

    cens(:,:,i_img)=[cen_david;cen_cherry;cen_summer;cen_OPPO;cen_VIVO];

    % figure(1);hold on;
    % plot(points_VIVO(:,2),points_VIVO(:,3),  'o', 'Color', 'b', 'MarkerSize', 6);
    % plot(cen_peggy(1,2),cen_peggy(1,3),  's', 'Color', 'r','MarkerFaceColor','r', 'MarkerSize', 6);
    % plot(cen_cherry(1,2),cen_cherry(1,3),  'p', 'Color', 'b','MarkerFaceColor','b', 'MarkerSize', 6);
    % plot(cen_summer(1,2),cen_summer(1,3),  'p', 'Color', 'g','MarkerFaceColor','g', 'MarkerSize', 6);
    % plot(cen_OPPO(1,2),cen_OPPO(1,3),  'p', 'Color', 'k','MarkerFaceColor','k', 'MarkerSize', 6);
    % plot(cen_david(1,2),cen_david(1,3),  '^', 'Color', 'r','MarkerFaceColor','r', 'MarkerSize', 6);
    % outputFolder=fullfile(output_folder,"a_b");
    % if ~exist(outputFolder,"dir")
    %     mkdir(outputFolder);
    % end
    % exportgraphics(gcf,fullfile(outputFolder,strcat(source_name,".jpg")));
    % close(gcf)
    % 

end
disp("d")
result_VIVO=[nanmean(de_david),nanmean(de_cherry),nanmean(de_summer),...
    nanmean(de_OPPO),nanmean(de_peggy)]
end
% result_all=[result_david;result_cherry;result_summer;result_OPPO;result_VIVO]
