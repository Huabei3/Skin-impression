function [outnew,dest_lab,bull_nosd] = img_AddRender_simp(img, bull,bull_nosd, string, ...
    delta_Lab,XYZ,noFaceRGB_file,if_wei,if_2mask)
% ======================================
% 函数名称：img_AddRender_simp
% 功能：基于颜色差值的图像渲染
% 输入：
%   img       - 原图（RGB格式，0-1范围）
%   bull      - 面部遮罩（二值图，白色为面部区域）
%   bull_nosd - 无阴影遮罩（用于处理阴影区域）
%   string    - 渲染模式（'LUT'/'srgb'）
%   delta_Lab - 目标Lab差值（[ΔL, Δa, Δb]）
%   XYZ       - 原图XYZ值（通过A_characterization获取）
%   noFaceRGB_file- 保存非面部区域RGB值，这样一组图片只用渲染一次非肤色区域
%   if_wei      - 是否对肤色边缘（如发际线）区域的mask赋予透明度，使得看起来自然一点
%   if_2mask - 是否应用两个mask（bull_nosd提取average肤色，bull用于渲染）
% 输出：
%   outnew    - 渲染后的RGB图像
%   dest_lab  - 渲染后的平均Lab值
% 依赖：
%   xyz2lab.m      - XYZ转Lab
%   lab2xyz2.m     - Lab转XYZ
%   lut3d_xyz2rgbKDitp1.m - LUT色域映射函数
% ======================================


    
    [m, n, p] = size(img);
    out = reshape(img, [m * n, p]); 
    [logicalIndex,bull_weight]=read_bull(bull,if_wei);
    [logicalIndex_nosd,bull_weight_nosd]=read_bull(bull_nosd,if_wei);


    datai_file = '..\..\A_characterization\display_model\datai_ipv35_3.mat';
    wd65=[94.813  100.000  107.262];
    LUT=load(datai_file);
    XYZw_LUT=LUT.XYZw;
    wd65_scaled=wd65./100.*XYZw_LUT(2);

    if strcmp(string,"srgb")
         xyz1= reshape(XYZ, [m * n, p]);
        % xyz1 = srgb2xyz(out);
        % xyz1=xyz1./100.*XYZw_LUT(2);

    elseif strcmp(string,"LUT")
        % out = out * 255;
        % xyz1 = lut3d_rgb2xyz1(out, datai_file);
        xyz1= reshape(XYZ, [m * n, p]);

        disp(['lut3d_rgb2xyz1 over: ' datestr(now, 'yyyy-mm-dd HH:MM:SS')]);

    end

    [lab1] = xyz2lab(xyz1,'user',wd65_scaled);

    lab2=lab1 + repmat(delta_Lab, length(lab1), 1).*bull_weight;
    sd_idx=(~logicalIndex)&(logicalIndex_nosd);
    lab2(sd_idx,2)=max(0,lab2(sd_idx,2));    
    lab2(sd_idx,3)=max(0,lab2(sd_idx,3));
    if if_2mask
        [dest_lab]=get_average(lab2,bull_nosd,if_wei);
    else
        [dest_lab]=get_average(lab2,bull,if_wei);
    end

    [xyz2] = lab2xyz2(lab2,'user',wd65_scaled);
    xyz2(logicalIndex, :) = xyz1(logicalIndex, :);
%%
    
    if strcmp(string,"srgb")
        xyz2=xyz2./XYZw_LUT(2).*100;
        rgbnew = xyz2srgb(xyz2);
    elseif strcmp(string,"LUT")

        datafile = '..\..\A_characterization\display_model\data_ipv35_3.mat';

        if ~exist(noFaceRGB_file,"file")
            noFaceRGB=lut3d_xyz2rgbKDitp1(xyz2(logicalIndex, :), datafile);
            save(noFaceRGB_file,"noFaceRGB");
        else
            load(noFaceRGB_file);
        end

        [rgbnew_bull1,out_of_gamut_ratio] = lut3d_xyz2rgbKDitp1(xyz2(~logicalIndex, :), datafile);
        % disp(strcat("out_of_gamut_ratio:",double2str(out_of_gamut_ratio)));
        rgbnew = zeros(size(xyz2));
        if ~isempty(noFaceRGB)
            rgbnew(logicalIndex, :) = noFaceRGB;
        end
        if ~isempty(rgbnew_bull1)
            rgbnew(~logicalIndex, :) = rgbnew_bull1;
        end
        
    end
    %%
    rgbnew=rgbnew./255;
    outxyz = reshape(xyz2, [m, n, p]);
    outnew = reshape(rgbnew, [m, n, p]);
end
