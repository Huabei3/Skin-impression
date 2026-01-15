function state = gaplotexpectation(options,state,flag)
%GAPLOTEXPECTATION Plots raw scores against the expected number of offspring.
%   STATE = GAPLOTEXPECTATION(OPTIONS,STATE,FLAG) plots the raw scores
%   against the expected number of offspring.
%
%   Example:
%    Create an options structure that uses GAPLOTEXPECTATION
%    as the plot function
%     options = gaoptimset('PlotFcns',@gaplotexpectation);

%   Copyright 2003-2009 The MathWorks, Inc.
%   $Revision: 1.1.6.1 $  $Date: 2009/08/29 08:24:44 $

% we have to store scores because the expectation in the state are for the
% last generation and the scores are for the next generation.
persistent scores;

if  ~isfield(state,'Expectation') || size(state.Score,2) > 1
    title('Expectation Plot: not available','interp','none');
    return;
end

switch flag
    case 'init'
        scores = state.Score;
        % Expectation is a vector of zeros because there is no expectation
        % in first iteration at all.
        plotExpec = plot(scores,zeros(1,length(scores)),'.');
        set(plotExpec,'Tag','gaplotexpectation');
        xlabel('Raw scores','interp','none');
        ylabel('Expectation','interp','none');
        title('Fitness Scaling','interp','none')
    case 'iter'
        %This is a safeguard when population size is reduced at run time.
        if length(state.Score) ~= length(state.Expectation)
            scores = state.Score(length(state.Score)-length(state.Expectation)+1:end);
        end
        plotExpec = findobj(get(gca,'Children'),'Tag','gaplotexpectation');
        set(plotExpec,'Xdata',scores,'Ydata',state.Expectation);
        scores = state.Score;
end
