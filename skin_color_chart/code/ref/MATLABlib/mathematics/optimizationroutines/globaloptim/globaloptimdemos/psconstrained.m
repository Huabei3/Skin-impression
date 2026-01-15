%% Constrained Minimization Using Pattern Search
% This is a demonstration of how to minimize an objective function subject
% to nonlinear inequality constraints and bounds using pattern search. 

%   Copyright 2005-2010 The MathWorks, Inc.
%   $Revision: 1.1.6.2 $  $Date: 2010/02/08 22:34:29 $

%% Constrained Minimization Problem
% We want to minimize a simple objective function of two variables x1
% and x2
%
%     min f(x) = (4 - 2.1*x1^2 + x1^4/3)*x1^2 + x1*x2 + (-4 + 4*x2^2)*x2^2;
%      x
%
% such that the following nonlinear constraints and bounds are satisfied
%
%     x1*x2 + x1 - x2 + 1.5 <=0, (nonlinear constraint)
%     10 - x1*x2 <=0,            (nonlinear constraint)
%     0 <= x1 <= 1, and          (bound)
%     0 <= x2 <= 13              (bound)
%
% The above objective function is known as 'cam' as described in L.C.W.
% Dixon and G.P. Szegö (eds.), Towards Global Optimisation 2,
% North-Holland, Amsterdam, 1978.

%% Coding the Objective Function
% We create a MATLAB file named simple_objective.m with the following
% code in it:
%
%     function y = simple_objective(x)
%     y = (4 - 2.1*x(1)^2 + x(1)^4/3)*x(1)^2 + x(1)*x(2) + ...
%         (-4 + 4*x(2)^2)*x(2)^2;
%
% The Pattern Search solver assumes the objective function will take one
% input x where x has as many elements as number of variables in the
% problem. The objective function computes the value of the function and
% returns that scalar value in its one return argument y.

%% Coding the Constraint Function
% We create a MATLAB file named simple_constraint.m with the following
% code in it:
%
%     function [c, ceq] = simple_constraint(x)
%     c = [1.5 + x(1)*x(2) + x(1) - x(2);
%     -x(1)*x(2) + 10];
%     ceq = [];
%
% The Pattern Search solver assumes the constraint function will take one
% input x where x has as many elements as number of variables in the
% problem.  The constraint function computes the values of all the
% inequality and equality constraints and returns two vectors c and ceq
% respectively.

%% Minimizing Using PATTERNSEARCH
% To minimize our objective function using the PATTERNSEARCH function,
% we need to pass in a function handle to the objective function as well
% as specifying a start point as the second argument. Lower and upper
% bounds are provided as LB and UB respectively. In addition, we also
% need to pass in a function handle to the nonlinear constraint function.

ObjectiveFunction = @simple_objective;
X0 = [0 0];   % Starting point
LB = [0 0];   % Lower bound
UB = [1 13];  % Upper bound
ConstraintFunction = @simple_constraint;
[x,fval] = patternsearch(ObjectiveFunction,X0,[],[],[],[],LB,UB, ...
    ConstraintFunction)

%% Adding Visualization
% Next we create an options structure using PSOPTIMSET that selects two
% plot functions. The first plot function PSPLOTBESTF plots the best
% objective function value at every iterations, and the second plot
% function PSPLOTMAXCONSTR plots maximum constraint violation at every
% iterations. We can also visualize the progress of the algorithm
% by displaying information to the command window using the 'Display'
% option.
options = psoptimset('PlotFcns',{@psplotbestf,@psplotmaxconstr}, ...
    'Display','iter');
% Next we run the PATTERNSEARCH solver.
[x,fval] = patternsearch(ObjectiveFunction,X0,[],[],[],[],LB,UB, ...
    ConstraintFunction,options)

displayEndOfDemoMessage(mfilename)

