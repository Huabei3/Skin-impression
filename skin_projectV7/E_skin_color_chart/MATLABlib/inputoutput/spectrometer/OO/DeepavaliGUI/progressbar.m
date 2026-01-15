%change progressbar
% global deltatime_;
% deltatime_=abs(user_minint_);
%i=0;

% while handles.spdisread==0;
    if i==handles.nlevels;i=0;end
    i=i+1;
    srgbim_level_i=handles.srgbim;
    srgbim_level_i(:,i*handles.nsublevels+1:end,:)=0;
    set(handles.axes_progress_,'HandleVisibility','ON'); 
    axes(handles.axes_progress_);
    imagesc(srgbim_level_i);axis off; axis equal;axis image
    %deltatime_=abs(user_minint_);
    pause_t=max([deltatime_./handles.nlevels,handles.pause_tmin]);
    if STOPSTART_==1;pause(pause_t);else;message='Determining optimal integration time.';set(handles.messages,'String',message);pause(0.001);end
% end
if spdisread_==1;
    srgbim_level_i=handles.srgbim;
    set(handles.axes_progress_,'HandleVisibility','ON'); 
    axes(handles.axes_progress_);
    imagesc(srgbim_level_i);axis off; axis equal;axis image
end
    



