function stop = saplotbestx(options,optimvalues,flag)
%SAPLOTBESTX PlotFcn to plot best X value.
%   STOP = SAPLOTBESTX(OPTIONS,OPTIMVALUES,FLAG) where OPTIMVALUES is a
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
%    Create an options structure that will use SAPLOTBESTX as the plot
%    function
%     options = saoptimset('PlotFcns',@saplotbestx);

%   Copyright 2006-2010 The MathWorks, Inc.
%   $Revision: 1.1.6.3 $  $Date: 2010/10/08 16:51:15 $

stop = false;
switch flag
    case 'init'
        set(gca,'xlimmode','manual','zlimmode','manual', ...
            'alimmode','manual')
        title('Best point','interp','none')
        Xlength = numel(optimvalues.bestx);
        xlabel(sprintf('Number of variables (%i)',Xlength),'interp','none');
        ylabel('Best point','interp','none');
        plotBestX = bar(optimvalues.bestx(:));
        set(plotBestX,'Tag','saplotbestx');
        set(plotBestX,'edgecolor','none')
        set(gca,'xlim',[0,1 + Xlength])
    case 'iter'
        plotBestX = findobj(get(gca,'Children'),'Tag','saplotbestx');
        set(plotBestX,'Ydata',optimvalues.bestx(:))
end