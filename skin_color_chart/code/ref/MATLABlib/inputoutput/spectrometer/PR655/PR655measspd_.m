function [spd,q]=PR655measspd_(S,nmeas,syncMode,varargin)
%Measure spectrum using the PR655 spectrophotometer
%S        : [start wavelength, samplinginterval, end wavelength]; min=380,max=780
%nmeas    : number of measurements. If nmeas < 0 : spd = average of measurements
%syncMode : 'on' / 'off' ; sync exposure time to frequency of source.
%Enter optional control parameters as follows, (n is value of control parameter 'SX')
%'SEnnnnn': Exposuretime: 6 ms - 6,000 ms (fixed); SE0: Adaptative Exposure (PR655 determines optimal exposure time)
%'SUn'    : Select 0: English or 1: Metric (SI) photometric values to be reported
%'SZn'    : Dark Measurement / Measure Shutter Control; 
%             0: dark current measurement (shutter closes) after each light measurement; 
%             1: no dark measurement (shutter always open);
%'SSn'    : Instructs the instrument to adjust the exposure time, when using Adaptive Sensitivity mode,
%           to the nearest even multiple of the refresh rate (frequency) of the source. 
%           Choices are 0: No Sync, 1: Auto Sync, and 3: User Frequency.
%           In Auto Sync mode, the instrument measures the frequency of the source to determine its period. 
%           The exposure time is then automatically altered so that it is an even multiple of the source period (1/frequency).
%           User Frequency will adjust the exposure time based on a user enter frequency in Hertz as entered using 
%           the SK command. See the User Sync Frequency section for more details on defining the Sync frequency.
%'SKnnn'  : User Sync Frequency Enter the frequency (in Hertz) of the source being measured. 
%           The range is 020 to 400 Hz. This command works in unison with the SYNC Mode setting.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Set default values
if nargin==0;S=[380,5,780];nmeas=1;syncMode = 'on';varargin(1)={'SE0'};varargin(2)={'SU1'};varargin(3)={'SS1'};end
if nargin==1;nmeas=1;syncMode = 'on';varargin(1)={'SE0'};varargin(2)={'SU1'};varargin(3)={'SS1'};end
if nargin==2;syncMode = 'on';varargin(1)={'SE0'};varargin(2)={'SU1'};varargin(3)={'SS1'};end
if nargin==3;varargin(1)={'SE0'};varargin(2)={'SU1'};varargin(3)={'SS1'};end
syncMode='off';
%allow use of dummy variables
if S==0;S=[380,5,780];end
if nmeas==0;nmeas=1;end
if syncMode==0;syncMode='off';else;if syncMode==1;syncMode='on';end;end
    
S_=[S(1), S(2), (S(3)-S(1))/S(2)+1];%set up wavelength info as used in PR655toolbox

%Store currently used control parameters in memory and set up device
global PR655_SS;varinput=[varargin];

if ~isempty(PR655_SS);
    temp=union((varinput),(PR655_SS));
    kk=(~ismember((varinput),temp));pkk=find(kk==1);
    for i=1:numel(temp);s1=char(temp(i));s1=s1(1:2);ss1(i)={s1};end
    for i=1:numel(temp);dd_(i)=(sum(ismember(ss1,ss1(i)))>1)*i;end
    PR655_SS(ismember(PR655_SS,temp(dd_>0)))= varinput(ismember(varinput,temp(dd_>0)));
    PR655_SS=unique([varinput,PR655_SS]);
    
else;
    kk=1;
    PR655_SS=varargin;
end



q=[];

%if (sum(kk,2) ~=0);

%set control parameters
for i=1:numel(PR655_SS)
    controlstring=char(PR655_SS(i));
    switch controlstring(1:2)
        case 'SE'
            %set exposure time
            SExposuretime=double(str2num(controlstring(3:end)));
            if SExposuretime>0 & SExposuretime<6 ;SExposuretime=6;disp('Minimum Exposure time = 6 ms');else;if SExposuretime>6000;SExposuretime=6000;disp('Maximum Exposure time = 6000 ms');end;end
            SE=['SE',num2str(SExposuretime)];
            PR655write(SE);q_=PR655read;
            q(i)=str2num(q_);
            if SExposuretime==0;
                if (q(i))==0;disp('Adaptive Exposure set: ok.');else; disp('Failed to set Adaptive Exposure set!');end
            else
                if (q(i))==0;disp(sprintf('Exposure time set to %4.0f ms: ok.',SExposuretime));else; disp(sprintf('Failed to set requested Exposure time!'));end
            end

        case 'SU'
            %set units (0:English or 1:metric)
            SUnits= double(str2num(controlstring(3:end)));
            SU=['SU',num2str(SUnits)];
            PR655write(SU);q_=PR655read;q(i)=str2num(q_);
            switch SUnits
                case 0
                    if (q(i))==0;disp('English units set: ok.');else; disp('Failed to set English units!');end
                case 1
                    if (q(i))==0;disp('Metric units set: ok.');else; disp('Failed to set Metric units!');end
            end
            
        case 'SZ'
            %Always take Dark measurement: shutter always closes after measurement
            SZ='SZ0';
            PR655write(SZ);q_=PR655read;q(i)=str2num(q_);
        otherwise
            PR655write(controlstring);q_=PR655read;q(i)=str2num(q_);
    end
end

%end%end store control parameters

%measure spectra
for j=1:abs(nmeas)
    [spd(:,j), qual(j)] = PR655measspd(S_,syncMode);
end

%store quality codes into one array
for i=1:numel(q);qs(i)={num2str(q(i))};end;
if ~isempty(q);q=[num2str(qual),PR655_SS,qs];else;q=[num2str(qual),PR655_SS];end
    
%If nmeas < 0; take average spd
if nmeas<0;spd=mean(spd')';end

%setup wavelength array
lam=(S(1):S(2):S(3))';
%create spectrum with wavelengths attached,delete by wavelength spacing to
%undo the taking into account of the wav spacing by the PR655 toolbox
spd=[lam,spd./S(2)];


