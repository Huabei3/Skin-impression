function varargout = keyboardlistenerGUI(varargin)
global keyboard
% KEYBOARDLISTENERGUI M-file for keyboardlistenerGUI.fig
%      KEYBOARDLISTENERGUI, by itself, creates a new KEYBOARDLISTENERGUI or raises the existing
%      singleton*.
%
%      H = KEYBOARDLISTENERGUI returns the handle to a new KEYBOARDLISTENERGUI or the handle to
%      the existing singleton*.
%
%      KEYBOARDLISTENERGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in KEYBOARDLISTENERGUI.M with the given input arguments.
%
%      KEYBOARDLISTENERGUI('Property','Value',...) creates a new KEYBOARDLISTENERGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before keyboardlistenerGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to keyboardlistenerGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help keyboardlistenerGUI

% Last Modified by GUIDE v2.5 30-Oct-2014 22:44:18

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @keyboardlistenerGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @keyboardlistenerGUI_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before keyboardlistenerGUI is made visible.
function keyboardlistenerGUI_OpeningFcn(hObject, eventdata, handles, varargin)
global keyboard
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to keyboardlistenerGUI (see VARARGIN)

% Choose default command line output for keyboardlistenerGUI
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);
set(handles.keyboardonoff,'value',keyboard.onoff);
% UIWAIT makes keyboardlistenerGUI wait for user response (see UIRESUME)
% uiwait(handles.keyboardlistenerGUI);


% --- Outputs from this function are returned to the command line.
function varargout = keyboardlistenerGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in keyboardonoff.
function keyboardonoff_Callback(hObject, eventdata, handles)
% hObject    handle to keyboardonoff (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of keyboardonoff
global keyboard 
keyboard.processed=1;
keyboard.onoff=get(handles.keyboardonoff,'value');

% --- Executes on key release with focus on keyboardlistenerGUI and none of its controls.
function keyboardlistenerGUI_KeyReleaseFcn(hObject, eventdata, handles)
% hObject    handle to keyboardlistenerGUI (see GCBO)
% eventdata  structure with the following fields (see FIGURE)
%	Key: name of the key that was released, in lower case
%	Character: character interpretation of the key(s) that was released
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) released
% handles    structure with handles and user data (see GUIDATA)
global keyboard
keyboard.onoff=get(handles.keyboardonoff,'value');
keyboard_script
