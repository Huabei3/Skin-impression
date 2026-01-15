function [state,options,optchanged] = gaoutput(FitnessFcn,options,state,flag)
%GAOUTPUT Helper function that manages the output functions for GA.
%
%   [STATE, OPTIONS, OPTCHANGED] = ...
%   GAOUTPUT(FitnessFcn, options, state, flag) runs each of the display
%   functions in the options.OutputFcns cell array.
%
%   this is a helper function called by ga between each generation, and is
%   not typically called directly.

%   Copyright 2003-2007 The MathWorks, Inc.
%   $Revision: 1.1.6.1 $  $Date: 2009/08/29 08:26:14 $


% get the functions and return if there are none
optchanged = false;
functions = options.OutputFcns;
if(isempty(functions))
    return
end

% call each output function
stopFlag = [];
args = options.OutputFcnsArgs;
for i = 1:length(functions)
    [state,optnew,changed] = feval(functions{i},options,state,flag,args{i}{:});
    if ~isempty(state.StopFlag)
        stopFlag = [stopFlag state.StopFlag ';'];
    end
    if changed %If changes are not duplicates, we will get all the changes
       % Keep LinearConstr out of options and accept new options
       LinearConstr = options.LinearConstr;
       type = LinearConstr.type;
       gLength = size(state.Population,2);
       options = gaoptimset(options,optnew);
       options = validate(options,type,gLength,[],[]);
       options.LinearConstr = LinearConstr;
       optchanged = true;
    end
end

state.StopFlag = stopFlag;