function [stop,optold,optchanged] = saoutput(OutputFcns,OutputFcnArgs,optimvalues,optold,flag)
%SAOUTPUT Helper function that manages the output functions.
%
%   [STATE, OPTNEW,OPTCHANGED] = SAOUTPUT(OPTIMVAL,OPTOLD,FLAG) runs each of
%   the output functions in the options.OutputFcn cell array.
%

%   Copyright 2006-2009 The MathWorks, Inc.
%   $Revision: 1.1.6.2 $  $Date: 2009/11/05 16:59:53 $


% Initialize
stop   = false;
optchanged = false;

% Get the functions and return if there are none
if(isempty(OutputFcns))
    return
end

% Call each output function
for i = 1:length(OutputFcns)
    [stop ,optnew , changed ] = feval(OutputFcns{i},optold,optimvalues, ...
        flag,OutputFcnArgs{i}{:});
    if changed  % If changes are not duplicates, we will get all the changes
        optold = optnew;
        optchanged = true;
    end
end
% If any stop(i) is true we set the stop to true
stop = any(stop);