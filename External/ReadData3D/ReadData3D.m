function varargout = ReadData3D(varargin)
% This function ReadData3D allows the user to open medical 3D files. It
% supports the following formats :
%
%   Dicom Files ( .dcm , .dicom )
%   V3D Philips Scanner ( .v3d )
%   GIPL Guys Image Processing Lab ( .gipl )
%   HDR/IMG Analyze ( .hdr )
%   ISI Files ( .isi )
%   NifTi ( .nii )
%   RAW files ( .raw , .* )
%   VMP BrainVoyager ( .vmp )
%   XIF HDllab/ATL ultrasound ( .xif )
%   VTK Visualization Toolkit ( .vtk )
%   Insight Meta-Image ( .mha, .mhd )
%   Micro CT ( .vff )
%   PAR/REC Philips ( .par, .rec)
%
% usage:
%
% [V,info]=ReadData3D;               
%
% or, 
%
% [V,info]=ReadData3D(filename)
% 
% or,
%
% [V,info]=ReadData3D(filename,real);
%
%
% outputs,
%   V : The 3D Volume
%   info : Struct with info about the data
%        Always the following fields are present
%        info.Filename : Name of file
%        info.Dimensions : Dimensions of Volume
%        info.PixelDimensions : Size of one pixel / voxel 
%   real : If set to true (default), convert the raw data to 
%        type Single-precision  and rescale data to real units 
%        (in CT Hounsfield). When false, it returns the raw-data.
%
% Warning!
%  The read functions are not fully implemented as defined in
%  the file-format standards. thus do not use this function for 
%  critical applications.
%
%
% Function is written by D.Kroon University of Twente (July 2010)

% Edit the above text to modify the response to help ReadData3D

% Last Modified by GUIDE v2.5 09-Nov-2010 14:12:50

% Begin initialization code - DO NOT EDIT
gui_Singleton = 0;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @ReadData3D_OpeningFcn, ...
    'gui_OutputFcn',  @ReadData3D_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if (nargin>2) && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before ReadData3D is made visible.
function ReadData3D_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ReadData3D (see VARARGIN)

% Choose default command line output for ReadData3D
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes ReadData3D wait for user response (see UIRESUME)
% uiwait(handles.figure1);

%---- Start supported file formats ----%
data.fileformat(1).ext='*.dcm';
data.fileformat(1).type='Dicom Files';
data.fileformat(1).folder='dicom';
data.fileformat(1).functioninfo='dicom_read_header';
data.fileformat(1).functionread='dicom_read_volume';

data.fileformat(2).ext='*.gipl';
data.fileformat(2).type='GIPL Guys Image Processing Lab';
data.fileformat(2).folder='gipl';
data.fileformat(2).functioninfo='gipl_read_header';
data.fileformat(2).functionread='gipl_read_volume';

data.fileformat(3).ext='*.hdr';
data.fileformat(3).type='HDR/IMG Analyze';
data.fileformat(3).folder='hdr';
data.fileformat(3).functioninfo='hdr_read_header';
data.fileformat(3).functionread='hdr_read_volume';

data.fileformat(4).ext='*.isi';
data.fileformat(4).type='ISI Files';
data.fileformat(4).folder='isi';
data.fileformat(4).functioninfo='isi_read_header';
data.fileformat(4).functionread='isi_read_volume';

data.fileformat(5).ext='*.nii';
data.fileformat(5).type='NifTi';
data.fileformat(5).folder='nii';
data.fileformat(5).functioninfo='nii_read_header';
data.fileformat(5).functionread='nii_read_volume';

data.fileformat(6).ext='*.raw';
data.fileformat(6).type='RAW files';
data.fileformat(6).folder='raw';
data.fileformat(6).functioninfo='raw_read_header';
data.fileformat(6).functionread='raw_read_volume';

data.fileformat(7).ext='*.v3d';
data.fileformat(7).type='V3D Philips Scanner';
data.fileformat(7).folder='v3d';
data.fileformat(7).functioninfo='v3d_read_header';
data.fileformat(7).functionread='v3d_read_volume';

