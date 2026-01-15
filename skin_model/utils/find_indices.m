function i_indices=find_indices(i_par,iOr)
    if iOr=='i'
        if ismember(i_par,[5])
            i_indices=1;
        elseif ismember(i_par,[12])
            i_indices=2;
        elseif ismember(i_par,[19])
            i_indices=3;

        end

    elseif iOr=='r'
        if ismember(i_par,[1,2,4,5,6])
            i_indices=1;
        elseif ismember(i_par,[3,7,8,9,10])
            i_indices=2;
        elseif ismember(i_par,[11,12])
            i_indices=3;
        elseif ismember(i_par,[13,14])
            i_indices=4;
        end

    end

end