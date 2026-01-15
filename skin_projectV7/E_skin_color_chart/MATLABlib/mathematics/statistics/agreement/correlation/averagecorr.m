function [rmu,p,Q,pQ,SE,df,chi2v,rp,rt]=averagecorr(r,N,k,rfmodel)
%calculate average correlation + statistics using 1 of 2 methods,
%rfmodel='HOf': fixed effects size model, hedges & olkin (1985) and hedges and vevea (1998)
%rfmodel= HOr :random effects size model, hedges & olkin (1985) and hedges and vevea (1998)
%rfmodel= 'HS' :Hunter-Schmidt method (1999)

N=N';r=r';

if nargin==3;rfmodel='HOr';end

K=length(N);%number of studies

%k=2;%use only two k digits for the correlations
cutoff=1-10.^(-k);
r=formn(r,k);

rt=r;


%calculate population r
rp=r+r.*(1-r.^2)./(2.*(N-1));
r=rp;
%rp=r.*(1+(1-(r.*(2.*N-1)./(2.*N-2)).^2)./(2.*N-2));%4e orde benadering van Hotelling 1953

switch rfmodel(1:2)
    case 'HO' %Hedges et al.

        if N(1)>1;wi=N-3;sumw=sum(wi);else wi=N;sumw=length(N);end %if N= samplesize, then use inverse of variances of corrs as weights

        %fixed-effects model: studies are entire population of studies
        r(r>=cutoff)=cutoff;r(r<=-cutoff)=-cutoff;

        zf=r2Fisherz(r,cutoff);
        zfmu=sum(zf.*wi)./sumw;%average weighted zf

        %zfmu=weightedMedian(zf,wi);

        Z=zfmu./sqrt(1./sumw);%z-score for zfmu
        SEr=sqrt(1./sum(wi));
        
        p=normcdf([-Z,Z]);p=1-(p(2)-p(1));%probability of obtaining Z by chance
        Q=sum((N-3).*(zf-zfmu).^2);%Homeogeneity of effect size: Chi2 probability with k=length(N)-1 degrees of freedom, Hedges & Olkin 1985
        df=length(N)-1;pQ=1-chi2cdf(Q,df);
        chi2v=chi2inv(0.95,length(N)-1);
        %random-effects model: studies are a samples of a population of studies
        if rfmodel=='HOr' & N(1)>1
            c=sumw-sum(wi.^2)./sumw;
            tausquared=(Q-df)./c;
            tausquared(tausquared<0)=0;%no negative variances
            wi=(N-3)./(1+(N-3).*tausquared); %new weights with between-study variance included

            zfmu=sum(zf.*wi)./sum(wi);%average weighted zf
            SEr=sqrt(1./sum(wi));
        end

        rmu = ((exp(2.*zfmu)-1)./((exp(2.*zfmu)+1)));%convert z back to r --> average correlation
        %rmu=rmu./1.15;%overestimation of effect sizes by a 15-45%, Field 2001
        rmu(zfmu==Inf)=1;

            %correction for sampling error variance
                    Ser2a=(((1-rmu.^2).^2.)/mean(N))./K;%via mean study
                    Seri2=((1-r.^2).^2.)./(N-1);
                    Ser2b=(sum(wi.*Seri2)./sum(wi))./K;%via individual studies
                    Ser2=min([Ser2a,Ser2b]);
                    Spxy2=SEr.^2-Ser2;%estimation of the biased population variance, uncorrected for measurement or range departure
                    %[SEr1,Ser2a,Ser2,Spxy2]
                    Spxy2(Spxy2<0)=1*10.^(-10);%avoid negative or zero variances!
                    SEr=sqrt(Spxy2);%standard error
            SE=SEr;

            Z=zfmu./SEr;%z-score for zfmu
            p=normcdf([-Z,Z]);p=1-(p(2)-p(1));%probability of obtaining Z by chance
            Q=sum((N-3).*(zf-zfmu).^2);%Homeogeneity of effect size: Chi2 probability with k=length(N)-1 degrees of freedom, Hedges & Olkin 1985
            df=length(N)-1;pQ=1-chi2cdf(Q,df);
            chi2v=chi2inv(0.95,length(N)-1);    


    case 'HS' %Hunter-Schmidt: bare-bones model
        
        rmu=sum(N.*r)./sum(N);
        
        %rmu=weightedMedian(r,N);
        
        %SDr=sqrt(sum(N.*(r-rmu).^2)./(sum(N)*((K-1)/K)));%small number of studies
        Sr2=(sum(N.*(r-rmu).^2)./sum(N));
              
   
            %correction for sampling error variance
            
            Ser2=(((1-rmu.^2).^2.)/(sum(N.^2)./sum(N)-1));%via weighted mean study
            %Seri2=((1-r.^2).^2.)./(N-1);Ser2b=(sum(N.*Seri2)./sum(N));%via individual studies
            %Ser2a=Ser2;Ser2=min([Ser2a,Ser2b]);
            Spxy2=Sr2-Ser2;%estimation of the biased population variance, uncorrected for measurement or range departure
            %[SEr1,Ser2a,Ser2,Spxy2]
            Spxy2(Spxy2<0)=1*10.^(-10);%avoid negative or zero variances!
            SEr=sqrt(Spxy2./K);%standard error
            %SEr=sqrt(Sr2./K);%standard error not corrected for sampling error variance       
            [Sr2,Ser2,Spxy2,SEr,sqrt(Spxy2./K)];
        Z=rmu./SEr;%zscore
        SE=SEr;%use SE to estimate significance
        Q=sum(((N-1).*(r-rmu).^2)./((1-rmu.^2).^2));
        df=K-1;pQ=1-chi2cdf(Q,df);
        p=(1-normcdf(Z)).*2;%probability of obtaining Z by chance
        chi2v=chi2inv(0.95,df);
        %rmu=rmu./0.95;rmu(rmu>1)=1;%underestimation of effect sizes by a 5-10%, Field 2001
        
end