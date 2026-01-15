% --- 1. 数据加载与预处理 ---
close all; % 关闭所有图窗
clear;     % 清除工作区所有变量
% 加载数据
load("lab_data.mat","lab_all","lab_pre","info_all","info_pre");
attr_type="all";
if strcmp(attr_type,"all")
    lab1 = lab_all;             
    info1 = info_all;
elseif strcmp(attr_type,"pre")
    lab1 = lab_pre;
    info1 = info_pre;
end
% 存储原始数据和索引的结构体
indices_del=[];
data_structure = struct('lab', {}, 'original_index', {}, 'model', {}, 'picname', {}, 'attribute', {});
for idx = 1:size(lab1, 1)
    model_val = info1{idx, 1};
    if ~isempty(model_val) && iscell(model_val)
        model_val = model_val{1,1};  % 处理嵌套单元格
    end
    
    picname_val = info1{idx, 2};
    if ~isempty(picname_val) && iscell(picname_val)
        picname_val = picname_val{1,1};  % 处理嵌套单元格
    end
    
    attribute_val = info1{idx, 3};
    if ~isempty(attribute_val) && iscell(attribute_val)
        attribute_val = attribute_val{1,1};  % 处理嵌套单元格
    end
    % if (strcmp(model_val, 'f03i'))
    %     continue
    % end
    % 统一使用ismember进行判断
    % if (strcmp(model_val, 'f03i') && strcmp(picname_val, 'f03ild65') && strcmp(attribute_val, '03Feminine')) || ...
    %    (strcmp(model_val, 'f10r') && strcmp(picname_val, '9 草地逆光') && (strcmp(attribute_val, '06Healthy') || strcmp(attribute_val, '03Feminine') || strcmp(attribute_val, '08Harmony'))) || ...
    %    (strcmp(model_val, 'f07i') && strcmp(picname_val, 'f07imd65') && strcmp(attribute_val, '01Preference')) || ...
    %    (strcmp(model_val, 'f05i') && strcmp(picname_val, 'f05imd65') && strcmp(attribute_val, '02Attractiveness'))
    %     % indices_del=[indices_del;idx];
    %     model_val, model_val, attribute_val
    %     continue
    % end
        
    % 检查 info1 是否有足够的行
    if idx <= size(info1, 1)
        data_structure(idx).lab = lab1(idx, :);
        data_structure(idx).original_index = idx;
        data_structure(idx).model = info1{idx, 1};
        data_structure(idx).picname = info1{idx, 2};
        data_structure(idx).attribute = info1{idx, 3};
    end
end
save_folder = fullfile("res", attr_type);
if ~exist(save_folder, "dir")
    mkdir(save_folder);
end
lch1 = lab1;
lch1(:, 2: 3) = ab2Ch(lch1(:, 2: 3));
% 假设 idremove 和 idr 经过某些处理后得到
idremove = [];
idr = [];
idremove=find(lab1(:,2)<0);
idremove=[idremove;find(lab1(:,2)<5&lab1(:,1)<48&lab1(:,1)>43)];
lab_clean = lab1; 
lch_clean = lch1; 
% lab_clean(indices_del,:)=[];
% lch_clean(indices_del,:)=[];
[type1, ITA1] = ITA(lab_clean);
for t = 1: 6
    numAll(t) = length(find(type1 == t));
end
ti = {'ab', 'al', 'bl'};
idp = [2, 3; 2, 1; 3, 1];
la = {'a*', 'b*'; 'a*', 'L*'; 'b*', 'L*'};
xg = cell(1, 3);
xg{1} = 10: 5: 90;
xg{2} = 0: 5: 30;
xg{3} = 0: 5: 30;

%% --- 2. 均匀选取点 (Original Logic from second script) ---
idselect = [];
stepL=5;
step =5;
minD0=2.5;
Lc = 20:stepL:90;
dL = stepL/2;
% manual_points 保持不变，请根据需要调整
manual_points = [
    87.6396436600000 17.1953698000000 20.6547042600000
];

