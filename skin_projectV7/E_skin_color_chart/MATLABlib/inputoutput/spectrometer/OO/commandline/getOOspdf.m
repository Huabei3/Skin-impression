function [SPD,SPDdn,errorflag,oospecname,actualTemperature,spectralData00]=getOOspdf(display,Nes,IntegrationTime,Nscans,DarkFlag,NonlinearityFlag,boxcarwidth,wtype_lev_alpha);
% Get spectrum using an OceanOptics spectrometer
% INPUT:
%   Display: 
%           Display spectrometer info & acquisition parameter (0: no, 1: yes, -1: no)
%           and in addition show a plot of the final SPD (0: no, 2: yes)
%   Nes: 
%           Nes = number of spectrometer to select
%   IntegrationTime:  
%           IntegrationTime(1)==0 --> let function determine max. integration
%           time without saturation
%           IntegrationTime(1)<0 --> let function determine max. integration
%           time without saturation AND not larger than -IntegrationTime
%           IntegrationTime(1)>0 --> User defined fixed integration time
%           Note: IntegrationTime is always limited to min and max
%           integration time of specified spectrometer model
%           IntegrationTime(2) = optional Active Cooling argument. 0: off; 1: on. If not
%           supported by detector, giving a value of 1 has no effect. 
%   Nscans:    
%           Number of scans to average
%   DarkFlag: 
%           0: No correction for electric Dark Signal, 1: correction
%   NonlinearityFlag:
%           Correction for Nonlinear behaviour of e- wells
%   boxcarwidth:
%           Each pixel column contains average of  "boxcarwidth"-number of
%           pixels to the left and right of center pixel
%   wtype_lev_alpha: 
%           parameters controlling denoising of meas. spectrum, input as:
%           1x3 array: [wtype,lev,alpha]:
%           wtype: 
%               Particular Wavelet type to use for de-noising,
%                   1: 'coif5' (default), 2: 'db9', 3:'db10'
%           lev: 
%               Level of wavelet packet decomposition of meas. spectrum
%           alpha: 
%               ALPHA is a tuning parameter for the penalty term, it 
%               must be a real number greater than 1. The sparsity of the
%               wavelet packet representation of the de-noised signal or 
%               image grows with ALPHA. Typically ALPHA = 2.
%
%            When wtype_lev_alpha=0 or nargout==1; don't calculate denoised spectrum!
%         
%   
% OUTPUT
%   SPD = [wavelength,measured SPD in counts/s]
%   [optional  SPDdn = [wavelength,denoised SPD in counts/s]    ]
%           
% Requirements
% This example requires the following:
% - A 32 bit or 64-bit(*) Microsoft(R) Windows(R)
% - Ocean Optics spectrometer USB2000(*), HR4000(*), QE65000, QE-PRO 
%   USB650  (RedTide) (*)
% - Install OmniDriver downloadable from http://www.oceanoptics.com/
% March 24 2014: (*) Tested on a 64 bit OS (Win7)
%
DetectorTemperatureDEF=NaN;IntTimeDEF=[0,DetectorTemperatureDEF];boxcarwidthDEF=0;wtype_lev_alphaDEF=[1,10,2];
if nargin<1;display=0;Nes=1;Nscans=1;IntegrationTime=IntTimeDEF;DarkFlag=1;NonlinearityFlag=1;boxcarwidth=boxcarwidthDEF;wtype_lev_alpha=[1,10,2];end
if nargin<2;Nes=1;Nscans=1;IntegrationTime=IntTimeDEF;DarkFlag=1;NonlinearityFlag=1;boxcarwidth=boxcarwidthDEF;wtype_lev_alpha=[1,10,2];end
if nargin<3;Nscans=1;IntegrationTime=IntTimeDEF;DarkFlag=1;NonlinearityFlag=1;boxcarwidth=boxcarwidthDEF;wtype_lev_alpha=[1,10,2];end
if nargin<4;Nscans=1;DarkFlag=1;NonlinearityFlag=1;boxcarwidth=boxcarwidthDEF;wtype_lev_alpha=[1,10,2];end
if nargin<5;DarkFlag=1;NonlinearityFlag=1;boxcarwidth=boxcarwidthDEF;wtype_lev_alpha=[1,10,2];end
if nargin<6;NonlinearityFlag=1;boxcarwidth=boxcarwidthDEF;wtype_lev_alpha=[1,10,2];end
if nargin<7;boxcarwidth=boxcarwidthDEF;wtype_lev_alpha=[1,10,2];end
if nargin<8; wtype_lev_alpha=[1,10,2];end

if isempty(wtype_lev_alpha);wtype_lev_alpha=[1,10,2];end;%set default values

SPD=[];
SPDdn=[];
oospecname=[];
actualTemperature=[];
spectralData00=[];


errorflag=0;%-1 --> cannot open spectrometer, 0 not tested, 1 successful connect

