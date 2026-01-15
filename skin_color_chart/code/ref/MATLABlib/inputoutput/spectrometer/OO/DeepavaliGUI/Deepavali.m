function varargout = Deepavali(varargin)
% DEEPAVALI M-file for Deepavali.fig
%      DEEPAVALI, by itself, creates a new DEEPAVALI or raises the existing
%      singleton*.
%
%      H = DEEPAVALI returns the handle to a new DEEPAVALI or the handle to
%      the existing singleton*.
%
%      DEEPAVALI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in DEEPAVALI.M with the given input arguments.
%
%      DEEPAVALI('Property','Value',...) creates a new DEEPAVALI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before Deepavali_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to Deepavali_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help Deepavali

% Last Modified by GUIDE v2.5 19-Jun-2013 08:55:46

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Deepavali_OpeningFcn, ...
                   'gui_OutputFcn',  @Deepavali_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before Deepavali is made visible.
function Deepavali_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to Deepavali (see VARARGIN)

% Choose default command line output for Deepavali
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes Deepavali wait for user response (see UIRESUME)
% uiwait(handles.Deepavali);

%--------------------------------------------------------------------------
% Make clean break, clear old global variables
%--------------------------------------------------------------------------
clear global spectrometerIndex_ spectrometermodel_ spectrometerseries_ Npixels_ usepixels_ specAD_
clear global user_minint_ user_maxint_ forceinttime_ boxcarwidth_ Nscans_ togg_Darkc_ togg_Nonlin_ togg_denoise_ togg_denoise1x_ togg_ActiveCooling 
clear global calref_ darksignal_ refsignal_ stimsignal_ CALSPD_ DarkRefStim_ hcolorimetry handlesCol SPDc 
global spectrometerIndex_ spectrometermodel_ spectrometerseries_ Npixels_ usepixels_ specAD_
global user_minint_ user_maxint_ forceinttime_ boxcarwidth_ Nscans_ togg_Darkc_ togg_Nonlin_ togg_denoise_ togg_denoise1x_ togg_ActiveCooling 
global calref_ darksignal_ refsignal_ stimsignal_ CALSPD_ DarkRefStim_ hcolorimetry handlesCol SPDc 
global DetectorTemperatureDEF


%--------------------------------------------------------------------------
% Add the java methods to MATLAB
%--------------------------------------------------------------------------
% fid = fopen([cd,'\path_Omnidriverjar.txt'],'r');
% path_omnidriverjar=char(fgets(fid))
% fclose(fid); 
% javaaddpath(path_omnidriverjar);

%--------------------------------------------------------------------------
%   Create Menubar
%--------------------------------------------------------------------------
hmenubar = uimenu(hObject,'Label','Menu');
hsave1 = uimenu(hmenubar,'Label','SAVE CAL. SPD','Callback',{@fSave,1});
set(hsave1,'Separator','on');
hsave2 = uimenu(hmenubar,'Label','Save Meas. dark','Callback',{@fSave,2});
set(hsave2,'Separator','on');
hsave3 = uimenu(hmenubar,'Label','Save Meas. ref','Callback',{@fSave,3});
hsave4 = uimenu(hmenubar,'Label','Save Cal. ref','Callback',{@fSave,4});
hsave5 = uimenu(hmenubar,'Label','Save Meas. SPD','Callback',{@fSave,0});
set(hsave5,'Separator','on');
hclose = uimenu(hmenubar,'Label','Exit','Callback',@fClose);
set(hclose,'Separator','on');
%hhelp = uimenu(hObject,'Label','Help');
%habout = uimenu(hObject,'Label','About','Callback',@fAbout);
habout = uimenu(hObject,'Label','About');
habout_text0=uimenu(habout,'Label',sprintf('---------------------------------------- '));
habout_text1=uimenu(habout,'Label',sprintf('***              DEEPAVALI              *** '));
habout_text2=uimenu(habout,'Label',sprintf('---------------------------------------- '));
habout_text3=uimenu(habout,'Label',sprintf('Quick & Easy Spectral Measurements'));
habout_text4=uimenu(habout,'Label',sprintf('using Ocean Optics Spectrometers: '));
habout_text5=uimenu(habout,'Label',sprintf('USB650,USB2000,HR4000,QE65000,... '));
habout_text6=uimenu(habout,'Label',sprintf('---------------------------------------- '));
habout_text7=uimenu(habout,'Label',sprintf('version 1.0                       '));
habout_text8=uimenu(habout,'Label',sprintf('Copyright: K. Smet, June 14, 2013. '));
habout_text9=uimenu(habout,'Label',sprintf('More info: Kevin.Smet@kahosl.be   '));
habout_text10=uimenu(habout,'Label',sprintf('---------------------------------------- '));

