function [xd,D]=waveletDenoising(x,y,wtype,wentropy,lev,alpha)
if nargin<4;wentropy='shannon';end
switch wtype
    case 1
    wname = 'db10'; 
    case 2
        wname = 'db9';
    case 3;
        wname='coif5';
    otherwise
        wname='coif5';
end
    if nargin<5;lev = 10;alpha=2;end
    if nargin<6;alpha = 2;end
    tree = wpdec(y,lev,wname,wentropy);
    det1 = wpcoef(tree,2);
    sigma = median(abs(det1))/0.6745;
    alpha = 2;
    thr =wpbmpen(tree,sigma,alpha);
    keepapp = 1;
    xd = wpdencmp(tree,'s','nobest',thr,keepapp);
    D=crosscorr(x,xd);
    