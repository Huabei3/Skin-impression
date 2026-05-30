%% PREPARE_TOMAX_FOR_DEEPSKIN
% 将 toMax 数据集预处理为 deepskin 网络可直接读取的格式
%
% 输出结构 (在 deepskin/data/toMax 下):
%   rendered_face/{scenePerson}/       -> {original_name}_face.jpg
%   rendered_face_uv/{scenePerson}/    -> {original_name}_face_uv.npy
%   rendered_2max/{scenePerson}/       -> {original_name}.jpg
%   gt/toMax_gt.xlsx                   -> 每个 scenePerson 一个 sheet
%
% 依赖:
%   - 推荐有 Computer Vision Toolbox (人脸检测)
%   - 无需 Image Processing Toolbox (UV 用手动 RGB->Luv)
%
% 使用说明:
%   1) 首次测试: 保持 TEST_FIRST = true，直接运行本脚本，只处理 f01i
%   2) 批量处理: 将 TEST_FIRST 改为 false，并核对 suffixes 与 new_names 一一对应
%   3) 运行: 在 MATLAB 命令行输入 prepare_tomax_for_deepskin 或直接按 F5

%% ====================== 用户可配置区域 ======================
TEST_FIRST = false;   % <-- 首次测试设为 true，确认无误后改为 false 跑全部

new_names = {'f04','f05','f06','m04','m05','m06',...
             'f01','f02','f03','m01','m02','m03',...
             'f07','f08','m07','m08',...
             'f09','f10','m09','m10'};

% 与 new_names 一一对应的后缀 (i / r / 其他)
% 请根据实际文件夹名修改，确保长度与 new_names 一致
% suffixes = [repmat({'i'}, 1, 20)];
suffixes = [repmat({'r'}, 1, 20)];
if TEST_FIRST
    scenePersons = {'f01i'};
    fprintf('[TEST MODE] 仅测试处理: f01i\n');
else
    assert(numel(new_names)==numel(suffixes), ...
        'new_names 与 suffixes 长度必须相同');
    scenePersons = cell(size(new_names));
    for k = 1:numel(new_names)
        scenePersons{k} = [new_names{k}, suffixes{k}];
    end
end

srcRootBase = fullfile('D:','work','secondYearMaster','thesis','reference',...
                       'appeal','datasets','toMax');
if TEST_FIRST
    dstRoot = fullfile('D:','work','secondYearMaster','thesis','reference',...
                   'appeal','algorithms','preference_evaluate','deepskin','data','toMax',"TEST_FIRST");
else
    dstRoot = fullfile('D:','work','secondYearMaster','thesis','reference',...
                   'appeal','algorithms','preference_evaluate','deepskin','data','toMax');
end
% faceMinSize  = [15 15];
faceMinSize  = [80 80];
centerMargin = 0.15;
% centerMargin = 0.5;

% 人脸检测器策略: 依次尝试default、lbp、cart三种方法
% 如果多个检测器都检测到人脸，选择最接近w=97,h=97的bbox

%% ====================== 检查计算机视觉工具箱可用性 ======================
hasCV = license('test','Computer_Vision_Toolbox') && exist('vision.CascadeObjectDetector','class');
if ~hasCV
    warning('未检测到 Computer Vision Toolbox，将全程使用中心裁剪');
end

%% ====================== 创建输出目录 ======================
outGt = fullfile(dstRoot,'gt');
if ~exist(outGt, 'dir'), mkdir(outGt); end

xlsxPath = fullfile(outGt, 'toMax_gt.xlsx');
allCenters = struct();   % 汇总所有 scenePerson 的 group centers

