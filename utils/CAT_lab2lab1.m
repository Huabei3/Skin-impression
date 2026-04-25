function lab_aft=CAT_lab2lab1(lab_bf,Dtype,CCT,direction)
    wd65_64 = [94.811, 100.00, 107.304];
    XYZw_pre = CCT2xyz(CCT);
    for i_input=1:size(lab_bf,1)    
        
        XYZ_bf(i_input, :) = lab2xyz2(lab_bf(i_input, :), 'd65_64');
        [~, duv, S_out] = xyz2CCT(XYZw_pre, 10);
        if strcmp(Dtype,'ZJUCAT')
            a=[0.9015  500.0089];
            D=a(1).*(1-a(2)./CCT);
        end
        if strcmp(direction,"fore")
            XYZ_aft(i_input, :) = CAT16_D(XYZ_bf(i_input, :),  wd65_64,XYZw_pre, D);
            XYZ_aft1(i_input, :) = CAT16_D(XYZ_aft(i_input, :), XYZw_pre, wd65_64, D);
        elseif strcmp(direction,"back")
            XYZ_aft(i_input, :) = CAT16_D(XYZ_bf(i_input, :),  XYZw_pre,wd65_64, D);
        end

        lab_aft(i_input, :) = xyz2lab(XYZ_aft(i_input, :), 'd65_64');

    
    end


end