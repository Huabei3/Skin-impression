%keyboard_script

if keyboard.processed==1 & keyboard.onoff==1
    
    event=eventdata;

    %Display valid keystrokes
    switch ~strcmp(char(event.Modifier),'')
        case 1;
            keyevent=[char(event.Modifier),'+',char(event.Key)];
        otherwise
            keyevent=[char(event.Key)];
    end
    if ~strcmp(keyevent,'control') & ~strcmp(keyevent,'alt') & ~strcmp(keyevent,'shift') 
        disp(sprintf('Test subject pressed: %s',keyevent))
    end
    %__________________________________________________________________________
    
    keyboard.command=[keyevent];
    keyboard.processed=0;
        
    %--------------------------------------------------------------------------

     %chromaticity / lightness change
            if strcmp(event.Key,'uparrow') | strcmp(event.Key,'downarrow') | strcmp(event.Key,'leftarrow') |  strcmp(event.Key,'rightarrow') |   ...
                    strcmp(event.Key,'pageup') | strcmp(event.Key,'pagedown') | ...
                    strcmp(event.Key,'numpad1') | strcmp(event.Key,'numpad2') | strcmp(event.Key,'numpad3') | ...
                    strcmp(event.Key,'numpad4') | strcmp(event.Key,'numpad5') | strcmp(event.Key,'numpad6') | ...
                    strcmp(event.Key,'numpad7') | strcmp(event.Key,'numpad8') | strcmp(event.Key,'numpad9') 

                    
                    L_range=keyboard.labrange(2)-keyboard.labrange(1);
                    a_range=keyboard.labrange(4)-keyboard.labrange(3);
                    b_range=keyboard.labrange(6)-keyboard.labrange(5);

                    fL=keyboard.scaleunit.*L_range;%set L step
                    fa=keyboard.scaleunit.*a_range;%set a step
                    fb=keyboard.scaleunit.*b_range;%set b step
                   
                    lab_modifier=[0,0,0];

                % check modifier type
                    ctrlScaler=1;
                    if strcmp(char(event.Modifier),'shift');
                        ctrlScaler=keyboard.shiftScaler;
                    else;
                        if strcmp(char(event.Modifier),'control');
                            ctrlScaler=keyboard.controlScaler;
                        else;
                            if strcmp(char(event.Modifier),'alt');
                                   ctrlScaler=keyboard.altScaler;
                            else
                                if strcmp(char(event.Modifier),'windows');
                                    ctrlScaler=keyboard.windowsScaler;
                                else
                                    ctrlScaler=1;
                                end
                            end
                        end;
                    end

                % check key type
                    if strcmp(event.Key, 'rightarrow') | strcmp(event.Key, 'numpad6');lab_modifier=[0,fa.*ctrlScaler,0];end
                    if strcmp(event.Key, 'leftarrow') | strcmp(event.Key, 'numpad4');lab_modifier=[0,-fa.*ctrlScaler,0];end
                    if strcmp(event.Key, 'uparrow') | strcmp(event.Key, 'numpad8');lab_modifier=[0,0,fb.*ctrlScaler];end
                    if strcmp(event.Key, 'downarrow')| strcmp(event.Key, 'numpad2');lab_modifier=[0,0,-fb.*ctrlScaler];end
                    if strcmp(event.Key, 'numpad9');lab_modifier=sqrt(2).*[0,fa.*ctrlScaler,fb.*ctrlScaler];end
                    if strcmp(event.Key, 'numpad7');lab_modifier=sqrt(2).*[0,-fa.*ctrlScaler,fb.*ctrlScaler];end
                    if strcmp(event.Key, 'numpad3');lab_modifier=sqrt(2).*[0,fa.*ctrlScaler,-fb.*ctrlScaler];end
                    if strcmp(event.Key, 'numpad1');lab_modifier=sqrt(2).*[0,-fa.*ctrlScaler,-fb.*ctrlScaler];end
                    if strcmp(event.Key, 'pageup');lab_modifier=[fL.*ctrlScaler,0,0];end
                    if strcmp(event.Key, 'pagedown');lab_modifier=[-fL.*ctrlScaler,0,0];end

                % calculate new chromaticity setting
                    keyboard.lab=keyboard.lab+lab_modifier;
                    keyboard.lab(keyboard.lab(1)<keyboard.labrange(1),1)=keyboard.labrange(1);
                    keyboard.lab(keyboard.lab(1)>keyboard.labrange(2),1)=keyboard.labrange(2);
                    keyboard.lab(keyboard.lab(2)<keyboard.labrange(3),2)=keyboard.labrange(3);
                    keyboard.lab(keyboard.lab(2)>keyboard.labrange(4),2)=keyboard.labrange(4);
                    keyboard.lab(keyboard.lab(3)<keyboard.labrange(5),3)=keyboard.labrange(5);
                    keyboard.lab(keyboard.lab(3)>keyboard.labrange(6),3)=keyboard.labrange(6);
            end
    %--------------------------------------------------------------------------
    if event.Key(1)=='f'; %only run during experiment
        %read rating
        R=single(str2double(event.Key(2:end)))-1;
        R=R./keyboard.ratingscale;
        keyboard.R=R;
        clear R;
    else
        keyboard.R=nan;
    end
    
    %--------------------------------------------------------------------------
    keyboard.input=1;
    
    %--------------------------------------------------------------------------
    
    if strcmp(char(event.Modifier),'control') & strcmp(event.Key,'x') %stop
        disp('Exiting program')
        keyboard.input=2;
    end
    %--------------------------------------------------------------------------
    
    
    
else
    if ~strcmp(char(eventdata.Modifier),'') 
        disp('Still processing previous keyboard input or keyboard control turned off')
    end
    keyboard.processed=1;
end