function y = simple_fitness(x)
%SIMPLE_FITNESS fitness function for GA

%   Copyright 2004 The MathWorks, Inc. 
%   $Revision: 1.1.6.1 $  $Date: 2009/08/29 08:28:28 $

  y = 100 * (x(1)^2 - x(2)) ^2 + (1 - x(1))^2;
