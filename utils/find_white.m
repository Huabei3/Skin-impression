function white = find_white(picname_group)
    picname_group=lower(picname_group);
    lastPart=picname_group(1:4);
    white_file = fullfile("D:\work\VIVOskinExpe\analyze\optimizedD\whiteSquare\XYZw_white", ...
    strcat(lastPart, ".mat"));
    load(white_file,"XYZw_white");
    if contains(picname_group,'i')
        picnames_groups = ["h3k","h4k","h5k","h6k","hd65","h7k","h8k",...
                        "m3k","m4k","m5k","m6k","md65","m7k","m8k",...
                        "l3k","l4k","l5k","l6k","ld65","l7k","l8k"];
    elseif contains(picname_group,'r')
        picnames_groups = ["rs01","rs02","rs03","rs04","rs05","rs06","rs07", ...
                         "rs08","rs09","rs10","rs11","rs12","rs13","rs14"];
    end
    
    % 遍历 picname_group
    for idx = 1:length(picnames_groups)
        % 检查 input_string 是否包含当前 picname
        if contains(picname_group(5:end), picnames_groups(idx))
            % 如果包含，返回对应的 CT 值
            white = XYZw_white(idx,:);
            break; % 找到匹配项后立即返回
        end
    end

end