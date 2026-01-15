function stop = gsplotfunccount(optimValues, state)
%GSPLOTFUNCCOUNT Plot function evaluations after every local solver call.
%
%   STOP = GSPLOTFUNCCOUNT(OPTIMVALUES, STATE) plots OPTIMVALUES.FUNCCOUNT
%   against OPTIMVALUES.LOCALRUNINDEX after every local solver call. This
%   function is called from the global solver with the following inputs:
%
%   OPTIMVALUES: Information after the current local solver call.
%    localsolution: solution returned from current call to the local solver
%    localrunindex: index of current call to the local solver
%        funccount: number of function evaluations
%            bestx: best solution found so far               
%         bestfval: function value at bestx
%
%   OPTIMVALUES.LOCALSOLUTION: Solution returned from current call to the
%                              local solver.
%                X: solution returned from local solver
%             Fval: function value at X
%         Exitflag: exit flag from current call to the local solver
% 
%   STATE: Current state in which plot function is called. 
%          Possible values are:
%             init: initialization state 
%             iter: after every call to the local solver 
%             done: final state
%
%   STOP: A boolean to stop the algorithm.
%
%   See also GLOBALSEARCH, MULTISTART

%   Copyright 2010 The MathWorks, Inc.
%   $Revision: 1.1.6.2 $  $Date: 2010/03/31 18:22:29 $

% Initialize stop boolean to false.
stop = false;

% Update the plot.
switch state
    case 'init'
        % Create the plot. 
        plot(optimValues.localrunindex, optimValues.funccount,'kd', ...
            'MarkerSize',5,'MarkerFaceColor',[1 0 1], 'Tag','gsplotfunccount');
        xlabel('Local solver call','interp','none');
        ylabel('Function evaluations','interp','none');
        
        % Create a title for the plot.
        title(sprintf('Total Function Evaluations: %i',optimValues.funccount), ...
            'interp','none');
        
    case 'iter'
        % Update the plot with the current number of function evaluations.        
        plotFunC = findobj(get(gca,'Children'),'Tag','gsplotfunccount');
        newX = [get(plotFunC,'Xdata') optimValues.localrunindex];
        newY = [get(plotFunC,'Ydata') optimValues.funccount];
        set(plotFunC,'Xdata',newX, 'Ydata',newY);
        
        % Update the title.
        set(get(gca,'Title'),'String', ...
            sprintf('Total Function Evaluations: %i',optimValues.funccount));
        
    case 'done'
        % No clean up tasks required for this plot function.
end