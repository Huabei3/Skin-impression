function stop = psplotbestx(optimvalues,flag)
%PSPLOTBESTX PlotFcn to plot best X value.
%   STOP = PSPLOTBESTX(OTIMVALUES,FLAG) where OPTIMVALUES is a structure
%   with the following fields: 
%              x: current point X
%      iteration: iteration count
%           fval: function value
%       meshsize: current mesh size
%      funccount: number of function evaluations
%         method: method used in last iteration
%         TolFun: tolerance on function value in last iteration
%           TolX: tolerance on X value in last iteration
%
%   FLAG: Current state in which PlotFcn is called. Possible values are:
%           init: initialization state
%           iter: iteration state
%           done: final state
%
%   STOP: A boolean to stop the algorithm.
%
%   See also PATTERNSEARCH, GA, PSOPTIMSET.


%   Copyright 2003-2007 The MathWorks, Inc.
%   $Revision: 1.1.6.2 $  $Date: 2010/10/08 16:51:10 $

stop = false;
switch flag
    case 'init'
        set(gca,'xlimmode','manual','zlimmode','manual', ...
            'alimmode','manual')
        title('Current Best Point','interp','none')
        Xlength = numel(optimvalues.x);
        xlabel(sprintf('Number of variables (%i)',Xlength),'interp','none');
        ylabel('Current best point','interp','none');
        plotBestX = bar(optimvalues.x(:));
        set(plotBestX,'Tag','psplotbestx');
        set(plotBestX,'edgecolor','none')
        set(gca,'xlim',[0,1 + Xlength])
    case 'iter'
        plotBestX = findobj(get(gca,'Children'),'Tag','psplotbestx');
        set(plotBestX,'Ydata',optimvalues.x(:))
end





