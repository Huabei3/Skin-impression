function meanX=meanzero(X)
%calculate the mean of X, not counting zero values
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[m,n]=size(X);
meanX=sum(X);
nonzero=sum((X~=0));
meanX=meanX./nonzero;
meanX(isnan(meanX))=0;
end
    