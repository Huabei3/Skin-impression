function stop = mulprocplot(options,optimvalues,flag,lengths)
%MULPROCPLOT PlotFcn used for SAMULTIPROCESSORDEMO
%   STOP = MULPROCPLOT(OPTIONS,OPTIMVALUES,FLAG) where OPTIMVALUES is a
%   structure with the following fields:
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
%   FLAG: Current state in which PlotFcn is called. Possible values are:
%           init: initialization state
%           iter: iteration state
%           done: final state
%
%   STOP: A boolean to stop the algorithm.
%

%   Copyright 2006-2010 The MathWorks, Inc.
%   $Revision: 1.1.6.2 $  $Date: 2010/05/10 17:17:41 $

schedule = optimvalues.x;
nrows = size(schedule,1);
% Remove zero columns (all processes are idle)
maxlen = 0;
for i = 1:nrows
    if max(nnz(schedule(i,:))) > maxlen
        maxlen = max(nnz(schedule(i,:)));
    end
end
schedule = schedule(:,1:maxlen);

toplot = zeros(size(schedule));
[nrows ncols] = size(schedule);
for i = 1:nrows
    for j = 1:ncols
        if schedule(i,j)==0 % idle process
            toplot(i,j) = 0;
        else
            toplot(i,j) = lengths(i,schedule(i,j));
        end
    end
end

stop = false;
switch flag
    case 'init'
        set(gca,'xlimmode','manual','zlimmode','manual', ...
            'alimmode','manual')
        title('Current Point','interp','none')
        Xlength = size(toplot,1);
        ylabel('Time','interp','none');
        plotBestX = bar(toplot, 'stacked');
        set(plotBestX,'Tag','mulplotx');
        set(plotBestX,'edgecolor','none')
        set(gca,'xlim',[0,1 + Xlength])
    case 'iter'
         bar(toplot, 'stacked','edgecolor','none');
end
