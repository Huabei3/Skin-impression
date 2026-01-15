function par=findrescaling_metric(metric,de,ra,par0);

opts=optimset('fminsearch');
opts.MaxFun=10^4;

global counter
counter=0;

switch metric
    case 'ciecri'
        disp(sprintf('calculating rescaling factor(s) for ciecri...'))
        par=fminsearch(@(par) scalefunction_ciecri(de,par,ra),par0,opts);
        
    case 'cri2012'
        disp(sprintf('calculating rescaling factor(s) for cri2012...'))
        par=fminsearch(@(par) scalefunction_cri2012(de,par,ra),par0,opts);
        
    case 'cqsv9p0'
        disp(sprintf('calculating rescaling factor(s) for cqsv9p0...'))
        par=fminsearch(@(par) scalefunction_cqsv9p0(de,par,ra),par0,opts);
       
    case 'sandersrp'
        disp(sprintf('calculating rescaling factor(s) for sandersrp...'))

        parB=fminsearch(@(parB) scalefunction_sandersrp(de,parB,ra,'B'),par0(1),opts);
        parC=fminsearch(@(parC) scalefunction_sandersrp(de,parC,ra,'C'),par0(2),opts);
        par=[parB parC];
        
    case 'juddrf'
        disp(sprintf('calculating rescaling factor(s) for juddrf...'))
        par=fminsearch(@(par) scalefunction_juddrf(de,par,ra),par0,opts);
             
    case 'cpi'
        disp(sprintf('calculating rescaling factor(s) for thorntoncpi...'))
        par=fminsearch(@(par) scalefunction_cpi(de,par,ra),par0,opts);
        
    case 'mcri'
        disp(sprintf('calculating rescaling factor(s) for mcri...'))
        par=fminsearch(@(par) scalefunction_mcri(de,par,ra),par0,opts);
    
end

%--------------------------------------------------------------------------
function [F,Rm_n]=scalefunction_mcri(sa,par,Rm_t)
global counter
counter=counter+1;
p1=par(1);p2=par(2);p3=par(3);

Rm_n=100.*(2./(exp(p1.*(abs(log(sa))).^p2)+1)).^p3;

Sa_line=0:0.01:1;Rm_line=100.*(2./(exp(p1.*(abs(log(Sa_line))).^p2)+1)).^p3;
F=sum(abs(Rm_t-Rm_n));

figure(1);subplot(1,2,1);
plot(Sa_line,Rm_line,'r');hold on
plot(sa,Rm_n,'bo');hold off
subplot(1,2,2);hold on;
plot(counter,F)


function [F,Ra_n]=scalefunction_mcri_euc_lin(de,par,Ra_t)
global counter
counter=counter+1;

Ra_n=100-par.*de;Ra_n(Ra_n>100)=100;
F=sum(abs(mean(Ra_n)-mean(Ra_t)));%keep means the same
de_line=0:20;Ra_line=100-par.*de_line;Ra_line(Ra_line>100)=100;

figure(1);subplot(1,2,1);
plot(de_line,Ra_line,'r');hold on
plot(de,Ra_n,'bo');
plot(mean(de),mean(Ra_t),'gs');
plot(mean(de),mean(Ra_n),'kp');hold off
subplot(1,2,2);hold on;
plot(counter,F)


%--------------------------------------------------------------------------
function [F,Ra_n]=scalefunction_cpi(de,par,Ra_t)
global counter
counter=counter+1;

Ra_n=156-par.*de;
F=sum(abs(mean(Ra_n)-mean(Ra_t)));%keep means the same

de_line=0:20;Ra_line=156-par.*de_line;
figure(1);subplot(1,2,1);
plot(de_line,Ra_line,'r');hold on
plot(de,Ra_n,'bo');
plot(mean(de),mean(Ra_t),'gs');
plot(mean(de),mean(Ra_n),'kp');hold off
subplot(1,2,2);hold on;
plot(counter,F)

%--------------------------------------------------------------------------
function [F,Ra_n]=scalefunction_juddrf(de,par,Ra_t)
global counter
counter=counter+1;

