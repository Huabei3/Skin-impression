function [CCT_out,duv_out,S_out] = XYZ2CCT(xyz_,obs);
%Calculate correlated colour temperature (CCT) by first finding an 
%approximation (MCAMY) and then constructing a section of the blackbody
%locus on which to find min distance to xyY of test source.
%XYZ are calculate with a 360-830nm range.
%output: CCT, duv= distance to spectrumlocus in uv1960 diagram, S
%spectrum of blackbody reference. 
%This program is more accurate (by about 0-0.4 K), but slower than CCTa!
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin < 2; obs = 2; end

%calculate source  1960 u,v UCS chromaticity coordinates
if size(xyz_,2)==2;xyz_=spd2xyz(xyz_,2,0);end %when a spectrum is used as input

%load CIE 2� CMFs
cmf=selectcmf(obs);
%cmf=cmf(1:1:end,:);

%set wavelengths for calculation of blackbody radiators
lambda=cmf(:,1);

%initialize for speed
CCT_out = nan(1,size(xyz_,1));
duv_out = CCT_out;
for cct_i = 1:size(xyz_,1)
    xyz = xyz_(cct_i,:);

    %calculate uv1960 coordinates
    uvt=xyz2uvY(xyz);
    ut=uvt(1);
    vt= (2/3)*uvt(2);
    uvt=[ut,vt];

    %calculate a preliminary solution
    CCTtemp=CCTMCAMY(xyz);
    %CCTtemp=CCTa(xyz);

    %initialize CCT search parameters
    deltaT=100;%percent difference with intermediate CCT
    dT=100;%determines range around CCTtemp
    delT=2*dT/10;%determines stepsize within range
    t=0;  


    c1=3.74183e-16;
    c2=1.4388*0.01;
    signduv=[];    
    while (deltaT>1e-6) | (delT>0.001);%keep narrowing on CCT 
        t=t+1;
        %T=(CCTtemp-dT:delT:CCTtemp+dT);
        T=linspace(CCTtemp-dT,CCTtemp+dT,2*dT/delT+1);
        for i=1:numel(T);
            S=((lambda.*1e-9).^(-5)).*(exp(c2*((lambda.*1e-9*T(i)).^(-1)))-1).^(-1);
            %S560= ((560*1e-9).^(-5)).*(exp(c2*((560.*1e-9*T(i)).^(-1)))-1).^(-1); S=S./S560;
            XYZS(i,:) = [sum(cmf(:,2).*S),sum(cmf(:,3).*S),sum(cmf(:,4).*S)];
        end
        denom=(XYZS(:,1)+15*XYZS(:,2)+3*XYZS(:,3));uv=[4*XYZS(:,1),6*XYZS(:,2)]./[denom,denom];
        dc=((ut-uv(:,1)).^2+(vt-uv(:,2)).^2).^0.5;

        if ~isnan(min(dc));
            eps=1e-12;q=((dc>=min(dc)-eps) &(dc<=min(dc)+eps));
            q=find(q);
            if numel(q)>1; %to minimize calculation time: only calculate mean when necessary
                CCT=median(T(q));duv=median(dc(q));q=round(median(q));
            else;
                CCT=T(q);duv=dc(q);
            end
            %[t,q,CCTtemp-dT,CCTtemp+dT,delT,0,0,CCT,duv]
            if (q~=numel(T)) & q~=1;
                dT=2.*dT./10;delT=2*dT/10;
                %if isempty(signduv) 
                    signduv=checkduvsign([ut,vt],uv([q-1,q,q+1],:));%fastest
                %end
            end

            deltaT=100.*abs(CCT-CCTtemp)./CCTtemp;%calculate difference with previous intermediate solution
            CCTtemp=CCT;%set new intermediate CCT

            %ts(t)=t;deltaTs(t)=deltaT;CCTs(t)=CCT;duvs(t)=duv;
            %co='r.-';subplot(1,3,1);hold on;plot(ts,deltaTs,co);subplot(1,3,2);hold on;plot(ts,CCTs,co);subplot(1,3,3);hold on;plot(ts,duvs,co);

        else
            CCT=NaN;duv=NaN;
        end
    end
    if isempty(CCT);CCT=NaN;end
    if isempty(duv);duv=NaN;else;duv=signduv*abs(duv);end
    CCT_out(1,cct_i) = CCT;
    duv_out(1,cct_i) = duv;
end
if nargout==3;
    for i=1:numel(CCT_out)
        S=blackbodySPD(CCT_out(i));
        if i == 1 %initialize array for speed
            S_out = nan(size(S,1),numel(CCT_out));
        end
        S_out(:,i) = S(:,2);
    end
    S_out = [S(:,1),S_out];
end
end


function signduv=checkduvsign(p,uvm)
% This function takes as arguments two equal-length vectors x and y. p is a
% vector of length 2. The function determines if the point p lies above (+1),
% on (0) or below (-1) the function y = f(x).

%rotate first to ensure p has x between uvm values
p=p-uvm(2,:);uvm=uvm-repmat(uvm(2,:),3,1);
alpha=-atan((uvm(1,2)-uvm(3,2))/(uvm(1,1)-uvm(3,1)));R1=[cos(alpha) -sin(alpha);sin(alpha) cos(alpha)];
uvm=(R1*uvm')';p=(R1*p')';
%plot_2(p,'ro');hold on;plot_2(uvm,'b.-');

x=uvm(:,1);y=uvm(:,2);
ux = min(x(x > p(1))); lx = max(x(x < p(1)));
if isempty(ux) | isempty(lx)
    %plot_2(p,'ro');hold on;plot_2(uvm,'b.-');
    signduv=sign(p(2));
else

uy = y(x == ux);
ly = y(x == lx);

if lx ~= ux
   s=(uy-ly)/(ux-lx)*(p(1)-lx)+ly;
else
   s = uy;
end
signduv = sign(p(2) - s);
end
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%�

function CCTest = CCTMCAMY(xyz)
xyY=xyz./sum(xyz')';
n=(xyY(:,1)-0.3320)./(xyY(:,2)-0.1858);
CCTest = -449*n.^3 + 3525*n.^2 - 6823.3*n + 5520.33;
end