function smoothed=smooth_(data, method,pars)
switch method
    case 'fft1'
        n=numel(data);
        nn=round(n*pars);
        f = fft(data);
        f(n/2+1-nn:n/2+nn) = zeros(2*nn,1);
        smoothed = real(ifft(f));
        %plot(data,'r');hold on;plot(smoothed,'g')
    case 'fft2'
        smoothed=smooth1q(data,'fft');
    case 'dft'
        smoothed=smooth1q(data,'fft');
end

function y = smooth1q(y,method)

%SMOOTH1Q Quick spline smoothing for 1-D data.
%   Z = SMOOTH1Q(Y) smooths data Y using a DCT- or FFT-based spline
%   smoothing method.
%
%   SMOOTH1Q is a simplified and quick version of SMOOTHN for 1-D data. If
%   you want to smooth N-D arrays or data with missing values, use SMOOTHN.
%   Use also <a
%   href="matlab:web('http://www.mathworks.com/matlabcentral/fileexchange/25634')">SMOOTHN</a> for robust smoothing.
%
%   Z = SMOOTH1Q(Y,METHOD) smooths data Y with specified METHOD. The
%   available methods are:
%
%       'dct'  - Discrete cosine transform (default)
%       'fft'  - Fast Fourier transform (for periodic data)
%
%   'DCT' is the default METHOD. Use the 'FFT' METHOD with periodic data.
%
%   Notes
%   -----
%   1) SMOOTH1Q works with regularly spaced data only.
%   2) The smoothness parameter used in this algorithm is determined
%      automatically by minimizing the generalized cross-validation score.
%      See the references for more details.
%
%   References
%   ----------
%   1) Buckley MJ, Fast computation of a discretized thin-plate smoothing
%   spline for image data. Biometrika, 1994.
%   <a
%   href="matlab:web('http://biomet.oxfordjournals.org/content/81/2/247')">Link</a>
%   2) Garcia D, Robust smoothing of gridded data in one and higher
%   dimensions with missing values. Computational Statistics & Data
%   Analysis, 2010. 
%   <a
%   href="matlab:web('http://www.biomecardio.com/pageshtm/publi/csda10.pdf')">PDF download</a>
%
%   Examples:
%   --------
%   % 1-D curve - 'DCT' method
%   x = linspace(0,100,1000);
%   y = cos(x/10)+(x/50).^2 + randn(size(x))/5;
%   z = smooth1q(y);
%   plot(x,y,'r.',x,z,'k','LineWidth',2)
%   axis tight square
%
%   % Periodic 1-D curve - 'FFT' method
%   x = linspace(0,2*pi,1000);
%   y = cos(x)+ sin(2*x+1).^2 + randn(size(x))/5;
%   z = smooth1q(y,'fft');
%   plot(x,y,'r.',x,z,'k','LineWidth',2)
%   axis tight square
%
%   % Limaon - 'FFT' method
%   t = linspace(0,2*pi,1000);
%   x = cos(t).*(.5+cos(t)) + randn(size(t))*0.05;
%   y = sin(t).*(.5+cos(t)) + randn(size(t))*0.05;
%   z = smooth1q(complex(x,y),'fft');
%   plot(x,y,'r.',real(z),imag(z),'k','linewidth',2)
%   axis equal tight
%
%   See also SMOOTHN, SMOOTH.
%
%   -- Damien Garcia -- 2012/08
%   website: <a
%   href="matlab:web('http://www.biomecardio.com')">www.BiomeCardio.com</a>

assert(isvector(y),['Y must be a vector. Use <a href="matlab:web(''',...
    'http://www.mathworks.com/matlabcentral/fileexchange/25634'')">SMOOTHN</a> for non vector arrays.'])
assert(all(isfinite(y)),['Use <a href="matlab:web(''',...
    'http://www.mathworks.com/matlabcentral/fileexchange/25634'')">SMOOTHN</a> if Y contains missing values.'])

if nargin==1
    method = 'dct';
end
method = lower(method);

n = length(y);
siz0 = size(y);
y = y(:).';

switch method
    case 'dct'
        Lambda = 2-2*cos((0:n-1)*pi/n);
        Y = dct(y);
    case 'fft'
        Lambda = 2-2*cos(2*(0:n-1)*pi/n);
        Y = fft(y);
    otherwise
        warning('MATLAB:smooth1q:UnknownMethod',...
            ['''' method ''' is not a valid method. The ''dct'' method is used'])
        method = 'dct';
        Lambda = 2-2*cos((0:n-1)*pi/n);
        Y = dct(y);
end

fminbnd(@GCVscore,-10,30,optimset('TolX',.1));

switch method
    case 'dct'
        y = idct(Gamma.*Y);
    case 'fft'
        if isreal(y)
            y = ifft(Gamma.*Y,'symmetric');
        else
            y = ifft(Gamma.*Y);
        end
end

y = reshape(y,siz0);

    function GCVs = GCVscore(p)
        s = 10^p;
        Gamma = 1./(1+s*Lambda.^2);
        RSS = norm(Y.*(Gamma-1))^2;
        TrH = sum(Gamma);
        GCVs = RSS/(1-TrH/n)^2;
    end

end