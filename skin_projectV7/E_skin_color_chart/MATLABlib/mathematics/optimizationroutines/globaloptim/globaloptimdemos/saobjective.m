%% Minimization Using Simulated Annealing Algorithm
% This is a demonstration of how to create and minimize an objective
% function using the Simulated Annealing in the Global Optimization Toolbox.

%   Copyright 2006-2010 The MathWorks, Inc.
%   $Revision: 1.1.6.3 $   $Date: 2010/02/08 22:34:32 $

%%  A Simple Objective Function
% We want to minimize a simple function of two variables
%
%     min f(x) = (4 - 2.1*x1^2 + x1^4/3)*x1^2 + x1*x2 + (-4 + 4*x2^2)*x2^2;
%      x
%
% The above function is known as 'cam' as described in L.C.W. Dixon and
% G.P. Szegö (eds.), Towards Global Optimisation 2, North-Holland,
% Amsterdam, 1978.

%% Coding the Objective Function
% We create a MATLAB file named simple_objective.m with the following
% code in it:
%
%     function y = simple_objective(x)
%     y = (4 - 2.1*x(1)^2 + x(1)^4/3)*x(1)^2 + x(1)*x(2) + ...
%         (-4 + 4*x(2)^2)*x(2)^2;
%
% The Simulated Annealing solver assumes the objective function will take
% one input x where x has as many elements as the number of variables in the
% problem. The objective function computes the scalar value of the objective and
% returns it in its single return argument y.

%% Minimizing Using SIMULANNEALBND
% To minimize our objective function using the SIMULANNEALBND function, we
% need to pass in a function handle to the objective function as well as
% specifying a start point as the second argument.
ObjectiveFunction = @simple_objective;
X0 = [0.5 0.5];   % Starting point
[x,fval,exitFlag,output] = simulannealbnd(ObjectiveFunction,X0)

%%
% The first two output arguments returned by SIMULANNEALBND are |x|, the best
% point found, and |fval|, the function value at the best point. A third
% output argument, |exitFlag| returns a flag corresponding to the reason
% SIMULANNEALBND stopped. SIMULANNEALBND can also return a fourth argument,
% |output|, which contains information about the performance of the solver.

%% Bound Constrained Minimization
% SIMULANNEALBND can be used to solve problems with bound constraints.
% The lower and upper bounds are passed to the solver as vectors. For
% each dimension i, the solver ensures that lb(i) <= x(i) <= ub(i), where x
% is a point selected by the solver during simulation. We impose the
% bounds on our problem by specifying a range -64 <= x(i) <= 64 for x(i). 
lb = [-64 -64];
ub = [64 64];

%%
% Now, we can rerun the solver with lower and upper bounds as input arguments.
[x,fval,exitFlag,output] = simulannealbnd(ObjectiveFunction,X0,lb,ub);

fprintf('The number of iterations was : %d\n', output.iterations);
fprintf('The number of function evaluations was : %d\n', output.funccount);
fprintf('The best function value found was : %g\n', fval);

%% How Simulated Annealing Works
% Simulated annealing mimics the annealing process to solve an optimization
% problem. It uses a temperature parameter that controls the search. The
% temperature parameter typically starts off high and is slowly "cooled" or 
% lowered in every iteration. At each iteration a new point is generated
% and its distance from the current point is proportional to the
% temperature. If the new point has a better function value it replaces the
% current point and iteration counter is incremented. It is possible to
% accept and move forward with a worse point. The probability of doing so
% is directly dependent on the temperature. This unintuitive step sometime
% helps identify a new search region in hope of finding a better minimum.

%% An Objective Function with Additional Arguments
% Sometimes we want our objective function to be parameterized by extra
% arguments that act as constants during the optimization.  For example,
% in the previous objective function, say we want to replace the
% constants 4, 2.1, and 4 with parameters that we can change to create a
% family of objective functions. We can re-write the above function to
% take three additional parameters to give the new minimization problem.
%
%     min f(x) = (a - b*x1^2 + x1^4/3)*x1^2 + x1*x2 + (-c + c*x2^2)*x2^2;
%      x
%
% a, b, and c are parameters to the objective function that act as
% constants during the optimization (they are not varied as part of the
% minimization). One can create a MATLAB file called parameterized_objective.m
% containing the following code.
%
%     function y = parameterized_objective(x,a,b,c)
%     y = (a - b*x(1)^2 + x(1)^4/3)*x(1)^2 + x(1)*x(2) + ...
%         (-c + c*x(2)^2)*x(2)^2;
%

%% Minimizing Using Additional Arguments
% Again, we need to pass in a function handle to the objective function as
% well as a start point as the second argument.
%
% SIMULANNEALBND will call our objective function with just
% one argument |x|, but our objective function has four arguments: x, a, b, c.
% We can use an anonymous function to capture the values of the additional 
% arguments, the constants a, b, and c. We create a function handle
% 'ObjectiveFunction' to an anonymous function that takes one input |x|,
% but calls 'parameterized_objective' with x, a, b and c. The variables a,
% b, and c have values when the function handle 'ObjectiveFunction' is
% created, so these values are captured by the anonymous function.

a = 4; b = 2.1; c = 4;    % define constant values
ObjectiveFunction = @(x) parameterized_objective(x,a,b,c);
X0 = [0.5 0.5];
[x,fval] = simulannealbnd(ObjectiveFunction,X0)

displayEndOfDemoMessage(mfilename)
