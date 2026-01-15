%writespecs2disp
[specminint,handles.specmaxint_,handles.specminint_,handles.maxCount_,handles.specADout_,handles.Npixels_,handles.usepixels_,handles.SNratio_,handles.ActiveCooling_,handles.boxcarwidth_,handles.wavrange,handles.NoOrUnknownspec_]=getMODELspecs(0,handles.spectrometermodel,handles);
if handles.NoOrUnknownspec_==1;Color=[1,0,0];Color2=Color;else;Color=[0.5,0.5,0.5];Color2=Color.*0;end


set(handles.specmodel,'string',handles.spectrometermodel);
set(handles.specmodel,'ForegroundColor',Color);

set(handles.specseries,'string',handles.spectrometerseries);
set(handles.specseries,'ForegroundColor',Color);

set(handles.specmaxint,'string',sprintf('%1.6g',handles.specmaxint_));
set(handles.specmaxint,'ForegroundColor',Color);

set(handles.specminint,'string',sprintf('%1.6g',handles.specminint_));
set(handles.specminint,'ForegroundColor',Color);

set(handles.specADout,'string',sprintf('%1.0f',handles.specADout_));
set(handles.specADout,'ForegroundColor',Color);

set(handles.Npixels,'string',sprintf('%1.0f',handles.Npixels_));
set(handles.Npixels,'ForegroundColor',Color);

set(handles.specSNratio,'string',handles.SNratio_);
set(handles.specSNratio,'ForegroundColor',Color);

set(handles.specActiveCooling,'string',sprintf('%1.6g',handles.ActiveCooling_(1)));
set(handles.specActiveCooling,'ForegroundColor',Color);

if handles.NoOrUnknownspec_==0 & handles.ActiveCooling_(1)==1;
    set(handles.togg_ActiveCooling,'string','Active Cooling off');
    set(handles.togg_ActiveCooling,'Visible','on');
    set(handles.togg_ActiveCooling,'ForegroundColor',0.75.*[1,1,1]);
    handles.togg_ActiveCooling_=0;
    set(handles.togg_ActiveCooling,'value',handles.togg_ActiveCooling_);
    
else;
    set(handles.togg_ActiveCooling,'Visible','off');
    handles.togg_ActiveCooling_=0;
    set(handles.togg_ActiveCooling,'value',handles.togg_ActiveCooling_);
end


%Preset integrationtimes based on spectrometer model
set(handles.user_minint,'string',sprintf('%1.6g',handles.specminint_));
set(handles.user_minint,'ForegroundColor',Color2);
handles.user_minint_=handles.specminint_;
handles.user_maxint_=10*handles.user_minint_;%use 10 x minint for initialization

set(handles.user_maxint,'string',sprintf('%1.6g',handles.user_maxint_));
set(handles.user_maxint,'ForegroundColor',Color2);
%handles.user_maxint_=handles.specmaxint_;


set(handles.user_boxcarwidth,'string',sprintf('%1.6g',handles.boxcarwidth_));
set(handles.user_boxcarwidth,'ForegroundColor',Color2);


guidata(hObject,handles);

