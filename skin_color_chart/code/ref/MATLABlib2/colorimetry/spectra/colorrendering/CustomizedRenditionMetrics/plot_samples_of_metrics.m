%plot_samples_of_metrics
%turn code line 16-29 on in selectsampleswithinhueintervalthetas.m
thetas=[0 220]; 
spdi=D65;
i=1;
hueint_i=2;
Elux=0.9;

load([cd,'\CustomizedRenditionMetrics\metricrescalingparameters.mat'])
rescalingparameters=rescalingpars{hueint_i};

clear Ra CCT duv CRI2012Ra_HL17 Qa Qf Qp Qg fci gai gaira Rf cpi Rm Sa

%--------------------------------------------------------------------------
global plotsamplesofmetrics
plotsamplesofmetrics=1;
    %CIE Ra
    [Ra(i),~,CCT(i),duv(i)]=CIECRI_c(spdi,thetas,rescalingparameters.ciecri);
     
    %CRI2012
    [CRI2012Ra_HL17(i)]=CRI2012_c(spdi,17,thetas,rescalingparameters.cri2012.HL17);
%     [CRI2012Ra_Real210(i)]=CRI2012_c(spdi,210,thetas,rescalingparameters.cri2012.Real210);
%     [CRI2012Ra_HL1000(i)]=CRI2012_c(spdi,1000,thetas,rescalingparameters.cri2012.HL1000);
%     [CRI2012Ra_FlatL(i)]=CRI2012_c(spdi,4800,thetas,rescalingparameters.cri2012.FlatL);%flattened large set from CRI2014
%     [CRI2012Ra_FlatS(i)]=CRI2012_c(spdi,99,thetas,rescalingparameters.cri2012.FlatS);%flattened small set from CRI2014
    
    %CQS v9.0 : a,f,p,g 
    [Qa(i),Qf(:,i),Qp(i),Qg(i)]=CQSv9p0_c(spdi,thetas,rescalingparameters.cqsv9p0); 
    
    %FCI
    fci(i)=FCI_c(spdi,thetas);
    
    %GAI in UVW* using 8 Munsell cards
    [gai(i)]=GAI_c(spdi,thetas); 
    
    %gai_Ra
    gaira(i)=geomean([gai(i);Ra(i)]);
    
    %Judd Flattery index
    [Rf(i)]=JuddFlattery_c(spdi,thetas,rescalingparameters.juddrf);
    
    %Thornton CPI
    [cpi(i)]=ThorntonCPI_c(spdi,thetas,rescalingparameters.thorntoncpi);
     
    %MCRI
    [Rm(i),Sa(i)]=MCRI_c(spdi,Elux,thetas,rescalingparameters.mcri);
plotsamplesofmetrics=0;
clear global plotsamplesofmetrics
%--------------------------------------------------------------------------