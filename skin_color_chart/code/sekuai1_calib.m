clear;clear;close all;
% load labps.mat
%% 
attr_type="all";

%load lab_r.mat;%全部
data_folder=fullfile("res",attr_type);
load(fullfile(data_folder,"lab_selected.mat"),"idselect","labs","lab1");
lab=labs;
lab = lab(end:-1:1, :);  % 行反转
% lab=lab([1:12,end-11:end],:);
data_file="document";
% file_name=fullfile(data_file,"1009_1.csv");
file_name=fullfile(data_file,"SAV_1_1.csv");
T = readtable(file_name);
% Convert the table to a double array, selecting columns 8, 9, and 10
lab_temp = table2array(T(:, 12:14)); 
lab_mea1=lab_temp(2:end,:);
file_name=fullfile(data_file,"SAV_1_2.csv");
T = readtable(file_name);
% Convert the table to a double array, selecting columns 8, 9, and 10
lab_temp = table2array(T(:, 12:14)); 
lab_mea1=[lab_mea1;lab_temp(2:end,:)];


data_file="document";
% file_name=fullfile(data_file,"1009_1.csv");
file_name=fullfile(data_file,"SAV_2_1.csv");
T = readtable(file_name);
% Convert the table to a double array, selecting columns 8, 9, and 10
lab_temp = table2array(T(:, 12:14)); 
lab_mea2=lab_temp(2:end,:);
file_name=fullfile(data_file,"SAV_2_2.csv");
T = readtable(file_name);
% Convert the table to a double array, selecting columns 8, 9, and 10
lab_temp = table2array(T(:, 12:14)); 
lab_mea2=[lab_mea2;lab_temp(2:end,:)];

% dE1=deltaE2000(lab,lab_mea1);
% dE1=dE1';
% [delch1(:,1),delch1(:,2),delch1(:,3),delch1(:,4)]=cielabde(lab,lab_mea1);
% delch1(:,5:7)=lab;
% delch1(:,8:10)=lab_mea1;
% dE1_mean=mean(dE1);
% 
% dE2=deltaE2000(lab,lab_mea2);
% dE2=dE2';
% [delch2(:,1),delch2(:,2),delch2(:,3),delch2(:,4)]=cielabde(lab,lab_mea2);
% delch2(:,5:7)=lab;
% delch2(:,8:10)=lab_mea2;
% dE2_mean=mean(dE2);
% 
% XYZ_theo=lab2xyz(lab,"d65_64");
% RGB_theo=xyz2srgb(XYZ_theo);
% XYZ_mea1=lab2xyz(lab_mea1,"d65_64");
% 
% RGB_mea1=xyz2srgb(XYZ_mea1);
% XYZ_mea2=lab2xyz(lab_mea2,"d65_64");
% RGB_mea2=xyz2srgb(XYZ_mea2);
% 
% RGB1=[RGB_theo,RGB_mea1,dE1];
% RGB2=[RGB_theo,RGB_mea2,dE2];

%% 多元多项式回归 - 3维输入到3维输出
% 假设 X (n×3)，Y (n×3)


%% ====== Step 1. 输入数据 ======
% 示例数据（请替换为你的实际数据）
n = 100;
X = lab_mea1;     % 输入数据示例（范围 [-1,1]）
Y = lab;  % 输出示例

%% ====== Step 2. 设置多项式阶数 ======
polyOrder = 3;   % 可修改为 1, 2, 3, 4 等

%% ====== Step 3. 生成多项式特征矩阵 ======
% 使用 polyexpand 函数（下面定义）
Phi = polyexpand(X, polyOrder);

%% ====== Step 4. 对每个输出通道进行回归 ======
coef = cell(1,3);
Y_pred = zeros(size(Y));

for i = 1:3
    % 最小二乘解
    coef{i} = Phi \ Y(:,i);
    % 预测
    Y_pred(:,i) = Phi * coef{i};
end

dE=deltaE2000(Y,Y_pred);
dE_mean=mean(dE)
%%
lab_2print = zeros(size(lab));

for i = 1:3
    % 最小二乘解
    coef{i} = Phi \ lab(:,i);
    % 预测
    lab_2print(:,i) = Phi * coef{i};
end

%% ====== Step 7. 定义多项式展开函数 ======
function Phi = polyexpand(X, order)
    % 输入: X 为 n×3 矩阵
    % 输出: Phi 为 n×m 多项式特征矩阵
    n = size(X,1);
    Phi = ones(n,1);  % 常数项

    for i = 1:order
        combs = nchoosek(repmat(1:3,1,i), i); % 生成组合（含重复项）
        combs = unique(sort(combs,2),'rows');
        for j = 1:size(combs,1)
            term = ones(n,1);
            for k = 1:i
                term = term .* X(:,combs(j,k));
            end
            Phi = [Phi term];
        end
    end
end
A=[lab,lab_mea1,lab_2print];

