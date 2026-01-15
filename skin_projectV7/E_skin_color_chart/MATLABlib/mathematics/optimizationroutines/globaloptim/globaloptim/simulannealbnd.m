function [x, fval, exitflag, output] = simulannealbnd(FUN, x0, lb, ub, options)
%SIMULANNEALBND Bound constrained optimization using simulated annealing.
%
%   SIMULANNEALBND attempts to solve problems of the form:
%       min F(X)  subject to  LB <= X <= UB
%        X                     
%                              
%   X = SIMULANNEALBND(FUN,X0) starts at X0 and finds a local minimum X to
%   the objective function FUN. FUN accepts input X and returns a scalar
%   function value evaluated at X. X0 may be a scalar or a vector.
%
%   X = SIMULANNEALBND(FUN,X0,LB,UB) defines a set of lower and upper
%   bounds on the design variables, X, so that a solution is found in the
%   range LB <= X <= UB. Use empty matrices for LB and UB if no bounds
%   exist. Set LB(i) = -Inf if X(i) is unbounded below;  set UB(i) = Inf if 
%   X(i) is unbounded above.
%
%   X = SIMULANNEALBND(FUN,X0,LB,UB,options) minimizes with the default
%   optimization parameters replaced by values in the structure OPTIONS.
%   OPTIONS can be created with the SAOPTIMSET function. See SAOPTIMSET for
%   details. 
%
%   X = SIMULANNEALBND(PROBLEM) finds the minimum for PROBLEM. PROBLEM is
%   a structure that has the following fields:
%      objective: <Objective function>
%             x0: <Starting point>
%             lb: <Lower bound on X>
%             ub: <Upper bound on X>
%        options: <options structure created with SAOPTIMSET>
%       rngstate: <State of the random number generator>
%
%   [X,FVAL] = SIMULANNEALBND(FUN, ...) returns FVAL, the value of the
%   objective function FUN at the solution X.
%
%   [X,FVAL,EXITFLAG] = SIMULANNEALBND(FUN, ...) returns EXITFLAG which
%   describes the exit condition of SIMULANNEALBND. Possible values of
%   EXITFLAG and the corresponding exit conditions are
%
%     1 Average change in value of the objective function over
%        options.StallIterLimit iterations less than options.TolFun.
%     5 options.ObjectiveLimit limit reached.
%     0 Maximum number of function evaluations or iterations exceeded.
%    -1 Optimization terminated by the output or plot function.
%    -2 No feasible point found.
%    -5 Time limit exceeded.
%
%   [X,FVAL,EXITFLAG,OUTPUT] = SIMULANNEALBND(FUN, ...) returns a
%   structure OUTPUT with the following information:
%      problemtype: Type of problem: unconstrained or bound constrained
%       iterations: Total iterations
%        funccount: Total function evaluations
%          message: Termination message of the solver
%      temperature: Temperature when solver terminated
%        totaltime: Time taken by the solver
%         rngstate: State of the random number generator before the solver started
%
%
%   Examples:
%    Minimization of Dejong's fifth function:
%     x0 = [0 0];
%     fun = @dejong5fcn;
%     [x,fval] = simulannealbnd(fun,x0)
%
%    Minimization of Dejong's fifth function subject to lower and upper
%    bounds:
%     x0 = [0 0];
%     fun = @dejong5fcn;
%     lb = [-64 -64];
%     ub = [64 64];
%     [x,fval] = simulannealbnd(fun,x0,lb,ub)
%
%     FUN can also be an anonymous function:
%     fun =  @(x) 3*sin(x(1))+exp(x(2));
%     x = simulannealbnd(fun,[1;1],[0 0])
%
%    Minimization of Dejong's fifth function while displaying plots:
%     x0 = [0 0];
%     fun = @dejong5fcn;
%     options = saoptimset('PlotFcns',{@saplotbestx, @saplotbestf, ...
%     @saplotx, @saplotf});
%     simulannealbnd(fun,x0,[],[],options)
%     
%   
%   See also SAOPTIMSET, PATTERNSEARCH, GA, FMINSEARCH.

%   Copyright 2006-2010 The MathWorks, Inc.
%   $Revision: 1.1.6.4 $  $Date: 2010/11/01 19:36:52 $

% If just 'defaults' passed in, return the default options in X
if nargin == 1 && nargout <= 1 && isequal(FUN,'defaults')
    x = simulanneal('defaults');
    return
end
% Check number of input arguments
errmsg = nargchk(1,5,nargin);

if ~isempty(errmsg)
    error(message('globaloptim:simulannealbnd:numberOfInputs', errmsg));
end

if nargin < 5
    options = [];
    if nargin < 4
        ub = [];
        if nargin < 3
            lb = [];
        end
    end
end

% One input argument is for problem structure
if nargin == 1
    if isa(FUN,'struct')
        [FUN,x0,lb,ub,rngstate,options] = separateOptimStruct(FUN);
        % Reset the random number generators
        resetDfltRng(rngstate);
    else % Single input and non-structure.
        error(message('globaloptim:simulannealbnd:invalidStructInput'));
    end
end

[x, fval, exitflag, output] = simulanneal(FUN, x0, [], [], [], [], lb, ub, options);
