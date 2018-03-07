function varargout = ErrorData3D(varargin)
% ERRORDATA3D M-file for ErrorData3D.fig
%      ERRORDATA3D, by itself, creates a new ERRORDATA3D or raises the existing
%      singleton*.
%
%      H = ERRORDATA3D returns the handle to a new ERRORDATA3D or the handle to
%      the existing singleton*.
%
%      ERRORDATA3D('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in ERRORDATA3D.M with the given input arguments.
%
%      ERRORDATA3D('Property','Value',...) creates a new ERRORDATA3D or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before ErrorData3D_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to ErrorData3D_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help ErrorData3D

% Last Modified by GUIDE v2.5 05-Jul-2010 15:17:44

% Begin initialization code - DO NOT EDIT
gui_Singleton = 0;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ErrorData3D_OpeningFcn, ...
                   'gui_OutputFcn',  @ErrorData3D_OutputFcn, ...
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


% --- Executes just before ErrorData3D is made visible.
function ErrorData3D_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ErrorData3D (see VARARGIN)

% Choose default command line output for ErrorData3D
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);
if (~isempty(varargin)) 
    set(handles.text1,'string',varargin{1})
end

% UIWAIT makes ErrorData3D wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = ErrorData3D_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in pushbutton1.
function pushbutton1_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
delete(handles.figure1);
