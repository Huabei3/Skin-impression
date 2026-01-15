function state = gaplotrange(options,state,flag)
%GAPLOTRANGE Plots the mean and the range of the scores.
%   STATE = GAPLOTRANGE(OPTIONS,STATE,FLAG) plots the mean and the range
%   (best and the worst) of scores.  
%
%   Example:
%   Create an options structure that uses GAPLOTRANGE
%   as the plot function
%     options = gaoptimset('PlotFcns',@gaplotrange);

%   Copyright 2003-2010 The MathWorks, Inc.
%   $Revision: 1.1.6.2 $  $Date: 2010/03/31 18:22:27 $

if isinf(options.Generations) || size(state.Score,2) > 1
    title('Plot Not Available','interp','none');
    return;
end
generation = state.Generation;
score = state.Score;
smean = mean(score);
Y = smean;
L = smean - min(score);
U = max(score) - smean;

switch flag

    case 'init'
        set(gca,'xlim',[1,options.Generations+1]);
        plotRange = errorbar(generation,Y,L,U);
        set(plotRange,'Tag','gaplotrange');
        title('Best, Worst, and Mean Scores','interp','none')
        xlabel('Generation','interp','none')
    case 'iter'
        plotRange = findobj(get(gca,'Children'),'Tag','gaplotrange');
        if feature('HGUsingMATLABClasses')
            newX = [get(plotRange,'Xdata') generation];
            newY = [get(plotRange,'Ydata') Y];
            newL = [get(plotRange,'Ldata') L];
            newU = [get(plotRange,'Udata') U];
        else
            newX = [get(plotRange,'Xdata'); generation];
            newY = [get(plotRange,'Ydata'); Y];
            newL = [get(plotRange,'Ldata'); L];
            newU = [get(plotRange,'Udata'); U];
        end        
        set(plotRange, 'Xdata',newX,'Ydata',newY,'Ldata',newL,'Udata',newU);
end

