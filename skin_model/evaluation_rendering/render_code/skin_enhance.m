function [outnew] = skin_enhance(img, bull, average,string, ...
    dlab,XYZ,noFaceRGB_file,if_wei,par,enhance_type)
% ======================================
% 函数名称：img_AddRender_simp
% 功能：基于颜色差值的图像渲染
% 输入：
%   img       - 原图（RGB格式，0-1范围）
%   bull      - 面部遮罩（二值图，白色为面部区域）
%   bull_nosd - 无阴影遮罩（用于处理阴影区域）
%   string    - 渲染模式（'LUT'/'srgb'）
%   delta_Lab - 目标Lab差值（[ΔL, Δa, Δb]）
%   XYZ       - 原图XYZ值（通过calibration获取）
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


    datai_file = '..\..\calibration\display_model\datai_ipv35_3.mat';
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
    
    delta_Lab=dlab-average;
    %-------skin enhance------------
    if strcmp(enhance_type,"None")
        delta_Lab=repmat(delta_Lab,size(lab1,1),1);
    else
        dlab=repmat(dlab,size(lab1,1),1);
        alpha=-log(par(6));
        dp = (par(1) .* (lab1(:,2) - dlab(:,2)).^2 + ...
            par(2) .* (lab1(:,3) - dlab(:,3)).^2 + ...
            par(3) .* (lab1(:,2) - dlab(:,2)) .* (lab1(:,3) - dlab(:,3)))./ (alpha).^2;
        if strcmp(enhance_type,"cherry")
            w=(max(dp)-dp)./(max(dp)-min(dp));
        elseif strcmp(enhance_type,"zeng")
            w=1-dp;
        end
        f=1;
        delta_Lab=w.*f.*repmat(delta_Lab, length(lab1), 1);
        
        % 新增高光保护策略
        % 1. 定义高光阈值(可根据实际需求调整)
        highlight_threshold = 70;  % L* > 70 判定为高光区域
        L = lab1(:,1);  % 提取亮度通道
        protect_type="hue_only";
        % 2. 根据protect_type选择高光保护策略
        if strcmp(protect_type, "reduce_weight")
            % 策略1: 降低高光区域的调整权重
            % 计算亮度衰减系数 (高光区域权重线性衰减)
            w_highlight = min(1,max(0, 1 - (L - highlight_threshold) / (100 - highlight_threshold)));
            % 应用高光权重修正
            delta_Lab = delta_Lab .* repmat(w_highlight, 1, 3);
            
        elseif strcmp(protect_type, "hue_only")
            % 策略2: 仅调整色相，保持彩度
            
            % 计算原始彩度和色相
            C_orig = sqrt(lab1(:,2).^2 + lab1(:,3).^2);  % 原始彩度
            
            % 计算调整后的a*b* (来自原有delta_Lab)
            a_adjusted = lab1(:,2) + delta_Lab(:,2);
            b_adjusted = lab1(:,3) + delta_Lab(:,3);
            
            % 计算调整后的色相
            h_adjusted = atan2(b_adjusted, a_adjusted);
            
            % 计算亮度过渡系数 (控制彩度融合程度)
            w_L = min(1,max(0, 1 - (L - highlight_threshold) / (100 - highlight_threshold)));
            % 融合彩度: 高光区域保留原始彩度，非高光区域使用调整后彩度
            C_adjusted = sqrt(a_adjusted.^2 + b_adjusted.^2);  % 调整后彩度
            C_final = C_orig + w_L .* (C_adjusted - C_orig);
            
            % 用调整后的色相和融合后的彩度重构a*b*
            a_final = C_final .* cos(h_adjusted);
            b_final = C_final .* sin(h_adjusted);
            
            % 更新delta_Lab的a*b*分量
            delta_Lab(:,2) = a_final - lab1(:,2);
            delta_Lab(:,3) = b_final - lab1(:,3);
            % 亮度分量保持不变(不调整L*)
            delta_Lab(:,1) = 0;
        end
    end
    
    % 应用最终调整
    lab2 = lab1 + delta_Lab;

    [xyz2] = lab2xyz2(lab2,'user',wd65_scaled);
    xyz2(logicalIndex, :) = xyz1(logicalIndex, :);
%%
    
    if strcmp(string,"srgb")
        xyz2=xyz2./XYZw_LUT(2).*100;
        rgbnew = xyz2srgb(xyz2);
    elseif strcmp(string,"LUT")

        datafile = '..\..\calibration\display_model\data_ipv35_3.mat';

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
