function f = shufcn(y)
%SHUFCN Shu objective function.
%
%   Reference: L.C.W. Dixon and G.P. Szeg? (eds.), Towards Global
%   Optimisation 2, North-Holland, Amsterdam 1978.

%   Copyright 2004-2007 The MathWorks, Inc.
%   $Revision: 1.1.6.1 $  $Date: 2009/08/29 08:28:25 $

for j = 1: size(y,1)
    f(j) = 0.0;
    x = y(j,:);
    temp1 = 0; 
    temp2 = 0;
    x1 = x(1);
    x2 = x(2);
    for i = 1:5
        temp1 = temp1 + i.*cos((i+1).*x1+i);
        temp2 = temp2 + i.*cos((i+1).*x2+i);
    end
    f(j) = temp1.*temp2;
end
