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
    inttime=NaN; minint=NaN;maxint=NaN;spectrometerAD=NaN;maxCount=NaN;Npixels=NaN;SNratio='NaN';ActiveCooling=NaN;NoOrUnknownSpec=1;boxcarwidth=NaN;usepixels=NaN;
end


