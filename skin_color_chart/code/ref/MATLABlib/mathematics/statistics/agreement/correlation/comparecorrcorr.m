function [Z,prob]=comparecorrcorr(r1x,r2x,r12,n, ntype)
%compare correlated correlation coefficients using the
%method of Meng Rosenthal and Ruben (1992).
%r1x = correlation between set 1 and set x
%r2x = correlation between set 2 and set x
%r12 = correlation between set 1 and set 2
%n  = number of samples
%ntype = two-tailed ('=') or one-tailed ('<' or '>')
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
r12(r12==1)=1-eps;%avoid div by zero
r1x(r1x==1)=1-eps;%avoid div by zero
r2x(r2x==1)=1-eps;%avoid div by zero
if nargin<5;ntype='=';end
z1=0.5*log((1+r1x)/(1-r1x));
z2=0.5*log((1+r2x)/(1-r2x));
rs=(r1x.^2+r2x.^2)./2;
f=(1-r12)/(2*(1-rs));
if f>1;f=1;end
h=(rs*(1-f)/(1-rs))+1;
%h=(1-f*rs)/(1-rs);

zdiff=z1-z2;
den=2*h*(1-r12);
Z=zdiff*((n-3)/den).^0.5;
prob=(1-normcdf(abs(Z)))*2;%twotailed

switch ntype
    case '='
        %do nothing, p already calculated
    case '<' %rdiff<0 (r1<r2)
        if zdiff<0;prob=1-prob./2;else;prob=prob./2;end
    case '>' %rdiff>0 (r1>r2)
        if zdiff>0;prob=1-prob./2;else;prob=prob./2;end
end



% %old code, prior to 18/09/2014
% switch ntype
%     case '='
%         zdiff=abs(z1-z2);ntailed=2;
%     case '>='
%         zdiff=z2-z1;ntailed=1;
%     case '<='
%         zdiff=z1-z2;ntailed=1;
% end
% den=2*h*(1-r12);
% 
% if den==0 & zdiff~=0;Z=Inf;else;if zdiff==0;Z=0;else;Z=zdiff*((n-3)/den).^0.5;end;end
% %p=normcdf([-Z,Z]);prob=1-(p(2)-p(1));
% prob=(1-normcdf(Z))*ntailed;
% if den==0; prob=comparecorr(r1x,r2x,n,n);disp('alternative comparisson'),end ;if den==0 & zdiff==0; prob=comparecorr(r1x,r2x,n,n);disp('alternative comparisson'),end
end
