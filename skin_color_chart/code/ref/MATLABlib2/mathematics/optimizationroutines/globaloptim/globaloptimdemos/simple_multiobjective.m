function y = simple_multiobjective(x)
%SIMPLE_MULTIOBJECTIVE is a simple multi-objective fitness function.
%
% The multi-objective genetic algorithm solver assumes the fitness function
% will take one input x where x is a row vector with as many elements as
% number of variables in the problem. The fitness function computes the
% value of each objective function and returns the vector value in its one
% return argument y.

%   Copyright 2007 The MathWorks, Inc. 
%   $Revision: 1.1.6.1 $  $Date: 2009/08/29 08:28:29 $

y(1) = (x+2)^2 - 10;
y(2) = (x-2)^2 + 20;


