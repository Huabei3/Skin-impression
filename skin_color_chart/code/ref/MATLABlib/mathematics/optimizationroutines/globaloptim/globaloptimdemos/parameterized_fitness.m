function y = parameterized_fitness(x,p1,p2)
%PARAMETERIZED_FITNESS fitness function for GA

%   Copyright 2004 The MathWorks, Inc.        
%   $Revision: 1.1.6.1 $  $Date: 2009/08/29 08:28:08 $
 
y = p1 * (x(1)^2 - x(2)) ^2 + (p2 - x(1))^2;
