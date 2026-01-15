function [pval,z]=comparecorr(r1,r2,n1,n2)
%compare correlation coefficients r1 & r2 using a z-test
%n (1&2) = number of samples
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin==3;n2=n1;end
r1p=0.5.*log(abs(1+r1)./abs(1-r1));
r2p=0.5.*log(abs(1+r2)./abs(1-r2));
z=(r1p-r2p)./sqrt(1./(n1-3) + 1./(n2-3));
[ztest_,pval]=ztest(z,0,1);
end