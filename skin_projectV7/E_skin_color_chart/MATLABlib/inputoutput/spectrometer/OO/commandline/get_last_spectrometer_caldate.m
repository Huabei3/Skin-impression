%get_last_spectrometer_caldate
    %check for callamp_file and CALlamp_file no more than x (=MGV.max_caldays) days old 
    %to enable realtime processing of measured spectra to XYZ
    months={'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'};
    days=[31,28,31,30,31,30,31,31,30,31,30,31];
    datum=date;
    datum_=[];
    for i=MGV.max_caldays:-1:1;%calibration files up to n days old are valid
        day_=str2double(datum(1:2))-(MGV.max_caldays-i);
        month_=(find(strcmp(datum(4:6),months)));
        year_=str2double(datum(end-3:end));
        if day_<=0;
           if month_>1;
              day_=days(month_-1)+day_;
              month_=month_-1;
           else;
              day_=days(12)+day_;
              month_=12;year_=year_-1;
           end;
        end
        datum_=[sprintf('%02.0f',day_),sprintf('-%s',months{month_}),sprintf('-%02.0f',year_)];
        
        MGV.spectrometer.callampfile=[MGV.droot,'\CalibrationData\RadianceStandard_data\callamp_',datum_,'.txt'];
        MGV.spectrometer.CALlampfile=[MGV.droot,'\CalibrationData\RadianceStandard_data\CALspd_',datum_,'.txt'];
        if exist(MGV.spectrometer.callampfile)& exist(MGV.spectrometer.CALlampfile)
           break;
        else
            datum_=[];
        end
    end
if isempty(datum_)     
    error(sprintf('Calibrate spectrometer. No valid calibration files found from within the last %1.0f days.',MGV.max_caldays)) 
else
    MGV.spectrometer.datum=datum_;     
end
%clear year_ month_ day_ days months datum_ 
