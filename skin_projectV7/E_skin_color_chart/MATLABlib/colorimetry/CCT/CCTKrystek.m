function [CCT,minDc] = CCTKrystek(uv1960);
%calculate CCT from uv1960 chromaticty coordinates,
%uses Krystek as a first approximation and then iteratively
%calculates the CCT by calculating planckian radiators
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%search increasing accuracy and decreasing searchlimits for planckianlocus
lbound=1000;
ubound=15000;
searchsize = 10;
%first searchround;
u=uv1960(1).*ones(1,(ubound-lbound)/searchsize + 1)';
v=uv1960(2).*ones(1,(ubound-lbound)/searchsize + 1)';
uv1960planck = planckianlocus(lbound,ubound,searchsize);
up = uv1960planck(:,1);
vp = uv1960planck(:,2);
DC=((u-up).^2+(v-vp).^2).^(1/2);
minDC = min(DC);
CCT1=lbound+searchsize.*((find(DC==minDC))-1);

%second searchround
lbound=CCT1-20;
ubound=CCT1+20;
searchsize=0.5;
u=uv1960(1).*ones(1,(ubound-lbound)/searchsize + 1)';
v=uv1960(2).*ones(1,(ubound-lbound)/searchsize + 1)';
uv1960planck = planckianlocus(lbound,ubound,searchsize);
up = uv1960planck(:,1);
vp = uv1960planck(:,2);
DC=((u-up).^2+(v-vp).^2).^(1/2);
minDC = min(DC);
CCT=lbound+searchsize.*((find(DC==minDC))-1);

end

function uvPlanck = planckianlocus(lbound,ubound,searchsize);
%Krystek planckian locus 
%______________________________________
for t = 1 :(((ubound-lbound)/searchsize)+1);
    T = lbound+(t-1)*searchsize;
    u(t) = (0.860117757 + 1.54118254*10^(-4)*T + 1.28641212*10^(-7)*T^2)/(1+8.42420235*10^(-4)*T+7.08145163*10^(-7)*T^2);
    v(t) = (0.317398726 + 4.22806245*10^(-5)*T + 4.20481691*10^(-8)*T^2)/(1-2.89741816*10^(-5)*T+1.61456053*10^(-7)*T^2);
end
u=u';
v=v';
uvPlanck=[u,v];
end
    
