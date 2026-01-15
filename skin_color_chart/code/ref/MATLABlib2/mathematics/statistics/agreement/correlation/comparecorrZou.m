function [p,r0CI]=comparecorrZou(r1x,r2x,r12,N,alpha)
error('ComparecorrZou.m gives wrong p-value, however CI works!!!')
%gives errors!!!!!

%compare correlated correlation coefficients using the
%Zou's method of confidence intervals
%r1x = correlation between set 1 and set x
%r2x = correlation between set 2 and set x
%r12 = correlation between set 1 and set 2
%n  = number of samples
%ntype = two-tailed ('=') or one-tailed ('<' or '>')
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
r12(r12==1)=0.9999999;%avoid div by zero
r1x(r1x==1)=0.9999999;%avoid div by zero
r2x(r2x==1)=0.9999999;%avoid div by zero
if nargin<5;alpha=0.05;end
z1=0.5*log((1+r1x)/(1-r1x));
z2=0.5*log((1+r2x)/(1-r2x));
z=[z1,z2];

zSE=sqrt(1./(N-3));

r0CI=getCI(alpha,z,zSE,r1x,r2x,r12);

findp=@(x) getCI(x,z,zSE,r1x,r2x,r12);

[r0CI,p]=findp(alpha);



% figure(1);plot(alpha,r0CI,'gp');hold on;plot(alpha,r0CI,'gp');

% alphas=[0.000001,(0.0001:0.00001:0.001),(0.001:0.0001:0.01),(0.01:0.001:0.1),(0.1:0.01:1)];
% for i=1:numel(alphas)
%     r0CIs(i,:)=findp(alphas(i));
%     figure(1);plot(alphas(i),r0CIs(i,1),'bo');hold on;plot(alphas(i),r0CIs(i,2),'bo');
% end
% x0=0.00000001;x=fminsearch(@(x) findp_(x,findp),x0);
% p=x
% r0CI=[findp(p)];
% figure(1);plot(p,r0CI,'r*');hold on;plot(p,r0CI,'r*');

function F=findp_(x,findp)

CI=findp(x);
if sum(CI>0)==2 | sum(CI<0)==2
    F=1000;
else
    F=min(abs(CI));

end


function [r0CI,p]=getCI(alpha,z,zSE,r1x,r2x,r12)
if nargout==2;alpha=0.05;end
zcrit=norminv(alpha/2);
zL=z+zcrit.*zSE;
zU=z-zcrit.*zSE;

rL=(exp(2.*zL)-1)./(exp(2.*zL)+1);
rU=(exp(2.*zU)-1)./(exp(2.*zU)+1);

rdiff=r1x-r2x;
r1x2x=((r12-0.5*r1x*r2x)*(1-r1x^2-r2x^2-r12^2)+r12^3)/((1-r1x^2)*(1-r2x^2));

L=rdiff-((r1x-rL(1))^2+(rU(2)-r2x)^2-2*(r1x2x*(r1x-rL(1))*(rU(2)-r2x)))^0.5;
U=rdiff+((rU(1)-r1x)^2+(r2x-rL(2))^2-2*(r1x2x*(rU(1)-r1x)*(r2x-rL(2))))^0.5;

r0CI=[L,U];

zL=0.5*log((1+L)/(1-L));
zU=0.5*log((1+U)/(1-U));
z=0.5*log((1+rdiff)/(1-rdiff));

%get p-value
p_SE = abs((r0CI(2) -r0CI(1))/(2.*norminv(alpha/2)));
p_r = rdiff/p_SE;
pr = exp(-0.717.*p_r-0.416.*p_r.^2);

p_SE = abs((zU -zL)/(2.*norminv(alpha/2)));
p_z = z/p_SE;
pz = exp(-0.717.*p_z-0.416.*p_z.^2);
p=pz;
 p=[pr,pz];

