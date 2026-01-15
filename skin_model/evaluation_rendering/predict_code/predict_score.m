function [y_scaled,y]=predict_score(skin_type,input,input_type,attribute,CCT,obs_type)
    %skin_type："f04", "f05", "f06","m04", "m05", "m06"之一
    %RGB：图片肤色RGB均值
    %attribute：数字，从1-10，分别代表     "Preference",
    % "Attractiveness", "Feminine", "Cooperative", ...
    % "Youth", "Healthy", "Fidelity","Harmony", "Fair", "Ruddy"
    %obs_type:分 non_model\model_group\model\all 四种情况

    %输出：y_scaled: 0-1范围内的图片得分
    %CCT：图片色温

    %算lab
    datai_file = '..\..\calibration\display_model\datai_ipv35_3.mat';
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
    CT = [3000, 4000, 5000, 6000, 6500, 7000, 8000]';
    [~,idx_CT]=min(abs(CT-CCT));

    %选择lightness_level
    model=skin_type;
    i_type=select_type(model);

    average_hml=[53.5108   14.0333   23.3488;39.2674   10.9477   18.9210;16.4238    6.3844   10.4384];

    [~,idx_ave]=min(abs(average_hml(:,1)-mean(lab(:,1),1)));
    start_idx=[1,8,15];
    idx_par=start_idx(idx_ave)-1+idx_CT;
    %CAT
    lab_aft=CAT_lab2lab1(lab,"ZJUCAT",CCT,"back");
    C_aft=sqrt(lab_aft(:,2).^2+lab_aft(:,3).^2);

    %加载par
    
    attribute_names = ["Preference", "Attractiveness", "Feminine", "Cooperative", ...
        "Youth", "Healthy", "Fidelity","Harmony", "Fair", "Ruddy"];
    lastPart=strcat(skin_type,"i");
    attribute_serial = strcat(sprintf("%02d", attribute), attribute_names(attribute));
    ellipPara_file=fullfile('..\..\data\ellipse_para',lastPart,obs_type, ...
        attribute_serial, ...
        'ellipPara\fitRes.mat');
    %计算
    if exist(ellipPara_file,"file")
        ellipPara=load(ellipPara_file);        
        par=ellipPara.par_all(idx_par,:);

        y=calculate_y(lab_aft(:,2),lab_aft(:,3),par);
        y_cen=calculate_y(par(1,4),par(1,5),par);
        y_scaled=y./y_cen;
    else
        y=NaN;
        y_scaled=NaN;
    end
    

end
