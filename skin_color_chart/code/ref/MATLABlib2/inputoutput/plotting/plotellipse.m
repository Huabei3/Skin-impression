function [xyellipse,h_el,h_cen]=plotellipse(v,plotcolour,linewidth,markertype,linestyle)
%plotellipse in v =[Rmax,Rmin,xc,yc,thetha]
%plotcolour = colour used in plotting
%output = ellipsepoints
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[rows,cols]=size(v);
if nargin<3;linewidth=1;markertype='+';linestyle='-';end
if nargin<4;markertype='+';linestyle='-';end
if nargin<5;linestyle='-';end

for nn=1:rows

xs=v(nn,1);
ys=v(nn,2);
xc=v(nn,3);
yc=v(nn,4);
alpha=v(nn,5);

if nargin==1; plotcolour=1;end
colours={'k','m','b','c','g','y','r','m--','b--','c--','g--','y--','r--','m.-','b.-','c.-','g.-','y.-','r.-','bx-','cx-','gx-','yx-','rx-'};

%calculate ellipse for drawing
    N = 100;
    dx = 2*pi/N;
    theta=alpha;
    R = [ [ cos(theta) sin(theta)]', [-sin(theta) cos(theta)]'];
    for j = 1:N
         ang = j*dx;
         x = xs*cos(ang);
         y = ys*sin(ang);
         d1 = R*[x y]';
         X(j) = d1(1) + xc;
         Y(j) = d1(2) + yc;
    end
     X=[X];Y=[Y];
    if ischar(plotcolour)
            %if linewidth==1;plot(X,Y,plotcolour);else;plot(X,Y,plotcolour,'LineWidth',linewidth);end
            h_el=plot(X,Y,plotcolour,'LineWidth',linewidth,'LineStyle',linestyle);
            hold on
            h_cen=plot(xc,yc,[plotcolour(1),markertype],'LineWidth',linewidth);
            xyellipse=[X',Y'];
    else    
        if plotcolour>0 & numel(plotcolour)==1;
            %if linewidth==1;plot(X,Y,char((colours(plotcolour))));plot(X,Y,char((colours(plotcolour))),'LineWidth',linewidth);end
            h_el=plot(X,Y,char((colours(plotcolour))),'LineWidth',linewidth,'LineStyle',linestyle);
            hold on
            h_cen=plot(xc,yc,[char((colours(plotcolour(1)))),markertype],'LineWidth',linewidth);
            xyellipse=[X',Y'];
        else
            if numel(plotcolour)==3;
                h_el=plot(X,Y,'Color',plotcolour,'LineWidth',linewidth,'LineStyle',linestyle);
                hold on
                h_cen=plot(xc,yc,'Color',plotcolour,'LineWidth',linewidth,'Marker',markertype);
                xyellipse=[X',Y'];
            else
                xyellipse=[X',Y'];
            end
        end
    end
end
end