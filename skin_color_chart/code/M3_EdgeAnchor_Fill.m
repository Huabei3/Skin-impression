function [idx_select, labs_sel, info] = M3_EdgeAnchor_Fill(lab, N, opts)
% M3_EdgeAnchor_Fill  Gamut edge anchoring + internal filling.
% 1) Estimate the colour solid boundary (alpha shape).
% 2) Select anchors on boundary via farthest-point sampling (FPS).
% 3) Fill internal points via FPS from remaining interior.
%
% Usage: [idx, labs, info] = M3_EdgeAnchor_Fill(lab, N, opts)
%   lab   : Nx3 CIELAB
%   N     : target number
%   opts  : fields (optional)
%       .edge_ratio   : fraction for edge anchors (default 0.3)
%       .alpha_factor : alpha = factor * median 6-NN distance (default 3.0)
%       .edge_boost   : extra weight to prefer more extreme boundary points (default true)
%       .verbose      : logical (default true)

if nargin < 3, opts = struct; end
if ~isfield(opts,'edge_ratio'), opts.edge_ratio = 0.3; end
if ~isfield(opts,'alpha_factor'), opts.alpha_factor = 3.0; end
if ~isfield(opts,'edge_boost'), opts.edge_boost = true; end
if ~isfield(opts,'verbose'), opts.verbose = true; end

lab = double(lab);
Nedge = max(1, min(N-1, round(N*opts.edge_ratio)));
Nfill = N - Nedge;

% Boundary estimation via alpha shape
[bd_idx, shp] = boundary_points_alpha(lab, opts.alpha_factor);
if isempty(bd_idx)
    warning('M3: boundary detection failed, falling back to convex hull vertices');
    [K,~] = convhulln(lab); bd_idx = unique(K(:));
end

% Edge anchoring via FPS on boundary points
P_edge = lab(bd_idx,:);
edge_ids_local = farthest_ids(P_edge, Nedge);
edge_idx = bd_idx(edge_ids_local);

% Internal filling via FPS on interior (exclude already chosen)
mask = true(size(lab,1),1); mask(edge_idx) = false;
P_int = lab(mask,:);
fill_ids_local = farthest_ids(P_int, Nfill);
all_idx = [edge_idx; find(mask).'(fill_ids_local)']; %#ok<*NASGU>

idx_select = all_idx;
labs_sel = lab(idx_select,:);

% Info
info = struct('edge_idx',edge_idx,'alpha',shp.Alpha,'Nedge',Nedge,'Nfill',Nfill);
if opts.verbose
    fprintf('M3: edge anchors=%d, internal fill=%d (alpha=%.3f)\n', Nedge, Nfill, shp.Alpha);
end

end

% === helpers ===
function [bd_idx, shp] = boundary_points_alpha(P, alpha_factor)
    % alpha from median 6-NN distance
    try
        IDX = knnsearch(P,P,'K',7);
        nn = sqrt(sum((P - P(IDX(:,2),:)).^2,2));
        a = median(nn) * alpha_factor;
        shp = alphaShape(P(:,1),P(:,2),P(:,3), a);
        [F, X] = boundaryFacets(shp); %#ok<ASGLU>
        if isempty(F)
            bd_idx = [];
            return;
        end
        verts = unique(F(:));
        Xb = X(verts,:);
        map = knnsearch(P, Xb, 'K',1);
        bd_idx = unique(map(:));
    catch
        shp = alphaShape(P(:,1),P(:,2),P(:,3));
        try
            [K,~] = convhulln(P);
            bd_idx = unique(K(:));
        catch
            bd_idx = [];
        end
    end
end

function ids = farthest_ids(P, m)
    n = size(P,1); m = min(m,n); ids = zeros(m,1);
    ids(1) = 1; d2 = sum((P - P(1,:)).^2,2);
    for i=2:m
        [~, ids(i)] = max(d2);
        d2 = min(d2, sum((P - P(ids(i),:)).^2,2));
    end
end
