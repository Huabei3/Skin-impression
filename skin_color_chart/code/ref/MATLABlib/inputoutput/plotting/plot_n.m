function plot_n(data,colour,num)
%easy plot of matrix (NxM): first column = X, following columns are Y data
%colour = plot colour (e.g. 'r')
%num = column number +1 to plot
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin==1;colour='b';end%if data is file then read file else data is matlab matrix




if ischar(data) == 1  
    spd=convertspdformat(data);
    spd = dlmread(data);
else
    spd = data;
end
[m,n]=size(data);
if nargin<3 ;
    for i=1:n-1
        hold on;plot(spd(:,1),spd(:,i+1),colour)
    end
else
    hold on;plot(spd(:,1),spd(:,num+1),colour)
end
grid on
end