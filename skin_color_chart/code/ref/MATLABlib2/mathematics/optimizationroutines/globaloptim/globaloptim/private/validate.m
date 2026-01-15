function [options,gLength,fitness,nonlcon]  = validate(options,type,gLength,fitness,nonlcon,user_options)
%VALIDATE validates the contents of the fitness function, genome length and
%   options struct. 
%   [OUT,nvars,fitness,constr] = VALIDATE(GenomeLength,FitnessFcn,Nonlcon,IN,type) 
%   validates the FitnessFcn, GenomeLength and the structure IN. OUT is a
%   structure which have all the fields in IN and it gets other fields
%   like FitnessFcn, GenomeLength, etc. The output 'nvars' is the number of
%   variables, 'fitness' is the function handle to the fitness function,
%   and 'nonlcon' is the function handle to the nonlinear constraint
%   function. 
%
%   This function is private to GA and GAMULTIOBJ.

%   Copyright 2003-2009 The MathWorks, Inc.
%   $Revision: 1.1.6.4 $  $Date: 2010/10/08 16:51:56 $

if nargin < 6
    user_options = options;
end
% Make sure user_options is consistent with gaoptimset
user_options = gaoptimset(user_options);

% range check each field
stringSet('PopulationType',options.PopulationType,{'doubleVector','custom','bitString'});
% Determine the verbosity
switch  options.Display
    case {'off','none'}
        options.Verbosity = 0;
    case 'final'
        options.Verbosity = 1;
    case 'iter'
        options.Verbosity = 2;
    case 'diagnose'
        options.Verbosity = 3;
end


validNumberofVariables(gLength)
% PopulationSize validation
if ischar(options.PopulationSize) && strcmpi(options.PopulationSize,'15*numberofvariables')
        options.PopulationSize = 15*gLength;
        options.PopulationSize  = floor(options.PopulationSize);
end
positiveIntegerArray('PopulationSize',options.PopulationSize);
% If population size is a matrix then we want to get the row vector expansion
options.PopulationSize = options.PopulationSize(:)';

% Generations validation
if ischar(options.Generations) && strcmpi(options.Generations,'200*numberofvariables')
        options.Generations = 200*gLength;
        options.Generations = floor(options.Generations);
end
positiveInteger('Generations',options.Generations);

% These options does not apply to gamultiobj
if ~isempty(options.FitnessLimit) 
    realScalar('FitnessLimit',options.FitnessLimit);
end
if ~isempty(options.StallTimeLimit)
    positiveScalar('StallTimeLimit',options.StallTimeLimit);
end
if ~isempty(options.FitnessScalingFcn) 
    [options.FitnessScalingFcn,options.FitnessScalingFcnArgs] = functionHandleOrCell('FitnessScalingFcn',options.FitnessScalingFcn);
end
% Elite count validation
if ~isempty(options.EliteCount)
    nonNegInteger('EliteCount',options.EliteCount);
    % Protect against EliteCount greater than PopulationSize.
    if options.EliteCount >= sum(options.PopulationSize)
        error(message('globaloptim:validate:EliteCountGTPop'));
    end
end

% These fields does not apply to GA
if ~isempty(options.ParetoFraction)
    realUnitScalar('ParetoFraction',options.ParetoFraction);
end
if ~isempty(options.DistanceMeasureFcn)
     [options.DistanceMeasureFcn,options.DistanceMeasureFcnArgs] = functionHandleOrCell('DistanceMeasureFcn',options.DistanceMeasureFcn);
end

stringSet('Vectorized',options.Vectorized,{'on','off'});
realUnitScalar('CrossoverFraction',options.CrossoverFraction);
positiveInteger('MigrationInterval',options.MigrationInterval);
realUnitScalar('MigrationFraction',options.MigrationFraction);
stringSet('MigrationDirection',options.MigrationDirection,{'both','forward'});
nonNegScalar('TolFun',options.TolFun);
nonNegScalar('TolCon',options.TolCon);
positiveScalar('TimeLimit',options.TimeLimit);
positiveInteger('StallGenLimit',options.StallGenLimit);

positiveInteger('PlotInterval',options.PlotInterval);

% Test for valid strings
if ~isempty(options.UseParallel)
    stringSet('UseParallel',options.UseParallel,{'never','always'});
    options.SerialUserFcn = strcmpi(options.UseParallel,'never');
else
    options.SerialUserFcn = true;
end

% Creation function for constrained GA has different default
if isempty(user_options.CreationFcn) && strcmp(type,'linearconstraints')
    % Creation function for linearly constrained GA has different default
    options.CreationFcn = @gacreationlinearfeasible;
    options.CreationFcnArgs = {};
else
    [options.CreationFcn,options.CreationFcnArgs] = functionHandleOrCell('CreationFcn',options.CreationFcn);
end

[options.SelectionFcn,options.SelectionFcnArgs] = functionHandleOrCell('SelectionFcn',options.SelectionFcn);
[options.CrossoverFcn,options.CrossoverFcnArgs] = functionHandleOrCell('CrossoverFcn',options.CrossoverFcn);


% Mutation function validation
if isempty(user_options.MutationFcn) && ~strcmp(type,'unconstrained')
    % Mutation function for constrained GA has different default
    options.MutationFcn = @mutationadaptfeasible;
    options.MutationFcnArgs = {};
