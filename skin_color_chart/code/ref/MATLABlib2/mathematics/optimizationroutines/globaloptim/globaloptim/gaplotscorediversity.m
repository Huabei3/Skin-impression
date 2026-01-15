function state = gaplotscorediversity(options,state,flag,p1)
%GAPLOTSCOREDIVERSITY Plots a histogram of this generation's scores.
%   STATE = GAPLOTSCOREDIVERSITY(OPTIONS,STATE,FLAG) plots a histogram of current
%   generation's scores.
%
%   Example:
%   Create an options structure that uses GAPLOTSCOREDIVERSITY
%   as the plot function
%     options = gaoptimset('PlotFcns',@gaplotscorediversity);

%   Copyright 2003-2010 The MathWorks, Inc. 
%   $Revision: 1.1.6.2 $  $Date: 2010/05/10 17:16:46 $

if nargin < 4
    p1 = 10;
end

switch flag
    case 'init'
        title('Score Histogram','interp','none')
        xlabel('Score (range)');
        ylabel('Number of individuals');
    case 'iter'
        % Check if Rank is a field and there are more than one objectives, then plot for Rank == 1
        if size(state.Score,2) > 1 && isfield(state,'Rank') 
            index = (state.Rank == 1);
            % When there is one point hist will treat it like a vector
            % instead of matrix; we need to add one more duplicate row
            if nnz(index) > 1
                set(gca,'ylimmode','auto');
                hist(state.Score(index,:),p1);
            else
                set(gca,'ylim',[0 1]);
                hist([state.Score(index,:); state.Score(index,:)],p1);
            end
            % Legend for each function <min max> values on the Pareto front
            nObj = size(state.Score,2);
            fminval = min(state.Score(index,:),[],1);
            fmaxval = max(state.Score(index,:),[],1);
            legendText = cell(1,nObj);
            for i = 1:nObj
               legendText{i} = ['fun',num2str(i),' [',sprintf('%g  ',fminval(i)), ...
                   sprintf('%g',fmaxval(i)),']'];
            end
            legend(legendText);
        else % else plot all score
            hist(state.Score,p1);
        end
    case 'done'
        % Add tag to the axis so that it can be easily found.
        set(gca,'Tag','gaplotscorediversity');
end
