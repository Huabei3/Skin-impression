global spectrometerIndex_ spectrometermodel_ spectrometerseries_ Npixels_ usepixels_
global user_minint_ user_maxint_ forceinttime_ boxcarwidth_ Nscans_ togg_Darkc_ togg_Nonlin_ togg_denoise_  togg_denoise1x_ togg_ActiveCooling 
global calref_ darksignal_ refsignal_ stimsignal_ CALSPD_ DarkRefStim_

spectrometerIndex_=handles.spectrometerIndex;
spectrometermodel_=handles.spectrometermodel;
spectrometerseries_=handles.spectrometerseries;
Npixels_=handles.Npixels_;
specAD_=handles.specADout_;
usepixels_=handles.usepixels_;
user_minint_=handles.user_minint_;
user_maxint_=handles.user_maxint_;
forceinttime_=handles.forceinttime_;
boxcarwidth_=handles.boxcarwidth_;
Nscans_=handles.Nscans_;
togg_Darkc_=handles.togg_Darkc_;
togg_Nonlin_=handles.togg_Nonlin_;
togg_denoise_=handles.togg_denoise_;
togg_denoise1x_=handles.togg_denoise1x_;
togg_ActiveCooling=handles.togg_ActiveCooling;


%setup user_minint_
if user_minint_>user_maxint_;user_minint_=user_maxint_;handles.user_minint_=user_minint_;end
if forceinttime_==0;
   %if user_minint_>user_maxint_;user_minint_=user_maxint_;handles.user_minint_=user_minint_;end
    handles.user_minint_=-abs(handles.user_minint_);user_minint_=-abs(user_minint_);
else
    handles.user_minint_=abs(handles.user_minint_);user_minint_=abs(user_minint_);
    user_maxint_=user_minint_;set(handles.user_maxint,'string',sprintf('%1.6f',user_maxint_));
end;%if not forced, let function search optimum inttime
set(handles.user_minint,'string',sprintf('%1.6f',abs(user_minint_)));


calref_=handles.calref_;
darksignal_=handles.darksignal_;
refsignal_=handles.refsignal_;
stimsignal_=handles.stimsignal_;
DarkRefStim_=handles.DarkRefStim_;

CALSPD_=handles.CALSPD_;




