function [stop,optold,optchanged] = psoutput(OutputFcns, OutputFcnArgs,optimval,optold,flag)
%PSOUTPUT Helper function that manages the output functions.
%
%   [STATE, OPTNEW,OPTCHANGED] = PSOUTPUT(OPTIMVAL,OPTOLD,FLAG) runs each of
%   the output functions in the options.OutputFcn cell array.
%
%   Private to PFMINLCON, PFMINBND, PFMINUNC.

%   Copyright 2003-2009 The MathWorks, Inc.
%   $Revision: 1.1.6.2 $  $Date: 2009/11/05 16:59:51 $

%Initialize
stop   = false;
optchanged = false;

% get the functions and return if there are none
if(isempty(OutputFcns))
    return
end
% call each output function
stop = false(length(OutputFcns),1);
for i = 1:length(OutputFcns)
    [stop(i) ,optnew , changed ] = feval(OutputFcns{i},optimval,optold,flag,OutputFcnArgs{i}{:});
    if changed  %If changes are not duplicates, we will get all the changes
        optold = optnew;
        optchanged = true;
    end
end
% If any stop(i) is true we set the stop to true
stop = any(stop);
