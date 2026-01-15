%%init_keyboard
global keyboard
keyboard.init=1;%signal keyboard is alrfeady initialized
keyboard.onoff=1;
keyboard.processed=1;
keyboard.input=0;
keyboard.labrange=[0 100 0 0.6 0 0.6];%Y, u', v'ranges
keyboard.scaleunit=0.001;%minimum step 
keyboard.shiftScaler=50;%unit step multiplier when shift is pressed
keyboard.controlScaler=10;%unit step multiplier when control is pressed
keyboard.altScaler=5;%unit step multiplier when alt is pressed
keyboard.windowsScaler=100;
keyboard.lab=xyz2cspace([100,100,100],[100,100,100],cspace);%set startingvalue
keyboard.ratingscale=1;
keyboard.R=nan;%stores rating if F1-F11 is pressed
keyboard.modifiers={'shift','control','alt','windows'};