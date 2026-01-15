global spectrometerIndex_ spectrometermodel_ spectrometerseries_ usepixels_ Npixels_ specAD_
global user_minint_ user_maxint_ forceinttime_ boxcarwidth_ Nscans_ togg_Darkc_ togg_Nonlin_ togg_denoise_ togg_denoise1x_ togg_ActiveCooling
global calref_ darksignal_ refsignal_ stimsignal_ CALSPD_ DarkRefStim_  signal_ DarkRef_measured STOPSTART_ 

%--------------------------------------------------------------------------
%   Setup measurement: set format of integrationTime
%--------------------------------------------------------------------------

switch STOPSTART_
    case 1 %called from STARTSTOP continuous acquisition
        integrationtime=abs(user_minint_);%don't look for optimimum
    case 0 % called from single measurement
        integrationtime=user_minint_;
end

spdisread_=0;%spd is not read yet

if STOPSTART_==0;message='Measuring spectrum...';set(handles.messages,'String',message);set(handles.messages,'ForegroundColor',[1,0,0]);set(handles.messages,'Visible','on');end

%--------------------------------------------------------------------------
%   Make measurement: ==> getOOspd_GUI
%   or : [SPDdn,SPD]=getOOspd(-1,handles.spectrometerIndex,integrationtime,handles.Nscans_,handles.togg_Darkc_,handles.togg_Nonlin_,handles.boxcarwidth_);
%--------------------------------------------------------------------------
tic,
getOOspd_GUI
deltatime_=toc;%time to make one measurement

tel=0;progressbar; %show progressbar

spdisread_=1;%spd is not read 
message=['Finished with spectral measurement.',issaturatedmessage];set(handles.messages,'String',message);set(handles.messages,'ForegroundColor',[1,0,0]);set(handles.messages,'Visible','on');pause(0.001);
if STOPSTART_==1;
    message='Real-time measurements.';set(handles.messages,'String',message);set(handles.messages,'ForegroundColor',[1,0,0]);set(handles.messages,'Visible','on');;
end

handles.SPD=SPD;%store measurement in handles structure
signal_=SPD;
% %DENOISE using wavelets (or not)
% if togg_denoise_==1;
%     handles.SPDdn=SPDdn;
% 
%     signal_=SPDdn;%store for further calculations: use denoised spectrum
%     signal_x=SPD;
% %     SPDc=SPD;SPDc(:,2)=SPDc(:,2).*abs(integrationtime);
% %     SPDdnc=SPDdn;SPDdnc(:,2)=SPDdnc(:,2).*abs(integrationtime);%get counts (not counts/s)
% else
%     handles.SPDdn=[];
%     signal_=SPD;%store for further calculations
%     signal_x=NaN;%no denoised spectrum
% %     SPDc=SPD;SPDc(:,2)=SPDc(:,2).*abs(integrationtime);%get counts (not counts/s)
% end


%--------------------------------------------------------------------------
%   Process measurement: determine signal type and measurement mode
%--------------------------------------------------------------------------

%Signal Type:
%if STOPSTART_==0 % only store when obtained from single acquisition!
signaltype_nr=find(DarkRefStim_==1);
if ~isempty(signaltype_nr)
switch signaltype_nr%select which type of signal was measured:
    case 1
        darksignal_=signal_;%counts/s
        handles_darksignal_=darksignal_;
         if STOPSTART_==0;
             message=sprintf('When DARK = OK --> Measure known reference stimulus. + For Irradiance mode: \n enter name of calibration file, browse for it or enter a CCT (format: ''xxxxK'').'); 
            set(handles.messages,'string',message);
         end
    case 2
        refsignal_=signal_;%counts/s
        handles.refsignal_=refsignal_;
         if STOPSTART_==0;
             if ~isempty(calref_);
                 message=sprintf('When REF = OK --> Measure test stimulus. + \n  Select spectrum-mode: Detector / Irradiance / Reflectance or Transmission'); 
             else
                 if get(handles.sel_irrsignal,'value')==1;message=sprintf('Do not forget to load calibration data of reference source before continuing!');end
             end
            set(handles.messages,'string',message);
         end
    case 3
        stimsignal_=signal_;%counts/s
        handles.stimsignal_=stimsignal_;
        if STOPSTART_==0;
             message=sprintf('Continue measurements using "SINGLE  acquisition" or switch to "Continuous mode". To reset (i.e. delete dark/ref/calref/stim,...): Select "dark"-toggle button.'); 
            set(handles.messages,'string',message);
         end
    otherwise
        %Do nothing
