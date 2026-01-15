function XYZ=jch2xyzcam02c(JCh,XYZw,La,Yb,surround)

% JCh2XYZCAM02: inverse model of CIECAM02 corrected for yellow-blue and
% purple problem
% calculates XYZ from appearance coordinates J, C and h
%
% XYZ=JCh2XYZCAM02(XYZ,XYZw,Lw,Yb,surround)
% Calculation as described in CIE Technical Report 'A Colour 
% Appearance Model for Colour Management Systems'.
%
% Default viewing condition corresponds to ISO 3664 P1 set-up
% Surround arguments can be 'avg', 'dim', or 'dark'
%
% Example: XYZ=JCh2XYZCAM02(JCh,[96.42,100,82.49],63.66,20,'avg')
%
%   Colour Engineering Toolbox
%   author:    © Phil Green
%   version:   1.1
%   date:  	   30-12-2004
%   book:      http://www.wileyeurope.com/WileyCDA/WileyTitle/productCd-0471486884.html
%   web:       http://www.digitalcolour.org

% Get parameters
if nargin>2;else La=2000/(pi*5);end % luminance of adapted white point
if nargin>3;else Yb=20;end % luminance of background (typically 20)
if nargin>4;
   if strcmp(surround,'average');F=1;c=0.69;Nc=1;s=1;end % average surround
   if strcmp(surround,'avg');F=1;c=0.69;Nc=1;s=1;end % average surround
   if strcmp(surround,'disp')||strcmp(surround,'display');c=0.69;Nc=1;F=0;s=1;end % for computer display colours
   if strcmp(surround,'dim');F=0.9;c=0.59;Nc=0.9;s=1;end % dim surround
   if strcmp(surround,'dark');F=0.8;c=0.525;Nc=0.8;s=1;end % dark surround
   if strcmp(surround,'T1');F=1;c=0.46;Nc=0.9;s=1;end % ISO 3664 T1 surround
else F=1;c=0.69;Nc=1;s=1;  % ISO 3664 P1, average surround
end

% Calculate constants
%F=1;
Yw=XYZw(2); F=1;
D=F*(1-(1/3.6)*exp((-La-42)/92)); %degree of adaptation
k=1/(5*La+1);
FL=0.2*k^4*5*La+0.1*(1-k^4)^2*(5*La)^(1/3);
n=Yb/Yw;
Nbb=0.725*(1/n)^0.2;
Ncb=0.725*(1/n)^0.2;
z=1.48+n^0.5;

J=JCh(:,1);C=JCh(:,2);h=JCh(:,3);

% CAT02 forward matrix
MCAT02=[0.7328,0.4296,-0.1624;
-0.7036,1.6975,0.0061;
0.0030,0.0136,0.9834];

% Hunt-Pointer-Estevez matrix
MH=[0.38971,0.68898,-0.07868;
-.22981,1.1834,0.04641;
0,0,1];

% CAT02 inverse matrix
MCAT02i=[1.096124,-0.278869,0.182745;
0.454369,0.473533,0.072098;
-0.009628,-0.005698,1.015326];

% Pre-multiply inverse CAT02 and HPE matrices
MHM=MH*MCAT02i;

% Pre-multiply CAT02 and inverse HPE matrices
MHCi=MCAT02*inv(MH);

   % Calculate Aw
   RGBw=(MCAT02*XYZw')';
   Rw=RGBw(:,1);Gw=RGBw(:,2);Bw=RGBw(:,3);

   Rcw=(Yw*(D/Rw)+1-D)*Rw;
   Gcw=(Yw*(D/Gw)+1-D)*Gw;
   Bcw=(Yw*(D/Bw)+1-D)*Bw;

   RGBpw=(MHM*[Rcw,Gcw,Bcw]')';
   Rpw=RGBpw(:,1);Gpw=RGBpw(:,2);Bpw=RGBpw(:,3);

   Rpaw=0.1+((400*(FL*Rpw/100).^0.42)./(27.13+(FL*Rpw/100).^0.42));
   Gpaw=0.1+((400*(FL*Gpw/100).^0.42)./(27.13+(FL*Gpw/100).^0.42));
   Bpaw=0.1+((400*(FL*Bpw/100).^0.42)./(27.13+(FL*Bpw/100).^0.42));

   Aw=(2*Rpaw+Gpaw+0.05*Bpaw-0.305)*Nbb; % achromatic signal of white
   
% Compute t, e, p1, p2 and p3
t=(C./((J/100).^(1/2)*(1.64-0.29^n)^0.73)).^(1/0.9);
et=(cos(h*pi/180+2)+3.8)/4;
A=Aw*(J/100).^(1/(c*z));
p1=(50000/13)*Nc*Ncb.*et./t;
p2=A/Nbb+0.305;
p3=21/20;

% Calculate temporary Cartesian coordinates  a and b
at=cos(h*pi/180);
bt=sin(h*pi/180);
p4=p1./bt;
p5=p1./at;

p=abs(bt)>=abs(at);
q=abs(bt)<abs(at);

r=size(JCh,1);a=zeros(r,1);b=a;

b(p)=p2(p)*(2+p3)*(460/1403)./(p4(p)+(2+p3).*(220/1403)*(at(p)./bt(p))-(27/1403)+p3*(6300/1403));
a(p)=b(p).*(at(p)./bt(p));

a(q)=p2(q)*(2+p3)*(460/1403)./(p5(q)+(2+p3).*(220/1403)-((27/1403)-p3*(6300/1403))*(bt(q)./at(q)));
b(q)=a(q).*(bt(q)./at(q));

% Calculate post-adaptation values
Rpa=(460*p2+451*a+288*b)/1403;
Gpa=(460*p2-891*a-261*b)/1403;
Bpa=(460*p2-220*a-6300*b)/1403;

% Convert back to Hunt-Pointer-Estevez space
Rp=100*(((27.13*abs(Rpa-0.1))./(400-abs(Rpa-0.1)))).^(1/0.42)/FL;
j=find(Rpa<0.1);Rp(j)=-Rp(j);

Gp=100*(((27.13*abs(Gpa-0.1))./(400-abs(Gpa-0.1)))).^(1/0.42)/FL;
l=find(Gpa<0.1);Gp(l)=-Gp(l);

Bp=100*(((27.13*abs(Bpa-0.1))./(400-abs(Bpa-0.1)))).^(1/0.42)/FL;
m=find(Bpa<0.1);Bp(m)=-Bp(m);

% RGB after chromatic adaptation
RGBc=(MHCi*[Rp,Gp,Bp]')';
Rc=RGBc(:,1);Gc=RGBc(:,2);Bc=RGBc(:,3);

% Convert back to CAT02 LMS space
R=Rc/(Yw*(D/Rw)+1-D);
G=Gc/(Yw*(D/Gw)+1-D);
B=Bc/(Yw*(D/Bw)+1-D);

% Calculate XYZ
XYZ=(MCAT02i*[R,G,B]')';
XYZ(XYZ<0)=0;