%% 准备数据和表头
% % 定义表头
% headers = {'编号', 'dE', 'dL', 'dC', 'dH', ...
%            'Lab_L', 'Lab_a', 'Lab_b', ...  % lab的三个分量
%            'Lab_mea_L', 'Lab_mea_a', 'Lab_mea_b', ...  % lab_mea的三个分量
%            'deltaE2000'};
% headers_RGB = {'编号', 'R_theo', 'G_theo', 'B_theo', 'R_mea', ...
%            'G_mea', 'B_mea',  ...  % lab_mea的三个分量
%            'deltaE2000'};
% % 获取样本数量
% n_samples = size(delch1, 1);
% 
% % 生成编号列（1到n_samples）
% ids = (1:n_samples)';
% 
% % 为delch1和delch2添加编号列和deltaE2000列
% delch1_all = [ids, delch1(:,1:4), delch1(:,5:7), delch1(:,8:10), dE1];
% delch2_all = [ids, delch2(:,1:4), delch2(:,5:7), delch2(:,8:10), dE2];
% delch1_all(end+1,:)=mean(delch1_all,1);
% delch2_all(end+1,:)=mean(delch2_all,1);
% 
% % 将均值行的编号改为'mean'
% delch1_all(end, 1) = NaN;  % 先设为NaN，后续替换为字符串
% delch2_all(end, 1) = NaN;
% 
% RGB1=[ids,RGB1];
% RGB2=[ids,RGB2];
% RGB1(end+1,:)=mean(RGB1,1);
% RGB2(end+1,:)=mean(RGB2,1);
% RGB1(end, 1) = NaN;  % 先设为NaN，后续替换为字符串
% RGB2(end, 1) = NaN;
% 
% 
% output_file = fullfile(data_folder,'lab_measurements_1001_1.xlsx');
% 
% % 写入第一个sheet (delch1)
% % 先写入表头
% writecell(headers, output_file, 'Sheet', 'delch1', 'Range', 'A1');
% % 写入数据（不包括表头）
% writematrix(delch1_all, output_file, 'Sheet', 'delch1', 'Range', 'A2');
% % 将最后一行的编号改为'mean'
% writecell({'mean'}, output_file, 'Sheet', 'delch1', 'Range', sprintf('A%d', n_samples+2));
% 
% % 写入第二个sheet (delch2)
% writecell(headers, output_file, 'Sheet', 'delch2', 'Range', 'A1');
% writematrix(delch2_all, output_file, 'Sheet', 'delch2', 'Range', 'A2');
% writecell({'mean'}, output_file, 'Sheet', 'delch2', 'Range', sprintf('A%d', n_samples+2));
% 
% 
% 
% writecell(headers_RGB, output_file, 'Sheet', 'RGB1', 'Range', 'A1');
% writematrix(RGB1, output_file, 'Sheet', 'RGB1', 'Range', 'A2');
% writecell({'mean'}, output_file, 'Sheet', 'RGB1', 'Range', sprintf('A%d', n_samples+2));
% writecell(headers_RGB, output_file, 'Sheet', 'RGB2', 'Range', 'A1');
% writematrix(RGB2, output_file, 'Sheet', 'RGB2', 'Range', 'A2');
% writecell({'mean'}, output_file, 'Sheet', 'RGB2', 'Range', sprintf('A%d', n_samples+2));
% % 显示完成信息
% fprintf('数据已成功导出到 %s\n', output_file);
% fprintf('delch1的平均deltaE2000: %.4f\n', dE1_mean);
% fprintf('delch2的平均deltaE2000: %.4f\n', dE2_mean);
%%
% attr_type="all";
% 
% %load lab_r.mat;%全部
% data_folder=fullfile("res",attr_type);
% load(fullfile(data_folder,"lab_selected.mat"),"idselect","labs","lab1");
% lab=labs;
% lab = lab(end:-1:1, :);  % 行反转
% data_file="document";
% % file_name=fullfile(data_file,"small_aperture.csv");
% % T = readtable(file_name);
% % % Convert the table to a double array, selecting columns 8, 9, and 10
% % lab_mea = table2array(T(:, 12:14)); 
% % lab_mea(1,:)=[];
% 
% 
% file_name=fullfile(data_file,"small_aperture2.csv");
% T = readtable(file_name);
% % Convert the table to a double array, selecting columns 8, 9, and 10
% lab_mea2 = table2array(T(:, 12:14)); 
% lab_mea2(1,:)=[];
% 
% 
% % lab_light_dark=[lab(1:12,:);lab(end-11:end,:)];
% % dE=deltaE2000(lab_light_dark,lab_mea);
% % dE=dE';
% % [delch(:,1),delch(:,2),delch(:,3),delch(:,4)]=cielabde(lab_light_dark,lab_mea);
% % delch(:,5:7)=lab_light_dark;
% % delch(:,8:10)=lab_mea;
% % dE1=mean(dE(1:12,:));
% % dE2=mean(dE(13:24,:));
% % dE_1=dE(1:12,:);
% % dE_1(11,:)=[];
% % dE1_del=mean(dE_1);
% % delch_light=delch(1:12,:);
% % delch_mean(1,:)=mean(delch_light,1);
% % delch_dark=delch(13:24,:);
% % delch_mean(2,:)=mean(delch_dark,1);
% 
% lab_light_dark=[lab(1:12,:);lab(end-11:end,:)];
% dE=deltaE2000(lab_light_dark,lab_mea2);
% dE=dE';
% [delch2(:,1),delch2(:,2),delch2(:,3),delch2(:,4)]=cielabde(lab_light_dark,lab_mea2);
% delch2(:,5:7)=lab_light_dark;
% delch2(:,8:10)=lab_mea2;
% % delch2(:,11:13)=lab_mea;
% dE1=mean(dE(1:12,:));
% dE2=mean(dE(13:24,:));
% dE_1=dE(1:12,:);
% dE_1(11,:)=[];
% dE1_del=mean(dE_1);
% delch_light2=delch2(1:12,:);
% delch_mean(3,:)=mean(delch_light2,1);
% delch_dark2=delch2(13:24,:);
% delch_mean(4,:)=mean(delch_dark2,1);