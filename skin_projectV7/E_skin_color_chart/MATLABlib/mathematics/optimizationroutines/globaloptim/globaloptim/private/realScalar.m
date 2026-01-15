function realScalar(property,value)
%realScalar Test for real scalar

%   Copyright 2007-2009 The MathWorks, Inc.
%   $Revision: 1.1.6.3 $  $Date: 2010/10/08 16:51:48 $

valid = isreal(value) && isscalar(value);
if(~valid)
    error(message('globaloptim:realScalar:notScalar', property));
end