end
end
%end


 


%test whether dark and ref have been measured and stored:
DarkRef_measured = double(~isempty(darksignal_) & ~isempty(refsignal_));


%Detect measurement mode
ylabel_str1='# counts / s';ylabel_str2=ylabel_str1;

if DarkRef_measured==1
    if ~isempty(calref_)%ensure that data of calibrated ref source is loaded!
        set(handles.sel_irrsignal,'Visible','On');
        set(handles.start_colorimetryGUI,'visible','on');
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
Det01=get(handles.sel_detsignal,'value');
Irr01=get(handles.sel_irrsignal,'value');
Rfl01=get(handles.sel_rflsignal,'value');
Tra01=get(handles.sel_transsignal,'value');
typesofmodes=[Det01,Irr01,Rfl01,Tra01];
typeofmode_nr=find(typesofmodes==1);


%only when all dark, ref and stim have been measured can a calibrated
%spectrum be calculated!:
lev=8;alpha=2;
if (DarkRef_measured & ~isempty(stimsignal_))
    
    
    % DeNoise Spectrum values using wavelets: 
    % "De-Noising Audio Signals Using MATLAB Wavelets Toolbox" by Villanueva-Luna
    % most symmetrical of coif5, db9 or db10
    % Denoise dark /ref /stim measuremenst: 
%     lev=8;alpha=2;
    if togg_denoise_==1
        
        wentropy='shannon';wtype='coif5';
        darksignal_(:,2)=waveletDenoising(darksignal_(:,1),darksignal_(:,2),wtype,wentropy,lev,alpha);
        refsignal_(:,2)=waveletDenoising(refsignal_(:,1),refsignal_(:,2),wtype,wentropy,lev,alpha);
        stimsignal_(:,2)=waveletDenoising(stimsignal_(:,1),stimsignal_(:,2),wtype,wentropy,lev,alpha);
    end
    
    switch typeofmode_nr
        case 1 %Detector mode
            %do nothing
            mode_=('detector mode');
            set(handles.start_colorimetryGUI,'visible','off');if exist('hcolorimetry','var');if ~isempty(hcolorimetry);close(hcolorimetry);global hcolorimetry;hcolorimetry=[];end;end
            ylabel_str1='# counts / s';ylabel_str2=ylabel_str1;
            SPD=signal_;%
            %SPDx=signal_x;
        case 2 %Irr mode
            mode_=('irradiance mode')
            %figure(12); plot_2(calref_,'r')
            set(handles.start_colorimetryGUI,'visible','on');
            if STOPSTART_==0;
                message=sprintf('In "Irradiance mode" extensive colorimetric info on measured stimulus is available by toggling the colorimetry button in the lower right-hand corner.'); 
                set(handles.messages,'string',message);
            end
            interpolated_calref_=neg2zero(interp1(calref_(:,1),calref_(:,2),stimsignal_(:,1),'linear'));
            SPD=[stimsignal_(:,1),(neg2zero(stimsignal_(:,2)-darksignal_(:,2))./neg2zero(refsignal_(:,2)-darksignal_(:,2))).*interpolated_calref_];
            
            %No extrapolation of calref_ allowed:
            SPD=SPD(signal_(:,1)>=calref_(1,1) & signal_(:,1)<=calref_(end,1),:);
            
            ylabel_str1='# counts / s';ylabel_str2='relative intensity (ref @ 560nm = 1)';
        case 3 %reflectance mode
            mode_=('reflectance mode');
            set(handles.start_colorimetryGUI,'visible','off');if exist('hcolorimetry','var');if ~isempty(hcolorimetry);close(hcolorimetry);global hcolorimetry;hcolorimetry=[];end;end
            SPD=[stimsignal_(:,1),100.*(neg2zero(stimsignal_(:,2)-darksignal_(:,2))./neg2zero((refsignal_(:,2)-darksignal_(:,2))))];
            ylabel_str1='# counts / s';ylabel_str2='%% reflectance';
        case 4 %transmission mode
            mode_=('transmission mode');
            set(handles.start_colorimetryGUI,'visible','off');if exist('hcolorimetry','var');if ~isempty(hcolorimetry);close(hcolorimetry);global hcolorimetry;hcolorimetry=[];end;end
            SPD=[stimsignal_(:,1),100.*(ones(size(stimsignal_,1),1)-(neg2zero(stimsignal_(:,2)-darksignal_(:,2))./neg2zero(refsignal_(:,2)-darksignal_(:,2))))];
            ylabel_str1='# counts / s';ylabel_str2='%% transmittance';
    end
    
    %Negative values are physically impossible:
    SPD(SPD(:,2)<0,2)=0;
    CALSPD_=SPD;
    SPDc=CALSPD_;%overwrite SPDc, all types of modes can be shown on axes_spd

   
    
