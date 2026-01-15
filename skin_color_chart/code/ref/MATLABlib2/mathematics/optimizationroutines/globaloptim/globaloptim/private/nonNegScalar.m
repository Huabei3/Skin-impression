function nonNegScalar(property,value)
%nonNegScalar any scalar >= 0    

%   Copyright 2007-2009 The MathWorks, Inc.
%   $Revision: 1.1.6.3 $  $Date: 2010/10/08 16:51:38 $

valid =  isreal(value) && isscalar(value) && (value >= 0);
if(~valid)
    error(message('globaloptim:nonNegScalar:notNonNegScalar', property));
end
