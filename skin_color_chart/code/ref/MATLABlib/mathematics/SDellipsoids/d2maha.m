function d2 = d2maha(data,M,C)
% Calculates the mahalanobis distance(s) d2 for data given the mean M 
% and covariance matrix C
n = size(data,1);
d2 = diag((data - repmat(M,n,1))*(pinv(C)*(data - repmat(M,n,1))'));



