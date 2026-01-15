%calculate_rescalingfactors    
disp(sprintf('Calculating metric rescaling parameters ...'))
clear hueintervals rescalingparameters rescalingpars CIERa12 DEavg12_CIERa Ra12 DEavg12_Ra CRI2012Ra12_HL17 DEavg12_CRI2012Ra_HL17 Qa12 Qf12 Qp12 Qg12 DEavg12_CQS Rf12 DEavg12_Rf cpi12 DEavg12_cpi Rm12 Sa12 RmD65 SaD65 RfD65 DEavgD65_Rf cpiD65 DEavgD65_cpi DEavgF4_Ra RaF4 

addpath([cd])

runyes=1;%1: calculate; 0: load previously saved

%set hue intervals
hueintervals=[0 360];

IllB=[380.000000	385.000000	390.000000	395.000000	400.000000	405.000000	410.000000	415.000000	420.000000	425.000000	430.000000	435.000000	440.000000	445.000000	450.000000	455.000000	460.000000	465.000000	470.000000	475.000000	480.000000	485.000000	490.000000	495.000000	500.000000	505.000000	510.000000	515.000000	520.000000	525.000000	530.000000	535.000000	540.000000	545.000000	550.000000	555.000000	560.000000	565.000000	570.000000	575.000000	580.000000	585.000000	590.000000	595.000000	600.000000	605.000000	610.000000	615.000000	620.000000	625.000000	630.000000	635.000000	640.000000	645.000000	650.000000	655.000000	660.000000	665.000000	670.000000	675.000000	680.000000	685.000000	690.000000	695.000000	700.000000	705.000000	710.000000	715.000000	720.000000	725.000000	730.000000	735.000000	740.000000	745.000000	750.000000	755.000000	760.000000	765.000000	770.000000	775.000000	780.000000
22.400000	26.850000	31.300000	36.180000	41.300000	46.620000	52.100000	57.700000	63.200000	68.370000	73.100000	77.310000	80.800000	83.440000	85.400000	86.880000	88.300000	90.080000	92.000000	93.750000	95.200000	96.230000	96.500000	95.710000	94.200000	92.370000	90.700000	89.950000	89.500000	90.430000	92.200000	94.460000	96.900000	99.160000	101.000000	102.200000	102.800000	102.920000	102.600000	101.900000	101.000000	100.070000	99.200000	98.440000	98.000000	98.080000	98.500000	99.060000	99.700000	100.360000	101.000000	101.560000	102.200000	103.050000	103.900000	104.590000	105.000000	105.080000	104.900000	104.550000	103.900000	102.840000	101.600000	100.380000	99.100000	97.700000	96.200000	94.600000	92.900000	91.100000	89.400000	88.000000	86.900000	85.900000	85.200000	84.800000	84.700000	84.900000	85.400000	86.100000	87.000000]';

 %set default (h =[0 360]) rescaling parameters
        rescalingparameters{1}.ciecri=4.6;
        rescalingparameters{1}.cri2012.HL17=1/55;
        rescalingparameters{1}.cqsv9p0.a=3.20;
        rescalingparameters{1}.cqsv9p0.f=3.03;
        rescalingparameters{1}.cqsv9p0.p=3.88;
        rescalingparameters{1}.sandersrp=[0.51813, 0.46730];
        rescalingparameters{1}.juddrf=4.6;
        rescalingparameters{1}.thorntoncpi=7.317;
        rescalingparameters{1}.mcri=[21.7016   4.2106   2.4154];



