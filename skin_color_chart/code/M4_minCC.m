% 替换成同色异谱色，减低CC色差
clear;
close all;
range = (400 :10 : 700)';

load reflskinDJI.mat;
reflAll(:, [4036 5643 6040 6218]) = [];  % NAN
clear reflskin;

load D65.mat;
D65 = find_spd(D65, range);
spddata = D65;
load cie1931xyz.mat;
XYZw = refl2xyz([range, ones(length(range), 1)], spddata, cie1931xyz1nm, range);
labALL = xyz2lab(refl2xyz([range, reflAll], spddata, cie1931xyz1nm, range)', 'user', XYZw);

% load reflselect_uLAB_v6.mat;
load reflselect_uLAB30_v5.mat;
labs = xyz2lab(refl2xyz([range, reflselect], spddata, cie1931xyz1nm, range)', 'user', XYZw);

for i = 1: size(labs, 1)
    lab = labs(i, :);
    de = deltaE(lab, labALL);
    [desort, id] = sort(de);
    idx = find(desort < 0.7);
    replaceID{i} = id(idx);
%     return
end
% return

load SSF_new.mat;
SSFt = find_spd([(380:5:730)', SSF_Finland], range);
load_refl_data;

load Ref100876.mat;
Ref100876 = Ref100876(:,5:35) / 100;
[SetName, SetLocation] = RefInfo100876;
subset = [18 19 20 21 22 23 24 25 9];
refltest = [];
for i = 1: length(subset)
    refltest = [refltest; Ref100876(SetLocation(subset(i),1): SetLocation(subset(i),2),:)];
end
reflval = refltest(1: 2: end, :);  % validation set
reflval = [range, reflval'];
spddata = {D65, A, F11};


%% SA
T=1; %初始化温度值
T_min=1e-6; %设置温度下界
alpha=0.9; %温度的下降率
k=100; %迭代次数
N=length(replaceID);
iter_times=ceil(k*log(T_min/T)/log(alpha));

% x 初始解
for i = 1: length(replaceID)
    x(i) = replaceID{i}(1);
end
fx=get_CCDE(reflAll(:, x), reflval, SSFt, cie1931xyz1nm, spddata, range);
fxmin=fx;
flag = false;
% return
while(T>T_min)
    for I=1:k
%         [T I];
        x_new=x;
        c = randi(N);
        while (length(replaceID{c}) == 1)
            c = randi(N);
        end
        r = randi(length(replaceID{c}));
        x_new(c) = replaceID{c}(r);  % 随机扰动

        fx_new=get_CCDE(reflAll(:, x), reflval, SSFt, cie1931xyz1nm, spddata, range);
        delta=fx_new-fxmin;
        if (delta<0)
            x=x_new;
            fxmin=fx_new
        else
            P=getP(delta,T);
%                 P=-1;
            if(P>rand)
                x=x_new;
                fxmin=fx_new
            end
        end
        if fxmin < 0.16
            flag = true;
            break;
        end
    end
    T=T*alpha;

    if flag
        break;
    end
end
disp('最优解为：')
disp(x)
disp(fxmin)

reflselect = reflAll(:, x);
% save reflect_minDE_v3.mat reflselect;
% save reflect_uLAB30_minDE.mat reflselect;


function p=getP(c,t)
    p=exp(-c/t);
end

function de_mean = get_CCDE(reflselect, refltest, SSFt, cie1931xyz1nm, spddata, range)
    L = length(spddata);
    for light = 1: L
        spd = spddata{light};
        M = getCCMlight(SSFt, cie1931xyz1nm, spd, [range, reflselect], range);
        [de00_mean(light, :), ~, de00_max(light, :)] = ...
            testCCMlight(SSFt, cie1931xyz1nm, spd, refltest, range, M);
    end
    
    de_mean = mean([de00_mean; de00_max / 5]);
end