%--------------------------------------------------------------------------
% Hide acquisition parameter setup and aquisition window 
% when no spectrometer is detected yet. 
%--------------------------------------------------------------------------
set(handles.acqui_panel,'Visible','Off');
set(handles.hide_acqui,'Visible','On');
set(handles.hide_acquipar,'Visible','On');



%--------------------------------------------------------------------------
% Hide Measurement Modes that rely on reference (not measured yet)
%--------------------------------------------------------------------------
set(handles.sel_irrsignal,'Visible','Off');
set(handles.sel_rflsignal,'Visible','Off');
set(handles.sel_transsignal,'Visible','Off');


%--------------------------------------------------------------------------
%   Create progressbar
%--------------------------------------------------------------------------
handles.deltatime=0;global deltatime_;deltatime_=handles.deltatime;
handles.spdisread=0;
handles.maxprogressbar=1;%get max of progress bar (= max of x-axis)
handles.nlevels=10;%number of levels to divide progress bar in
handles.nsublevels=20;
handles.pause_tmin=0.00;
t_levels=repmat(linspace(0,handles.maxprogressbar,handles.nlevels*handles.nsublevels),10,1);%progress bar levels
handles.srgbim=cat(3,zeros(10,handles.nlevels*handles.nsublevels),t_levels,zeros(10,handles.nlevels*handles.nsublevels));%store image





%--------------------------------------------------------------------------
% Detect all attached spectrometers, pre-select first one if it exists 
%   and preset values in display  
%--------------------------------------------------------------------------
detectconnectedspectrometers

deltatime_=handles.specminint_;handles.deltatime_=handles.specminint_;

%--------------------------------------------------------------------------
% Setup all handles.var and properties of some objects
%--------------------------------------------------------------------------
handles.wavrange=(200:100:1100);%wavelength range of OO spectrometers
handles.calref_=[];%storage for spectrum of calibrated reference source
handles.darksignal_=[];%storage for meas. signal of dark measurement
handles.refsignal_=[];%storage for meas.signal of calibrated reference source
handles.stimsignal_=[];%storage for meas. signal of stimulus
handles.CALSPD_=[];%%storage for calibrated spectrum of stimulus
handles.DarkRefStim_=[1,0,0];%shows which type is selected
handles.SPD=[];
set(handles.sel_dark,'value',1);set(handles.sel_ref,'value',0);set(handles.sel_stim,'value',0);


handles.togg_Darkc_=1;%Correct for Dark Current
set(handles.togg_Darkc,'value',handles.togg_Darkc_);
set(handles.togg_Darkc,'ForegroundColor',[1,0,0]);
handles.togg_Nonlin_=1;%Correct for detector nonlinearity
set(handles.togg_Nonlin,'value',handles.togg_Nonlin_);
set(handles.togg_Nonlin,'ForegroundColor',[1,0,0]);
handles.togg_denoise_=0;%Don't denoise (using wavelets) measured spectrum 
set(handles.togg_denoise,'value',handles.togg_denoise_);
set(handles.togg_denoise,'ForegroundColor',0.75.*[1,1,1]);
handles.togg_denoise1x_=0;%Don't denoise (using wavelets) calibrated spectrum 
set(handles.togg_denoise1x,'value',handles.togg_denoise1x_);
set(handles.togg_denoise1x,'ForegroundColor',0.75.*[1,1,1]);
%handles.togg_ActiveCooling_=0;%Activate Active Cooling (when present, assume not).
% set(handles.togg_ActiveCooling,'value',handles.togg_ActiveCooling_);
% set(handles.togg_ActiveCooling,'ForegroundColor',[1,0,0]);
% set(handles.togg_ActiveCooling,'Visible','Off');
DetectorTemperatureDEF=-20;
handles.forceinttime_=0;%don't force integration time.
set(handles.forceinttime,'value',0);
handles.boxcarwidth_=0;%no averaging of nearby pixels
set(handles.user_boxcarwidth,'string',sprintf('%1.0f',handles.boxcarwidth_));
handles.Nscans_=1;%number of scans to average before output
set(handles.Nscans,'string',sprintf('%1.0f',handles.Nscans_));


set(handles.STOPSTARTacqui,'string','START continuous acquisition');set(handles.STOPSTARTacqui,'value',0);set(handles.STOPSTARTacqui,'BackgroundColor',[0,0.498,0]);
set(handles.singlemeas,'string','Make a SINGLE acquisition and STORE in memory');set(handles.singlemeas,'BackgroundColor',[0,0,1]);

set(handles.axes_spd,'HandleVisibility','ON');axes(handles.axes_spd);%create handles to be deleted when plotting spd

