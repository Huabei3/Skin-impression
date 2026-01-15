function [XYZ,XYZw]=spd2xyz(spddata, obs, AorR,rfldata)
%Calculate XYZ from source spectrum (and reflectance spectrum)
%spddata = filename or matrixname of SPD data
%obs = 2 for 2 degree, 10 for 10 degree CIE standard observer
%AorR: absolute (1) or relative tristimulus values (default = 1), 
%rfldata = filename or matrixname of Reflectance data (0: calculate XYZ of SPD, not SPD.*RFL)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin<2;obs=2;AorR=1;rfldata=0;;end
if nargin<3;AorR=1;rfldata=0;end
if nargin<4;rfldata=0;end

%read colour matching functions

[cmf,k]=selectcmf(obs);

%if data is file then read file else data is matlab matrix
if ischar(spddata) == 1  
    spd=convertspdformat(spddata);
    spd = dlmread(spddata);
else
    spd = spddata;
end


lambdas=spd(:,1);
r=find((lambdas>=360) & (lambdas<=830));

spd=spd(r,:);
lambdas=spd(:,1);
dl=abs(lambdas(1)-lambdas(2));
spd=spd(:,2);


%to save calculation time only perform interpolation when necessary
if ((dl==5) | (dl==1) | (dl==2)) & ((lambdas(1,1)==380) | (lambdas(1,1)==360));
    cmf=cmf(1:dl:end,2:end);
    if lambdas(1,1)==380;cmf=cmf(20/dl+1:end-50/dl,:);end;%for 380:780 nm data
else
    for i=1:3;cmf_(:,i)=interpK(cmf(:,1),cmf(:,i+1),lambdas,'linear');end;cmf=cmf_;clear cmf_;
end
    

%Relative or absolute tristimulus values?
if AorR==0
        k=100./sum(spd.*cmf(:,2).*dl); %relative tristimulus
end

%surface color or object color?  
if rfldata~=0 %=surface color
    %if data is file then read file else data is matlab matrix
    if ischar(rfldata) == 1  
        rfl=convertspdformat(rfldata);
        rfl = dlmread(rfldata);
    else
        rfl = rfldata;
    end
    for i=1:size(rfl,2)-1;
        rfl_(:,i)=interpK(rfl(:,1),rfl(:,i+1),lambdas,'linear'); 
    end
    rfl=rfl_;
    k=100./sum(spd.*cmf(:,2).*dl);
else %=selfluminous color
    rfl=ones(1,size(spd,1))'  ;
end

for i=1:size(rfl,2);
    
    XYZ(i,:)=k*[sum(spd.*rfl(:,i).*cmf(:,1)),sum(spd.*rfl(:,i).*cmf(:,2)),sum(spd.*rfl(:,i).*cmf(:,3))].*dl;
end
XYZw=k*[sum(spd.*cmf(:,1).*dl),sum(spd.*cmf(:,2).*dl),sum(spd.*cmf(:,3).*dl)];

end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function X=neg2zero(X)
X=(X+X.*sign(X))/2;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function Ynew=interpK(X,Y,Xnew,type,extrap);
% 1-D interpolation (table lookup) with all negative values set to 0!
% Extrapolate if necessary: if extrapolation produces impossible results,
% set to closest old value.
%
%     YI = INTERP1(X,Y,XI) interpolates to find YI, the values of
%     the underlying function Y at the points in the vector, or array XI. X
%     must be a vector of length N, and SIZE(Y,1) must be N.  If Y is an array
%     of size [N,M1,M2,...,Mk] then the interpolation is performed for 
%     each M1-by-M2-by-...-Mk value in Y.  If XI is an array of size
%     [D1,D2,...,Dj], then YI will be of size [D1,D2,...,Dj,M1,M2,...,Mk].
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin<5;extrap=1;end
if nargin <4; extrap=1;type='v5cubic';end
switch type
    case 'none'
    case 'lagrange'
        Ynew=Lagrange(X,Y,Xnew);
    case 'sprague';
        Ynew=sprague(X,Y,Xnew);
        if isnan(Ynew);Ynew = (interp1(X,Y,Xnew,'v5cubic'));end
    otherwise
        Ynew = (interp1(X,Y,Xnew,type));
        %plot(X,Y,'b-');hold on;plot(Xnew,Ynew,'b.-')
end
%extrapolate beyond begin and end boundary;
switch extrap
    case 0
        if sum(Ynew(Xnew<X(1))>0) | sum(isnan(Ynew(Xnew<X(1)))); Ynew(Xnew<X(1))=0;end %if extrapolation produces impossible results, set to closest old value.
        if sum(Ynew(Xnew>X(end))>0) | sum(isnan(Ynew(Xnew>X(end))));Ynew(Xnew>X(end))=0;end %if extrapolation produces impossible results, set to closest old value.
    case 1
        if sum(Ynew(Xnew<X(1))>0) | sum(isnan(Ynew(Xnew<X(1)))); Ynew(Xnew<X(1))=Y(1);end %if extrapolation produces impossible results, set to closest old value.
        if sum(Ynew(Xnew>X(end))>0) | sum(isnan(Ynew(Xnew>X(end))));Ynew(Xnew>X(end))=Y(end);end %if extrapolation produces impossible results, set to closest old value.
        
end


Ynew=neg2zero(Ynew);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function data=convertspdformat(filename)
%convert komma decimal numbers to point decimal numbers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
datastring=textread(filename,'%s');
chardatastring=char(datastring);
kommapos=find(chardatastring==',');
chardatastring(kommapos)='.';
data=str2double(cellstr(chardatastring));
lendata=length(data);
positions=(1:lendata);
oddn=find(mod(positions,2)~=0);
evenn=find(mod(positions,2)==0);
lamb=data(oddn);
spdy=data(evenn);
data=[lamb,spdy];
format long
dlmwrite(filename,data,'delimiter','\t','precision','%.12g');
end