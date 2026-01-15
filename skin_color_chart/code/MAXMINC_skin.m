function [numSelect] = MAXMINC_skin(lab, k)
% lab space 
%% the first sample with max L*
[~, numSelect] = max(lab(:, 1));

%% more
for i = 2: k
    numRest = setdiff(1: size(lab, 1), numSelect);
    dismin = zeros(1, length(numRest));
    for j = 1: length(numRest)
        dis = sum((lab(numSelect,:) - lab(numRest(j),:)).^2, 2);
        dismin(j) = min(dis);
    end
    [~, tmp] = max(dismin);
    numSelect(i) = numRest(tmp);
end
