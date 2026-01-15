function [idx_select, labs_sel, centers_sel, info] = M2_EqualCube(lab, N, opts)
% M2_EqualCube  Equal-sized cube uniform coverage with hole completion.
% Implements the method described in CIC-JIST paper (Li & Yan):
% - Build equal-sized cube grid (two phase options) centered around d_ave
% - Count non-empty cubes and internal holes
% - Bisection on side length sl so that Nnec + Nh == N (or as close as possible)
% - Output two sets: centers_sel (centers of selected cubes) and labs_sel
%   (nearest real samples to each center). idx_select are indices into lab.
%
% Usage:
%   [idx, labs, centers, info] = M2_EqualCube(lab, N, opts)
% Inputs:
%   lab   : Nx3 matrix in CIELAB (D65/2) defining the colour solid
%   N     : target number of representative colours
%   opts  : struct with optional fields:
%       .phase   : 'I' | 'II' | 'auto' (default 'auto')
%       .sl_init : initial side length guess (default [])
%       .itmax   : max bisection iters (default 20)
%       .tolN    : acceptable mismatch in count (default 0)
%       .verbose : logical (default true)
%
% Outputs:
%   idx_select  : indices of selected real samples
%   labs_sel    : selected real samples (Nx3)
%   centers_sel : selected cube centers (Nx3)
%   info        : struct with diagnostics (sl, counts, timing, etc.)

if nargin < 3, opts = struct; end
if ~isfield(opts,'phase'),   opts.phase   = 'auto'; end
if ~isfield(opts,'itmax'),   opts.itmax   = 20; end
if ~isfield(opts,'tolN'),    opts.tolN    = 0; end
if ~isfield(opts,'verbose'), opts.verbose = true; end

lab = double(lab);
[n, d] = size(lab); %#ok<NASGU>
assert(d==3, 'lab must be Nx3');

% Precompute per-dim mins/aves/maxs
mins = min(lab,[],1); maxs = max(lab,[],1); aves = (mins+maxs)/2;

% Initial bracketing for sl via coarse scan
if isfield(opts,'sl_init') && ~isempty(opts.sl_init)
    sl0 = opts.sl_init;
else
    span = maxs - mins; % typical side length from volume/N^(1/3)
    sl0 = mean(span) / max(N^(1/3), 1);
    sl0 = max(1.0, sl0); % guard
end

% Helper to evaluate a given sl and phase
    function ev = eval_sl(sl, phase)
        [centers, startv, nv] = make_centers(mins, aves, maxs, sl, phase);
        % Map samples to nearest center (per-dim rounding)
        idxL = round((lab(:,1) - startv(1))/sl) + 1;
        idxA = round((lab(:,2) - startv(2))/sl) + 1;
        idxB = round((lab(:,3) - startv(3))/sl) + 1;
        % Keep only valid within grid bounds
        valid = idxL>=1 & idxL<=nv(1) & idxA>=1 & idxA<=nv(2) & idxB>=1 & idxB<=nv(3);
        occ = false(nv);
        lin = sub2ind(nv, idxL(valid), idxA(valid), idxB(valid));
        occ(lin) = true;
        % Holes: empty components not touching boundary (6-neigh)
        empt = ~occ;
        holes_mask = internal_holes(empt);
        Nnec = nnz(occ); Nh = nnz(holes_mask);
        % Centers for non-empty + holes
        centers_sel = centers(occ | holes_mask, :);
        ev.Nnec = Nnec; ev.Nh = Nh; ev.Nsum = Nnec + Nh;
        ev.sl = sl; ev.phase = phase; ev.centers = centers_sel;
        ev.startv = startv; ev.nv = nv; ev.occ = occ; ev.holes = holes_mask;
    end

% Try to bracket N by adjusting sl
phases = {'I','II'};
if strcmpi(opts.phase,'I'), phases = {'I'}; elseif strcmpi(opts.phase,'II'), phases = {'II'}; end

% Find slS (smaller) s.t. Nsum > N and slL (larger) s.t. Nsum < N
slS = max(sl0/2, 0.5); slL = sl0*2; evS = []; evL = [];
for rep=1:20
    evS = best_phase_eval(slS, phases);
    if evS.Nsum > N, break; end
    slS = slS/1.4; if slS < 0.2, break; end
end
for rep=1:20
    evL = best_phase_eval(slL, phases);
    if evL.Nsum < N, break; end
    slL = slL*1.4; if slL > 200, break; end
end

% Bisection on sl to match N
best = evS; % keep closest seen
if isempty(best) || abs(evL.Nsum - N) < abs(best.Nsum - N), best = evL; end
if ~isempty(evS) && ~isempty(evL)
    for it=1:opts.itmax
        slA = (slS + slL)/2;
        evA = best_phase_eval(slA, phases);
        if abs(evA.Nsum - N) < abs(best.Nsum - N), best = evA; end
        if evA.Nsum == N, best = evA; break; end
        if evA.Nsum < N
            slL = slA; evL = evA;
        else
            slS = slA; evS = evA;
        end
    end
end

