function parents = selectionroulette(expectation,nParents,options)
%SELECTIONROULETTE Choose parents using roulette wheel.
%   PARENTS = SELECTIONROULETTE(EXPECTATION,NPARENTS,OPTIONS) chooses
%   PARENTS using EXPECTATION and number of parents NPARENTS. On each 
%   of the NPARENTS trials, every parent has a probability of being selected
%   that is proportional to their expectation.
%
%   Example:
%   Create an options structure using SELECTIONROULETTE as the selection
%   function
%     options = gaoptimset('SelectionFcn',@selectionroulette);

%   Copyright 2003-2007 The MathWorks, Inc.
%   $Revision: 1.1.6.1 $  $Date: 2009/08/29 08:25:35 $

expectation = expectation(:,1);
wheel = cumsum(expectation) / nParents;

parents = zeros(1,nParents);
for i = 1:nParents
    r = rand;
    for j = 1:length(wheel)
        if(r < wheel(j))
            parents(i) = j;
            break;
        end
    end
end
    
