function [stop,optnew,updateoptions] = satooloutput(optlast,optimval,flag)
%SATOOLOUTPUT private to OPTIMTOOL.

%   Copyright 2007-2009 The MathWorks, Inc.
%   $Revision: 1.1.6.2 $  $Date: 2009/10/10 20:08:36 $

%Initialize
stop = false;
updateoptions = false;
optnew = optlast;
drawnow;
STOP = 0;
RUN_RESUME = 1;
PAUSE = 2;
modelCheck = false;

switch flag
    case 'init'
        optimtoolGui = javaMethodEDT('getOptimGUI','com.mathworks.toolbox.optim.OptimGUI'); % Get a handle to the GUI
        [msg,id] = lastwarn;
        if ~isempty(msg)
            % Make sure that exactly one newline character is at the end of 'msg'
            newLineIndex = regexp(msg,'\n');
            if isempty(newLineIndex) || newLineIndex(end) ~=length(msg)
                msg = sprintf('%s\n',msg);
            end
            javaMethodEDT('appendResults',optimtoolGui,['Warning: ',msg]); % Append to the 'Status and Results' panel
        end
        setappdata(0,'last_warning_id_for_optimtool',id);
        %Set up for the GUI.
        return; %Nothing to do now
    case 'iter'
        optimtoolGui = javaMethodEDT('getOptimGUI','com.mathworks.toolbox.optim.OptimGUI');
        if isempty(optimtoolGui)
            stop = true;
            return;
        end
        [msg,id] = lastwarn;
        if ~isempty(msg) && ~strcmp(id,getappdata(0,'last_warning_id_for_optimtool'))
            newLineIndex = regexp(msg,'\n');
            if isempty(newLineIndex) || newLineIndex(end) ~=length(msg)
                msg = sprintf('%s\n',msg);
            end
            javaMethodEDT('appendResults',optimtoolGui,['Warning: ',msg]);
            lastwarn('');
        end
            javaMethodEDT('setIteration',optimtoolGui,value2RHS(optimval.iteration));
        %Action based on run mode of GUI
        RunMode = javaMethodEDT('getRunMode',optimtoolGui);
        switch RunMode
            case RUN_RESUME
              % Nothing to do
            case STOP   %Stop
                stop = true;
                return;
            case PAUSE  %Pause
                fprintf('%s\n%s\n','OPTIMTOOL is paused. MATLAB Command prompt will', ...
                    'not be accessible until the simulated annealing solver is completed.');
                %If in pause state keeping looping here.
                while true
                    drawnow
                    if isempty(javaMethodEDT('getOptimGUI','com.mathworks.toolbox.optim.OptimGUI'))
                        stop = true;
                        return;
                    end
                    mode = javaMethodEDT('getRunMode',optimtoolGui);
                    if mode == STOP
                        stop = true;
                        return;
                    elseif mode == RUN_RESUME
                        modelCheck = true;
                        break;
                    end
                    pause(0.1);
                end % End while
            otherwise
                return;
        end

        if  javaMethodEDT('getChangedState',optimtoolGui) || modelCheck
            hashOptions = javaMethodEDT('getChangedOptionModelAndClear',optimtoolGui);
            % Empty problem hash table (problem fields can not change while
            % solver is running)
            hashProblem =javaObjectEDT('java.util.Hashtable');
            [unused1,optnew,unused2,errOpt] = readOptimHashTable(hashProblem, hashOptions);
            try
                if ~isempty(errOpt)
                    error('globaloptim:satooloutput:invalidModel',errOpt);
                end
                % Add output function to the list
                optnew = addOptimguiOutputFcn(optnew,'simulannealbnd');
                % Merge new and old options
                optnew = saoptimset(optlast,optnew);
                updateoptions = true;
            catch ME
                errordlg(ME.message,'Simulated Annealing run time error');
                javaMethodEDT('setRunMode',optimtoolGui,2)  %Set GUI to pause.
                optnew = optlast;  %Don't change the options if it contains errors
            end
        else
            optnew = optlast;
        end
    case 'interrupt'
        optimtoolGui = javaMethodEDT('getOptimGUI','com.mathworks.toolbox.optim.OptimGUI');
        if isempty(optimtoolGui)
            stop = true;
            return;
        end
        [msg,id] = lastwarn;
        if ~isempty(msg) && ~strcmp(id,getappdata(0,'last_warning_id_for_optimtool'))
            newLineIndex = regexp(msg,'\n');
            if isempty(newLineIndex) || newLineIndex(end) ~=length(msg)
                msg = sprintf('%s\n',msg);
            end
            javaMethodEDT('appendResults',optimtoolGui,['Warning: ',msg]);
            lastwarn('');
        end
        %Action based on run mode of GUI
        RunMode = javaMethodEDT('getRunMode',optimtoolGui);
        switch RunMode
            case RUN_RESUME
              % Nothing to do
            case STOP   %Stop
                stop = true;
                return;
            case PAUSE  %Pause
                fprintf('%s\n%s\n','OPTIMTOOL is paused. MATLAB Command prompt will', ...
                    'not be accessible until the simulated annealing solver is completed.');
                %If in pause state keeping looping here.
                while true
                    drawnow
                    if isempty(javaMethodEDT('getOptimGUI','com.mathworks.toolbox.optim.OptimGUI'))
                        stop = true;
                        return;
                    end
                    mode = javaMethodEDT('getRunMode',optimtoolGui);
                    if mode == STOP
                        stop = true;
                        return;
                    elseif mode == RUN_RESUME
                        break;
                    end
                    pause(0.1);
                end % End while
        end

    case 'done'
        optimtoolGui = javaMethodEDT('getOptimGUI','com.mathworks.toolbox.optim.OptimGUI');
        if isempty(optimtoolGui)
            stop = true;
            return;
        end
        javaMethodEDT('setIteration',optimtoolGui,value2RHS(optimval.iteration));
        if isappdata(0,'last_warning_id_for_optimtool')
            rmappdata(0,'last_warning_id_for_optimtool');
        end
 end
