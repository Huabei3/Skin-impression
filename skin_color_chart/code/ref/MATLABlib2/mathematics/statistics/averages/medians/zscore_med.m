function X=zscore_med(X);
% Calculates a zscore-like quantity based on the median and iqr
iqrX=iqr(X);
medX=median(X);
X=(X-repmat(medX,size(X,1),1))./repmat(iqrX,size(X,1),1);