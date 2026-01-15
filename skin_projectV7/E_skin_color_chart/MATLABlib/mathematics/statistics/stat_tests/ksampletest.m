function [pvalues,STATs]=ksampletest(data,alpha)
% Significance test for the K-sample problem. Perform's F-tests on 
%   1) Wilks' lambda (Rao's test)
%   2) Pillai's trace 
%   3) Hotelling-Lawley trace
%   4) Roy's max root
%
% Input:
%   data = cell array containg k groups of data
%   alpha = signifcance level
%
% Output:
% pvalues: array of 4 p-values 
% STATs: struct containing p, F, Fcrit & df for each statistical test, as
% well as the means for the K groups

if nargin < 2; alpha = 0.05; end

if ~iscell(data)
    for k=1:size(data,3);
        data_{k}=data(:,:,k);
    end
    data=data_;clear data_;
end


K = numel(data);% number of groups

%check for empty
t=0;
for k=1:K;
    if ~isempty(data{k});
        t=t+1;
        data_{t}=data{k};
    end
end
data=data_;clear data_;

K = numel(data);% number of groups
p = size(data{1},2);% number of variables


% Calculate group means M and SSCP matrices Sk
    poolofalldata = [];
    for k=1:K;
        nk(k) = size(data{k},1); % number of samples in group k
        Mk(k,:) = mean(data{k},1); % mean of group k 
        Xdk_M = data{k} - repmat(Mk(k,:),nk(k),1); % mean centered data for group k
        Sk(:,:,k) = Xdk_M'*Xdk_M; % sum-of-squares-and-cross-products matrices
        poolofalldata = [poolofalldata;data{k}];
    end
    n = sum(nk); % total number of samples across groups
    
% Calculate within-groups SSCP     
    WT = sum(Sk,3); % within-groups SSCP;
    
% Calculate within-group subjects SSCP;
    WS = 0;%not implemented yet

% Calculate within group error SSCP;
    W = WT - WS;

% Calculate Grand Mean
    Mgrand = mean(poolofalldata,1); %grand mean

% Calculate Total SSCP
    Xd = [];
    for k=1:K;
        Xdk_GM = data{k} - repmat(Mgrand,nk(k),1);
        Xd = [Xd;Xdk_GM];
    end
    T = Xd'*Xd;% total sum-of-squares-and-cross-products matrix

 % Calculate hypothesis SSCP
    H = T - W;
    
%--------------------------------------------------------------------------
%Perform various significance tests  
%--------------------------------------------------------------------------
    % Calculate Wilke's Lambda
        WLambda = det(W)/det(T);
        
        eta2_WL = 1-WLambda;%postively biased
        omega2m_WL = 1-n*WLambda/((n-K)+WLambda);%better, but still pos. biased estimator of effectsize
        omega2mc_WL = omega2m_WL-((p^2+(K-1)^2)/(3*n))*(1-omega2m_WL);%nearly unbiased
        

        % Apply Bartlett's V test (when n - 1 - (p + K)/2 is large )
            m = n - 1 - (p + K)/2;
            BVWL = -m*log(WLambda); %~ chi2[p*(K-1)] distributed

            dfBVWL = p*(K-1);
            BVWLcrit = chi2inv(1-alpha,dfBVWL);
            pBVWL = 1-chi2cdf(BVWL,dfBVWL);

        % Apply Rao's R test
            q = K - 1;
            v = n - q - 1;
            r = v - (p - q + 1)/2;
            u = (p*q - 2)/4;
            t = sqrt((p^2*q^2-4)/(p^2+q^2-5));if p^2+q^2-5 < 0; t = 1;end
            RWL = ((1-WLambda^(1/t))/WLambda^(1/t))*(r*t-2*u)/(p*q);
            df1RWL = p*q;
            df2RWL = r*t-2*u;
            
            RWLcrit = finv(1-alpha,df1RWL,df2RWL);
            pRWL = 1-fcdf(RWL,df1RWL,df2RWL);

    %----------------------------------------------------------------------
    % Pillai trace V
        Ptrace = sum(diag(pinv(T)*H));
        m = (abs(p-q)-1)/2;
        n = (v - p - 1)/2;
        s = min([p,q]);
        PV = (2*n + s + 1)/(2*m + s + 1)*(Ptrace/(s - Ptrace));
        df1PV = s*(2*m + s + 1);
        df2PV = s*(2*n + s + 1);
            
        PVcrit = finv(1-alpha,df1PV,df2PV);
        pPV = 1-fcdf(PV,df1PV,df2PV);
    
    %----------------------------------------------------------------------
    % Hotelling-Lawley trace U
        Utrace = sum(diag(pinv(W)*H));
        if n > 0;
            b = (p+2*n)*(q+2*n)/(2*(2*n+1)*(n-1));
            c = (2 + (p*q+2)/(b-1))/(2*n);
            U = (Utrace/c)*((4+(p*q+2)/(b-1))/(p*q));
            df1U = p*q;
            df2U = 4 + (p*q+2)/(b-1);
        else
            U = (2*(s*n + 1)*Utrace)/(s^2*(2*m + s + 1));
            df1U = s*(2*m + s + 1);
            df2U = 2*(s*n + 1);
        end
        Ucrit = finv(1-alpha,df1U,df2U);
        pU = 1-fcdf(U,df1U,df2U);
    
        %----------------------------------------------------------------------
    % Roy's root
       [lambda_i]= eig(pinv(W)*H);
       Theta = max(lambda_i);
       r = max(p,q);
       R = Theta*(v - r + q)/r;
       
       df1R = r;
       df2R = v - r + q;
       Rcrit = finv(1-alpha,df1R,df2R);
       pR = 1-fcdf(R,df1R,df2R);
    
