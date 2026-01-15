function [MetamericBlack,FundMetamer]=FundMetamerBlack(spd,obs)
%Calculates the Fundamental Metamer and the Metameric Black
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin<2;obs=10;end
[cmf,K]=selectcmf(obs);
lamb=cmf(:,1);cmf=cmf(:,2:end);
R=cmf*inv(cmf'*cmf)*cmf';%Cohen's matrix
spd=[lamb,interp1(spd(:,1),spd(:,2),lamb,'spline')];
spd(:,2)=spd(:,2)./sum(spd(:,2).*cmf(:,3));%normalize
FundMetamer=[lamb,R*spd(:,2)];%fundamental metamer
MetamericBlack=[lamb,spd(:,2)-FundMetamer(:,2)];%Metameric Black
end