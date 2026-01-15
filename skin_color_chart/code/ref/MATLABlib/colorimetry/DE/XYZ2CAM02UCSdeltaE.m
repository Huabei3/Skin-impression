function deltaE= XYZ2CAM02UCSdeltaE(XYZ1,XYZw1,La1,Yb1,surround1,XYZ2,XYZw2,La2,Yb2,surround2);
%Calculate dE using CAM02UCS
%Input:
%   XYZ1,XYZ2 = input tristimulus values
%   XYZw1 = adapting white point under test source 1
%   XYZw2 = adapting white point under test source 2
%   La1 = adapting luminance of test source 1
%   La2 = adapting luminance of test source 2
%   Yb1 = background luminance under test source 1 in percent of white luminance 
%   Yb2 = background luminance under test source 2 in percent of white
%   luminance 
%   surround1 =  surround conditions under test source 1 ('average', 'dark', 'dim' or 'disp')
%   surround2 =  surround conditions under test source 1 ('average', 'dark', 'dim' or 'disp')
%       Note :
%           Default values for La, Yb, surround and FLL correspond to ISO 3664 P1 set-up
%           Surround arguments can either be 'avg', 'dim' or 'dark' or a vector of numeric 
%           values for c, Nc and F. Such values should follow the recommendations in CIE (2004).
%Output: dE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%ù

Jab1=XYZ2CAM02UCS(XYZ1,XYZw1,La1,Yb1,surround1);
Jab2=XYZ2CAM02UCS(XYZ2,XYZw2,La2,Yb2,surround2);
KL=1;
deltaE = ((((Jab1(:,1)-Jab2(:,2))./KL).^2)+(Jab1(:,2)-Jab2(:,2)).^2+(Jab1(:,3)-Jab2(:,3)).^2).^0.5;
end