%--------------------------------------------------------------------------
% Summary in struct

% Wilk's lambda
    WilksLambda.V=WLambda;
    WilksLambda.F = RWL;
    WilksLambda.df1= df1RWL;
    WilksLambda.df2 = df2RWL;
    WilksLambda.Fcrit = RWLcrit;
    WilksLambda.p = pRWL;

% Pillai's Trace
    PillaiTrace.V=Ptrace;
    PillaiTrace.F = PV;
    PillaiTrace.df1= df1PV;
    PillaiTrace.df2 = df2PV;
    PillaiTrace.Fcrit = PVcrit;
    PillaiTrace.p = pPV;
    
% Hotelling-Lawley Trace
    HotellingLawleyTrace.V=Utrace;
    HotellingLawleyTrace.F = U;
    HotellingLawleyTrace.df1= df1U;
    HotellingLawleyTrace.df2 = df2U;
    HotellingLawleyTrace.Fcrit = Ucrit;
    HotellingLawleyTrace.p = pU;
    
 %Roy's largest root
    RoysMaxRoot.V=Theta;
    RoysMaxRoot.F = R;
    RoysMaxRoot.df1= df1R;
    RoysMaxRoot.df2 = df2R;
    RoysMaxRoot.Fcrit = Rcrit;
    RoysMaxRoot.p = pR;

STATs.alpha = alpha;
STATs.K = K;
STATs.p = p;
STATs.means = Mk;
STATs.Sk = Sk;
STATs.nk = nk;
STATs.W = W;
STATs.H = H;
STATs.T = T;
STATs.effectsize.eta2 = eta2_WL;
STATs.effectsize.omega2m_WL = omega2m_WL;
STATs.effectsize.omega2mc_WL = omega2mc_WL
STATs.WilksLambda = WilksLambda;
STATs.PillaiTrace = PillaiTrace;
STATs.HotellingLawleyTrace = HotellingLawleyTrace;
STATs.RoysMaxRoot = RoysMaxRoot;

Vvalues = [WLambda,Ptrace, Utrace, Theta];
Fvalues = [RWL,PV,U,R];
dfvalues = [[df1RWL,df1PV,df1U,df1R];[df2RWL,df2PV,df2U,df2R]];
Fcritvalues = [RWLcrit,PVcrit,Ucrit,Rcrit];
pvalues = [pRWL,pPV,pU,pR];

STATs.all.test = {'Wilks'' lambda','Pillai''s trace','Hotelling-Lawley''s trace','Roy''s max root'};
STATs.all.V = Vvalues;
STATs.all.F = Fvalues;
STATs.all.df1 = dfvalues(1,:);
STATs.all.df2 = dfvalues(2,:);
STATs.all.Fcrit = Fcritvalues;
STATs.all.p = pvalues;


               
