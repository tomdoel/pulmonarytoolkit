function varargout = TDPTKGui(varargin)
    % TDPTKGui. The user interface for the TD Pulmonary Toolkit.
    %
    %     To start the user interface, run ptk.m.
    %
    %     You do not need to modify this file. To add new functionality, create
    %     new plguins in the Plugins and GuiPlugins folders.
    % 
    %     TDPTKGui.m, along with the corresponding .fig file, creates the
    %     basic user interface window for the Pulmonary Toolkit. This can be
    %     modified using Matlab's Guide editor:
    %
    %         guide('TDPTKGui');
    %
    %     Most of the user interface is constructed and managed programatically
    %     within the class TDPTKGuiApp.m. An instance of this is created and stored in
    %     the application data for the figure. This will be automatically destroyed
    %     when the application closes.
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @TDPTKGui_OpeningFcn, ...
                   'gui_OutputFcn',  @TDPTKGui_OutputFcn, ...
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



    
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Custom application events
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    

% Executes just before TDPTKGui is made visible.
function TDPTKGui_OpeningFcn(hObject, ~, handles, varargin)
    % Choose default command line output for TDPTKGui
    handles.output = hObject;

    % Update handles structure
    guidata(hObject, handles);

    % Set custom function for application closing
    set(handles.TDPTK_Figure, 'CloseRequestFcn', @CustomCloseFunction);

    % Create the application object
    if ~isempty(varargin) && isa(varargin{1}, 'TDProgressInterface')
        splash_screen = varargin{1};
    else
        splash_screen = [];
    end
    ptk_app = TDPTKGuiApp(handles.uipanel_image, handles.TDPTK_Figure, handles.uipanel_plugins, handles.popupmenu_load, handles.text_version, handles, splash_screen);
    
    % Store a handle to the application object in the figure data, so that it
    % can be obtained by the gui callbacks.
    SetPtkApp(handles, ptk_app);
    
    % Update the profile checkbox with the current status of the Matlab
    % profilers
    UpdateProfilerStatus(handles);
    


% Executes when application closes
function CustomCloseFunction(src, ~)
    ptk_app = getappdata(src, 'TDPTKHandle');
    ptk_app.ApplicationClosing();
    
    
    % Note: this will delete the only reference to the application 
    % object handle, triggering its destruction which will save settings
    delete(src);

    
% Default output function for returning values to the command line
function varargout = TDPTKGui_OutputFcn(~, ~, handles) 
    varargout{1} = handles.output;

% Executes during object deletion, before destroying properties
function TDPTK_Figure_DeleteFcn(~, ~, ~) %#ok<DEFNU>

% Executes when figure is resized
function TDPTK_Figure_ResizeFcn(~, ~, handles) %#ok<DEFNU>
    ptk = GetPtkAppFromHandles(handles);
    if ~isempty(ptk)
        ptk.Resize(handles);
    end

    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Gui callbacks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% Item selected from the pop-up "quick load" menu
function popupmenu_load_Callback(hObject, ~, handles) %#ok<DEFNU>
    GetPtkAppFromHandles(handles).LoadFromPopupMenu(get(hObject, 'Value'));

    
% Profile checkbox
% Enables or disables (and shows) Matlab's profiler
function checkbox_profile_Callback(hObject, ~, ~) %#ok<DEFNU>
    if get(hObject,'Value')
        profile on
    else
        profile viewer
    end

    
% Custom creation function for the Load pop-up menu
function popupmenu_load_CreateFcn(hObject, ~, ~) %#ok<DEFNU>
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[0, 0.129, 0.278]);
end






%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Helper functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% Retrieves a handle to the application object from the figure application data
function ptk_app = GetPtkAppFromHandles(handles)
    ptk_app = getappdata(handles.TDPTK_Figure, 'TDPTKHandle');

    
% Stores a handle to the application object in the figure application data
function SetPtkApp(handles, ptk_app)
    setappdata(handles.TDPTK_Figure, 'TDPTKHandle', ptk_app);

    
% Updates the "Show profile" check box according to the current running state 
% of the Matlab profiler    
function UpdateProfilerStatus(handles)
    profile_status = profile('status');
    if strcmp(profile_status.ProfilerStatus, 'on')
        set(handles.checkbox_profile, 'Value', true);
    else
        set(handles.checkbox_profile, 'Value', false);
    end

    
    
