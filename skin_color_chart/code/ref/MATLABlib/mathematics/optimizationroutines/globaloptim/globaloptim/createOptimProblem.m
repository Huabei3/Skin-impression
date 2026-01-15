function problemStructure = createOptimProblem(solvername,varargin)
%createOptimProblem Create an optimization problem.
%   createOptimProblem creates a structure that contains the solver
%   name, solver options and problem description.
%
%   PROBLEM = createOptimProblem(SOLVERNAME, 'PROP1', VAL1, ... 
%   'PROP2', VAL2, ...) specifies a set of property-value pairs relevant
%   for the Optimization Toolbox solver, SOLVERNAME, to construct the
%   optimization problem structure, PROBLEM. SOLVERNAME is a required
%   argument and can be either one of 'fmincon', 'fminunc', 'lsqnonlin' or
%   'lsqcurvefit'. The property names, can be one or more of the problem
%   structure field names: 'objective', 'x0', 'xdata', 'ydata', 'Aineq',
%   'bineq', 'Aeq', 'beq', 'lb', 'ub', 'nonlcon', 'options'. The field
%   names specified  
%        (1) need to be relevant to the chosen solver, SOLVERNAME,
%        (2) can be entered in any order,
%        (3) can consist of only non-empty input arguments for the chosen
%        solver.
%
%   The full input argument lists for the supported solvers and
%   createOptimProblem calls to create the corresponding problem structures
%   are:
%
%       FMINCON(FUN,X0,A,B,Aeq,Beq,LB,UB,NONLCON,OPTIONS)
%
%       createOptimProblem('fmincon','objective', FUN, 'x0', X0, ...
%       'Aineq', A, 'bineq', b, 'Aeq', Aeq, 'beq', beq, 'lb', LB, ...
%       'ub', UB, 'nonlcon', NONLCON, 'options', OPTIONS)
%
%       FMINUNC(FUN,X0,OPTIONS)
%
%       createOptimProblem('fminunc','objective', FUN, 'x0', X0, ...
%       'options', OPTIONS)
%
%       LSQNONLIN(FUN,X0,LB,UB,OPTIONS)
%
%       createOptimProblem('lsqnonlin','objective', FUN, 'x0', X0, ...
%       'lb', LB, 'ub', UB, 'options', OPTIONS)
%
%       LSQCURVEFIT(FUN,X0,XDATA,YDATA,LB,UB,OPTIONS)
%
%       createOptimProblem('lsqcurvefit','objective', FUN, 'x0', X0, ...
%       'xdata', XDATA, 'ydata', YDATA, 'lb', LB, 'ub', UB, ...
%       'options', OPTIONS)
%   
%   Examples:
%
%   Create an optimization problem structure for solver fmincon:
%       problem = createOptimProblem('fmincon', 'objective', @myfun, ...
%        'x0', [1;1], 'lb', [-3;-3], 'ub', [3;3]);
%
%       Here myfun is a function such as
%  
%           function f = myfun(x)      
%           f = sin(x(1))*x(2)^3;  
%
%   Create an optimization problem structure for solver lsqnonlin:
%       problem = createOptimProblem('lsqnonlin', ...
%        'objective', @myfun, 'x0', [2 3 4]);
%
%       Here myfun is a function such as
%  
%           function f = myfun(x)      
%           f = sin(x);  
%
%   See also MULTISTART, GLOBALSEARCH, FMINCON, FMINUNC, LSQNONLIN, LSQCURVEFIT

%   Copyright 2009-2010 The MathWorks, Inc.
%   $Revision: 1.1.6.6 $  $Date: 2010/11/01 19:36:43 $

useValues.options = [];
problemProp = varargin;

if nargin < 1
    error(message('globaloptim:createOptimProblem:AtLeastOneInput'));
else
    if isa(solvername,'char')
    % First argument should be the name of these valid solvers
        validSolvers = {'fmincon','fminunc','lsqnonlin','lsqcurvefit'};
        if isempty(strmatch(solvername,validSolvers))
            error(message('globaloptim:createOptimProblem:InvalidSolver'));
        end
        useValues.solver = solvername;
    else
            error(message('globaloptim:createOptimProblem:SolverNameNotString'));
    end
end
if mod(length(problemProp),2) ~= 0
    error(message('globaloptim:createOptimProblem:NotAPair'));
end
while length(problemProp) >=2
    prop = problemProp{1};
    if ~ischar(prop)
        error(message('globaloptim:createOptimProblem:PropertyNameNotString'));
    end    
    val = problemProp{2};
    problemProp = problemProp(3:end);
    propName = i_isExactFieldName(prop);
    if ~isempty(propName)
        useValues.(propName) = val;
    else
        % No match at all
        error(message('globaloptim:createOptimProblem:InvalidPropertyName', prop));
    end
end

problemStructure = createProblemStruct(useValues.solver,[],useValues);
% Get the solver options and update the changed ones thru
% useValues.options
if ~isempty(useValues.options) && isstruct(useValues.options)
    defaultOptions = optimset(useValues.solver);
    % Overriding local solver defaults for use in global solvers
    defaultOptions.Display = 'off';
    if strcmp(useValues.solver, 'fmincon')
        defaultOptions.Algorithm = 'active-set';
    end
    problemStructure.options = optimset(defaultOptions,useValues.options);
else
    problemStructure.options = optimset(useValues.solver);
    % Overriding local solver defaults for use in global solvers    
    problemStructure.options.Display = 'off';
    if strcmp(useValues.solver, 'fmincon')
        problemStructure.options.Algorithm = 'active-set';
    end
end

function correctPName = i_isExactFieldName(prop)
% Check whether an identifier matches exactly to a field name.

correctIdents = {'objective','x0','Aineq','bineq','Aeq','beq','lb','ub', ...
    'nonlcon','options','xdata','ydata'};
correctPName = '';
if strmatch(prop,correctIdents,'exact');
    correctPName = prop;
end

