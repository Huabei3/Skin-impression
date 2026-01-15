%script testwavelengthcalibration_scriptHgXe()
% bij nieuwe pc terug '\Inge' verwijderen!
penHg=dlmread([cd,'\',datum,'\Hg_lamp.txt'],'\t');
penXe=dlmread([cd,'\',datum,'\Xe_lamp.txt'],'\t');
 
SPD=penHg; % kolom 1: alle golflengtes
SPD(:,2)=SPD(:,2)+penXe(:,2); % kolom 2: alle waarden per golflengte voor zowel Hg als Xe -> alsof door beide belicht
 
figure(3);plot(SPD(:,1),SPD(:,2),'r');hold on
 
%OOmaxi = positie van de max
% 0.005 is gevoeligheid waarmee hij detecteert -> zelf controleren of hij alles detecteert (404 en 407 -> moet beide apart zien = groen bolletje. Hoe kleiner het getal, hoe meer groene bolletjes)
[OOmax,OOmaxi]=extrema_(SPD(:,1:2),0.005);
figure(3);plot(SPD(OOmaxi,1),SPD(OOmaxi,2),'go'),
 
% KWIK + XENON
 
% With spectrometers that have 1200-, 1800-, 2400- or 3600-lines/mm gratings, spectral lines will be evident at 576.96 nm and 579.07 nm.
%Hg_wavOO=[302.2,365.015,404.656,435.833,546.074,576.960,579.065];
Hg_wavOO=[253.652,296.728,302.2,365.015,404.656,407.780,435.833,546.074,576.960,579.065];
 
% Nog extra emmissielijnen gevonden (http://www.oceanoptics.com/products/hg1.asp)
% Hg_wavOO=[253.652,296.728,302.2,313.155, 334.148, 365.015,404.656,407.780,435.833,546.074,576.960,579.065];
 
%Oriel Instruments
%Xe_wavOO=[764.2,823.16,828.01,834.68,840.92];
%Ocean Optics - maar slechts tot 1000nm overgetypt
%Xe_wavOO=[764.391,823.163,826.652,881.941,904.545,916.265,979.97];
%Oriel instrument (oorsprong toestel) + uitbreiding Ocean Optics (voorbij 890 nm)
Xe_wavOO=[764.2,823.163,828.01,834.68,840.92,881.941,904.545,916.265,979.97];
 
%samenbrengen, sorteren en dubbele er uit
wavOO=unique([Hg_wavOO,Xe_wavOO]);
 
 
% ZOEK OVEREENKOMSTIGE GOLFLENGTEN
 
%uitbreiden (horizontaal en vertikaal) en dan aftrekken
 
% numel(OOmaxi) = aantal elementen in OOmaxi
d=repmat(wavOO,numel(OOmaxi),1)-repmat(SPD(OOmaxi,1),1,numel(wavOO))
[wOO,spdOO]=meshgrid(wavOO,SPD(OOmaxi,1));
d=abs(wOO-spdOO)
dd1=min(abs(d))';
dd2=min(abs(d'))';
 
wOO=wavOO(dd1<5),
spdOO=SPD(OOmaxi(dd2<5),1)'
 
 
spdOO_2=[];
wOO_2=[];
for i=1:numel(wOO);
    d=abs(spdOO-wOO(i));
    if min(d)<5
        spdOO_2=[spdOO_2,spdOO(d==min(d))];
        wOO_2=[wOO_2,wOO(i)];
    end
end
 
[n, bin] = histc(spdOO_2, unique(spdOO_2));
multiple = find(n > 1);
index    = find(ismember(bin, multiple));
d=wOO_2'-spdOO_2';
spdOO_2(index(find(d(index)==max(d(index)))))=NaN;
wOO_2(index(find(d(index)==max(d(index)))))=NaN;
d(index(find(d(index)==max(d(index)))))=NaN;
    
    
 
%geldige golflengte als verschil < 5 nm
d4_OO=[wOO_2',spdOO_2',d]
 
d4_OO=d4_OO(~isnan(d4_OO(:,1)),:)
%d4_OO=[wavOO(dd2<5)',SPD(OOmaxi(dd2<5),1),dd2(dd2<5)]
 
%bepaal lin. corectie
global wavelengthCorrection;
% 2e kolom = gemeten, 1e kolom = werkelijk (cf internet)
wavelengthCorrection=polyfit(d4_OO(:,2),d4_OO(:,1),1)
 
%plot
r=(360:830);figure(6);
hold on;
%plot_2 plot kolom1 en kolom2 van eerste argument
plot_2(d4_OO,'ro');
plot(r,polyval(wavelengthCorrection,r),'r');
 
save lambdaOOcorr wavelengthCorrection
 
 