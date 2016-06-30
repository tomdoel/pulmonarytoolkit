function varargout = raw_read_header(varargin)
% function for reading header of raw volume file
%
% info = raw_read_header(filename);
%
% examples:
% 1,  info=raw_read_header()
% 2,  info=raw_read_header('volume.raw');

% Edit the above text to modify the response to help raw_read_header

% Last Modified by GUIDE v2.5 06-Jul-2010 14:01:48

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @raw_read_header_OpeningFcn, ...
                   'gui_OutputFcn',  @raw_read_header_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if (nargin>1) && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before raw_read_header is made visible.
function raw_read_header_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to raw_read_header (see VARARGIN)

% Choose default command line output for raw_read_header
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes raw_read_header wait for user response (see UIRESUME)
if(isempty(varargin))
    [filename, pathname] = uigetfile({'*.raw', 'Read Raw file (*.raw) ';'*.*', 'All Files (*.*)'});
    filename = [pathname filename];
else
    filename=varargin{1};
end

fileInfo = dir(filename);
info.Filesize= fileInfo.bytes;
info.Filename=filename;
setMyData(info);
updateGUIvalues(handles);
uiwait(handles.figure1);


function updateGUIvalues(handles)
info=getMyData();
set(handles.text_filesize,'string',['File Size (Bytes) : ' num2str(info.Filesize)]);
info.Headersize=str2double(get(handles.edit_header_size,'String'));
info.Dimensions(1)=str2double(get(handles.edit_dimx,'String'));
info.Dimensions(2)=str2double(get(handles.edit_dimy,'String'));
info.Dimensions(3)=str2double(get(handles.edit_dimz,'String'));

info.PixelDimensions(1)=str2double(get(handles.edit_scalex,'String'));
info.PixelDimensions(2)=str2double(get(handles.edit_scaley,'String'));
info.PixelDimensions(3)=str2double(get(handles.edit_scalez,'String'));
switch(get(handles.popupmenu_dataclass,'Value'))
    case 1
        info.Nbits=8;
        info.DataType='uchar';
    case 2
        info.Nbits=8;
        info.DataType='char';
    case 3
        info.Nbits=16;
        info.DataType='ushort';
    case 4
        info.Nbits=16;
        info.DataType='short';
    case 5
        info.Nbits=32;
        info.DataType='uint';
    case 6
        info.Nbits=32;
        info.DataType='int';
    case 7
        info.Nbits=32;
        info.DataType='float';
    case 8
        info.Nbits=64;
        info.DataType='double';        
end

switch(get(handles.popupmenu_data_alligment,'Value'))
    case 1
        info.Alignment='LittleEndian';
    case 2
        info.Alignment='BigEndian';
end
currentbytes=(info.Nbits/8)*info.Dimensions(1)*info.Dimensions(2)*info.Dimensions(3)+info.Headersize;
set(handles.text_setbytes,'string',['Current (Bytes) : ' num2str(currentbytes)]);
if(currentbytes==info.Filesize)
    set(handles.pushbutton1,'enable','on');
else
    set(handles.pushbutton1,'enable','off');    
end

drawnow
setMyData(info);

% --- Outputs from this function are returned to the command line.
function varargout = raw_read_header_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
info=getMyData();
if(~isempty(info))
    varargout{1} = info;
end
if(ishandle(hObject))
    close(hObject)
end

