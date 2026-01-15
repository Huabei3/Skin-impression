function scores = vectorized_multiobjective(pop)
%VECTORIZED_MULTIOBJECTIVE is a vectorized multi-objective fitness function.
%
% The multi-objective genetic algorithm solver assumes the fitness function
% will take one input 'pop' where 'pop' is a matrix; each row represents one
% individual (point). The fitness function computes the value of each objective
% function for each individual and returns the output 'scores' that is a matrix.

%   Copyright 2007 The MathWorks, Inc. 
%   $Revision: 1.1.6.1 $  $Date: 2009/08/29 08:28:39 $

% More help on vectorizing fitnes function for GAMULTIOBJ
% If X = [5 -9 ....3]  Size: 1-by-nvar  then population will be of the form:
%
% pop   = [5 -9 ... 3
%          9  1 ... 3
%          ...
%          ...
%         -8  2 ... 10]  Size: popSize-by-nvar
%
% When the fitness function is called with 'pop'  the output argument scores is
% expected to be a matrix of size popSize-by-numObj, where numObj is the number
% of objectives in the problem.


popSize = size(pop,1); % Population size 
numObj = 2;  % Number of objectives

% scores is initialized
scores = zeros(popSize, numObj);

% Compute first objective (vectorized evaluation)
scores(:,1) = (pop + 2).^2 - 10;
% Compute second obective (vectorized evaluation)
scores(:,2) = (pop - 2).^2 + 20;
