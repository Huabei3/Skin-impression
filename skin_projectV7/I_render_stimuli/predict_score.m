function [y,lab_aft]=predict_score(skin_type,input,input_type,attribute,CCT)
    %skin_type："f04", "f05", "f06","m04", "m05", "m06"之一
    %RGB：图片肤色RGB均值
    %attribute：数字，从1-10，分别代表     "Preference",
    % "Attractiveness", "Feminine", "Cooperative", ...
    % "Youth", "Healthy", "Fidelity","Harmony", "Fair", "Ruddy"
    %CCT：图片色温

    %算lab
    datai_file = 'calibResults\model3d_file_350_1deg_realP3\datai_ipv40_3.mat';
    wd65_64=[94.813  100.000  107.262];
    LUT=load(datai_file);
    XYZw_LUT=LUT.XYZw;
    wd65_scaled=wd65_64./100.*XYZw_LUT(2);
    if strcmp(input_type,"RGB")
        RGB=input;
        RGB=double(RGB);
        if max(RGB(:,2))<=1
            RGB=RGB.*255;
        end
        xyz=lut3d_rgb2xyz1(RGB, datai_file);
        lab=xyz2lab(xyz,'user',wd65_scaled);
    elseif strcmp(input_type,"lab")
        lab=input;
    end


    %选择CT
    CT = [3000, 4000, 5000, 6000, 7000, 8000, 6500]';
    [~,idx_CT]=min(abs(CT-CCT));

    %选择lightness_level
    model=gen_lastPart_old(skin_type);
    i_type=select_type(model);
    average=load(fullfile("aveSkinByHand2\average_mods\i", ...
        strcat("average_allMod_",num2str(i_type),".mat")));
    average=average.average;
    average_hml(1,:)=mean(average(1:7,:),1);
    average_hml(2,:)=mean(average(8:14,:),1);
    average_hml(3,:)=mean(average(15:21,:),1);  
    [~,idx_ave]=min(abs(average_hml(:,1)-mean(lab(:,1),1)));
    start_idx=[1,8,15];
    idx_par=start_idx(idx_ave)-1+idx_CT;
    %CAT
    Dtype="summer";
    lab_aft=CAT_lab2lab1(lab,Dtype,CCT,"back");
    C_aft=sqrt(lab_aft(:,2).^2+lab_aft(:,3).^2);

    %加载par
    
    attribute_names = ["Preference", "Attractiveness", "Feminine", "Cooperative", ...
    "Youth", "Healthy", "Precise reproduction", "suit the environment or not",...
    "white-skinned", "ruddy"]; 
    lastPart_old=gen_lastPart_old(strcat(skin_type,"i"));
    attribute_serial = strcat(sprintf("%02d", attribute), attribute_names(attribute));
    ellipPara_file=fullfile('..\analyze\AnalyseResults',Dtype, ...
        lastPart_old,'all',attribute_serial, ...
        'ellipPara\fitRes_level.mat');
    %计算
    if exist(ellipPara_file,"file")
        ellipPara=load(ellipPara_file);        
        par=ellipPara.par_all(idx_par,:);

        y=calculate_y(lab_aft(:,2),lab_aft(:,3),par);
    else
        y=NaN;
    end


end
