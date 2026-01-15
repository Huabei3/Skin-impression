function [Sr,duv,Sr_fcn2] = blackbodySPD(T, lb,le,stepsize);
%calculates black body radiator spectrum based on
%T= T or CIE xy coordinates or xyz 
%lb=start wavelength 
%le=end wavelength 
%stepsize= wavelength interval
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargin==1;
    lambda =(360:1:830)';
else;
    if nargin==2 & numel(lb)>1;lambda=lb;else;lambda =(360:1:830)';end
    if nargin<4;stepsize=1;end
    if nargin>=3;lambda=(lb:stepsize:le)';end
end

lb=lambda(1);le=lambda(end);stepsize=abs(lambda(1)-lambda(2));


duv=[];
switch size(T,1)
    case 2;%input = CIExy transposed (as column vector)
        [T,duv]=CCTa(xyY2xyz(T'));
        if sum(abs(duv)>5.4e-3)>0;disp('Warning: duv too large!');end
    case 3;%input=XYZ transposed (as column vector)
        [T,duv]=CCTa(T');    
        if sum(abs(duv)>5.4e-3)>0;disp('Warning: duv too large!');end
end
c1 = 3.74183e-16;
c2 =  1.4388*10^-2;
n=1.000;

Sr_fcn = @(T,lambda) (1/pi).*c1.*((repmat(lambda,1,numel(T)).*1e-9).^(-5)).*(n.^(-2)).*(exp(c2.*((n.*repmat(lambda,1,numel(T)).*1e-9.*repmat(T,numel(lambda),1)).^(-1)))-1).^(-1);
Sr_fcn2= @(T,lambda) Sr_fcn(T,lambda)./repmat(Sr_fcn(T,560),numel(lambda),1);
Sr = [lambda,Sr_fcn2(T,lambda)];
end

