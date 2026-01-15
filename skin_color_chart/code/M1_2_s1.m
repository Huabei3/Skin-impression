% % uniform select in lab space
 clear;clc;close all;
load("lab_data.mat","lab_all","lab_pre");
attr_type="pre";
%load lab_r.mat;%全部
if strcmp(attr_type,"all")
    attr_serial="2";
    lab1=lab_all;             %only preference
elseif strcmp(attr_type,"pre")
    attr_serial="1";
    lab1=lab_pre;
end
% save_folder=fullfile("res",attr_type,"adjusted");
% if ~exist(save_folder,"dir")
%     mkdir(save_folder);
% end
save_folder=fullfile("res",attr_type,"adjusted");
if ~exist(save_folder,"dir")
    mkdir(save_folder);
end
%load labp.mat
%lab1=labp;la
lch1 = lab1;
lch1(:, 2: 3) = ab2Ch(lch1(:, 2: 3));
 idremove = [];
% idremove = union(find(lab1(:, 2) > 25), find(lab1(:, 3) > 25));  % a或b大于25的都去掉
% idremove = union(idremove, find(lab1(:, 1) < 25));  % 去掉黑色
% idremove = union(idremove, find(lab1(:, 1) > 76));  % 去掉太亮的
% idremove = union(idremove, find(lab1(:, 3) < 1));  % 去掉灰色lab_pre
lab2 = lab1; 
%refl2 = reflAll; 
lch2 = lch1;
%refl2(:, idremove) = []; 
%lab2(idremove, :) = []; lch2(idremove, :) = [];

%Lrange = [30 40 43 46  48:70 72 75];
 Lrange =25: 5: 75;
 % Lrange =30: 5: 75;
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

ti = {'\textit{a*-b*}', '\textit{a*-L*}', '\textit{b*-L*}'};
idp = [2, 3; 2, 1; 3, 1];
la = {'\textit{a*}', '\textit{b*}';...
    '\textit{a*}', '\textit{L*}';...
    '\textit{b*}', '\textit{L*}'};


xg = cell(1, 3);
xg{1} = 10: 5: 90;
xg{2} = 0: 5: 30;
xg{3} = 0: 5: 30;

Lset = Lrange(1) : Lrange(end);

figure(1)
for i = 1: 3
    subplot(1, 3, i)
    hold on
    plot(lab1(idremove, idp(i, 1)), lab1(idremove, idp(i, 2)), '.', 'color', [0.5 0.5 1])
    plot(lab2(idr, idp(i, 1)), lab2(idr, idp(i, 2)), '.', 'color', [0.5 0.5 1])
    x = lab_clean(:, idp(i, 1));
    y = lab_clean(:, idp(i, 2));
    plot(x, y, '.', 'color', [1 0.5 0.5], 'MarkerSize', 4)

    % title(ti{i})
    % xlabel(la{i, 1});
    % ylabel(la{i, 2});
    xlabel(la{i, 1}, 'Interpreter', 'latex', 'FontSize', 12*2);
    ylabel(la{i, 2}, 'Interpreter', 'latex', 'FontSize', 12*2);
    title(ti{i},'Interpreter', 'latex','FontSize', 12*2);
    grid on
    axis equal;
    set(gca,'xtick', xg{idp(i, 1)});
    set(gca,'ytick', xg{idp(i, 2)});
    set(gca, 'FontSize', 13)
    xlim([xg{idp(i, 1)}(1), xg{idp(i, 1)}(end)])
    ylim([xg{idp(i, 2)}(1), xg{idp(i, 2)}(end)])
    xticks(xg{idp(i,1)}(1):10: xg{idp(i,1)}(end))
    yticks(xg{idp(i,2)}(1):10: xg{idp(i,2)}(end))
end

%% 

idselect = [];
stepL=5;
step =5;
minD0=2.5;

Lc = 20:stepL:90;
dL = stepL/2;
h2=figure(2);
% manual_points = [
%     87.63964366	15.94019195	18.31095266;
%     83.99327184	19.17783588	28.84937534
% ];%全部时手动加上的点
% manual_points = [
% 87.6396436600000	17.1953698000000	20.6547042600000;
% 22.69174444	4.641793188	9.226150897;
% 22.69174444	4.280355409	6.906400343;
% 
% ];%仅有preference时手动加上的点

