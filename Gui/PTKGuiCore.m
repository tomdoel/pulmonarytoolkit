classdef PTKGuiCore < GemFigure
    % PTKGui. The user interface for the TD Pulmonary Toolkit.
    %
    %     To start the user interface, run ptk.m.
    %
    %     You do not need to modify this file. To add new functionality, create
    %     new plguins in the Plugins and GuiPlugins folders.
    % 
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    properties (SetAccess = private)
        ImagePanel
        GuiSingleton
    end
    
    properties (SetObservable)
        DeveloperMode = false
    end
    
    properties (Access = private)
        AppDef
        GuiDataset
        WaitDialogHandle
        
        PatientNamePanel
        SidePanel
        ToolbarPanel
        StatusPanel

        OrganisedPlugins
        OrganisedManualSegmentations
        ModeTabControl

        MatNatBrowserFactory
        PatientBrowserFactory
        
        LastWindowSize % Keep track of window size to prevent unnecessary resize
        
        MarkerManager  % For loading and saving marker points
    end
    
    properties (Constant, Access = private)
        LoadMenuHeight = 23
        PatientBrowserWidth = 100
        SidePanelWidth = 250
        ModePanelMinimumWidth = 250
        ImageMinimumWidth = 200
    end
    
    methods
        function obj = PTKGuiCore(app_def, splash_screen)

            % Create the splash screen if it doesn't already exist
            if nargin < 2 || isempty(splash_screen) || ~isa(splash_screen, 'CoreProgressInterface')
                splash_screen = PTKSplashScreen.GetSplashScreen;
            end
            
            % Create the reporting object. Later we will update it with the viewer panel and
            % the new progress panel when these have been created.
            reporting = PTKReporting(splash_screen, PTKSoftwareInfo.WriteVerboseEntriesToLogFile, PTKDirectories.GetLogFilePath);
            reporting.Log('New session of PTKGui');
                        
            % Call the base class to initialise the figure class
            obj = obj@GemFigure(app_def.GetName, [], reporting);
            obj.StyleSheet = app_def.GetDefaultStyleSheet;

            obj.AppDef = app_def;

            % Set the figure title to the sotware name and version
            obj.Title = [app_def.GetName, ' ', app_def.GetVersion];
            
            % Set up the viewer panel
            if PTKSoftwareInfo.ViewerPanelToolbarEnabled
                obj.ImagePanel = PTKViewerPanelWithControlPanel(obj);
            else
                obj.ImagePanel = PTKViewerPanel(obj);
            end
            
            
            obj.ImagePanel.DefaultOrientation = app_def.GetDefaultOrientation;
            obj.AddChild(obj.ImagePanel);
            
            % Any unhandled keyboard input goes to the viewer panel
            obj.DefaultKeyHandlingObject = obj.ImagePanel;

            % Get the singleton, which gives access to the settings
            obj.GuiSingleton = PTKGuiSingleton.GetGuiSingleton(obj.Reporting);
            
            % Load the settings file
            obj.GuiSingleton.GetSettings.ApplySettingsToGui(obj, obj.ImagePanel);
            
            % Create the object which manages the current dataset
            obj.GuiDataset = PTKGuiDataset(app_def, obj, obj.ImagePanel, obj.GuiSingleton.GetSettings, obj.Reporting);

            obj.MarkerManager = PTKMarkerPointManager(obj.ImagePanel.MarkerLayer, obj.ImagePanel.MarkerImageSource, obj.ImagePanel.MarkerImageDisplayParameters, obj.ImagePanel, obj, obj.GuiDataset, reporting);
            
            % Create a callback handler for the Patient Browser and sidebar
            if obj.AppDef.MatNatEnabled
                mnConfig = matnattestconfig; % ToDo: the config file has to be defined
                matnat_database = PTKMatNatDatabase(mnConfig);
                combined_database = PTKCombinedImageDatabase(obj.GuiDataset.GetImageDatabase, matnat_database);
            else
                matnat_database = [];
                combined_database = obj.GuiDataset.GetImageDatabase;
            end
            combined_controller = PTKCombinedImageDatabaseController(obj, matnat_database);
            
            % Create the side panel showing available datasets
            obj.SidePanel = PTKSidePanel(obj, combined_controller, combined_database, obj.GuiDataset.GuiDatasetState, obj.GuiDataset.GetLinkedRecorder);
            obj.AddChild(obj.SidePanel);
            
            % Create the status panel showing image coordinates and
            % values of the voxel under the cursor
            obj.StatusPanel = PTKStatusPanel(obj, obj.ImagePanel);
            obj.AddChild(obj.StatusPanel);
            
            % The Patient Browser factory manages lazy creation of the Patient Browser. The
            % PB may take time to load if there are many datasets
            obj.PatientBrowserFactory = PTKPatientBrowserFactory(combined_controller, obj.GuiDataset.GetImageDatabase, obj.AppDef, obj.GuiDataset.GuiDatasetState, obj.GuiSingleton.GetSettings, 'Patient Browser : Pulmonary Toolkit', obj.Reporting);

            if obj.AppDef.MatNatEnabled
                % The MatNat Browser factory manages lazy creation of the
                % MatNat Browser. This may take some time to load as it has to
                % get the information from the server
                obj.MatNatBrowserFactory = PTKPatientBrowserFactory(combined_controller, matnat_database, obj.AppDef, obj.GuiDataset.GuiDatasetState, obj.GuiSingleton.GetSettings, 'MatNat', obj.Reporting);
            end
            
            % Map of all plugins visible in the GUI
            obj.OrganisedPlugins = PTKOrganisedPlugins(obj, obj.GuiDataset.GetPluginCache, app_def, obj.Reporting);
            obj.OrganisedManualSegmentations = PTKOrganisedManualSegmentations(obj, app_def, obj.Reporting);

            % Create the panel of tools across the bottom of the interface
            if PTKSoftwareInfo.ToolbarEnabled
                obj.ToolbarPanel = PTKToolbarPanel(obj, obj.OrganisedPlugins, 'Toolbar', [], 'Always', obj, obj.AppDef, false, false);
                obj.AddChild(obj.ToolbarPanel);
            end
            
            obj.ModeTabControl = PTKModeTabControl(obj, obj.OrganisedPlugins, obj.OrganisedManualSegmentations, obj.AppDef);
            obj.AddChild(obj.ModeTabControl);

            obj.PatientNamePanel = PTKNamePanel(obj, obj, obj.GuiDataset.GuiDatasetState);
            obj.AddChild(obj.PatientNamePanel);
            
            % Load the most recent dataset
            image_info = obj.GuiSingleton.GetSettings.ImageInfo;
            if ~isempty(image_info)
                obj.Reporting.ShowProgress('Loading images');
                obj.GuiDataset.InternalLoadImages(image_info);
            else
                obj.GuiDataset.SetNoDataset(false);

            end            
            
            % Resizing has to be done before we call Show(), and will ensure the GUI is
            % correctly laid out when it is shown
            position = obj.GuiSingleton.GetSettings.ScreenPosition;
            if isempty(position)
                position = [0, 0, CoreSystemUtilities.GetMonitorDimensions];
            end
            obj.Resize(position);
            
            % We need to force all the tabs to be created at this point, to ensure the
            % ordering is correct. The following Show() command will create the tabs, but
            % only if they are eabled
            obj.ModeTabControl.ForceEnableAllTabs;
            
            % Create the figure and graphical components
            obj.Show;
            
            % After creating all the tabs, we now re-disable the ones that should be hidden
            obj.GuiDataset.UpdateModeTabControl;
            
            % Add listener for switching modes when the tab is changed
            obj.AddEventListener(obj.ModeTabControl, 'PanelChangedEvent', @obj.ModeTabChanged);
            
            % Create a progress panel which will replace the progress dialog
            obj.WaitDialogHandle = GemProgressPanel(obj.ImagePanel);
            obj.WaitDialogHandle.ShowDebuggingControls = PTKSoftwareInfo.DebugMode;
            
            % Now we switch the reporting progress bar to a progress panel displayed over the gui
            obj.Reporting.ProgressDialog = obj.WaitDialogHandle;            
            
            % Ensure the GUI stack ordering is correct
            obj.ReorderPanels;

            obj.AddPostSetListener(obj, 'DeveloperMode', @obj.DeveloperModeChangedCallback);
            
            % Listen for changes in the viewer panel controls
            obj.AddPostSetListener(obj.ImagePanel, 'SelectedControl', @obj.ViewerPanelControlsChangedCallback);
            obj.AddPostSetListener(obj.ImagePanel.GetImageSliceParameters, 'Orientation', @obj.ViewerPanelControlsChangedCallback);
            obj.AddPostSetListener(obj.ImagePanel.GetImageSliceParameters, 'SliceNumber', @obj.ViewerPanelControlsChangedCallback);
            obj.AddPostSetListener(obj.ImagePanel.GetBackgroundImageDisplayParameters, 'Level', @obj.ViewerPanelControlsChangedCallback);
            obj.AddPostSetListener(obj.ImagePanel.GetBackgroundImageDisplayParameters, 'Window', @obj.ViewerPanelControlsChangedCallback);
            obj.AddPostSetListener(obj.ImagePanel.GetBackgroundImageDisplayParameters, 'ShowImage', @obj.ViewerPanelControlsChangedCallback);
            obj.AddPostSetListener(obj.ImagePanel.GetOverlayImageDisplayParameters, 'ShowImage', @obj.ViewerPanelControlsChangedCallback);
            obj.AddPostSetListener(obj.ImagePanel.GetOverlayImageDisplayParameters, 'Opacity', @obj.ViewerPanelControlsChangedCallback);
            obj.AddPostSetListener(obj.ImagePanel.GetOverlayImageDisplayParameters, 'BlackIsTransparent', @obj.ViewerPanelControlsChangedCallback);
            obj.AddPostSetListener(obj.ImagePanel.GetOverlayImageDisplayParameters, 'OpaqueColour', @obj.ViewerPanelControlsChangedCallback);
            obj.AddPostSetListener(obj.ImagePanel, 'SliceSkip', @obj.ViewerPanelControlsChangedCallback);
            obj.AddPostSetListener(obj.ImagePanel, 'PaintBrushSize', @obj.ViewerPanelControlsChangedCallback);
            obj.AddPostSetListener(obj.ImagePanel.MarkerImageDisplayParameters, 'ShowMarkers', @obj.ShowMarkersChanged);
            
            % Wait until the GUI is visible before removing the splash screen
            splash_screen.delete;
        end
        
        function ShowPatientBrowser(obj)
            obj.PatientBrowserFactory.Show;
        end
        
        function ShowMatNatBrowser(obj)
            if ~isempty(obj.MatNatBrowserFactory)
                obj.MatNatBrowserFactory.Show;
            end
        end
        
        function ChangeMode(obj, mode)
            obj.GuiDataset.ChangeMode(mode);
            obj.UpdateToolbar;
        end
        
        function SetTabMode(obj, mode)
            obj.ModeTabControl.AutoTabSelection(mode);
        end
        
        function CreateGuiComponent(obj, position)
            CreateGuiComponent@GemFigure(obj, position);

            obj.Reporting.SetViewerPanel(obj.ImagePanel);
        end
        
        function SaveEditedResult(obj)
            obj.GuiDataset.SaveEditedResult;
        end
        
        
        function SelectFilesAndLoad(obj)
            % Prompts the user for file(s) to load
            image_info = PTKChooseImagingFiles(obj.GuiSingleton.GetSettings.SaveImagePath, obj.Reporting);
            
            % An empty image_info means the user has cancelled
            if ~isempty(image_info)
                % Save the path in the settings so that future load dialogs 
                % will start from there
                obj.GuiSingleton.GetSettings.SetLastSaveImagePath(image_info.ImagePath, obj.Reporting);
                
                if (image_info.ImageFileFormat == PTKImageFileFormat.Dicom) && (isempty(image_info.ImageFilenames))
                    uiwait(msgbox('No valid DICOM files were found in this folder', [obj.AppDef.GetName ': No image files found.']));
                    obj.Reporting.ShowMessage('PTKGuiApp:NoFilesToLoad', ['No valid DICOM files were found in folder ' image_info.ImagePath]);
                else
                    obj.LoadImages(image_info);
                    
                end
            end
        end

        function uids = ImportFromPath(obj, file_path)
            % Imports from a given location
            
            obj.WaitDialogHandle.ShowAndHold('Loading data');
            
            % Import all datasets from this path
            uids = obj.GuiDataset.ImportDataRecursive(file_path);
            
            if ~isempty(uids)
                obj.GuiDataset.InternalLoadImages(uids{1});
            end
            obj.WaitDialogHandle.Hide;
        end
        
        function uids = ImportMultipleFiles(obj)
            % Prompts the user for file(s) to import
            
            obj.WaitDialogHandle.ShowAndHold('Import data');
            
            folder_path = CoreDiskUtilities.ChooseDirectory('Select a directory from which files will be imported', obj.GuiSingleton.GetSettings.SaveImagePath);
            
            % An empty folder_path means the user has cancelled
            if ~isempty(folder_path)
                
                % Save the path in the settings so that future load dialogs 
                % will start from there
                obj.GuiSingleton.GetSettings.SetLastSaveImagePath(folder_path, obj.Reporting);
                
                % Import all datasets from this path
                uids = obj.GuiDataset.ImportDataRecursive(folder_path);

                % Bring Patient Browser to the front after import
                obj.PatientBrowserFactory.Show;
            end
            
            obj.WaitDialogHandle.Hide;
        end
        
        function uids = ImportPatch(obj)
            % Prompts the user to import a patch
            
            obj.WaitDialogHandle.ShowAndHold('Import patch');
            
            [folder_path, filename, filter_index] = CoreDiskUtilities.ChooseFiles('Select the patch to import', obj.GuiSingleton.GetSettings.SaveImagePath, false, {'*.ptk', 'PTK Patch'});
            
            
            % An empty folder_path means the user has cancelled
            if ~isempty(folder_path)
                
                % Save the path in the settings so that future load dialogs 
                % will start from there
                obj.GuiSingleton.GetSettings.SetLastSaveImagePath(folder_path, obj.Reporting);
                
                patch = PTKDiskUtilities.LoadPatch(fullfile(folder_path, filename{1}), obj.Reporting);
                if (strcmp(patch.PatchType, 'EditedResult'))
                    uid = patch.SeriesUid;
                    plugin = patch.PluginName;
                    obj.LoadFromUid(uid);
                    obj.GuiDataset.RunPlugin(plugin, obj.WaitDialogHandle);
                    obj.ChangeMode(PTKModes.EditMode);
                    obj.GetMode.ImportPatch(patch);
                end
            end
            
            obj.WaitDialogHandle.Hide;
        end
               
        
               
        function SaveBackgroundImage(obj)
            patient_name = obj.ImagePanel.BackgroundImage.Title;
            image_data = obj.ImagePanel.BackgroundImage;
            path_name = obj.GuiSingleton.GetSettings.SaveImagePath;
            
            path_name = PTKSaveAs(image_data, patient_name, path_name, false, obj.Reporting);
            if ~isempty(path_name)
                obj.GuiSingleton.GetSettings.SetLastSaveImagePath(path_name, obj.Reporting);
            end
        end
        
        function SaveOverlayImage(obj)
            patient_name = obj.ImagePanel.BackgroundImage.Title;
            background_image = obj.ImagePanel.OverlayImage.Copy;
            template = obj.GuiDataset.GetTemplateImage;
            background_image.ResizeToMatch(template);
            image_data = background_image;
            path_name = obj.GuiSingleton.GetSettings.SaveImagePath;
            
            path_name = PTKSaveAs(image_data, patient_name, path_name, true, obj.Reporting);
            if ~isempty(path_name)
                obj.GuiSingleton.GetSettings.SetLastSaveImagePath(path_name, obj.Reporting);
            end
        end
        
        function RefreshPlugins(obj)
            obj.GuiDataset.RefreshPlugins;
            obj.ResizeGui(obj.Position, true);
        end

        function dataset_cache_path = GetDatasetCachePath(obj)
            dataset_cache_path = obj.GuiDataset.GetDatasetCachePath;
        end
        
        function edited_results_path = GetEditedResultsPath(obj)
            edited_results_path = obj.GuiDataset.GetEditedResultsPath;
        end

        function dataset_cache_path = GetOutputPath(obj)
            dataset_cache_path = obj.GuiDataset.GetOutputPath;
        end
        
        function image_info = GetImageInfo(obj)
            image_info = obj.GuiDataset.GetImageInfo;
        end        
        
        function ClearCacheForThisDataset(obj)
            obj.GuiDataset.ClearCacheForThisDataset;
        end
        
        function plugin_name = GetCurrentPluginName(obj)
            plugin_name = obj.GuiDataset.GuiDatasetState.CurrentPluginName;
        end
        
        function Capture(obj)
            % Captures an image from the viewer, including the background and transparent
            % overlay. Prompts the user for a filename
            
            path_name = obj.GuiSingleton.GetSettings.SaveImagePath;
            [filename, path_name, save_type] = PTKDiskUtilities.SaveImageDialogBox(path_name);
            if ~isempty(path_name) && ischar(path_name)
                obj.GuiSingleton.GetSettings.SetLastSaveImagePath(path_name, obj.Reporting);
            end
            if (filename ~= 0)
                % Hide the progress bar before capture
                obj.Reporting.ProgressDialog.Hide;
                frame = obj.ImagePanel.Capture;
                PTKDiskUtilities.SaveImageCapture(frame, PTKFilename(path_name, filename), save_type, obj.Reporting)
            end
        end
        
        function DeleteOverlays(obj)
            obj.ImagePanel.ClearOverlays;
            obj.GuiDataset.InvalidateCurrentPluginResult;
        end
        
        function ResetCurrentPlugin(obj)
            obj.GuiDataset.InvalidateCurrentPluginResult;
        end
        
        function LoadFromPatientBrowser(obj, series_uid, fallback_patient_id)
            obj.BringToFront;
            obj.GuiDataset.SwitchPatient(fallback_patient_id);
            obj.LoadFromUid(series_uid);
        end
        
        function LoadPatient(obj, patient_id)
            obj.GuiDataset.SwitchPatient(patient_id);
            datasets = obj.GuiDataset.GetImageDatabase.GetAllSeriesForThisPatient(PTKImageDatabase.LocalDatabaseId, patient_id);
            if isempty(datasets)
                series_uid = [];
            else
                last_uid = obj.GuiSingleton.GetSettings.GetLastPatientUid(patient_id);
                if ~isempty(last_uid) && ismember(last_uid, CoreContainerUtilities.GetFieldValuesFromSet(datasets, 'SeriesUid'))
                    series_uid  = last_uid;
                else
                    series_uid = PTKImageUtilities.FindBestSeries(datasets);
                end
            end
            obj.LoadFromUid(series_uid);
        end
        
        function ForceRefresh(obj)
            obj.SidePanel.Refresh;
        end
        
        function CloseAllFiguresExceptPtk(obj)
            all_figure_handles = get(0, 'Children');
            for figure_handle = all_figure_handles'

                if ~isempty(obj.MatNatBrowserFactory)
                    if (figure_handle ~= obj.GraphicalComponentHandle) && (~obj.PatientBrowserFactory.HandleMatchesPatientBrowser(figure_handle)) && (~obj.MatNatBrowserFactory.HandleMatchesPatientBrowser(figure_handle))
                        if ishandle(figure_handle)
                            delete(figure_handle);
                        end
                    end
                else
                    if (figure_handle ~= obj.GraphicalComponentHandle) && (~obj.PatientBrowserFactory.HandleMatchesPatientBrowser(figure_handle))
                        if ishandle(figure_handle)
                            delete(figure_handle);
                        end
                    end
                end
            end
        end
        
        function Resize(obj, new_position)
            Resize@GemFigure(obj, new_position);
            obj.ResizeGui(new_position, false);
        end
        
        function delete(obj)
            delete(obj.GuiDataset);

            if ~isempty(obj.Reporting);
                obj.Reporting.Log('Closing PTKGui');
            end
        end        

        function DeleteThisImageInfo(obj)
            obj.GuiDataset.DeleteThisImageInfo;
        end
        
        function DeleteImageInfo(obj, uid)
            obj.GuiDataset.DeleteImageInfo(uid);
        end

        function DeleteDatasets(obj, series_uids)
            obj.WaitDialogHandle.ShowAndHold('Deleting data');
            obj.GuiDataset.DeleteDatasets(series_uids);
            obj.WaitDialogHandle.Hide;
        end
        
        function UnlinkDataset(obj, series_uid)
            if obj.GuiDataset.GetLinkedRecorder.IsPrimaryDataset(series_uid)
                choice = questdlg('This dataset is linked to multiple other datasets. Do you want to unlink all these datasets?', ...
                    'Unlink dataset', 'Unlink', 'Don''t unlink', 'Don''t unlink');
                switch choice
                    case 'Unlink'
                        obj.GuiDataset.GetLinkedRecorder.RemoveLink(series_uid, obj.Reporting);
                    case 'Don''t unlink'
                end
            else
                obj.GuiDataset.GetLinkedRecorder.RemoveLink(series_uid, obj.Reporting);
            end
        end     

        function DeleteDataset(obj, series_uid)
            choice = questdlg('Do you want to delete this series?', ...
                'Delete dataset', 'Delete', 'Don''t delete', 'Don''t delete');
            switch choice
                case 'Delete'
                    obj.DeleteDatasets(series_uid);
                case 'Don''t delete'
            end
        end
        
        function DeletePatient(obj, patient_id)
            choice = questdlg('Do you want to delete this patient?', ...
                'Delete patient', 'Delete', 'Don''t delete', 'Don''t delete');
            switch choice
                case 'Delete'
                    obj.BringToFront;
                    
                    series_descriptions = obj.GuiDataset.GetImageDatabase.GetAllSeriesForThisPatient(PTKImageDatabase.LocalDatabaseId, patient_id);
                    
                    series_uids = {};
                    
                    for series_index = 1 : numel(series_descriptions)
                        series_uids{series_index} = series_descriptions{series_index}.SeriesUid;
                    end
                    
                    obj.DeleteDatasets(series_uids);
                    
                case 'Don''t delete'
            end
        end
        
        function mode = GetMode(obj)
            mode = obj.GuiDataset.GetMode;
        end
        
        function mode_name = GetCurrentModeName(obj)
            mode_name = obj.GuiDataset.GetCurrentModeName;
        end
        
        function mode_name = GetCurrentSubModeName(obj)
            mode_name = obj.GuiDataset.GetCurrentSubModeName;
        end
        
        function RunGuiPluginCallback(obj, plugin_name)
            
            wait_dialog = obj.WaitDialogHandle;
            
            plugin_info = feval(plugin_name);
            wait_dialog.ShowAndHold([plugin_info.ButtonText]);

            plugin_info.RunGuiPlugin(obj);
            
            obj.UpdateToolbar;
            
            wait_dialog.Hide;
        end
        
        function RunPluginCallback(obj, plugin_name)
            wait_dialog = obj.WaitDialogHandle;
            obj.GuiDataset.RunPlugin(plugin_name, wait_dialog);
        end
        
        function LoadSegmentationCallback(obj, segmentation_name)
            wait_dialog = obj.WaitDialogHandle;
            obj.GuiDataset.LoadManualSegmentation(segmentation_name, wait_dialog);
        end
        
        function dataset_is_loaded = IsDatasetLoaded(obj)
            dataset_is_loaded = obj.GuiDataset.DatasetIsLoaded;
        end
        
        function is_ct = IsCT(obj)
            is_ct = strcmp(obj.GuiDataset.GuiDatasetState.CurrentModality, 'CT');
        end
        
        function is_mr = IsMR(obj)
            is_mr = strcmp(obj.GuiDataset.GuiDatasetState.CurrentModality, 'MR');
        end
        
        function ToolClicked(obj)
            obj.UpdateToolbar;
        end
    
        function ClearDataset(obj)
            obj.WaitDialogHandle.ShowAndHold('Clearing dataset');
            obj.GuiDataset.ClearDataset;
            obj.WaitDialogHandle.Hide;
        end
        
        function segmentation_list = GetListOfManualSegmentations(obj)
            segmentation_list = obj.GuiDataset.GetListOfManualSegmentations;
        end
        
        function LoadMarkers(obj)
            wait_dialog = obj.WaitDialogHandle;
            wait_dialog.ShowAndHold('Loading Markers');
            obj.MarkerManager.LoadMarkers;
            wait_dialog.Hide;
        end
    end
    
    methods (Access = protected)
        
        function ViewerPanelControlsChangedCallback(obj, ~, ~, ~)
            % This methods is called when controls in the viewer panel have changed
            
            if obj.ImagePanel.IsInMarkerMode
                obj.MarkerManager.LazyLoadMarkerImage;
            end
            
            obj.UpdateToolbar;
        end
        
        
        function input_has_been_processed = Keypressed(obj, click_point, key)
            % Shortcut keys are normally processed by the object over which the mouse
            % pointer is located. If a key hasn't been processed, we divert it to the viewer
            % panel so that viewer panel shortcuts will work from other parts of the GUI.            
            input_has_been_processed = obj.ImagePanel.ShortcutKeys(key);

            % Failing that, we allow the side panel to execute shortcuts
            if ~input_has_been_processed
                input_has_been_processed = obj.SidePanel.ShortcutKeys(key);
            end
        end

        
        function CustomCloseFunction(obj, src, ~)
            % Executes when application closes
            obj.Reporting.ShowProgress('Saving settings');
            
            % Hide the Patient Browser and MatNatBrowser, as they can take a short time to close
            obj.PatientBrowserFactory.Hide;
            
            if ~isempty(obj.MatNatBrowserFactory)
                obj.MatNatBrowserFactory.Hide;
            end

            obj.ApplicationClosing();
            
            delete(obj.PatientBrowserFactory);
            if ~isempty(obj.MatNatBrowserFactory)
                delete(obj.MatNatBrowserFactory);
            end
            
            % The progress dialog will porbably be destroyed before we get here
