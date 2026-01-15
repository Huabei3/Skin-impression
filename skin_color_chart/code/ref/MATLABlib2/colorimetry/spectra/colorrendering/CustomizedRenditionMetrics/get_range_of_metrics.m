%get_range_of_metrics
load([cd,'\CustomizedRenditionMetrics\metricrescalingparameters.mat'])
thetas=[0 360];
rescalingparameters=rescalingparameters{1};

metrics={'CIE Ra','CRI2012 Ra(HL17)','CQSv9.0 Qf','CQSv9.0 Qa','CQSv9.0 Qp','CQSv9.0 Qg','FCI','GAI','geomean(GAI,CIE Ra)','Sanders Rp','Judd Rf','Thornton CPI','MCRI Rm','MCRI Sa'};
Nmetrics=length(metrics);

%initialize variables
xyzw=nan(N,3);
xyYw=xyzw;
Ra=nan(1,N);
CCT=Ra;
duv=Ra;
CRI2012Ra_HL17=Ra;
Qa=Ra;
Qf=Ra;
Qp=Ra;
Qg=Ra;
fci=Ra;
gai=Ra;
gaira=Ra;
Rp=Ra;
Rf=Ra;
cpi=Ra;
Rm=Ra;

%specify CCT
cct0=3000;
%specify point away from BB
du=0;
dv=-0.0;

% for ii=1:1;
ii=9
    switch ii
        case 1
            %CIE Ra
            metricfcn=@(x) CIECRI_c(x,thetas,rescalingparameters.ciecri);
            obs=2;
        case 2
             %CRI2012
            metricfcn=@(x) CRI2012_c(x,17,thetas,rescalingparameters.cri2012.HL17);
            obs=10;
        case 3
            %CQS v9.0 : f
            metricfcn=@(x) CQSv9p0_c(x,2,thetas,rescalingparameters.cqsv9p0); 
            obs=2;
        case 4
            %CQS v9.0 : a
            metricfcn=@(x) CQSv9p0_c(x,1,thetas,rescalingparameters.cqsv9p0); 
            obs=2;
        case 5
            %CQS v9.0 : p
            metricfcn=@(x) CQSv9p0_c(x,3,thetas,rescalingparameters.cqsv9p0); 
            obs=2;
        case 6
            %CQS v9.0 : g
            metricfcn=@(x) CQSv9p0_c(x,4,thetas,rescalingparameters.cqsv9p0); 
            obs=2;
        case 7
            %FCI
            metricfcn=@(x) -FCI_c(x);
            obs=2;
        case 8
            %GAI in UVW* using 8 Munsell cards
            metricfcn=@(x) -GAI_c(x,thetas); 
            obs=2;
        case 9
            %gai_Ra
            %gai_fcn(x)=GAI_c(x,thetas);
            %ra1_fcn(x)=CIECRI_c(x,thetas,rescalingparameters.ciecri);
            %ra_fcn(x) = ra1_fcn(x)*(ra1_fcn(x)>=0);
            metricfcn=@(x) -geomean([GAI_c(x,thetas);CIECRI_c(x,thetas,rescalingparameters.ciecri)*(CIECRI_c(x,thetas,rescalingparameters.ciecri)>=0)]);
            obs=2;
        case 10
             %Sanders Rp index
            metricfcn=@(x) SandersRp_c(x,thetas,rescalingparameters.sandersrp);
            obs=2;
        case 11
            %Judd Flattery index
            metricfcn=@(x) JuddFlattery_c(x,thetas,rescalingparameters.juddrf);
            obs=2;
        case 12
            %Thornton CPI
            metricfcn=@(x) ThorntonCPI_c(x,thetas,rescalingparameters.thorntoncpi);
            obs=2;
        case 13
            %MCRI
            metricfcn=@(x) MCRI_c(x,0.9,thetas,rescalingparameters.mcri);
            obs=10;
    end
    
    
            %set up SPDoptimizer
            
            clear optim
            clear global best fcn_data %best records best solution, fcn_data (to export data from within an objective fcn)
            global best fcn_data
            optim.type_ = 'none'; %'none': fluxes must be supplied!, 'mixer': fluxes are found using colormixer, 'search': fluxes are found using fminsearch
            optim.obs = obs; %CIE observer
            optim.routine = 'NSGA-II'; %'none' or 'fminsearch' (not implemented yet(5/09/2014))
            optim.gen = 30; %number of generations for NSGA-II
            optim.pop = 400; %number of individuals in populatoin for NSGA-II

            optim.fcns=[]; %handles to individual objective fcn

            i=1;%to specify objective fcn number for fcn_data
            optim.fcns{i} = @(i,x) metricfcn(x);
            optim.fcn_weigths = ones(1,numel(optim.fcns));%weigths for the different fcns
            optim.numberofobjectives = numel(optim.fcns); %number of objectives
            optim.cct0 = []; %target chromaticity as CCT (K); if = 0: calculate random CCT and add some noise to chromaticity
            
            xyzwtarget=spd2xyz(blackbodySPD(cct0),obs);
            uvYwtarget=xyz2uvY(xyzwtarget)+[du,dv,0]
            optim.uvYm = uvYwtarget;%or as u'v' chromaticity coordinates; 
                               %
            optim.nsources = 20; %number of sources; 
            optim.usesourceorder = 0; %use sourceorder as part of the optimization (only important when using 'mixer')
            optim.sp.sources=[];%contains predefined source spectra (if empty: source spectra are created from peakw, fwhm and rbas/fluxes)
            optim.InitChromosome = []; %source parameters (peak wavelength + fwhm + rbas/fluxes (depending on choice of SPDbuildertype
            optim.duvyn = 0; %1: restrict chromaticity to solutions close to blackbody locus (can only be active when mixer is not used)
            optim.lambdas = (360:1:830)'; %wavelength range of SPD
            optim.verbosity=1; %level of output (0: off, >0: on)
    
            [spdout,optim]=SPDoptimizer2(optim);
    
       
% end