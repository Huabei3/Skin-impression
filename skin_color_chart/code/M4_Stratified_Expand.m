function [idx_select, labs_sel, info] = M4_Stratified_Expand(lab, N, opts)
% M4_Stratified_Expand  Multi-dimensional stratified coverage + edge expansion.
% - Stratify by L* bins and Hue sectors; optional Chroma bins.
% - Allocate quota per stratum ~ uniform with edge expansion weight.
% - Sample within each stratum via farthest-point sampling.
%
% Usage: [idx, labs, info] = M4_Stratified_Expand(lab, N, opts)
%   opts.nL    : # L* bins (default 12)
%   opts.nHue  : # hue sectors over [-180,180) (default 8)
%   opts.nCh   : # chroma bins (0 means disabled; default 0)
%   opts.edge_boost : weight factor for edge strata (default 0.5)
%   opts.alpha_factor: for boundary estimation (default 3.0)
%   opts.verbose: default true

if nargin<3, opts=struct; end
if ~isfield(opts,'nL'), opts.nL = 12; end
if ~isfield(opts,'nHue'), opts.nHue = 8; end
if ~isfield(opts,'nCh'), opts.nCh = 0; end
if ~isfield(opts,'edge_boost'), opts.edge_boost = 0.5; end
if ~isfield(opts,'alpha_factor'), opts.alpha_factor = 3.0; end
if ~isfield(opts,'verbose'), opts.verbose = true; end

lab = double(lab); N = min(N, size(lab,1));
L = lab(:,1); a = lab(:,2); b = lab(:,3);
C = hypot(a,b); H = atan2d(b,a); % [-180,180]

% Bins
Ledges = linspace(min(L), max(L), opts.nL+1);
Hedges = linspace(-180, 180, opts.nHue+1);
if opts.nCh>0
    Cedges = linspace(min(C), max(C), opts.nCh+1);
else
    Cedges = [min(C) max(C)];
end

% Boundary points for edge boosting
bd_idx = boundary_estimate(lab, opts.alpha_factor);
ismbd = false(size(lab,1),1); ismbd(bd_idx)=true;

% Assign each point to a stratum id
[idL,~] = discretize(L,Ledges); [idH,~] = discretize(H,Hedges); [idC,~] = discretize(C,Cedges);
valid = ~isnan(idL) & ~isnan(idH) & ~isnan(idC);
ids = [idL(valid), idH(valid), idC(valid)];
lin = sub2ind([opts.nL, opts.nHue, max(1,opts.nCh)], ids(:,1), ids(:,2), ids(:,3));

% Collect members per stratum
G = accumarray(lin, find(valid), [opts.nL*opts.nHue*max(1,opts.nCh), 1], @(x){x});
% Edge fraction per stratum
Ecnt = accumarray(lin, ismbd(valid), [numel(G), 1], @sum, 0);
Cnt  = cellfun(@numel, G);
edge_frac = zeros(numel(G),1); nz = Cnt>0; edge_frac(nz) = Ecnt(nz)./Cnt(nz);

% Weights: uniform + edge boost
w = ones(numel(G),1) + opts.edge_boost * edge_frac;
w = w .* (Cnt>0); % zero out empty strata
wsum = sum(w); if wsum==0, w(:)=1; wsum = sum(w); end
quota = floor(N * (w/wsum));
% Distribute remainders by largest fractional and with available members
rem = N - sum(quota);
if rem>0
    [~,order] = sort((N*(w/wsum)-quota),'descend');
    k=1;
    while rem>0 && k<=numel(order)
        idx = order(k);
        if Cnt(idx) > quota(idx)
            quota(idx) = quota(idx) + 1; rem = rem - 1;
        end
        k=k+1;
    end
end

% Sample within each stratum
sel = [];
for s=1:numel(G)
    if quota(s)<=0 || isempty(G{s}), continue; end
    members = G{s};
    m = min(quota(s), numel(members));
    ids_local = farthest_ids(lab(members,:), m);
    sel = [sel; members(ids_local)]; %#ok<AGROW>
end

% If still not exactly N due to shortages, top-up globally via FPS
if numel(sel) < N
    need = N - numel(sel);
    topup = fps_from_excluding(lab, sel, need);
    sel = [sel; topup];
elseif numel(sel) > N
    keep = farthest_ids(lab(sel,:), N);
    sel = sel(keep);
end

idx_select = sel(:);
labs_sel = lab(idx_select,:);
info = struct('nL',opts.nL,'nHue',opts.nHue,'nCh',opts.nCh,'edge_boost',opts.edge_boost);
if opts.verbose
    fprintf('M4: strata=%d (L*%d x H%d x C%d), selected N=%d\n', ...
        opts.nL*opts.nHue*max(1,opts.nCh), opts.nL, opts.nHue, max(1,opts.nCh), numel(idx_select));
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

function ids = farthest_ids(P, m)
    n = size(P,1); m = min(m,n); ids = zeros(m,1);
    ids(1) = 1; d2 = sum((P - P(1,:)).^2,2);
    for i=2:m
        [~, ids(i)] = max(d2);
        d2 = min(d2, sum((P - P(ids(i),:)).^2,2));
    end
end

function top = fps_from_excluding(P, exclude_idx, need)
    mask = true(size(P,1),1); mask(exclude_idx)=false;
    Q = P(mask,:); % candidates
    seeds = P(exclude_idx,:);
    % init dist to nearest seed
    if isempty(seeds)
        d2 = sum((Q - Q(1,:)).^2,2);
    else
        d2 = inf(size(Q,1),1);
        for k=1:size(seeds,1)
            d2 = min(d2, sum((Q - seeds(k,:)).^2,2));
        end
    end
    top_local = zeros(need,1);
    for i=1:need
        [~, top_local(i)] = max(d2);
        d2 = min(d2, sum((Q - Q(top_local(i),:)).^2,2));
    end
    % map back
    cand_idx = find(mask);
    top = cand_idx(top_local);
end
