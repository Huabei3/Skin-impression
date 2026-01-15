% uniform select in lab space
clear;
close all;
range = (400 :10 : 700)';

load reflskinDJI.mat;
Name = {'China Data', 'Global Data 1', 'Spain Data', 'Thailand Data', ...
    'Iraq Data', 'Pakistan Data', 'Global Data 2', 'ALL'};
reflAll(:, [4036 5643 6040 6218]) = [];  % NAN
reflskin{end + 1} = [range, reflAll];

load D65.mat;
D65 = find_spd(D65, range);
spddata = D65;
load cie1931xyz.mat;
XYZw = refl2xyz([range, ones(length(range), 1)], spddata, cie1931xyz1nm, range);

%% 删除异常值

all_lab_data = [];

% 第一步：读取第一个Excel文件 color_chart2_data_i.xlsx 的所有sheet
excel_file_i = 'color_chart2_data_i.xlsx';
% 获取该Excel的所有sheet名称（动态识别，无需手动输入）
[~, sheet_names_i] = xlsfinfo(excel_file_i);

% 循环读取每个sheet的H:J列
for sheet_idx = 1:9
    % 1. 获取当前sheet的名称
    current_sheet = sheet_names_i{sheet_idx};
    data_table = readtable(excel_file_i, ...
                          'Range', 'H:J', ...          % 明确读取H-J列，兼容Excel范围格式
                          'Sheet', current_sheet, ...  % 指定当前要读取的sheet
                          'VariableNamingRule', 'preserve');  % 保留表头名称（如L*、a*、b*）
    
    if ~isnumeric(data_table{1,1})  % 检查第一行第一列是否为非数值（即表头）
        data_table = data_table(2:end, :);  % 删除第一行（表头），从第二行开始保留数据
    end
    
    data_matrix = table2array(data_table);

    if ~isempty(data_matrix)
        all_lab_data = [all_lab_data; data_matrix];
    end
end

excel_file_r = 'color_chart2_data_r.xlsx';
[~, sheet_names_r] = xlsfinfo(excel_file_r);

for sheet_idx = 1:9
    current_sheet = sheet_names_r{sheet_idx};
    
    % 读取H:J列表格
    data_table = readtable(excel_file_r, ...
                          'Range', 'H:J', ...
                          'Sheet', current_sheet, ...
                          'VariableNamingRule', 'preserve');
    
    % 处理表头（无表头则删除此段）
    if ~isnumeric(data_table{1,1})
        data_table = data_table(2:end, :);
    end
    
    % 表格转矩阵并拼接
    data_matrix = table2array(data_table);
    if ~isempty(data_matrix)
        all_lab_data = [all_lab_data; data_matrix];
    end
end

%% 最终得到原始拼接数据（未剔除NaN），与原代码的lab1_ori对应
lab1_ori = all_lab_data;

% （可选）验证读取结果：输出数据尺寸，确认是否正确
fprintf('读取的总数据：%d行 × %d列（L*/a*/b*）\n', size(lab1_ori, 1), size(lab1_ori, 2));

