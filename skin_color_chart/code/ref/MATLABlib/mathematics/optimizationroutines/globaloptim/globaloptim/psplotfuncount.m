function stop = psplotfuncount(optimvalues,flag)
%PSPLOTFUNCOUNT Plot function evaluations every iteration.
%   STOP = PSPLOTFUNCOUNT(OPTIMVALUES,FLAG) where OPTIMVALUES is a
%   structure with the following fields: 
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
%   $Revision: 1.1.6.2 $  $Date: 2010/10/08 16:51:11 $

stop = false;
switch flag
    case 'init'
    plotFunC = plot(optimvalues.iteration, optimvalues.funccount,'kd', ...
        'MarkerSize',5,'MarkerFaceColor',[1 0 1]);
    set(plotFunC,'Tag','psplotfuncount');
    xlabel('Iteration','interp','none'); 
    ylabel('Function evaluations per interval','interp','none');
    title(sprintf('Total Function Evaluations: %i',optimvalues.funccount),'interp','none');
    case 'iter'
    plotFunC = findobj(get(gca,'Children'),'Tag','psplotfuncount');
    totalFunCount = sum(get(plotFunC,'Ydata'));
    newX = [get(plotFunC,'Xdata') optimvalues.iteration];
    newY = [get(plotFunC,'Ydata') (optimvalues.funccount - totalFunCount)];
    set(plotFunC,'Xdata',newX,'Ydata',newY);
    set(get(gca,'Title'),'String',sprintf('Total Function Evaluations: %i',optimvalues.funccount));
end

