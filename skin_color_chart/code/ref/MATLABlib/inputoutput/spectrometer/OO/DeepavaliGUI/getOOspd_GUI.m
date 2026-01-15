%script: getOOspd(wrapper,Nes,IntegrationTime,Nscans,DarkFlag,NonlinearityFlag,boxcarwidth,wtype);
%Obtains one spectrum (averaged over Nscans).


spectrometerIndex=spectrometerIndex_-1;
IntegrationTime=integrationtime;
Nscans=Nscans_;
DarkFlag=togg_Darkc_;
NonlinearityFlag=togg_Nonlin_;
boxcarwidth=boxcarwidth_;
specAD=specAD_;

IntegrationTime_in=IntegrationTime;


%--------------------------------------------------------------------------
%   Display Device Information
%--------------------------------------------------------------------------

oospecname = handles.wrapper.getName(spectrometerIndex);
oospecsn = handles.wrapper.getSerialNumber(spectrometerIndex);

IntegrationTime=abs(IntegrationTime);
%[IntegrationTime,specsmaxint,minint,maxCount]=COMPLYwithMODELspecs(IntegrationTime,oospecname.char,0);
[dummy,specsmaxint,minint,maxCount,specAD,Npixels_,usepixels_]=getMODELspecs(0,oospecname.char,handles);
maxint=min([specsmaxint,user_maxint_]);

%--------------------------------------------------------------------------
%   Start configuration of ReadOut parameters
%--------------------------------------------------------------------------

%numberOfPixels = wrapper.getNumberOfPixels(spectrometerIndex);
handles.wrapper.setBoxcarWidth(spectrometerIndex,boxcarwidth);



    %--------------------------------------------------------------------------
    %   Set Detector Temperature if applicable and requested (e.g. for QE65000)
    %--------------------------------------------------------------------------
    global DetectorTemperature 
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
%             for i=1:10;actualTemperature = tecController.getDetectorTemperatureCelsius();end; % call several times to avoid bug described in manual
%             if display==1;
%                 disp(sprintf('Active Cooling on. DetectorTemperature at %1.2f °C',actualTemperature))
%             end
        else
            tecController.setTECEnable(logical(0));
            tecController.setFanEnable(logical(0)); % turn the fan on (optional)
%             actualTemperature = tecController.getDetectorTemperatureCelsius();
%             if display==1;
%                 disp(sprintf('Active Cooling off. DetectorTemperature at %1.2f °C',actualTemperature))
%             end
        end
    end






%--------------------------------------------------------------------------
% If entered IntegrationTime <=0; find optimal integration time
%--------------------------------------------------------------------------
Pr_maxcount=0.9; % stay a minimum of 0.9 away from maxCount of spectrometer to avoid saturation
   
if IntegrationTime_in <= 0
    if IntegrationTime_in<0;MaxIntTime_user=abs(user_maxint_);IntegrationTime=minint;else;MaxIntTime_user=0;end %limit max inttime to user defined value
    handles.wrapper.setIntegrationTime(spectrometerIndex,IntegrationTime*(10^6));%native integrationtime of OO spectrometers = µs (not s as in this function!)
    handles.wrapper.setCorrectForElectricalDark(spectrometerIndex,DarkFlag);
    handles.wrapper.setCorrectForDetectorNonlinearity(spectrometerIndex,NonlinearityFlag);
    handles.wrapper.setScansToAverage(spectrometerIndex,1);
    counts_ = double(handles.wrapper.getSpectrum(spectrometerIndex));counts_=counts_(usepixels_);maxcount=max(counts_);
    issaturated=handles.wrapper.isSaturated(spectrometerIndex);
    
    if issaturated>0 | sum(maxcount>=maxCount.*Pr_maxcount)>0;error(sprintf('Saturation at minimum IntegrationTime of %1.5f s',IntegrationTime));return,end

    SearchMaxIntTime_fullscript
    
    
    %[IntegrationTime]=COMPLYwithMODELspecs(IntegrationTime,oospecname.char,0);
    [IntegrationTime]=getMODELspecs(IntegrationTime,oospecname.char,handles);
end


%--------------------------------------------------------------------------
% ReadOut and automic dataprocessing of final spectrum
%--------------------------------------------------------------------------
if STOPSTART_==1;else;if IntegrationTime_in<=0;message=sprintf('Optimal integration time found: %1.4fs. Measuring spectrum...',IntegrationTime);set(handles.messages,'String',message);pause(0.001);end;end
handles.user_minint_=IntegrationTime;user_minint_=handles.user_minint_;set(handles.user_minint,'string',sprintf('%1.6f',user_minint_));

handles.wrapper.setCorrectForElectricalDark(spectrometerIndex,DarkFlag); 
handles.wrapper.setCorrectForDetectorNonlinearity(spectrometerIndex,NonlinearityFlag);
handles.wrapper.setScansToAverage(spectrometerIndex,Nscans);
wavelengths0 = handles.wrapper.getWavelengths(spectrometerIndex);wavelengths0=wavelengths0(usepixels_);
handles.wrapper.setIntegrationTime(spectrometerIndex,IntegrationTime*(10^6));
spectralData0 = handles.wrapper.getSpectrum(spectrometerIndex);spectralData0=spectralData0(usepixels_);
issaturated=handles.wrapper.isSaturated(spectrometerIndex);
while issaturated==1 & IntegrationTime_in <= 0;%just in case setting the detector nonlinearity etc, cause saturation, but only when a fixed IntTime is not requested!
    IntegrationTime=IntegrationTime*1000/1050;
    handles.wrapper.setIntegrationTime(spectrometerIndex,IntegrationTime*(10^6));
    spectralData0 = handles.wrapper.getSpectrum(spectrometerIndex);spectralData0=spectralData0(usepixels_);
    issaturated=handles.wrapper.isSaturated(spectrometerIndex);
end

handles.user_minint_=IntegrationTime;user_minint_=handles.user_minint_;set(handles.user_minint,'string',sprintf('%1.6f',user_minint_));

IntegrationTime_=wrapper.getIntegrationTime(spectrometerIndex); %gives different value from IntegrationTime ??????
    

%check for possible saturation of signal
issaturated=handles.wrapper.isSaturated(spectrometerIndex);if issaturated==1;warning(sprintf('Saturation at user defined IntegrationTime of %1.5f s',IntegrationTime));end
if issaturated>0;issaturatedmessage='Saturated Signal Detected!';else;issaturatedmessage=[];end

spectralData0=spectralData0./IntegrationTime;%NOG CHECKEN OF spectraData0 NU AL GECORRIGEERD IS VOOR DE INT_TIJD OF NIET!!!
SPD=[wavelengths0,spectralData0];

% DeNoise Spectrum values using wavelets: 
% "De-Noising Audio Signals Using MATLAB Wavelets Toolbox" by Villanueva-Luna
%most symmetrical of coif5, db9 or db10
% if togg_denoise_==1;
%     wentropy='shannon';
%     spectralData_denoised=waveletDenoising(wavelengths0,spectralData0,wtype,wentropy);pause(0.05);
%     SPDdn=[wavelengths0,spectralData_denoised];
% end





