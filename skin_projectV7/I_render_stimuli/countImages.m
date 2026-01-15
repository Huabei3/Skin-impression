clear;


%% 数文件

folderPath ='F:\VIVOskinExpe\skin_projectV4\evaluation_rendering\render_code\rendered\LUT\non_model\100\drawable\r';

% 获取所有jpg文件
jpgFiles = dir(fullfile(folderPath, '*.JPG'));

% 初始化一个空的容器
fileGroups = containers.Map('KeyType', 'char', 'ValueType', 'any');

% 遍历每个文件
i_33=1;
for i = 1:length(jpgFiles)
    % 获取文件名
    [~, fileName, ~] = fileparts(jpgFiles(i).name);
    %-----check CL关系-----
    slashes=find(fileName=='_');
    serial(i,1)=str2double(fileName(slashes+1:slashes+2));
%     
    % if serial(i,1)==33
    %     slashes1=find(fileName=='[');
    %     slashes2=find(fileName==',');
    %     slashes3=find(fileName==']');
    %     dlab(1,1)=str2double(fileName(slashes1+1:slashes2(1)-1));
    %     dlab(1,2)=str2double(fileName(slashes2(1)+1:slashes2(2)-1));
    %     dlab(1,3)=str2double(fileName(slashes2(2)+1:slashes3-1));
    %     C=sqrt(dlab(1,2).^2+dlab(1,3).^2);
    %     if dlab(1,1)<=60
    %         C_pre=6.7421*log(dlab(1,1))-9.9816;%亮度实验
    %     else
    %         C_pre=6.7421*log(60)-9.9816;%亮度实验
    %     end
    %     dlab_pre=[dlab(1,1),dlab(1,2)./C.*C_pre,dlab(1,3)./C.*C_pre];
    %     CL_check{i_33,1}=deltaE2000(dlab_pre,dlab);
    %     CL_check{i_33,2}=dlab_pre;
    %     CL_check{i_33,3}=dlab;
    %     CL_check{i_33,4}=fileName;
    %     i_33=i_33+1;
    % end
    %-----------
    % 使用正则表达式提取第二个下划线前的内容
    tokens = fileName(1:slashes(1)-1);
    % tokens = regexp(fileName, '^[^_]*', 'match');
    % tokens = regexp(fileName, '^([^_]+_[^_]+)_', 'tokens', 'once');
    if ~isempty(tokens)
        % key = tokens{1};
        key = tokens;
        % 将文件路径添加到对应的组
        if isKey(fileGroups, key)
            fileGroups(key) = [fileGroups(key); {fullfile(folderPath, jpgFiles(i).name)}];
        else
            fileGroups(key) = {fullfile(folderPath, jpgFiles(i).name)};
        end
    end
end

% 转换为cell矩阵
groupKeys = keys(fileGroups);
cellMatrix = cell(length(groupKeys), 2);
for i = 1:length(groupKeys)
    cellMatrix{i, 1} = fileGroups(groupKeys{i});
    cellMatrix{i, 2} = groupKeys{i};
end
disp("done");


