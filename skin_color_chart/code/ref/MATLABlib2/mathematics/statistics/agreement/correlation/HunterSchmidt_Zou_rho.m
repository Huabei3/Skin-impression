function [rbarc,pz,SE_rho,CI_rho,SE_rho1rho2,CI_rho1rho2,H_rho1rho2,CIClosestTo0,Q,pQ,df,chi2v,ro,rc,I2,tau]=HunterSchmidt_Zou_rho(rx,N,alpha,correctsamplingerror,ryy,rxx,ux,b,correctheterogeneity,VarCorrectionfactor)
% Estimate population correlation using the average correlation as
% calculated according to the method (with corrections) of
% Hunter-Schmidt(1999).
% If r contains r1x, r2x & r12 the SE & CI for rho1 - rho2 is also
% calculated following Zou(2007).
% Hunter-Schmidt artifact corrections:
%   - sampling error (correctsamplingerror == 0/1 --> correct or not)
%   - reliability (IV: rxx,DV: ryy, if 1 no correction)
%   - range restriction/enhancement (direct: ux = SDresticted/SDunrestricted, if <0 --> indirect: calculate ut from abs(ux) and rxx, if 1: no correction)
%   - correlation bias (b == 0/1: correct or not)
% r: individual r 
% N: number of samples for each individual r
% alpha: significance level for Confidence Intervals 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin<3;alpha=0.05;correctsamplingerror=1;ryy=1;rxx=1;ux=1;b=1;correctheterogeneity=1;VarCorrectionfactor=1;end
if nargin<4;correctsamplingerror=1;ryy=1;rxx=1;ux=1;b=1;correctheterogeneity=1;VarCorrectionfactor=1;end
if nargin<5;ryy=1;rxx=1;ux=1;b=1;correctheterogeneity=1;VarCorrectionfactor=1;end
if nargin<6;rxx=1;ux=1;b=1;correctheterogeneity=1;VarCorrectionfactor=1;end
if nargin<7;ux=1;b=1;correctheterogeneity=1;VarCorrectionfactor=1;end
if nargin<8;b=1;correctheterogeneity=1;VarCorrectionfactor=1;end
if nargin<9;correctheterogeneity=1;VarCorrectionfactor=1;end
if nargin<10;VarCorrectionfactor=1;end
if isempty(ux);ux=1;end
if isempty(rxx);rxx=1;end
if isempty(ryy);ryy=1;end
if isempty(correctsamplingerror);correctsamplingerror=1;end
if isempty(b);b=1;end
if size(ryy,1)==1;ryy=ryy.*ones(size(rx));end
if size(rxx,1)==1;rxx=rxx.*ones(size(rx));end
if size(ux,1)==1;ux=ux.*ones(size(rx));end
if isempty(correctheterogeneity);correctheterogeneity=1;end


%store original r values
ro = rx;

%number of r-sets supplied (rx = [r1x,r2x,r12])
nn=size(rx,2);


%When two r-sets are supplied, use same rxx, ryy, ux for both r-sets when 
%they are not supplied.
if nn>1
    if size(rxx,2)==1;
        rxx=[rxx,rxx,rxx];
    elseif size(rxx,2)==2;
        rxx=[rxx,ones(size(rx,1),1)];
    end
    if size(ryy,2)==1;
        ryy=[ryy,ryy,ones(size(rx,1),1)];
    elseif size(ryy,2)==2;
        ryy=[ryy,ones(size(rx,1),1)];
    end
    if size(ux,2)==1;
        ux=[ux,ux,ux];
    elseif size(ux,2)==2;
        ux=[ux,ones(size(rx,1),1)];
    end
end