%% ====================== 循环处理每个 scenePerson ======================
% for spIdx = 1:1
for spIdx = numel(scenePersons):-1:1
    scenePerson = scenePersons{spIdx};
    fprintf('\n%s\n', repmat('=',1,60));
    fprintf('[场景 %d/%d] %s\n', spIdx, numel(scenePersons), scenePerson);
    fprintf('%s\n', repmat('=',1,60));

    srcRoot = fullfile(srcRootBase, scenePerson);
    if ~exist(srcRoot, 'dir')
        warning('目录不存在，跳过: %s', srcRoot);
        continue;
    end

    drawableDir = fullfile(srcRoot, 'drawable');
    matDir      = fullfile(srcRoot, 'non_model','01Preference','labNscore');
    ellipDir    = fullfile(srcRoot, 'non_model','01Preference','ellipPara');

    outFace   = fullfile(dstRoot,'rendered_face',scenePerson);
    outUv     = fullfile(dstRoot,'rendered_face_uv',scenePerson);
    outGlobal = fullfile(dstRoot,'rendered_2max',scenePerson);

    for d = {outFace, outUv, outGlobal}
        if ~exist(d{1}, 'dir'), mkdir(d{1}); end
    end

    %% ---------- 加载 ellipPara ----------
    ellipPath = fullfile(ellipDir, 'fitRes.mat');
    if ~exist(ellipPath, 'file')
        warning('fitRes.mat 不存在，跳过 %s: %s', scenePerson, ellipPath);
        continue;
    end
    ellipData = load(ellipPath);
    par_all = ellipData.par_all;
    fprintf('[INFO] fitRes.mat loaded, par_all size = %s\n', mat2str(size(par_all)));

    %% ---------- 扫描图片并分组 ----------
    jpgFiles = dir(fullfile(drawableDir, [scenePerson '*.jpg']));
    groupMap = containers.Map('KeyType','char','ValueType','any');

    for k = 1:length(jpgFiles)
        name = jpgFiles(k).name;
        % 例: f01ih3k_01.jpg  -> group=h3k, idx=01
        pat = ['^' scenePerson '([a-zA-Z0-9]+)_(\d{2})\.jpg$'];
        tokens = regexp(name, pat, 'tokens');
        if isempty(tokens), continue; end
        grp = lower(tokens{1}{1});
        idx = str2double(tokens{1}{2});
        if ~isKey(groupMap, grp)
            groupMap(grp) = {};
        end
        lst = groupMap(grp);
        lst{end+1} = struct('name',name,'idx',idx,...
                            'path',fullfile(drawableDir,name));
        groupMap(grp) = lst;
    end

    groupNames = sort(keys(groupMap));
    fprintf('[INFO] 发现 %d 个 image group: %s\n', length(groupNames), strjoin(groupNames,', '));

    %% ---------- 逐 group 处理 ----------
    allRecords = cell(0,5);     % {original_name, score, L, a, b}
    personCenters = struct();

    for g = 1:length(groupNames)
        grp = groupNames{g};
        lst = groupMap(grp);
        idxs = cellfun(@(x)x.idx, lst);
        [~,ord] = sort(idxs);
        lst = lst(ord);

        % ---- 加载 labNscore ----
        matName = sprintf('labNscore_group%s%s.mat', scenePerson, grp);
        matPath = fullfile(matDir, matName);
        if ~exist(matPath,'file')
            warning('跳过 group %s: 找不到 %s', grp, matPath);
            continue;
        end
        m = load(matPath);

        p_group = m.p_group;
        lab_group = m.lab_group;
        average_bf = m.average_bf;

        p_group = p_group(:);
        if size(lab_group,1) == 3 && size(lab_group,2) ~= 3
            lab_group = lab_group';
        end

        nMat = numel(p_group);
        nImg = numel(lst);
        nUse = min(nMat, nImg);
        if nMat ~= nImg
            warning('group %s: mat样本数(%d) ~= 图片数(%d)，使用前%d个', grp, nMat, nImg, nUse);
        end

        % ---- center L,a,b ----
        if isfield(m,'average_bf') && ~isempty(average_bf)
            centerL = double(average_bf(1));
        else
            centerL = 50.0;
        end

        nParRows = size(par_all,1);
        if nParRows == 1
            parRow = 1;
        elseif nParRows >= g
            parRow = g;
        else
            parRow = 1;
        end
        centerA = double(par_all(parRow, 4));
        centerB = double(par_all(parRow, 5));
        center_pre=[centerL,centerA,centerB];
        personCenters.(grp) = struct('L',centerL,'a',centerA,'b',centerB);

        fprintf('\n[处理 group] %s: %d 张 | center L=%.3f a=%.3f b=%.3f\n', grp, nUse, centerL, centerA, centerB);

        % ---- 逐张处理图片 ----
        for i = 1:nUse
            item = lst{i};
            originalName = item.name(1:end-4);
            
            % 检查文件是否已经处理过
            facePath = fullfile(outFace, [originalName '_face.jpg']);
            uvPath = fullfile(outUv, [originalName '_face_uv.npy']);
            globalPath = fullfile(outGlobal, [originalName '.jpg']);
            
            if fileAlreadyProcessed(facePath, uvPath, globalPath)
                fprintf('  [跳过] %s: 文件已处理\n', originalName);
                % 仍然需要添加到GT记录
                allRecords(end+1,:) = {originalName, ...
                                       double(p_group(i)), ...
                                       double(center_pre(1)), ...
                                       double(center_pre(2)), ...
                                       double(center_pre(3))};
                continue;
            end
            
            img = imread(item.path);

            % 人脸检测 - 多检测器策略
            faceMinSize = [80 80];
            
            % 定义目标尺寸
            target_w = 97;
            target_h = 97;
            
            if mean(mean(mean(img)))<20
                img_used=img*2;
            else
                img_used=img;
            end
            
            % 检查计算机视觉工具箱可用性
            hasCV = license('test','Computer_Vision_Toolbox') && exist('vision.CascadeObjectDetector','class');
            all_bboxes = [];
            
            if hasCV
                % 方法1: default检测器
                try
                    det1 = vision.CascadeObjectDetector();
                    det1.MinSize = faceMinSize;
                    bboxes1 = det1(img_used);
                    if ~isempty(bboxes1)
                        all_bboxes = [all_bboxes; bboxes1];
                    end
                catch
                    fprintf('  [警告] %s: default检测器失败\n', originalName);
                end
                
                % 方法2: LBP检测器
                try
                    det2 = vision.CascadeObjectDetector('FrontalFaceLBP');
                    det2.MinSize = faceMinSize;
                    bboxes2 = det2(img_used);
                    if ~isempty(bboxes2)
                        all_bboxes = [all_bboxes; bboxes2];
                    end
                catch
                    fprintf('  [警告] %s: LBP检测器失败\n', originalName);
                end
                
                % 方法3: CART检测器
                try
                    det3 = vision.CascadeObjectDetector('FrontalFaceCART');
                    det3.MinSize = faceMinSize;
                    bboxes3 = det3(img_used);
                    if ~isempty(bboxes3)
                        all_bboxes = [all_bboxes; bboxes3];
                    end
                catch
                    fprintf('  [警告] %s: CART检测器失败\n', originalName);
                end
            else
                % 没有计算机视觉工具箱，使用中心裁剪作为备选方案
                [h,w,~] = size(img_used);
                centerMargin = 0.15;
                x1 = round(w*centerMargin);
                y1 = round(h*centerMargin);
                x2 = round(w*(1-centerMargin));
                y2 = round(h*(1-centerMargin));
                center_bbox = [x1, y1, x2-x1, y2-y1];
                all_bboxes = [all_bboxes; center_bbox];
            end
            
            % 如果所有检测器都检测不到人脸，使用中心裁剪作为最后手段
            if isempty(all_bboxes)
                fprintf('  [警告] %s: 检测失败，使用中心裁剪\n', originalName);
                [h,w,~] = size(img_used);
                centerMargin = 0.15;
                x1 = round(w*centerMargin);
                y1 = round(h*centerMargin);
                x2 = round(w*(1-centerMargin));
                y2 = round(h*(1-centerMargin));
                center_bbox = [x1, y1, x2-x1, y2-y1];
                all_bboxes = [all_bboxes; center_bbox];
            end

            % 选择最接近目标尺寸的bbox
            if isempty(all_bboxes)
                fprintf('  [跳过] %s: 无法生成有效的边界框\n', originalName);
                continue;
            end

            avg_values = mean(all_bboxes(:, [3, 4]), 2);
            diff_from_tar = abs(avg_values - 500);
            [~, min_idx] = min(diff_from_tar);
            best_bbox = all_bboxes(min_idx, :);

            % 检查bbox有效性
            if ~isValidBbox(best_bbox, size(img))
                fprintf('  [跳过] %s: 无效的边界框 [%d %d %d %d]\n', originalName, ...
                    round(best_bbox(1)), round(best_bbox(2)), round(best_bbox(3)), round(best_bbox(4)));
                continue;
            end


            % 使用最佳bbox裁剪人脸 - 添加边界检查
            try
                y1 = max(1, round(best_bbox(2)));
                y2 = min(size(img,1), round(best_bbox(2) + best_bbox(4) - 1));
                x1 = max(1, round(best_bbox(1)));
                x2 = min(size(img,2), round(best_bbox(1) + best_bbox(3) - 1));

                if y2 <= y1 || x2 <= x1
                    fprintf('  [跳过] %s: 边界框坐标无效\n', originalName);
                    continue;
                end

                faceRgb = img(y1:y2, x1:x2, :);
            catch ME
                fprintf('  [跳过] %s: 裁剪失败 - %s\n', originalName, ME.message);
                continue;
            end

            % imshow(faceRgb)
            % 保存 global (原图)
            imwrite(img, fullfile(outGlobal, [originalName '.jpg']));

            % 保存 face
            % imshow(faceRgb)
            imwrite(faceRgb, fullfile(outFace, [originalName '_face.jpg']));

            % 生成并保存 UV
            uv = generateFaceUv(faceRgb);
            writeNpy(fullfile(outUv, [originalName '_face_uv.npy']), uv);

            % GT 记录
            allRecords(end+1,:) = {originalName, ...
                                   double(p_group(i)), ...
                                   double(center_pre(1)), ...
                                   double(center_pre(2)), ...
                                   double(center_pre(3))};

            if mod(i,10)==0 || i==nUse
                fprintf('  %s 完成 (%d/%d)\n', originalName, i, nUse);
            end
        end
    end

    %% ---------- 保存当前 scenePerson 的 Excel GT ----------
    if ~isempty(allRecords)
        T = cell2table(allRecords, 'VariableNames', {'original_name','preference_score','L*','a*','b*'});

        % 尝试写入Excel，如果失败则保存为CSV备份
        try
            writetable(T, xlsxPath, 'Sheet', scenePerson);
            fprintf('\n[INFO] Excel GT 已写入: %s (sheet: %s), 共 %d 条\n', xlsxPath, scenePerson, height(T));
        catch ME
            warning('无法写入Excel文件 (可能被占用): %s', ME.message);
            csvPath = fullfile(outGt, sprintf('toMax_gt_%s.csv', scenePerson));
            writetable(T, csvPath);
            fprintf('\n[INFO] 已保存为CSV备份: %s, 共 %d 条\n', csvPath, height(T));
        end
    else
        warning('场景 %s 没有生成任何 GT 记录', scenePerson);
    end

    % 汇总 centers
    allCenters.(scenePerson) = personCenters;
