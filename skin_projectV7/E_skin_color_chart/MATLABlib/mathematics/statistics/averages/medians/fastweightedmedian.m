function [m,iqr,CF,Q13] = fastweightedmedian( x, w, alpha, dim )
% Fast weighted median.
%
% Computes the weighted median of a set of samples.
%  http://en.wikipedia.org/wiki/Weighted_median
% "A weighted median of a sample is the 50% weighted percentile."
% For matrices computes median along each column (or dimension dim).
% If all weights are equal to 1 gives identical results to median.
%
% USAGE
%  m = medianw( x, w, [dim] )
%
% INPUTS
%  x      - vector or array of samples
%  w      - vector or array of weights
%  dim    - dimension along which to compute median
%
% OUTPUTS
%  m      - weighted median value of x
%
% EXAMPLE - simple toy example
%  x=[1 2 3]; w=[1 1 5]; medianw(x,w)
%
% EXAMPLE - comparison to median
%  n=randi(100); m=randi(100);
%  x=rand(n,m); w=ones(n,m);
%  m1=median(x); m2=medianw(x,w);
%  assert(isequal(m1,m2))
%
% See also median
%
% Piotr's Image&Video Toolbox      Version 3.24
% Copyright 2013 Piotr Dollar.  [pdollar-at-caltech.edu]
% Adjusted K.A.G. Smet, Sep 2 2014
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if(nargin<2),w=ones(size(x));alpha=0.05; dim=find(size(x)~=1,1); end
if(nargin<3),alpha=0.05; dim=find(size(x)~=1,1); end
if(nargin<4), dim=find(size(x)~=1,1); end

[m,dSort]=quartile(x,w,dim,0.5);%weigthed median

%calculate IQR
Q1=quartile(x,w,dim,0.25);
Q3=quartile(x,w,dim,0.75);
iqr=abs(Q3-Q1);
Q13=[Q1,Q3];

%calculate confidence intervals: Conover, W.J. (1980) Practical
%Nonparametric Statistics John Wiley and Sons, New
%York.(http://www-users.york.ac.uk/~mb55/intro/cicent.htm) 
%Access date, Sep 2, 2014
a=norminv(1-alpha/2);
j=(numel(dSort).*0.5-a.*sqrt(numel(dSort).*0.5.*(1-0.5)));
k=(numel(dSort).*0.5+a.*sqrt(numel(dSort).*0.5.*(1-0.5)));
j(j<1)=1;k(k<1)=1;
j=ceil(j);
k=ceil(k);
CF=[dSort(j),dSort(k)];
end


function [m,x]=quartile(x,w,dim,Qi)



if(nargin<3), dim=find(size(x)~=1,1); end
d=dim; 
nd=ndims(x); 
n=numel(x);

if( n==1 || size(x,d)==1 )
  m=x;
elseif( length(x)==n )
  [x,o]=sort(x); 
  w=w(o); 
  w=cumsum(w);
  w=w/w(end); 
  [~,j]=min(w<=Qi);
  if(j==1 || w(j-1)~=Qi), 
      m=x(j);
  else
      m=(x(j-1)+x(j))/2; 
  end
else
  if(d>1), 
      p=[d 1:d-1 d+1:nd]; 
      x=permute(x,p); 
      w=permute(w,p); 
  end
  [x,o]=sort(x); 
  w=w(o); 
  w=cumsum(w); 
  is={':'}; 
  is=is(ones(1,nd-1));
  w=bsxfun(@rdivide,w,w(end,is{:})); 
  [~,j]=min(w<=Qi);
  s=size(x); 
  s=reshape(((1:n/s(1))-1)*s(1),size(j));
  j0=max(1,j-1); 
  j0=j0+s; 
  j=j+s;
  same=w(j0)~=Qi; 
  j0(same)=j(same); 
  m=(x(j0)+x(j))/2;
  if(d>1), 
      p=[2:d 1 d+1:nd]; 
      m=permute(m,p); 
  end
end

end
