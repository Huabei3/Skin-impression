function [xmax,imax] = extrema_(x,k)
 l=x(:,1);x=x(:,2);
 
 x0=x;x=x./max(x(l>300));
 [xmax,imax,xmin,imin] = extrema(x);
 [imax,IM]=sort(imax); xmax=xmax(IM);
 [imin,Im]=sort(imin);xmin=xmin(Im);
 
 %figure(1);plot(imax,xmax,'b.-');hold on; plot(imin,xmin,'r.--')
 for i=1:numel(xmax)
     iminsi=imin([find(imin<imax(i),1,'last'),find(imin>imax(i),1,'first')]);
     if length(iminsi)<2;iminsi=[iminsi,iminsi];end
     I(i,:)=[imax(i),iminsi(1),iminsi(2)]
     V(i,:)=[xmax(i),mean([x(iminsi(1)),x(iminsi(2))])];
     
 end
V=x(I);V(:,2)=mean(V(:,2:3)')';
%V=[imax,((((V(:,1)-V(:,2))./xmax)>=(1-k)))];
V=[imax,(V(:,1)-V(:,2))>k];
imax=imax(find(V(:,2)==1));xmax=x(imax);
%plot(imax,xmax,'ro')
     