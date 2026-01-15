function minCCT = CCTaccurate(uv1960);
%Calculate CCT from CIE uv1960 coordinates by first finding an 
%approximation (KRYSTEK) and then constructing a section of the 
%blackbody locus on which to find min distance to xyY test source.
%output: CCT, DCmin= distance to spectrumlocus in uv1960 diagram, S
%spectrum of blackbody reference. 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
global l0 ln samplestep

%store setupvariables
l0temp=l0;
lntemp=ln;
samplesteptemp=samplestep;

%change steupvariables to more accurate values
l0=360;
ln=830;
samplestep=1;

CCTtemp = CCTKrystek(uv1960); %first, find approximation

c1 = (2*pi*(6.626176*10^(-34))*((2.99792458*10^8)^2));
c2 = 1.438*10^(-2);% ((6.626176*10^(-34))*(2.99792458*10^8))/(1.380662*10^(-23));%1.435*10^(-2);((6.626176*10^(-34))*(2.99792458*10^8))/(1.380662*10^(-23)); %1.4387752*10^(-2);
Sl = linspace(l0,ln,((ln-l0)/samplestep)+1)';
lamb=Sl.*10^-9;
teller=1;
Woffset=10;dL=0.1;
for T=CCTtemp-Woffset:dL:CCTtemp+Woffset;
    
    S = c1./((lamb.^5).*(exp((c2./(T.*lamb)))-1));
    S=[Sl,S];
    XYZS = spd2xyz(2,S);
    xyYref = xyz2xyY(XYZS);
    uv1960temp = xyz2uvp(XYZS);
    uv1960temp(2) = (2/3)*uv1960temp(2);
    
    delta(teller)=((uv1960temp(1)-uv1960(1)).^2+(uv1960temp(2)-uv1960(2)).^2).^0.5;
    teller=teller+1;
end

%restore setup values to original
l0=l0temp;
ln=lntemp;
samplestep=samplesteptemp;
delta;

min(delta);
findmin=(find(delta==min(delta))-1);
minCCT=CCTtemp-Woffset+(find(delta==min(delta))-1)*dL;
minCCT=minCCT(1) %if more then one min, just take the first.

S = c1./((lamb.^5).*(exp((c2./(minCCT.*lamb)))-1));
S=S';
Sl=Sl';
S = [Sl,S];

end

function CCT = CCTKrystek(uv1960);
%'An algorithm to calculate correlated colour temperature' M. Krystek


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
lbound=CCT1-50;
ubound=CCT1+50;
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
    
