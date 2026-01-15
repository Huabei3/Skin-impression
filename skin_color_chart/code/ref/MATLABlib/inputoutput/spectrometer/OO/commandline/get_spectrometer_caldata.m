% get_spectrometer_caldata    
if MGV.spectrometer.dospectralmeas==1;
    tt=MGV.spectrometer.meetradiantiestandaard
    if MGV.spectrometer.meetradiantiestandaard==1;
        answer = questdlg('Measure new callamp data or load existing?','Sec. Radiance Standard','Existing','New','Existing');
        switch answer
            case 'New'
                MGV.spectrometer.meetradiantiestandaard=1;
            case 'Existing'
                MGV.spectrometer.meetradiantiestandaard=0;
            otherwise
                MGV.spectrometer.meetradiantiestandaard=0;
        end
    end   
    
        % Measure radiance standard
        waitfor(msgbox('Controleer of de juiste CAL file wordt ingelezen'))
              %zet locaties voor meting (en werkelijk spectrum) van radiantie standaard
                get_last_spectrometer_caldate
                MGV.spectrometer.callampfile=[MGV.droot,'\CalibrationData\RadianceStandard_data\callamp_',MGV.spectrometer.datum,'.txt'];
                MGV.spectrometer.CALspdfile=[MGV.droot,'\CalibrationData\RadianceStandard_data\CALspd_',MGV.spectrometer.datum,'.txt'];%gebruik juiste CAL file, indien er een nieuwe is!!!
                MGV.spectrometer.CALspd=dlmread(MGV.spectrometer.CALspdfile);
                
              
                
                %Meten van radiantiestandaard
                if MGV.spectrometer.meetradiantiestandaard==1;
                    waitfor(msgbox('Start meting van radiantie standaard.'))
                    [MGV.spectrometer.callamp]=getOOspdf2_KS(1,1,[-MGV.spectrometer.maxint,1],MGV.spectrometer.Nscans);
                    dlmwrite(MGV.spectrometer.callampfile,MGV.spectrometer.callamp,'delimiter','\t','precision','%1.10f');
                else
                    MGV.spectrometer.callamp=dlmread(MGV.spectrometer.callampfile);
                end


                if MGV.runexperiment==0;
                    dlmwrite([MGV.droot,'\CalibrationData\',MGV.calibration.datum,'\CALspd.txt'],MGV.spectrometer.CALspd,'delimiter','\t','precision','%1.10f');
                    dlmwrite([MGV.droot,'\CalibrationData\',MGV.calibration.datum,'\callamp.txt'],MGV.spectrometer.callamp,'delimiter','\t','precision','%1.10f');
                end
                
                
                
                
%                 % load CALspd and callamp files for automated spectral calibration
%                 if MGV.runexperiment==1
%                     if exist([MGV.droot,'\VisualData\Exp_',num2str(MGV.experiment.nr),'\CALspd_',MGV.experiment.datum,'.txt']);
%                         MGV.spectrometer.CALspd=dlmread([MGV.droot,'\VisualData\Exp_',num2str(MGV.experiment.nr),'\CALspd_',MGV.experiment.datum,'.txt']);
%                     else;
%                         MGV.spectrometer.CALspd=[];
%                     end
%                     if exist([MGV.droot,'\VisualData\Exp_',num2str(MGV.experiment.nr),'\callamp_',MGV.experiment.datum,'.txt'])
%                         MGV.spectrometer.callamp=dlmread([MGV.droot,'\VisualData\Exp_',num2str(MGV.experiment.nr),'\callamp_',MGV.experiment.datum,'.txt']);
%                     else
%                         MGV.spectrometer.callamp=[];
%                     end
%                 else
%                     if exist([MGV.droot,'\CalibrationData\CALspd_',MGV.calibration.datum,'.txt']);
%                         MGV.spectrometer.CALspd=dlmread([MGV.droot,'\CalibrationData\CALspd_',MGV.calibration.datum,'.txt']);
%                     else;
%                         MGV.spectrometer.CALspd=[];
%                     end
%                     if exist([MGV.droot,'\CalibrationData\callamp_',MGV.calibration.datum,'.txt'])
%                         MGV.spectrometer.callamp=dlmread([MGV.droot,'\CalibrationData\callamp_',MGV.calibration.datum,'.txt']);
%                     else
%                         MGV.spectrometer.callamp=[];
%                     end
%                 end
            else
                MGV.spectrometer.dospectralmeas=0;
                MGV.spectrometer.CALspd=[];
                MGV.spectrometer.callamp=[];
            end