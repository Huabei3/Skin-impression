function state = gaplotbestfun(options,state,flag)
%GAPLOTBESTFUN Plots the best score and the mean score.

%   Copyright 2005 The MathWorks, Inc. 
%   $Revision: 1.1.6.1 $  $Date: 2009/08/29 08:27:49 $

if(strcmp(flag,'init'))
    set(gca,'xlim',[1,options.Generations]);
    xlabel('Generation','interp','none');
    grid on
    ylabel('Fitness value','interp','none');
end

hold on;
generation = state.Generation;
best = min(state.Score);
plot(generation,best, 'v');
title(['Best: ',num2str(best)],'interp','none')
hold off;
        