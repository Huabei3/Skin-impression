% % uniform select in lab space
 clear;

%load lab_r.mat;%全部
load labp.mat;%only preference
lab1=labp;
%load labp.mat
%lab1=labp;
lch1 = lab1;
lch1(:, 2: 3) = ab2Ch(lch1(:, 2: 3));
 idremove = [];
% idremove = union(find(lab1(:, 2) > 25), find(lab1(:, 3) > 25));  % a或b大于25的都去掉
% idremove = union(idremove, find(lab1(:, 1) < 25));  % 去掉黑色
% idremove = union(idremove, find(lab1(:, 1) > 76));  % 去掉太亮的
% idremove = union(idremove, find(lab1(:, 3) < 1));  % 去掉灰色
lab2 = lab1; 
%refl2 = reflAll; 
lch2 = lch1;
%refl2(:, idremove) = []; 
%lab2(idremove, :) = []; lch2(idremove, :) = [];

%Lrange = [30 40 43 46  48:70 72 75];
 Lrange =30: 5: 75;
 idr = [];
% perc = [10 90];



lab_clean = lab2; 
%reflclean = refl2; 
lch_clean = lch2; 
%lab_clean(idr, :) = [];
%reflclean(:, idr) = [];
%lch_clean(idr, :) = [];

[type1, ITA1] = ITA(lab_clean);
% [type1, ITA1] = ITA(lab1);
for t = 1: 6
    numAll(t) = length(find(type1 == t));
end

ti = {'ab', 'al', 'bl'};
idp = [2, 3; 2, 1; 3, 1];
la = {'a*', 'b*';'a*', 'L*';'b*', 'L*'};

xg = cell(1, 3);
xg{1} = 10: 5: 90;
xg{2} = 0: 5: 30;
xg{3} = 0: 5: 30;

Lset = Lrange(1) : Lrange(end);

figure
for i = 1: 3
    subplot(1, 3, i)
    hold on
    plot(lab1(idremove, idp(i, 1)), lab1(idremove, idp(i, 2)), '.', 'color', [0.5 0.5 1])
    plot(lab2(idr, idp(i, 1)), lab2(idr, idp(i, 2)), '.', 'color', [0.5 0.5 1])
    x = lab_clean(:, idp(i, 1));
    y = lab_clean(:, idp(i, 2));
    plot(x, y, '.', 'color', [1 0.5 0.5], 'MarkerSize', 4)

    title(ti{i})
    xlabel(la{i, 1});
    ylabel(la{i, 2});
    grid on
    axis equal;
    set(gca,'xtick', xg{idp(i, 1)});
    set(gca,'ytick', xg{idp(i, 2)});
    set(gca, 'FontSize', 13)
    xlim([xg{idp(i, 1)}(1), xg{idp(i, 1)}(end)])
    ylim([xg{idp(i, 2)}(1), xg{idp(i, 2)}(end)])
end

%% 

idselect = [];
stepL=5;
step =5;
minD0=2.5;

Lc = 20:stepL:90;
dL = stepL/2;
figure
% manual_points = [
%     87.63964366	15.94019195	18.31095266;
%     83.99327184	19.17783588	28.84937534
% ];%全部时手动加上的点
manual_points = [
87.6396436600000	17.1953698000000	20.6547042600000
];%仅有preference时手动加上的点
for i = 1:length(Lc)
    L = Lc(i);
    
    % 选取 L 范围内的数据
    mask = (lab_clean(:,1) >= L - dL) & (lab_clean(:,1) < L + dL);
    t = lab_clean(mask, :);
    p = find(mask);
    
    % 绘制子图
    subplot(4, 4, i)
    hold on
    plot(t(:,2), t(:,3), '.')
    xlabel(la{1,1});
    ylabel(la{1,2});
    grid on
    axis equal;
    
    % 设置坐标轴刻度和范围
    set(gca,'xtick', xg{idp(1,1)});
    set(gca,'ytick', xg{idp(1,2)});
    set(gca, 'FontSize', 5)
    xlim([xg{idp(1,1)}(1), xg{idp(1,1)}(end)])
    ylim([xg{idp(1,2)}(1), xg{idp(1,2)}(end)])
    
    title(['L* = ', num2str(L)])
    
    % 动态生成网格
    xrange = 0:step:30;
    yrange = 0:step:30;
    [X, Y] = meshgrid(xrange, yrange);
    grid_points = [L*ones(numel(X),1), X(:), Y(:)];
    
    % 向量化距离计算
    D = pdist2(t, grid_points);   % 每行 t 与每列 grid_point 的距离
    [minD, idx] = min(D, [], 1);  % 找每个 grid_point 最近的 t 的索引
    
    % 筛选距离小于minD0 的点
    selected_mask = minD < minD0;
    idt = unique(idx(selected_mask));  % 去重
    % 绘制选中的点
    plot(t(idt,2), t(idt,3), 'k*')

    % 保存索引
    idselect = [idselect; p(idt)];                
    dL = stepL/2;  % 切片半宽
    mask_manual = (manual_points(:,1) >= L - dL) & (manual_points(:,1) < L + dL);
    manual_in_slice = manual_points(mask_manual, :);

    % 如果有手动点在当前切片
    if ~isempty(manual_in_slice)
        % 绘制手动点，使用不同符号或颜色
        plot(manual_in_slice(:,2), manual_in_slice(:,3), 'k*')
    end
end

    row_idx = find(ismember(lab_clean, manual_points, 'rows'));

    % 加入 idselect
    idselect = [idselect; row_idx];



figure

dL2 = 2.5;
Lc2 = 90:-5:20;

for i = 1:length(Lc2)
    L = Lc2(i);
    
    % 找出第一张图中对应 L 的点索引
    p = intersect(find(lab_clean(:, 1) >= L -2.5), find(lab_clean(:, 1) < L + 2.5));
    t = lab_clean(p, :);  % 这些点和第一张图一致
    
    % 对应第一张图选择的星号索引
    [~, idx] = intersect(p, idselect);  % 找到在第一张图中被选中的索引
    
    subplot(4,4,i)
    hold on
    plot(t(:,2), t(:,3), '.')             % 原始点
    plot(t(idx,2), t(idx,3), 'k*')        % 已选择的星号点
    xlabel(la{1,1});
    ylabel(la{1,2});
    grid on
    axis equal
    xlim([xg{idp(1,1)}(1), xg{idp(1,1)}(end)])
    ylim([xg{idp(1,2)}(1), xg{idp(1,2)}(end)])
    set(gca, 'FontSize', 10)
    title(['L* = ', num2str(L)])
end
%% 



labs = lab_clean(idselect, :);
  figure(1)
  for i = 1: 3
      subplot(1, 3, i)
      hold on
      plot(labs(:, idp(i, 1)), labs(:, idp(i, 2)), 'k*')
  end