for hueint_i=1:size(hueintervals,1)
    rescalingparameters{hueint_i}.thetas=hueintervals(hueint_i,:);
    thetas=hueintervals(hueint_i,:);
    
    if hueintervals(hueint_i,1)==1 & hueintervals(hueint_i,2)==360
        %set default (h =[0 360]) rescaling parameters
        rescalingparameters{1}.ciecri=4.6;
        rescalingparameters{1}.cri2012.HL17=1/55;
        rescalingparameters{1}.cqsv9p0.a=3.20;
        rescalingparameters{1}.cqsv9p0.f=3.03;
        rescalingparameters{1}.cqsv9p0.p=3.88;
        rescalingparameters{1}.sandersrp=[0.51139   0.51139];
        rescalingparameters{1}.juddrf=4.6;
        rescalingparameters{1}.thorntoncpi=7.317;
        rescalingparameters{1}.mcri=[21.7016   4.2106   2.4154];
        rescalingparameters{1}.mcri_euc=[21.7016   4.2106   2.4154];;
    else
        %calculate new rescaling parameters
        if runyes==1
            spds=xlsread('F1F12.xlsx');
            for i=1:12;
                spdi=[spds(:,1),spds(:,i+1)];

                %CIE Ra
                [CIERa12{hueint_i}(i),DEavg12_CIERa{hueint_i}(i)]=CIECRI_c(spdi,[0 360],rescalingparameters{1}.ciecri);
                [Ra12{hueint_i}(i),DEavg12_Ra{hueint_i}(i)]=CIECRI_c(spdi,thetas,rescalingparameters{1}.ciecri);

                %CRI2012
                [CRI2012Ra12_HL17{hueint_i}(i),DEavg12_CRI2012Ra_HL17{hueint_i}(i)]=CRI2012_c(spdi,17,thetas,rescalingparameters{1}.cri2012.HL17);

                %CQS v9.0 : a,f,p,g 
                [Qa12{hueint_i}(i),Qf12{hueint_i}(i),Qp12{hueint_i}(i),Qg12{hueint_i}(i),DEavg12_CQS{hueint_i}(i,:)]=CQSv9p0_c(spdi,thetas,rescalingparameters{1}.cqsv9p0); 

                        
                %Sanders Rp
                [Rp12{hueint_i}(i),DEavg12_Rp{hueint_i}(i)]=SandersRp_c(spdi,thetas,rescalingparameters{1}.sandersrp);
            
                %Judd Flattery index
                [Rf12{hueint_i}(i),DEavg12_Rf{hueint_i}(i)]=JuddFlattery_c(spdi,thetas,rescalingparameters{1}.juddrf);

                %Thornton CPI
                [cpi12{hueint_i}(i),DEavg12_cpi{hueint_i}(i)]=ThorntonCPI_c(spdi,thetas,rescalingparameters{1}.thorntoncpi);

                %MCRI
                [Rm12{hueint_i}(i),Sa12{hueint_i}(i)]=MCRI_c(spdi,0.9,thetas,rescalingparameters{1}.mcri);
            
            end
            [RaF4{hueint_i},DEavgF4_Ra{hueint_i}]=CIECRI_c(IllF4,thetas,rescalingparameters{1}.ciecri);
            [RmD65{hueint_i},SaD65{hueint_i}]=MCRI_c(D65,0.9,thetas,rescalingparameters{1}.mcri);
          
            [RpIllB{hueint_i},d2muIllB{hueint_i},~,d2IllB{hueint_i}]=SandersRp_c(IllB,thetas,rescalingparameters{1}.sandersrp);
            [RfD65{hueint_i},DEavgD65_Rf{hueint_i}]=JuddFlattery_c(D65,thetas,rescalingparameters{1}.juddrf);
            [cpiD65{hueint_i},DEavgD65_cpi{hueint_i}]=ThorntonCPI_c(D65,thetas,rescalingparameters{1}.thorntoncpi);

            save([cd,'\rescaling_par_data.mat'],'Rm12','Sa12','RmD65','SaD65','RpIllB','d2muIllB','cpi12','DEavg12_cpi','Rf12','DEavg12_Rf','Qa12','Qf12','Qp12','Qg12','DEavg12_CQS','CRI2012Ra12_HL17','DEavg12_CRI2012Ra_HL17','CIERa12','Ra12','DEavg12_CIERa','spds','rescalingparameters')
        else
            load rescaling_par_data
        end

        %CIE Ra
        %rescalingparameters{hueint_i}.ciecri=findrescaling_metric('ciecri',DEavg12_Ra{hueint_i},CIERa12{hueint_i},rescalingparameters{1}.ciecri);
        rescalingparameters{hueint_i}.ciecri=findrescaling_metric('ciecri',DEavgF4_Ra{hueint_i},CIECRI(IllF4),rescalingparameters{1}.ciecri);%keep F4 the same!

        %CRI2012
        rescalingparameters{hueint_i}.cri2012.HL17=findrescaling_metric('cri2012',DEavg12_CRI2012Ra_HL17{hueint_i},CIERa12{hueint_i},rescalingparameters{1}.cri2012.HL17);

        %CQS v9.0 : a,f,p
        rescalingparameters{hueint_i}.cqsv9p0.a=findrescaling_metric('cqsv9p0',DEavg12_CQS{hueint_i}(:,1),CIERa12{hueint_i},rescalingparameters{1}.cqsv9p0.a);
        rescalingparameters{hueint_i}.cqsv9p0.f=findrescaling_metric('cqsv9p0',DEavg12_CQS{hueint_i}(:,2),CIERa12{hueint_i},rescalingparameters{1}.cqsv9p0.f);
        rescalingparameters{hueint_i}.cqsv9p0.p=findrescaling_metric('cqsv9p0',DEavg12_CQS{hueint_i}(:,3),CIERa12{hueint_i},rescalingparameters{1}.cqsv9p0.p);

        %Sanders Rp
        %rescalingparameters{hueint_i}.sandersrp=findrescaling_metric('sandersrp',DEavg12_Rp{hueint_i},CIERa12{hueint_i},rescalingparameters{1}.sandersrp);
        rescalingparameters{hueint_i}.sandersrp=findrescaling_metric('sandersrp',d2IllB{hueint_i},85,rescalingparameters{1}.sandersrp);
       
        %Judd Rf
        %rescalingparameters{hueint_i}.juddrf=findrescaling_metric('juddrf',DEavg12_Rf{hueint_i},CIERa12{hueint_i},rescalingparameters{1}.juddrf);
        rescalingparameters{hueint_i}.juddrf=findrescaling_metric('juddrf',DEavgD65_Rf{hueint_i},90,rescalingparameters{1}.juddrf);%D65=90



        %cpi
        %rescalingparameters{hueint_i}.thorntoncpi=findrescaling_metric('cpi',DEavg12_cpi{hueint_i},CIERa12{hueint_i},rescalingparameters{1}.thorntoncpi);
        rescalingparameters{hueint_i}.thorntoncpi=findrescaling_metric('cpi',DEavgD65_cpi{hueint_i},100,rescalingparameters{1}.thorntoncpi);%D65 = 100

        %mcri
        rescalingparameters{hueint_i}.mcri=findrescaling_metric('mcri',[0.5;Sa12{hueint_i}(4);SaD65{hueint_i};1],[0;50;90;100],rescalingparameters{1}.mcri);
       
    end
end

save([cd,'\metricrescalingparameters.mat'],'rescalingparameters')