%--------------------------------------------------------------------------
%   Create plots
%--------------------------------------------------------------------------
%-------------------------------------------------------------------------   

%     if STOPSTART_==0;figure(11);
%         subplot(1,2,1);title('Raw data');
%         plot_2(darksignal_,'k');hold on;plot_2(refsignal_,'b');plot_2(stimsignal_,'g');
%         xlabel('wavelength (nm)');ylabel('ylabel_str1');
%         legend(gca,{'dark signal','reference signal','stimulus signal'});hold off;
%         subplot(1,2,2);title('Calibrated Stimulus Spectrum');
%         plot_2(SPDc,'r');
%         xlabel('wavelength (nm)');ylabel(ylabel_str2);
%         legend(gca,{mode_});
%     end
handles.CALSPD_=CALSPD_;  %write calibrated stimulus to handles for storage     
end



%--------------------------------------------------------------------------
%   Create graph of spectrum on main figure
%--------------------------------------------------------------------------

%to get stable ylabel!
set(handles.axes_ylabel,'HandleVisibility','ON'); 
axes(handles.axes_ylabel);
ylabelstring=ylabel_str2;
plot(0,0,'k');ylabel(ylabelstring,'Color',[1,1,1]);
set(gca, 'Color', 'None');

set(handles.axes_spd,'HandleVisibility','ON'); 
axes(handles.axes_spd);


if (isempty(refsignal_) & isempty(stimsignal_))| isempty(stimsignal_) | isempty(typeofmode_nr) | typeofmode_nr==1;%first measurements
    mode_=('detector mode');
    set(handles.start_colorimetryGUI,'visible','off');if exist('hcolorimetry','var');if ~isempty(hcolorimetry);close(hcolorimetry);global hcolorimetry;hcolorimetry=[];end;end
    SPDc=signal_;ylabel_str1='# counts / s';ylabel_str2=ylabel_str1;
end


plot(SPDc(:,1),SPDc(:,2),'b-');hold on

% DeNoise Spectrum values using wavelets: 
% "De-Noising Audio Signals Using MATLAB Wavelets Toolbox" by Villanueva-Luna
%most symmetrical of coif5, db9 or db10
% Denoise calibrated spectrum
if togg_denoise1x_==1;
    SPDdn=SPDc;
    wentropy='shannon';wtype='coif5';
    SPDdn(:,2)=waveletDenoising(SPDdn(:,1),SPDdn(:,2),wtype,wentropy,lev,alpha);pause(0.05);
    plot(SPDdn(:,1),SPDdn(:,2),'r-');
end


hold off
xlabel('wavelength (nm)');
set(gca, 'Color', 'None');
wavs=SPDc(:,1);wavs=[round(min(wavs)/100)*100:100:round(max(wavs)/100)*100];
spdvalues=SPDc(:,2);spdvalues=spdvalues(~isnan(spdvalues) & ~isinf(spdvalues));
if size(spdvalues)>1;radiance=linspace(min(spdvalues).*0.9,max(spdvalues).*1.1,10);else;radiance=linspace(min([0,min(spdvalues)]),max([0,max(spdvalues)]),10);end
if isempty(spdvalues);radiance=[0,1];end
set(handles.axes_spd,'Xtick',wavs,'Xticklabel',sprintf('%1.0f|',wavs),'Xcolor','w'),
set(handles.axes_spd,'Ytick',radiance,'Yticklabel',sprintf('%5.2f|',radiance),'Ycolor','w')
axis([wavs(1),wavs(end),radiance(1),radiance(end)])
line([wavs(1);wavs(end)],[0;0],'Color',[1,1,1]);



%--------------------------------------------------------------------------
%   Create graph of spectrum and chromaticity on secundary figure (toggle
%   colorimetry button--> sets global showcolorimetry to 0 or 1).
%--------------------------------------------------------------------------

%run script
calcmetrics=1;%toggles calculation of metric-values on/off (set off to speed up 'measurement')
colorimetry_script; 


guidata(hObject,handles);


pause(0.001);
    