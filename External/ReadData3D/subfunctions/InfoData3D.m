function varargout = InfoData3D(varargin)
% INFODATA3D M-file for InfoData3D.fig
%      INFODATA3D, by itself, creates a new INFODATA3D or raises the existing
%      singleton*.
%
%      H = INFODATA3D returns the handle to a new INFODATA3D or the handle to
%      the existing singleton*.
%
%      INFODATA3D('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in INFODATA3D.M with the given input arguments.
%
%      INFODATA3D('Property','Value',...) creates a new INFODATA3D or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before InfoData3D_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to InfoData3D_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help InfoData3D

% Last Modified by GUIDE v2.5 05-Jul-2010 15:13:54

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @InfoData3D_OpeningFcn, ...
                   'gui_OutputFcn',  @InfoData3D_OutputFcn, ...
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


% --- Executes just before InfoData3D is made visible.
function InfoData3D_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to InfoData3D (see VARARGIN)

% Choose default command line output for InfoData3D
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes InfoData3D wait for user response (see UIRESUME)
% uiwait(handles.figure1);

info=varargin{1};
infocell=cell(100000,2);
[infocell,poscell]=showinfo(info,infocell,0,'');
infocell(poscell+1:end,:)=[];
set(handles.uitable1,'Data',infocell)


function [infocell,poscell] = showinfo(info,infocell,poscell,s)
fnames=fieldnames(info);
for i=1:length(fnames)
    type=fnames{i};
    data=info.(type);
    if(isnumeric(data))
        poscell=poscell+1;
        infocell{poscell,1}=[s type];
        infocell{poscell,2}=num2str(data(:)');
    elseif(ischar(data))
        poscell=poscell+1;
        infocell{poscell,1}=[s type];
        infocell{poscell,2}=data;
    elseif(iscell(data))
    elseif(isstruct(data))
        [infocell,poscell]=showinfo(data,infocell,poscell,[type '.']);
    end
end



% --- Outputs from this function are returned to the command line.
function varargout = InfoData3D_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
