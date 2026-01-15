function [nation,i_nation,nation_serial]= find_nation(model)
    nations = ["AS", "CA", "SA", "AF"];
    new_names{1} = [ "f04", "f05", "f06", "m04", "m05", "m06"];
    new_names{2} = ["f01", "f02", "f03", "m01", "m02", "m03"];
    new_names{3} = [ "f07", "f08","m07", "m08"];
    new_names{4} = [ "f09", "f10","m09", "m10"];
    for i_nation=1:length(new_names)
        if ismember(model,new_names{i_nation})
            nation=nations(i_nation);
            nation_serial=strcat(num2str(i_nation),nation);
            break
        end
    end


end