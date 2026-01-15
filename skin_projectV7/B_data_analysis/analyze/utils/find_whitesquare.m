function [XYZw_wsq] = find_whitesquare(picname_group)
   
    if contains(picname_group,'i')
        iOr='i';
    else contains(picname_group,'r')
        iOr='r';
    end
    slash=find(picname_group==iOr);
    lastPart=picname_group(1:slash(1));
    lastPart=gen_lastPart_new(lastPart);
    load(fullfile("documents\white_square",strcat(lastPart,".mat")), ...
        "XYZw","picname_check");

    for i_match = 1:length(picname_check)
        if contains(picname_group, lower(picname_check{i_match}))
            XYZw_wsq=XYZw(i_match,:);
            return 
        end
    end 

end