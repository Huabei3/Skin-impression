function state = gaplotscores(options,state,flag)
%GAPLOTSCORES Plots the scores of every member of the population.
%   STATE = GAPLOTSCORES(OPTIONS,STATE,FLAG) plots the scores of  every
%   member of the population. The individuals are ordered as follows.  The
%   first (leftmost) n individuals are the elites (by default 2), these will
%   always be the lowest scores. The next (Middle) group is the individuals
%   that were created by crossover and finally the last (rightmost) group
%   are those individuals created by mutation.
%
%   You can get an idea of the relative behavior of each of these groups. 
%   In particular you can gauge the relative contributions of mutation and
%   crossover and adjust the crossover fraction accordingly.
%
%   If you are using multiple populations, this entire pattern will be
%   repeated in a different color for each subpopulation. You can see which
%   population is outperforming the others and watch the effects of migration
%   between subpopulations.
%
%   Example:
%    Create an options structure that uses GAPLOTSCORES
%    as the plot function
%      options = gaoptimset('PlotFcns',@gaplotscores);

%   Copyright 2003-2006 The MathWorks, Inc.
%   $Revision: 1.1.6.1 $  $Date: 2009/08/29 08:24:52 $

colors = ['r','b','g','y','m','c'];
subPops = populationIndices(options.PopulationSize);
[unused,c] = size(subPops);
switch flag
    case 'init'
         set(gca,'xlimmode','manual','zlimmode','manual', ...
            'climmode','manual','alimmode','manual')
        % make the x axis span exactly the data size
        set(gca,'xlim',[0,1 + sum(options.PopulationSize)])
        title('Fitness of Each Individual','interp','none')
        for i = 1:c
            pop = subPops(:,i);
            range = pop(1):pop(2);
            h = bar(range,state.Score(range),colors(1 + mod(i,5)));
            str = ['gaplotscore',int2str(i)];
            set(h,'edgecolor','none','facecolor',colors(1 + mod(i,5)),'Tag',str)
            hold on;
        end
        hold off;

    case 'iter'
        for i = 1:c
            pop = subPops(:,i);
            range = pop(1):pop(2);
            str = ['gaplotscore',int2str(i)];
            h = findobj(get(gca,'Children'),'Tag',str);
            set(h,'Ydata',state.Score(range));
        end
end

