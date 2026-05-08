clc;clear;close all;
addpath("..\utils\")
% XYZ2lab
% ========== 消融实验配置 ==========
% "":                默认 — 不进行场景适配（向后兼容）
% "scene_types":     完整模型 — 根据 scene_type 分组加载 rela_incre 对 par(4:5) 进行百分比平移
% ablation_type = "";  % predict_all_in_one 默认不启用 scene_types
ablation_type = "scene_types";

% scene_type_indices 定义（对应 rs01-rs14 的分组）
scene_type_indices{1} = [1, 2, 4, 5, 6];   % indoor
scene_type_indices{2} = [3, 7, 8, 10, 12]; % outdoor
scene_type_indices{3} = [13, 14];          % night
scene_type_indices{4} = [9, 11];            % 另一分组
n_scene_type = length(scene_type_indices);
% =============================================
%% 评价all-in-one
%-----------load data--------------
cherry_fitRes_file=fullfile("D:\work\ZJU_entire_skin\Cherry\software\skin colour\数据分析\分析过程\res\nation\weighted\fitRes\ellipPara.mat");
cherry_fitRes_data=load(cherry_fitRes_file);

summer_table_file = fullfile("D:\work\ZJU_entire_skin\Summer\Data\Haisi skin\3. Test experiment\4. Model\res\resTable\Summer_table.mat");
summer_table_data = load(summer_table_file);
summer_table_all = summer_table_data.fit_table;

% Filtered summer table (CCT=6500, scene contains "cat") for summer/cherry/david
summer_table = summer_table_all;
cct_values = cell2mat(summer_table.CCT);
idx_cct = cct_values == 6500;
if iscell(summer_table.scene)
    scene_chars = cellfun(@char, summer_table.scene, 'UniformOutput', false);
    idx_scene = cellfun(@(x) contains(x, "cat"), scene_chars);
else
    idx_scene = contains(summer_table.scene, "cat");
end
idx = idx_cct & idx_scene;
summer_table = summer_table(idx, :);

david_table_file = fullfile("D:\work\ZJU_entire_skin\David\Naturalness model\Jason's final project\data analysis\res\separate_skin_methods\resTable\quality\David_table.mat");
david_table_data = load(david_table_file);
david_table = david_table_data.fit_table;

David_fitRes_folder=fullfile("D:\work\ZJU_entire_skin\David\Naturalness model\Jason's final project\data analysis\res\CATed\fitRes");

David_fitRes_file=fullfile(David_fitRes_folder,"fitRes.mat");
David_fitRes_data=load(David_fitRes_file);

% Cherry table for cherry evaluation
cherry_table_file=fullfile("D:\work\ZJU_entire_skin\Cherry\software\skin colour\数据分析\分析过程\resTable\manual\cherry_ellipse_fits.mat");
cherry_table_data=load(cherry_table_file);
cherry_table = cherry_table_data.fit_table;
idx = strcmp(cherry_table.observer_type, "weighted(o:30,s:30,c:31)");
cherry_table = cherry_table(idx, :);

% OPPO (OPPO) table for OPPO evaluation
Peggy_OPPO_folder="D:\work\project_code_backup\OPPOskinExpe\analyzeResult_scaled\AnalyseResults_p\display\rela\efit_p\resTable";
Peggy_OPPO_file=fullfile(Peggy_OPPO_folder,"Peggy_OPPO_table.mat");
Peggy_OPPO_data=load(Peggy_OPPO_file);
OPPO_table=Peggy_OPPO_data.fit_table(1:52,:);

lastParts_OPPO = ["inLab","indoorAdd","outdoorAdd","sunsetAdd","nightAdd"];

% VIVO
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

output_folder=fullfile("res","pic","all_in_one");
if ~exist(output_folder,"dir")
    mkdir(output_folder);
end

% ========== 输出文件夹配置 ==========
cross_res_folder=fullfile(pwd,"cross_research_res");
if ~exist(cross_res_folder,"dir")
    mkdir(cross_res_folder);
end
% xlsx 文件名包含 ablation_type
if isempty(ablation_type)
    ablation_suffix="default";
else
    ablation_suffix=ablation_type;
end
cross_res_xlsx=fullfile(cross_res_folder,...
    sprintf("cross_research_res_%s.xlsx",ablation_suffix));

sources=["david","cherry","summer","OPPO","peggy"];
% sources=["peggy"];
for i_source=1:length(sources)
    clear("de_david","de_cherry","de_summer","de_OPPO","de_peggy")
    source=sources(i_source);
    if strcmp(source,"david")
        base_table=david_table;
    elseif strcmp(source,"cherry")
        base_table=cherry_table;
    elseif strcmp(source,"summer")
        base_table=summer_table;
    elseif strcmp(source,"OPPO")
        base_table=OPPO_table;
    elseif strcmp(source,"peggy")
        base_table=VIVO_table;

        idx_h=[];
        for i_img=1:size(base_table,1)
            scene_name=char(base_table.scene{i_img});
            blank=find(scene_name==' ');
            
            if strcmp(scene_name(blank+1),"h")
                idx_h=[idx_h;i_img];
            end

        end

    end


    
    for i_img=1:size(base_table,1)
        base_ethnicity=base_table.model_ethnicity{i_img};
        source_name=strcat(base_table.source{i_img},base_ethnicity);
        if strcmp(base_ethnicity,"cherry")
            base_ethnicity=strrep(base_ethnicity,"(YY)","");
            base_ethnicity=strrep(base_ethnicity,"(YO)","");
        end
        scene_char=char(base_table.scene{i_img});
        blank=find(scene_char==' ');
        lastPart_OPPO=scene_char(1:blank-1);
        points_base=base_table.lab_values{i_img};
        scores_base=base_table.opinion_scores{i_img};
        if strcmp(source,"david")
            points_base=points_base(2:17,:);
            scores_base=scores_base(2:17,:);
        elseif strcmp(source,"cherry")||strcmp(source,"OPPO")
            points_base=points_base(1:16,:);
            scores_base=scores_base(1:16,:);
        end
        par_base=base_table.par{i_img};
        if size(par_base,1)>1
            par_base=par_base';
        end
        ave_base=base_table.average_lab{i_img};
        if strcmp(source,"summer")
            cen_base=[ave_base(1),par_base(1,5:6)];  
        elseif strcmp(source,"VIVO")||strcmp(source,"peggy")
            cen_base=[ave_base(1),par_base(1,4:5)];  
        else
            cen_base=par_base(1,5:7);        
        end
        xyz_cen_base=lab2xyz(cen_base,"d65_64");

        if strcmp(base_ethnicity,"African")
            i_david=0;i_cherry=1;i_summer=1;
        elseif strcmp(base_ethnicity,"South Asian")
            i_david=0;i_cherry=2;i_summer=4;
        elseif contains(base_ethnicity,"Oriental")||strcmp(base_ethnicity,"Asian")
            i_david=4;i_cherry=3;i_summer=3;
        elseif strcmp(base_ethnicity,"Caucasian")
            i_david=5;i_cherry=4;i_summer=2;
        end


        if strcmp(source,"david")&&ismember(base_table.model_id{i_img},["skin_9","skin_10"])
            i_OPPO=4;lastPart_OPPO="outdoorAdd";
        elseif strcmp(source,"cherry")||strcmp(source,"summer")
            i_OPPO=1;lastPart_OPPO="inLab";
        else
            scene_char=char(base_table.scene{i_img});
            blank=find(scene_char==' ');
            lastPart_OPPO=scene_char(1:blank-1);
            for i_OPPO=1:length(lastParts_OPPO)
                if strcmp(lastPart_OPPO,lastParts_OPPO(i_OPPO))
                    break
                end
            end

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
        par_summer=summer_table.par{i_summer};
        cen_summer=summer_table.lab_center{i_summer};
        cen_summer_ori=cen_summer;
        
        lab_cen_summer=cen_summer;
        xyz_cen_summer=lab2xyz2(lab_cen_summer,"d65_64");
        xyz_cen_summer1=xyz_cen_summer./xyz_cen_summer(2).*xyz_cen_base(2);
        lab_cen_summer1=xyz2lab(xyz_cen_summer1,"d65_64");
        par_summer(1,5:6)=lab_cen_summer1(1,2:3);
        cen_summer=[cen_base(1),par_summer(1,5:6)];
        
    
        y_summer=cal_y(par_summer,points_base,"ellipsoidfit5");
        [r_summer(i_img,1)] = corr(y_summer, scores_base, 'Type', 'Pearson'); 
        de_summer(i_img,1)=deltaE2000(cen_summer,cen_base);
        de_summer1(i_img,:)=[cen_summer,cen_base,de_summer(i_img,1)];

        de_summer_ori(i_img,1)=deltaE2000(cen_summer_ori,cen_base);
        de_summer_ori1(i_img,:)=[cen_summer_ori,cen_base,de_summer_ori(i_img,1)];
    
        %david
        lab_cen_david=cen_david;
        cen_david_ori=cen_david;

        xyz_cen_david=lab2xyz2(lab_cen_david,"d65_64");
        xyz_cen_david1=xyz_cen_david./xyz_cen_david(2).*xyz_cen_base(2);
        lab_cen_david1=xyz2lab(xyz_cen_david1,"d65_64");
        par_david(1,5:7)=lab_cen_david1;
        cen_david=par_david(1,5:7);
        
    
        y_david=cal_y(par_david,points_base,"ellipsoidfit4");
        r_david(i_img,1) = corr(y_david, scores_base, 'Type', 'Pearson');
        de_david(i_img,1)=deltaE2000(cen_david,cen_base);
        de_david1(i_img,:)=[cen_david,cen_base,de_david(i_img,1)];

        de_david_ori(i_img,1)=deltaE2000(cen_david_ori,cen_base);
        de_david_ori1(i_img,:)=[cen_david_ori,cen_base,de_david_ori(i_img,1)];
    
        %cherry
        par_cherry=cherry_fitRes_data.par_all(i_cherry,:);
        cen_cherry=par_cherry(1,5:7);
    
        lab_cen_cherry=cen_cherry;
        cen_cherry_ori=cen_cherry;

        xyz_cen_cherry=lab2xyz2(lab_cen_cherry,"d65_64");
        xyz_cen_cherry1=xyz_cen_cherry./xyz_cen_cherry(2).*xyz_cen_base(2);
        lab_cen_cherry1=xyz2lab(xyz_cen_cherry1,"d65_64");
        par_cherry(1,5:7)=lab_cen_cherry1;
        cen_cherry=par_cherry(1,5:7);
        
    
        y_cherry=cal_y(par_cherry,points_base,"ellipsoidfit3_1");
        r_cherry(i_img,1) = corr(y_cherry, scores_base, 'Type', 'Pearson');
        de_cherry(i_img,1)=deltaE2000(cen_cherry,cen_base);
        de_cherry1(i_img,:)=[cen_cherry,cen_base,de_cherry(i_img,1)];

        de_cherry_ori(i_img,1)=deltaE2000(cen_cherry_ori,cen_base);
        de_cherry_ori1(i_img,:)=[cen_cherry_ori,cen_base,de_cherry_ori(i_img,1)];
    
        %peggy
        % 从场景名中提取 rs 序号作为 scene_idx（仅 scene_types 模式需要）
        scene_idx_peggy = [];
        if strcmp(ablation_type, "scene_types")
            scene_char_peggy = char(base_table.scene{i_img});
            rs_match = regexp(scene_char_peggy, 'rs(\d+)', 'tokens');
            if ~isempty(rs_match)
                scene_idx_peggy = str2double(rs_match{1}{1});
            end
        end
        [y_peggy,par_peggy,characteristics(i_img,:)]=predict_my(ave_base(1),points_base,1,"01Preference",ablation_type,scene_idx_peggy);
        cen_peggy=[ave_base(1),par_peggy(1,4:5)];
        [r_peggy(i_img,1)] = corr(y_peggy, scores_base, 'Type', 'Pearson');    
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
    
        lab_cen_OPPO=cen_OPPO;
        cen_OPPO_ori=cen_OPPO;

        xyz_cen_OPPO=lab2xyz2(lab_cen_OPPO,"d65_64");
        xyz_cen_OPPO1=xyz_cen_OPPO./xyz_cen_OPPO(2).*xyz_cen_base(2);
        lab_cen_OPPO1=xyz2lab(xyz_cen_OPPO1,"d65_64");
        par_OPPO(1,5:7)=lab_cen_OPPO1;
        cen_OPPO=par_OPPO(1,5:7);
    
        y_OPPO=cal_y(par_OPPO,points_base,"ellipsoidfit5");
        [r_OPPO(i_img,1)] = corr(y_OPPO, scores_base, 'Type', 'Pearson'); 
        de_OPPO(i_img,1)=deltaE2000(cen_OPPO,cen_base);
        de_OPPO1(i_img,:)=[cen_OPPO,cen_base,de_OPPO(i_img,1)];

        de_OPPO_ori(i_img,1)=deltaE2000(cen_OPPO_ori,cen_base);
        de_OPPO_ori1(i_img,:)=[cen_OPPO_ori,cen_base,de_OPPO_ori(i_img,1)];
    
        cens{i_source,i_img}=[cen_david;cen_cherry;cen_summer;cen_OPPO;cen_peggy];
    
        % figure(1);hold on;
        % plot(points_base(:,2),points_base(:,3),  'o', 'Color', 'b', 'MarkerSize', 6);
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
    result(i_source,:)=[nanmean(de_david),nanmean(de_cherry),...
        nanmean(de_summer),nanmean(de_OPPO),nanmean(de_peggy)]

    if strcmp(source,"peggy")
        idx_h_david=find(abs(de_david_ori1(:,4)-de_david_ori1(:,1))<5);
        idx_h_cherry=find(abs(de_cherry_ori1(:,4)-de_cherry_ori1(:,1))<5);
        idx_h_summer=find(abs(de_summer_ori1(:,4)-de_summer_ori1(:,1))<5);
        idx_h_OPPO=find(abs(de_OPPO_ori1(:,4)-de_OPPO_ori1(:,1))<5);

        result_ori(i_source,:)=[nanmean(de_david_ori(idx_h_david,:)),...
            nanmean(de_cherry_ori(idx_h_cherry,:)),...
            nanmean(de_summer_ori(idx_h_summer,:)),...
            nanmean(de_OPPO_ori(idx_h_OPPO,:)),...
            nanmean(de_peggy)]

        de_david_ori2=de_david_ori1(idx_h_david,:);
        de_cherry_ori2=de_cherry_ori1(idx_h_cherry,:);
        de_summer_ori2=de_summer_ori1(idx_h_summer,:);
        de_OPPO_ori2=de_OPPO_ori1(idx_h_OPPO,:);

    else
        result_ori(i_source,:)=[nanmean(de_david_ori),nanmean(de_cherry_ori),...
        nanmean(de_summer_ori),nanmean(de_OPPO_ori),nanmean(de_peggy)]
    end


 
end

%%

% ========== 输出 result 和 result_ori 到 xlsx ==========
model_names=["David","Cherry","Summer","OPPO","STIM"];  % 列名
source_labels=sources;  % 行名 = david/cherry/summer/OPPO/peggy

% --- Sheet 1: result ---
ws_result=result;  % size: length(sources) x 5
writetable(array2table(ws_result,'VariableNames',model_names,'RowNames',source_labels),...
    cross_res_xlsx,'Sheet','result');

% --- Sheet 2: result_ori ---
ws_result_ori=result_ori;
writetable(array2table(ws_result_ori,'VariableNames',model_names,'RowNames',source_labels),...
    cross_res_xlsx,'Sheet','result_ori');

fprintf("已输出 cross_research_res 至: %s\n",cross_res_xlsx);
fprintf("  Sheet 'result':     %d x %d\n",size(result,1),size(result,2));
fprintf("  Sheet 'result_ori': %d x %d\n",size(result_ori,1),size(result_ori,2));