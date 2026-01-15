function h=plot_2(data,colour,plotcolour,marker);
%easy plot of 2D data (Nx2)
%colour = plot colour (e.g. 'r')
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin==1;colour='b';end
if ischar(data) == 1 %if data is file then read file else data is matlab matrix 
    spd=convertspdformat(data);
    spd = dlmread(data);
else
    spd = data;
end
if strcmp(colour,'color') & nargin >= 3
    if nargin<4;marker='o';end
    h=plot(spd(:,1),spd(:,2),'color',plotcolour,'marker',marker);
else
    h=plot(spd(:,1),spd(:,2),colour);
end
grid on
end