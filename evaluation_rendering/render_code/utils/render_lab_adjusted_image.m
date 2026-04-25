function render_lab_adjusted_image(lab_img_lin, logicalIndex, average, cen_target_lab, sz, output_folder, subfolder_name, img_name)
    % 输入参数说明：
    % lab_img_lin: 展平后的lab图像数据
    % logicalIndex: 掩码逻辑索引
    % average: 原始lab均值
    % cen_target_lab: 目标中心lab坐标
    % sz: 原始图像尺寸 [h,w,c]
    % output_folder: 根输出文件夹
    % subfolder_name: 子文件夹名（如"cen_david"/"cen_cherry"）
    % img_name: 图片名（不含后缀）
    
    % 1. 调整lab值
    lab_adjusted = lab_img_lin;
    lab_face = lab_adjusted(~logicalIndex, :);
    delta_lab = cen_target_lab - average;
    lab_face = lab_face + repmat(delta_lab, size(lab_face,1), 1);
    lab_adjusted(~logicalIndex, :) = lab_face;
    
    % 2. 转换回RGB
    xyz_adjusted = lab2xyz2(lab_adjusted, "d65_64");
    rgb_adjusted = xyz2srgb(xyz_adjusted) ./ 255;
    rgb_adjusted = reshape(rgb_adjusted, [sz(1), sz(2), sz(3)]);
    
    % 3. 保存图片
    output_subfolder = fullfile(output_folder, subfolder_name);
    if ~exist(output_subfolder, "dir")
        mkdir(output_subfolder);
    end
    imwrite(rgb_adjusted, fullfile(output_subfolder, strcat(img_name, ".jpg")));
end