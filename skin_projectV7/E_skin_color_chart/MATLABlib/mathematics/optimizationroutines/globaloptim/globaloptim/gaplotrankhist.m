function state = gaplotrankhist(options,state,flag)
%GAPLOTRANKHIST Plots a histogram of all ranks.
%
%   Example:
%    Create an options structure that will use GAPLOTRANK
%    as the plot function
%     options = gaoptimset('PlotFcns',@gaplotrank);

%   Copyright 2007 The MathWorks, Inc.
%   $Revision: 1.1.6.1 $  $Date: 2009/08/29 08:24:50 $

if ~isfield(state,'Rank') 
      title('Rank Histogram: not available','interp','none');
    return;
end

% maximum limit for x axis
maxRank = 5;

switch flag
    case 'init'
        title('Rank histogram','interp','none')
        xlabel('Rank','interp','none')
        ylabel('Number of individuals','interp','none')
    case 'iter'
        allRank = state.Rank;
        hist(allRank);
        if maxRank < max(allRank)
            set(gca,'xlim',[1,max(allRank)])
        end
end