for j=1:nn
    
    r=rx(:,j);

    %avoid divisions by zero
    r(r==0)=eps;

    %number of studies
    n = numel(r);
    
    %calculate weigthed average rbar an Nbar
    rbar(j) = sum(r.*N)./sum(N);


    %correct for ryy reliability attenuation
    a1 = 1./sqrt(ryy(:,j));
    rc(:,j)=r.*a1;

    %set direct range restriction parameter
    Ux(:,j) = 1./abs(ux(:,j));% Ux = SDunrestricted/SD restricted


    %calculate indirect range restriction parameter ut from ux and rxx
    if j==1;
        rxxa=nan(n,nn);
    end
    for i=1:n
        rxxa(i,j)=1-(ux(i,j).^2).*(1-rxx(i,j));%also needed for rxx adjustement in case of direct range restriction!
        if rxxa(i,j)<0;rxxa(i,j)=eps;end
        if ux(i,j)<0;%use indirect
            ut = sqrt(abs((ux(i,j).^2-(1-rxxa(i,j)))./rxxa(i,j)));
            Ux(i,j)=1./ut;
        end
    end


    %correct for direct range restriction/enhancement
    a2(:,j) = Ux(:,j)./sqrt(abs((Ux(:,j).^2-1).*rc(:,j).^2+1));
    rc(:,j)=rc(:,j).*a2(:,j);

    %correct for rxx reliability attenuation
    a3 = 1./sqrt(rxxa(:,j));
    rc(:,j)=rc(:,j).*a3;

    %calculate combined de-attenuation factor ac
    ac = (a1.*a2(:,j).*a3);
    if j==3;ac=a1.*mean(a2')'.*a3;end
    
    
   
    %calculate fixed effects weights
    w = N./(ac.^2);%Heterogenity assumed zero! Note that ac is the compound (range restrictrion & reliability) de-attenuation factor
    
    %calculate corrected weighted mean rbarc 
    rbarc(j) = sum(w.*rc(:,j),1)./sum(w);
    
    %calculate heterogenity tau
    Q(j) = sum((w.*(rc(:,j)-rbarc(j)).^2));
    
    i2(j)=100.*(Q(j)-(n-1))./Q(j);
    
    if correctheterogeneity==1;
        tau(j) = (Q(j)-n)./sum(w);
        if tau(j) < 0;tau(j)=0;end
    else
        tau(j)=0;
    end
    
    
    %calculate optimized weights: cfr. wi = 1/(tau+sigma_i.^2),with sigma_i.^2 within study variance,
    w = (1./(tau(j)+(1./N)))./ac.^2; 
    
    %calculate corrected weighted mean rbarc using optimized weigths
    rbarc(j) = sum(w.*rc(:,j),1)./sum(w);

    
    %estimate sampling error variance of studies
    %Vei(:,j) = ((1-rx(:,j).^2).^2)./(N-1);
    Vei(:,j) = ((1-rbar(j).^2).^2)./(N-1);% = sampling variance of uncorrected r
                                  %Note the use of rbar (not r!), because the
                                  %former is a better estimator (less error)
    Veic(:,j) = Vei(:,j).*ac.^2;  % = sampling variance of corrected  r
    Veic(:,j) = Veic(:,j).*(1./(abs((Ux(:,j).^2-1).*rx(:,j).^2+1))).^2;%adjust sampling variance of corrected r for range restriction
        
    
    
    %estimate sampling error covariance of studies
    if j==3;
        Ux(:,3)=sqrt((Ux(:,1).^2+Ux(:,2).^2)/2);
        COVei = ((rx(:,end)-0.5.*rx(:,1).*rx(:,2)).*(1-rx(:,1).^2-rx(:,2).^2-rx(:,end).^2)+rx(:,end).^3)./(N-1);%use N-1 as better estimator than N
        COVeic=COVei.*ac.^2;
        COVeic=COVeic.*(1./(abs((Ux(:,j).^2-1).*rx(:,j).^2+1))).^2;
        CORReic=COVeic./sqrt(prod(Veic(:,1:2)')');
        
    end
    

    % %calculate correlation bias attenuation factor
    if b==1;
        a = (1-1./(2.*N-1));%for rc <= 0.7
        a(rc(:,j)>=0.7) = (1-(1-rc(rc(:,j)>=0.7,j).^2)./(2.*N(rc(:,j)>=0.7)-1));%for rc >= 0.7
        a(a>1)=1;

        %correct correlation, attenuation factor & sampling error (cov)variance for correlation bias
        ac=ac./a;
        rc(:,j)=rc(:,j)./a;
        Veic(:,j)=Veic(:,j)./a.^2;
        if j==3;
            COVeic=COVeic./a.^2;
        end

        %calculate weights
        w = N./(ac.^2);%Note that a is the compound (range restrictrion & reliability) de-attenuation factor

        %calculate corrected weighted mean rbarc 
        rbarc(j) = sum(w.*rc(:,j),1)./sum(w);

        %calculate update for heterogenity tau
        Q(j) = sum((w.*(rc(:,j)-rbarc(j)).^2));
        if correctheterogeneity==1;
            tau(j) = (Q(j)-n)./sum(w);
            if tau(j) < 0;tau(j)=0;end
        else
            tau(j)=0;
        end
        
        %calculate optimized weights: cfr. wi = 1/(tau+sigma_i.^2),with sigma_i.^2 within study variance,
        w = (1./(tau(j)+(1./N)))./ac.^2; 
                
        
        %calculate update for corrected weighted mean rbar
        rbarc(j) = sum(w.*rc(:,j),1)./sum(w);
    end

    %calculate weighted variance of (un)corrected r
    Var_wrc(j) = sum(w.*(rc(:,j)-rbarc(j)).^2,1)./sum(w);
    Var_wr(j) = sum(N.*(rx(:,j)-rbar(j)).^2,1)./sum(N);

    %calculate weighted average corrected r sampling error
    avg_werr(j) = sum(w.*Veic(:,j),1)./sum(w);

    %variance of rho = variance of rc - weighted average corrected sampling error
    Var_rho(j) = Var_wrc(j) - avg_werr(j).*(correctsamplingerror>0);
    if Var_rho(j) < 0;
        Var_rho(j) = eps;
    end
                           %Although there is little error in the statistically %
                           %given sampling error variance, the variance of observed
                           %correlations is a sample estimate. Unless the number of
                           %studies is infinite, there will be some error in that 
                           %empirical estimate. If the population difference is 0, 
                           %then error will cause the estimated difference to be 
                           %positive or negative with probability one-half.
                           %Thus it is possible that sampling error causes the 
                           %variance of observed correlations to differ slightly 
                           %from the expected value, and that error causes the 
                           %estimating difference to be negative.

        Var_rho(j)=Var_rho(j).*VarCorrectionfactor; %Var for pearson = 1/(n-3); Var for spearman = 1.06/(n-3)!
                           
        if j==3;   
            %set weights
            w3=mean(W(:,1:2)')';%
            
            %calculate weighted covariance of corrected rc
            COV_wrc = sum(w3.*(rc(:,1)-rbarc(1)).*(rc(:,2)-rbarc(2)),1)./sum(w3);
            COV_wr = sum(N.*(rx(:,1)-rbar(1)).*(rx(:,2)-rbar(2)),1)./sum(N);
            CORR_wrc = COV_wrc./sqrt(prod(Var_wrc(1:2)));
          
            %calculate weighted average corrected r sampling error covariance
            avg_wcov = sum(w3.*COVeic,1)./sum(w3);
            avg_wcorr = avg_wcov./sqrt(prod(avg_werr(1:2)));
           
            %cov(rhox,rhoy) = cov(rx-ex,ry-ex) = cov(rx,ry) - cov(ex,ey) - cov(ex,ry) - cov(rx,ey) - cov(rx,ex) - cov(ry,ey)
            %assume independence--> cov(ex,ry) = cov(rx,ey) = cov(rx,ex) = cov(ry,ey) = 0
            COV_rho1rho2 = COV_wrc - (avg_wcov).*(correctsamplingerror>0);
            
            COV_rho1rho2=COV_rho1rho2.*VarCorrectionfactor; %Var for pearson = 1/(n-3); Var for spearman = 1.06/(n-3)!, adjust cov to ensure corr stays equal
            
            %calculate variance of (rho1 - rho2)
            Var_rho1rho2 = (sum(Var_wrc(1:2)) - 2*COV_wrc).*VarCorrectionfactor; %for confidence interval do not correct for sampling errror (for credibility interval, do correct)
            Var_rho1rho2(Var_rho1rho2<0) = 0;
            SE_rho1rho2 = sqrt(Var_rho1rho2./n);%standard error on rho1rho2

            rdiff=(rbarc(1)-rbarc(2));
            CI_rho1rho2 = [rdiff- norminv(1-alpha./2).*SE_rho1rho2,rdiff+norminv(1-alpha./2).*SE_rho1rho2];
            CIClosestTo0 = CI_rho1rho2(abs(CI_rho1rho2)==min(abs(CI_rho1rho2)));%if very close to zero --> significance almost reached
            CIClosestTo0 = CIClosestTo0(1);
            H_rho1rho2 = ~((CI_rho1rho2(1) <= 0) & (0 <= CI_rho1rho2(2)));
       
        else
            %in case only data for one r is supplied
            COV_rho1rho2 = nan;
            Var_rho1rho2 = nan;
            SE_rho1rho2 = nan;
            CI_rho1rho2 = [nan,nan];
            H_rho1rho2 = nan;
        end
                      
                           
    %calculate SD for rho
    SD_rho(j) = sqrt(Var_wrc(j));%for confidence interval on the mean corrected r
    SE_rho(j) = SD_rho(j)./sqrt(n);


    %calculate (1-alpha)-confidence interval for mean corrected rbarc
    CI_rho(j,:) = [rbarc(j)-norminv(1-alpha./2).*SD_rho(j),rbarc(j)+norminv(1-alpha./2).*SD_rho(j)];
    
    %store weigthings and attenuation factors
    W(:,j)=w;
    AC(:,j)=ac;
    
    
    %calculate p-value (for H0: rbarc = 0)
    Z(j) = abs(rbarc(j))./SE_rho(j);%zscore
    pz(j) = (1-normcdf(Z(j))).*2;%probability of obtaining Z by chance
    
    %calculate p value for heterogenity
    df(j) = n-1;
    pQ(j) = 1-chi2cdf(Q(j),df(j));
    chi2v(j) = chi2inv(1-alpha,df(j));
    
    I2(j)=100.*(Q(j)-(n-1))./Q(j);

    
end


for j=1:nn
    %rectrict corrected r-values to [-1,1]
    rbarc(rbarc>1) = 1;
    rbarc(rbarc<-1) = -1;
    rc(rc(:,j)>1,j) = 1;
    rc(rc(:,j)<-1,j) = -1;

end




