%% Constrained Minimization Using the Genetic Algorithm
% This is a demonstration of how to minimize an objective function subject
% to nonlinear inequality constraints and bounds using the Genetic
% Algorithm.

%   Copyright 2005-2010 The MathWorks, Inc.
%   $Revision: 1.1.6.2 $  $Date: 2010/02/08 22:34:25 $

%% Constrained Minimization Problem
% We want to minimize a simple fitness function of two variables x1
% and x2
%
%     min f(x) = 100 * (x1^2 - x2) ^2 + (1 - x1)^2;
%      x
%
% such that the following two nonlinear constraints and bounds are
% satisfied
%
%     x1*x2 + x1 - x2 + 1.5 <=0, (nonlinear constraint)
%     10 - x1*x2 <=0,            (nonlinear constraint)
%     0 <= x1 <= 1, and          (bound)
%     0 <= x2 <= 13              (bound)
%
% The above fitness function is known as 'cam' as described in L.C.W.
% Dixon and G.P. Szegö (eds.), Towards Global Optimisation 2,
% North-Holland, Amsterdam, 1978.

%% Coding the Fitness Function
% We create a MATLAB file named simple_fitness.m with the following
% code in it:
%
%     function y = simple_fitness(x)
%      y = 100 * (x(1)^2 - x(2)) ^2 + (1 - x(1))^2;
%
% The Genetic Algorithm (GA) function assumes the fitness function will
% take one input x where x has as many elements as number of variables in
% the problem. The fitness function computes the value of the function and
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
% The GA function assumes the constraint function will take one
% input x where x has as many elements as number of variables in the
% problem.  The constraint function computes the values of all the
% inequality and equality constraints and returns two vectors c and ceq
% respectively.

%% Minimizing Using GA
% To minimize our fitness function using the GA function, we need to pass
% in a function handle to the fitness function as well as specifying the
% number of variables as the second argument. Lower and upper bounds are
% provided as LB and UB respectively. In addition, we also need to pass in
% a function handle to the nonlinear constraint function. 

ObjectiveFunction = @simple_fitness;
nvars = 2;    % Number of variables
LB = [0 0];   % Lower bound
UB = [1 13];  % Upper bound
ConstraintFunction = @simple_constraint;
[x,fval] = ga(ObjectiveFunction,nvars,[],[],[],[],LB,UB, ...
    ConstraintFunction)

%%
% Note that for our constrained minimization problem, the GA function
% changed the mutation function to @mutationadaptfeasible. The default
% mutation function, @mutationgaussian, is only appropriate for
% unconstrained minimization problems.

%% GA Operators for Constrained Minimization
% The GA solver handles linear constraints and bounds differently from
% nonlinear constraints. All the linear constraints and bounds are
% satisfied throughout the optimization. However, GA may not satisfy all
% the nonlinear constraints at every generation. If GA converges to a
% solution, the nonlinear constraints will be satisfied at that solution.

%%
% GA uses the mutation and crossover functions to produce new individuals
% at every generation. The way the GA satisfies the linear and bound
% constraints is to use mutation and crossover functions that only generate
% feasible points. For example, in the previous call to GA, the default
% mutation function MUTATIONGAUSSIAN will not satisfy the linear
% constraints and so the MUTATIONADAPTFEASIBLE is used instead. If you
% provide a custom mutation function, this custom function must only
% generate points that are feasible with respect to the linear and bound
% constraints. All the crossover functions in the toolbox generate points
% that satisfy the linear constraints and bounds.

%%
% We specify MUTATIONADAPTFEASIBLE as the mutation function for our
% minimization problem by using GAOPTIMSET function.
options = gaoptimset('MutationFcn',@mutationadaptfeasible);
% Next we run the GA solver.
[x,fval] = ga(ObjectiveFunction,nvars,[],[],[],[],LB,UB, ...
    ConstraintFunction,options)

%% Adding Visualization
% Next we use GAOPTIMSET to create an options structure to select two plot
% functions. The first plot function is GAPLOTBESTF, which plots the
% best and mean score of the population at every generation. The second
% plot function is GAPLOTMAXCONSTR, which plots the maximum constraint
% violation of nonlinear constraints at every generation. We can also
% visualize the progress of the algorithm by displaying information to
% the command window using the 'Display' option.
options = gaoptimset(options,'PlotFcns',{@gaplotbestf,@gaplotmaxconstr}, ...
    'Display','iter');
% Next we run the GA solver.
[x,fval] = ga(ObjectiveFunction,nvars,[],[],[],[],LB,UB, ...
    ConstraintFunction,options)

%% Providing a Start Point
% A start point for the minimization can be provided to GA function by
% specifying the InitialPopulation option. The GA function will use the
% first individual from InitialPopulation as a start point for a
% constrained minimization. Refer to the documentation for a description of
% specifying an initial population to GA.
X0 = [0.5 0.5]; % Start point (row vector)
options = gaoptimset(options,'InitialPopulation',X0);
% Next we run the GA solver.
[x,fval] = ga(ObjectiveFunction,nvars,[],[],[],[],LB,UB, ...
    ConstraintFunction,options)

displayEndOfDemoMessage(mfilename)
