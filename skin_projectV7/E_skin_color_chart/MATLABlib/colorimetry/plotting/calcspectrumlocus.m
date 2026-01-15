function xyY= calcspectrumlocus(observer)
%calculates CIE xy of spectrum locus (400 -700 nm)
%observer: CIE observer 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
cmf=selectcmf(observer);
xyY=xyz2xyY(cmf(cmf(:,1)>=400 & cmf(:,1)<=700,2:4));
xyY=[xyY;xyY(1,:)];
end