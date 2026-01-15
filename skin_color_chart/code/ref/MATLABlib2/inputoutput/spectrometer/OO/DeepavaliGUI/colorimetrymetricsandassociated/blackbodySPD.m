function [Sr,duv] = blackbodySPD(T, lb,le,stepsize);
%calculates black body radiator spectrum based on
%T= T or CIE xy coordinates or xyz 
%lb=start wavelength 
%le=end wavelength 
%stepsize= wavelength interval
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin==1;
    lambda =(360:1:830)';
else;
    if nargin<4;stepsize=1;end
    if nargin>=3;lambda=(lb:stepsize:le)';end
    if nargin==2 & numel(lb)>1;lambda=lb;lb=lambda(1);le=lambda(end);stepsize=abs(lambda(1)-lambda(2));else;lambda =(360:1:830)';end
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
c1 = 3.74183e-16;
c2 =  1.4388*10^-2;
n=1.000;

Sr=(1/pi)*c1*((lambda.*1e-9).^(-5))*(n^(-2)).*(exp(c2*((n.*lambda.*1e-9.*T).^(-1)))-1).^(-1);
Sr560=(1/pi)*c1*((560*1e-9).^(-5))*(n^(-2)).*(exp(c2*((n*560*1e-9.*T).^(-1)))-1).^(-1);
Sr=Sr./Sr560;
Sr = [lambda,Sr];
end