function edit_header_size_Callback(hObject, eventdata, handles)
% hObject    handle to edit_header_size (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_header_size as text
%        str2double(get(hObject,'String')) returns contents of edit_header_size as a double
updateGUIvalues(handles);

% --- Executes during object creation, after setting all properties.
function edit_header_size_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_header_size (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenu_data_alligment.
function popupmenu_data_alligment_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_data_alligment (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_data_alligment contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_data_alligment
updateGUIvalues(handles);

% --- Executes during object creation, after setting all properties.
function popupmenu_data_alligment_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_data_alligment (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenu_dataclass.
function popupmenu_dataclass_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_dataclass (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_dataclass contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_dataclass
updateGUIvalues(handles);

% --- Executes during object creation, after setting all properties.
function popupmenu_dataclass_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_dataclass (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_dimx_Callback(hObject, eventdata, handles)
% hObject    handle to edit_dimx (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_dimx as text
%        str2double(get(hObject,'String')) returns contents of edit_dimx as a double
updateGUIvalues(handles);

% --- Executes during object creation, after setting all properties.
function edit_dimx_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_dimx (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_dimy_Callback(hObject, eventdata, handles)
% hObject    handle to edit_dimy (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_dimy as text
%        str2double(get(hObject,'String')) returns contents of edit_dimy as a double
updateGUIvalues(handles);

% --- Executes during object creation, after setting all properties.
function edit_dimy_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_dimy (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_dimz_Callback(hObject, eventdata, handles)
% hObject    handle to edit_dimz (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_dimz as text
%        str2double(get(hObject,'String')) returns contents of edit_dimz as a double
updateGUIvalues(handles);

% --- Executes during object creation, after setting all properties.
function edit_dimz_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_dimz (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_scalex_Callback(hObject, eventdata, handles)
% hObject    handle to edit_scalex (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_scalex as text
%        str2double(get(hObject,'String')) returns contents of edit_scalex as a double
updateGUIvalues(handles);

% --- Executes during object creation, after setting all properties.
function edit_scalex_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_scalex (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_scaley_Callback(hObject, eventdata, handles)
% hObject    handle to edit_scaley (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_scaley as text
%        str2double(get(hObject,'String')) returns contents of edit_scaley as a double
updateGUIvalues(handles);

% --- Executes during object creation, after setting all properties.
function edit_scaley_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_scaley (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_scalez_Callback(hObject, eventdata, handles)
% hObject    handle to edit_scalez (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_scalez as text
%        str2double(get(hObject,'String')) returns contents of edit_scalez as a double
updateGUIvalues(handles);

% --- Executes during object creation, after setting all properties.
function edit_scalez_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_scalez (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton1.
function pushbutton1_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
updateGUIvalues(handles);
uiresume

% --- Executes on button press in pushbutton2.
function pushbutton2_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
setMyData(0);
uiresume

function setMyData(data)
% Store data struct in figure
setappdata(gcf,'rawinfo',data);

function data=getMyData()
% Get data struct stored in figure
data=getappdata(gcf,'rawinfo');


% --- Executes on key press with focus on edit_header_size and none of its controls.
function edit_header_size_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to edit_header_size (see GCBO)
% eventdata  structure with the following fields (see UICONTROL)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
updateGUIvalues(handles);

% --- Executes on key press with focus on edit_dimx and none of its controls.
function edit_dimx_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to edit_dimx (see GCBO)
% eventdata  structure with the following fields (see UICONTROL)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
updateGUIvalues(handles);

% --- Executes on key press with focus on edit_dimy and none of its controls.
function edit_dimy_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to edit_dimy (see GCBO)
% eventdata  structure with the following fields (see UICONTROL)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
updateGUIvalues(handles);

% --- Executes on key press with focus on edit_dimz and none of its controls.
function edit_dimz_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to edit_dimz (see GCBO)
% eventdata  structure with the following fields (see UICONTROL)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
updateGUIvalues(handles);

% --- Executes on key press with focus on edit_scalex and none of its controls.
function edit_scalex_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to edit_scalex (see GCBO)
% eventdata  structure with the following fields (see UICONTROL)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
updateGUIvalues(handles);

% --- Executes on key press with focus on edit_scaley and none of its controls.
function edit_scaley_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to edit_scaley (see GCBO)
% eventdata  structure with the following fields (see UICONTROL)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
updateGUIvalues(handles);

% --- Executes on key press with focus on edit_scalez and none of its controls.
function edit_scalez_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to edit_scalez (see GCBO)
% eventdata  structure with the following fields (see UICONTROL)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
updateGUIvalues(handles);

% --- Executes on key press with focus on popupmenu_dataclass and none of its controls.
function popupmenu_dataclass_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_dataclass (see GCBO)
% eventdata  structure with the following fields (see UICONTROL)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
updateGUIvalues(handles);

% --- Executes on key press with focus on popupmenu_data_alligment and none of its controls.
function popupmenu_data_alligment_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_data_alligment (see GCBO)
% eventdata  structure with the following fields (see UICONTROL)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
updateGUIvalues(handles);


% --- Executes on button press in pushbutton3.
function pushbutton3_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
info=getMyData();
currentbytes=(info.Nbits/8)*info.Dimensions(1)*info.Dimensions(2)*info.Dimensions(3);
info.Headersize=info.Filesize-currentbytes;
set(handles.edit_header_size,'String',num2str(info.Headersize));
updateGUIvalues(handles);
