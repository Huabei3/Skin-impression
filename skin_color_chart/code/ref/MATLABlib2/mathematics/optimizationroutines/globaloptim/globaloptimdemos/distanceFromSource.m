function d = distanceFromSource(v,numSources,origins)
% distanceFromSource Distance function for opticalInterferenceDemo.

%   Copyright 2009 The MathWorks, Inc.  
%   $Revision: 1.1.6.1 $  $Date: 2009/11/05 17:00:00 $

d = zeros(numSources,1);
for k = 1:numSources
    d(k) = norm(origins(k,:) - [v 0]);
end

