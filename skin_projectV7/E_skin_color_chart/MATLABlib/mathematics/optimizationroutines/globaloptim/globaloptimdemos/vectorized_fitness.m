function y = vectorized_fitness(x,p1,p2)
%VECTORIZED_FITNESS fitness function for GA

%   Copyright 2004-2010 The MathWorks, Inc.  
%   $Revision: 1.1.6.2 $  $Date: 2010/11/08 02:22:28 $

y = p1 * (x(:,1).^2 - x(:,2)).^2 + (p2 - x(:,1)).^2;