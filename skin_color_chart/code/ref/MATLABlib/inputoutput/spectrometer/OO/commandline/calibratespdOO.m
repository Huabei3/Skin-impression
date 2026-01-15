function [spd]=calibratespdOO(spdfile,ijkfile,RFLfile,CALfile,wavelengthCorrection,interpolationtype,readoutnoise)
%Calibrate 'Ocean Optics' spectral measurement contained in 'spdfile' (txt, tab delimited)
%and write to file.
%input:
%spdfile = spectral measurement of stimulus.
%ijkffile = file containing spectral measurement of calibration source 
%RFLfile = file containing known spectral reflectance on which a source was
%           measured: if RFLfile = 0 then 'spdfile' is stimulus, 
%           if RFLfile ~= 0 then measurement in spdfile is corrected with 
%           RFLfile (e.g. spectral reflectance of a white CERAM tile). 
%CALfile = file containing known spectral output of calibration source.
%interpolationtype = 'spline' by default.
%
%output:
%spd = calibrated stimulus

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if RFLfile==0; object='y';else object='n';end
if nargin <5;wavelengthCorrection=[1 0];warning('No wavelength correction');end
if nargin<6;interpolationtype='linear';end
if nargin<7;readoutnoise=0;end

if ischar(spdfile)
    spdwaschar=1;
    spd=dlmread(spdfile);
else
    spdwaschar=0;
    spd=spdfile;%%--> must be file to enable save to spdfilename (line69)
end

lambmeas=spd(:,1);

if isempty(wavelengthCorrection);
    error('No wavelength correction supplied: e.g. [1 0]')
else
    lambmeas=polyval(wavelengthCorrection,lambmeas);
end

if ischar(ijkfile)
    ijk=dlmread(ijkfile);
else
    ijk=ijkfile;
end

%figure(11);plot_2(ijk,'g');hold on

spd=(spd(:,2)-readoutnoise)./(ijk(:,2)-readoutnoise);

if ischar(CALfile)
    CAL=dlmread(CALfile);
else
    CAL=CALfile;
end
CAL=interpK(CAL(:,1),CAL(:,2),lambmeas,interpolationtype);

if object=='n';
    if ischar(RFLfile)
        RFL=dlmread(RFLfile);
    else
        RFL=RFLfile;
    end
     RFL=interpK(RFL(:,1),RFL(:,2),lambmeas,interpolationtype);
    if max(RFL)>1;RFL=RFL./100;end%procent omzetten
end

if object=='n';
    spd=spd./RFL.*CAL;
    %rfl=spd.*RFL;dlmwrite(['RFL',spdfile],[lamb,rfl],'\t');
else;
    spd=spd.*CAL;
end

spd=[lambmeas,spd];

if spdwaschar==1
    spdfile=[spdfile(1:end-4),'_C.txt' ];
    dlmwrite([spdfile],spd,'delimiter','\t','precision','%1.10f');
else
    disp('Give filename as input to enable save, or save SPD later!!!')
end

end