Ra_n=100-par.*de;Ra_n(Ra_n>100)=100;
F=sum(abs(mean(Ra_n)-mean(Ra_t)));%keep means the same
de_line=0:20;Ra_line=100-par.*de_line;Ra_line(Ra_line>100)=100;

figure(1);subplot(1,2,1);
plot(de_line,Ra_line,'r');hold on
plot(de,Ra_n,'bo');
plot(mean(de),mean(Ra_t),'gs');
plot(mean(de),mean(Ra_n),'kp');hold off
subplot(1,2,2);hold on;
plot(counter,F)

%--------------------------------------------------------------------------
function [F,Ra_n]=scalefunction_sandersrp(de,par,Ra_t,IllBCtype)
global counter
counter=counter+1;

pf=[-12.0748  -36.7331    0.2507  100.0000];%polynomal representation of dRcurve
switch IllBCtype
    case 'B'
        %keep all d2 values
        de=abs(de); %make sure all de's are positive (change negative d value for beefsteak to pos)
    case 'C'
        %remove beefsteak if still in set (check for negative d-value)
        de=abs(de(de>0));
end


Ra_n=polyval(pf,par.*mean(de));Ra_n(Ra_n>100)=100;
F=sum(abs(mean(Ra_n)-mean(Ra_t)));%keep means the same
de_line=(0:0.0002:1.5);Ra_line=polyval(pf,par.*de_line);Ra_line(Ra_line>100)=100;



figure(1);subplot(1,2,1);
plot(de_line,Ra_line,'r');hold on
plot(de,Ra_n,'bo');
plot(mean(de),mean(Ra_t),'gs');
plot(mean(de),mean(Ra_n),'kp');hold off
subplot(1,2,2);hold on;
plot(counter,F)


%--------------------------------------------------------------------------
function [F,Ra_n]=scalefunction_cqsv9p0(de,par,Ra_t)
global counter
counter=counter+1;

GA=1;%no CCT factor
Ra_n=(100-de.*par);
Ra_n=GA.*log(exp(Ra_n/10)+1).*10;
F=sum(abs(mean(Ra_n)-mean(Ra_t)));%keep means the same

de_line=0:20;Ra_line=100-par.*de_line;Ra_line=GA.*log(exp(Ra_line/10)+1).*10;

figure(1);subplot(1,2,1);
plot(de_line,Ra_line,'r');hold on
plot(de,Ra_n,'bo');
plot(mean(de),mean(Ra_t),'gs');
plot(mean(de),mean(Ra_n),'kp');hold off
subplot(1,2,2);hold on;
plot(counter,F)

%--------------------------------------------------------------------------
function [F,Ra_n]=scalefunction_cri2012(de,par,Ra_t)
global counter
counter=counter+1;

Ra_n = 100 * (2 ./ (exp((par) .* abs(de) .^ (3 / 2)) + 1)) .^ 2;
F=sum(abs(mean(Ra_n)-mean(Ra_t)));%keep means the same

de_line=0:20;Ra_line=100 * (2 ./ (exp((par) .* abs(de_line) .^ (3 / 2)) + 1)) .^ 2;

figure(1);subplot(1,2,1);
plot(de_line,Ra_line,'r');hold on
plot(de,Ra_n,'bo');
plot(mean(de),mean(Ra_t),'gs');
plot(mean(de),mean(Ra_n),'kp');hold off
subplot(1,2,2);hold on;
plot(counter,F)

%--------------------------------------------------------------------------
function [F,Ra_n]=scalefunction_ciecri(de,par,Ra_t)
global counter
counter=counter+1;

Ra_n=100-par.*de;
F=sum(abs(mean(Ra_n)-mean(Ra_t)));%keep means the same
de_line=0:20;Ra_line=100-par.*de_line;

figure(1);subplot(1,2,1);
plot(de_line,Ra_line,'r');hold on
plot(de,Ra_n,'bo');
plot(mean(de),mean(Ra_t),'gs');
plot(mean(de),mean(Ra_n),'kp');hold off
subplot(1,2,2);hold on;
plot(counter,F)
