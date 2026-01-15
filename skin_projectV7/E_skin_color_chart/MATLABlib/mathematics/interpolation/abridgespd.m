function spdi=abridgespd(spdi,d)
if nargin==1;d=5;end
M=diag(ones(numel(spdi(:,1))+2*(floor(d/2)+1),1));M(M==1)=0;
for j=1:numel(spdi(:,1));i=ceil((j-1)+d-(floor(d/2)+1));M(i:d+i-1,j)=ones(d,1);end;
p=sum(M,2)>floor(d/2);%te=[p,(377:783)',M];te=te(p,:);
M=M(p,:);M=M(:,1:numel(spdi(:,1)));
%xlswrite('abridgementmatrix.xlsx',M);
Mspdi=sum(repmat(spdi(:,2),1,numel(spdi(:,1))).*M,1)./sum(M,1);
spdi=Mspdi(1:d:end)';