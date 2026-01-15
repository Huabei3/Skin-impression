% uniform select in lab space
clear;
close all;
range = (400 :10 : 700)';

load reflskinDJI.mat;
Name = {'China Data', 'Global Data 1', 'Spain Data', 'Thailand Data', ...
    'Iraq Data', 'Pakistan Data', 'Global Data 2', 'ALL'};
reflAll(:, [4036 5643 6040 6218]) = [];  % NAN
reflskin{end + 1} = [range, reflAll];

% load reflselect_uLAB_v6.mat;
% load reflect_minDE_v2.mat;
% load reflselect_uLAB30_v4.mat;
% reflselect(:, [1 3 5 12 32 36 34 37]) = [];
% load reflselect_uLAB30_v5.mat;
load reflect_uLAB30_minDE.mat;

load refl_pantoneSkin.mat;

load D65.mat;
D65 = find_spd(D65, range);
spddata = D65;
load cie1931xyz.mat;
XYZw = refl2xyz([range, ones(length(range), 1)], spddata, cie1931xyz1nm, range);
labselect = xyz2lab(refl2xyz([range, reflselect], spddata, cie1931xyz1nm, range)', 'user', XYZw);
lchselect = labselect;
lchselect(:, 2:3) = ab2Ch(lchselect(:, 2:3));

%% 删除异常值
lab1 = xyz2lab(refl2xyz(reflskin{8}, spddata, cie1931xyz1nm, range)', 'user', XYZw);
lch1 = lab1;
lch1(:, 2: 3) = ab2Ch(lch1(:, 2: 3));
idremove = [];
idremove = union(find(lab1(:, 2) > 20), find(lab1(:, 3) > 25));  % a或b大于25的都去掉
idremove = union(idremove, find(lab1(:, 1) < 29));  % 去掉黑色
idremove = union(idremove, find(lab1(:, 1) > 76));  % 去掉太亮的
idremove = union(idremove, find(lab1(:, 3) < 1));  % 去掉灰色
lab2 = lab1; refl2 = reflAll; lch2 = lch1;
refl2(:, idremove) = []; lab2(idremove, :) = []; lch2(idremove, :) = [];

Lrange = [30 40 43 46  48:70 72 75];
idr = [];
perc = [10 90];
% perc = [2.5 97.5];
for i = 1: length(Lrange) - 1
    p = intersect(find(lab2(:, 1) > Lrange(i)), find(lab2(:, 1) <= Lrange(i + 1)));
    tmp = lab2(p, :);
    [~, TFrm] = rmoutliers(lab2(p, 2), "percentiles", perc);  % a
    id1 = find(TFrm == 1);
    [~, TFrm] = rmoutliers(lab2(p, 3), "percentiles", perc);  % b
    id2 = find(TFrm == 1);
%     [~, TFrm] = rmoutliers(lch2(p, 3), "percentiles", perc);  % h
%     id3 = find(TFrm == 1);
    idr = [idr; p(id1); p(id2)];
%     if (i == 6) return;
%     end
end

lab_clean = lab2; reflclean = refl2; lch_clean = lch2; 
lab_clean(idr, :) = []; reflclean(:, idr) = []; lch_clean(idr, :) = [];

[type1_clean, ITA1_clean] = ITA(lab_clean);
% [type1, ITA1] = ITA(lab1);
for t = 1: 6
    numAll_clean(t) = length(find(type1_clean == t));
end

ti = {'a*b*', 'a*L*', 'b*L*'};
idp = [2, 3; 2, 1; 3, 1];
la = {'a*', 'b*';'a*', 'L*';'b*', 'L*'};

xg = cell(1, 3);
% xg{1} = 10: 5: 90;
xg{1} = 25: 5: 80;
xg{2} = 0: 5: 30;
xg{3} = 0: 5: 30;

Lset = Lrange(1) : Lrange(end);

figure
for i = 1: 3
    subplot(1, 3, i)
    hold on
%     plot(lab1(idremove, idp(i, 1)), lab1(idremove, idp(i, 2)), 'b.')
%     plot(lab2(idr, idp(i, 1)), lab2(idr, idp(i, 2)), 'b.')
    x = lab2(:, idp(i, 1));
    y = lab2(:, idp(i, 2));
    plot(x, y, '.', 'color', [0.6 0.7 1], 'MarkerSize', 4)

    if i == 3
        x = 0: 0.1: 45;
        the = pi / 180 * [-30 10 28 41 55];
        center = [0, 50];
        for h = 1: length(the)
            k = tan(the(h));
            y = center(2) + k * x;
            plot(x, y, 'k--')
        end
    end

    plot(labselect(:, idp(i, 1)), labselect(:, idp(i, 2)), 'k*')

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
set(gcf, 'Position', [100,341,1058,562])


%% CL
figure
subplot(121)
hold on
plot(lch2(:, 2), lch2(:, 1), '.', 'color', [0.6 0.7 1], 'MarkerSize', 5)
plot(lchselect(:, 2), lchselect(:, 1), 'k*')
title('C* - L*')
xlabel('C*');
ylabel('L*');
legend('skin samples', 'selected samples')
grid on
axis equal;
set(gca,'xtick', 5: 5: 35);
set(gca,'ytick', xg{1});
set(gca, 'FontSize', 13)
xlim([5, 35])
ylim([xg{1}(1), xg{1}(end)])
% set(gcf, 'Position', [775,175,511,775])

%% HL
subplot(122)
hold on
plot(lch2(:, 3), lch2(:, 1), '.', 'color', [0.6 0.7 1], 'MarkerSize', 5)
plot(lchselect(:, 3), lchselect(:, 1), 'k*')
title('hue - L*')
xlabel('hue');
ylabel('L*');
grid on
axis equal;
set(gca,'xtick', 35: 5: 80);
set(gca,'ytick', xg{1});
set(gca, 'FontSize', 13)
xlim([35 80])
ylim([xg{1}(1), xg{1}(end)])
% set(gcf, 'Position', [775,175,511,775])
set(gcf, 'Position', [160,327,902,586])

%% ITA
[type1, ITA1] = ITA(labselect);
for t = 1: 6
    numselect(t) = length(find(type1 == t));
end


% k = round(numAll / 100);
% k(k == 0) = 1;
k = [5 10 10 10 10 5];

idselect = [];

dL1 = 0.5;
dL = 2.5;
Lc = 30: 5: 75;
figure
for i = 1: length(Lc)
    L = Lc(i);
    p = intersect(find(lab2(:, 1) >= L - dL1), find(lab2(:, 1) < L + dL1));
    t = lab2(p, :);
    subplot(2, 5, i)
    hold on
    plot(t(:, 2), t(:, 3), '.', 'color', [0.6 0.7 1], 'MarkerSize',8)
    xlabel(la{1, 1});
    ylabel(la{1, 2});
    grid on
    axis equal;
    set(gca,'xtick', xg{idp(1, 1)});
    set(gca,'ytick', xg{idp(1, 2)});
    set(gca, 'FontSize', 13)
    xlim([xg{idp(1, 1)}(1), xg{idp(1, 1)}(end)])
    ylim([xg{idp(1, 2)}(1), xg{idp(1, 2)}(end)])
%     title(['L* = ', num2str(L), ' ± 2.5'])
%     title(['L* = ', num2str(L)])
    title(['L* = ', num2str(L)],'FontName', 'consolas', 'FontWeight','bold', 'FontSize',18)
    %% selected ones
    ps = intersect(find(labselect(:, 1) >= L - dL), find(labselect(:, 1) < L + dL));
    ts = labselect(ps, :);

    plot(ts(:, 2), ts(:, 3), 'k*')

    if i == 1
        legend("skin samples", 'selected samples','FontName', 'consolas', 'fontsize',15)
    end

end
set(gcf, 'Position', [100,240,1765,663])
% exportgraphics(gcf,'figure3.emf','Resolution',300)   % 没有白边 emf


figure
plot(range, reflselect)
ylim([0 1])


%% comp with pantone
figure
for i = 1: 3
    subplot(1, 3, i)
    hold on
    x = lab2(:, idp(i, 1));
    y = lab2(:, idp(i, 2));
    plot(x, y, '.', 'color', [0.6 1 1], 'MarkerSize', 4)

    if i == 3
        x = 0: 0.1: 45;
        the = pi / 180 * [-30 10 28 41 55];
        center = [0, 50];
        for h = 1: length(the)
            k = tan(the(h));
            y = center(2) + k * x;
            plot(x, y, 'k--')
        end
    end
    plot(labpt(:, idp(i, 1)), labpt(:, idp(i, 2)), 'm.', 'MarkerSize', 10)
    plot(labselect(:, idp(i, 1)), labselect(:, idp(i, 2)), 'k.', 'MarkerSize', 10)
    if (i == 2)
        legend('', 'Pantone skin', 'Selected ones')
    end
    
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

