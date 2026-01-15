function [idx_select, labs_sel, info] = M5_Generative_Expand(lab, N, opts)
% M5_Generative_Expand  GMM/KDE-based edge expansion + coverage optimization.
% - Fit a GMM to the LAB data
% - Generate virtual edge-expanded samples by extrapolating boundary points
%   along the direction from the nearest component mean (scale >1)
% - Run equal-cube coverage (M2 core) on the union of real + virtual points
% - Map selected centers to nearest real samples
%
% Usage: [idx, labs, info] = M5_Generative_Expand(lab, N, opts)
%   opts.K          : # GMM components (default 5)
%   opts.expand     : scalar s>1 extrapolation factor (default 1.2)
%   opts.alpha_factor : for boundary detection (default 3.0)
%   opts.phase/sl/itmax/tolN : forwarded to internal M2 call (optional)
%   opts.verbose    : default true

if nargin<3, opts = struct; end
if ~isfield(opts,'K'), opts.K = 5; end
if ~isfield(opts,'expand'), opts.expand = 1.2; end
if ~isfield(opts,'alpha_factor'), opts.alpha_factor = 3.0; end
if ~isfield(opts,'verbose'), opts.verbose = true; end

lab = double(lab); N = min(N, size(lab,1));

% Fit GMM
try
    gmm = fitgmdist(lab, opts.K, 'RegularizationValue',1e-6,'Options',statset('MaxIter',500));
catch ME
    warning('M5: GMM fit failed (%s); falling back to K=1 Gaussian.', ME.message);
    mu = mean(lab,1); S = cov(lab);
    gmm = struct('mu',mu,'Sigma',reshape(S,1,3,3),'ComponentProportion',1,'NumComponents',1);
end

% Boundary points (alpha shape)
bd_idx = boundary_estimate(lab, opts.alpha_factor);
Pbd = lab(bd_idx,:);

% Extrapolate boundary points away from nearest component means
virt = zeros(size(Pbd));
for i=1:size(Pbd,1)
    p = Pbd(i,:);
    % find nearest component mean
    if isstruct(gmm) && isfield(gmm,'mu') && ~isfield(gmm,'mu_component')
        mu = gmm.mu; % fallback single mean
    else
        mu = gmm.mu; % for gmdistribution
    end
    [~,k] = min(sum((mu - p).^2,2));
    dir = p - mu(k,:);
    if all(dir==0), dir = p - mean(lab,1); end
    virt(i,:) = mu(k,:) + opts.expand * dir;
end

% Combine and run M2 centers on union
cand = [lab; virt];
opts2 = rmfield_or(opts, {'K','expand','alpha_factor','verbose'});
opts2.verbose = false;
[~, ~, centers, infoM2] = M2_EqualCube(cand, N, opts2);

% Map centers to nearest real samples
idx_select = knnsearch(lab, centers, 'K',1);
labs_sel = lab(idx_select,:);

info = struct('K',opts.K,'expand',opts.expand,'alpha',opts.alpha_factor,'M2',infoM2);
if opts.verbose
    fprintf('M5: virtual=%d (from boundary), selected N=%d via M2-coverage\n', size(virt,1), numel(idx_select));
end

end

% === helpers ===
function bd_idx = boundary_estimate(P, alpha_factor)
    try
        IDX = knnsearch(P,P,'K',7);
        nn = sqrt(sum((P - P(IDX(:,2),:)).^2,2));
        a = median(nn) * alpha_factor;
        shp = alphaShape(P(:,1),P(:,2),P(:,3), a);
        [F, X] = boundaryFacets(shp);
        verts = unique(F(:)); Xb = X(verts,:);
        bd_idx = unique(knnsearch(P, Xb, 'K',1));
    catch
        try
            [K,~] = convhulln(P); bd_idx = unique(K(:));
        catch
            bd_idx = (1:size(P,1)).';
        end
    end
end

function S = rmfield_or(S, names)
    for i=1:numel(names)
        if isfield(S, names{i}), S = rmfield(S, names{i}); end
    end
end
