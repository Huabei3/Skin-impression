function y = vectorized_objective(x,p1,p2,p3)
%VECTORIZED_OBJECTIVE Objective function for PATTERNSEARCH solver

%   Copyright 2004 The MathWorks, Inc.
%   $Revision: 1.1.6.1 $  $Date: 2009/08/29 08:28:40 $

y = zeros(size(x,1),1); %Pre-allocate y
for i = 1:size(x,1) 
  x1 = x(i,1);
  x2 = x(i,2);
  y(i) = (p1-p2.*x1.^2+x1.^4./3).*x1.^2+x1.*x2+(-p3+p3.*x2.^2).*x2.^2;
end

