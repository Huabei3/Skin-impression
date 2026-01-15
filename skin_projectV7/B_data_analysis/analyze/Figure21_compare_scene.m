close all; % 关闭所有图窗
clc;       % 清空命令窗口
clear;     % 清除工作区所有变量

%%
length_color=4;
hue_values = linspace(0, 1, length_color + 1);hue_values = hue_values(1:end-1);
hsv_matrix = [hue_values', 0.8 * ones(length_color, 1), 0.8 * ones(length_color, 1)];
colors = hsv2rgb(hsv_matrix);
scale_type_origin="unscaled";
scale_type="scaled";
Dtype="efit_p";
lab_cherry=[65.50 	17.21 	17.72 ];
ab_summer=[0 17.9 18.7];
% ab_zeng=[0 19.9 23.0];
ab_zeng=[0 18 21];
ab_zengCIC=[0 21 24];
lab_OPPO=[65.1919   19.0833   23.0048];
PengCIC=[[67,0,0,25.3,46.0];[65,0,0,25.3,46.5];[58,0,0,25.1,46.5];[40,0,0,25.0,46.5]];
PengCIC(:,2)=PengCIC(:,4).*cosd(PengCIC(:,5));
PengCIC(:,3)=PengCIC(:,4).*sind(PengCIC(:,5));

CaoCIC=[[0,0,0,24.5,43.7];[0,0,0,25.4,44.5];[0,0,0,25.7,48.3];[0,0,0,23.0,48.0]];
CaoCIC(:,2)=CaoCIC(:,4).*cosd(CaoCIC(:,5));
CaoCIC(:,3)=CaoCIC(:,4).*sind(CaoCIC(:,5));

Zeng=[[0,18,21];[0,17,16];[0,0,0];[0,21,29]];

scenes_OPPO=[[59.22 0 0	26.81 	46.85] ;%室内
[57.49 0 0	23.66 	46.81] ;%室外
[62.87 0 0	22.02 	42.75];%黄昏
[61.78 0 0	25.84 	49.74]];%夜景
scenes_OPPO(:,2)=scenes_OPPO(:,4).*cosd(scenes_OPPO(:,5));
scenes_OPPO(:,3)=scenes_OPPO(:,4).*sind(scenes_OPPO(:,5));


labCh_PMCC=[[62.11	18.96	19.76	27.39	46.18];...
            [64.15	19.56	19.63	27.71	45.10];...
            [56.01	18.25	18.72	26.14	45.72];...
            [41.06	17.37	17.94	24.97	45.93]];

output_folder=fullfile("ellip_pic_p",Dtype,"compare_scene");

if ~exist(output_folder,"dir")
    mkdir(output_folder);
end

ethnic_names=["Asian","Caucasian","South Asian","African"];
ethnic_groups=["1AS","2CA","3SA","4AF"];
for i_eth=[1]
    figure(i_eth);
    grid on;box on;
    hold on;
    if strcmp(Dtype,"efit_p_free")
        AnalyseResults_folder="AnalyseResults_p_free";
    elseif strcmp(Dtype,"efit_p")
        AnalyseResults_folder="AnalyseResults_p";
    end
    source_folder=fullfile(AnalyseResults_folder, ...
        Dtype,"50",scale_type_origin,"nation1",scale_type, ...
            "non_model\r\01Preference",ethnic_groups(i_eth));
    for i_indices=1:4
        full_path=fullfile(source_folder,strcat(num2str(i_indices),".mat"));
        if ~exist(full_path,"file")
            continue
        end
        fitRes_data = load(full_path); 
        par=fitRes_data.par;
        center(i_eth,:)=[fitRes_data.average_indices_curr(1,1),par(1,4:5)];
        
        check_data2 = par(4) + (-30:0.2:30);
        check_data3 = par(5) + (-30:0.2:30);
        [data2, data3] = meshgrid(check_data2, check_data3);
        [row, col] = size(data2);
        
        % 计算等高线数据
        a = par;
        y = (1./(1+a(6)*exp(sqrt(a(1)*(data2-a(4)).^2+a(2)*(data3-a(5)).^2+ ...
            a(3)*(data2-a(4)).*(data3-a(5)))))).*((a(1)*(data2-a(4)).^2+ ...
            a(2)*(data3-a(5)).^2+a(3)*(data2-a(4)).*(data3-a(5)))>=0);
        
        % 绘制等高线
        s0 = contour(data2, data3, y, [0.5, 1], 'LineWidth', 1, ...
             'Color', colors(i_indices,:));
        hold on;
        % 绘制特殊点
        plot(par(4), par(5), 'o', 'MarkerSize', 4, ...
            'MarkerFaceColor', colors(i_indices,:), 'Color', colors(i_indices,:));
        
        axis equal
        min_lim=-5;
        max_lim=40;
        xlim([min_lim,max_lim])
        ylim([min_lim,max_lim])
        x = linspace(min_lim, max_lim, 1000);
        y = x;
        plot(x, y);
        scatter(scenes_OPPO(i_indices,2), scenes_OPPO(i_indices,3), 20, '^', 'LineWidth', 1, ...
        'MarkerEdgeColor',colors(i_indices,:));
    end
    scatter(labCh_PMCC(1,2), labCh_PMCC(1,3), 20, 's', 'LineWidth', 1, ...
    'MarkerEdgeColor','m','MarkerFaceColor','m');
    title(ethnic_names(i_eth))
    exportgraphics(gcf, fullfile(output_folder, ...
        strcat(ethnic_groups(i_eth),'.jpg')),'resolution',300);

end

concatenate_images1(output_folder,4);
