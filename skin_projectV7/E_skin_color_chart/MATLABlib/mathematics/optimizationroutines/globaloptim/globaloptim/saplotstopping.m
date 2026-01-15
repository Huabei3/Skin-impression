function stop = saplotstopping(options,optimvalues,flag)
%SAPLOTSTOPPING PlotFcn to plot stopping criteria satisfaction.
%   STOP = SAPLOTSTOPPING(OPTIONS,OPTIMVALUES,FLAG) where OPTIMVALUES is a
%   structure with the following fields:
%              x: current point 
%           fval: function value at x
%          bestx: best point found so far
%       bestfval: function value at bestx
%    temperature: current temperature
%      iteration: current iteration
%      funccount: number of function evaluations
%             t0: start time
%              k: annealing parameter
%
%   OPTIONS: The options structure created by using SAOPTIMSET
%
%   FLAG: Current state in which PlotFcn is called. Possible values are:
%           init: initialization state
%           iter: iteration state
%           done: final state
%
%   STOP: A boolean to stop the algorithm.
%
%   Example:
%    Create an options structure that will use SAPLOTSTOPPING
%    as the plot function
%     options = saoptimset('PlotFcns',@saplotstopping);

%   Copyright 2006-2010 The MathWorks, Inc.
%   $Revision: 1.1.6.2 $  $Date: 2010/05/10 17:16:53 $

stop = false;
% Calculate fraction of 'doneness' for each criterion
func = optimvalues.funccount / options.MaxFunEvals;
iter = optimvalues.iteration / options.MaxIter;
time = (cputime-optimvalues.t0) / options.TimeLimit;

% Multiply ratios by 100 to get percentages
ydata = 100 * [time, iter, func];

switch flag
    case 'init'
        barh(ydata,'Tag','saplotstopping')
        set(gca,'xlim',[0,100],'yticklabel', ...
            {'Time','Iteration', 'f-count'},'climmode','manual')
        xlabel('% of criteria met','interp','none')
        title('Stopping Criteria','interp','none')
    case 'iter'
        ch = findobj(get(gca,'Children'),'Tag','saplotstopping');
        set(ch,'YData',ydata);
end