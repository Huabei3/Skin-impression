function x = qtukey(v,k,p);
%QTUKEY Tukey's q studentized range critical value.
%   X = QTUKEY(V,K,P) finds the Tukey's q studentized range critical value.
%(This modified macro based on the Fortran77 algorithm AS 190.2 Appl. Statist. (1983)
%gives a very good approximation for 0.8 < p < 0.995).
%
%   Syntax: function x = qtukey(v,k,p) 
%
%     Inputs:
% 	        v - sample degrees of freedom (must be the same for each sample).
% 	        k - number of samples.
% 	        p - cumulative probability value.
%

%  Created by A. Trujillo-Ortiz and R. Hernandez-Walls
%             Facultad de Ciencias Marinas
%             Universidad Autonoma de Baja California
%             Apdo. Postal 453
%             Ensenada, Baja California
%             Mexico.
%             atrujo@uabc.mx
%
%  May 18, 2003.
%
%  To cite this file, this would be an appropriate format:
%  Trujillo-Ortiz, A. and R. Hernandez-Walls. (2003). qtukey: Tukey's q studentized range 
%    critical value. A MATLAB file. [WWW document]. URL http://www.mathworks.com/
%    matlabcentral/fileexchange/loadFile.do?objectId=3469&objectType=FILE
%
%  References:
% 
%  Algorithm AS 190.2 (1983), Applied Statistics, 32(2)
%

if nargin < 3, 
    p = 0.95;
end

if nargin < 2, 
   error('Requires at least two arguments.');
end


t=norminv(.5+.5*p);
vmax=120; c=[0.89,0.237,1.214,1.21,1.414];

if v <=vmax;
    t=t+(t*t*t+t)/v/4;
    q=c(1)-c(2)*t;
    q=q-c(3)/v+c(4)*t/v;
    qc=t*(q*log(k-1)+c(5));
else
    qt=[80.0000    2.8140    3.3770    3.7110    3.9470    4.1290    4.2770    4.4020    4.5090    4.6030 4.6860    4.7610    4.8290    4.8920    4.9490    5.0030    5.0520    5.0990    5.1420    5.1830;
  120.0000    2.8000    3.3560    3.6850    3.9170    4.0960    4.2410    4.3630    4.4680    4.5600 4.6410    4.7140    4.7810    4.8420    4.8980    4.9500    4.9980    5.0430    5.0860    5.1260;
  240.0000    2.7860    3.3350    3.6590    3.8870    4.0630    4.2050    4.3240    4.4270    4.5170 4.5960    4.6680    4.7330    4.7920    4.8470    4.8970    4.9440    4.9880    5.0300    5.0690;
       10^10    2.7720    3.3140    3.6330    3.8580    4.0300    4.1700    4.2860    4.3870    4.4740 4.5520    4.6220    4.6850    4.7430    4.7960    4.8450    4.8910    4.9340    4.9740    5.0120];
 p=polyfit(qt(:,1),qt(:,k+1),1);
 qc=polyval(p,v);
end
    x=qc;
