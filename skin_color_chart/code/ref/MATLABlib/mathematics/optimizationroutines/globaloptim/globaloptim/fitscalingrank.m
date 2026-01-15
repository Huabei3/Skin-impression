function expectation = fitscalingrank(scores,nParents)
% FITSCALINGRANK Rank based fitness scaling (single objective only).
%   EXPECTATION = FITSCALINGRANK(SCORES,NPARENTS) calculates the
%   EXPECTATION using the SCORES and number of parents NPARENTS.
%   This relationship can be linear or nonlinear.
%
%   Example:
%   Create an options structure using FITSCALINGRANK as 
%   the fitness scaling function
%     options = gaoptimset('FitnessScalingFcn',@fitscalingrank);

%   Copyright 2003-2010 The MathWorks, Inc.
%   $Revision: 1.1.6.2 $  $Date: 2010/02/08 22:34:16 $

scores = scores(:);
[~,i] = sort(scores);

expectation = zeros(size(scores));
expectation(i) = 1 ./ ((1:length(scores))  .^ 0.5);

expectation = nParents * expectation ./ sum(expectation);
