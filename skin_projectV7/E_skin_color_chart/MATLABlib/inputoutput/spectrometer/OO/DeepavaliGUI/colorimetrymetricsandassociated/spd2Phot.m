function Phot=spd2Phot(spd,obs,viewingconditions)
%Calculate photometric value from source spectrum 
%spddata = filename or matrixname of SPD data
%obs = 2 for 2 degree, 10 for 10 degree CIE standard observer (default = 2)
%viewing conditions: photopic 'P', scotopic 'S' (default = 'P')

if nargin==1;obs=2;viewingconditions='P';end
if nargin==2;viewingconditions='P';end

switch upper(viewingconditions)
    case 'P' % photopisch
        XYZ=spd2xyz(spd,obs,1);
        Phot=XYZ(:,2);
    case 'S' %scotopisch
        [Phot]=spd2scot(spd);
    otherwise
        error('Invalid viewing condition!');
        
end