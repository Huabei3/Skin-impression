function IPT=xyz2ipt(XYZ)
%transform from XYZ(2° or 10° (=default)) to IPT
%D65 is assumed whitepoint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin<2;cieobs=10;end
switch cieobs
    case 2
        IPT=xyz2ipt2(XYZ);
    case 10
        IPT=xyz2ipt10(XYZ);
    otherwise
        error('Unsupported CIE observer.')
end
end