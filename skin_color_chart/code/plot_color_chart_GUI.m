% --- 1. 数据加载与预处理 ---
close all; % 关闭所有图窗
clear;     % 清除工作区所有变量

% 定义要处理的两个XLSX文件
the_files = ["color_chart2_data_i.xlsx", "color_chart2_data_r.xlsx"];

% 初始化一个结构体数组来存储所有数据
data_structure = struct('model', {}, 'picname', {}, 'attribute', {}, 'lab', {});
data_idx = 1; % 用于追踪结构体的索引

% 循环处理每个文件
for k = 1:length(the_files)
    file_name = the_files{k};

    % 检查文件是否存在
    if ~exist(file_name, 'file')
        warning('文件未找到: %s。跳过此文件。', file_name);
        continue;
    end

    % 获取当前文件的所有工作表名称
    [~, sheet_names] = xlsfinfo(file_name);

    % 循环处理每个工作表
    for s = 1:length(sheet_names)
        sheet_name = sheet_names{s};

        % 如果工作表名为 "10Ruddy"，则跳过
        if strcmp(sheet_name, "10Ruddy")
            fprintf('跳过工作表: %s\n', sheet_name);
            continue;
        end

        % 从工作表读取数据到表格中
        T = readtable(file_name, 'Sheet', sheet_name);

        % 获取行数
        num_rows = size(T, 1);

        % 循环处理每一行以提取数据
        for r = 1:num_rows
            % 检查L*a*b*列是否有NaN值
            lab_values = table2array(T(r, 8:10));
            if any(isnan(lab_values))
                continue; % 跳过包含NaN的行
            end

            % 从第1列读取model
            model = T{r, 1};
            if iscell(model)
                model = model{1};
            end

            % 从第2列读取picname
            picname = T{r, 2};
            if iscell(picname)
                picname = picname{1};
            end

            % 将数据存储到结构体中
            if ismember(model,["m02r"])&&ismember(picname,["13夜景小卖部门口"])
                continue
            end
            if ismember(model,["f07i","f08i"])&&ismember(picname,["f07ild65","f08ild65"])
                continue
            end
            if ismember(model,["f09r"])&&ismember(picname,["12夕阳草地侧光"])&&ismember(sheet_name,["01Preference","03Feminine"])
                continue
            end
            if ismember(model,["f10r"])&&ismember(picname,["9草地逆光"])
                continue
            end

            data_structure(data_idx).model = model;
            data_structure(data_idx).picname = picname;
            data_structure(data_idx).attribute = sheet_name;
            data_structure(data_idx).lab = lab_values;
            data_idx = data_idx + 1;
        end
    end
end

% 提取所有数据的L*, a*, b*值
all_lab_values = [data_structure.lab]';
L_values = all_lab_values(1:3:end);
a_values = all_lab_values(2:3:end);
b_values = all_lab_values(3:3:end);

% 计算色度 C* = sqrt(a*^2 + b*^2)
C_values = sqrt(a_values.^2 + b_values.^2);

% 检查是否有数据可用于绘图
if isempty(a_values)
    error('没有可用于绘图的数据。请检查文件和工作表。');
end

% --- 2. 绘图 ---

% 创建并绘制第一个图窗：a*-b* 图
h_fig1 = figure(1);
hold on;
scatter(a_values, b_values, 20, 'filled');
title('CIE L*a*b* 色度图 (a*-b*)');
xlabel('a*');
ylabel('b*');
axis equal;
grid on;

% 创建并绘制第二个图窗：L*-C* 图
h_fig2 = figure(2);
hold on;
scatter(C_values, L_values, 20, 'filled');
title('CIE L*a*b* 色度图 (L*-C*)');
xlabel('C*');
ylabel('L*');
grid on;

% --- 3. GUI 和交互功能 ---

% 为第一个图窗（a*-b*）启用数据游标模式
dcm_obj1 = datacursormode(h_fig1);
set(dcm_obj1, 'UpdateFcn', @(hObj, eventObj) custom_data_tip(eventObj, data_structure));

% 为第二个图窗（L*-C*）启用数据游标模式
dcm_obj2 = datacursormode(h_fig2);
set(dcm_obj2, 'UpdateFcn', @(hObj, eventObj) custom_data_tip(eventObj, data_structure));

disp('交互模式已启用。点击任一图中的数据点以查看其详细信息。');

% --- 自定义数据提示函数 ---
% 当点击数据点时，此函数将被调用
function txt = custom_data_tip(eventObj, data_structure)
    % 获取被点击数据点的索引
    data_index = eventObj.DataIndex;

    % 从预填充的结构体中获取数据
    point_data = data_structure(data_index);

    % 格式化数据提示文本
    txt = {
        ['Model: ' char(point_data.model)], ...
        ['Pic Name: ' char(point_data.picname)], ...
        ['Attribute: ' char(point_data.attribute)], ...
        ['L*a*b*: (' num2str(point_data.lab(1), '%.2f') ', ' num2str(point_data.lab(2), '%.2f') ', ' num2str(point_data.lab(3), '%.2f') ')']
    };
end