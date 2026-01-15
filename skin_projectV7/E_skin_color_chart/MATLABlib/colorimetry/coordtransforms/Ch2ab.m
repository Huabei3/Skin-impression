function ab=Ch2ab(Ch)
% FUNCTION Ch2ab
%   transform from Chroma and hue angle to a*b*

C=abs(Ch(:,1));
h=mod(Ch(:,2),360);
a=C.*cosd(h);
b=C.*sind(h);
ab=[a,b];
end

