function options  = savalidate(options,problem)
% SAVALIDATE is used to ensure that the options structure for a SIMULANNEAL
%   problem is valid and each field in it has an acceptable type.
%
%   This function is private to SIMULANNEAL.

%   Copyright 2006-2010 The MathWorks, Inc.
%   $Revision: 1.1.6.4 $  $Date: 2010/10/08 16:51:53 $

% Sanity check for the options structure
options = saoptimset(options);

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
    otherwise
        options.Verbosity = 1;
end

% MaxFunEvals default value is string
if strcmpi(options.MaxFunEvals,'3000*numberofvariables')
    options.MaxFunEvals = 3000*problem.nvar;
end
% StallIterLimit default value is string
if strcmpi(options.StallIterLimit,'500*numberofvariables')
    options.StallIterLimit = 500*problem.nvar;
end

if strcmpi(options.HybridInterval, 'end')
    options.HybridInterval = [];
elseif strcmpi(options.HybridInterval, 'never')
    options.HybridFcn = [];
elseif isempty(options.HybridInterval)
else
    nonNegInteger('HybridInterval', options.HybridInterval)
end

positiveInteger('MaxIter', options.MaxIter)
positiveInteger('MaxFunEvals', options.MaxFunEvals);
positiveInteger('StallIterLimit', options.StallIterLimit)
positiveScalarArray('InitialTemperature',options.InitialTemperature);

positiveScalar('TimeLimit', options.TimeLimit)
realScalar('ObjectiveLimit', options.ObjectiveLimit)

nonNegInteger('DisplayInterval', options.DisplayInterval)
nonNegInteger('ReannealInterval', options.ReannealInterval)
nonNegInteger('PlotInterval', options.PlotInterval)

nonNegScalar('TolFun',options.TolFun);

% These functions not only savalidate, they separate fcns from args for
% speed.
[options.AnnealingFcn,options.AnnealingFcnArgs] = functionHandleOrCell('AnnealingFcn',options.AnnealingFcn);
[options.TemperatureFcn,options.TemperatureFcnArgs] = functionHandleOrCell('TemperatureFcn',options.TemperatureFcn);
[options.AcceptanceFcn,options.AcceptanceFcnArgs] = functionHandleOrCell('AcceptanceFcn',options.AcceptanceFcn);

if ~isempty(options.HybridFcn)
    [options.HybridFcn,options.HybridFcnArgs] = functionHandleOrCell('HybridFcn',options.HybridFcn);
end

% this special case takes an array of function cells
[options.PlotFcns,options.PlotFcnsArgs] = functionHandleOrCellArray('PlotFcns',options.PlotFcns);
[options.OutputFcns,options.OutputFcnsArgs] = functionHandleOrCellArray('OutputFcns',options.OutputFcns);

% Make the length of the options.InitialTemperature to nvar
len_temp = length(options.InitialTemperature);
if len_temp > problem.nvar
    warning(message('globaloptim:savalidate:lengthOfInitialTemperature'));
    options.InitialTemperature(len_temp:end) = [];
elseif len_temp < problem.nvar
    temperature = zeros(problem.nvar,1);
    temperature(1:len_temp) = options.InitialTemperature;
    temperature(len_temp+1 : end)= options.InitialTemperature(end);
    options.InitialTemperature = temperature;
end
% We want initialtemperature to be a column vector
options.InitialTemperature = options.InitialTemperature(:);

