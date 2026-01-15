function [c, ceq] = simple_constraint(x)
%SIMPLE_CONSTRAINT Nonlinear inequality constraints.

%   Copyright 2005-2007 The MathWorks, Inc.
%   $Revision: 1.1.6.1 $  $Date: 2009/08/29 08:28:26 $

c = [1.5 + x(1)*x(2) + x(1) - x(2); 
     -x(1)*x(2) + 10];

% No nonlinear equality constraints:
ceq = [];
