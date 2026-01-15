function [x,fval,exitflag,output,solverData,problem,options] = ...
    simulannealcommon(FUN,x0,Aineq,bineq,Aeq,beq,lb,ub,options,defaultopt)
%simulannealcommon is called by simulanneal to perform common
%initialization tasks

% This function is private to simulanneal.

%   Copyright 2006-2010 The MathWorks, Inc.
%   $Revision: 1.1.6.4 $  $Date: 2010/10/08 16:51:55 $

% Only function_handle are allowed
if isempty(FUN) ||  ~isa(FUN,'function_handle')
    error(message('globaloptim:simulannealcommon:needFunctionHandle'));
end

% Use default options if empty
if ~isempty(options) && ~isa(options,'struct')
    error(message('globaloptim:simulannealcommon:fifthInputNotStruct'));
elseif isempty(options)
    options = defaultopt;
end
% All inputs should be double
try
    dataType = superiorfloat(x0,lb,ub);
    if ~isequal('double', dataType)
        error(message('globaloptim:simulannealcommon:dataType'))
    end
catch
    error(message('globaloptim:simulannealcommon:dataType'))
end

% Keep a copy of the user options structure
user_options = options;

% Get all default options and merge with non-default options
options = saoptimset(defaultopt,options);

if ~isempty(x0)
    x = x0;
    initialX = x0(:);
    numberOfVariables = length(initialX);
else
    error(message('globaloptim:simulannealcommon:initialPoint'));
end

% Remember the random number states used
output.iterations = 0;
output.funccount   = 0;
output.message   = '';
dflt = RandStream.getDefaultStream;
output.rngstate = struct('state',{dflt.State}, 'type',{dflt.Type});

% Initialize data structures for problem and also for solver state
problem = struct('objective', FUN, 'x0', x0, 'nvar', numberOfVariables);
solverData  = struct('t0',cputime,'currentx',initialX);

% Call savalidate to ensure that all the fields of options are valid
options = savalidate(options,problem);

% Make sure that the bound-constraints are valid
[lb, ub, msg, exitflag] = checkbound(lb, ub, numberOfVariables);
if exitflag < 0
    fval = [];
    x(:) = solverData.currentx;
    output.message = msg;
    if options.Verbosity > 0
        fprintf('%s\n',msg)
    end
    return;
end
problem.lb = lb; problem.ub = ub;
% Make sure the problem is not unbounded
if min(ub)==Inf && max(lb)==-Inf
    problem.bounded = false;
else
    if strcmpi(options.DataType,'custom')
        problem.bounded = false;
        if options.Verbosity > 0
            warning(message('globaloptim:simulannealcommon:boundsWithCustom'));
        end
    else
        problem.bounded = true;
    end
end
% Determine problemtype
if problem.bounded
    output.problemtype = 'boundconstraints';
else
    output.problemtype = 'unconstrained';
end

% Aineq, bineq, Aeq, beq are not part of problem because linear
% constraints are not implemented yet
% Find initial feasible point
[solverData.currentx,Aineq,bineq,Aeq,beq,lb,ub,msg,exitflag] = ...
    preProcessLinearConstr(solverData.currentx,Aineq,bineq,Aeq,beq,lb,ub,numberOfVariables,output.problemtype,options.Verbosity);
if exitflag < 0
    fval =    [];
    x(:) =  solverData.currentx;
    output.message = msg;
    if options.Verbosity > 0
        fprintf('%s\n',msg)
    end
    return
end
% Print diagnostic information if asked
if options.Verbosity > 2
    sadiagnose(user_options,problem);
end
% Additional fields for solver parameters need initialization
solverData = samakedata(solverData,problem,options);
% Initialize fval
fval = [];

