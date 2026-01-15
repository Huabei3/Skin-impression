function f = discont_objective(z)
%DISCONT_OBJECTIVE Objective function used by comparegadsoptim.

%   Copyright 2004-2007 The MathWorks, Inc. 
%   $Revision: 1.1.6.1 $Date: 2009/08/29 08:27:38 $


for i = 1:length(z)
    x = z(i);
    if  x < -5
        y = sin(x+rand*0.4)+1.5;
    elseif x < -3
        y = -2*x+rand*0.4;
    elseif x < 0
        y = -sin(x+rand*0.4);
    elseif x > 5
        y = sin(-x+rand*0.4) +1.5;
    elseif x > 3
        y = 2*x+rand*0.4;
    elseif x >= 0
        y = -sin(x);
    end
    f(i) = y;
end

f = f';
