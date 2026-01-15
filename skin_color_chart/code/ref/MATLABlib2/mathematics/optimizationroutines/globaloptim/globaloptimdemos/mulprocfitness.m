function timeToComplete = mulprocfitness(schedule, lengths)
%MULPROCFITNESS determines the "fitness" of the given schedule.
%  In other words, it tells us how long the given schedule will take using the
%  knowledge given by "lengths"

%   Copyright 2006 The MathWorks, Inc.
%   $Revision: 1.1.6.1 $   $Date: 2009/08/29 08:28:01 $

[nrows ncols] = size(schedule);
timeToComplete = zeros(1,nrows);
for i = 1:nrows
    timeToComplete(i) = 0;
    for j = 1:ncols
        if schedule(i,j)~=0
            timeToComplete(i) = timeToComplete(i)+lengths(i,schedule(i,j));
        else
            break
        end
    end
end
timeToComplete = max(timeToComplete);
