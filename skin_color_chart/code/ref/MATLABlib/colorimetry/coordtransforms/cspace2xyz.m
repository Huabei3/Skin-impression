function xyz=cspace2xyz(lab,XYZw,cspace,Laf,Ybf,surroundf,Did)
if nargin==1;cspace='uvp';end

switch cspace
    case 'lab'
        xyz=lab2xyz(lab,XYZw);
    case 'luv'
        xyz=lab2xyz(lab,XYZw);
    case 'ipt'
        xyz=ipt2xyz(lab);
    case 'ipt10'
        xyz=ipt2xyz10(lab);
    case 'ipt2'
        xyz=ipt2xyz2(lab);
    case 'uvp'    
        xyz=uvY2xyz(lab);
     case 'uvY'    
        xyz=uvY2xyz(lab);
    case 'xyY'    
        lab=lab(:,[2,3,1]);
        xyz=xyY2xyz(lab);
     case 'cam02'
        if nargin < 4;Laf=XYZw(2);end
        if nargin < 5;Ybf=100;end
        if nargin < 6; surroundf='avg';end       
        
        %first convert abJ to JCh for input in reverse ciecam02 model
        abJ=[lab(:,2:3),lab(:,1)];%convert from Jab format 2 abJ format
        C=sqrt(abJ(:,1).^2+abJ(:,2).^2);%chroma
        h=(180/pi)*atan2(abJ(:,2),abJ(:,1)); % hue angle
        j=(abJ(:,1)<0);h(j)=h(j)+360;
        JCh=[abJ(:,3),C,h];
        
        xyz=jch2xyzcam02(JCh(:,1:3),XYZw,Laf,Ybf,surroundf); 
    case 'cam02ucs'
        if nargin < 4;Laf=XYZw(2);end
        if nargin < 5;Ybf=20;end
        if nargin < 6; surroundf='avg';end  
        if nargin < 7; Did = NaN; end
        xyz=jab2xyzcamucs_(lab,XYZw,Laf,Ybf,surroundf,Did); 
    case 'camucs'
        %set CAM02UCS parameters
        F=1;Nc=1;c=0.69;Laf=100;Ybf=20;surroundf=[F,Nc,c];Did=1;
        global Did_;Did = Did_;
        xyz=jab2xyzcamucs_(lab,XYZw,Laf,Ybf,surroundf,Did); 

end      