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
    if nargin<4;stepsize=1;end
    if nargin>=3;lambda=(lb:stepsize:le)';end
    if nargin==2 & numel(lb)>1;lambda=lb;else;lambda =(360:1:830)';end
end
lb=lambda(1);le=lambda(end);stepsize=abs(lambda(1)-lambda(2));

duv=[];
switch size(T,2)
    case 2;%input = CIExy
        [T,duv]=CCTa(xyY2xyz(T));
        if abs(duv)>5.4e-3;disp('Warning: duv too large!');end
    case 3;%input=XYZ
        [T,duv]=CCTa(T);    
        if abs(duv)>5.4e-3;disp('Warning: duv too large!');end
end

if T<5000;
    Sr=blackbodySPD(T,lb,le,stepsize);
    Sr(:,2)=Sr(:,2)./(sum(Sr(:,2)).*abs(Sr(2,1)-Sr(1,1)));
else
    Sr=daylightSPD(T,lb,le,stepsize);
end
Sr(isnan(Sr(:,2)),2)=0;

