% test camera model

clear
close all
new_names=["f07","f08","f09","f10","m07","m08","m09","m10"];
for i_model=1:length(new_names)
    model=new_names(i_model);
% %---------------femaleVIVO------------

    source_folder=char(fullfile('G:\Hassel\RealScene',model,'raw\noCard'));
    dir_pic=dir(fullfile(source_folder,"*.3FR"));
    source_folder1=char(fullfile('G:\Hassel\RealScene',model,'raw\card'));
    dir_pic1=dir(fullfile(source_folder1,"*.3FR"));
    special=["rs13","rs14"];
    special_scale=[5,50];

    slashes = strfind(source_folder, '\');
    if ~isempty(slashes)
        lastPart = source_folder((slashes(1,end-2)+1:slashes(1,end-1)-1));
    end
    lastPart=[lastPart,'r'];

    dir_mask=dir(strcat("D:\work\VIVOskinExpe\renderCode\mask\",lastPart,"\*.jpg"));
    save_folder=fullfile("D:\work\VIVOskinExpe\renderCode\XYZ\rs",lastPart);
    if ~exist(save_folder,"dir")
        mkdir(save_folder);
    end
    XYZw_max_all=[];XYZw_all=[];
    wd65=[94.813  100.000  107.262];
    file_whiteSquare=(strcat("whiteSquare\" + ...
        "crop_rect_info_white_",lastPart,".mat"));
    %读取模型的曝光参数
    
    model_image_shutterspeed = 1/30;
    model_image_FNumber = 4;
    model_image_iso = 400;
    
    ratio_exceed=[];ratio_exceed1=[];ratio_exceed2=[];

    for i_pic=1:length(dir_pic)
    
        imagename = fullfile(dir_pic(i_pic).folder, dir_pic(i_pic).name);
        imagename1 = fullfile(dir_pic1(i_pic).folder, dir_pic1(i_pic).name);

        % target image info
        %算无卡的scalefactor
        cfaInfo = rawinfo(imagename);
        target_image_shutterspeed = cfaInfo.ExifTags.ExposureTime;
        target_image_FNumber = cfaInfo.ExifTags.FNumber;
        target_image_iso = cfaInfo.ExifTags.ISOSpeedRatings;
        %
        iso_scale = model_image_iso/target_image_iso;
        time_scale = model_image_shutterspeed/target_image_shutterspeed;
        Fnumber_scale=(model_image_FNumber/target_image_FNumber).^2;
        scalefactor = iso_scale*time_scale*(1/Fnumber_scale);
    
        %算有卡的scalefactor
        cfaInfo = rawinfo(imagename1);
        target_image_shutterspeed1 = cfaInfo.ExifTags.ExposureTime;
        target_image_FNumber1 = cfaInfo.ExifTags.FNumber;
        target_image_iso1 = cfaInfo.ExifTags.ISOSpeedRatings;
        %
        iso_scale1 = model_image_iso/target_image_iso1;
        time_scale1 = model_image_shutterspeed/target_image_shutterspeed1;
        Fnumber_scale1=(model_image_FNumber/target_image_FNumber1).^2;
        scalefactor1 = iso_scale1*time_scale1*(1/Fnumber_scale1);
        %过暗提亮
        if ismember(dir_pic(i_pic).name(1:end-4),special)
            spe_ind(i_pic,1)=find(strcmp(dir_pic(i_pic).name(1:end-4),special));
            scalefactor=scalefactor*special_scale(spe_ind(i_pic,1));
            scalefactor1=scalefactor1*special_scale(spe_ind(i_pic,1));
        end
    
        %% image read
        [~,linrgb] = raw2xyz(imagename); % raw图线性rgb（imresize-0.25,缩小16倍图像尺寸，可以在函数内修改）
        [~,linrgb1] = raw2xyz(imagename1);
        %% camera model
        linrgb= permute(linrgb, [2, 1, 3]);
        linrgb1= permute(linrgb1, [2, 1, 3]);
        linrgb = flipud(linrgb);
        linrgb1 = flipud(linrgb1);
    
        sz = size(linrgb);
        RGB = reshape(double(linrgb),sz(1)*sz(2),sz(3));    
        RGB1 = reshape(double(linrgb1),sz(1)*sz(2),sz(3));    
        
        RGB = min(65536, max(0, RGB));
        RGB1 = min(65536, max(0, RGB1));
    
        XYZ = cameramodel_poly1227(RGB); % 这里就是XYZ数据！！！
        XYZ1 = cameramodel_poly1227(RGB1);
    
        XYZ = XYZ*scalefactor;
        XYZ1 = XYZ1*scalefactor1;  
        XYZ=reshape(XYZ,sz);
        XYZ1=reshape(XYZ1,sz);
    
        %% 裁剪，提取白色块
   
        load(file_whiteSquare);
        gray_pos = crop_rect_info(i_pic,:);
    
        XYZ=XYZ(31:2944,26:2210,:);
        XYZ1=XYZ1(31:2944,26:2210,:);
    
        XYZw(1,:) = mean(mean(XYZ1(gray_pos(2): gray_pos(2)+30,gray_pos(1) :gray_pos(1)+30,:)));
    
    
        sz2=size(XYZ);
        XYZ_cpd_rspd=reshape(XYZ,[sz2(1)*sz2(2),sz2(3)]);
        XYZ_cpd_rspd1=reshape(XYZ1,[sz2(1)*sz2(2),sz2(3)]);
    
        [sortedValues, sortIndex] = sortrows(XYZ_cpd_rspd,2, 'descend');    
        maxValues = sortedValues(1:round(length(XYZ_cpd_rspd)/100),:);
        maxIndices = sortIndex(1:round(length(XYZ_cpd_rspd)/100),:);
        %----
        for i_mask=1:length(dir_mask)
            if strcmp(dir_pic(i_pic).name(1:end-4),dir_mask(i_mask).name(1:end-4))
                bull=imread(strcat(dir_mask(i_mask).folder,'\',dir_mask(i_mask).name));
                break
            end
        end
        [m,n,p]=size(bull);
        bull_reshaped=reshape(bull, [m * n, p])./255;
        bull_reshaped = double(bull_reshaped);
        logicalIndex = all(bull_reshaped == 0, 2);
        XYZ_face_lin=XYZ_cpd_rspd(~logicalIndex,:);

        maxRows = floor((maxIndices - 1) / sz2(1)) + 1;
        maxCols = mod(maxIndices - 1, sz2(1)) + 1;
        % 检查是否在边缘25像素以内
        validIndices = (maxRows > 25) & (maxRows <= sz2(1) - 25) & (maxCols > 25) & (maxCols <= sz2(2) - 25);
        maxRows = maxRows(validIndices);
        maxCols = maxCols(validIndices);
        maxValues = maxValues(validIndices, :);
    
        XYZw_max=mean(maxValues);
        if XYZw(2) > XYZw_max(2)
            XYZw_max = XYZw; % 如果 XYZw 的第二个元素更大，则取 XYZw
        end
        face_exceed=sum(any(XYZ_face_lin>XYZw(2),2))./length(XYZ_face_lin);
        
        if face_exceed>0.1
            XYZw_max=mean(maxValues(1:round(length(maxValues)./10),:),1);
            if XYZw(2) > XYZw_max(2)
                XYZw_max = XYZw; 
            end
        end
        datai_file = 'D:\work\VIVOskinExpe\calibResults\model3d_file_350_1deg_realP3\datai_ipv40_3.mat';
        data_file = 'D:\work\VIVOskinExpe\calibResults\model3d_file_350_1deg_realP3\data_ipv40_3.mat';
        LUT=load(datai_file);
        XYZw_LUT=LUT.XYZw;
        ratio_exceed(i_pic,1)=sum(any(XYZ_cpd_rspd>XYZw(2),2))./length(XYZ_cpd_rspd);
        ratio_exceed1(i_pic,1)=sum(any(XYZ_cpd_rspd>XYZw_max(2),2))./length(XYZ_cpd_rspd);
        ratio_exceed2(i_pic,1)=sum(any(XYZ_cpd_rspd>XYZw_LUT(2),2))./length(XYZ_cpd_rspd);
        %归一化
        if XYZw_max(2)>XYZw_LUT(2)
            XYZ_cpd_rspd=XYZ_cpd_rspd./XYZw_max(2).*XYZw_LUT(2);
            XYZ_cpd_rspd1=XYZ_cpd_rspd1./XYZw_max(2).*XYZw_LUT(2);
            XYZw_max=XYZw_LUT;
        end
        %截断
        
        % XYZ = min(XYZw_LUT(2), max(0, XYZ));
        % XYZ1 = min(XYZw_LUT(2), max(0, XYZ1));
        XYZ = min(XYZw_max(2), max(0, XYZ));
        XYZ1 = min(XYZw_max(2), max(0, XYZ1));
        XYZ_cpd_rspd = min(XYZw_max(2), max(0, XYZ_cpd_rspd));
        XYZ_cpd_rspd1 = min(XYZw_max(2), max(0, XYZ_cpd_rspd1));
        
        %reshape回来
        XYZ_cropped=reshape(XYZ_cpd_rspd,[sz2(1),sz2(2),sz2(3)]);
        XYZ1_cropped=reshape(XYZ_cpd_rspd1,[sz2(1),sz2(2),sz2(3)]);
       
        XYZ_dspd(:,:,1)=imresize(XYZ_cropped(:,:,1),[floor(sz2(1)/1),floor(sz2(2)/1)]);
        XYZ_dspd(:,:,2)=imresize(XYZ_cropped(:,:,2),[floor(sz2(1)/1),floor(sz2(2)/1)]);
        XYZ_dspd(:,:,3)=imresize(XYZ_cropped(:,:,3),[floor(sz2(1)/1),floor(sz2(2)/1)]);
        XYZ_dspd_rspd=reshape(XYZ_dspd,[floor(sz2(1)/1)*floor(sz2(2)/1),sz2(3)]);
        % RGB_cropped = lut3d_xyz2rgbKD(XYZ_dspd_rspd,data_file);
        RGB_cropped = xyz2srgb(XYZ_dspd_rspd);
        RGB_cropped = uint8(RGB_cropped);
        RGB_cropped = reshape(RGB_cropped,[floor(sz2(1)/1),floor(sz2(2)/1),sz2(3)]);
        % close
        figure(1)
        imshow(RGB_cropped);
        h2=figure(2);
        imshow(RGB_cropped.*(bull./255));
        outputFolder=fullfile("fdQst\noCard",lastPart);
        if ~exist(outputFolder,"dir")
            mkdir(outputFolder)
        end
        exportgraphics(h2,fullfile(outputFolder,strcat(dir_pic(i_pic).name(1:end-4),".jpg")),"Resolution",150);
    
    
        RGB_cropped1 = xyz2srgb(reshape(XYZ1_cropped,[sz2(1)*sz2(2),sz2(3)]));
        RGB_cropped1 = uint8(RGB_cropped1);
        RGB_cropped1 = reshape(RGB_cropped1,[floor(sz2(1)),floor(sz2(2)),sz2(3)]);
        % close
        h3=figure(3);
        imshow(RGB_cropped1);  
        hold on; 
        rectangle('Position', [gray_pos(1), gray_pos(2), 30, 30], 'EdgeColor', 'r', 'LineWidth', 2);
        outputFolder=fullfile("fdQst\card",lastPart);
        if ~exist(outputFolder,"dir")
            mkdir(outputFolder)
        end
        % imwrite(RGB_cropped1,fullfile(outputFolder,strcat(dir_pic(i_pic).name(1:end-4),".jpg")));
        exportgraphics(h3,fullfile(outputFolder,strcat(dir_pic(i_pic).name(1:end-4),".jpg")),"Resolution",150);
        % plot(floor(maxRows(:,1)/1), floor(maxCols(:,1)/1), 'ro',"LineWidth",0.4,"MarkerSize",3); % 使用红色圆圈标记
    
    
        % 标注信息
        interv=50;
        text(20, 1*interv, ['Model Shutter Speed: 1/' num2str(1./model_image_shutterspeed)], 'Color', 'red', 'FontWeight', 'bold');
        text(20, 2*interv, ['Shutter Speed: 1/' num2str(1./target_image_shutterspeed)], 'Color', 'red', 'FontWeight', 'bold');
        text(20, 3*interv, ['Time Scale: ' num2str(time_scale)], 'Color', 'red', 'FontWeight', 'bold');
    
        text(20, 5*interv, ['Model F-Number: ' num2str(model_image_FNumber)], 'Color', 'red', 'FontWeight', 'bold');
        text(20, 6*interv, ['F-Number: ' num2str(target_image_FNumber)], 'Color', 'red', 'FontWeight', 'bold');
        text(20, 7*interv, ['F-Number Scale: ' num2str(Fnumber_scale)], 'Color', 'red', 'FontWeight', 'bold');
    
        text(20, 9*interv, ['Model ISO: ' num2str(model_image_iso)], 'Color', 'red', 'FontWeight', 'bold'); 
        text(20, 10*interv, ['ISO: ' num2str(target_image_iso)], 'Color', 'red', 'FontWeight', 'bold');
        text(20, 11*interv, ['ISO Scale: ' num2str(iso_scale)], 'Color', 'red', 'FontWeight', 'bold');
    
        text(20, 13*interv, ['Scale Factor: ' num2str(scalefactor)], 'Color', 'red', 'FontWeight', 'bold');
    
        % outputFolder=fullfile("fdQst\fdQst_maxw1\LUT",lastPart);
        % if ~exist(outputFolder,"dir")
        %     mkdir(outputFolder);
        % end
        % saveas(1,fullfile(outputFolder,strcat(dir_pic(i_pic).name(1:end-4),".jpg")));
    
        % RGB_cropped = xyz2srgb(XYZ_cpd_rspd);
        % RGB_cropped = uint8(RGB_cropped);
        % RGB_cropped = reshape(RGB_cropped,sz2);
        % figure(2)
        % hold on;            
        % imshow(RGB_cropped)
    
    %----------
        output_folder=fullfile(save_folder,"XYZw_max_all");
        if ~exist(output_folder,"dir")
            mkdir(output_folder);
        end
    
        XYZw_max_all=[XYZw_max_all;XYZw_max];
        wd65_scaled2max=wd65./wd65(2).*XYZw_max(2);
        save(fullfile(save_folder,strcat(lastPart,"_",dir_pic(i_pic).name(1:end-4),".mat")), ...
            "XYZ_cropped","XYZw_max","wd65_scaled2max","XYZw");
    
    
    
    end
end
% save(fullfile(output_folder,strcat(lastPart,"_XYZw_max_all.mat")), ...
%         "XYZw_max_all","XYZw_all");