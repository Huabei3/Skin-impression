function y = lincontest6(x)
%LINCONTEST6 A quadratic objective function (from Optimization Toolbox)

%   Copyright 2003-2007 The MathWorks, Inc. 
%   $Revision: 1.1.6.1 $  $Date: 2009/08/29 08:27:53 $

p1=0.5;
p2=6.0;
y = p1*x(1)^2 + x(2)^2 -x(1)*x(2) -2*x(1) - p2*x(2);

%Derivative of the function above
% dy = [(2*p1*x(1) - x(2) -2);(2*x(2) -x(1) -p2)];
