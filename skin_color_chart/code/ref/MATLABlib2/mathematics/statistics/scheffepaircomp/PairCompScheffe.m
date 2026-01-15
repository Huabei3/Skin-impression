function [alpha_qual,Ye_qual,Dalpha_qual,ratingadequat_qual,ranking_qual,freqs,Ftest,muij_,sig_]=PairCompScheffe(data3D,scaletype,epsilon,unbalanceyn);
%PC according to Scheffe
%data= matrix with  rows (pairs), columns(judges); entries (scores)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin<4;unbalanceyn=0;end
[rows,cols,dims]=size(data3D);cols=cols-2;
check10s=cols*rows*10;
for i=1:dims %find measured qualities
    if (sum(sum(data3D(:,3:end,i)))<check10s); quals(i)=i;end
end

quality={'Colour Rendering','Preference','Fidelity','Vividness','Naturalness','Attractiveness'};

for qual=1:dims
    clear freq data xijk pcseq 
    if length(find(quals==qual)) %do calculations for measured qualities
    data=data3D(:,:,quals(qual));
    pcseq=data(:,1:2);
    xijk=data(:,3:end);
    scores=(-(scaletype-1)/2:(scaletype-1)/2);
    
    for i=1:scaletype
       for j=1:length(pcseq(:,1))
        
           freq(j,i)=length(find(xijk(j,:)==scores(i)));%calculate frequencies
           
       end
    end
    freqs(:,:,qual)=freq;           

    %make unbalanced experiemnt balanced by omitting the scores that deviate the most from the mean
    

%freq=sum(data(2:end,3:end),3);xijk=data(2:end,3:end,:);data=data(:,:,1);data(2:end,3:end)=freq;

