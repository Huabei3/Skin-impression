function XYZ=ipt2xyz(IPT,cieobs)
%transform from ipt to XYZ(2° or 10° (=default))
%D65 is assumed whitepoint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin<2;cieobs=10;end
switch cieobs
    case 2
        XYZ=ipt2xyz2(IPT);
    case 10
        XYZ=ipt2xyz10(IPT);
    otherwise
        error('Unsupported CIE observer.')
end
end