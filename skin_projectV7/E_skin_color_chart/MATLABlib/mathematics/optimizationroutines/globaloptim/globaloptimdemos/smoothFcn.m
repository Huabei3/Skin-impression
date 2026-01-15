function y = smoothFcn(z,noise)
%smoothFcn Objective function used in nonSmoothOpt demo.

%   Copyright 2005-2007 The MathWorks, Inc.
%   $Revision: 1.1.6.1 $  $Date: 2009/08/29 08:28:31 $

if nargin < 2
    noise = 0;
end
LB = [-5 -5];      %Lower bound 
UB = [5 5];        %Upper bound

y = zeros(1,size(z,1));
for i = 1:size(z,1)
    x = z(i,:);
    if any(x<LB) || any(x>UB)
        y(i) = Inf;
    else
    y(i) = x(1)^3 - x(2)^2 + ...
        100*x(2)/(10+x(1)) + noise*randn;
    end
end

