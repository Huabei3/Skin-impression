function out_img = process_outside_crop_rect(img, crop_rect,i)
    % outnew 是(targetwhite)标准D65，Y=100作为参考白时的结果，图像亮度Y归一化到0-100，所有像素的xyz均乘以亮度系数kL，可以作为渲染结果使用，因为参考光源恒定为D65，Y=100
    % outxyz同理，使用Y=100标准D65转换到lab
    % 获取图像的尺寸
    [m, n, p] = size(img);
    % 创建一个与图像同样大小的逻辑矩阵，表示所有区域都为1（默认全为crop_rect以外区域）
    logicalIndexMatrix = true(m, n);    
    % 设置 crop_rect 区域内的逻辑值为0
    logicalIndexMatrix(crop_rect(2):(crop_rect(2) + crop_rect(4) - 1), crop_rect(1):(crop_rect(1) + crop_rect(3) - 1)) = false;
    % 将逻辑矩阵展开为一维数组
    logicalIndex = reshape(logicalIndexMatrix, [m * n, 1]);

    matrix = 3;
    % outnew2 是(targetwhite)D65，亮度保持原图亮度的结果，xyz没有乘系数，而是参考白D65的亮度Y=100*kL,可以用作白平衡，因为每个参考白都根据图片亮度做了适应
    switch string
        case 'srgb'
            matrix = 1;
        case 'polynomial'
            matrix = 2;
        case 'LUT'
            matrix = 3;
    end

    [m, n, p] = size(img);
    out = reshape(img, [m * n, p]); % 展开
    % xyz2 = zeros(size(out));


%     datai_file = 'Z:\homes\Peggy\oppoSkinExperi\LUT3d\results\datai_sorted53_3OV.mat';
    datai_file = 'Z:\homes\Peggy\oppoSkinExperi\LUT3d\results\datai_sorted40_3.mat';

    % RGB 转换到 XYZ
    if matrix == 1
        xyz = srgb2xyz(out);
    elseif matrix == 2
        xyz = rgb2xyz(out, w);
    elseif matrix == 3
        out = out * 255;
        xyz = lut3d_rgb2xyz1(out(logicalIndex==true,:), datai_file);
        disp(['lut3d_rgb2xyz1 over: ' datestr(now, 'yyyy-mm-dd HH:MM:SS')]);

    end


%%
    

    if matrix==1
        % [rgbnew, flag,out_of_gamut_ratio] = xyz2srgb(xyz(logicalIndex==true),:);
    elseif matrix==3
        datafile = 'Z:\homes\Peggy\oppoSkinExperi\LUT3d\results\data_sorted40_3.mat';    
        % 检查缓存文件是否存在
        cache_file = sprintf("outRect%02d.mat",i);
        if isfile(cache_file)
            % 如果缓存文件存在，加载保存的结果
            load(cache_file, 'outRectRGB');
        else
            % 如果缓存文件不存在，对 outRect 的部分进行计算并保存
            if any(logicalIndex)
                [outRectRGB,out_of_gamut_ratio] = lut3d_xyz2rgbIpv_bfCashe(xyz, datafile);
                save(cache_file, 'outRectRGB');
            else
                outRectRGB = [];
            end
        end
        
        
        % 对 insideRect 的部分进行计算
        if any(~logicalIndex)            
            [inRectRGB,out_of_gamut_ratio] = out(logicalIndex==false, :);
        else
            inRectRGB = [];
        end
    
    %     outofgamut=(cached_outofgamut+outofgamut_bull1)/(size(cachedRGB,1)+size(rgbnew_bull1,1));
    %     fprintf("outofgamut pecent\\cel%d\n",outofgamut);
        
        
        % 合并 bull_reshaped==0 和 bull_reshaped==1 的结果
        rgbnew = zeros(size(xyz));
        if ~isempty(outRectRGB)
            rgbnew(logicalIndex, :) = outRectRGB;
        end
        if ~isempty(inRectRGB)
            rgbnew(~logicalIndex, :) = inRectRGB;
        end

        rgbnew=rgbnew./255;
    end
    %%


    % 重塑输出

    out_img = reshape(rgbnew, [m, n, p]);

end