end

%% ====================== 保存所有 group center 摘要 ======================
centerPath = fullfile(outGt, 'toMax_group_centers.mat');
save(centerPath, '-struct', 'allCenters');
fprintf('\n[INFO] 所有 Group centers 已保存: %s\n', centerPath);

%% ====================== 打印摘要 ======================
fprintf('\n%s\n', repmat('=',1,60));
fprintf('全部处理完成! 共处理 %d 个场景\n', numel(scenePersons));
fprintf('输出根目录: %s\n', dstRoot);
fprintf('GT Excel  : %s\n', xlsxPath);
fprintf('\n下一步:\n');
fprintf('  修改 facial_preference/config.py 中的路径:\n');
fprintf('    FACE_RGB_ROOT    = r"%s"\n', fullfile(dstRoot,'rendered_face'));
fprintf('    FACE_UV_ROOT     = r"%s"\n', fullfile(dstRoot,'rendered_face_uv'));
fprintf('    GLOBAL_RGB_ROOT  = r"%s"\n', fullfile(dstRoot,'rendered_2max'));
fprintf('    GT_EXCEL_PATH    = r"%s"\n', xlsxPath);
fprintf('%s\n', repmat('=',1,60));

%% ========================================================================
% 局部函数 (Local Functions)
%% ========================================================================

