function spd=convertim2spd(filename,lamrange);
%digitizes a spectral power distribution in an image
%image should be cut to match the range 
%and only spd should be visible (black).
%lamrange = [begin, end] wavelengths of the original figure.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
im=imread(filename);
%figure(99);imshow(im)
clear spdi;
for i=1:3;im(:,:,i)=flipud(im(:,:,i));end
k=10;if size(im,3)==1;imt(:,:,1)=im;imt(:,:,2)=im;imt(:,:,3)=im;im=imt;clear imt;end
for j=1:size(im,2);spdi(j)=mean(find(im(:,j,1)<k & im(:,j,2)<k & im(:,j,3)<k));end

spdi=abs(spdi./max(spdi));
spdi(isnan(spdi))=0;

dlam=(lamrange(2)-lamrange(1))./(size(im,2)-1);
lam=lamrange(1):dlam:lamrange(2);
spd=[lam',spdi'];
%figure(3);plot(lam',spdi','b');
lamn=(380:780)';%(380:780)';
spd=[lamn,interpK(spd(:,1),spd(:,2),lamn,'spline')];spd(:,2)=spd(:,2)./max(spd(:,2));
figure(2);plot_2(spd,'b');
end
