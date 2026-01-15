function Sr=CCT2CIEref(T,lb,le,stepsize)
%calculates CIE reference illuminant based on
%T = CCT or CIE xy coordinates or xyz 
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

Sr = blackbodySPD(T,lb,le,stepsize);
lambda = Sr(:,1);
Sr = Sr(:,2:end);
pL5k = (T >= 5000);
if sum(pL5k)>0
    SrDL=daylightSPD(T(pL5k),lb,le,stepsize);
    SrDL = SrDL(:,2:end);
    Sr(:,pL5k) = SrDL;
end

Sr=Sr./(repmat(sum(Sr).*abs(lambda(2)-lambda(1)),size(Sr,1),1));
Sr(isnan(Sr))=0;
Sr = [lambda,Sr];

