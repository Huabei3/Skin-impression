function [numSelect, condNumMin] = minCondN_skin(SPD, k)

%% the first sample with medium norm of spd


[~, idx1] = sort(sum(SPD.^2));
numSelect = idx1(round(length(idx1) / 2));

%% more
% for i = 2: size(SPD,2)
for i = 2: k
    numRest=setdiff(1:size(SPD,2),numSelect);
    condNum=zeros(1,length(numRest));
    for j=1:length(numRest)
        condNum(j) = cond(SPD(:,[numSelect,numRest(j)]));
    end
    [condNumMin(i),tmp]=min(condNum);
    numSelect(i)=numRest(tmp);
end
