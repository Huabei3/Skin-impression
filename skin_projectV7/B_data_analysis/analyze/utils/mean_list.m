
%% 有用，但只对总的求平均的版本
function mean_list(filename, n_para)
    nations = ["AS", "CA", "SA", "AF"];
    
    % 定义每个人种对应的模特
    nation_models = containers.Map();
    nation_models("AS") = {'f04', 'f05', 'f06', 'm04', 'm05', 'm06'};
    nation_models("CA") = {'f01', 'f02', 'f03', 'm01', 'm02', 'm03'};
    nation_models("SA") = {'f07', 'f08', 'm07', 'm08'};
    nation_models("AF") = {'f09', 'f10', 'm09', 'm10'};
    

    % 获取所有工作表的名称
    sheetNames = sheetnames(filename);
    iOr=sheetNames{1}(end);
    for i_nation=1:length(nations)
        sheetNames_nation{i_nation}=nation_models(nations(i_nation));
        sheetNames_temp=sheetNames_nation{i_nation};
        for i_model_curr=1:length(sheetNames_temp)
            sheetNames_temp{i_model_curr}=strcat(sheetNames_temp{i_model_curr},iOr);
        end
        sheetNames_nation{i_nation}=sheetNames_temp;
    end


    % 定义 picname_group 的值
    if n_para==21
        picname_groups = ["H3K", "H4K", "H5K", "H6K", "HD65", "H7K", "H8K",...
            "M3K", "M4K", "M5K", "M6K", "MD65", "M7K", "M8K",...
            "L3K", "L4K", "L5K", "L6K", "LD65", "L7K", "L8K"];
    elseif n_para==14
        picname_groups = ["rs01", "rs02", "rs03", "rs04", "rs05",...
            "rs06", "rs07", "rs08", "rs09", "rs10",...
            "rs11", "rs12", "rs13", "rs14"];
    end



    % 遍历每个工作表
    mean_sheetNames(filename,sheetNames,"Mean",picname_groups)
    for i_nation=1:length(nations)
        mean_sheetNames(filename,sheetNames_nation{i_nation},nations(i_nation),picname_groups)
    end
end