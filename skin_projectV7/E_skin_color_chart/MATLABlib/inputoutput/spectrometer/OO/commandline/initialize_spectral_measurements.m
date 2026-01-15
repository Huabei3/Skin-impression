 %initialize_spectral_measurements
 
    %detect presence of spectrometer
    errorflag=0;
    [~,~,errorflag]=getOOspdf(0,1,[0.05,1],1); %try and make a quick measurement
%     if errorflag==-1;
%             MGV.spectrometer.dospectralmeas=0;
%             MGV.spectrometer.CALspd=[];
%             MGV.spectrometer.callamp=[];
%     end
 
 
    %load darkmodel
    if MGV.spectrometer.donkerstroomcorrectie==1;
        MGV.spectrometer.darkmodel=[MGV.droot,'\CalibrationData\darkmodel.txt'];
    else
        MGV.spectrometer.darkmodel=[];
    end

    %initialiseer spectrometer and spectral measurements
%          try
            if MGV.spectrometer.dospectralmeas==1;
                spectrometer=MGV.spectrometer;
                wavcorr_file=[MGV.droot,'\VisualData\Exp_',num2str(MGV.experiment.nr),'\OOspectrometerwavelengthcorrection.txt'];
                if exist(wavcorr_file)
                    wavelengthCorrection=dlmread(wavcorr_file);
                else
                    wavelengthCorrection=[1 0];
                    warning(sprintf('%s \n NOT found! Setting wavelengthCorrection to [1 0].',wavcorr_file));
                end
                spectrometer.wavelengthCorrection = wavelengthCorrection;clear wavelengthCorrection
           
                get_dark_model %measure or load
                
                MGV.spectrometer=spectrometer;
            end
            
            %get spectrometer calibration data (CALspd, callamp: load or meas)
            if MGV.spectrometer.dospectralmeas==1;
               get_spectrometer_caldata
            end
                 
%         catch
%             MGV.spectrometer.dospectralmeas=0;
%             MGV.spectrometer.CALspd=[];
%             MGV.spectrometer.callamp=[];
%             fprintf('!!! Error trying to initialize the spectrometer !!!')
%         end
