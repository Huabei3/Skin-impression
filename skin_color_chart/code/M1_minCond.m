% read DJI skin db
clear;
close all;
range = (400 :10 : 700)';

load reflskinDJI.mat;
Name = {'China Data', 'Global Data 1', 'Spain Data', 'Thailand Data', ...
    'Iraq Data', 'Pakistan Data', 'Global Data 2', 'ALL'};
reflskin{end + 1} = [range, reflAll];

%% ITA
load D65.mat;
D65 = find_spd(D65, range);
spddata = D65;
load cie1931xyz.mat;
XYZw = refl2xyz([range, ones(length(range), 1)], spddata, cie1931xyz1nm, range);

%% refl ALL，删除
lab1 = xyz2lab(refl2xyz(reflskin{8}, spddata, cie1931xyz1nm, range)', 'user', XYZw);
[lab1_clean, TFrm] = rmoutliers(lab1, 'grubbs');

ti = {'ab', 'al', 'bl'};
idp = [2, 3; 2, 1; 3, 1];
figure
for i = 1: 3
    subplot(1, 3, i)
    plot(lab1(:, idp(i, 1)), lab1(:, idp(i, 2)), 'g.')
    hold on
    plot(lab1_clean(:, idp(i, 1)), lab1_clean(:, idp(i, 2)), 'r.')
    title(ti{i})
end
set(gcf, 'Position', [50 400 1850 600])


reflclean = reflAll(:, ~TFrm);
[type1, ITA1] = ITA(lab1_clean);
for t = 1: 6
    num(t) = length(find(type1 == t));
end

k = round(num / 100);
for t = 1: 6
    idx = find(type1 == t);
    num(t) = length(idx);
    refl_t = reflclean(:, idx);
    ns = minCondN_skin(refl_t, k(t));
    numSelect{t} = idx(ns);
end

reflselect = [];
figure
for t = 1: 6
    refl = reflclean(:, numSelect{t});
    [~, idr] = sort(mean(refl, 1), 2, "descend");
    refl = refl(:, idr);
    subplot(2, 3, t)
    plot(range, refl)
    ylim([0 1])
    reflselect = [reflselect, refl];
end
figure
plot(range, reflselect)
ylim([0 1])

% save reflselect.mat reflselect