% This loop generates the idselect array but doesn't plot anything
for i = length(Lc):length(Lc)
    L = Lc(i);
    mask = (lab_clean(:,1) >= L - dL) & (lab_clean(:,1) < L + dL);
    t = lab_clean(mask, :);
    p = find(mask);
    
    xrange = 0:step:30;
    yrange = 0:step:30;
    [X, Y] = meshgrid(xrange, yrange);
    grid_points = [L*ones(numel(X),1), X(:), Y(:)];
    
    D = pdist2(t, grid_points);   
    [minD, idx] = min(D, [], 1);  
    
    selected_mask = minD < minD0;
    idt = unique(idx(selected_mask));  
    
    idselect = [idselect; p(idt)];                
    
    dL = stepL/2;  
    mask_manual = (manual_points(:,1) >= L - dL) & (manual_points(:,1) < L + dL);
    manual_in_slice = manual_points(mask_manual, :);
end
row_idx = find(ismember(lab_clean, manual_points, 'rows'));
idselect = unique([idselect; row_idx]);
labs = lab_clean(idselect, :);
save(fullfile(save_folder,"lab_selected.mat"),"idselect","labs","lab1");

%% --- 3. 绘图与交互 ---
% 创建并绘制图窗
h_fig1 = figure(1);
for i = 3
    % subplot(1, 3, i)
    hold on
    
    % 绘制所有点，以实现交互功能
    h_scatter_all = plot(lab1(:, idp(i, 1)), lab1(:, idp(i, 2)), '.', 'color', [1 0.5 0.5], 'MarkerSize', 4);
    
    % 绘制选中的点，使用不同的标记进行高亮
    h_scatter_selected = plot(labs(:, idp(i, 1)), labs(:, idp(i, 2)), 'k*', 'MarkerSize', 3);
    
    title(ti{i})
    xlabel(la{i, 1});
    ylabel(la{i, 2});
    grid on
    axis equal;
    set(gca, 'xtick', xg{idp(i, 1)});
    set(gca, 'ytick', xg{idp(i, 2)});
    set(gca, 'FontSize', 13)
    xlim([xg{idp(i, 1)}(1), xg{idp(i, 1)}(end)])
    ylim([xg{idp(i, 2)}(1), xg{idp(i, 2)}(end)])
    xticks(xg{idp(i, 1)}(1):10: xg{idp(i, 1)}(end))
    yticks(xg{idp(i, 2)}(1):10: xg{idp(i, 2)}(end))
end

% 为 figure(1) 启用数据游标模式
dcm_obj1 = datacursormode(h_fig1);
% 确保数据游标绑定到第一个plot对象（h_scatter_all），因为这是包含所有数据的图
set(dcm_obj1, 'UpdateFcn', @(hObj, eventObj) custom_data_tip(eventObj, data_structure));
disp('交互模式已启用。点击图中的数据点以查看其详细信息。');
exportgraphics(h_fig1,fullfile(save_folder,"show_lab_selected.jpg"),"Resolution",150);

% --- 自定义数据提示函数 ---
function txt = custom_data_tip(eventObj, data_structure)
    % 获取被点击数据点的索引
    data_index = eventObj.DataIndex;
    
    % 从预填充的结构体中获取数据
    if data_index <= length(data_structure)
        point_data = data_structure(data_index);
        
        % 格式化数据提示文本
        txt = {
            ['Model: ' char(point_data.model)], ...
            ['Pic Name: ' char(point_data.picname)], ...
            ['Attribute: ' char(point_data.attribute)], ...
            ['L*a*b*: (' num2str(point_data.lab(1), '%.2f') ', ' num2str(point_data.lab(2), '%.2f') ', ' num2str(point_data.lab(3), '%.2f') ')']
        };
    else
        % 处理索引超出范围的情况
        txt = {'Data not found'};
    end
end