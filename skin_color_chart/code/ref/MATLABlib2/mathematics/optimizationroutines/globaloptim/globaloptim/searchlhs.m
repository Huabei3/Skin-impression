function [successSearch,xBest,fBest,funccount] = searchlhs(FUN,X,Aineq,bineq, ...
                Aeq,beq,lb,ub,optimValues,options,iterLimit,factors)
%SEARCHLHS PATTERNSEARCH optional search step using LHS.
%   [SUCESSSEARCH,XBEST,FBEST,FUNCCOUNT] = SEARCHLHS(FUN,X,A,b,Aeq,beq, ...
%   lb,ub,OPTIMVALUES,OPTIONS,ITERLIMIT,FACTORS) searches for the next
%   iterate in a Latin hypercube design space. SEARCHLHS is only used for
%   the first iteration (OPTIMVALUES.iteration == 1) by default.
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
%   FACTORS: The design level for LHS (Optional argument)
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
%   $Revision: 1.1.6.1 $  $Date: 2009/08/29 08:25:32 $

successSearch = 0;
xBest = X;
fBest = optimValues.fval;
funccount = optimValues.funccount;
numberofVariables  = numel(X);
range = [];

if nargin < 12 || isempty(factors) % Short-circuit will prevent 2nd test if 1st failed
    factors = 15*numberofVariables; 
end
if nargin < 11 || isempty(iterLimit) % Short-circuit will prevent 2nd test if 1st failed
    iterLimit = 1;  
end
   

% Use search step only till iterLimit.
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
constr = any(strcmpi(optimValues.problemtype, ...
    {'linearconstraints','nonlinearconstr','boundconstraints'}));

% LHS design calculations for 'maximin' criterion
Points = lhspoint(factors,numberofVariables);
if ~isempty(lb) || isempty(ub)
    range = [lb ub]';
end

if ~isempty(range) && ~any(isinf(range(:)))
    limit = range(2,:) - range(1,:);
    Points = repmat(range(1,:)',1,size(Points,2)) +  repmat(limit',1,size(Points,2)) .* Points;
    span = size(Points,2);
    sites = struct('x',cell(span,1,1),'f',cell(span,1,1));
    for k = 1:span
        sites(k).x = Points(:,k);
    end
else 
    Points = -1 + Points*2;
    span = size(Points,2);
    sites = struct('x',cell(span,1,1),'f',cell(span,1,1));
    for k = 1:span
        sites(k).x = X(:) + optimValues.meshsize*optimValues.scale.*Points(:,k); 
    end
end

% Create structure 'Iterate' to be used by local function 'psnextfeasible'
Iterate.x = X(:); Iterate.f = optimValues.fval;

% Find an iterate with lower objective 
[successSearch,Iterate,unused1,funccount] = psnextfeasible(FUN,X,sites, ...
    Iterate,Aineq,bineq,Aeq,beq,lb,ub,options.TolBind,constr,objFcnArg,optimValues.funccount,options);

if successSearch
    xBest(:) = Iterate.x;
    fBest = Iterate.f;
end
