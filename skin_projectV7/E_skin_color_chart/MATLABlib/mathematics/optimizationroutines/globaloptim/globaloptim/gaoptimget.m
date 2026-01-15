function o = gaoptimget(options,name,default,flag)
%GAOPTIMGET Get GA OPTIONS parameter value.
%   VAL = GAOPTIMGET(OPTIONS,'NAME') extracts the value of the named parameter
%   from optimization options structure OPTIONS, returning an empty matrix if
%   the parameter value is not specified in OPTIONS.  It is sufficient to
%   type only the leading characters that uniquely identify the
%   parameter.  Case is ignored for parameter names.  [] is a valid OPTIONS
%   argument.
%   
%   VAL = GAOPTIMGET(OPTIONS,'NAME') extracts the parameter NAME 
%   For example:
%     
%     opts = gaoptimset('Generations',200);
%     val = gaoptimget(opts,'Generations');
%   
%   returns val = 200.
%   
%   See also GAOPTIMSET.

%   Copyright 2003-2009 The MathWorks, Inc.
%   $Revision: 1.1.6.2 $  $Date: 2009/10/10 20:08:19 $


if nargin < 2
  error('globaloptim:GAOPTIMGET:inputarg','Not enough input arguments.');
end
if nargin < 3
  default = [];
end
if nargin < 4
   flag = [];
end

% undocumented usage for fast access with no error checking
if isequal('fast',flag)
   o = gaoptimgetfast(options,name,default);
   return
end

if ~isempty(options) && ~isa(options,'struct')
  error('globaloptim:GAOPTIMGET:firstargerror','First argument must be an options structure created with GAOPTIMSET.');
end

if isempty(options)
  o = default;
  return;
end

optionsstruct = struct('PopulationType', [], ...
    'PopInitRange',[], ...
    'PopulationSize',[], ...
    'EliteCount',[], ...
    'CrossoverFraction',[], ...
    'ParetoFraction',[], ...    
    'MigrationDirection',[], ...
    'MigrationInterval',[], ...
    'MigrationFraction',[], ...
    'Generations',[], ...
    'TimeLimit',[], ...
    'FitnessLimit',[], ...
    'StallGenLimit',[], ...
    'StallTimeLimit',[], ...
    'TolFun', [], ...
    'TolCon',[], ...
    'InitialPopulation',[], ...
    'InitialScores',[], ...
    'InitialPenalty', [], ...
    'PenaltyFactor', [], ...
    'PlotInterval',[], ...
    'FitnessScalingFcn',[], ...
    'SelectionFcn',[], ...
    'CrossoverFcn',[], ...
    'MutationFcn',[], ...
    'DistanceMeasureFcn',[], ...
    'Display',[], ...
    'PlotFcns',[], ...
    'OutputFcns',[], ...
    'CreationFcn',[], ...
    'HybridFcn',[], ...
    'Vectorized',[], ...
    'UseParallel',[]);      

Names = fieldnames(optionsstruct);
%[m,n] = size(Names);
names = lower(Names);

lowName = lower(name);
j = strmatch(lowName,names);
if isempty(j)               % if no matches
  error('globaloptim:GAOPTIMGET:invalidproperty',sprintf(['Unrecognized property name ''%s''.  ' ...
                 'See GAOPTIMSET for possibilities.'], name));
elseif length(j) > 1            % if more than one match
  % Check for any exact matches (in case any names are subsets of others)
  k = strmatch(lowName,names,'exact');
  if length(k) == 1
    j = k;
  else
    msg = sprintf('Ambiguous property name ''%s'' ', name);
    msg = [msg '(' Names{j(1),:}];
    for k = j(2:length(j))'
      msg = [msg ', ' Names{k,:}];
    end
    msg = sprintf('%s).', msg);
    error('globaloptim:GAOPTIMGET:ambiguousproperty',msg);
  end
end

if any(strcmp(Names,Names{j,:}))
   o = options.(Names{j,:});
  if isempty(o)
    o = default;
  end
else
  o = default;
end

%------------------------------------------------------------------
function value = gaoptimgetfast(options,name,defaultopt)
%OPTIMGETFAST Get OPTIM OPTIONS parameter with no error checking so fast.
%   VAL = OPTIMGETFAST(OPTIONS,FIELDNAME,DEFAULTOPTIONS) will get the
%   value of the FIELDNAME from OPTIONS with no error checking or
%   fieldname completion. If the value is [], it gets the value of the
%   FIELDNAME from DEFAULTOPTIONS, another OPTIONS structure which is 
%   probably a subset of the options in OPTIONS.
%

if ~isempty(options)
        value = options.(name);
else
    value = [];
end

if isempty(value)
    value = defaultopt.(name);
end