else
    [options.MutationFcn,options.MutationFcnArgs] = functionHandleOrCell('MutationFcn',options.MutationFcn);
end

if ~isempty(options.HybridFcn)
    [options.HybridFcn,options.HybridFcnArgs] = functionHandleOrCell('HybridFcn',options.HybridFcn);
    stringSet('HybridFcn',func2str(options.HybridFcn),{'patternsearch','fminsearch','fminunc','fmincon','fgoalattain'});
end

[options.PlotFcns,options.PlotFcnsArgs] = functionHandleOrCellArray('PlotFcns',options.PlotFcns);
[options.OutputFcns,options.OutputFcnsArgs] = functionHandleOrCellArray('OutputFcns',options.OutputFcns);

options.FitnessFcnArgs = {};
options.NonconFcnArgs = {};
if ~isempty(fitness)
    [fitness,FitnessFcnArgs] = functionHandleOrCell('FitnessFcn',fitness);
    fitness = @(x) fitness(x,FitnessFcnArgs{:});
else
    fitness = [];
end
if ~isempty(nonlcon)
    [nonlcon,NonconFcnArgs] = functionHandleOrCell('NonconFcn',nonlcon);
    nonlcon = @(x) nonlcon(x,NonconFcnArgs{:});
else
    nonlcon = [];
end

options = rangeCorrection('PopInitRange',gLength,options);

% Additional checks for 'bitString' population type
if strcmpi(options.PopulationType,'bitString') 
    % Verify that if population type is 'bitString' then initial population is
    % not 'logical' data type (common mistake in input)    
    if islogical(options.InitialPopulation)
        options.InitialPopulation = double(options.InitialPopulation);
    end
    % Also make sure that the default CrossoverFcn is set to
    % constraint-preserving crossover function
    if isempty(user_options.CrossoverFcn)
       options.CrossoverFcn = @crossoverscattered;
       options.CrossoverFcnArgs = {};
    end
    % Warn if crossover function is known not to work with bitString and
    % what are supported ones for bitString.
    crossoverfcn = func2str(options.CrossoverFcn);
    if any(strcmpi(crossoverfcn, {'crossoverintermediate','crossoverarithmetic','crossoverheuristic'}))
       warning(message('globaloptim:validate:bitStringCrossoverFcn', crossoverfcn));
       options.CrossoverFcn = @crossoverscattered;
       options.CrossoverFcnArgs = {};       
    end
end

% Remaining tests do not apply to custom population
if strcmpi(options.PopulationType,'custom')
    return;
end

if ~isnumeric(gaoptimget(options,'InitialPopulation'))
    error(message('globaloptim:validate:invalidInitialPopulation'));
end
if ~isnumeric(gaoptimget(options,'InitialScores'))
    error(message('globaloptim:validate:invalidInitialScores'));
end

% Make sure that initial population is consistent with GenomeLength
if ~isempty(options.InitialPopulation) && size(options.InitialPopulation,2) ~= gLength
    error(message('globaloptim:validate:wrongSizeInitialPopulation'));
end


%-------------------------------------------------------------------------------

% Number of variables
function validNumberofVariables(GenomeLength)
valid =  isnumeric(GenomeLength) && isscalar(GenomeLength)&& (GenomeLength > 0) ...
         && (GenomeLength == floor(GenomeLength));
if ~valid
   error(message('globaloptim:validate:validNumberofVariables:notValidNvars'));
end

%------------------------------------------------------------------------------
function options = rangeCorrection(property,nvars,options)
%rangeCorrection Check the size of PopInitRange

Range = options.PopInitRange;
% Check only for double data type range
if ~isa(Range,'double')
    return;
end

if size(Range,1) ~=2
    error(message('globaloptim:rangeCorrection:invalidPopInitRange', property));  
end
lb = Range(1,:);
lb = lb(:);
lenlb = length(lb);
ub = Range(2,:);
ub = ub(:);
lenub = length(ub);

% Check maximum length
if lenlb > nvars
   lb = lb(1:nvars);   
   lenlb = nvars;
elseif lenlb < nvars
   lb = [lb; lb(end)*ones(nvars-lenlb,1)];
   lenlb = nvars;
end

if lenub > nvars
   ub = ub(1:nvars);
   lenub = nvars;
elseif lenub < nvars
   ub = [ub; ub(end)*ones(nvars-lenub,1)];
   lenub = nvars;
end
% Check feasibility of range
len = min(lenlb,lenub);
if any( lb( (1:len)' ) > ub( (1:len)' ) )
   count = full(sum(lb>ub));
   if count == 1
      msg=sprintf(['\nExiting due to infeasibility:  %i lower range exceeds the' ...
            ' corresponding upper range.\n'],count);
   else
      msg=sprintf(['\nExiting due to infeasibility:  %i lower ranges exceed the' ...
            ' corresponding upper ranges.\n'],count);
   end
   error('globaloptim:rangeCorrection:infeasibleRange',msg);
end
% Check if -inf in ub or inf in lb   
if any(eq(ub, -inf)) 
   error('globaloptim:rangeCorrection:infRange','-Inf detected in upper range: upper range must be > -Inf.');
elseif any(eq(lb,inf))
   error('globaloptim:rangeCorrection:infRange','+Inf detected in lower range: lower range must be < Inf.');
end

options.PopInitRange = [lb,ub]';
%------------------------------End of rangeCorrection --------------------------


