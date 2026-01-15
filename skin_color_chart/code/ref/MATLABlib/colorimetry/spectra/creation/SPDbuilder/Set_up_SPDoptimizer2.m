%Set_up_SPDoptimizer2
%example:
clear optim
clear global best fcn_data %best records best solution, fcn_data (to export data from within an objective fcn)
optim.type_ = 'mixer'; %'none': fluxes must be supplied!, 'mixer': fluxes are found using colormixer, 'search': fluxes are found using fminsearch
optim.obs = 10; %CIE observer
optim.routine = 'NSGA-II'; %'none' or 'fminsearch' (not implemented yet(5/09/2014))
optim.gen = 10; %number of generations for NSGA-II
optim.pop = 400; %number of individuals in populatoin for NSGA-II

optim.fcns=[]; %handles to individual objective fcn
%      Example:
          i=1;%to specify objective fcn number for fcn_data
          %optim.fcns{i} = @(i,x) -spd2Si(i,x,optim.pars.a,optim.pars.rfls,optim.pars.catyn,optim.pars.xyzwtarget);
          optim.fcns{i} = @(i,x) -CIECRI(x);
          optim.fcn_weigths = ones(1,numel(optim.fcns));%weigths for the different fcns
optim.numberofobjectives = numel(optim.fcns); %number of objectives
optim.cct0 = []; %target chromaticity as CCT (K); if = 0: calculate random CCT and add some noise to chromaticity
optim.uvYm = xyz2uvY(xyzwtarget);%or as u'v' chromaticity coordinates; 
                   %
optim.nsources = 10; %number of sources; 
optim.usesourceorder = 0; %use sourceorder as part of the optimization (only important when using 'mixer')
optim.sp.sources=[];%contains predefined source spectra (if empty: source spectra are created from peakw, fwhm and rbas/fluxes)
optim.InitChromosome = []; %source parameters (peak wavelength + fwhm + rbas/fluxes (depending on choice of SPDbuildertype
optim.duvyn = 0; %1: restrict chromaticity to solutions close to blackbody locus (can only be active when mixer is not used)
optim.lambdas = (360:1:830)'; %wavelength range of SPD
optim.verbosity=1; %level of output (0: off, >0: on)

% %create fixed set of source spds
% optim.nsources=[];
% wavs=[360:10:830];
% fwhms=10.*ones(1,numel(wavs));
% clear spdi
% for i=1:numel(wavs)
%     spdi_=creategaussian(optim.lambdas,wavs(i),fwhms(i));
%     spdi(:,i)=spdi_(:,2)./max(spdi_(:,2));
% end
% sourcepars=[0.5.*ones(1,numel(wavs)+1);[optim.lambdas,spdi(:,:)]];
% optim.sourcepars=sourcepars;