%             obj.Reporting.CompleteProgress;

            CustomCloseFunction@GemFigure(obj, src);
        end    
    end
    
    methods (Access = private)
        
        function ApplicationClosing(obj)
            obj.MarkerManager.AutoSaveMarkers;
            obj.SaveSettings;
        end
        
        function ResizeCallback(obj, ~, ~, ~)
            % Executes when figure is resized
            obj.Resize;
        end
        
        function DeveloperModeChangedCallback(obj, ~, ~, ~)
            % This methods is called when the DeveloperMode property is changed
            
            obj.GuiDataset.UpdateModeTabControl;
            obj.RefreshPlugins;
        end
        
        
        function ShowMarkersChanged(obj, ~, ~)
            obj.MarkerManager.LazyLoadMarkerImage;
        end
        
        function LoadFromUid(obj, series_uid)
            
            % Get the UID of the currently loaded dataset
            currently_loaded_image_UID = obj.GuiDataset.GetUidOfCurrentDataset;
            
            % Check whether this image is already loaded. If no dataset is loaded and a null
            % dataset is requested, this also counts as a match
            image_already_loaded = strcmp(series_uid, currently_loaded_image_UID) || ...
                (isempty(series_uid) && isempty(currently_loaded_image_UID));
            
            % We prevent data re-loading when the same dataset is selected.
            % Also, due to a Matlab/Java bug, this callback may be called twice 
            % when an option is selected from the drop-down load menu using 
            % keyboard shortcuts. This will prevent the loading function from
            % being called twice
            if ~image_already_loaded
                if ~isempty(series_uid)
                    obj.LoadImages(series_uid);
                else
                    % Clear dataset
                    obj.ClearDataset;
                end
            end
        end
        
        
        function LoadImages(obj, image_info_or_uid)
            obj.WaitDialogHandle.ShowAndHold('Loading dataset');
            obj.GuiDataset.InternalLoadImages(image_info_or_uid);
            obj.WaitDialogHandle.Hide;
        end

        function ReplaceOverlayImageAdjustingSize(obj, new_image, title, colour_label_map, new_parent_map, new_child_map)
            new_image.ResizeToMatch(obj.ImagePanel.BackgroundImage);
            obj.ImagePanel.OverlayImage.ChangeRawImage(new_image.RawImage, new_image.ImageType);
            obj.ImagePanel.OverlayImage.Title = title;
            if ~isempty(colour_label_map)
                obj.ImagePanel.OverlayImage.ChangeColorLabelMap(colour_label_map);
            end
            if ~(isempty(new_parent_map)  && isempty(new_child_map))
                obj.ImagePanel.OverlayImage.ChangeColorLabelParentChildMap(new_parent_map, new_child_map)
            end
        end


        function ReplaceOverlayImage(obj, new_image, title, colour_label_map, new_parent_map, new_child_map)
            obj.ImagePanel.OverlayImage.ChangeRawImage(new_image.RawImage, new_image.ImageType);
            obj.ImagePanel.OverlayImage.Title = title;
            if ~isempty(colour_label_map)
                obj.ImagePanel.OverlayImage.ChangeColorLabelMap(colour_label_map);
            end
            if ~(isempty(new_parent_map)  && isempty(new_child_map))
                obj.ImagePanel.OverlayImage.ChangeColorLabelParentChildMap(new_parent_map, new_child_map)
            end
        end


        function ReplaceQuiverImageAdjustingSize(obj, new_image)
            new_image.ResizeToMatch(obj.ImagePanel.BackgroundImage);
            obj.ImagePanel.QuiverImage.ChangeRawImage(new_image.RawImage, new_image.ImageType);
        end


        function ReplaceQuiverImage(obj, new_image, image_type)
            obj.ImagePanel.QuiverImage.ChangeRawImage(new_image, image_type);
        end




        
        function ResizeGui(obj, parent_position, force_resize)
            
            parent_width_pixels = parent_position(3);
            parent_height_pixels = parent_position(4);
            
            new_size = [parent_width_pixels, parent_height_pixels];
            if isequal(new_size, obj.LastWindowSize) && ~force_resize
                return;
            end
            obj.LastWindowSize = new_size;
            
            if PTKSoftwareInfo.ToolbarEnabled
                toolbar_height = obj.ToolbarPanel.ToolbarHeight;
            else
                toolbar_height = 0;
            end
            
            status_panel_height = obj.StatusPanel.GetRequestedHeight;
            
            patient_name_panel_height = obj.PatientNamePanel.GetRequestedHeight;
            
            viewer_panel_height = max(1, parent_height_pixels - toolbar_height - patient_name_panel_height);
            
            side_panel_height = max(1, parent_height_pixels - toolbar_height - status_panel_height);
            side_panel_width = obj.SidePanelWidth;
            
            obj.SidePanel.Resize([1, 1 + toolbar_height + status_panel_height, side_panel_width, side_panel_height]);

            if PTKSoftwareInfo.ViewerPanelToolbarEnabled
                image_height_pixels = viewer_panel_height - obj.ImagePanel.ControlPanelHeight;
            else
                image_height_pixels = viewer_panel_height;
            end
            
            image_width_pixels = max(obj.ImageMinimumWidth, obj.GetSuggestedWidth(image_height_pixels));
            viewer_panel_width = image_width_pixels + GemSlider.SliderWidth;
            
            
            mode_panel_width = max(1, parent_width_pixels - viewer_panel_width - side_panel_width);

            % The right panel has a minimum width
            viewer_panel_reduction = max(0, obj.ModePanelMinimumWidth - mode_panel_width);
            
            % The image has a minimum width
            viewer_panel_reduction = viewer_panel_reduction - max(0, (obj.ImageMinimumWidth - (image_width_pixels - viewer_panel_reduction)));
            
            viewer_panel_width = viewer_panel_width - viewer_panel_reduction;
            mode_panel_width = mode_panel_width + viewer_panel_reduction;

            patient_name_panel_width = viewer_panel_width;

            
            plugins_panel_height = max(1, parent_height_pixels - toolbar_height - status_panel_height);
            
            image_panel_x_position = 1 + side_panel_width;
            image_panel_y_position = 1 + toolbar_height;
            obj.ImagePanel.Resize([image_panel_x_position, image_panel_y_position, viewer_panel_width, viewer_panel_height]);

            patient_name_panel_y_position = 1 + toolbar_height + viewer_panel_height;
            obj.PatientNamePanel.Resize([image_panel_x_position, patient_name_panel_y_position, patient_name_panel_width, patient_name_panel_height]);
            
            if PTKSoftwareInfo.ToolbarEnabled
                toolbar_width = parent_width_pixels;
                obj.ToolbarPanel.Resize([1, 1, toolbar_width, toolbar_height]);
            end
            
            right_side_position = image_panel_x_position + viewer_panel_width;
            
            obj.ModeTabControl.Resize([right_side_position, 1 + toolbar_height + status_panel_height, mode_panel_width, plugins_panel_height]);
            obj.StatusPanel.Resize([right_side_position, 1 + toolbar_height, mode_panel_width, status_panel_height]);
            
            if ~isempty(obj.WaitDialogHandle)
                obj.WaitDialogHandle.Resize();
            end
            
        end

        function ModeTabChanged(obj, ~, event_data)
            mode = obj.ModeTabControl.GetModeToSwitchTo(event_data.Data);
            obj.ChangeMode(mode);
        end
        
    end
    
    methods

        %%% Callbacks from GuiDataset
        
        function UpdateModeTabControl(obj, plugin_info)
            obj.ModeTabControl.UpdateMode(plugin_info);
        end
        
        function AddPreviewImage(obj, plugin_name, dataset)
            obj.ModeTabControl.AddPreviewImage(plugin_name, dataset, obj.ImagePanel.Window, obj.ImagePanel.Level);
        end
        
        function ClearImages(obj)
            if obj.GuiDataset.DatasetIsLoaded
                obj.MarkerManager.AutoSaveMarkers;
                obj.MarkerManager.ClearMarkers
                obj.ImagePanel.BackgroundImage.Reset;
            end
            obj.DeleteOverlays;
        end
        
        function RefreshPluginsForDataset(obj, dataset)
            obj.ModeTabControl.RefreshPlugins(dataset, obj.ImagePanel.Window, obj.ImagePanel.Level)
        end
        
        function SetImage(obj, new_image)
            obj.ImagePanel.BackgroundImage = new_image;
            
            if obj.ImagePanel.OverlayImage.ImageExists
                obj.ImagePanel.OverlayImage.ResizeToMatch(new_image);
            else
                obj.ImagePanel.OverlayImage = new_image.BlankCopy;
            end
            
            if obj.ImagePanel.QuiverImage.ImageExists
                obj.ImagePanel.QuiverImage.ResizeToMatch(new_image);
            else
                obj.ImagePanel.QuiverImage = new_image.BlankCopy;
            end
            
            % Make image visible when it is altered
            obj.ImagePanel.ShowImage = true;
            
            % Force a resize. This is so that the image panel can resize itself to optimally
            % fit the image. If however the image panel is changed to retain a fixed size
            % between datasets, then this resize is not necessary.
            if obj.ComponentHasBeenCreated
                obj.ResizeGui(obj.Position, true);
            end
        end
        
        function UpdateGuiForNewDataset(obj, dataset)
            obj.ModeTabControl.UpdateGuiForNewDataset(dataset, obj.ImagePanel.Window, obj.ImagePanel.Level);
        end

        function ReplaceOverlayImageCallback(obj, new_image, image_title)
            if isequal(new_image.ImageSize, obj.ImagePanel.BackgroundImage.ImageSize) && isequal(new_image.Origin, obj.ImagePanel.BackgroundImage.Origin)
                obj.ReplaceOverlayImage(new_image, image_title, new_image.ColorLabelMap, new_image.ColourLabelParentMap, new_image.ColourLabelChildMap)
            else
                obj.ReplaceOverlayImageAdjustingSize(new_image, image_title, new_image.ColorLabelMap, new_image.ColourLabelParentMap, new_image.ColourLabelChildMap);
            end
            
            % Make overlay visible when it is altered
            obj.ImagePanel.ShowOverlay = true;
        end
        
        function ReplaceQuiverImageCallback(obj, new_image)
            if all(new_image.ImageSize(1:3) == obj.ImagePanel.BackgroundImage.ImageSize(1:3)) && all(new_image.Origin == obj.ImagePanel.BackgroundImage.Origin)
                obj.ReplaceQuiverImage(new_image.RawImage, 4);
            else
                obj.ReplaceQuiverImageAdjustingSize(new_image);
            end
        end

        function LoadMarkersIfRequired(obj)
            obj.MarkerManager.LoadMarkersIfRequired;
        end
        
        function UpdateToolbar(obj)
            if PTKSoftwareInfo.ToolbarEnabled
                obj.ToolbarPanel.Update(obj);
            end
            obj.ModeTabControl.UpdateDynamicPanels;
        end

        
        %%% Callbacks and also called from within this class
        
        
        function SaveSettings(obj)
            settings = obj.GuiSingleton.GetSettings;
            if ~isempty(settings)
                set(obj.GraphicalComponentHandle, 'units', 'pixels');
                settings = obj.GuiSingleton.GetSettings;
                settings.SetPosition(get(obj.GraphicalComponentHandle, 'Position'), obj.PatientBrowserFactory.GetScreenPosition);
                settings.UpdateSettingsFromGui(obj, obj.ImagePanel);
                settings.SaveSettings(obj.Reporting);
            end
        end
        
        function ReorderPanels(obj)
            % Ensure the stack order is correct, to stop the scrolling panels appearing on
            % top of the version panel or drop-down menu
            
            child_handles = get(obj.GraphicalComponentHandle, 'Children');
            
            if isempty(obj.ToolbarPanel)
                toolbar_handle = [];
            else
                toolbar_handle = obj.ToolbarPanel.GraphicalComponentHandle;
            end
            other_handles = setdiff(child_handles, toolbar_handle);
            reordered_handles = [other_handles; toolbar_handle];
            set(obj.GraphicalComponentHandle, 'Children', reordered_handles);
        end
        
        function SetTab(obj, tab_name)
            obj.ModeTabControl.ChangeSelectedTab(tab_name);
        end
        
        function enabled = IsTabEnabled(obj, panel_mode_name)
            enabled = obj.ModeTabControl.IsTabEnabled(panel_mode_name);
        end
        
        function reporting = GetReporting(obj)
            reporting = obj.Reporting;
        end
    end
    
    methods (Access = private)
        
        function suggested_width_pixels = GetSuggestedWidth(obj, image_height_pixels)
            % Computes the width of the viewer so that the coronal view fills the whole window
            
            % If no dataset, then just make the viewer square
            if ~obj.GuiDataset.DatasetIsLoaded
                suggested_width_pixels = image_height_pixels;
                return;
            end
            
            image_size_mm = obj.ImagePanel.BackgroundImage.ImageSize.*obj.ImagePanel.BackgroundImage.VoxelSize;

            % We choose the preferred orientation based on the image
            % Note we could change this to the current orientation
            % (obj.ImagePanel.Orientation), but if we did this we would need to force a
            % GUI resize whenever the orientation was changed
            optimal_direction_orientation = PTKImageUtilities.GetPreferredOrientation(obj.ImagePanel.BackgroundImage, obj.AppDef.GetDefaultOrientation);
            
            [dim_x_index, dim_y_index, dim_z_index] = GemUtilities.GetXYDimensionIndex(optimal_direction_orientation);
            
            image_height_mm = image_size_mm(dim_y_index);
            image_width_mm = image_size_mm(dim_x_index);
            suggested_width_pixels = ceil(image_width_mm*image_height_pixels/image_height_mm);
            
            suggested_width_pixels = max(suggested_width_pixels, ceil((2/3)*image_height_pixels));
            suggested_width_pixels = min(suggested_width_pixels, ceil((5/3)*image_height_pixels));
        end
    end
end