manual_points = [
87.6396436600000	17.1953698000000	20.6547042600000;
22.69174444	4.641793188	9.226150897;
22.69174444	4.280355409	6.906400343;

];%仅有preference时手动加上的点
% manual_points = [];

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
    xlabel(la{1,1}, 'Interpreter', 'latex');
    ylabel(la{1,2}, 'Interpreter', 'latex');
    grid on
    axis equal;
    
    % 设置坐标轴刻度和范围

    set(gca,'xtick', xg{idp(1,1)});
    set(gca,'ytick', xg{idp(1,2)});
    set(gca, 'FontSize', 5)
    xlim([xg{idp(1,1)}(1), xg{idp(1,1)}(end)])
    ylim([xg{idp(1,2)}(1), xg{idp(1,2)}(end)])
    xticks(xg{idp(1,1)}(1):10: xg{idp(1,1)}(end))
    yticks(xg{idp(1,2)}(1):10: xg{idp(1,2)}(end))
    
    title(strcat('\textit{L*} = ', num2str(L)), 'Interpreter', 'latex')
    
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
    plot(t(idt,2), t(idt,3), 'k*','MarkerSize', 3)

    % 保存索引
    idselect = [idselect; p(idt)];                
    dL = stepL/2;  % 切片半宽
    if ~isempty(manual_points)
    mask_manual = (manual_points(:,1) >= L - dL) & (manual_points(:,1) < L + dL);
    manual_in_slice = manual_points(mask_manual, :);

    % 如果有手动点在当前切片
    if ~isempty(manual_in_slice)
        % 绘制手动点，使用不同符号或颜色
        plot(manual_in_slice(:,2), manual_in_slice(:,3), 'k*','Color','r','MarkerSize', 3)
    end
    end
end
if ~isempty(manual_points)
    row_idx = find(ismember(lab_clean, manual_points, 'rows'));

    % 加入 idselect
    idselect = [idselect; row_idx];
end
saveFolder=fullfile("res","adjusted","lab_selected_from_low");
if ~exist(saveFolder,"dir")
    mkdir(saveFolder);
end
exportgraphics(h2,fullfile(saveFolder, ...
    strcat("lab_selected_from_low",attr_serial,".jpg")),"Resolution",150);
concatenate_images1(saveFolder,4);

h3=figure(3);

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
    % plot(t(:,2), t(:,3), '.')             % 原始点
    plot(t(idx,2), t(idx,3), 'k*','MarkerSize', 3)        % 已选择的星号点
    xlabel(la{1,1}, 'Interpreter', 'latex');
    ylabel(la{1,2}, 'Interpreter', 'latex');
    grid on
    axis equal
    xlim([xg{idp(1,1)}(1), xg{idp(1,1)}(end)])
    ylim([xg{idp(1,2)}(1), xg{idp(1,2)}(end)])

    set(gca, 'FontSize', 10)
    title(strcat('\textit{L*} = ', num2str(L)), 'Interpreter', 'latex')
end
saveFolder=fullfile("res","adjusted","lab_selected_from_high");
if ~exist(saveFolder,"dir")
    mkdir(saveFolder);
end

exportgraphics(h3,fullfile(saveFolder, ...
    strcat("lab_selected_from_high",attr_serial,".jpg")),"Resolution",150);
concatenate_images1(saveFolder,4);
%% 



labs = lab_clean(idselect, :);
  h1=figure(1);
  for i = 1: 3
      subplot(1, 3, i)
      hold on
      plot(labs(:, idp(i, 1)), labs(:, idp(i, 2)), 'k*','MarkerSize', 3)

  end
saveFolder=fullfile("res","adjusted","show_lab_selected");
if ~exist(saveFolder,"dir")
    mkdir(saveFolder);
end

exportgraphics(h1,fullfile(saveFolder,strcat("show_lab_selected",attr_serial,".jpg")),"Resolution",150);
concatenate_images1(saveFolder,4);
  % save(fullfile(save_folder,"lab_selected.mat"),"idselect","labs","lab1");
