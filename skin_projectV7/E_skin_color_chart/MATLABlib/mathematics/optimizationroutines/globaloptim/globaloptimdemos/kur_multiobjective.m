function y = kur_multiobjective(x)
%KUR_MULTIOBJECTIVE Objective function for a multiobjective problem. 
%   The Pareto-optimal set for this two-objective problem is nonconvex as
%   well as disconnected. The function KUR_MULTIOBJECTIVE computes two
%   objectives and returns a vector y of size 2-by-1.
%
%   Reference: Kalyanmoy Deb, "Multi-Objective Optimization using
%   Evolutionary Algorithms", John Wiley & Sons ISBN 047187339 

%   Copyright 2007 The MathWorks, Inc.
%   $Revision: 1.1.6.1 $  $Date: 2009/08/29 08:27:51 $


% Initialize for two objectives 
y = zeros(2,1);

% Compute first objective
for i = 1:2
  y(1) = y(1)  - 10*exp(-0.2*sqrt(x(i)^2 + x(i+1)^2));
end

% Compute second objective
for i = 1:3
   y(2) = y(2) +  abs(x(i))^0.8 + 5*sin(x(i)^3);
end
