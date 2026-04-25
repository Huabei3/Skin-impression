function [Iwb,gain] = grayEdgeWB2(I, sigma, p)
% grayEdgeWB2 - Second-order Gray Edge White Balance
%
% I     : Input RGB image (uint8 or double, range [0,255] or [0,1])
% sigma : Gaussian smoothing scale (e.g., 2)
% p     : Minkowski norm (e.g., 6)
%
% Iwb   : White-balanced image

% ---------- Input handling ----------
I = im2double(I);

if size(I,3) ~= 3
    error('Input must be an RGB image.');
end

% ---------- LoG filter (2nd-order derivative) ----------
filterSize = 2 * ceil(3*sigma) + 1;
LoG = fspecial('log', filterSize, sigma);

edgeEnergy = zeros(1,3);

% ---------- Compute second-order Gray Edge ----------
for c = 1:3
    Ic = I(:,:,c);
    
    % Apply Laplacian of Gaussian
    Ic_log = imfilter(Ic, LoG, 'replicate', 'conv');
    
    % Minkowski p-norm
    edgeEnergy(c) = mean(abs(Ic_log(:)).^p).^(1/p);
end

% ---------- Illumination estimation ----------
illum = edgeEnergy / norm(edgeEnergy);
gain = 1 ./ illum; 
% ---------- Diagonal white balance ----------
Iwb = zeros(size(I));
for c = 1:3
    Iwb(:,:,c) = I(:,:,c) ./ illum(c);
end

% ---------- Normalize to valid range ----------
Iwb = Iwb ./ max(Iwb(:));
Iwb = max(min(Iwb,1),0);

end