data.fileformat(8).ext='*.vmp';
data.fileformat(8).type='VMP BrainVoyager';
data.fileformat(8).folder='vmp';
data.fileformat(8).functioninfo='vmp_read_header';
data.fileformat(8).functionread='vmp_read_volume';

data.fileformat(9).ext='*.xif';
data.fileformat(9).type='XIF HDllab/ATL ultrasound';
data.fileformat(9).folder='xif';
data.fileformat(9).functioninfo='xif_read_header';
data.fileformat(9).functionread='xif_read_volume';

data.fileformat(10).ext='*.vtk';
data.fileformat(10).type='VTK Visualization Toolkit';
data.fileformat(10).folder='vtk';
data.fileformat(10).functioninfo='vtk_read_header';
data.fileformat(10).functionread='vtk_read_volume';

data.fileformat(11).ext='*.mha';
data.fileformat(11).type='Insight Meta-Image';
data.fileformat(11).folder='mha';
data.fileformat(11).functioninfo='mha_read_header';
data.fileformat(11).functionread='mha_read_volume';

data.fileformat(12).ext='*.vff';
data.fileformat(12).type='Micro CT';
data.fileformat(12).folder='vff';
data.fileformat(12).functioninfo='vff_read_header';
data.fileformat(12).functionread='vff_read_volume';

data.fileformat(13).ext='*.par';
data.fileformat(13).type='Philips PAR/REC';
data.fileformat(13).folder='par';
data.fileformat(13).functioninfo='par_read_header';
data.fileformat(13).functionread='par_read_volume';


%---- End supported file formats ----%


% Get path of ReadData3D
functionname='ReadData3D.m';
functiondir=which(functionname);
functiondir=functiondir(1:end-length(functionname));

% Add the file-reader functions also to the matlab path
addpath([functiondir '/subfunctions']);
for i=1:length(data.fileformat), addpath([functiondir '/' data.fileformat(i).folder]); end

% Make popuplist file formats
fileformatcell=cell(1,length(data.fileformat));
for i=1:length(data.fileformat), fileformatcell{i}=[data.fileformat(i).type '   (' data.fileformat(i).ext ')']; end
set(handles.popupmenu_format,'String',fileformatcell);

% Check if last filename is present from a previous time
data.configfile=[functiondir '/lastfile.mat'];
filename='';
fileformatid=1;
if(exist(data.configfile,'file')), load(data.configfile); end
data.handles=handles;
data.lastfilename=[];
data.volume=[];
data.info=[];

% If filename is selected, look if the extention is known
found=0;
if(~isempty(varargin))
    filename=varargin{1}; [pathstr,name,ext]=fileparts(filename);
    for i=1:length(data.fileformat)
        if(strcmp(data.fileformat(i).ext(2:end),ext)), found=1; fileformatid=i; end
    end
end

% Rescale the databack to original units.
if(length(varargin)>1), real=varargin{2}; else real=true; end
    
data.real=real;
data.filename=filename;
data.fileformatid=fileformatid;

set(handles.checkbox_real,'Value',data.real);
set(handles.edit_filename,'String',data.filename)
set(handles.popupmenu_format,'Value',data.fileformatid);

% Store all data
setMyData(data);

if(found==0)
    % Show Dialog File selection
    uiwait(handles.figure1);
else
    % Load the File directly
    loaddata();
end

% --- Outputs from this function are returned to the command line.
function varargout = ReadData3D_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
if(ishandle(hObject))
    data=getMyData();
else
    data=[];
end
if(~isempty(data))
    varargout{1} = data.volume;
    varargout{2} = data.info;
else
    varargout{1}=[];
    varargout{2}=[];
end
if(ishandle(hObject))
    close(hObject)
end

