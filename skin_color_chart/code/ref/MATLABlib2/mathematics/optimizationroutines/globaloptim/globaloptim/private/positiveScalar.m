function positiveScalar(property,value)
%positiveScalar any positive scalar

%   Copyright 2007-2009 The MathWorks, Inc.
%   $Revision: 1.1.6.3 $  $Date: 2010/10/08 16:51:44 $

valid =  isreal(value) && isscalar(value) && (value > 0);
if(~valid)
    error(message('globaloptim:positiveScalar:notPosScalar', property));
end
