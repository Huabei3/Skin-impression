function [successSearch,xBest,fBest,funccount] = searchfcntemplate(FUN,X,Aineq, ...
    bineq,Aeq,beq,lb,ub,optimValues,options,iterLimit,optionsFmin)
%SEARCHFCNTEMPLATE Template to write a search step in pattern search.
%   [SUCESSSEARCH,XBEST,FBEST,FUNCCOUNT] = SEARCHFCNTEMPLATE(FUN,X,A,b, ...
%   Aeq,beq,lb,ub,OPTIMVALUES,OPTIONS) searches for the next iterate. 
%
%   FUN: The objective function
% 		
%   X: Current point in optimization
%
%   A,b: Linear inequality constraints
%
%   Aeq,beq: Linear equality constraints
%
%   lb,ub: Lower and upper bound constraints
%
%   OPTIMVALUES is a structure containing the following information:
%              x: Current point 
%           fval: Objective function value at 'x'
%      iteration: Current iteration number
%      funccount: Counter for user function evaluation
%          scale: Scale factor used to scale the mesh
%    problemtype: Type of problem; 'unconstrained','boundconstraints', or
%                 'linearconstraints'; this field is a sub-problem type for
%                 nonlinear constrained problems.
%       meshsize: Current mesh size used by pattern search solver
%         method: method used in last iteration 
%
%   OPTIONS: Pattern search options structure
%
%   SUCCESSSEARCH: A boolean identifier indicating whether search is
%   successful or not
%
%   XBEST, FBEST: Best point XBEST and function value FBEST found by search
%   method
% 		
%   FUNCCOUNT: Number of user function evaluation in search method
%                                                      
%   See also PATTERNSEARCH, GA, PSOPTIMSET, SEARCHGA.

%   Copyright 2003-2007 The MathWorks, Inc.
%   $Revision: 1.1.6.1 $  $Date: 2009/08/29 08:25:30 $

% NOTE: This SearchMethod template implements search using FMINCON or
% FMINUNC function

if nargin < 12 || isempty(optionsFmin) % Short-circuit will prevent 2nd test if 1st failed
   optionsFmin = optimset('Display','off');
end
if nargin < 11 || isempty(iterLimit) % Short-circuit will prevent 2nd test if 1st failed
    iterLimit = 1;
end

% Initialize output
successSearch = 0;
xBest = X;
fBest = optimValues.fval;
funccount = 0;

% Use search step only till 'iterLimit'
if optimValues.iteration >= iterLimit 
    return;
end
% If FUN is a cell array with additional arguments, handle them
if iscell(FUN)
    objFcnArg = FUN(2:end);
    FUN = FUN{1};
else
    objFcnArg = {};
end
% Does problem have constraints (linear or bounds only)
constr = any(strcmpi(optimValues.problemtype,{'linearconstraints','boundconstraints'}));

optionsFmin = optimset(optionsFmin,'MaxFunEvals',options.MaxFunEvals - optimValues.funccount, ...
    'LargeScale','off');
if constr % Call fmincon
    [x,fval,unused1,output] = fmincon(FUN,X,Aineq,bineq,Aeq,beq,lb,ub,[],optionsFmin,objFcnArg{:});
else % Call fminunc
    [x,fval,unused1,output] = fminunc(FUN,X,optionsFmin,objFcnArg{:});
end

funccount = optimValues.funccount + output.funcCount; % optim functions return funcCount
if fval < optimValues.fval
    successSearch = true;
    xBest = x(:);
    fBest = fval;
end
