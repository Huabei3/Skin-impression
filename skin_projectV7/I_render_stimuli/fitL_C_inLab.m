clc;clear;close all;
%%
output_folder="pmcc\under21light";
load(fullfile(output_folder,"PMCCunder21light.mat"),"lab_PMCC");
for i_type=1:length(lab_PMCC)
    labCh_PMCC{i_type,1}=[lab_PMCC{i_type,1},...
        sqrt(lab_PMCC{i_type,1}(:,2).^2+lab_PMCC{i_type,1}(:,3).^2),...
        atan2d(lab_PMCC{i_type,1}(:,3),lab_PMCC{i_type,1}(:,2))];
end

for i_type=1:length(lab_PMCC)
    figure();
    C=labCh_PMCC{i_type,1}([7,14,21],4);
    L=labCh_PMCC{i_type,1}([7,14,21],1);
    hold on;
    scatter(C,L, 40, '+','LineWidth', 1); 

    
    
    %拟合直线
        xdata = C(:);
        ydata = L;
        
        f = @(a,xdata)(a(1).*xdata+a(2));
       
        rmax = 0;
    
        for t = 1:500
            a0 = [rand,rand];
            options = optimset('MaxFunEvals',200000);
            a = lsqcurvefit(f,a0,xdata,ydata,[-inf,-inf],[inf,inf],options);
            y = a(1).*xdata+a(2);
       
            r = corr(y,ydata);
            if r >= rmax
                rmax = r;
                afinal = a;
            end
        end
        r_LC_pmcc(i_type,:)=rmax;
        a_LC_pmcc(i_type,:) = afinal;
    
    %45°
    axis equal;
    
    %画拟合直线
    x = 0:0.1:30;
    y= a_LC_pmcc(i_type,1)*x+a_LC_pmcc(i_type,2);
    
    plot(x,y,'LineStyle','-');
    
    %-------------
    
    xlabel('C_{ab}*','FontAngle','italic');
    ylabel('L*','FontAngle', 'italic');
    title('L*-C_{ab}*','FontAngle', 'italic');

    output_folder="pmcc\fitL_C_inLab";
    if ~exist(output_folder,"dir")
        mkdir(output_folder);
    end
    saveas(gcf,fullfile(output_folder,strcat(num2str(i_type),'.jpg')));
end
%%
%计算labCh_pre
load(fullfile("aveSkinByHand","i","aveLab20models.mat"),"ave_lab_mat","lab_cell","picname_check");

for i_type=1:length(lab_PMCC)
    for i_ct=1:length(lab_PMCC{1,1})

        C_PMCC_pre{i_type,1}(i_ct,1)=(ave_lab_mat(i_ct,1)-a_LC_pmcc(i_type,2))./a_LC_pmcc(i_type,1);
        lab_PMCC_pre{i_type,1}(i_ct,:)=[ave_lab_mat(i_ct,1),...
            lab_PMCC{i_type,1}(i_ct,2)./labCh_PMCC{i_type,1}(i_ct,4).*C_PMCC_pre{i_type,1}(i_ct,1),...
            lab_PMCC{i_type,1}(i_ct,3)./labCh_PMCC{i_type,1}(i_ct,4).*C_PMCC_pre{i_type,1}(i_ct,1)];
    end
end
output_folder="pmcc\under21light";
if ~exist(output_folder,"dir")
    mkdir(output_folder);
end
save(fullfile(output_folder,"PMCCunder21light.mat"),"lab_PMCC_pre","lab_PMCC","a_LC_pmcc");

A=labCh_PMCC{2,1}(:,1)>ave_lab_mat(:,1);
B=labCh_PMCC{2,1}(:,4)>C_PMCC_pre{2,1};