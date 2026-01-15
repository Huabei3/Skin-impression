clear;clc;close all;
%%


% 
% models{1,1}=["male92","male97","male48","female01","female04","female06"];
% models{2,1}=["male59","male39","maleVIVO","female78","female41","femaleVIVO"];
% models{3,1}=["male21","male46","female23","female51"];
% models{4,1}=["male22","male28","female25","female69"];
models{1,1}=["m01","m02","m03","f01","f02","f03"];
models{2,1}=["m04","m05","m06","f04","f05","f06"];
models{3,1}=["m07","m08","f07","f08"];
models{4,1}=["m09","m10","f09","f10"];
types=["Caucasian","Oriental","South Asian","African"];


% a_LC=[4.459300459802465,-47.488828958697376];

ave_folder="aveSkinByHand2";
lab_cell_all=[];picname_check_all=[];labC_HD65_all=[];
for i_type=3:4

    picname_check=[];
    lab_sum=zeros(21,3);
    for i_model=1:length(models{i_type,1})    
        model_new=gen_lastPart_new(models{i_type,1}(i_model));
        file_ave=fullfile(ave_folder,strcat(model_new,'i'),"autoNhand_scaleoverLUT.mat");
        picname_check{i_model,1}=model_new;
        ave_data=load(file_ave);
        lab_sum=lab_sum+ave_data.average_lab_all;
    end
    lab_ave=lab_sum./length(models{i_type,1});
    disp("d")

save(fullfile("aveSkinByHand2","i",strcat("aveLab_",num2str(i_type),".mat")), ...
    "lab_ave","picname_check");
end
% save(fullfile("aveSkinByHand2","i","aveLab_4types_D65.mat"), ...
%     "labC_HD65_all","lab_cell_all","picname_check_all","lab_data");


disp("d")

%%
%CL curve
for i_type=3:4
    load(fullfile("aveSkinByHand2","i",strcat("aveLab_",num2str(i_type),".mat")), ...
    "lab_ave","picname_check");
    L=lab_ave([7,14,21],1);
    figure();
    hold on;
    C_all=sqrt(lab_ave([7,14,21],2).^2+lab_ave([7,14,21],3).^2);
    
    scatter(L,C_all, 40, 'filled'); 
    
    %拟合直线
        xdata = L;
        ydata = C_all(:);
    
        f = @(a,xdata)(a(1).*log(xdata)+a(2));
    
        rmax = 0;
    
        for t = 1:500
            a0 = [rand,rand];
            options = optimset('MaxFunEvals',200000);
            a = lsqcurvefit(f,a0,xdata,ydata,[-inf,-inf],[inf,inf],options);
            y = a(1).*log(xdata)+a(2);
    
            r = corr(y,ydata);
            if r >= rmax
                rmax = r;
                afinal = a;
            end
        end
        r_CL=rmax;
        a_CL = afinal;
    
    axis equal;
    max_lim=max(L(:))+10;
    
    %画拟合直线
    x = 0:0.1:max_lim;
    y= a_CL(1)*log(x)+a_CL(2);
    y1=8.4412*log(x)-10.859;
    y2=6.7421*log(x)-9.9816;%亮度实验
    y3=5.648268903337794*log(x)-7.382104283246091;
    % [5.648268903337794,-7.382104283246091]
    plot(x,y,"Color","r");
    % plot(x,y1,"Color","b");
    plot(x,y2,"Color","g");
    % plot(x,y3,"Color","m");
    
    
    %设置坐标
    
    % ax = gca; ax.XLim = [0 max_lim];
    % ay = gca; ay.YLim = [0 20];
    xlabel('L_{ab}*','FontAngle','italic');
    ylabel('C*','FontAngle', 'italic');
    title('C*-L_{ab}*','FontAngle', 'italic');
    
    output_folder=fullfile("aveSkinByHand2","i","ellip_pic");
    if ~exist(output_folder,"dir")
        mkdir(output_folder);
    end 

    exportgraphics(gcf,fullfile(output_folder, ...
        strcat(num2str(i_type),'C_L.jpg')),"Resolution",150);
    output_folder=fullfile("aveSkinByHand2","i","C_Lpara");
    if ~exist(output_folder,"dir")
        mkdir(output_folder);
    end 
    % save(fullfile(output_folder,strcat(num2str(i_type),'C_L_para.mat')), ...
    %     "a_CL");
end


%%
i_type=4;

picname_check=[];
lab_sum=zeros(21,3);
figure();
hold on;
for i_model=1:length(models{i_type,1})    
    model_new=gen_lastPart_new(models{i_type,1}(i_model));
    file_ave=fullfile(ave_folder,strcat(model_new,'i'),"autoNhand_scaleoverLUT.mat");
    ave_data=load(file_ave);
    ave_data=ave_data.average_lab_all;

    L=ave_data([7,14,21],1);
    C=sqrt(ave_data([7,14,21],2).^2+ave_data([7,14,21],3).^2);


    scatter(L,C, 40, 'filled'); 
    
    %拟合直线
        xdata = L;
        ydata = C(:);
    
        f = @(a,xdata)(a(1).*log(xdata)+a(2));
    
        rmax = 0;
    
        for t = 1:500
            a0 = [rand,rand];
            options = optimset('MaxFunEvals',200000);
            a = lsqcurvefit(f,a0,xdata,ydata,[-inf,-inf],[inf,inf],options);
            y = a(1).*log(xdata)+a(2);
    
            r = corr(y,ydata);
            if r >= rmax
                rmax = r;
                afinal = a;
            end
        end
        r_CL=rmax;
        a_CL = afinal;
    
    axis equal;
    max_lim=max(L(:))+10;
    
    %画拟合直线
    x = 0:0.1:max_lim;
    y= a_CL(1)*log(x)+a_CL(2);
    y1=8.4412*log(x)-10.859;
    y2=6.7421*log(x)-9.9816;%亮度实验
    y3=5.648268903337794*log(x)-7.382104283246091;
    % [5.648268903337794,-7.382104283246091]
    plot(x,y,"Color","r");
    % plot(x,y1,"Color","b");
    plot(x,y2,"Color","g");
    % plot(x,y3,"Color","m");
    
    
    %设置坐标
    
    % ax = gca; ax.XLim = [0 max_lim];
    % ay = gca; ay.YLim = [0 20];
    xlabel('L_{ab}*','FontAngle','italic');
    ylabel('C*','FontAngle', 'italic');
    title(strcat('C*-L_{ab}*',num2str(i_type)),'FontAngle', 'italic');
    
    output_folder=fullfile("aveSkinByHand2","i","C_Lpara");
    if ~exist(output_folder,"dir")
        mkdir(output_folder);
    end 
    % save(fullfile(output_folder,strcat(model_new,'C_L_para.mat')), ...
    %     "a_CL");


end
output_folder=fullfile("aveSkinByHand2","i","ellip_pic");
if ~exist(output_folder,"dir")
    mkdir(output_folder);
end 

exportgraphics(gcf,fullfile(output_folder, ...
    strcat(num2str(i_type),'sepaC_L.jpg')),"Resolution",150);
output_folder=fullfile("aveSkinByHand2","i","C_Lpara");

