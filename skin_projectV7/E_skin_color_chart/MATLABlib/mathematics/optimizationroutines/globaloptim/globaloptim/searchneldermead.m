function [successSearch,xBest,fBest,funccount] = searchneldermead(FUN,X,Aineq,bineq, ...
                Aeq,beq,lb,ub,optimValues,options,iterLimit,optionsNM)
%SEARCHNELDERMEAD PATTERNSEARCH optional search step using FMINSEARCH.
%   [SUCCESSSEARCH,NEXTITERATE,OPTIMSTATE] = SEARCHNELDERMEAD(FUN,X,A,b,Aeq, ...
%   beq,lb,ub,OPTIMVALUES,OPTIONS,ITERLIMIT,OPTIONSNM) searches for a lower
%   function value uses the Nelder-Mead method.
%
%   FUN: The objective function
% 		
%   X: The current point in optimization
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
%                 'linearconstraints'
%       meshsize: Current mesh size used by pattern search solver
%         method: method used in last iteration 
%
%   OPTIONS: Pattern search options structure
%
%   ITERLIMIT: No search above this iteration number (Optional argument)
%
%   OPTIONSNM: Options structure for FMINSEARCH (Optional argument)
%
%   SUCCESSSEARCH: A boolean identifier indicating whether search is
%   successful or not
%
%   XBEST, FBEST: Best point XBEST and function value FBEST found by search
%   method
% 		
%   FUNCCOUNT: Number of user function evaluation in search method
%
%   See also PATTERNSEARCH, GA, PSOPTIMSET, SEARCHFCNTEMPLATE.

%   Copyright 2003-2007 The MathWorks, Inc.
%   $Revision: 1.1.6.1 $  $Date: 2009/08/29 08:25:33 $
 
if nargin < 12 || isempty(optionsNM) % Short-circuit will prevent 2nd test if 1st failed
   optionsNM = optimset('Display','off');
end
if nargin < 11 || isempty(iterLimit) % Short-circuit will prevent 2nd test if 1st failed
    iterLimit = 1;
end
% Initialize output
successSearch = 0;
xBest = X;
fBest = optimValues.fval;
funccount = optimValues.funccount;

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
% Call FMINSEARCH 
optionsNM = optimset(optionsNM,'MaxFunEvals',options.MaxFunEvals - optimValues.funccount);
[x,fval,unused1,output] = fminsearch(FUN,X,optionsNM,objFcnArg{:});
funccount = funccount + output.funcCount; % optim functions return funcCount

if fval < optimValues.fval
    successSearch = true;
    xBest = x(:);
    fBest = fval;
end
