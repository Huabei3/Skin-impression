% export fit_table.lab_values from Peggy_VIVO_table.mat to long CSV (ASCII only)
MAT  = 'D:\work\VIVOSkinExpe\PeggySkinBackup\B_dataset\D_ZJU_entire_skin\ZJU_skin_database\B_Tables\Peggy_VIVO_table.mat';
OUTD = 'D:\work\VIVOSkinExpe\deepskin\_peggy_export';
if ~exist(OUTD, 'dir'); mkdir(OUTD); end

S = load(MAT);
T = S.fit_table;
fprintf('=== fit_table: %d rows x %d vars ===\n', height(T), width(T));
vn = T.Properties.VariableNames;
for k = 1:numel(vn)
    v = T.(vn{k});
    fprintf('%2d) %-18s class=%-10s size=%s\n', k, vn{k}, class(v), mat2str(size(v)));
end

lv = T.lab_values;
fprintf('=== lab_values class=%s size=%s ===\n', class(lv), mat2str(size(lv)));
if iscell(lv)
    fprintf('cell{1}: class=%s size=%s\n', class(lv{1}), mat2str(size(lv{1})));
    M0 = lv{1};
elseif ndims(lv) == 3
    M0 = lv(:,:,1);
    fprintf('first slice size=%s\n', mat2str(size(M0)));
else
    M0 = lv;
end
fprintf('point 1 Lab = %s\n', mat2str(M0(1,:)));
np = size(M0, 1);
fprintf('n_points = %d\n', np);

hasCenter = ismember('lab_center', vn);
fprintf('has lab_center = %d\n', hasCenter);

n = height(T);
attr = strings(n, 1); mid = strings(n, 1); ot = strings(n, 1);
scn = strings(n, 1); scode = strings(n, 1); ior = strings(n, 1);
cL = nan(n, 1); cA = nan(n, 1); cB = nan(n, 1);

for r = 1:n
    try
        attr(r) = string(T.attribute(r));
        mid(r)  = string(T.model_id(r));
        ot(r)   = string(T.observer_type(r));
        s = string(T.scene(r));
        scn(r) = s;
        t = regexprep(s, '^\s*(inLab|outLab)\s+', '', 'ignorecase');
        scode(r) = lower(strtrim(t));
        if ismember('scene_ior', vn)
            ior(r) = string(T.scene_ior(r));
        end
        if hasCenter
            c = T.lab_center{r};
            if isnumeric(c) && numel(c) >= 3
                cL(r) = c(1); cA(r) = c(2); cB(r) = c(3);
            end
        end
    catch ME
        fprintf('row %d ERR %s\n', r, ME.message);
    end
end

N = n * np;
A1 = strings(N, 1); A2 = strings(N, 1); A3 = strings(N, 1); A4 = strings(N, 1);
A5 = strings(N, 1); A6 = strings(N, 1);
pIdx = zeros(N, 1); Lv = nan(N, 1); Av = nan(N, 1); Bv = nan(N, 1);
idx = 0;
for r = 1:n
    if iscell(lv)
        M = lv{r};
    elseif ndims(lv) == 3
        M = lv(:, :, r);
    else
        M = lv;
    end
    for p = 1:size(M, 1)
        idx = idx + 1;
        A1(idx) = attr(r); A2(idx) = mid(r); A3(idx) = ot(r);
        A4(idx) = scn(r); A5(idx) = scode(r); A6(idx) = ior(r);
        pIdx(idx) = p; Lv(idx) = M(p, 1); Av(idx) = M(p, 2); Bv(idx) = M(p, 3);
    end
end
longT = table(A1, A2, A3, A4, A5, A6, pIdx, Lv, Av, Bv, ...
    'VariableNames', {'attribute','model_id','observer_type','scene','scene_code','scene_ior','i_point','L','a','b'});
writetable(longT, fullfile(OUTD, 'peggy_lab_values.csv'));
fprintf('wrote %s rows=%d\n', fullfile(OUTD, 'peggy_lab_values.csv'), height(longT));

cenT = table(attr, mid, ot, scn, scode, ior, cL, cA, cB, ...
    'VariableNames', {'attribute','model_id','observer_type','scene','scene_code','scene_ior','center_L','center_a','center_b'});
writetable(cenT, fullfile(OUTD, 'peggy_lab_centers.csv'));
fprintf('wrote centers rows=%d\n', height(cenT));
fprintf('=== done ===\n');
