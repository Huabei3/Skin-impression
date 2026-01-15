function mcdm = MCDM(lab)
%MCDM from LAB vaules
%   lab vaules (n, 3)
n = length(lab(:, 1));
ave = mean(lab);
tmp = lab-ave.*ones(n, 1);
mcdm = sum(sum(sqrt(tmp.^2)))/n;
end

