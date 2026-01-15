clc;clear;
source_folder ="D:\work\VIVOskinExpe\calibResults\TCL";
% source_folder ="D:\work\VIVOskinExpe\3D MODEL\calibResults\NO4";
dir_phones=dir(fullfile(source_folder,"*.mat"));
figure();
for i_phone=1:length(dir_phones)
    source_file =fullfile(dir_phones(i_phone).folder,dir_phones(i_phone).name);
    shalashes=find(dir_phones(i_phone).name=='_');
    serial(i_phone,1)=str2double(dir_phones(i_phone).name(end));
    % serial(i_phone,1)=str2double(dir_phones(i_phone).name(shalashes(4)+1:shalashes(5)-1));
end

[serial_sorted,index] = sortrows(serial,1,'ascend');

for i_phone=1:length(dir_phones)
    source_file =fullfile(dir_phones(i_phone).folder,dir_phones(i_phone).name);

    SPDname = 380:1:780; SPDname = SPDname';
    DATAs=load(source_file);
    DATAs=DATAs.DATAs;
    DATAs(1,:) = [];
    SPD = reshape(cell2mat(DATAs(:,4)), 401, 20);
    XYZ10 = spd2xyz([SPDname SPD], 10);
    xyz=XYZ10;
    xyz_all(:,i_phone)=xyz(:,2);
    xyz_all_sorted(:,index(i_phone))=xyz(:,2);

    CCT = zeros(20, 1);
    
    [CCT_out,duv_out,S_out] = xyz2CCT(xyz(:, 1:3),10);
    % [CCT_out,duv_out,S_out] = XYZ2CCT(xyz(:, 1:3));
    
    x = 5:5:100;
    % hold on 
    % plot(x, CCT_out, '-.');
    % plot(x, CCT_out0, '-.');
    % axis([5, 100, 6500, 7800])
    % xlabel('Brightness(%)')
    % ylabel('CCT(K)')
    % line([0, 100], [7400, 7400], linewidth=1, color='k')
    
    
    hold on 
    plot(x, xyz(:,2), '.');
    
    axis([5, 100, 0, 1000])
    xlabel('Brightness(%)')
    ylabel('Luminance(cd/m^2)')
    % line([0, 1000], [7400, 7400], linewidth=1, color='k')
    % legend('small', 'large', Location='southeast')
    
    
    % Gamma拟合
    ft = fittype('a*x^b + c'); % Gamma函数形式
    options = fitoptions('Method', 'NonlinearLeastSquares', 'StartPoint', [1, 1, 0]);
    
    % 拟合xyz数据
    [fitresult, gof] = fit(x', xyz(:,2), ft, options);
    
    
    
    % 手动生成拟合曲线
    x_fit = linspace(min(x), max(x), 100);
    y_fit = feval(fitresult, x_fit);
    
    
    % 绘制拟合结果
    plot(x_fit, y_fit, '--', 'DisplayName', 'small fit');
    
    
    % 设置图形属性
    axis([5, 100, 0, 1000]);
    xlabel('Brightness(%)');
    ylabel('Luminance(cd/m^2)');
    % legend('show', 'Location', 'southeast');
    
    % 显示拟合参数
    disp('Gamma Fit Parameters for Small:');
    disp(fitresult);
    
    
    
    % hold off;
    
    % 计算Luminance = 200时的Brightness percentage
    target_luminance = 350;
    
    % 定义小尺寸显示屏亮度与百分比的关系函数
    small_fit_func = @(b) fitresult.a * b^fitresult.b + fitresult.c - target_luminance;
    
    % 使用fzero寻找使亮度为200的Brightness percentage
    brightness(i_phone,1) = fzero(small_fit_func, [min(x), max(x)]);
end


% 显示结果
% fprintf('Brightness percentage for small screen at Luminance = 200: %.2f%%\n', brightness);
