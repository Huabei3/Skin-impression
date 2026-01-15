function density=griddensity(grid,cc)
%calculate density of points in a grid and plot result
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
colours='krgbycmw';
size(grid)
figure(13);hold on;
voronoi(grid(:,1),grid(:,2));
[V,C]=voronoin(grid)
size(C)
K = convhull(grid(:,1),grid(:,2));
contour=[grid(K,1),grid(K,2)]
volgrid=[];
for i=1:length(C);
    Vindices=C{i};
    for j=1:length(Vindices)
        volgrid=[volgrid;V(Vindices(j),:)];
        dist(i,j)=sqrt((V(Vindices(j),1)-grid(i,1)).^2+(V(Vindices(j),2)-grid(i,2)).^2);
        
    end 

    if length(find(Vindices==1))==0; v(i,:)=vfitellipse([grid(:,1:2);V(Vindices,:)]);else;v(i,:)=[0,0,0,0,0];end
end

iscontourpoint=find(max(dist')==Inf)';
isvolumepoint=find(max(dist')~=Inf)';

maxdist=max(dist(isvolumepoint,:)')' ; 
disttemp=dist(isvolumepoint,:);disttemp(find(disttemp==0))=Inf;%zero is not min!
mindist=min(disttemp')';
mediandist=median(dist(isvolumepoint,:)')' ;
meandist=mean(dist(isvolumepoint,:)')' ;
dens=[mindist,mediandist,meandist,maxdist,(maxdist-mindist)./meandist,pi.*(maxdist.*mindist).*10^4]
dens2=(v(:,1).*v(:,2).*pi);dens2=dens2(isvolumepoint).*10^4;
plot(contour(:,1),contour(:,2),'r.-');
plot(grid(iscontourpoint,1),grid(iscontourpoint,2),'ro');
plot(grid(:,1),grid(:,2),[colours(cc),'o']);
%stem3(grid(isvolumepoint,1),grid(isvolumepoint,2),1./dens2(:,end),'b.');
%stem3(grid(isvolumepoint,1),grid(isvolumepoint,2),1./dens(:,3),[colours(cc),'.']);
density=std(1./dens(:,3))./100;
stem3(grid(isvolumepoint,1),grid(isvolumepoint,2),abs((1./dens(:,3)),[colours(cc),'.']);
%density2=length(find(dens(:,end)>=0.5.*density & dens(:,end)<=1.5.*density))./length(dens(:,end))

end