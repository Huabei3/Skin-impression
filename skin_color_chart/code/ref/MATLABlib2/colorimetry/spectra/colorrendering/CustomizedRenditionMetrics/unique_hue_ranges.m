%unique_hue_ranges
%Some studies don't have all hues present in their objects.
%Those hues should be excluded in the calculations.
%Selection of hue range is based on semantics:
%e.g. no blue and magenta are present then the hue range would
%go from the lower limit of red to the upper limit of cyan.
%Estimates of hue ranges were calculated based on the unique hues as
%defined in ciecam02.
%Hue ranges were visually checked using a graphical 'srgb'-representation 
%of the reflectance samples of all metrics under D65.
%--------------------------------------------------------------------------

%unique hues from ciecam02
uh = [20 90 164 238 380];%red yellow green blue red

%binary hues
ubh = diff(uh./2);

%all major hues
h = unique([uh, uh + [ubh,0]]); % red orange yellow lime green cyan blue magenta red

%hue ranges
dh = [diff(h),0];

LU1=([h-dh./2;h;h+dh./2]); %approximate 1
LU=round(LU1(:,1:end-1))

%correct approximate 1 for direction of diff
h=fliplr(h);
LU2=(fliplr([h-abs([diff(h),0])./2;h;h+abs([diff(h),0])./2])); %approximate

LU2(:,1)=LU1(:,1);
LU1(:,end)=LU2(:,end);

LU=((LU1+LU2)./2);
LU(:,end)=LU(:,1)+360;

for i=1:size(LU,2)-1
    m=mean([LU(3,i);LU(1,i+1)]);
    LU(3,i)=m;
    LU(1,i+1)=m;
end
m=mean([LU(1,end)-360;LU(1,1)]);
LU(1,1)=m+360;
LU(1,end)=m+360;
LU(3,end-1)=m+360;
LU=round(LU(:,1:end-1))

% approximate 1-->
% red: 0<20<38
% orange: 38<55<73
% yellow: 73<90<109
% lime: 109<127<146
% green: 146<164<183
% cyan: 183<201<220
% blue: 220<238<274
% magenta: 274<309<360