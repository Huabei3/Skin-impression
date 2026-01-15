function spdnew=changespectrum(startspd,sp,factors,methodn,span,degree)
%change a spectrum using smoothing functions working on portions of the spectrum
%startspd = input spd
%sp = wavelength intervals dividing the spectrum
%factors = amounts by which each spectrum portion is increased (e.g.
%'+3');decreased(e.g. '-2') or multiplied ('x1.4') 
%
%Parameters used in smoothing function (more info --> help smooth):
%   method = method used in smoothing
%   span = range used in smoothing function
%   degree = smoothing function
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin<4;span=80;degree=2;methodn=1;end
switch methodn
    case 1
       method= 'moving'   %- Moving average (default)
    case 2
      method=  'lowess'   %- Lowess (linear fit)
    case 3
       method= 'loess'    %- Loess (quadratic fit)
    case  4
       method= 'sgolay'   %- Savitzky-Golay
    case   5
       method= 'rlowess'  %- Robust Lowess (linear fit)
    case  6
       method= 'rloess'   %- Robust Loess (quadratic fit)
end
spdtemp=startspd;
m=size(sp);
sp=sp-380+1
%change from lambda to index
%switch addf
 %   case 'x'
        for i=1:m
            charfac=char(factors(i));
            switch charfac(1)
                case 'x' 
                    
                    spdtemp(sp(i,1):sp(i,2),2)=startspd(sp(i,1):sp(i,2),2).*str2double((charfac(2:end)));
                    spdtemp=[(380:1:780)',smooth(spdtemp(:,1),spdtemp(:,2),span,method,degree)];
                case '+' 
                    spdtemp(sp(i,1):sp(i,2),2)=startspd(sp(i,1):sp(i,2),2)+repmat(str2double((charfac(2:end))),length([sp(i,1):sp(i,2)]),1);
                    spdtemp=[(380:1:780)',smooth(spdtemp(:,1),spdtemp(:,2),span,method,degree)];
                case '-' 
                spdtemp(sp(i,1):sp(i,2),2)=startspd(sp(i,1):sp(i,2),2)-repmat(str2double((charfac(2:end))),length([sp(i,1):sp(i,2)]),1);
                spdtemp=[(380:1:780)',smooth(spdtemp(:,1),spdtemp(:,2),span,method,degree)];
            end
        end
  

spdnew=[(380:1:780)',smooth(spdtemp(:,1),spdtemp(:,2),span,method,degree)];
figure(20);
plot_2(spdtemp,'k');hold on
plot_2(startspd,'bx');
spdnew(:,2)=(spdnew(:,2)+startspd(:,2))./2;
plot_2(spdnew,'r')
end