%colormitry GUI
set(handles.start_colorimetryGUI,'Visible','Off');%Not ready yet, first Irr spectrum is required!
global showcolorimetry hcolorimetry handlesCol; showcolorimetry=0;hcolorimetry=[]; handlesCol=[];

guidata(hObject, handles);

convert_handlesdata2globalvars 

%start progressbar
%progressbar


% --- Outputs from this function are returned to the command line.
function varargout = Deepavali_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



% --- Executes on selection change in detectedspecs.
function detectedspecs_Callback(hObject, eventdata, handles)
% hObject    handle to detectedspecs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns detectedspecs contents as cell array
%        contents{get(hObject,'Value')} returns selected item from detectedspecs


%--------------------------------------------------------------------------
%   Get selected spectrometer type
%--------------------------------------------------------------------------
handles.spectrometerIndex=get(handles.detectedspecs,'value');
detectedspecs=get(handles.detectedspecs,'string');
handles.spectrometermodel=char(detectedspecs(handles.spectrometerIndex));

%get model and series
%global wrapper
handles.spectrometermodel=char(handles.wrapper.getName(handles.spectrometerIndex-1));
handles.spectrometerseries = char(handles.wrapper.getSerialNumber(handles.spectrometerIndex-1));

%get & write specs to display
writespecs2disp

%Store some handles in global vars
convert_handlesdata2globalvars