FlagChangeInt=1;
maxcCount_ratio=0.9;
Pr_maxcount=0.8;

%handle Active Cooling 
%if numel(IntegrationTime)==1; DetectorTemperature=DetectorTemperatureDEF;else;DetectorTemperature=IntegrationTime(2);end;%old code for setting actual temperature
if numel(IntegrationTime)==1; DetectorTemperature=DetectorTemperatureDEF;else;DetectorTemperature=IntegrationTime(2);switch DetectorTemperature;case 0;DetectorTemperature=DetectorTemperatureDEF,case 1;DetectorTemperature=-20;end;end

IntegrationTime=IntegrationTime(1);
IntegrationTime_in=IntegrationTime;
IntegrationTime=abs(IntegrationTime);%work with positive IntegrationTime!

try %try making a measurement

%IMPORT JAVA class
import('com.oceanoptics.omnidriver.api.wrapper.Wrapper')
% Create a new instance of the API object assignin(ws, 'var', val)

%clear wrapper;
wrapper = Wrapper();assignin('base', 'wrapper', Wrapper());

%--------------------------------------------------------------------------
% Open all attached spectrometers
%--------------------------------------------------------------------------
numoospec = wrapper.openAllSpectrometers()

if numoospec~=-1; %at least one spectrometer detected
        
    if nargin<2 
        disp(sprintf('%s','________________________________________________'));
        disp(sprintf('%1.0f Spectrometers detected: \n',numoospec));
%         disp(sprintf('\t %1.0f) %s',0,'ABORT Measurement'))
%         disp(sprintf('%s','------------------------------------------------'));
        if numoospec>1
            for i=1:numoospec
                oospecnames=wrapper.getName(i-1);
                disp(sprintf('\t %1.0f) %s',i,oospecnames.char))
            end
            disp(sprintf('%s','------------------------------------------------'));
            spectrometerIndex=input('\n Select spectrometer or ABORT Measurement (0): ');
        else
            spectrometerIndex=1;
        end
            disp(sprintf('%s','________________________________________________'));
            spectrometerIndex=spectrometerIndex-1;%Java counts arrays from zero!
        if  spectrometerIndex ==-1;disp(sprintf('\n Measurement ABORTED by user! \n')); return;end   
        %disp(sprintf('Index of selected spectrometer: %1.0f',spectrometerIndex+1))
    else
        spectrometerIndex=Nes-1;
    end

%--------------------------------------------------------------------------
%   Display Device Information
%--------------------------------------------------------------------------

oospecname = wrapper.getName(spectrometerIndex)
oospecsn = wrapper.getSerialNumber(spectrometerIndex);

if display>=1;
    disp('------------------Spectrometer Info------------------')
    disp(sprintf('Number of Spectrometers detected: %1.0f',numoospec));
    disp(sprintf('Model: %s',oospecname.char));
    disp(sprintf('Series number: %s',oospecsn.char));
    disp('----------------END Spectrometer Info----------------')
    disp('')
end

%Get some spectrometer specific parameters
[IntegrationTime,maxint,minint,maxCount,specAD,Npixels_,usepixels_,SNration, ActiveCooling]=getMODELspecs(IntegrationTime,oospecname.char);
if ActiveCooling(1)==1;AllowedTemprange=ActiveCooling(2:3);else;AllowedTemprange=[0,0];end %get allowed cooling range below ambient

%make sure minint <= inttime <= maxint!!
if IntegrationTime<minint;IntegrationTime=minint;if display==1;disp(sprintf('\n %s \n','IntegrationTime changed to comply with spectrometer specs!')),end;end
if IntegrationTime>maxint;IntegrationTime=maxint;if display==1;disp(sprintf('\n %s \n','IntegrationTime changed to comply with spectrometer specs!')),end;end
 

if display>=1;
disp('')
disp('----------------Acquisition parameters----------------')
disp(sprintf('Number of scans: %1.0g', Nscans))
disp(sprintf('Correct for Dark: %1.0g', DarkFlag))
disp(sprintf('Correct for Non-linearity: %1.0g', NonlinearityFlag))
disp(sprintf('Boxcar width (pixels): %1.0g', boxcarwidth))
disp(sprintf('Integration Time: %1.6g s', IntegrationTime))  
%disp('--------------END Acquisition parameters--------------')
%--------------------------------------------------------------------------
end

