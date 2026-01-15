function LER=LER_(spd,obs)
if nargin==1;obs=2;end
[cmf,k]=selectcmf(obs);
for i=1:3;cmf_(:,i)=interp1(cmf(:,1),cmf(:,2),spd(:,1),'linear');end;
cmf=[spd(:,1),cmf_];clear cmf_;
LER=k.*sum(repmat(cmf(:,3),1,size(spd,2)-1).*spd(:,2:end),1)./sum(spd(:,2:end),1);%calc LER
end