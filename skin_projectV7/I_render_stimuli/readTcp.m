clc;clear;close all;
%%
%读取光源信息
%-----------
% % %20240718
% filename = 'light_r\20240718_rspd.xlsx';
% n_model=4;
% model_name=["male07","male22","male28","maleVIVO"];
% pmcc_serial=[1,4,4,2];

%-----------
% % 20240719
% filename = 'light_r\20240719_rspd.xlsx';
% n_model=4;
% model_name=["female06","male21","female25","female23"];
% pmcc_serial=[1,3,4,3];
%-----------
% % % % 20240722
% filename = 'light_r\20240722_rspd.xlsx';
% n_model=4;
% model_name=["male39","male59","female36","femaleVIVO"];
% pmcc_serial=[2,1,2,2];
%-----------
%20240723
% filename = 'light_r\20240723_rspd.xlsx';
% n_model=5;
% model_name=["female04","female01","female41","female51","male46"];
% pmcc_serial=[1,1,2,3,3];

% %-----------
% % % % %20240724
% filename = 'light_r\20240724_rspd.xlsx';
% n_model=2;
% model_name=["male59","female69"];
% pmcc_serial=[2,4];
%-----------

% %-----------
% % % % %20241127
% filename = 'light_r\20241127_rspd.xlsx';
% n_model=4;
% model_name=["female69","female78","male92","male97"];
% pmcc_serial=[4,2,1,1];
%-----------
%%
% Excel 文件路径

% 获取所有工作表名称
[~, sheetNames] = xlsfinfo(filename);

% 遍历每个工作表
for i_scene = 1:length(sheetNames)
    % 读取当前工作表
    data{i_scene,1} = readtable(filename, 'Sheet', sheetNames{i_scene});
    data{i_scene,2}=sheetNames{i_scene};
    % 删除空列
    data{i_scene,1} = removeEmptyColumns(data{i_scene,1});

end

for i_scene=1:length(data)
    secene_name{i_scene,1}=data{i_scene,2};
    lightdata=data{i_scene,1};
    unit_col=floor(size(lightdata,2)/n_model);
    %提取目标行
    for i_row = 1:height(data)
        % 检查当前行是否包含 'Tcp[K](JIS)(0)'
        if strcmp(lightdata{i_row, 1}, 'Tcp[K](JIS)(0)')
            targetRow = i_row; % 保存目标行
            break; % 找到后退出循环
        end
    end

    for i_model=1:n_model
        col_start=(i_model-1)*unit_col+2;
        col_end=(i_model)*unit_col;
        Tcp_temp=[];
        for i_col=col_start:2:col_end
            tcp=lightdata{targetRow,i_col};
            Tcp_temp=[Tcp_temp;tcp];
        end
        inds_Tcp_front(i_scene,i_model)=lightdata{targetRow,col_start};
        inds_Tcp_mean(i_scene,i_model)=mean(Tcp_temp);
    end
end

%保存模特数据
model_name_check=[];
for i_model=1:n_model
    model_tcp_front=inds_Tcp_front(:,i_model);
    model_tcp_mean=inds_Tcp_mean(:,i_model);
    save(strcat("light_r\model_tcp\",model_name(i_model),".mat"), ...
        "model_tcp_front","model_tcp_mean","secene_name");
end



% 删除空列的函数
function data = removeEmptyColumns(data)
    % 获取所有列
    columns = data.Properties.VariableNames;

    % 遍历每列，检查是否为空
    for col = length(columns):-1:1
        if all(ismissing(data.(columns{col})))
            data.(columns{col}) = []; % 删除空列
        end
    end
end