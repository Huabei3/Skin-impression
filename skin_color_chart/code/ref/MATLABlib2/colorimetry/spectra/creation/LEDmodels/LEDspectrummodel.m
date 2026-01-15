function SPD=LEDspectrummodel(n,lb,le,lB,hlB,wB,lG,hlG,wG,lR,hlR,wR)
%SIMULATE RGB LED engine by entering the peak wavelengths, halfwidths and weights
%n = number of model, used to write SPD to a different file 
%l0 = starting wavelength
%ln = end wavelength
%lB,lG,lR = peak wavelengths
%hlB,hlG,hlR = wavelength halfwidths
%wB,wG,wR = weights given to each LED dye! 
%___________________________________________________________________
global B G R gaussl RGB tempdatadir
B = wB*LEDgaussmodel1(lB,hlB,[lb,le,1]);
G = wG*LEDgaussmodel1(lG,hlG,[lb,le,1]);
R = wR*LEDgaussmodel1(lR,hlR,[lb,le,1]);
lamb = linspace(lb,le,((le-lb)+1))';

RGB=[lamb,R,G,B];
%filename = [tempdatadir 'LEDRGBmodel' num2str(n) '.txt'];
%dlmwrite(filename,RGB,'delimiter',',');
SPD = RGB(:,2)+RGB(:,3)+RGB(:,4);
SPD = [RGB(:,1),SPD];
filename = ['LEDSPDmodel' num2str(n) '.txt'];
dlmwrite(filename,SPD,'delimiter',',');
plot(RGB(:,1),RGB(:,end:-1:2),SPD(:,1),SPD(:,2),'k');
end
