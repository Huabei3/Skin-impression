function [stop,options,optchanged] = saoutputfcntemplate(options,optimvalues,flag)
%SAOUTPUTFCNTEMPLATE Template to write custom OutputFcn for SIMULANNEALBND
%   [STOP,OPTIONS,OPTCHANGED] = SAOUTPUTFCNTEMPLATE(OPTIONS,OPTIMVALUES,FLAG) 
%   OPTIMVALUES is a structure with the following fields:  
%              x: current point 
%           fval: function value at x
%          bestx: best point found so far
%       bestfval: function value at bestx
%    temperature: current temperature
%      iteration: current iteration
%      funccount: number of function evaluations
%             t0: start time
%              k: annealing parameter 'k'
%
%   OPTIONS: The options structure created by using SAOPTIMSET
%
%   FLAG: Current state in which OutputFcn is called. Possible values are:
%           init: initialization state
%           iter: iteration state
%           done: final state
%
%   STOP: A boolean to stop the algorithm.
% 		
%   OPTCHANGED: A boolean indicating if the options have changed.
%

%   Copyright 2006-2009 The MathWorks, Inc.
%   $Revision: 1.1.6.1 $  $Date: 2009/08/29 08:25:21 $

stop = false;
optchanged = false;
switch flag
   case 'init'
        disp('Initializing output function');
    case 'iter'
        disp('Iterating ...')
    case 'done'
        disp('Performing final task');
end