function edit_filename_Callback(hObject, eventdata, handles)
% hObject    handle to edit_filename (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_filename as text
%        str2double(get(hObject,'String')) returns contents of edit_filename as a double


% --- Executes during object creation, after setting all properties.
function edit_filename_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_filename (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in pushbutton_browse.
function pushbutton_browse_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_browse (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
data=getMyData();
[extlist extlistid]=FileDialogExtentionList(data);
[filename, dirname,filterindex] = uigetfile(extlist, 'Select a dicom file',fileparts(data.filename));
if(filterindex>0)
    if(extlistid(filterindex)~=0)
        data.fileformatid=extlistid(filterindex);
        set( handles.popupmenu_format,'Value',data.fileformatid);
    end
    if(filename==0), return; end
    filename=[dirname filename];
    data.filename=filename;
    setMyData(data);
    set(handles.edit_filename,'String',data.filename)
end

function [extlist extlistid]=FileDialogExtentionList(data)
extlist=cell(length(data.fileformat)+1,2);
extlistid=zeros(length(data.fileformat)+1,1);
ext=data.fileformat(data.fileformatid).ext;
type=data.fileformat(data.fileformatid).type;
extlistid(1)=data.fileformatid;
extlist{1,1}=ext; extlist{1,2}=[type ' (' ext ')'];
j=1;
for i=1:length(data.fileformat);
    if(i~=data.fileformatid)
        j=j+1;
        ext=data.fileformat(i).ext;
        type=data.fileformat(i).type;
        extlistid(j)=i;
        extlist{j,1}=ext; extlist{j,2}=[type ' (' ext ')'];
    end
end
extlist{end,1}='*.*';
extlist{end,2}='All Files (*.*)';


function setMyData(data)
% Store data struct in figure
setappdata(gcf,'dataload3d',data);

function data=getMyData()
% Get data struct stored in figure
data=getappdata(gcf,'dataload3d');

% --- Executes on button press in pushbutton_cancel.
function pushbutton_cancel_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_cancel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
setMyData([]);
uiresume;

% --- Executes on selection change in popupmenu_format.
function popupmenu_format_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_format (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_format contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_format
data=getMyData();
data.fileformatid=get( handles.popupmenu_format,'Value');
setMyData(data);


% --- Executes during object creation, after setting all properties.
function popupmenu_format_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_format (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton_load.
function pushbutton_load_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_load (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
data=getMyData();
data.filename=get(handles.edit_filename,'string');
loaddata();
pause(0.1);
uiresume

function loaddata()
data=getMyData();
set(data.handles.figure1,'Pointer','watch'); drawnow('expose');
if(~strcmp(data.lastfilename,data.filename))
    % Get info
    fhandle = str2func( data.fileformat(data.fileformatid).functioninfo);
    data.info=feval(fhandle,data.filename);
    data.lastfilename=data.filename;
end
fhandle = str2func( data.fileformat(data.fileformatid).functionread);
data.volume=feval(fhandle,data.info);
if(data.real)
    data.volume=single(data.volume);
    if(isfield(data.info,'RescaleSlope')), 
        data.volume=data.volume*data.info.RescaleSlope;
    else
        disp('RescaleSlope not available, assuming 1')
    end
    if(isfield(data.info,'RescaleIntercept')), 
        data.volume=data.volume+data.info.RescaleIntercept; 
    else
        disp('RescaleIntercept not available, assuming 0')
    end
end
setMyData(data);
set(data.handles.figure1,'Pointer','arrow')

% Save the filename, for the next time this function is used
filename=data.filename; fileformatid=data.fileformatid;
try save(data.configfile,'filename','fileformatid'); catch ME; disp(ME.message); end


% --- Executes on button press in pushbutton_info.
function pushbutton_info_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_info (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
data=getMyData();
data.filename=get(handles.edit_filename,'string');
if(~strcmp(data.lastfilename,data.filename))
    % Get info
    set(data.handles.figure1,'Pointer','watch'); drawnow('expose');
    fhandle = str2func( data.fileformat(data.fileformatid).functioninfo);
    data.info=feval(fhandle,data.filename);
    data.lastfilename=data.filename;
    set(data.handles.figure1,'Pointer','arrow')
end
setMyData(data);
% Show info
InfoData3D(data.info);


% --- Executes on button press in checkbox_real.
function checkbox_real_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_real (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_real
data=getMyData();
data.real=get(handles.checkbox_real,'Value');
setMyData(data);
    