function bbox = detectFace(detector, img, margin)
    %DETECTFACE 检测人脸并返回 bbox [x,y,w,h]；失败则回退中心裁剪
    bbox = [];
    if ~isempty(detector)
        try
            bbox = detector(img);
        catch
            bbox = [];
        end
    end
    if isempty(bbox)
        [h,w,~] = size(img);
        x1 = round(w*margin);
        y1 = round(h*margin);
        x2 = round(w*(1-margin));
        y2 = round(h*(1-margin));
        bbox = [x1, y1, x2-x1, y2-y1];
    else
        bbox = bbox(1,:);
    end
end

function uv = generateFaceUv(faceRgb)
    faceRgb = im2double(faceRgb);

    % sRGB -> linear RGB
    lin = faceRgb;
    mask = lin <= 0.04045;
    lin(mask)  = lin(mask) / 12.92;
    lin(~mask) = ((lin(~mask) + 0.055) / 1.055) .^ 2.4;

    % linear RGB -> XYZ (D65)
    M = [0.4124564, 0.3575761, 0.1804375;
         0.2126729, 0.7151522, 0.0721750;
         0.0193339, 0.1191920, 0.9503041];
    s = size(lin);
    rgbLin = reshape(lin, [], 3)';
    xyz = M * rgbLin;
    xyz = reshape(xyz', s);

    X = xyz(:,:,1); Y = xyz(:,:,2); Z = xyz(:,:,3);

    % XYZ -> CIE L*u*v*
    Xn = 0.95047; Yn = 1.00000; Zn = 1.08883;
    eps = 1e-6;

    denom = X + 15*Y + 3*Z + eps;
    up = 4*X ./ denom;
    vp = 9*Y ./ denom;

    un = 4*Xn / (Xn + 15*Yn + 3*Zn);
    vn = 9*Yn / (Xn + 15*Yn + 3*Zn);

    yr = Y / Yn;
    L = zeros(size(Y));
    maskL = yr > 0.008856;
    L(maskL) = 116 * yr(maskL).^(1/3) - 16;
    L(~maskL) = 903.3 * yr(~maskL);

    u = 13 * L .* (up - un);
    v = 13 * L .* (vp - vn);

    uv = single(cat(3, u, v));
    uv = permute(uv, [3,1,2]);
end

function writeNpy(filename, data)
    fid = fopen(filename, 'wb');
    if fid == -1
        error('无法创建文件: %s', filename);
    end

    fwrite(fid, [0x93, 'NUMPY'], 'uchar');
    fwrite(fid, uint8([1, 0]), 'uint8');

    switch class(data)
        case 'single',  dtype = '<f4';
        case 'double',  dtype = '<f8';
        case 'int32',   dtype = '<i4';
        case 'int64',   dtype = '<i8';
        case 'uint8',   dtype = '|u1';
        otherwise
            fclose(fid);
            error('不支持的数组类型: %s', class(data));
    end

    sz = size(data);
    shapeStr = sprintf('%d,', sz);
    shapeStr = shapeStr(1:end-1);

    header = sprintf('{''descr'': ''%s'', ''fortran_order'': True, ''shape'': (%s), }', dtype, shapeStr);

    pad = 16 - mod(10 + numel(header), 16);
    if pad == 16, pad = 0; end
    header = [header, repmat(' ',1,pad)];

    fwrite(fid, uint16(numel(header)), 'uint16', 'l');
    fwrite(fid, header, 'char');
    fwrite(fid, data, class(data));
    fclose(fid);
end

function valid = isValidBbox(bbox, imgSize)
    %ISVALIDBBOX 检查边界框是否有效
    %   bbox: [x, y, width, height]
    %   imgSize: [height, width, channels] 或 [height, width]
    
    valid = false;
    if numel(bbox) ~= 4
        return;
    end
    
    x = bbox(1);
    y = bbox(2);
    w = bbox(3);
    h = bbox(4);
    
    % 检查边界框尺寸是否为正数
    if w <= 0 || h <= 0
        return;
    end
    
    % 检查边界框是否在图像范围内
    if x < 1 || y < 1 || (x + w - 1) > imgSize(2) || (y + h - 1) > imgSize(1)
        return;
    end
    
    % 检查边界框是否过大（超过图像尺寸的80%）
    if w > imgSize(2) * 0.8 || h > imgSize(1) * 0.8
        return;
    end
    
    valid = true;
end

function exists = fileAlreadyProcessed(facePath, uvPath, globalPath)
    %FILEALREADYPROCESSED 检查文件是否已经处理过
    %   检查所有三个输出文件是否存在且大小合理
    
    exists = false;
    
    % 检查人脸图片是否存在且大小合适
    if exist(facePath, 'file') && exist(uvPath, 'file') && exist(globalPath, 'file')
        try
            % 所有文件都存在，视为已处理
            exists = true;
        catch
            % 如果读取失败，视为未处理
            exists = false;
        end
    end
end
