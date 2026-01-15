function dE=deltaE(data1,data2,dims)
%calculates colour difference using dims as dimensions:
%e.g. dE=deltaE(lab1,lab2,123) calculates dE using L*, a*,b* 
% or dE=deltaE(lab1,lab2,23) calculates dE using a*,b* 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin<3 dims=123;end
switch dims
    case 123
        dE=sqrt((data1(:,1)-data2(:,1)).^2+(data1(:,2)-data2(:,2)).^2+(data1(:,3)-data2(:,3)).^2);
    case 23
        dE=sqrt((data1(:,2)-data2(:,2)).^2+(data1(:,3)-data2(:,3)).^2);
    case 12
        dE=sqrt((data1(:,1)-data2(:,1)).^2+(data1(:,2)-data2(:,2)).^2);
    case 13
        dE=sqrt((data1(:,1)-data2(:,1)).^2+(data1(:,3)-data2(:,3)).^2);
end
end