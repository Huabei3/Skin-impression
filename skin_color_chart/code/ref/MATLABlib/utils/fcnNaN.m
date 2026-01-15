function m=fcnNaN(data,fcn,dim)
%remove NaNs before performing function fcn. Report NaN when all values
%were NaN.
if nargin<2;fcn=@(x) mean(x);end
if nargin<3;dim=1;end

if dim>=1;
    dims = 1:numel(size(data));
    dims_remaining = dims(~ismember(dims,dim));
    data=permute(data,[dim,dims_remaining]);
end

m = nan(1,size(data,2));
for i=1:size(data,2);
    x=data(:,i);
    x=x(~isnan(x));
    if ~isempty(x)
        m(i)=fcn(x);
    end
end

if dim>=1;
    dims = 1:numel(size(m));
    dims_remaining = dims(~ismember(dims,dim));
    m=permute(m,[dim,dims_remaining]);
end