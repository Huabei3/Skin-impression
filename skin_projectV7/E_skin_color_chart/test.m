addpath('..\');
addpath('..\utils\')
load cie1931xyz5nm.mat

%cmfs_data_example = rand(43, 3);  % 你需要替换为实际的CMF数据
range = (360 :10 : 780);
cmfs_data_example =find_spd( cie1931xyz5nm,range);
cmfs_data_example = cmfs_data_example(:, 2:end);
% 加载反射光谱数据库（假设已经存在一个.mat文件）
reflectance_db_path = 'R_Types.mat'; % 替换为你的反射光谱数据库路径

% 创建ReflectancePredictor对象
reflectancePredictor = ReflectancePredictor();

% 加载数据
reflectancePredictor = reflectancePredictor.load_data(cmfs_data_example, reflectance_db_path);

% 2. 准备输入数据进行预测
% 假设目标XYZ为随机生成的示例数据，代表3个样本
% load 108xyz.mat
attr_type="all";

data_folder=fullfile("res",attr_type);
load(fullfile(data_folder,"lab_selected.mat"),"idselect","labs","lab1");
lab=labs;
XYZ=lab2xyz(lab,"d65_64");
XYZ_target_example = XYZ;  % 3个样本的XYZ值，每个样本3个坐标

% 假设自定义光源的参考白点XYZ
XYZ_ref_white_example =[95.047 100.00 108.883];  

% 3. 调用predict_ref方法进行预测
[RefP_out, XYZP_calculated, labP_predicted, m_deP] = reflectancePredictor.predict_ref(XYZ_target_example, 0, XYZ_ref_white_example);

% 4. 显示输出结果
% disp('预测的反射光谱 (RefP_out):');
% disp(RefP_out);
% 
% disp('计算得到的XYZ值 (XYZP_calculated):');
% disp(XYZP_calculated);
% 
% disp('预测的Lab值 (labP_predicted):');
% disp(labP_predicted);
% 
% disp('目标XYZ与预测XYZ的平均色差 (m_deP):');
% disp(m_deP);

%%
wavelengths = 360:10:780;

save_folder=fullfile(data_folder,"spd_pic");
if ~exist(save_folder,"dir")
    mkdir(save_folder);
end
for i = 1:length(XYZ)
% for i = 1:108
    % subplot(6, 12, i); % 创建子图
    figure("Visible","off");
    plot(wavelengths, RefP_out(i, :) / 100,"LineWidth",3); % 绘制每个反射光谱，并将纵坐标除以 100
    %title(['' num2str(i)]); % 为每个子图加上标题
    xlabel('');
    ylabel('');
    ylim([0 1])
    xlim([400 700])
    exportgraphics(gcf,fullfile(save_folder,sprintf("spd%03d.jpg",length(XYZ)-i+1)),"resolution",150);
    close(gcf);
end
concatenate_images1(save_folder,6);
%%
% save_folder="D:\work\secondYearMaster\CIC\documents\" + ...
%     "CIC33-Skin color preference under multi-scene demand_9.15";
% concatenate_images1(save_folder,3)
