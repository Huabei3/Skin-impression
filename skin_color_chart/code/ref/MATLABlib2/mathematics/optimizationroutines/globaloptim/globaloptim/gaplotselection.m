function state = gaplotselection(options,state,flag)
%GAPLOTSELECTION A histogram of parents.
%   STATE = GAPLOTSELECTION(OPTIONS,STATE,FLAG) plots a histogram of the
%   parents. This will let you see which parents are contributing to each 
%   generation. If there is not enough spread (only a few parents are being 
%   used) then you may want to change some parameters to get more diversity.
%
%   Example:
%    Create an options structure that uses GAPLOTSELECTION
%    as the plot function
%      options = gaoptimset('PlotFcns',@gaplotselection);

%   Copyright 2003-2010 The MathWorks, Inc. 
%   $Revision: 1.1.6.2 $  $Date: 2010/05/10 17:16:47 $

switch flag
    case 'init'
        title('Selection Function','interp','none')
        xlabel('Individual','interp','none')
        ylabel('Number of children','interp','none')
    case 'iter'
        hist(state.Selection);
    case 'done'
        % Add tag to the axis so that it can be easily found.
        set(gca,'Tag','gaplotselection');
end

