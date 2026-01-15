function yi=find_spd(spd,xi)
    if(size(xi,1)==1)
        xi=xi';
    end
    x=spd(:,1);
    y=spd(:,2:end);
    yi=interp1(x,y,xi,'v5cubic'); 
% yi=interp1(x,y,xi,'linear'); 
    
    t=sum(xi<x(1));
    if(t)%小于min(x)以及大于max(x)的值都要用边界的值来填充
        %[~,index]=min(abs(xi-x(1)));
        yi(1:t,:)=repmat(yi(t+1,:),t,1);
    end
    
    t=sum(xi>x(end));
    if(t)
        [~,index]=min(abs(xi-x(end)));
        yi(index+1:end,:)=repmat(yi(index,:),t,1);
    end
    yi=[xi,yi];
end

% load xyz.mat%间隔5的观测者
% XYZ(i,2)=sum(xyz(2,:).*spd(k,:).*rr(i,:)*5);
%     