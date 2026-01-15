function plot_3(data,colour)
%easy plot of 2D data (Nx3)
%colour = plot colour (e.g. 'r')
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
plot3(data(:,1),data(:,2),data(:,3),colour)
grid on
end