% Selected centers (possibly not exactly N)
centers_all = best.centers;
if size(centers_all,1) ~= N
    % Adjust to exactly N by farthest-point selection or augmentation
    if size(centers_all,1) > N
        keep = farthest_ids(centers_all, N);
        centers_sel = centers_all(keep,:);
    else
        % Augment by FPS over lab around centers to reach N
        need = N - size(centers_all,1);
        add_idx = fps_from_pointset(lab, centers_all, need);
        centers_sel = [centers_all; lab(add_idx,:)];
    end
else
    centers_sel = centers_all;
end

% Map each center to nearest real sample
idx_select = knnsearch(lab, centers_sel,'K',1);
labs_sel = lab(idx_select,:);

% Info
info = struct('sl',best.sl,'phase',best.phase,'Nnec',best.Nnec,'Nh',best.Nh, ...
              'Nsum',best.Nsum,'nv',best.nv,'startv',best.startv);
if opts.verbose
    fprintf('M2: sl=%.3f phase=%s  Nnec=%d Nh=%d Nsum=%d -> N=%d\n', ...
        best.sl, best.phase, best.Nnec, best.Nh, best.Nsum, N);
end

end % main

% ==== helpers ====
function ev = best_phase_eval(sl, phases)
    ev = [];
    for i=1:numel(phases)
        e = eval_sl(sl, phases{i}); %#ok<NASGU>
        if isempty(ev)
            ev = e;
        else
            % prefer closer to target N when comparing elsewhere; here just pick denser (more centers)
            if e.Nsum > ev.Nsum, ev = e; end
        end
    end
end

function [centers, startv, nv] = make_centers(mins, aves, maxs, sl, phase)
    startv = zeros(1,3); nv = zeros(1,3);
    centers1 = cell(1,3);
    for i=1:3
        if phase == 'I'
            % centers at d_ave + k*sl
            kmin = ceil( (mins(i) - aves(i)) / sl );
            kmax = floor((maxs(i) - aves(i)) / sl );
            c = aves(i) + (kmin:kmax)*sl;
            if c(1) - mins(i) >= sl/2, c = [c(1)-sl, c]; end
            if maxs(i) - c(end) >= sl/2, c = [c, c(end)+sl]; end
        else
            % centers at d_ave + (k+0.5)*sl  -> start at d_ave - sl/2
            start = aves(i) - sl/2;
            kmin = ceil( (mins(i) - start) / sl );
            kmax = floor((maxs(i) - start) / sl );
            c = start + (kmin:kmax)*sl;
            if c(1) - mins(i) >= sl/2, c = [c(1)-sl, c]; end
            if maxs(i) - c(end) >= sl/2, c = [c, c(end)+sl]; end
        end
        centers1{i} = c(:);
        startv(i) = centers1{i}(1);
        nv(i) = numel(centers1{i});
    end
    [L,A,B] = ndgrid(centers1{1}, centers1{2}, centers1{3});
    centers = [L(:), A(:), B(:)];
end

function holes_mask = internal_holes(empt)
    % empt: logical 3D array (true = empty)
    sz = size(empt);
    % pad and flood-fill from boundary to mark external empty
    ext = false(sz);
    q = java.util.ArrayDeque();
    % enqueue all boundary empty voxels
    for i=1:sz(1)
        for j=1:sz(2)
            for k=1:sz(3)
                if ~(i==1 || j==1 || k==1 || i==sz(1) || j==sz(2) || k==sz(3)), continue; end
                if empt(i,j,k)
                    ext(i,j,k)=true; q.add([i j k]); %#ok<JAPIMATH>
                end
            end
        end
    end
    % 6-neighbour BFS
    nbr = [1 0 0; -1 0 0; 0 1 0; 0 -1 0; 0 0 1; 0 0 -1];
    while ~q.isEmpty()
        v = q.remove(); i=v(1); j=v(2); k=v(3);
        for t=1:6
            ii=i+nbr(t,1); jj=j+nbr(t,2); kk=k+nbr(t,3);
            if ii<1||jj<1||kk<1||ii>sz(1)||jj>sz(2)||kk>sz(3), continue; end
            if empt(ii,jj,kk) && ~ext(ii,jj,kk)
                ext(ii,jj,kk)=true; q.add([ii jj kk]); %#ok<JAPIMATH>
            end
        end
    end
    holes_mask = empt & ~ext;
end

function ids = farthest_ids(P, m)
    % Farthest point sampling on P (Euclidean), returns indices of size m
    n = size(P,1); assert(m<=n);
    ids = zeros(m,1); ids(1) = 1; % seed
    dist2 = sum((P - P(ids(1),:)).^2,2);
    for i=2:m
        [~, ids(i)] = max(dist2);
        d2 = sum((P - P(ids(i),:)).^2,2);
        dist2 = min(dist2, d2);
    end
end

function add_idx = fps_from_pointset(P, seeds, need)
    % Choose additional points from P farthest from a set of seed points
    if isempty(seeds)
        seed = P(1,:);
        dist2 = sum((P - seed).^2,2);
    else
        % init with min distance to any seed
        dist2 = inf(size(P,1),1);
        for k=1:size(seeds,1)
            d2 = sum((P - seeds(k,:)).^2,2);
            dist2 = min(dist2, d2);
        end
    end
    add_idx = zeros(need,1);
    for i=1:need
        [~, add_idx(i)] = max(dist2);
        d2 = sum((P - P(add_idx(i),:)).^2,2);
        dist2 = min(dist2, d2);
    end
end
