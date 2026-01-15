function [ZWH,prob]=Williamsoverlappingdepcorr(r1x,r2x,r12,n, ntype)
%compare overlapping dependent correlation coefficients using the
%method of William's (1959).
%r1x = correlation between set 1 and set x
%r2x = correlation between set 2 and set x
%r12 = correlation between set 1 and set 2
%n  = number of samples
%ntype = two-tailed ('=') or one-tailed ('<' or '>')
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin<5;ntype='=';end

rdiff = r1x-r2x;
Rbar = (r1x+r2x)./2;
Rn=1-r1x.^2-r2x.^2-r12.^2+2.*r1x.*r2x.*r12;
den = 2*((n-1)/(n-3))*Rn+Rbar.^2.*(1-r12).^3;
ZWH=rdiff.*((n-1).*(1+r12)./den).^0.5;

prob=(1-tcdf(abs(ZWH),n-3))*2;%twotailed

switch ntype
    case '='
        %do nothing, p already calculated
    case '<' %rdiff<0 (r1<r2)
        if rdiff<0;prob=1-prob./2;else;prob=prob./2;end
    case '>' %rdiff>0 (r1>r2)
        if rdiff>0;prob=1-prob./2;else;prob=prob./2;end
end
end
