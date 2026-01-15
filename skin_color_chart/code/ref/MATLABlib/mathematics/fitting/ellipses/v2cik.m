function cik=v2cik(v)
%calculate 2x2 'covariance matrix' elements cik (=not actually a covariance matrix,
%only for gaussian or normal distribution!)
%ellipse format -->v=[Rmax,Rmin,xc,yc,theta]
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
g11=(1/v(1)*cos(v(5)))^2+(1/v(2)*sin(v(5)))^2;
g22=(1/v(1)*sin(v(5)))^2+(1/v(2)*cos(v(5)))^2;
g12=(1/v(1)^2-1/v(2)^2)*sin(v(5))*cos(v(5));
cik=[g11,g12;g12,g22];
end