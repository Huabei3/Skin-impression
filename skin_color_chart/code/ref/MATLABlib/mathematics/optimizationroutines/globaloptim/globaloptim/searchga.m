function [successSearch,xBest,fBest,funccount] = searchga(FUN,X,Aineq,bineq, ...
                Aeq,beq,lb,ub,optimValues,options,iterLimit,optionsGA)
%SEARCHGA Implements pattern search optional search step using GA function.
%   [SUCESSSEARCH,XBEST,FBEST,FUNCCOUNT] = SEARCHGA(FUN,X,A,b,Aeq,beq, ...
%   lb,ub,OPTIMVALUES,OPTIONS,ITERLIMIT,OPTIONSGA) uses GA to search for
%   the next iterate for patternsearch. GA does not accept an initial
%   point, therefore SEARCHGA is only used for the first iteration
%   (OPTIMVALUES.iteration == 1) by default.
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
%   OPTIONSGA: options structure for GA (Optional argument)
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

%   Copyright 2003-2006 The MathWorks, Inc.
%   $Revision: 1.1.6.1 $  $Date: 2009/08/29 08:25:31 $

if nargin < 16 || isempty(optionsGA) % Short-circuit will prevent 2nd test if 1st failed
    optionsGA = gaoptimset;
    optionsGA.PopulationSize = 5*numel(X);
    optionsGA.Generations    = 10*numel(X);
    optionsGA.StallGenLimit  = 5*numel(X);
    %No time limit by default
    optionsGA.TimeLimit      = inf;
    optionsGA.StallTimeLimit = inf;
    optionsGA.Display = 'off';
    if ~strcmpi(optimValues.problemtype, 'unconstrained')
        optionsGA.MutationFcn = @mutationadaptfeasible;
    end
    % Set population range for GA.
    if ~isempty(lb) || ~isempty(ub)
        range = [lb ub]';
        if ~isempty(range) && ~any(isinf(range(:)))
            optionsGA.PopInitRange = range;
        end
    end
end
if nargin < 15 || isempty(iterLimit) % Short-circuit will prevent 2nd test if 1st failed
    % GA search is performed only in 1st iteration by default
    iterLimit = 1;
end
% Initialization
successSearch = false;
xBest = X;
fBest = optimValues.fval;
funccount = optimValues.funccount;
% Limit search step to 'iterLimit' iterations
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
% GA setup
GenomeLength = numel(X);
% Call GA  if you are using GA search make sure that FUN is compatible with
% GA syntax.
[xga,fga,unused1,output] = ga(@fitnessWrapper,GenomeLength, ...
    Aineq,bineq,Aeq,beq,lb,ub,[],optionsGA);
if fga < optimValues.fval
    successSearch = true;
    xBest(:) = xga; 
    fBest = fga;
end
funccount =  funccount +  output.funccount;

% GA always uses row major input. A wrapper around the fitness function
% to take care of shape of the input vector. 
    function f = fitnessWrapper(pop)
        % fitnessWrapper is a nested function. We know what is the X (the
        % shape of start point)
        if size(X,1) ~= 1
            f = feval(FUN,pop',objFcnArg{:});
        else
            f = feval(FUN,pop ,objFcnArg{:});
        end
    end
end