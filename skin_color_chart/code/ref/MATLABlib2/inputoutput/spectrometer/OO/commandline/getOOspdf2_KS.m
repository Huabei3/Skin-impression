function [SPDZonderDonker,SPD,errorflag,oospecname,actualTemperature,spectralData00]=getOOspdf2(display,Nes,IntegrationTime,Nscans,DarkFlag,NonlinearityFlag,boxcarwidth,wtype_lev_alpha)

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
SPDZonderDonker=[];
oospecname=[];
actualTemperature=[];
spectralData00=[];


%bepaal parameters gemiddelde donkerstroom -> run modeldarkmeasurement

global donkerstroomcorrectie parametersGemiddeldeDonkerstroom Nscans
[SPD,SPDdn,SPDcounts,IntegrationTime]=getOOspdf(display,Nes,IntegrationTime,Nscans,DarkFlag,NonlinearityFlag,boxcarwidth,wtype_lev_alpha);
%figure,hold on;plot_2(spd,'r')
if donkerstroomcorrectie==1;
    %DonkerBerekend=parametersGemiddeldeDonkerstroom.SPDmean.*fitexp(parametersGemiddeldeDonkerstroom,IntegrationTime);%use exponential as model
    DonkerBerekend=parametersGemiddeldeDonkerstroom.meandark(:,2).*polyval(parametersGemiddeldeDonkerstroom.pdark,IntegrationTime)./IntegrationTime;%use polynomial model
    SPDZonderDonker=SPD;
    SPDZonderDonker(:,2)=SPD(:,2)-DonkerBerekend;
    SPDZonderDonker(end,2)=IntegrationTime;
    % figure(11);subplot(1,2,1);r=1:1024;plot(SPD(r,1),SPD(r,2),'b');hold on;plot(SPD(r,1),DonkerBerekend(r),'r');plot(SPD(r,1),SPDZonderDonker(r,2),'g');subplot(1,2,2);plot(SPD(r,1),DonkerBerekend(r),'r')
else
    SPDZonderDonker=SPD;
end

% figure(1);plot(SPD(:,1),DonkerBerekend)
% figure(2);plot(SPD(:,1),SPD(:,2),'r',SPDZonderDonker(:,1),SPDZonderDonker(:,2),'b');


end


