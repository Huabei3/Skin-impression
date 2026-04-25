function cluster=find_cluster(pcn,i_nation)
    if i_nation~=4
        pcns = {
            ["rs06"];  % 聚类1
            ["rs01", "rs02", "rs04", "rs05", "rs13", "rs14"];  % 聚类2
            ["rs03", "rs07", "rs08", "rs10", "rs12"];  % 聚类3
            ["rs09", "rs11"] % 聚类4
        };
    else
        pcns = {
            ["rs06"]; % 聚类1
            ["rs01", "rs04", "rs05"];% 聚类2
            ["rs02", "rs13", "rs14"];% 聚类3
            ["rs03", "rs07", "rs08","rs09", "rs10", "rs11","rs12"] % 聚类4
        };
    end
    for i_cluster =1:4
        if ismember(pcn,pcns{i_cluster})
            cluster=strcat("cluster",num2str(i_cluster));
        end
    end



end