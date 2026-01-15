function saveimage(handle,filename,width,height,resolution)
if nargin<5;resolution=300;end
set(handle,'Position', [0 0 width height]);
print(handle,'-depsc','-tiff',['-r',num2str(resolution)],[filename,'_r',num2str(resolution)','.eps']);
print(handle,'-dtiff',['-r',num2str(resolution)],[filename,'_r',num2str(resolution)','.tiff']);
end