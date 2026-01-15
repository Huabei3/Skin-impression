function xyY= calcspectrumlocus(observer)
%calculates CIE xy of spectrum locus (400 -700 nm)
%observer: CIE observer 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
global cmfobs
if nargin==0;observer=cmfobs; end
%if ischar(observer);observer=fliplr(observer);observer=observer(2:end);observer=fliplr(observer);observer=str2double(observer);end
cmf=selectcmf(observer);
xyY=xyz2xyY(cmf(cmf(:,1)>=400 & cmf(:,1)<=700,2:4));
xyY=[xyY;xyY(1,:)];
end