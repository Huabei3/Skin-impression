function [corr_picname]= find_corr_res(picname)
    picname=lower(picname);
    if ~contains(picname,'r')
        corr_picnames=["hd65","md65","ld65"];
        picnames_groups{1} = ["h3k","h4k","h5k","h6k","hd65","h7k","h8k"];
        picnames_groups{2} = ["m3k","m4k","m5k","m6k","md65","m7k","m8k"];
        picnames_groups{3} = ["l3k","l4k","l5k","l6k","ld65","l7k","l8k"];
        for i_grp=1:length(picnames_groups)
            if ismember(picname,picnames_groups{i_grp})
                corr_picname=corr_picnames(i_grp);
                break
            end
        end
    else
        corr_picname=picname;
    end


end