% --- Executes during object creation, after setting all properties.
function detectedspecs_CreateFcn(hObject, eventdata, handles)
% hObject    handle to detectedspecs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in detectspecsagain.
function detectspecsagain_Callback(hObject, eventdata, handles)
% hObject    handle to detectspecsagain (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%--------------------------------------------------------------------------
% Try and Re-detect all attached spectrometers, pre-select first one 
%   if it exists and preset values in display  
%--------------------------------------------------------------------------
detectconnectedspectrometers

%Store some handles in global vars
convert_handlesdata2globalvars


% --- Executes on button press in togg_Darkc.
function togg_Darkc_Callback(hObject, eventdata, handles)
% hObject    handle to togg_Darkc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of togg_Darkc

handles.togg_Darkc_=get(handles.togg_Darkc,'value');

button_state = get(hObject,'Value');
if button_state == get(hObject,'Max')
	% Toggle button is pressed, take appropriate action
    set(hObject,'ForegroundColor',[1 0 0]);
   ...
elseif button_state == get(hObject,'Min')
	% Toggle button is not pressed, take appropriate action
    set(hObject,'ForegroundColor',0.75.*[1 1 1]);
    ...
end

global togg_Darkc_; togg_Darkc_=handles.togg_Darkc_;
guidata(hObject,handles);




% --- Executes on button press in togg_Nonlin.
function togg_Nonlin_Callback(hObject, eventdata, handles)
% hObject    handle to togg_Nonlin (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of togg_Nonlin

handles.togg_Nonlin_=get(handles.togg_Nonlin,'value');

button_state = get(hObject,'Value');
if button_state == get(hObject,'Max')
	% Toggle button is pressed, take appropriate action
    set(hObject,'ForegroundColor',[1 0 0]);
   ...
elseif button_state == get(hObject,'Min')
	% Toggle button is not pressed, take appropriate action
    set(hObject,'ForegroundColor',0.75.*[1 1 1]);
    ...
end

global togg_Nonlin_; togg_Nonlin_=handles.togg_Nonlin_;
guidata(hObject,handles);



% --- Executes on button press in togg_ActiveCooling.
function togg_ActiveCooling_Callback(hObject, eventdata, handles)
% hObject    handle to togg_ActiveCooling (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of togg_ActiveCooling

global spectrometerIndex_ DetectorTemperatureDEF DetectorTemperature display

handles.togg_ActiveCooling_=get(handles.togg_ActiveCooling,'value');

button_state = get(hObject,'Value');
if button_state == get(hObject,'Max')
	% Toggle button is pressed, take appropriate action
    set(hObject,'ForegroundColor',[1 0 0]);
    set(handles.togg_ActiveCooling,'string','Active Cooling on');
    DetectorTemperature=DetectorTemperatureDEF;
     
    
   ...
elseif button_state == get(hObject,'Min')
	% Toggle button is not pressed, take appropriate action
    set(hObject,'ForegroundColor',0.75.*[1 1 1]);
    set(handles.togg_ActiveCooling,'string','Active Cooling off');
    DetectorTemperature=NaN;
    ...
end


 %IMPORT JAVA class
    import('com.oceanoptics.omnidriver.api.wrapper.Wrapper')
    % Create a new instance of the API object assignin(ws, 'var', val)

    %clear wrapper;
    wrapper = Wrapper();assignin('base', 'wrapper', Wrapper());

    % --------------------------------------------------------------------------
    % Open all attached spectrometers
    % --------------------------------------------------------------------------

    numoospec = wrapper.openAllSpectrometers();
   
    if numoospec~=-1; %at least one spectrometer detected

    spectrometerIndex=spectrometerIndex_-1;
    
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
            while actualTemperature>1;
                actualTemperature = tecController.getDetectorTemperatureCelsius();
            end; % call several times to avoid bug described in manual
%             if display==1;
%                 disp(sprintf('Active Cooling on. DetectorTemperature at %1.2f °C',actualTemperature))
%             end
             disp(sprintf('Active Cooling on. DetectorTemperature at %1.2f °C',actualTemperature))
        else
            tecController.setTECEnable(logical(0));
            tecController.setFanEnable(logical(0)); % turn the fan on (optional)
            disp('Active Cooling Off')
%             actualTemperature = tecController.getDetectorTemperatureCelsius();
%             if display==1;
%                 disp(sprintf('Active Cooling off. DetectorTemperature at %1.2f °C',actualTemperature))
%             end
        end
        
    end
    getboardtemperature_script
    end




guidata(hObject,handles);


function user_minint_Callback(hObject, eventdata, handles)
% hObject    handle to user_minint (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of user_minint as text
%        str2double(get(hObject,'String')) returns contents of user_minint as a double
handles.user_minint_=str2double(get(handles.user_minint,'string'));
global forceinttime_ user_minint_ user_maxint_ specmaxint_ specminint_;user_minint_=handles.user_minint_;
if forceinttime_==0;
    if abs(user_minint_)>user_maxint_;user_minint_=sign(user_minint_).*abs(user_maxint_);handles.user_minint_=user_minint_;end
    handles.user_minint_=-abs(handles.user_minint_);user_minint_=-abs(user_minint_);
else
    handles.user_minint_=abs(handles.user_minint_);user_minint_=abs(user_minint_);
    user_maxint_=user_minint_;set(handles.user_maxint,'string',sprintf('%1.6f',user_maxint_));
end;%if not forced, let function search optimum inttime
user_maxint_(user_maxint_>=specmaxint_)=specmaxint_;user_maxint_(user_maxint_<=specminint_)=specminint_;
user_minint_(user_minint_>=specmaxint_ & user_minint_~=0)=specminint_;user_minint_(user_minint_<=specminint_ & user_minint_~=0)=specminint_;
set(handles.user_minint,'string',sprintf('%1.6g',abs(user_minint_)));
set(handles.user_maxint,'string',sprintf('%1.6g',user_maxint_));




guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function user_minint_CreateFcn(hObject, eventdata, handles)
% hObject    handle to user_minint (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function user_maxint_Callback(hObject, eventdata, handles)
% hObject    handle to user_maxint (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of user_maxint as text
%        str2double(get(hObject,'String')) returns contents of user_maxint as a double
handles.user_maxint_=str2double(get(handles.user_maxint,'string'));
global specmaxint_ specminint_;
global user_maxint_;user_maxint_=handles.user_maxint_;
global forceinttime_ user_minint_ ;
if forceinttime_==1;
    handles.user_minint_=abs(handles.user_maxint_);user_minint_=abs(user_maxint_);
    %set(handles.user_minint,'string',sprintf('%1.6g',user_minint_));
else
    if abs(user_minint_)>user_maxint_;user_minint_=sign(user_minint_).*abs(user_maxint_);end
    handles.user_minint_=-abs(handles.user_minint_);user_minint_=-abs(user_minint_);
    %set(handles.user_minint,'string',sprintf('%1.6g',abs(user_minint_)));
end

user_maxint_(user_maxint_>=specmaxint_)=specmaxint_;user_maxint_(user_maxint_<=specminint_)=specminint_;
user_minint_(user_minint_>=specmaxint_ & user_minint_~=0)=specminint_;user_minint_(user_minint_<=specminint_ & user_minint_~=0)=specminint_;
set(handles.user_minint,'string',sprintf('%1.6g',abs(user_minint_)));
set(handles.user_maxint,'string',sprintf('%1.6g',user_maxint_));
guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function user_maxint_CreateFcn(hObject, eventdata, handles)
% hObject    handle to user_maxint (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in forceinttime.
function forceinttime_Callback(hObject, eventdata, handles)
% hObject    handle to forceinttime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of forceinttime
handles.forceinttime_=get(handles.forceinttime,'value');
global forceinttime_ user_minint_ user_maxint_ specminint_ specmaxint_;forceinttime_=handles.forceinttime_;
if forceinttime_==1;
    handles.user_minint_=abs(handles.user_minint_);user_minint_=abs(user_minint_);
    user_maxint_=user_minint_;set(handles.user_maxint,'string',sprintf('%1.6g',user_maxint_));
    set(handles.user_minint,'string',sprintf('%1.6g',user_minint_));
else
    handles.user_minint_=-abs(handles.user_minint_);user_minint_=-abs(user_minint_);
    user_maxint_=10*specminint_;set(handles.user_maxint,'string',sprintf('%1.6g',user_maxint_));
end;%force function to use user_inttime as given

user_maxint_(user_maxint_>=specmaxint_)=specmaxint_;user_maxint_(user_maxint_<=specminint_)=specminint_;
user_minint_(user_minint_>=specmaxint_ & user_minint_~=0)=specminint_;user_minint_(user_minint_<=specminint_ & user_minint_~=0)=specminint_;
set(handles.user_minint,'string',sprintf('%1.6g',abs(user_minint_)));
set(handles.user_maxint,'string',sprintf('%1.6g',user_maxint_));

guidata(hObject,handles);


function user_boxcarwidth_Callback(hObject, eventdata, handles)
% hObject    handle to user_boxcarwidth (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of user_boxcarwidth as text
%        str2double(get(hObject,'String')) returns contents of user_boxcarwidth as a double
handles.boxcarwidth_=str2double(get(handles.user_boxcarwidth,'string'));
global boxcarwidth_;boxcarwidth_=handles.boxcarwidth_;
guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function user_boxcarwidth_CreateFcn(hObject, eventdata, handles)
% hObject    handle to user_boxcarwidth (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function sel_dark_Callback(hObject, eventdata, handles)
% hObject    handle to sel_dark(see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of sel_dark as text
%        str2double(get(hObject,'String')) returns contents of sel_dark as a double

%--------------------------------------------------------------------------
%   Measurent of dark stimulus 
%--------------------------------------------------------------------------
handles.sel_dark_=get(handles.sel_dark,'value');
set(handles.sel_dark,'value',1);set(handles.sel_ref,'value',0);set(handles.sel_stim,'value',0);
handles.DarkRefStim_=[1,0,0];
global DarkRefStim_;DarkRefStim_=handles.DarkRefStim_;
handles.darksignal_=[];%reset dark measurement and ref and stim
handles.refsignal_=[];
handles.stimsignal_=[];
global darksignal_ refsignal_ stimsignal_ signal_ CALSPD_ ;
darksignal_=handles.darksignal_;
refsignal_=handles.refsignal_;
stimsignal_=handles.stimsignal_;
CALSPD_=[];
signal_=[];
%set(handles.cal_ref_file_,'string','enter '''?''' for info');

%--------------------------------------------------------------------------
% Hide Measurement Modes that rely on reference --> reset
%--------------------------------------------------------------------------
set(handles.sel_irrsignal,'Visible','Off');
set(handles.sel_rflsignal,'Visible','Off');
set(handles.sel_transsignal,'Visible','Off');
set(handles.start_colorimetryGUI,'visible','off');

delete(get(handles.axes_spd,'Children'))

guidata(hObject,handles);


function sel_ref_Callback(hObject, eventdata, handles)
% hObject    handle to sel_ref (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of sel_ref as text
%        str2double(get(hObject,'String')) returns contents of sel_ref as a double

%--------------------------------------------------------------------------
%   Measurement of reference source 
%--------------------------------------------------------------------------
handles.sel_ref_=get(handles.sel_ref,'value');
set(handles.sel_dark,'value',0);set(handles.sel_ref,'value',1);set(handles.sel_stim,'value',0);
handles.DarkRefStim_=[0,1,0];
global DarkRefStim_;DarkRefStim_=handles.DarkRefStim_;
handles.refsignal_=[];%reset reference measurement
global refsignal_;refsignal_=handles.refsignal_;
guidata(hObject,handles);

function sel_stim_Callback(hObject, eventdata, handles)
% hObject    handle to sel_stim (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of sel_stim as text
%        str2double(get(hObject,'String')) returns contents of sel_stim as a double

%--------------------------------------------------------------------------
%   Measurement of stimulus source 
%--------------------------------------------------------------------------
handles.sel_stim_=get(handles.sel_stim,'value');
set(handles.sel_dark,'value',0);set(handles.sel_ref,'value',0);set(handles.sel_stim,'value',1);
handles.DarkRefStim_=[0,0,1];
global DarkRefStim_;DarkRefStim_=handles.DarkRefStim_;
handles.stimsignal_=[];%reset stimulus measurement
global stimsignal_;stimsignal_=handles.stimsignal_;
guidata(hObject,handles);




function calref_file_Callback(hObject, eventdata, handles)
% hObject    handle to calref_file (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of calref_file as text
%        str2double(get(hObject,'String')) returns contents of calref_file as a double

%--------------------------------------------------------------------------
%   Get calibrated reference source data
%--------------------------------------------------------------------------
handles.calref_file_=get(handles.calref_file,'string');
if sum(ismember('?',handles.calref_file_))>0;
    message='enter CALIBRATION file or CCT (end with K) or push load button.';
    set(handles.messages,'String',message);set(handles.messages,'ForegroundColor',[1,0,0]);set(handles.messages,'Visible','on');
    if ~exist('calref_','var');global calref_; calref_=[];end
else
if (upper(handles.calref_file_(end))~='K');
    if handles.calref_file_(2:3)~=':\';handles.calref_file_=[cd,'\',handles.calref_file_];end %assume no path and file is in current directory
    handles.calref_=dlmread(handles.calref_file_);
    set(handles.messages,'string',sprintf('%s loaded as reference source!',handles.calref_file_));
else
    CCT=str2double(handles.calref_file_(1:end-1));
    if sign(CCT)>0;handles.calref_=blackbodySPD(abs(CCT),360,830);reftype='Blackbody radiator';end%use blackbody as reference
    if sign(CCT)<0;handles.calref_=daylightSPD(abs(CCT),360,830);reftype='Daylight phase';end%use daylight as reference
    handles.calref_(:,2)=handles.calref_(:,2)./handles.calref_(handles.calref_(:,1)==560,2);if abs(CCT)<=4000;reftype='Blackbody radiator';end;%(sum(handles.calref_(:,2)).*abs(handles.calref_(1,1)-handles.calref_(2,1)));
    set(handles.messages,'string',sprintf('%s of %1.0f K calculated as reference source!',reftype,abs(CCT)));
end
global calref_; calref_=handles.calref_;

global darksignal_ refsignal_ stimsignal_;
DarkRef_measured = double(~isempty(darksignal_) & ~isempty(refsignal_));%test whether dark and ref have been measured and stored

%Detect measurement mode
if DarkRef_measured==1
    if ~isempty(calref_)%ensure that data of calibrated ref source is loaded!
        set(handles.sel_irrsignal,'Visible','On');
        if ~isempty(stimsignal_);set(handles.start_colorimetryGUI,'visible','on');end
    else
        set(handles.sel_irrsignal,'Visible','Off');
    end
    set(handles.sel_rflsignal,'Visible','On');
    set(handles.sel_transsignal,'Visible','On');
else
    set(handles.sel_irrsignal,'Visible','Off');
    set(handles.sel_rflsignal,'Visible','Off');
    set(handles.sel_transsignal,'Visible','Off');
end
end


guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function calref_file_CreateFcn(hObject, eventdata, handles)
% hObject    handle to calref_file (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in loadreffile.
function loadreffile_Callback(hObject, eventdata, handles)
% hObject    handle to loadreffile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%--------------------------------------------------------------------------
%   Get calibrated reference source data by browsing for it
%--------------------------------------------------------------------------
[calreffile1,pathname]=uigetfile({'*.xls;*.xlsx;*.txt;*.dat','Data files (*.xls,*.xlsx,*.txt,*.dat)'},'Select spectral data of calibrated reference source');
ext=calreffile1(end-2:end);
handles.calref_file_=[char(pathname),'\',char(calreffile1)];
switch ext
    case 'xls'
        handles.calref_=xlsread(handles.calref_file_);
    case 'lsx'
        handles.calref_=xlsread(handles.calref_file_);
    otherwise
        handles.calref_=dlmread(handles.calref_file_);
end
global calref_;calref_=handles.calref_;
guidata(hObject,handles);







% --- Executes on button press in togg_denoise.
function togg_denoise_Callback(hObject, eventdata, handles)
% hObject    handle to togg_denoise (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of togg_denoise
handles.togg_denoise_=get(handles.togg_denoise,'value');
global togg_denoise_;togg_denoise_=handles.togg_denoise_;

button_state = get(hObject,'Value');
if button_state == get(hObject,'Max')
	% Toggle button is pressed, take appropriate action
    set(hObject,'ForegroundColor',[1 0 0]);
   ...
elseif button_state == get(hObject,'Min')
	% Toggle button is not pressed, take appropriate action
    set(hObject,'ForegroundColor',0.75.*[1 1 1]);
    ...
end

guidata(hObject,handles);


% --- Executes on button press in togg_denoise1x.
function togg_denoise1x_Callback(hObject, eventdata, handles)
% hObject    handle to togg_denoise1x (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of togg_denoise1x
handles.togg_denoise1x_=get(handles.togg_denoise1x,'value');
global togg_denoise1x_;togg_denoise1x_=handles.togg_denoise1x_;

button_state = get(hObject,'Value');
if button_state == get(hObject,'Max')
	% Toggle button is pressed, take appropriate action
    set(hObject,'ForegroundColor',[1 0 0]);
   ...
elseif button_state == get(hObject,'Min')
	% Toggle button is not pressed, take appropriate action
    set(hObject,'ForegroundColor',0.75.*[1 1 1]);
    ...
end

guidata(hObject,handles);


% --- Executes on button press in STOPSTARTacqui.
function STOPSTARTacqui_Callback(hObject, eventdata, handles)
% hObject    handle to STOPSTARTacqui (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of STOPSTARTacqui
handles.STOPSTART=get(handles.STOPSTARTacqui,'value');%0=start on top, 1=stop
global STOPSTART_;STOPSTART_=handles.STOPSTART;
switch STOPSTART_
    case 0
        STOPSTART_=0;
        set(handles.STOPSTARTacqui,'string','START continuous acquisition');
        set(handles.STOPSTARTacqui,'BackgroundColor',[0,0.498,0]);
        set(handles.singlemeas,'Visible','On');
        message='';set(handles.messages,'String',message);set(handles.messages,'ForegroundColor',[1,0,0]);set(handles.messages,'Visible','on');

    case 1
        STOPSTART_=1;
        set(handles.STOPSTARTacqui,'string','STOP continuous acquisition');
        set(handles.STOPSTARTacqui,'BackgroundColor',[1,0,0]);
        set(handles.singlemeas,'Visible','Off');
end

guidata(hObject,handles);


%IMPORT JAVA class
import('com.oceanoptics.omnidriver.api.wrapper.Wrapper')
% Create a new instance of the API object assignin(ws, 'var', val)

%clear wrapper;
wrapper = Wrapper();assignin('base', 'wrapper', Wrapper());

% --------------------------------------------------------------------------
% Open all attached spectrometers
% --------------------------------------------------------------------------

numoospec = wrapper.openAllSpectrometers();

global  deltatime_;i=0;%for progressbar
while (get(hObject,'Max') == get(hObject,'Value'))
        
       
      getspdfromOOandplot 
     
      global hDeepavali;figure(hDeepavali);
    
%     switch handles.STOPSTART
%     case 1 %called from STARTSTOP continuous acquisition
%         integrationtime=abs(handles.user_minint_);%don't look for optimimum
%     case 0 % called from single measurement
%         integrationtime=handles.user_minint_;
%     end
%     
%     
%     %--------------------------------------------------------------------------
%     %   Configure ReadOut parameters & get SPD
%     %--------------------------------------------------------------------------
%     Nes=handles.spectrometerIndex;
%     IntegrationTime=integrationtime
%     NScans=handles.Nscans_
%     DarkFlag=handles.togg_Darkc_;
%     NonlinearityFlag=handles.togg_Nonlin_;
%     boxcarwidth=handles.boxcarwidth_;
%     wtype='coif5';
%     spectrometerIndex=Nes-1;
%     
%     wrapper.setIntegrationTime(spectrometerIndex,IntegrationTime);
%     wrapper.setCorrectForDetectorNonlinearity(spectrometerIndex,NonlinearityFlag);
%     wrapper.setCorrectForElectricalDark(spectrometerIndex,DarkFlag);
%     wrapper.setScansToAverage(spectrometerIndex,NScans);
%     wrapper.setBoxcarWidth(spectrometerIndex,boxcarwidth);
%     wavelengths0 = wrapper.getWavelengths(spectrometerIndex);
%     tic
%     spectralData0 = wrapper.getSpectrum(spectrometerIndex);
%     t1=toc
%     spectralData0=spectralData0./IntegrationTime;
%     
%     % DeNoise Spectrum values using wavelets: 
%     % "De-Noising Audio Signals Using MATLAB Wavelets Toolbox" by Villanueva-Luna
%     if nargin<8;wtype='coif5';end%most symmetrical of coif5, db9 or db10
%     
%     if handles.togg_denoise==1
%         wentropy='log energy';
%         spectralData_denoised=waveletDenoising(wavelengths0,spectralData0,wtype,wentropy);
%         SPDdn=[wavelengths0,spectralData_denoised];
%     end
%     t2=toc
%     tic,
%     SPD=[wavelengths0,spectralData0];
%         
%     t3=toc
%     
%     tic
%     set(handles.axes_spd,'HandleVisibility','ON'); 
%     axes(handles.axes_spd);
% 
%     %delete previous plot
% %     if ~isempty(hspd);delete(hspd);end
% %     if ~isempty(hspddn);delete(hspddn);end
% 
%     %make new plot
%     hspd=plot(SPD(:,1),SPD(:,2),'b-');
%     hold on;
%     if handles.togg_denoise_==1;
%         hspddn=plot(SPDdn(:,1),SPDdn(:,2),'r-');
%     end
%     hold off;
%     t4=toc
%     pause(0.01);
end

%reset progressbar
srgbim_level_i=handles.srgbim;srgbim_level_i(:,:,:)=0;
set(handles.axes_progress_,'HandleVisibility','ON'); 
axes(handles.axes_progress_);
imagesc(srgbim_level_i);axis off; axis equal;axis image

guidata(hObject,handles);


% --- Executes on button press in singlemeas.
function singlemeas_Callback(hObject, eventdata, handles)
% hObject    handle to singlemeas (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.singlemeas,'Visible','Off');pause(0.05);

handles.STOPSTART=0;%0=start on top, 1=stop
global STOPSTART_;STOPSTART_=handles.STOPSTART;
switch STOPSTART_
    case 0
        set(handles.STOPSTARTacqui,'string','START continuous acquisition');
        set(handles.STOPSTARTacqui,'BackgroundColor',[0,0.498,0]);
    case 1
        set(handles.STOPSTARTacqui,'string','STOP continuous acquisition');
        set(handles.STOPSTARTacqui,'BackgroundColor',[1,0,0]);
end


%IMPORT JAVA class
import('com.oceanoptics.omnidriver.api.wrapper.Wrapper')
% Create a new instance of the API object assignin(ws, 'var', val)

%clear wrapper;
wrapper = Wrapper();assignin('base', 'wrapper', Wrapper());

% --------------------------------------------------------------------------
% Open all attached spectrometers
% --------------------------------------------------------------------------

numoospec = wrapper.openAllSpectrometers();

global deltatime_;i=0;%for progressbar

if STOPSTART_==0;
    getspdfromOOandplot
end

%reset progressbar
srgbim_level_i=handles.srgbim;srgbim_level_i(:,:,:)=0;
set(handles.axes_progress_,'HandleVisibility','ON'); 
axes(handles.axes_progress_);
imagesc(srgbim_level_i);axis off; axis equal;axis image

guidata(hObject,handles);

pause(0.05);%to ensure the button isn't pressed again 
set(handles.singlemeas,'Visible','On');




function Nscans_Callback(hObject, eventdata, handles)
% hObject    handle to Nscans (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Nscans as text
%        str2double(get(hObject,'String')) returns contents of Nscans as a double
handles.Nscans_=str2double(get(handles.Nscans,'string'));
global Nscans_;Nscans_=handles.Nscans_;
guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function Nscans_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Nscans (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function fClose(hObject, eventdata)
close(gcf);

function fSave(hObject, eventdata,indexnr)
global CALSPD_ calref_ darksignal_ refsignal_ stimsignal_ togg_denoised_

[FileName,PathName,FilterIndex] = uiputfile;
savefile = strcat(PathName,FileName);
if togg_denoised_==1;savefile=[savefile(1:end-4),'_denoised',savefile(end-3:end)];end
switch indexnr
    case 0
        dlmwrite(savefile,stimsignal_,'delimiter','\t','precision','%1.6g');
    case 1
        dlmwrite(savefile,CALSPD_,'delimiter','\t','precision','%1.6g');
    case 2
        dlmwrite(savefile,darksignal_,'delimiter','\t','precision','%1.6g');
    case 3
        dlmwrite(savefile,refsignal_,'delimiter','\t','precision','%1.6g');
   case 4
        dlmwrite(savefile,calref_,'delimiter','\t','precision','%1.6g');
end      
if togg_denoised_==1;savefile=[savefile(1:end-4),'_denoised',savefile(end-3:end)];end



% --- Executes on button press in start_colorimetryGUI.
function start_colorimetryGUI_Callback(hObject, eventdata, handles)
% hObject    handle to start_colorimetryGUI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global hDeepavali showcolorimetry hcolorimetry  handlesCol srgbPT;
showcolorimetry=abs(showcolorimetry-1); 

button_state = get(hObject,'Value');
if button_state == get(hObject,'Max')
	% Toggle button is pressed, take appropriate action
    set(hObject,'ForegroundColor',[1 0 0]);
    
   ...
elseif button_state == get(hObject,'Min')
	% Toggle button is not pressed, take appropriate action
    set(hObject,'ForegroundColor',0.75.*[1 1 1]);
   
end

if showcolorimetry==1;
    calcmetrics=1;
    hcolorimetry=colorimetry();pause(0.05)
    handlesCol=guihandles(hcolorimetry)
    colorimetry_uvY_backgroundaxes_script;
    colorimetry_script
else; hcolorimetry=[];
    if exist('hcolorimetry','var');
        if ~isempty(hcolorimetry);
            close(hcolorimetry);
            global hcolorimetry;hcolorimetry=[];
        end;
    end
end
figure(hDeepavali);
