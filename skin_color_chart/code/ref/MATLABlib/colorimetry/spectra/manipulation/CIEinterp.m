function Ynew=interpK(X,Y,Xnew,type,extrap);
% 1-D interpolation (table lookup) with all negative values set to 0!
% Extrapolate if necessary: if extrapolation produces impossible results,
% set to closest old value.
%
%     YI = INTERP1(X,Y,XI) interpolates to find YI, the values of
%     the underlying function Y at the points in the vector, or array XI. X
%     must be a vector of length N, and SIZE(Y,1) must be N.  If Y is an array
%     of size [N,M1,M2,...,Mk] then the interpolation is performed for 
%     each M1-by-M2-by-...-Mk value in Y.  If XI is an array of size
%     [D1,D2,...,Dj], then YI will be of size [D1,D2,...,Dj,M1,M2,...,Mk].
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin<5;extrap=1;end
if nargin <4; extrap=1;type='v5cubic';end
switch type
    case 'none'
    case 'lagrange'
        Ynew=Lagrange(X,Y,Xnew);
    case 'sprague';
        Ynew=sprague(X,Y,Xnew);
        if isnan(Ynew);Ynew = (interp1(X,Y,Xnew,'v5cubic'));end
    otherwise
        Ynew = (interp1(X,Y,Xnew,type));
        %plot(X,Y,'b-');hold on;plot(Xnew,Ynew,'b.-')
end
%extrapolate beyond begin and end boundary;
switch extrap
    case 0
        if sum(Ynew(Xnew<X(1))>0) | sum(isnan(Ynew(Xnew<X(1)))); Ynew(Xnew<X(1))=0;end %if extrapolation produces impossible results, set to closest old value.
        if sum(Ynew(Xnew>X(end))>0) | sum(isnan(Ynew(Xnew>X(end))));Ynew(Xnew>X(end))=0;end %if extrapolation produces impossible results, set to closest old value.
    case 1
        if sum(Ynew(Xnew<X(1))>0) | sum(isnan(Ynew(Xnew<X(1)))); Ynew(Xnew<X(1))=Y(1);end %if extrapolation produces impossible results, set to closest old value.
        if sum(Ynew(Xnew>X(end))>0) | sum(isnan(Ynew(Xnew>X(end))));Ynew(Xnew>X(end))=Y(end);end %if extrapolation produces impossible results, set to closest old value.
        
end


Ynew(Ynew<0)=0;

end
