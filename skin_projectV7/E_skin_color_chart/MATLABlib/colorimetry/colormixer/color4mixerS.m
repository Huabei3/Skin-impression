function M = colormixerS(xyYm,xyY1,xyY2,xyY3,xyY4,r41)
%Calculates the weights M for sources with xy coordinates:
%xyY1,xyY2,xyY3 & xyY4 to obtain xyYm; r41 is the relative weight 
%of xyY4 to xyY1.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin==6;
    
rba=r41;%4/1
x1 = xyY1(1);
y1 = xyY1(2);
Y1 = xyY1(3);
x2 = xyY2(1);
y2 = xyY2(2);
Y2 = xyY2(3);
x3 = xyY3(1);
y3 = xyY3(2);
Y3 = xyY3(3);
x4 = xyY4(1);
y4 = xyY4(2);
Y4 = xyY4(3);
xm = xyYm(1);
ym = xyYm(2);
outgamutyn=0;
    %calculate RYratio
    warning off MATLAB:divideByZero;
    
    %figure(3);hold on;plotwhite(2,'xyY');xyY=[xyY1;xyY2;xyY3;xyY4];plot_2(xyY,'b.');
     %calculate chromatic position (xmt,ymt) of temporary source (=mixture of source 1 and 4)
    X1=x1.*Y1./y1;X4=x4.*Y4./y4;
    Z1=(1-x1-y1).*Y1./y1;Z4=(1-x4-y4).*Y4./y4;
    
    a=1./(1+rba);Xmt=a.*(X1+rba.*X4);Zmt=a.*(Z1+rba.*Z4);Ymt=a.*(Y1+rba.*Y4);
    
    xmt=Xmt./(Xmt+Ymt+Zmt);ymt=Ymt./(Xmt+Ymt+Zmt);
        
    %temporary source becomes one of the three source used in regular colormixing
    %xyYmt=[xmt,ymt,Ymt];figure(3);plot_2(xyYmt,'g.')
    x1=xmt;
    y1=ymt;
    xyYmt=[xmt,ymt,Ymt];
    m1 = y1*((xm-x3)*y2-(ym-y3)*x2+x3*ym-xm*y3)/(ym*((x3-x2)*y1+(x2-x1)*y3+(x1-x3)*y2));
    m2 = -y2*((xm-x3)*y1-(ym-y3)*x1+x3*ym-xm*y3)/(ym*((x3-x2)*y1+(x2-x1)*y3+(x1-x3)*y2));
    m3 = y3*((x2-x1)*ym-(y2-y1)*xm+x1*y2-x2*y1)/(ym*((x2-x1)*y3-(y2-y1)*x3+x1*y2-x2*y1));

    %calculate the contributions of source 1 and source 2 needed to get the m1 of the temporary source
    mm=m1;
    m1=mm./(1+rba).*Y1./Ymt;m4=rba.*mm./(1+rba).*Y4./Ymt;
    M = [m1,m2,m3,m4];
    if (M(1) < 0) | (M(2) < 0) |(M(3) < 0)|(M(4) < 0)
      warning('Selected Color outside of GAMUT!');
      %figure(21);hold on;plot_2(xyY1,'b.');plot_2(xyY4,'r.');plot_2([xmt,ymt],'g.'),stop
    end
end
if nargin ==4;
    x1 = xyY1(1);
    y1 = xyY1(2);
    x2 = xyY2(1);
    y2 = xyY2(2);
    x3 = xyY3(1);
    y3 = xyY3(2);
    xm = xyYm(1);
    ym = xyYm(2);
    m1 = y1*((xm-x3)*y2-(ym-y3)*x2+x3*ym-xm*y3)/(ym*((x3-x2)*y1+(x2-x1)*y3+(x1-x3)*y2));
    m2 = -y2*((xm-x3)*y1-(ym-y3)*x1+x3*ym-xm*y3)/(ym*((x3-x2)*y1+(x2-x1)*y3+(x1-x3)*y2));
    m3 = y3*((x2-x1)*ym-(y2-y1)*xm+x1*y2-x2*y1)/(ym*((x2-x1)*y3-(y2-y1)*x3+x1*y2-x2*y1));
    M = [m1,m2,m3];
    if sum(M<0)>1;warning('out of gamut');end
end
end