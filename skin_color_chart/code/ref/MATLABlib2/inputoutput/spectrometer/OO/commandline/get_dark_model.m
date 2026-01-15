%get_dark_model

%dark correction (for option to determine new, delete or rename previous
if spectrometer.donkerstroomcorrectie==1;
    try 
        spectrometer.parametersGemiddeldeDonkerstroom=[];
        spectrometer.modeldark=dlmread(spectrometer.darkmodel);
        spectrometer.parametersGemiddeldeDonkerstroom.pdark=spectrometer.modeldark(1:spectrometer.modeldark(1,1)+1,2);
        spectrometer.parametersGemiddeldeDonkerstroom.meandark=spectrometer.modeldark(numel(spectrometer.parametersGemiddeldeDonkerstroom.pdark)+1:end,:);
    catch
        answer = questdlg('Could not read darkmodel. Determine new darkmodel?','Dark measurement model','Yes','No','No');
        switch answer
            case 'Yes'
                spectrometer.donkerstroomcorrectie=1;
            case 'No'
                spectrometer.donkerstroomcorrectie=0;
            otherwise 
                spectrometer.donkerstroomcorrectie=0;
                
        end
        
        
        if spectrometer.donkerstroomcorrectie==1;
            waitfor(msgbox('Cover telescope to measure dark'))
            disp('Cover telescope to measure dark')
            try 
                modeldarkmeasurement
            catch
                spectrometer.donkerstroomcorrectie=0;   
                spectrometer.parametersGemiddeldeDonkerstroom.pdark=[];
                spectrometer.parametersGemiddeldeDonkerstroom.meandark=[];
                disp('Could not read darkmodel. --> No dark correction.');
                waitfor(msgbox('Could not read darkmodel. --> No dark correction.'))
            end
        else
             spectrometer.donkerstroomcorrectie=0;   
             spectrometer.parametersGemiddeldeDonkerstroom.pdark=[];
             spectrometer.parametersGemiddeldeDonkerstroom.meandark=[];
             disp('''NO dark correction'' set')
        end
    end
else
    spectrometer.donkerstroomcorrectie=0; 
    spectrometer.parametersGemiddeldeDonkerstroom.pdark=[];
    spectrometer.parametersGemiddeldeDonkerstroom.meandark=[];
    disp('''NO dark correction'' set')
end


