function im=rgb2Image(RGB,dim,RGBback,dimback);
if nargin==1;RGBback=RGB;dim=[600,800];dimback=dim;end
if nargin==2;RGBback=RGB;dimback=dim;end
if nargin==3;dimback=dim;end


%setup start images
%displayimage
dimensions=dim;
im = cat(3,ones(dimensions(1),dimensions(2)),ones(dimensions(1),dimensions(2)),ones(dimensions(1),dimensions(2)));
im = reshape2D3D(im,'3D22D',dimensions);
%create color image
im(:,1)=im(:,1)*RGB(1);                                     %XYZ 2D
im(:,2)=im(:,2)*RGB(2);                    
im(:,3)=im(:,3)*RGB(3);
%rescale data to truecolor requirements (R,G,B<=1.0)
maxlevel = max(max(max(im)));
if maxlevel>1.0
    im = im/maxlevel;
end
%reshape image to 3D
im = reshape2D3D(im,'2D23D',dimensions);

%background image
dimensions=dimback;
imback = cat(3,ones(dimensions(1),dimensions(2)),ones(dimensions(1),dimensions(2)),ones(dimensions(1),dimensions(2)));
imback = reshape2D3D(imback,'3D22D',dimensions);
%create color image
imback(:,1)=imback(:,1)*RGBback(1);                                     %XYZ 2D
imback(:,2)=imback(:,2)*RGBback(2);                    
imback(:,3)=imback(:,3)*RGBback(3);
%rescale data to truecolor requirements (R,G,B<=1.0)
maxlevel = max(max(max(imback)));
if maxlevel>1.0
    imback = imback/maxlevel;
end
%reshape image to 3D
imback = reshape2D3D(imback,'2D23D',dimensions);

[r,c,d]=size(im);[rb,cb,db]=size(imback);

posc=(cb-c)/2+1;posr=(rb-r)/2+1;
imback(posr:posr+r-1,posc:posc+c-1,1)=im(:,:,1);
imback(posr:posr+r-1,posc:posc+c-1,2)=im(:,:,2);
imback(posr:posr+r-1,posc:posc+c-1,3)=im(:,:,3);
im=imback;clear imback;
%display image
%image(im);
%axis tight;
%axis equal;
%axis off;
%figure(gcf);
end
