function cmap = getcmap(N)
cmap=colormap;
if N>size(cmap,1);error('N is too large for cmap');end
cmap=cmap(1:floor(size(cmap,1)./N):end,:);
