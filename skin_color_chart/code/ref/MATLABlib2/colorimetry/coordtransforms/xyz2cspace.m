function lab=xyz2cspace(XYZ,XYZw,cspace,Laf,Ybf,surroundf,Did)
if nargin==1;cspace='uvp';end
switch cspace
    case 'lab'
        lab=xyz2lab(XYZ,XYZw);
    case 'luv'
        lab=xyz2luv(XYZ,XYZw);
    case 'ipt'
        lab=XYZ2IPT10(XYZ);
    case 'ipt10'
        lab=XYZ2IPT10(XYZ);
    case 'ipt2'
        lab=XYZ2IPT2(XYZ);
    case 'uvp'    
        lab=xyz2uvY(XYZ);
        lab=lab(:,[3,1:2]);
    case 'uvY'    
        lab=xyz2uvY(XYZ);
        lab=lab(:,[3,1:2]);
    case 'xyY'    
        lab=xyz2xyY(XYZ);
        lab=lab(:,[3,1:2]);
    case 'cam02'
        if nargin < 4;Laf=XYZw(2);end
        if nargin < 5;Ybf=20;end
        if nargin < 6; surroundf='avg';end        
        JCH=xyz2cam02(XYZ,XYZw,Laf,Ybf,surroundf);
        lab=[JCH(:,1),JCH(:,6:7)];
    case 'cam02ucs'
        if nargin < 4;Laf=XYZw(2);end
        if nargin < 5;Ybf=20;end
        if nargin < 6; surroundf='avg';end     
        if nargin < 7; Did=NaN;end  
        Jab=xyz2camucs_(XYZ,XYZw,Laf,Ybf,surroundf,Did);
        lab=Jab;
    case 'camucs'
        %set CAM02UCS parameters
        F=1;Nc=1;c=0.69;Laf=100;Ybf=20;surroundf=[F,Nc,c];Did=1;
        global Did_;Did = Did_;
        Jab=xyz2camucs_(XYZ,XYZw,Laf,Ybf,surroundf,Did);
        lab=Jab;
end  