%--------------------------------------------------------------------------
%   Start configuration of Acquisition parameters
%--------------------------------------------------------------------------
wrapper.setBoxcarWidth(spectrometerIndex,boxcarwidth);
wrapper.setExternalTriggerMode(spectrometerIndex,0);
%triggermode=wrapper.getExternalTriggerMode(spectrometerIndex);
    %--------------------------------------------------------------------------
    %   Set Detector Temperature if applicable and requested (e.g. for QE65000)
    %--------------------------------------------------------------------------
    % Attempt to obtain a "CCoThermoElectric" object that will allow us to
    % interact with the thermo-electric controls for this spectrometer.
    if wrapper.isFeatureSupportedThermoElectric(spectrometerIndex) == 0 
        if ~isnan(DetectorTemperature)
            warning('The thermo-electric feature is not supported.')
        end
    else
        % The following call to getFeatureControllerThermoElectric() will
        % always return a "valid" object,
        % even if the spectrometer does not support that feature.
        % Hence it is important to first call sFeatureSupportedThermoElectric()
        tecController = wrapper.getFeatureControllerThermoElectric(spectrometerIndex);
        if ~isnan(DetectorTemperature)
            % If you want to control the temperature, setTECEnable()
            % MUST be set to true
            tecController.setTECEnable(logical(1));
            tecController.setFanEnable(logical(1)); % turn the fan on (optional)
            desiredTemperature = DetectorTemperature; % degrees Celsius
            tecController.setDetectorSetPointCelsius(desiredTemperature);
            actualTemperature = tecController.getDetectorTemperatureCelsius();
            for i=1:10;actualTemperature = tecController.getDetectorTemperatureCelsius();end; % call several times to avoid bug described in manual
            if display>=1;
                disp(sprintf('Active Cooling on. DetectorTemperature at %1.2f °C',actualTemperature))
            end
        else
            tecController.setTECEnable(logical(0));
            tecController.setFanEnable(logical(0)); % turn the fan on (optional)
            actualTemperature = tecController.getDetectorTemperatureCelsius();
            if display>=1;
                disp(sprintf('Active Cooling off. DetectorTemperature at %1.2f °C',actualTemperature))
            end
        end
    end


