function newx = annealingfast(optimValues,problem)
%ANNEALINGFAST Generates a point using Student's t distribution
%   NEWX = ANNEALINGFAST(optimValues,problem) generates a point based on
%   the current point and the current temperature using Student's t
%   distribution. 
%
%   OPTIMVALUES is a structure containing the following information:
%              x: current point 
%           fval: function value at x
%          bestx: best point found so far
%       bestfval: function value at bestx
%    temperature: current temperature
%      iteration: current iteration 
%             t0: start time
%              k: annealing parameter
%
%   PROBLEM is a structure containing the following information:
%      objective: function handle to the objective function
%             x0: the start point
%           nvar: number of decision variables
%             lb: lower bound on decision variables
%             ub: upper bound on decision variables
%
%   Example:
%    Create an options structure using ANNEALINGFAST as the annealing
%    function
%    options = saoptimset('AnnealingFcn' ,@annealingfast);


%   Copyright 2006-2010 The MathWorks, Inc.
%   $Revision: 1.1.6.2 $  $Date: 2010/05/10 17:16:44 $

currentx = optimValues.x;
nvar = numel(currentx);
newx = currentx;
y = randn(nvar,1);
y = y./norm(y);
newx(:) = currentx(:) + optimValues.temperature.*y;

newx = sahonorbounds(newx,optimValues,problem);
