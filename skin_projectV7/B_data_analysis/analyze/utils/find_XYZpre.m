function [CCT, XYZwpre] = find_XYZpre(picname_group)
    if contains(picname_group,'i')
        picnames_groups = ["h3k","h4k","h5k","h6k","h7k","h8k","hd65", ...
                         "l3k","l4k","l5k","l6k","l7k","l8k","ld65", ...
                         "m3k","m4k","m5k","m6k","m7k","m8k","md65"];
        dir_whiteSq=dir("..\camera model-20240924\whiteSquare\*i.mat");
        picname_group=char(picname_group);
        slash=find(picname_group=='i');
        lastPart=picname_group(1:slash(1));
        light=picname_group(slash(1)+1:end);

        for i_sq=1:length(dir_whiteSq)
            if strcmpi(lastPart,dir_whiteSq(i_sq).name(22:25))
                load(fullfile(dir_whiteSq(i_sq).folder,dir_whiteSq(i_sq).name), ...
                    "crop_rect_info","picname");
            end
        end
        for i_pic=1:length(picname)
            if strcmpi(lastPart,dir_whiteSq(i_pic).name(22:25))
                xy_sideL=crop_rect_info(i_pic, :);
            end
        end
        XYZ_file=fullfile("..\renderCode\XYZ\i",lastPart,strcat(upper(light),".mat"));
        load(XYZ_file,"XYZ_cropped");
        XYZwpre=mean(mean(XYZ_cropped(xy_sideL(2):xy_sideL(2)+xy_sideL(4), ...
            xy_sideL(1):xy_sideL(1)+xy_sideL(3),:),1),2);
        XYZwpre = reshape(XYZwpre,[1,3]);
        figure(1)
        hold on;
        imshow(XYZ_cropped./350)
        rectangle('Position', [xy_sideL(1), xy_sideL(2), xy_sideL(3), xy_sideL(4)], ...
              'EdgeColor', 'r', ...        % 矩形框的边缘颜色为红色
              'LineWidth', 2);      
        CCT = xyz2CCT(XYZwpre,10);

    elseif contains(picname_group,'r')
        picnames_groups = ["rs01","rs02","rs03","rs04","rs05","rs06","rs07", ...
                         "rs08","rs09","rs10","rs11","rs12","rs13","rs14"];
        picname_group=char(picname_group);
        slash=find(picname_group=='r');
        model=picname_group(1:slash(1)-1);
        model=gen_lastPart_new(model);
        load(fullfile("..\renderCode\light_r\model_tcp",strcat(model,".mat")), ...
            "model_tcp_mean");
        for idx = 1:length(picnames_groups)
            % 检查 input_string 是否包含当前 picname
            if contains(picname_group, picnames_groups(idx))
                % 如果包含，返回对应的 CT 值
                CCT = model_tcp_mean(idx,1);
                return; % 找到匹配项后立即返回
            end
        end
    end

end