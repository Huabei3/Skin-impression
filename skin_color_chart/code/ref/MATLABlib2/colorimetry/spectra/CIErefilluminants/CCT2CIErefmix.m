function Sr=CCT2CIErefmix(T,lb,le,stepsize)
%calculates CIE reference illuminant mixture based on
%T = CCT or CIE xy coordinates or xyz 
%lb=start wavelength 
%le=end wavelength 
%stepsize= wavelength interval
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargin==1;
    lambda =(360:1:830)';
else;
    if nargin==2 & numel(lb)>1;lambda=lb;else;lambda =(360:1:830)';end
    if nargin<4;stepsize=1;end
    if nargin>=3;lambda=(lb:stepsize:le)';end
end
lb=lambda(1);le=lambda(end);stepsize=abs(lambda(1)-lambda(2));

duv=[];

N = size(T,2);

Tb = 4500.*ones(1,N);%CCT at which to start mixing BB and Daylight phases
Te = 5500.*ones(1,N);%CCT at which to stop mixing BB and Daylight phases
cieobs = 2.*ones(1,N);% default CIE observer

switch size(T,1)
    case 2;%input = CIExy
        [T,duv]=CCTa(xyY2xyz(T'));
        if abs(duv)>5.4e-3;disp('Warning: duv too large!');end
    case 3;%input=XYZ
        [T,duv]=CCTa(T');    
        if abs(duv)>5.4e-3;disp('Warning: duv too large!');end
    case 4 %control start and stop mixing ccts
        cieobs = T(2,:);
        Tb = T(3,:);
        Te = T(4,:);
        T = T(1,:);
end
        

%get CIE CMFs
unique_cmfs = unique(cieobs);
for i=1:numel(unique_cmfs)
    [cmf,K]=selectcmf(cieobs(i));
    Ybar = cmf(:,3);

    %to save calculation time only perform interpolation when necessary
    dl = diff(lambda);
    if abs(dl(1)-dl(2))==abs(mean(dl)) & (((dl(1)==5) | (dl(1)==1) | (dl(1)==2)) & ((lambda(1,1)==380) | (lambda(1,1)==360)) & ((lambda(end,1)==780) | (lambda(end,1)==830)));
        Ybar=Ybar(1:dl(1):end,2:end);
        if lambda(1,1)==380;Ybar=Ybar(20/dl(1)+1:end-50/dl(1),:);end;%for 380:780 nm data
    else
        Ybar=CIEinterp(cmf(:,1),Ybar,lambda,'linear');
    end
    YbarKi(:,i)=Ybar.*K;
end

dl = stepsize;

%create YbarK = Ybar.*K array
for i=1:numel(unique_cmfs)
    pobs_i = (cieobs == unique_cmfs(i));
    YbarKis(:,pobs_i) = repmat(YbarKi(:,i),1,sum(pobs_i));
end

%calculate reference illuminant
    %for T<Tb:
    SrBB_= blackbodySPD(T,lb,le,stepsize);
    SrBB = SrBB_(:,2:end);
    SrBB=100.*SrBB./repmat((sum(YbarKis.*SrBB).*dl),numel(lambda),1);
    
    %for T>Te:
    SrDL_ = daylightSPD(T,lb,le,stepsize);
    SrDL = SrDL_(:,2:end);
    SrDL=100.*SrDL./repmat((sum(YbarKis.*SrDL).*dl),numel(lambda),1);

    %for (T>=Tb) & (T<=Te): --> mixture ratios
    f_BB_DL = [(Te-T)./(Te-Tb);(T-Tb)./(Te-Tb)];
    f_BB_DL(f_BB_DL<0)=0;
    f_BB_DL(f_BB_DL>1)=1;
    
    %calculate Sr
    Sr = repmat(f_BB_DL(2,:),numel(lambda),1).*SrDL + repmat(f_BB_DL(1,:),numel(lambda),1).*SrBB;
    Sr(isnan(Sr))=0;   
 
Sr = [lambda,Sr];    
end




