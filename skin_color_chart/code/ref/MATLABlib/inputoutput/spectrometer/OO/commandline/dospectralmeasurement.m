%dospectralmeasurement
spd = getOOspdf2_KS(1,1,[-MGV.spectrometer.maxint,1],MGV.spectrometer.Nscans);
if ~isempty(MGV.experiment.observerdir);
    dlmwrite([MGV.experiment.observerdir,'\spd',num2str(MGV.experiment.stim_i),'.txt'],spd,'delimiter','\t','precision','%1.6f');
else
    error('Empty observerdir')
end
spd = dlmread([MGV.experiment.observerdir,'\spd',num2str(MGV.experiment.stim_i),'.txt']);
if ~isempty(MGV.spectrometer.CALspd) & ~isempty(MGV.spectrometer.callamp)
    SPD = calibratespdOO(spd,MGV.spectrometer.callamp,0,MGV.spectrometer.CALspd,spectrometer.wavelengthCorrection);
    dlmwrite([MGV.experiment.observerdir,'\SPDc',num2str(MGV.experiment.stim_i),'.txt'],SPD,'delimiter','\t','precision','%1.6f');
    if stimnr==1;%also write CALspd and callamp to directory for archiving
        dlmwrite([MGV.experiment.observerdir,'\CALspd.txt'],MGV.spectrometer.CALspd,'delimiter','\t','precision','%1.6f');
        dlmwrite([MGV.experiment.observerdir,'\callamp.txt'],MGV.spectrometer.callamp,'delimiter','\t','precision','%1.6f');
    end
    MGV.experiment.xyz = spd2xyz(SPD,MGV.cieobs,1)./MGV.Lw.*100;
    MGV.experiment.lab = xyz2cspace(MGV.experiment.xyz,MGV.xyzw,MGV.cspace);
end