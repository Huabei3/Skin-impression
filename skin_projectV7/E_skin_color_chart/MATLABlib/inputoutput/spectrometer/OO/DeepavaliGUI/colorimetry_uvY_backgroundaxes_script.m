%calculate coloured backgroundimage for chrom plot
    global srgbPT;
    cspacemax=1;
    Ps=([0:0.004:cspacemax]);Ts=Ps;[p,t]=meshgrid(Ps,Ts);
    L=0.8.*100;
    Lpt=reshape(cat(3,p,t,L.*ones(size(p,1),size(p,2))),size(p,1)*size(p,2),3);%note that Lpt is in fact uvY
    
    xyz_=uvp2xyz(Lpt);
    xy=Lpt(:,1:2);
    srgb_=xyz2srgb(xyz_);
    srgbPT=reshape(srgb_,size(p,2),size(p,1),3);
    tel=0;
    for i=1:numel(p(:,1));
        for j=1:numel(t(:,1));
                tel=tel+1;
                ij(tel,:)=[j,i];
        end;
    end;
    xySL = calcspectrumlocus(2);
    xySL=xy2uv(xySL(:,1:2));
    inSL=~inhull(xy,[xySL(:,1:2)]);
    I=sub2ind(size(srgbPT(:,:,1)),ij(inSL,1),ij(inSL,2));
    I=[I;I+size(srgbPT,1).*size(srgbPT,2);I+2.*size(srgbPT,1).*size(srgbPT,2)];
    srgbPT(I)=0;
    