lab1 = lab1_ori(~any(isnan(lab1_ori), 2), :);
% lab1 = xyz2lab(refl2xyz(reflskin{8}, spddata, cie1931xyz1nm, range)', 'user', XYZw);
lch1 = lab1;
lch1(:, 2: 3) = ab2Ch(lch1(:, 2: 3));
idremove = [];
idremove = union(find(lab1(:, 2) > 25), find(lab1(:, 3) > 25));  % a或b大于25的都去掉
idremove = union(idremove, find(lab1(:, 1) < 0));  % 去掉黑色
idremove = union(idremove, find(lab1(:, 1) > 100));  % 去掉太亮的
idremove = union(idremove, find(lab1(:, 3) < 1));  % 去掉灰色
lab2 = lab1; refl2 = reflAll; lch2 = lch1;
% refl2(:, idremove) = []; lab2(idremove, :) = []; lch2(idremove, :) = [];

Lrange = [30 40 43 46  48:70 72 75];
idr = [];
perc = [10 90];
% perc = [5 95];
% perc = [2.5 97.5];
for i = 1: length(Lrange) - 1
    p = intersect(find(lab2(:, 1) > Lrange(i)), find(lab2(:, 1) <= Lrange(i + 1)));
    tmp = lab2(p, :);
    [~, TFrm] = rmoutliers(lab2(p, 2), "percentiles", [0 100]);  % a
    id1 = find(TFrm == 1);
    [~, TFrm] = rmoutliers(lab2(p, 3), "percentiles", [0 100]);  % b
    id2 = find(TFrm == 1);
%     [~, TFrm] = rmoutliers(lch2(p, 3), "percentiles", perc);  % h
%     id3 = find(TFrm == 1);
    idr = [idr; p(id1); p(id2)];
%     if (i == 6) return;
%     end
end

lab_clean = lab2; reflclean = refl2; lch_clean = lch2; 
% lab_clean(idr, :) = []; reflclean(:, idr) = []; lch_clean(idr, :) = [];

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
set(gcf, 'Position', [100,175,1186,775])

figure
for i = 1: 3
    subplot(1, 3, i)
    hold on
    plot(lab1(idremove, idp(i, 1)), lab1(idremove, idp(i, 2)), 'r.')
    plot(lab2(:, idp(i, 1)), lab2(:, idp(i, 2)), '.','color', [0 115 189]/255)
%     title(ti{i})
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
set(gcf, 'Position', [100,175,1186,775])

% LH
figure
hold on
plot(lch1(idremove, 3), lch1(idremove, 1), 'b.')
plot(lch2(idr, 3), lch2(idr, 1), 'b.')
plot(lch_clean(:, 3), lch_clean(:, 1), 'r.', 'MarkerSize', 5)
for i = 20: 10: 90
    plot([i i], [10, 90], 'k')
end 
for j = 10: 10: 90
    plot([10, 90], [j j], 'k')
end
grid on
axis equal;
set(gca,'xtick', 20: 10: 90);
set(gca,'ytick', 10: 10: 90);
xlabel('hue'); ylabel('L*');
legend('reflectance dataset', 'selected 50')
axis([20 90 10 90])
set(gca, 'FontSize', 15)
set(gcf, 'Position', [680,181,776,797])



%% select key part

idselect = [];

dL = 0.5;
Lc = 25: 5: 85;  % 共13个点
figure


for i = 1: length(Lc)
    L = Lc(i);
    p = intersect(find(lab_clean(:, 1) >= L - dL), find(lab_clean(:, 1) <= L + dL));
    t = lab_clean(p, :);
    
    % 关键优化2：调整子图行列数为4行4列（容纳13个点，布局均衡）
    subplot(4, 4, i)  % 4行4列，共16个子图位置，第13个点在(4,1)位置
    
    hold on
    plot(t(:, 2), t(:, 3), '.')
    xlabel(la{1, 1});
    ylabel(la{1, 2});
    grid on
    axis equal;
    set(gca,'xtick', xg{idp(1, 1)});
    set(gca,'ytick', xg{idp(1, 2)});
    set(gca, 'FontSize', 11)  % 可选：若子图放大后字体显小，可适当调大字体（如11→12）
    xlim([xg{idp(1, 1)}(1), xg{idp(1, 1)}(end)])
    ylim([xg{idp(1, 2)}(1), xg{idp(1, 2)}(end)])
    title(['L* = ', num2str(L)], 'FontSize', 12)  % 标题字体也可同步调大
    
    step = 3;
    xrange = 0:step:25;
    yrange = 0:step:25;
    [x, y] = meshgrid(xrange, yrange);
    ab = [x(:), y(:)];
    idt = [];
    for k = 1: size(ab, 1)
        tmp = sqrt(sum((ab(k, :) - t(:, [2 3])).^2, 2));
        [demin, s] = min(tmp);
        if demin < 0.5
            idt = [idt, s];
        end
    end
    plot(t(idt, 2), t(idt, 3), 'k*', 'MarkerSize', 6)  % 可选：放大筛选点的标记（6→8）
    idselect = [idselect, p(idt)'];
end

% 关键优化3：放大图形窗口总尺寸（宽度从1765→2000，高度从663→1200，根据屏幕调整）
% set(gcf, 'Position', [100, 240, 2000, 1200])  % [左偏移 下偏移 宽度 高度]

reflselect = reflclean(:, idselect);

figure
plot(range, reflselect)
ylim([0 1])

% save reflselect_uLAB_v5.mat reflselect

%% plot selected points on whole
xyz = refl2xyz([range, reflselect], spddata, cie1931xyz1nm, range)';
labs = xyz2lab(xyz, 'user', XYZw);
figure(1)
for i = 1: 3
    subplot(1, 3, i)
    hold on
    plot(labs(:, idp(i, 1)), labs(:, idp(i, 2)), 'k*')
end
