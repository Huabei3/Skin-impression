%--------------------------------------------------------------------------
% Open all attached spectrometers
%--------------------------------------------------------------------------
import('com.oceanoptics.omnidriver.api.wrapper.Wrapper')
% Create a new instance of the API object assignin(ws, 'var', val)

%clear wrapper;
wrapper = Wrapper();assignin('base', 'wrapper', Wrapper());
handles.wrapper=wrapper;
global wrapper_;wrapper_=handles.wrapper;

handles.spectrometerIndex=[];handles.spectrometermodel=NaN;handles.spectrometerseries=NaN;%assume no spectrometers are connect

numoospec=0;oospecnames=[];numoospec = handles.wrapper.openAllSpectrometers();%open all attached spectrometers

handles.numberofdetectedspectrometers=numoospec;

if  numoospec>0;
    
       %create array with detected spectrometers
       oospecnames=[];
       for i=1:numoospec;
           oospecnames{i}=char(handles.wrapper.getName(i-1));
       end
       handles.specnames_=oospecnames;
    
       %autoselect first spectrometer
       handles.spectrometerIndex=1;
              
       message=sprintf('At least one spectrometer detected. #1 selected by default. Set Acquisition \n parameters and collect a DARK measurement (use "SINGLE acquisition"!). '); 
       set(handles.messages,'string',message);
       
       set(handles.detectedspecs,'string',handles.specnames_);
       set(handles.detectedspecs,'value',handles.spectrometerIndex);
       
       
       %get model and series
        %global wrapper
        handles.spectrometermodel=char(handles.wrapper.getName(handles.spectrometerIndex-1));
        handles.spectrometerseries = char(handles.wrapper.getSerialNumber(handles.spectrometerIndex-1));

       %get & write specs to display
       writespecs2disp
       
       
       
       %show acquisition parameters and window
        set(handles.acqui_panel,'Visible','On');
        set(handles.hide_acqui,'Visible','Off');
        set(handles.hide_acquipar,'Visible','Off');
        
        
    %--------------------------------------------------------------------------
    %   Turn Off Active Cooling
    %--------------------------------------------------------------------------
    spectrometerIndex=0;
    handles.spectrometerIndex;global DetectorTemperature;DetectorTemperature=NaN;
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

        else
            tecController.setTECEnable(logical(0));
            tecController.setFanEnable(logical(0)); % turn the fan on (optional)

        end
    end
    
   
else
       set(handles.detectedspecs,'string','None');
       set(handles.detectedspecs,'value',1);
        
       %get & write empty specs to display (even when no detector is found)
       writespecs2disp
    
       message=sprintf('NO spectrometer detected. Connect one and hit "Detect Again".'); 
       set(handles.messages,'string',message);
       
       set(handles.acqui_panel,'Visible','Off');
        set(handles.hide_acqui,'Visible','On');
        set(handles.hide_acquipar,'Visible','On');
end

global spectrometerIndex_ spectrometermodel_ spectrometerseries_;
spectrometerIndex_=handles.spectrometerIndex;spectrometermodel_=handles.spectrometermodel;spectrometeseries_=handles.spectrometerseries;

guidata(hObject,handles);

