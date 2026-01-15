function [outnew,dest_lab,bull_nosd,lab2] = img_AddRender_protected(img, bull,bull_nosd, string, ...
    delta_Lab,XYZ,noFaceRGB_file,if_wei,if_2mask)
    % outnew 鏄?(targetwhite)鏍囧噯D65锛孻=100浣滀负鍙傝?冪櫧鏃剁殑缁撴灉锛屽浘鍍忎寒搴褰掍竴鍖栧埌0-100锛屾墍鏈夊儚绱犵殑xyz鍧囦箻浠ヤ寒搴︾郴鏁発L锛屽彲浠ヤ綔涓烘覆鏌撶粨鏋滀娇鐢紝鍥犱负鍙傝?冨厜婧愭亽瀹氫负D65锛孻=100
    % outxyz鍚岀悊锛屼娇鐢╕=100鏍囧噯D65杞崲鍒發ab

    
    % outnew2 鏄?(targetwhite)D65锛屼寒搴︿繚鎸佸師鍥句寒搴︾殑缁撴灉锛寈yz娌℃湁涔樼郴鏁帮紝鑰屾槸鍙傝?冪櫧D65鐨勪寒搴=100*kL,鍙互鐢ㄤ綔鐧藉钩琛★紝鍥犱负姣忎釜鍙傝?冪櫧閮芥牴鎹浘鐗囦寒搴﹀仛浜嗛?傚簲
    switch string
        case 'srgb'
            matrix = 1;
        case 'polynomial'
            matrix = 2;
        case 'LUT'
            matrix = 3;
    end
    
    [m, n, p] = size(img);
    out = reshape(img, [m * n, p]); % 灞曞紑
    [logicalIndex,bull_weight]=read_bull(bull,if_wei);
    [logicalIndex_nosd,bull_weight_nosd]=read_bull(bull_nosd,if_wei);

    % 璁＄畻浜害绯绘暟鍜屼慨姝ｇ殑鐧界偣
    datai_file = 'calibResults\data_ipv35_3.mat';

    wd65=[94.813  100.000  107.262];
    LUT=load(datai_file);
    XYZw_LUT=LUT.XYZw;
    wd65_scaled=wd65./100.*XYZw_LUT(2);

    % RGB 杞崲鍒? XYZ
    if matrix == 1
         xyz1= reshape(XYZ, [m * n, p]);
        % xyz1 = srgb2xyz(out);
        % xyz1=xyz1./100.*XYZw_LUT(2);
    elseif matrix == 2
        xyz1 = rgb2xyz(out, w);
    elseif matrix == 3
        % out = out * 255;
        % xyz1 = lut3d_rgb2xyz1(out, datai_file);
        xyz1= reshape(XYZ, [m * n, p]);

        disp(['lut3d_rgb2xyz1 over: ' datestr(now, 'yyyy-mm-dd HH:MM:SS')]);

    end

    [lab1] = xyz2lab(xyz1,'user',wd65_scaled);

    lab2=lab1 + repmat(delta_Lab, length(lab1), 1).*bull_weight;
    face_idx=~logicalIndex;
    lab2(face_idx,2)=max(0,lab2(face_idx,2));    
    lab2(face_idx,3)=max(0,lab2(face_idx,3));
    if if_2mask
        [dest_lab]=get_average(lab2,bull_nosd,if_wei);
    else
        [dest_lab]=get_average(lab2,bull,if_wei);
    end

    [xyz2] = lab2xyz2(lab2,'user',wd65_scaled);
    xyz2(logicalIndex, :) = xyz1(logicalIndex, :);
%%
    
    if matrix==1
        xyz2=xyz2./XYZw_LUT(2).*100;
        rgbnew = xyz2srgb(xyz2);
    elseif matrix==3
        datafile = 'calibResults\data_ipv35_3.mat';
        % 
        if ~exist(noFaceRGB_file,"file")
            % noFaceRGB=lut3d_xyz2rgbLeo(xyz2(logicalIndex, :), recnew_file);
            noFaceRGB=lut3d_xyz2rgbKDitp1(xyz2(logicalIndex, :), datafile);
            save(noFaceRGB_file,"noFaceRGB");
        else
            load(noFaceRGB_file);
        end
        % [rgbnew_bull1] = lut3d_xyz2rgbLeo(xyz2(~logicalIndex, :), recnew_file);
        [rgbnew_bull1,~] = lut3d_xyz2rgbKDitp1(xyz2(~logicalIndex, :), datafile);


        rgbnew = zeros(size(xyz2));
        if ~isempty(noFaceRGB)
            rgbnew(logicalIndex, :) = noFaceRGB;
        end
        if ~isempty(rgbnew_bull1)
            rgbnew(~logicalIndex, :) = rgbnew_bull1;
        end
        rgbnew=rgbnew./255;
    end
    %%
    % 璁＄畻 xyz3 杞崲鍥? RGB 鐨勭粨鏋?

    % 閲嶅杈撳嚭
    outxyz = reshape(xyz2, [m, n, p]);
    outnew = reshape(rgbnew, [m, n, p]);
end
