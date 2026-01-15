function realUnitScalar(property,value)
%realUnitScalar A scalar on the interval [0,1]

%   Copyright 2007-2009 The MathWorks, Inc.
%   $Revision: 1.1.6.3 $  $Date: 2010/10/08 16:51:49 $

valid = isreal(value) && isscalar(value) && (value >= 0) && (value <= 1);
if(~valid)
    error(message('globaloptim:realUnitScalar:notScalarOnUnitInterval', property));
end