%pcseq=data(2:end,1:2);
%scores=data(1,3:end);
%freq=data(2:end,3:end);
njudgesr=sum(freq')';njudges=ceil(mean(njudgesr));

items=max(max(pcseq));
M=0.5*(items*(items-1));

%pcseqsorted=sortrows(pcseq);

%find opposite pairs
for i=1:length(pcseq)
    pos(i)=find(pcseq(:,1)==pcseq(i,2) & pcseq(:,2)==pcseq(i,1));
end



%make unbalanced experiemnt balanced by omitting the scores that deviate the most from the mean
if abs(unbalanceyn)==1;
freqt=freq;scores2=[-(max(scores)+1):max(scores)+1];scores3=scores2(find(scores2~=0));clear scores2;scores2=scores3;clear scores3;
freq2=[freq(:,1:floor(length(freq(1,:))./2)),ceil(freq(:,1+floor(length(freq(1,:))./2))./2),ceil(freq(:,1+floor(length(freq(1,:))./2))./2),freq(:,floor(length(freq(1,:))./2)+2:end)];clear freq;freq=freq2;
for i=1:length(pos)
    r1(i)=sum(freq(i,:));r2(i)=sum(freq(pos(i),:));
    meanScore(i,1)=sum(freq(i,:)'.*scores2')'./r1(i);
    meanScore(i,2)=sum(freq(pos(i),:)'.*scores2')'./r2(i);
    tempn0=((freq(i,:)'.*scores2')');
    tempr=rankdata(-(sign(unbalanceyn)).*abs(scores2-round(mean(tempn0(tempn0~=0)))));
    td(i)=abs(r1(i)-abs(min(-sign(unbalanceyn).*njudgesr)));%number of scores to delete
    t0=length(find(freq(i,tempr)==0));%total zeros
    h=1;for l=1:td(i) ;tdd=0;while h<=length(scores)& tdd==0;h=h;freq(i,tempr(h));if freq(i,tempr(h))>=1 & h<=length(scores) & tdd==0;freq(i,tempr(h))=freq(i,tempr(h))-1.*(-sign(unbalanceyn));tdd=1;else;h=h+1;end;end;end
end
clear freq2;freq2=[freq(:,1:floor(length(freq(1,:))./2)-1),ceil(freq(:,1+floor(length(freq(1,:))./2))),freq(:,floor(length(freq(1,:))./2)+2:end)];clear freq;freq=freq2;
njudges=abs(min(-sign(unbalanceyn).*njudgesr));
end

for i=1:length(pos);
    TotalScore(i,:)=sum(freq(i,:)'.*scores')';
    muij(i,:)=TotalScore(i,:)./mean(njudgesr(:));
end
Totals=sum(freq);

for i=1:length(pos)
    piij(i)=(muij(i)-muij(pos(i)))./2;
    dij(i)=(muij(i)+muij(pos(i)))./2;
    PIij(pcseq(i,1),pcseq(i,2))=piij(i);
    MUij(pcseq(i,1),pcseq(i,2))=muij(i);
    Dij(pcseq(i,1),pcseq(i,2))=dij(i);
end
alpha=sum(PIij')'./items;
delta=(sum(sum(MUij')'))./(2*M);

for i=1:length(pos)
    Gij(pcseq(i,1),pcseq(i,2))=PIij(pcseq(i,1),pcseq(i,2))-alpha(pcseq(i,1))+alpha(pcseq(i,2));
    %for k=1:njudges;
    %    Xijk(pcseq(i,1),pcseq(i,2),k)=xijk(i,k+2);
    %end
end

Sa = 2.*njudges*items*sum(alpha.^2);%Main effects
da=items-1;%degrees of freedom main effects

Spi=2*njudges*(sum(sum(triu(PIij)'.^2)'));%Average preferences
dpi=M;%degrees of freedom average prefences

Smu= njudges.*(sum(sum(MUij'.^2)'));%Means
dmu=2*M;%%degrees of freedom means

%Sg= 2*njudges*(sum(sum(tril(Gij)'.^2)'))%Deviations from subtractivity%??
Sg=Spi-Sa;
dg=M-items+1;%degrees of freedom 'Deviations from subtractivity'

%Sd= 2*njudges*(sum(sum(triu(Dij')'.^2)'))%order effects
Sd=Smu-Spi;
dd=M;%degrees of freedom order effects
Sdaccent=Sd-2*njudges*M*delta.^2;

%St=sum(sum(sum(Xijk.^2,3),2),1)%Total
St=sum(Totals.*scores.^2);
dt=2*njudges*M; %degrees of freedom total

Se=St-Smu;%error
de=2*M*(njudges-1);%degrees of freedom error
q = getcrit(epsilon, de, items);
sig=Se/(2*M*(njudges-1));
Ye=q*sqrt(sig/(2*njudges*items));

Msqa=Sa/da;
Msqg=Sg/dg;
Msqpi=Spi/dpi;
Msqd=Sd/dd;
Msqmu=Smu/dmu;
Msqe=Se/de %MSqe=Ye/q

%check if items are adequately rated: Msqe ~ Msqg ?
%use F-test F=max(Msqe,Msqg)/min(Msqe,Msqg)
disp('---------------------------------')
disp(' ')
disp(quality(qual))
disp(' ')

Fi=max([Msqe,Msqg])./min([Msqg,Msqe]);if Msqg==max([Msqe,Msqg]);Fn=finv(0.95,dg,de);dM=dg;dm=de;else;if Msqe==max([Msqe,Msqg]); Fn=finv(0.95,de,dg);dM=de;dm=dg;end;end
Fn2=1-fcdf(Fi,dM,dm);
disp(['Msqg: ',num2str(Msqg),', Msqe: ',num2str(Msqe)])
%if max([Msqe,Msqg])./min([Msqg,Msqe])<=2;disp(['Items are adequaltely rated! (Msqg,Msde) = (',num2str(Msqg),' , ',num2str(Msqe),')']); RatingAdequat=1;else disp(['Items are not adequaltely rated!: (Msqg,Msde) = (',num2str(Msqg),' , ',num2str(Msqe),')']);RatingAdequat=0;end
if Fi<=Fn;disp(sprintf(['Items are adequaltely rated! F = %0.3g <= F(0.95,%3.0f,%3.0f) = %0.3g'],Fi,dM,dm,Fn)); RatingAdequat=1;else disp(sprintf(['Items are NOT adequaltely rated! F = %0.3g > F(0.95,%3.0f,%3.0f) = %0.3g'],Fi,dM,dm,Fn));;RatingAdequat=0;end
disp(' ')
Ftest(:,qual)=[Fi;Fn;dM;dm];


%check alpha comparisson significance
for i=1:items
    for j=1:items
    Dalpha(i,j)=alpha(i)-alpha(j);
    end
end
triDalpha=triu(Dalpha);

disp(sprintf('Yardstick Ye: %0.3f',Ye))
disp(' ')
for i=1:items
    for j=1:items
        %if i<j;disp(sprintf('% 0.2f  <=   a %s - a %s <= % 0.2f           real difference?: %s',Dalpha(i,j)-Ye,num2str(i),num2str(j),Dalpha(i,j)+Ye,num2str(abs(Dalpha(i,j)-Ye)>=1 | abs(Dalpha(i,j)+Ye)>=1)));end
        if i<j;disp(sprintf('  a %s - a %s = % 0.2f           real difference?: %s',num2str(i),num2str(j),Dalpha(i,j),num2str(abs(Dalpha(i,j))>=Ye)));end
  
    end
end

%save data per quality
ranking=[rankdata(alpha);alpha(rankdata(alpha))'];
disp(' ')
dispitems='';dispscale='';
for i=1:items
    dispitems=[dispitems,num2str(ranking(1,i)), ' , '];
    dispscale=[dispscale,sprintf('%0.4f , ',ranking(2,i))];
end
disp(['Ranked items: ',dispitems(1:end-2)])
disp(['Item scores : ',dispscale(1:end-2)])

    muij_(:,qual)=muij;
    sig_(qual)=sig;
    
    ranking_qual(:,:,qual)=ranking;
    alpha_qual(:,qual)=(alpha);
    Ye_qual(qual)=Ye;
    Dalpha_qual(:,:,qual)=Dalpha;
    ratingadequat_qual(qual)=RatingAdequat;
    else %no calculation but put -100!
    ranking_qual(:,:,qual)=-100.*ones(2,items);
    alpha_qual(:,qual)=-100.*ones(items,1);
    Ye_qual(qual)=-100;
    Dalpha_qual(:,:,qual)=-100.*ones(items,items); 
    ratingadequat_qual(qual)=-1;
    end
end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%ù
function crit = getcrit(alpha, df, ng)
qt=[1   17.969 26.976 32.819 37.082 40.408 43.119 45.397 47.357 49.071 50.592 51.957 53.194 54.323 55.361 56.320 57.212 58.044 58.824 59.558;
  2    6.085  8.331  9.798 10.881 11.734 12.435 13.027 13.539 13.988 14.389 14.749 15.076 15.375 15.650 15.905 16.143 16.365 16.573 16.769;
  3    4.501  5.910  6.825  7.502  8.037  8.478  8.852  9.177  9.462  9.717  9.946 10.155 10.346 10.522 10.686 10.838 10.980 11.114 11.240;
  4    3.926  5.040  5.757  6.287  6.706  7.053  7.347  7.602  7.826  8.027  8.208  8.373  8.524  8.664  8.793  8.914  9.027  9.133  9.233;
  5    3.635  4.602  5.218  5.673  6.033  6.330  6.582  6.801  6.995  7.167  7.323  7.466  7.596  7.716  7.828  7.932  8.030  8.122  8.208;
  6    3.460  4.339  4.896  5.305  5.628  5.895  6.122  6.319  6.493  6.649  6.789  6.917  7.034  7.143  7.244  7.338  7.426  7.508  7.586;
  7    3.344  4.165  4.681  5.060  5.359  5.606  5.815  5.997  6.158  6.302  6.431  6.550  6.658  6.759  6.852  6.939  7.020  7.097  7.169;
  8    3.261  4.041  4.529  4.886  5.167  5.399  5.596  5.767  5.918  6.053  6.175  6.287  6.389  6.483  6.571  6.653  6.729  6.801  6.869;
  9    3.199  3.948  4.415  4.755  5.024  5.244  5.432  5.595  5.738  5.867  5.983  6.089  6.186  6.276  6.359  6.437  6.510  6.579  6.643;
 10    3.151  3.877  4.327  4.654  4.912  5.124  5.304  5.460  5.598  5.722  5.833  5.935  6.028  6.114  6.194  6.269  6.339  6.405  6.467;
 11    3.113  3.820  4.256  4.574  4.823  5.028  5.202  5.353  5.486  5.605  5.713  5.811  5.901  5.984  6.062  6.134  6.202  6.265  6.325;
 12    3.081  3.773  4.199  4.508  4.750  4.950  5.119  5.265  5.395  5.510  5.615  5.710  5.797  5.878  5.953  6.023  6.089  6.151  6.209;
 13    3.055  3.734  4.151  4.453  4.690  4.884  5.049  5.192  5.318  5.431  5.533  5.625  5.711  5.789  5.862  5.931  5.995  6.055  6.112;
 14    3.033  3.701  4.111  4.407  4.639  4.829  4.990  5.130  5.253  5.364  5.463  5.554  5.637  5.714  5.785  5.852  5.915  5.973  6.029;
 15    3.014  3.673  4.076  4.367  4.595  4.782  4.940  5.077  5.198  5.306  5.403  5.492  5.574  5.649  5.719  5.785  5.846  5.904  5.958;
 16    2.998  3.649  4.046  4.333  4.557  4.741  4.896  5.031  5.150  5.256  5.352  5.439  5.519  5.593  5.662  5.726  5.786  5.843  5.896;
 17    2.984  3.628  4.020  4.303  4.524  4.705  4.858  4.991  5.108  5.212  5.306  5.392  5.471  5.544  5.612  5.675  5.734  5.790  5.842;
 18    2.971  3.609  3.997  4.276  4.494  4.673  4.824  4.955  5.071  5.173  5.266  5.351  5.429  5.501  5.567  5.629  5.688  5.743  5.794;
 19    2.960  3.593  3.977  4.253  4.468  4.645  4.794  4.924  5.037  5.139  5.231  5.314  5.391  5.462  5.528  5.589  5.647  5.701  5.752;
 20    2.950  3.578  3.958  4.232  4.445  4.620  4.768  4.895  5.008  5.108  5.199  5.282  5.357  5.427  5.492  5.553  5.610  5.663  5.714;
 21    2.941  3.565  3.942  4.213  4.424  4.597  4.743  4.870  4.981  5.081  5.170  5.252  5.327  5.396  5.460  5.520  5.576  5.629  5.679;
 22    2.933  3.553  3.927  4.196  4.405  4.577  4.722  4.847  4.957  5.056  5.144  5.225  5.299  5.368  5.431  5.491  5.546  5.599  5.648;
 23    2.926  3.542  3.914  4.180  4.388  4.558  4.702  4.826  4.935  5.033  5.121  5.201  5.274  5.342  5.405  5.464  5.519  5.571  5.620;
 24    2.919  3.532  3.901  4.166  4.373  4.541  4.684  4.807  4.915  5.012  5.099  5.179  5.251  5.319  5.381  5.439  5.494  5.545  5.594;
 25    2.913  3.523  3.890  4.153  4.358  4.526  4.667  4.789  4.897  4.993  5.079  5.158  5.230  5.297  5.359  5.417  5.471  5.522  5.570;
 26    2.907  3.514  3.880  4.141  4.345  4.511  4.652  4.773  4.880  4.975  5.061  5.139  5.211  5.277  5.339  5.396  5.450  5.500  5.548;
 27    2.902  3.506  3.870  4.130  4.333  4.498  4.638  4.758  4.864  4.959  5.044  5.122  5.193  5.259  5.320  5.377  5.430  5.480  5.528;
 28    2.897  3.499  3.861  4.120  4.322  4.486  4.625  4.745  4.850  4.944  5.029  5.106  5.177  5.242  5.302  5.359  5.412  5.462  5.509;
 29    2.892  3.493  3.853  4.111  4.311  4.475  4.613  4.732  4.837  4.930  5.014  5.091  5.161  5.226  5.286  5.342  5.395  5.445  5.491;
 30    2.888  3.486  3.845  4.102  4.301  4.464  4.601  4.720  4.824  4.917  5.001  5.077  5.147  5.211  5.271  5.327  5.379  5.429  5.475;
 31    2.884  3.481  3.838  4.094  4.292  4.454  4.591  4.709  4.812  4.905  4.988  5.064  5.134  5.198  5.257  5.313  5.365  5.414  5.460;
 32    2.881  3.475  3.832  4.086  4.284  4.445  4.581  4.698  4.802  4.894  4.976  5.052  5.121  5.185  5.244  5.299  5.351  5.400  5.445;
 33    2.877  3.470  3.825  4.079  4.276  4.436  4.572  4.689  4.791  4.883  4.965  5.040  5.109  5.173  5.232  5.287  5.338  5.386  5.432;
 34    2.874  3.465  3.820  4.072  4.268  4.428  4.563  4.680  4.782  4.873  4.955  5.030  5.098  5.161  5.220  5.275  5.326  5.374  5.420;
 35    2.871  3.461  3.814  4.066  4.261  4.421  4.555  4.671  4.773  4.863  4.945  5.020  5.088  5.151  5.209  5.264  5.315  5.362  5.408;
 36    2.868  3.457  3.809  4.060  4.255  4.414  4.547  4.663  4.764  4.855  4.936  5.010  5.078  5.141  5.199  5.253  5.304  5.352  5.397;
 37    2.865  3.453  3.804  4.054  4.249  4.407  4.540  4.655  4.756  4.846  4.927  5.001  5.069  5.131  5.189  5.243  5.294  5.341  5.386;
 38    2.863  3.449  3.799  4.049  4.243  4.400  4.533  4.648  4.749  4.838  4.919  4.993  5.060  5.122  5.180  5.234  5.284  5.331  5.376;
 39    2.861  3.445  3.795  4.044  4.237  4.394  4.527  4.641  4.741  4.831  4.911  4.985  5.052  5.114  5.171  5.225  5.275  5.322  5.367;
 40    2.858  3.442  3.791  4.039  4.232  4.388  4.521  4.634  4.735  4.824  4.904  4.977  5.044  5.106  5.163  5.216  5.266  5.313  5.358;
 48    2.843  3.420  3.764  4.008  4.197  4.351  4.481  4.592  4.690  4.777  4.856  4.927  4.993  5.053  5.109  5.161  5.210  5.256  5.299;
 60    2.829  3.399  3.737  3.977  4.163  4.314  4.441  4.550  4.646  4.732  4.808  4.878  4.942  5.001  5.056  5.107  5.154  5.199  5.241;
 80    2.814  3.377  3.711  3.947  4.129  4.277  4.402  4.509  4.603  4.686  4.761  4.829  4.892  4.949  5.003  5.052  5.099  5.142  5.183;
120    2.800  3.356  3.685  3.917  4.096  4.241  4.363  4.468  4.560  4.641  4.714  4.781  4.842  4.898  4.950  4.998  5.043  5.086  5.126;
240    2.786  3.335  3.659  3.887  4.063  4.205  4.324  4.427  4.517  4.596  4.668  4.733  4.792  4.847  4.897  4.944  4.988  5.030  5.069;
1000000    2.772  3.314  3.633  3.858  4.030  4.170  4.286  4.387  4.474  4.552  4.622  4.685  4.743  4.796  4.845  4.891  4.934  4.974  5.012];

if df<=120;
    crit=stdrinv(alpha, df, ng);
else;   
      clear p 
      t=4;%number of points to use in fit
      p=fit(qt(end-t:end,1),qt(end-t:end,ng),'power2');
      crit = p.a.*df.^p.b+p.c;

end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function x = stdrinv(p, v, r)
%STDRINV Compute inverse c.d.f. for Studentized Range statistic
%   STDRINV(P,V,R) is the inverse cumulative distribution function for
%   the Studentized range statistic for R samples and V degrees of
%   freedom, evaluated at P.

%   Copyright 1993-2002 The MathWorks, Inc. 
%   $Revision: 1.3 $  $Date: 2002/02/04 18:52:50 $

% Based on Fortran program from statlib, http://lib.stat.cmu.edu
% Algorithm AS 190  Appl. Statist. (1983) Vol.32, No. 2
% Incorporates corrections from Appl. Statist. (1985) Vol.34 (1)

if (length(p)>1 | length(v)>1 | length(r)>1),
   error('STDRINV requires scalar arguments.'); % for now
end

[err,p,v,r] = distchck(3,p,v,r);
if (err > 0), error('Non-scalar arguments must match in size.'); end

% Handle illegal or trivial values first.
x = zeros(size(p));
if (length(x) == 0), return; end
ok = (v>0) & (v==round(v)) & (r>1) & (r==round(r) & (p<1));
x(~ok) = NaN;
ok = ok & (p>0);
v = v(ok);
p = p(ok);
r = r(ok);
if (length(v) == 0), return; end
xx = zeros(size(v));

% Define constants
jmax = 20;
pcut = 0.00001;
tiny = 0.000001;
upper = (p > .99);
if (upper)
   uppertail = 'u';
   p0 = 1-p;
else
   uppertail = 'l';
   p0 = p;
end

% Obtain initial values
q1 = qtrng0(p, v, r);
p1 = stdrcdf(q1, v, r, uppertail);
xx = q1;
if (abs(p1-p0) >= pcut*p0)
   if (p1 > p0), p2 = max(.75*p0, p0-.75*(p1-p0)); end
   if (p1 < p0), p2 = p0 + (p0 - p1) .* (1 - p0) ./ (1 - p1) * 0.75; end
   if (upper)
      q2 = qtrng0(1-p2, v, r);
   else
      q2 = qtrng0(p2, v, r);
   end

   % Refine approximation
   for j=2:jmax
      p2 = stdrcdf(q2, v, r, uppertail);
      e1 = p1 - p0;
      e2 = p2 - p0;
      d = e2 - e1;
      xx = (q1 + q2) / 2;
      if (abs(d) > tiny*p0)
         xx = (e2 .* q1 - e1 .* q2) ./ d;
      end
      if (abs(e1) >= abs(e2))
         q1 = q2;
         p1 = p2;
      end
      if (abs(p1 - p0) < pcut*p0), break; end
	   q2 = xx;
   end
end
   
x(ok) = xx;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ---------------------------------
function x = qtrng0(p, v, r)
% Algorithm AS 190.2  Appl. Statist. (1983) Vol.32, No.2
% Calculates an initial quantile p for a studentized range
% distribution having v degrees of freedom and r samples
% for probability p, p.gt.0.80 .and. p.lt.0.995.

t=norminv(0.5 + 0.5 .* p);
if (v < 120), t = t + 0.25 * (t.^3 + t) ./ v; end
q = 0.8843 - 0.2368 .* t;
if (v < 120), q = q - (1.214./v) + (1.208.*t./v); end
x = t .* (q .* log(r-1) + 1.4142);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function xout = stdrcdf(q, v, r, upper)
%STDRCDF Compute c.d.f. for Studentized Range statistic
%   F = STDRCDF(Q,V,R) is the cumulative distribution function for the
%   Studentized range statistic for R samples and V degrees of
%   freedom, evaluated at Q.
%
%   G = STDRCDF(Q,V,R,'upper') is the upper tail probability,
%   G=1-F.  This version computes the upper tail probability
%   directly (not by subtracting it from 1), and is likely to be
%   more accurate if Q is large and therefore F is close to 1.

%   Copyright 1993-2002 The MathWorks, Inc. 
%   $Revision: 1.3 $  $Date: 2002/02/04 19:25:50 $

% Based on Fortran program from statlib, http://lib.stat.cmu.edu
% Algorithm AS 190  Appl. Statist. (1983) Vol.32, No. 2
% Incorporates corrections from Appl. Statist. (1985) Vol.34 (1)
% Vectorized and simplified for MATLAB.  Added 'upper' option.

if (length(q)>1 | length(v)>1 | length(r)>1),
   error('STDRCDF requires scalar arguments.'); % for now
end
[err,q,v,r] = distchck(3,q,v,r);
if (err > 0), error('Non-scalar arguments must match in size.'); end
uppertail = 0;
if (nargin>3)
   if ~(  isequal(upper,'u') | isequal(upper,'upper') ...
        | isequal(upper,'l') | isequal(upper,'lower'))
      error('Fourth argument must be ''upper'' or ''lower''.');
   end
   uppertail = isequal(upper,'u') | isequal(upper,'upper');
end

% Accuracy can be increased by use of a finer grid.  Increase
% jmax, kmax and 1/step proportionally.
jmax = 15;          % controls maximum number of steps
kmax = 15;          % controls maximum number of steps
step = 0.45;        % node spacing
vmax = 120;         % max d.f. for integration over chi-square

% Handle illegal or trivial values first.
xout = zeros(size(q));
if (length(xout) == 0), return; end   
ok = (v>0) & (v==round(v)) & (r>1) & (r==round(r));
xout(~ok) = NaN;
ok = ok & (q > 0);
v = v(ok);
q = q(ok);
r = r(ok);
if (length(v) == 0), return; end
xx = zeros(size(v));

% Compute constants, locate midpoint, adjust steps.
g = step ./ (r .^ 0.2);
if (v > vmax)
   c = log(r .* g ./ sqrt(2*pi));
else
   h = step ./ sqrt(v);
   v2 = v * 0.5;
   c = sqrt(2/pi) * exp(-v2) .* (v2.^v2) ./ gamma(v2);
   c = log(c .* r .* g .* h);

   j=(-jmax:jmax)';
   hj = h * j;
   ehj = exp(hj);
   qw = q .* ehj;
   vw = v .* (hj + 0.5 * (1 - ehj .^2));
   C = ones(1,2*kmax+1);         % index to duplicate columns
   R = ones(1,2*jmax+1);         % index to duplicate rows
end

% Compute integral by summing the integrand over a
% two-dimensional grid centered approximately near its maximum.
gk = (0.5 * log(r)) + g * (-kmax:kmax);
w0 = c - 0.5 * gk .^ 2;
pz = normcdf(-gk);
if (~uppertail)
   % For regular cdf, use integrand as in AS 190.
   if (v > vmax)
      % don't integrate over chi-square
      x = normcdf(q - gk) - pz;
      xx = sum(exp(w0) .* (x .^ (r-1)));
   else
      % integrate over chi-square
      x = normcdf(qw(:,C) - gk(R,:)) - pz(R,:);
      xx = sum(sum(exp(w0(R,:) + vw(:,C)) .* (x .^ (r-1))));
   end
else
   % To compute the upper tail probability, we need an integrand that
   % contains the normal probability of a region consisting of a
   % hyper-quadrant minus a rectangular region at the origin of the
   % hyperquadrant.
   if (v > vmax)           % for large d.f., don't integrate over chi-square
      xhq   = (1 - pz) .^ (r-1);
      xrect = (normcdf(q - gk) - pz) .^ (r-1);
      xx = sum(exp(w0) .* (xhq - xrect));
   else                    % for typical cases, integrate over chi-square
      xhq   = (1 - pz) .^ (r-1);
      xrect = (normcdf(qw(:,C) - gk(R,:)) - pz(R,:)) .^ (r-1);
      xx = sum(sum(exp(w0(R,:) + vw(:,C)) .* (xhq(R,:) - xrect)));
   end
end

xout(ok) = xx;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%