%--------------------------------------------------------------------------
% If entered IntegrationTime <=0; find optimal integration time, start 
% search at minint.
%--------------------------------------------------------------------------
Flags=1;%DarkcFlag & NonlinearityFlag
%spectralData0 = wrapper.getSpectrum(spectrometerIndex);
if IntegrationTime_in <= 0
    if IntegrationTime_in<0;%limit max inttime to user defined value
        MaxIntTime_user=abs(IntegrationTime_in);
        IntegrationTime=minint;
    else
        MaxIntTime_user=0;
    end 
    wrapper.setIntegrationTime(spectrometerIndex,IntegrationTime*(10^6));%native integrationtime of OO spectrometers = µs (not s as in this function!)
    wrapper.setCorrectForElectricalDark(spectrometerIndex,DarkFlag);
    wrapper.setCorrectForDetectorNonlinearity(spectrometerIndex,NonlinearityFlag);
    wrapper.setScansToAverage(spectrometerIndex,1);
    
    counts_ = double(wrapper.getSpectrum(spectrometerIndex));counts_=counts_(usepixels_);
    maxcount=max(counts_);
    issaturated=wrapper.isSaturated(spectrometerIndex);
    if issaturated>0;error(sprintf('Saturation at minimum IntegrationTime of %1.5f s',IntegrationTime));return,end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %Determine optimimum integration time = max. counts but not saturated!
    %%%%%=SearchMaxIntTime_fullscript%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    %search for max non saturated inttime

                    warning off
                    %Initialize parameters

                    if ~exist('Pr_maxcount','var');Pr_maxcount=0.8;end;%already defined
                    if ~exist('maxcCount_ratio','var');maxcCount_ratio=0.9;end;
                    if ~exist('display','var');display=0;end%already defined
                    FlagChangeInt=0;
                    target_count=maxCount*(Pr_maxcount+0.05);
                    IntTime_IncreaseRatio1=4;
                    tol_error_projected_time=1.1;
                    error_projected_inttime=100;
                    projected_large_than_maxint=0;
                    ratio_1=0.95;

                    %maxint=wrapper.getMaximumIntegrationTime(spectrometerIndex)./10^6;%get maxCount
                    MaxIntTime_user(MaxIntTime_user==0)=maxint*maxcCount_ratio;
                    maxint=min([maxint,MaxIntTime_user/maxcCount_ratio]);

                    Nspectra_0=1;Nspectra=Nspectra_0;%number of spectra to average to reduce influence of noise on fit
                    numberoflastmaxcounts2useinfitting=3;

                    db2=-specAD+4;MinimummaxcountRatioForNspectraIsOne=(2^(db2/2));%Noise ratio: cfr.: db2=2.*log2(I1/I0)

                    %--------------------------------------------------------------------------
                    % collect spectrum for inttime=minint (1st run)
                    %--------------------------------------------------------------------------
                    i=1;
                    IntTimes(i)=IntegrationTime;%start search at IntegrationTime
                    projected_inttime=IntegrationTime;

                    wrapper.setScansToAverage(spectrometerIndex,1);
                    wrapper.setCorrectForElectricalDark(spectrometerIndex,1);
                    wrapper.setCorrectForDetectorNonlinearity(spectrometerIndex,1);
                    wavs_ = wrapper.getWavelengths(spectrometerIndex);wavs_=wavs_(usepixels_);


                    %----------------------------------------------------------------------
                    % get stablespectrum for 1st run
                    %______________________________________________________________________
                    wrapper.setIntegrationTime(spectrometerIndex,IntTimes(i)*(10^6));
                    if display>=1;disp(sprintf('1st run: Checking IntegrationTime: %1.5f s',projected_inttime));end
                    n=2;
                    clear xy_ii satvals_ii maxcounts_ii COUNTS_ii;
                    ii=1;satvals_ii(ii)=0;
                    while (satvals_ii(ii)==0 & ii<=Nspectra) | maxcounts_ii(ii)<=0
                        ii=ii+1;

                        counts_ = wrapper.getSpectrum(spectrometerIndex);
                        counts_=counts_(usepixels_);maxcounts_ii(ii)=max(counts_);COUNTS_ii(:,ii)=counts_;
                        satvals_ii(ii)=~(~wrapper.isSaturated(spectrometerIndex) & (maxcounts_ii(ii)<=target_count));
                        satvals_ii(ii)=~(~wrapper.isSaturated(spectrometerIndex) & (maxcounts_ii(ii)<=target_count))-2*wrapper.isSaturated(spectrometerIndex);
                        std_ii(ii)=std(maxcounts_ii(n:end));
                        xy_ii(ii,:)=[ii,IntTimes(i),projected_inttime,maxcounts_ii(ii),std(maxcounts_ii(n:end)),(std(maxcounts_ii(n:end))/mean(maxcounts_ii(n:end))),IntTimes(i)./projected_inttime,maxcounts_ii(ii)./maxCount,satvals_ii(ii),NaN];  %summary array 
                        %[ii,Nspectra,ii>=Nspectra/2,((std(maxcounts_ii(n:end))/mean(maxcounts_ii(n:end)))),NaN,satvals_ii(ii),maxcounts_ii(ii)]
                        if (Nspectra>1 & ii>=Nspectra/2 & ii>n & ((std(maxcounts_ii(n:end))/mean(maxcounts_ii(n:end)))<=0.05));break;end
                    end
                    maxcounts_ii=maxcounts_ii(n:end);
                    stdcounts(i)=std(maxcounts_ii);
                    maxcounts(i)=mean(maxcounts_ii);
                    satvals(i)=mean(satvals_ii(n:end))>0;
                    COUNTS_(:,i)=mean(COUNTS_ii')';counts_=COUNTS_(:,i);

                    nn=numberoflastmaxcounts2useinfitting;%use only last 3 for fitting
                    %maxcounts_valid=[maxcounts(satvals<=0 & (1:numel(maxcounts))>i-nn+1),IntTimes(satvals<=0 & (1:numel(maxcounts))>i-nn+1)];

                    if i>=nn;
                        [p,S]=polyfit(maxcounts(satvals<=0 & (1:numel(maxcounts))>i-nn+1),IntTimes(satvals<=0 & (1:numel(maxcounts))>i-nn+1),1);
                        [projected_inttime,DELTA]=polyval(p,target_count,S);
                        if projected_inttime>minint
                            projected_inttimes(i)=projected_inttime;
                            DELTA=3.*DELTA;
                            proj_intt_max=(projected_inttime+DELTA);proj_maxcount_max=(proj_intt_max-p(2))./p(1); 
                            proj_intt_min=(projected_inttime-DELTA);proj_mincount_min=(proj_intt_min-p(2))./p(1); 
                            errorontargetcount=proj_maxcount_max-proj_mincount_min;
                            error_projected_inttime=std(projected_inttimes((1:numel(maxcounts))>i-nn+1));%use only last nn for checking stability of solution  
                            %figure(3);plot(target_count,projected_inttime,'r.');errorbarxy(target_count,projected_inttime,errorontargetcount,DELTA);hold on;text(target_count,projected_inttime,sprintf('%1.0f',i));waituntilclicked;figure(3);

                        else
                            projected_inttimes(i)=IntTimes(i)*IntTime_IncreaseRatio1;
                        end
                    else
                         IntTime_IncreaseRatio1_actual=min([IntTime_IncreaseRatio1,(maxCount.*maxcCount_ratio*ratio_1)./maxcounts(i)]);
                         projected_inttimes(i)=IntTimes(i)*IntTime_IncreaseRatio1_actual;
                    end
                    projected_inttime=projected_inttimes(i);

                    %check if larger than maxint
                    if projected_inttime>=maxint & maxcounts(i)/maxCount>=MinimummaxcountRatioForNspectraIsOne;
                            projected_inttime=maxint.*maxcCount_ratio;
                            projected_inttimes(i)=projected_inttime;
                            projected_large_than_maxint=1;
                    else
                            projected_large_than_maxint=0;
                    end

                    %xy(i,:)=[i,IntTimes(i),projected_inttimes(i),maxcounts(i),stdcounts(i),stdcounts(i)/maxcounts(i),IntTimes(i)./projected_inttime,maxcounts(i)./maxCount,satvals(i),NaN];   %summary array 
                    %figure(3);hold on;line([maxCount;maxCount],[0;projected_inttime*1.1]);plot(maxcounts(i),IntTimes(i),'b.');errorbarxy(maxcounts(i),IntTimes(i),stdcounts(i),[]);hold on;text(maxcounts(i),IntTimes(i),sprintf('%1.0f',i));waituntilclicked;figure(3);
                    %disp(sprintf('i=%1.0f t=%1.4f / %1.4f sat=%1.0f maxcount=%1.1f/ %1.3f, t_projected: %1.3f',i,IntTimes(i),IntTimes(i)/projected_inttime,satvals(i),maxcounts(i),maxcounts(i)./maxCount, projected_inttime))



                    %--------------------------------------------------------------------------
                    % collect spectra for increasing inttimes 
                    %--------------------------------------------------------------------------

                    while (maxcounts(i)<maxCount*(Pr_maxcount) & IntTimes(i)<=maxint  & projected_large_than_maxint==0) %& (projected_inttime+error_projected_inttime)/projected_inttime>=tol_error_projected_time
                        i=i+1;
                        Nspectra=Nspectra_0;
                        IntTimes(i)=IntTimes(i-1)*IntTime_IncreaseRatio1;

                        if ((IntTimes(i)>projected_inttime) | (((projected_inttime+error_projected_inttime)/projected_inttime)<=tol_error_projected_time)) & (maxcounts(i-1)/maxCount>=MinimummaxcountRatioForNspectraIsOne)
                            IntTimes(i)=projected_inttime;
                        end

                        if maxcounts(i-1)/maxCount>=MinimummaxcountRatioForNspectraIsOne | IntTimes(i)>=maxint*maxcCount_ratio;Nspectra=1;end


                        %----------------------------------------------------------------------
                        % get stable spectrum for other spectra
                        %______________________________________________________________________
                        wrapper.setIntegrationTime(spectrometerIndex,IntTimes(i)*(10^6));
                        if display>=1;disp(sprintf('Checking IntegrationTime: %1.5f s',IntTimes(i)));end
                        n=2;
                        clear xy_ii satvals_ii maxcounts_ii COUNTS_ii;
                        ii=1;satvals_ii(ii)=0;
                        while (satvals_ii(ii)==0 & ii<=Nspectra) | maxcounts_ii(ii)<=0
                            ii=ii+1;
                            counts_ = wrapper.getSpectrum(spectrometerIndex);
                            counts_=counts_(usepixels_);maxcounts_ii(ii)=max(counts_);COUNTS_ii(:,ii)=counts_;
                            satvals_ii(ii)=~(~wrapper.isSaturated(spectrometerIndex) & (maxcounts_ii(ii)<=target_count));
                            satvals_ii(ii)=~(~wrapper.isSaturated(spectrometerIndex) & (maxcounts_ii(ii)<=target_count))-2*wrapper.isSaturated(spectrometerIndex);
                            std_ii(ii)=std(maxcounts_ii(n:end));
                            xy_ii(ii,:)=[ii,IntTimes(i),projected_inttime,maxcounts_ii(ii),std(maxcounts_ii(n:end)),(std(maxcounts_ii(n:end))/mean(maxcounts_ii(n:end))),IntTimes(i)./projected_inttime,maxcounts_ii(ii)./maxCount,satvals_ii(ii),NaN];  %summary array 
                            if (Nspectra>1 & ii>=Nspectra/2 & ii>n & ((std(maxcounts_ii(n:end))/mean(maxcounts_ii(n:end)))<=0.05));break;end
                        end
                        maxcounts_ii=maxcounts_ii(n:end);
                        stdcounts(i)=std(maxcounts_ii);
                        maxcounts(i)=mean(maxcounts_ii);
                        satvals(i)=mean(satvals_ii(n:end))>0;
                        COUNTS_(:,i)=mean(COUNTS_ii')';counts_=COUNTS_(:,i);

                        nn=numberoflastmaxcounts2useinfitting;%use only last 3 for fitting
                        if i>=nn;
                            [p,S]=polyfit(maxcounts(satvals<=0 & (1:numel(maxcounts))>i-nn+1),IntTimes(satvals<=0 & (1:numel(maxcounts))>i-nn+1),1);
                            [projected_inttime,DELTA]=polyval(p,target_count,S);
                            if projected_inttime>minint
                                projected_inttimes(i)=projected_inttime;
                                DELTA=3.*DELTA;
                                proj_intt_max=(projected_inttime+DELTA);proj_maxcount_max=(proj_intt_max-p(2))./p(1); 
                                proj_intt_min=(projected_inttime-DELTA);proj_mincount_min=(proj_intt_min-p(2))./p(1); 
                                errorontargetcount=proj_maxcount_max-proj_mincount_min;
                                error_projected_inttime=std(projected_inttimes((1:numel(maxcounts))>i-nn+1));%use only last nn for checking stability of solution  

                                %figure(3);plot(target_count,projected_inttime,'r.');errorbarxy(target_count,projected_inttime,errorontargetcount,DELTA);hold on;text(target_count,projected_inttime,sprintf('%1.0f',i));waituntilclicked;figure(3);

                            else
                                projected_inttimes(i)=IntTimes(i)*IntTime_IncreaseRatio1;
                            end
                        else
                            IntTime_IncreaseRatio1_actual=min([IntTime_IncreaseRatio1,(maxCount.*maxcCount_ratio*ratio_1)./maxcounts(i)]);
                            projected_inttimes(i)=IntTimes(i)*IntTime_IncreaseRatio1_actual;
                        end
                        projected_inttimes;
                        projected_inttime=projected_inttimes(i);

                        %check if larger than maxint
                        if projected_inttime>=maxint & maxcounts(i)/maxCount>=MinimummaxcountRatioForNspectraIsOne;
                            projected_inttime=maxint.*maxcCount_ratio;
                            projected_inttimes(i)=projected_inttime;
                            projected_large_than_maxint=1;
                        else
                            projected_large_than_maxint=0;
                        end


                    end
                    wrapper.setIntegrationTime(spectrometerIndex,minint*(10^6));%reduce latency time for final meas.
                    IntegrationTime=projected_inttime;
                     %IntegrationTime=IntTimes(IntTimes<=maxint*maxcCount_ratio & maxcounts./maxCount<=maxcCount_ratio);IntegrationTime=IntegrationTime(IntegrationTime==max(IntegrationTime));
                    IntegrationTime(IntegrationTime>MaxIntTime_user)=MaxIntTime_user;
                    FlagChangeInt=1;
    
    %%%%% END SearchMaxIntTime_fullscript%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    if MaxIntTime_user>0;IntegrationTime(IntegrationTime>=MaxIntTime_user)=MaxIntTime_user;FlagChangeInt=1;end
end

%make sure minint <= inttime <= maxint!!
if IntegrationTime<minint;IntegrationTime=minint;FlagChangeInt=1;if display>=1;disp(sprintf('\n %s \n','IntegrationTime changed to comply with spectrometer specs!')),end;end
if IntegrationTime>maxint;IntegrationTime=maxint;FlagChangeInt=1;if display>=1;disp(sprintf('\n %s \n','IntegrationTime changed to comply with spectrometer specs!')),end;end
 

%--------------------------------------------------------------------------
% ReadOut and automic dataprocessing of final spectrum at final/optimum
% integration time with all spectrometer acquisition parameters as
% requested
if Nscans>1 | FlagChangeInt==1;%if Nscans==1--> use previous result to save time!
    wrapper.setIntegrationTime(spectrometerIndex,IntegrationTime*(10^6));
    wrapper.setCorrectForElectricalDark(spectrometerIndex,DarkFlag); 
    wrapper.setCorrectForDetectorNonlinearity(spectrometerIndex,NonlinearityFlag);
    wrapper.setScansToAverage(spectrometerIndex,Nscans);
    spectralData0 = wrapper.getSpectrum(spectrometerIndex);
    spectralData0=spectralData0(usepixels_);
    spectralData0(spectralData0<0)=0;
    spectralData00=spectralData0;
    
%     spectralData1 = wrapper.getSpectrum(spectrometerIndex);
%     spectralData1=spectralData1(usepixels_);
%     spectralData1(spectralData1<0)=0;
% %     spectralData1 =spectralData00;
 
else
   spectralData0=spectralData0_1; 
end

wavelengths0 = wrapper.getWavelengths(spectrometerIndex);wavelengths0=wavelengths0(usepixels_);
%     ccc=rand(1,3);
%     figure(112);subplot(1,3,1);hold on
%     plot(wavelengths0,spectralData00,'Color',ccc)
%     subplot(1,3,2);hold on
%     plot(wavelengths0,spectralData1,'Color',ccc)


%check for possible saturation of signal, just in case setting the detector nonlinearity etc do cause saturation, but only when a fixed IntTime is not requested!
issaturated=wrapper.isSaturated(spectrometerIndex);
satval=max(spectralData0)>maxcCount_ratio*maxCount;%apparently one can get sat 0 with wrapper function, while it is saturation when looking at  graph
if (issaturated==1 | satval==1);warning(sprintf('Saturation at user defined IntegrationTime of %1.5f s',IntegrationTime));end
ii=0;
while (issaturated==1 | satval==1) & IntegrationTime_in <= 0 & IntegrationTime>=minint;
    ii=ii+1;[ii,IntegrationTime,issaturated,max(spectralData0)]
    IntegrationTime=IntegrationTime*1000/1050;%decrease IntegrationTime fractionally
    wrapper.setIntegrationTime(spectrometerIndex,IntegrationTime*(10^6));
    spectralData0 = wrapper.getSpectrum(spectrometerIndex);spectralData0=spectralData0(usepixels_);
    issaturated=wrapper.isSaturated(spectrometerIndex);
    satval=max(spectralData0)>maxcCount_ratio*maxCount;%apparently one can get sat 0 with wrapper function, while it is saturation when looking at  graph

end
IntegrationTime_=wrapper.getIntegrationTime(spectrometerIndex);
IntegrationTime=[IntegrationTime_/(10^6)];

if display>=1;
disp(sprintf('Final Integration Time: %1.6g s', IntegrationTime))   
disp('--------------END Acquisition parameters--------------')
end

%summaryize spectral data in 2D array [wavelength, counts/s]
SPD=[wavelengths0,spectralData0./IntegrationTime];

if nargout>1
% DeNoise Spectrum values using wavelets: 
% "De-Noising Audio Signals Using MATLAB Wavelets Toolbox" by Villanueva-Luna
    switch wtype_lev_alpha(1);
        case 1;wtype='coif5';
        case 2;wtype='db9';
        case 3;wtype='db10';
        otherwise
            wtype='coif5';
    end
    lev=wtype_lev_alpha(2);
    alpha=wtype_lev_alpha(3);        
    wentropy='log energy';
    spectralData_denoised=waveletDenoising(wavelengths0,spectralData0,wtype,wentropy,lev,alpha);
    %summaryize spectral data in 2D array [wavelength, counts/s]
    SPDdn=[wavelengths0,spectralData_denoised./IntegrationTime];
end
    
if display>1;
    figure('Name','Measured spectrum');
    subplot(1,2,1);plot(wavelengths0,spectralData0,'b-');legend(gca,{'Measured SPD'});xlabel('wavelength (nm)');ylabel(sprintf('counts for int. time of %1.5f s',IntegrationTime));title('Measured uncalibrated spectrum');axis([360,830,min(spectralData0).*1.1,max(spectralData0).*1.1]);grid on;
    subplot(1,2,2);plot(wavelengths0,SPD(:,2),'b-');legend(gca,{'Measured SPD'});xlabel('wavelength (nm)');ylabel('counts/s');title('Measured uncalibrated spectrum');axis([360,830,min(SPD(:,2)).*1.1,max(SPD(:,2)).*1.1]);grid on;
    if nargout>1;
       subplot(1,2,1);hold on;plot(wavelengths0,spectralData_denoised,'r-');hold off;legend(gca,{'Measured SPD','Wavelet De-Noised SPD'});xlabel('wavelength (nm)');ylabel(sprintf('counts for int. time of %1.5f s',IntegrationTime));title('Measured uncalibrated spectrum');axis([360,830,min(spectralData0).*1.1,max(spectralData0).*1.1]);grid on;
       subplot(1,2,2);hold on;plot(wavelengths0,spectralData_denoised./IntegrationTime,'r-');hold off;legend(gca,{'Measured SPD','Wavelet De-Noised SPD'});xlabel('wavelength (nm)');ylabel('counts/s');title('Measured uncalibrated spectrum');axis([360,830,min(SPDdn(:,2)).*1.1,max(SPDdn(:,2)).*1.1]);grid on;
    end
    %figure('Name','Measured spectrum');plot(wavelengths0,spectralData0./maxCount,'b-');hold on;plot(wavelengths0,spectralData_denoised./maxCount,'r-');legend(gca,{'Measured SPD','Wavelet De-Noised SPD'});xlabel('wavelength (nm)');ylabel('counts/s');title('Measured uncalibrated spectrum');axis([360,830,min(spectralData0./maxCount).*1.1,max(spectralData0./maxCount).*1.1]);grid on;
end

%--------------------------------------------------------------------------
% Setup spectrometer so that next readout goes quicker!
% OO spectrometers are in continuous measurement mode.
% By (re)-setting Dark and Nonlinearity to zero, Nscans to 1 and especially
% IntegrationTime to zero a next call of this functions is 
% significantly faster!
%--------------------------------------------------------------------------
wrapper.setCorrectForElectricalDark(spectrometerIndex,1);
wrapper.setCorrectForDetectorNonlinearity(spectrometerIndex,1);
wrapper.setScansToAverage(spectrometerIndex,1);
wrapper.setIntegrationTime(spectrometerIndex,minint);
spectralData0 = wrapper.getSpectrum(spectrometerIndex);spectralData0=spectralData0(usepixels_);spectralData0(spectralData0<0)=0;
%     figure(112);subplot(1,3,3);hold on
%     plot(wavelengths0,spectralData00,'Color',ccc)
%--------------------------------------------------------------------------
% Close the spectrometer before exiting
%--------------------------------------------------------------------------

wrapper.closeAllSpectrometers();

else
    open_exception=wrapper.getLastException();
    disp(sprintf('Exception at opening: %1.0f', open_exception));
    SPDdn=[];SPD=[];
end

    errorflag=1;
    
catch
    errorflag=-1;
    disp(sprintf('\n%s\n%s\n%s\n','Error reading spectrum or no spectrometer connected.','Make sure it is installed properly and you''re running matlab in the same bit-version as your operating system. ','Check connection and type (this program supports OceanOptics QE65000 (Pro), HR4000, US2000(+) USB650 (Redtide))'))
end







function [xd,D]=waveletDenoising(x,y,wtype,wentropy,lev,alpha)
if nargin<4;wentropy='shannon';end
switch wtype
    case 1
    wname = 'db10'; 
    case 2
        wname = 'db9';
    case 3;
        wname='coif5';
    otherwise
        wname='coif5';
end
    if nargin<5;lev = 10;alpha=2;end
    if nargin<6;alpha = 2;end
    tree = wpdec(y,lev,wname,wentropy);
    det1 = wpcoef(tree,2);
    sigma = median(abs(det1))/0.6745;
    alpha = 2;
    thr =wpbmpen(tree,sigma,alpha);
    keepapp = 1;
    xd = wpdencmp(tree,'s','nobest',thr,keepapp);
    D=crosscorr(x,xd);
    
    
function [inttime,maxint,minint,maxCount,spectrometerAD,Npixels,usepixels,SNratio,ActiveCooling,boxcarwidth,wavrange,NoOrUnknownSpec]=getMODELspecs(inttime,spectrometermodel,handles)
%get spectrometer specs and preset some other values (like boxcarwidth)
%also correct inttime to be between minint and maxint
%handles: dummy var

NoOrUnknownSpec=0;%assume a known detector is attached

boxcarwidth=0;%reset boxcarwidth to zero

wavrange=(200:100:1100);
if ~isempty(spectrometermodel) & ~isnan(spectrometermodel)
    
switch spectrometermodel
    case 'HR4000';
        minint=3.8/1000;maxint=10;spectrometerAD=14;Npixels=3648;SNratio='300:1 (at full Signal)';ActiveCooling=0;usepixels=(5:Npixels);
    case 'USB2000';
        minint=3/1000;maxint=65;spectrometerAD=12;Npixels=2048;SNratio='250:1 (at full Signal)';ActiveCooling=0;usepixels=(1:Npixels);
    case 'USB2000+';
        minint=1/1000;maxint=65;spectrometerAD=12;Npixels=2048;SNratio='250:1 (at full Signal)';ActiveCooling=0;usepixels=(1:Npixels);
    case 'QE65000';
        minint=8/1000;maxint=15*60;spectrometerAD=16;Npixels=1044;
        usepixels=(11:Npixels-10);%some pixel have moved from the front to the back for some reason 
        ActiveCooling=[1,30,43];%Allowed temperature range below ambient is 30-43°C!
        SNratio='1000:1 (single acquisition)';
    case 'USB650'; %RedTide
        minint=10/1000;maxint=14;%(max < 60, but detectorlimit ~15 according to manual)
        spectrometerAD=12;Npixels=650;SNratio='250:1 (at full Signal)';ActiveCooling=0;
        usepixels=(1:Npixels);
    case 'QE-PRO';
        minint=8/1000;maxint=15*60;spectrometerAD=16;Npixels=1044;
        usepixels=(11:Npixels-10);%some pixel have moved from the front to the back for some reason 
        ActiveCooling=[1,30,43];%Allowed temperature range below ambient is 30-43°C!
        SNratio='1000:1 (single acquisition)';
    otherwise
        minint=NaN;maxint=NaN;spectrometerAD=NaN;Npixels=NaN;SNratio='unknown';ActiveCooling=NaN;NoOrUnknownSpec=1;boxcarwidth=NaN;usepixels=NaN;
end
maxCount=2^spectrometerAD-1;

%override with data from spectrometer itself: Do not use because "minint"
%from e.g. HR4000 detector is not the same as the manual specs and gives
%1e-5, which gives strange readout results!
%minint=handles.wrapper.getMinimumIntegrationTime(handles.spectrometerIndex-1)./(10^(6));
%maxint=handles.wrapper.getMaximumIntegrationTime(handles.spectrometerIndex-1)./(10^(6));
% maxCount=handles.wrapper.getMaximumIntensity(handles.spectrometerIndex-1); %wrapper.getSaturationThreshold() ?
% spectrometerAD=log2((maxCount+1));
% Npixels=handles.wrapper.getNumberOfPixels(handles.spectrometerIndex-1);

if inttime<minint;inttime=minint;end
if inttime>maxint;inttime=maxint;end

else
    inttime=NaN; minint=NaN;maxint=NaN;spectrometerAD=NaN;maxCount=NaN;Npixels=NaN;SNratio='NaN';ActiveCooling=NaN;NoOrUnknownSpec=1;boxcarwidth=NaN;
end
