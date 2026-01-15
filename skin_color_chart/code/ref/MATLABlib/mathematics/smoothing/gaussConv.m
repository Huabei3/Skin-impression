function [smoothspd,lamconv]=gaussConv(spd,sigma,type_tol,figyn)
%smooth spd, sigma = std of gaussian to use in convolution (if sigma < 0 or
%if numel(sigma)>1, sigma are the weigths of the convolution function, e.g.
%[1 1 1 1 1] = rectangular smoothing (cfr. moving average)
%type_tol: numerical input : keep only values above type_tol in the conv function
%         or  'same' or 'valid' : see "help smooth"
%figyn: 0 no plotting, 1: plot results
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin<4;figyn=0;end
delta=abs(spd(1)-spd(2));
d=(0:delta:100);
c=delta*floor(numel(d)/2);

if sigma<0 | numel(sigma)>1;
     gaussCONV=zeros(numel(d),1);gaussCONV(c/delta+1-floor(numel(sigma)/2):c/delta+1+floor(numel(sigma)/2))=abs(sigma);
else;
    gaussCONV=delta/(sqrt(2*pi*sigma^2)).*exp(-0.5*((d-c)/sigma).^2);
    gaussCONV=exp(-0.5*((d-c)/sigma).^2);
end

gaussCONV=gaussCONV./sum(gaussCONV);
if nargin<3;type_tol=1e-6;end
if ~ischar(type_tol);
    tol=type_tol
    if figyn==1;figure(1);subplot(1,2,1);hold on;plot(d,gaussCONV,'r');end
    d=d(gaussCONV>tol);gaussCONV=gaussCONV(gaussCONV>tol);
    if figyn==1;figure(1);subplot(1,2,1);hold on;plot(d,gaussCONV,'b--');end
    if isempty(gaussCONV);error('Increase tolerance!'),return;end
    spdCONV=conv(spd(:,2),gaussCONV,'valid');
    lamconv= ((spd(1,1)+delta*floor(numel(gaussCONV)/2)):delta:(spd(end,1)-delta*floor(numel(gaussCONV)/2)))';
else
    if figyn==1;figure(1);subplot(1,2,1);hold on;plot(d,gaussCONV,'r');
    figure(1);subplot(1,2,1);hold on;plot(d,gaussCONV,'b--');end
    spdCONV=conv(spd(:,2),gaussCONV,'same');
    lamconv= spd(:,1);
end
if nargin<4;figyn=0;end
if figyn==1
    subplot(1,2,2);hold on;plot(spd(:,1)',spd(:,2),'b');plot(lamconv,spdCONV,'r--');
end
if nargout<2;smoothspd=[lamconv,spdCONV];else;smoothspd=spdCONV;end