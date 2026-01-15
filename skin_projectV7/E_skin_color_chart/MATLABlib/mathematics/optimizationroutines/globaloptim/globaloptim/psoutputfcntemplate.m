function [stop,options,optchanged]  = psoutputfcntemplate(optimvalues,options,flag)
%PSOUTPUTFCNTEMPLATE Template to write custom OutputFcn for PATTERNSEARCH.
%   [STOP,OPTIONS,OPTCHANGED] = PSOUTPUTFCNTEMPLATE(OPTIMVALUES,OPTIONS,FLAG) 
%   where OPTIMVALUES is a structure containing information about the state
%   of the optimization:
%            x: current point X 
%    iteration: iteration number
%         fval: function value 
%     meshsize: current mesh size 
%    funccount: number of function evaluations
%       method: method used in last iteration 
%       TolFun: tolerance on fval
%         TolX: tolerance on X
%
%   OPTIONS: Options structure used by PATTERNSEARCH.
%
%   FLAG: Current state in which OutPutFcn is called. Possible values are:
%         init: initialization state 
%         iter: iteration state
%    interrupt: intermediate state
%         done: final state
% 		
%   STOP: A boolean to stop the algorithm.
%
%   OPTCHANGED: A boolean indicating if the options have changed.
%
%	See also PATTERNSEARCH, GA, PSOPTIMSET, SEARCHFCNTEMPLATE


%   Copyright 2003-2006 The MathWorks, Inc.
%   $Revision: 1.1.6.1 $  $Date: 2009/08/29 08:25:09 $

stop = false;
optchanged = false;

switch flag
    case 'init'
        disp('Starting the algorithm');
    case {'iter','interrupt'}
        disp('Iterating ...')
    case 'done'
        disp('Performing final task');
end
  