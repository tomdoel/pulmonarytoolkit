classdef MimGuiBase < GemFigure
    % MimGuiBase. The base class for MIM user interface applications
    %
    %     To create an application, inherit from this class and provide an
    %     app_def object. See MivGui.m for an example.
    % 
    %
    %     Licence
    %     -------
    %     Part of the TD MIM Toolkit. https://github.com/tomdoel
    %     Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
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

        PreviewFetcher
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
        function obj = MimGuiBase(app_def, splash_screen)

            % Create the splash screen if it doesn't already exist
            if nargin < 2 || isempty(splash_screen) || ~isa(splash_screen, 'CoreProgressInterface')
                splash_screen = MimSplashScreen.GetSplashScreen;
            end
            
            % Create the reporting object. Later we will update it with the viewer panel and
            % the new progress panel when these have been created.
            reporting = MimReporting(splash_screen, app_def.WriteVerboseEntriesToLogFile, app_def.GetLogFilePath);
            reporting.Log('New session of MimGui');
                        
            % Call the base class to initialise the figure class
            obj = obj@GemFigure(app_def.GetName, [], reporting);
            obj.StyleSheet = app_def.GetDefaultStyleSheet;

            obj.AppDef = app_def;

            % Set the figure title to the sotware name and version
            obj.Title = [app_def.GetName, ' ', app_def.GetVersion];
            
            % Set up the viewer panel
            obj.ImagePanel = MimViewerPanel(obj);
            
            obj.ImagePanel.DefaultOrientation = app_def.GetDefaultOrientation;
            obj.AddChild(obj.ImagePanel);
            
            % Any unhandled keyboard input goes to the viewer panel
            obj.DefaultKeyHandlingObject = obj.ImagePanel;

            % Get the singleton, which gives access to the settings
            obj.GuiSingleton = MimGuiSingleton.GetGuiSingleton(app_def, obj.Reporting);
            
            % Load the settings file
            obj.GuiSingleton.GetSettings.ApplySettingsToGui(obj, obj.ImagePanel);
            
            % Create the object which manages the current dataset
            obj.GuiDataset = MimGuiDataset(app_def, obj, obj.ImagePanel, obj.GuiSingleton.GetSettings, obj.Reporting);

            obj.MarkerManager = MimMarkerPointManager(obj.ImagePanel.MarkerLayer, obj.ImagePanel.MarkerImageSource, obj.ImagePanel.MarkerImageDisplayParameters, obj.ImagePanel.BackgroundImageSource, obj.ImagePanel, obj, obj.GuiDataset, obj.AppDef, reporting);
            
            % Create a callback handler for the Patient Browser and sidebar
            if obj.AppDef.MatNatEnabled
                mnConfig = matnattestconfig; % ToDo: the config file has to be defined
                matnat_database = MimMatNatDatabase(mnConfig);
                combined_database = MimCombinedImageDatabase(obj.GuiDataset.GetImageDatabase, matnat_database);
            else
                matnat_database = [];
                combined_database = obj.GuiDataset.GetImageDatabase;
            end
            combined_controller = MimCombinedImageDatabaseController(obj, matnat_database);
            
            % Create the side panel showing available datasets
            obj.SidePanel = MimSidePanel(obj, combined_controller, combined_database, obj.GuiDataset.GuiDatasetState, obj.GuiDataset.GetLinkedRecorder, obj.AppDef.GroupPatientsWithSameName);
            obj.AddChild(obj.SidePanel);
            
            % Create the status panel showing image coordinates and
            % values of the voxel under the cursor
            obj.StatusPanel = MimStatusPanel(obj, obj.ImagePanel);
            obj.AddChild(obj.StatusPanel);
            
            % The Patient Browser factory manages lazy creation of the Patient Browser. The
            % PB may take time to load if there are many datasets
            obj.PatientBrowserFactory = MimPatientBrowserFactory(combined_controller, obj.GuiDataset.GetImageDatabase, obj.AppDef, obj.GuiDataset.GuiDatasetState, obj.GuiSingleton.GetSettings, obj.Reporting);

            if obj.AppDef.MatNatEnabled
                % The MatNat Browser factory manages lazy creation of the
                % MatNat Browser. This may take some time to load as it has to
                % get the information from the server
                obj.MatNatBrowserFactory = MimPatientBrowserFactory(combined_controller, matnat_database, obj.AppDef, obj.GuiDataset.GuiDatasetState, obj.GuiSingleton.GetSettings, 'MatNat', obj.Reporting);
            end
            
            % Map of all plugins visible in the GUI
            obj.OrganisedPlugins = MimOrganisedPlugins(obj, obj.GuiDataset.GetPluginCache, app_def, obj.Reporting);
            obj.OrganisedManualSegmentations = MimOrganisedManualSegmentations(obj, app_def, obj.Reporting);

            % Create the panel of tools across the bottom of the interface
            obj.ToolbarPanel = MimToolbarPanel(obj, obj.OrganisedPlugins, 'Toolbar', [], 'Always', obj, obj.AppDef, false, false);
            obj.AddChild(obj.ToolbarPanel);
            
            obj.PreviewFetcher = MimPreviewFetcher(obj.GuiDataset);
            obj.ModeTabControl = MimModeTabControl(obj, obj.PreviewFetcher, obj.OrganisedPlugins, obj.OrganisedManualSegmentations, obj.MarkerManager, obj.GuiDataset.GuiDatasetState, obj.AppDef);
            obj.AddChild(obj.ModeTabControl);

            obj.PatientNamePanel = MimNamePanel(obj, obj, obj.GuiDataset.GuiDatasetState);
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
            obj.GuiDataset.UpdateModeTabControl();
            
            % Add listener for switching modes when the tab is changed
            obj.AddEventListener(obj.ModeTabControl, 'PanelChangedEvent', @obj.ModeTabChanged);
            
            % Create a progress panel which will replace the progress dialog
            obj.WaitDialogHandle = GemProgressPanel(obj.ImagePanel);
            obj.WaitDialogHandle.ShowDebuggingControls = app_def.GetFrameworkAppDef.IsDebugMode;
            
            % Now we switch the reporting progress bar to a progress panel displayed over the gui
            obj.Reporting.ProgressDialog = obj.WaitDialogHandle;            
            
            % Ensure the GUI stack ordering is correct
            obj.ReorderPanels;

            obj.AddPostSetListener(obj, 'DeveloperMode', @obj.DeveloperModeChangedCallback);
            
            % Listen for changes in the viewer panel controls
            obj.AddPostSetListener(obj.ImagePanel, 'SelectedControl', @obj.ViewerPanelControlsChangedCallback);
            obj.AddPostSetListener(obj.ImagePanel, 'NewMarkerColour', @obj.ViewerPanelControlsChangedCallback);
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
            obj.AddPostSetListener(obj.ImagePanel, 'PaintBrushColour', @obj.ViewerPanelControlsChangedCallback);
            obj.AddPostSetListener(obj.ImagePanel.MarkerImageDisplayParameters, 'ShowMarkers', @obj.ShowMarkersChanged);
            obj.AddPostSetListener(obj.ImagePanel.MarkerImageDisplayParameters, 'ShowLabels', @obj.ViewerPanelControlsChangedCallback);
            
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
            obj.UpdateToolbar();
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
            image_info = MimChooseImagingFiles(obj.GuiSingleton.GetSettings.SaveImagePath, obj.Reporting);
            
            % An empty image_info means the user has cancelled
            if ~isempty(image_info)
                % Save the path in the settings so that future load dialogs 
                % will start from there
                obj.GuiSingleton.GetSettings.SetLastSaveImagePath(image_info.ImagePath, obj.Reporting);
                
                if (image_info.ImageFileFormat == MimImageFileFormat.Dicom) && (isempty(image_info.ImageFilenames))
                    uiwait(msgbox('No valid DICOM files were found in this folder', [obj.AppDef.GetName ': No image files found.']));
                    obj.Reporting.ShowMessage('MimGuiBase:NoFilesToLoad', ['No valid DICOM files were found in folder ' image_info.ImagePath]);
                else
                    obj.LoadImages(image_info);
                    
                end
            end
        end

        function uids = ImportFromPath(obj, file_path)
            % Imports from a given location
            
            obj.WaitDialogHandle.ShowAndHold('Loading data');
            
            % Import all datasets from this path
            [uids, patient_ids] = obj.GuiDataset.ImportDataRecursive(file_path);
            
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
                [uids, patient_ids] = obj.GuiDataset.ImportDataRecursive(folder_path);

                % Load the first patient
                if ~isempty(patient_ids)
                    obj.LoadPatient(patient_ids{1});
                end
                
                % Bring Patient Browser to the front after import
                obj.PatientBrowserFactory.Show();
            end
            
            obj.WaitDialogHandle.Hide();
        end
        
        function ImportPatch(obj)
            % Prompts the user to import a patch
            
            obj.WaitDialogHandle.ShowAndHold('Import patch');
            
            [folder_path, filename, filter_index] = CoreDiskUtilities.ChooseFiles('Select the patch to import', obj.GuiSingleton.GetSettings.SaveImagePath, false, {'*.ptk', 'PTK Patch'});
            
            
            % An empty folder_path means the user has cancelled
            if ~isempty(folder_path)
                
                % Save the path in the settings so that future load dialogs 
                % will start from there
                obj.GuiSingleton.GetSettings.SetLastSaveImagePath(folder_path, obj.Reporting);
                
                patch = MimDiskUtilities.LoadPatch(fullfile(folder_path, filename{1}), obj.Reporting);
                if (strcmp(patch.PatchType, 'EditedResult'))
                    uid = patch.SeriesUid;
                    plugin = patch.PluginName;
                    obj.LoadFromUid(uid);
                    obj.GuiDataset.RunPlugin(plugin, obj.WaitDialogHandle);
                    obj.ChangeMode(MimModes.EditMode);
                    obj.GetMode.ImportPatch(patch);
                end
            end
            
            obj.WaitDialogHandle.Hide;
        end
               
        
               
        function SaveBackgroundImage(obj)
            patient_name = obj.ImagePanel.BackgroundImage.Title;
            image_data = obj.ImagePanel.BackgroundImage;
            path_name = obj.GuiSingleton.GetSettings.SaveImagePath;
            
            path_name = MimSaveAs(image_data, patient_name, path_name, false, obj.AppDef.GetDicomMetadata, obj.Reporting);
            if ~isempty(path_name)
                obj.GuiSingleton.GetSettings.SetLastSaveImagePath(path_name, obj.Reporting);
            end
        end
        
        function SaveOverlayImage(obj)
            patient_name = obj.ImagePanel.BackgroundImage.Title;
            overlay_image = obj.ImagePanel.OverlayImage.Copy();
            template = obj.GuiDataset.GetTemplateImage();
            overlay_image.ResizeToMatch(template);
            image_data = overlay_image;
            path_name = obj.GuiSingleton.GetSettings().SaveImagePath;
            
            path_name = MimSaveAs(image_data, patient_name, path_name, true, obj.AppDef.GetDicomMetadata, obj.Reporting);
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
        
        function image_info = GetPatientName(obj)
            image_info = obj.GuiDataset.GetPatientName;
        end        
        
        function ClearCacheForThisDataset(obj)
            obj.GuiDataset.ClearCacheForThisDataset;
        end
        
        function plugin_name = GetCurrentPluginName(obj)
            plugin_name = obj.GuiDataset.GuiDatasetState.CurrentPluginName;
        end
        
        function plugin_name = CurrentSegmentationName(obj)
            plugin_name = obj.GuiDataset.GuiDatasetState.CurrentSegmentationName;
        end
        
        function Capture(obj)
            % Captures an image from the viewer, including the background and transparent
            % overlay. Prompts the user for a filename
            
            path_name = obj.GuiSingleton.GetSettings.SaveImagePath;
            [filename, path_name, save_type] = MimDiskUtilities.SaveImageDialogBox(path_name);
            if ~isempty(path_name) && ischar(path_name)
                obj.GuiSingleton.GetSettings.SetLastSaveImagePath(path_name, obj.Reporting);
            end
            if (filename ~= 0)
                % Hide the progress bar before capture
                obj.Reporting.ProgressDialog.Hide;
                frame = obj.ImagePanel.Capture;
                MimDiskUtilities.SaveImageCapture(frame, CoreFilename(path_name, filename), save_type, obj.Reporting)
            end
        end
        
        function DeleteOverlays(obj)
            obj.ImagePanel.ClearOverlays();
            obj.GuiDataset.InvalidateCurrentPluginResult();
        end
        
        function ResetCurrentPlugin(obj)
            obj.GuiDataset.InvalidateCurrentPluginResult();
        end
        
        function LoadFromPatientBrowser(obj, series_uid, fallback_patient_id)
            obj.BringToFront;
            obj.GuiDataset.SwitchPatient(fallback_patient_id);
            obj.LoadFromUid(series_uid);
        end
        
        function LoadPatient(obj, patient_id)
            obj.GuiDataset.SwitchPatient(patient_id);
            datasets = obj.GuiDataset.GetImageDatabase.GetAllSeriesForThisPatient(MimImageDatabase.LocalDatabaseId, patient_id, obj.AppDef.GroupPatientsWithSameName);
            if isempty(datasets)
                series_uid = [];
            else
                last_uid = obj.GuiSingleton.GetSettings.GetLastPatientUid(patient_id);
                if ~isempty(last_uid) && ismember(last_uid, CoreContainerUtilities.GetFieldValuesFromSet(datasets, 'SeriesUid'))
                    series_uid  = last_uid;
                else
                    series_uid = MimImageUtilities.FindBestSeries(datasets);
                end
            end
            obj.LoadFromUid(series_uid);
        end
        
        function ForceRefresh(obj)
            obj.SidePanel.Refresh;
        end
        
        function CloseAllFiguresExceptMim(obj)
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
                obj.Reporting.Log('Closing MimGui');
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
                    
                    series_descriptions = obj.GuiDataset.GetImageDatabase.GetAllSeriesForThisPatient(MimImageDatabase.LocalDatabaseId, patient_id, obj.AppDef.GroupPatientsWithSameName);
                    
                    series_uids = {};
                    
                    for series_index = 1 : numel(series_descriptions)
                        series_uids{series_index} = series_descriptions{series_index}.SeriesUid;
                    end
                    
                    obj.DeleteDatasets(series_uids);
                    
                case 'Don''t delete'
            end
        end
        
        function mode = GetMode(obj)
            mode = obj.GuiDataset.GetMode();
        end
        
        function mode_name = GetCurrentModeName(obj)
            mode_name = obj.GuiDataset.GetCurrentModeName;
        end
        
        function mode_name = GetCurrentSubModeName(obj)
            mode_name = obj.GuiDataset.GetCurrentSubModeName();
        end
        
        function RunGuiPluginCallback(obj, plugin_name)
            
            wait_dialog = obj.WaitDialogHandle;
            
            plugin_info = feval(plugin_name);
            wait_dialog.ShowAndHold([plugin_info.ButtonText]);

            if strcmp(plugin_info.PluginInterfaceVersion, '1')
                plugin_info.RunGuiPlugin(obj);
            else
                plugin_info.RunGuiPlugin(obj, obj.Reporting);
            end
            
            plugin_info.RunGuiPlugin(obj, obj.Reporting);
            
            obj.UpdateToolbar();
            
            wait_dialog.Hide;
        end
        
        function RunPluginCallback(obj, plugin_name)
            wait_dialog = obj.WaitDialogHandle;
            obj.GuiDataset.RunPlugin(plugin_name, wait_dialog);
        end
        
        function LoadSegmentationCallback(obj, segmentation_name)
            wait_dialog = obj.WaitDialogHandle;
            obj.AutoSaveSegmentation();
            obj.GuiDataset.LoadAndDisplayManualSegmentation(segmentation_name, wait_dialog);
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
        
        function is_linked_dataset = IsLinkedDataset(obj, linked_name_or_uid)
            % Returns true if another dataset has been linked to this one, using
            % the name or uid specified
            
            is_linked_dataset = obj.GuiDataset.IsLinkedDataset(linked_name_or_uid);
       end
        
        function is_gas_mri = IsGasMRI(obj)
            % Check if this is a hyperpolarised gas MRI image
            
            is_gas_mri = obj.GuiDataset.IsGasMRI();
        end        
        
        function ToolClicked(obj)
            obj.UpdateToolbar();
        end
    
        function ClearDataset(obj)
            obj.WaitDialogHandle.ShowAndHold('Clearing dataset');
            obj.GuiDataset.ClearDataset;
            obj.WaitDialogHandle.Hide;
        end
        
        function segmentation_list = GetListOfManualSegmentations(obj)
            segmentation_list = obj.GuiDataset.GetListOfManualSegmentations;
        end
        
        function segmentation_list = GetListOfMarkerSets(obj)
            if isempty(obj.GuiDataset)
                segmentation_list = [];
            else
                segmentation_list = obj.GuiDataset.GetListOfMarkerSets;
            end
        end
        
        function SaveTableAsCSV(obj, plugin_name, subfolder_name, file_name, description, table, file_dim, row_dim, col_dim, filters)
            obj.GuiDataset.SaveTableAsCSV(plugin_name, subfolder_name, file_name, description, table, file_dim, row_dim, col_dim, filters);
        end
        
        function LoadDefaultMarkers(obj)
            % Loads the default marker set for this dataset, which could be
            % the last used marker set or the marker set with the default name
            
            currently_loaded_image_UID = obj.GuiDataset.GetUidOfCurrentDataset();
            marker_set_name = obj.GuiSingleton.GetSettings.GetLastMarkerSetName(currently_loaded_image_UID);            
            if isempty(marker_set_name)
                marker_set_name = obj.AppDef.DefaultMarkersName;
            end
            
            obj.LoadAndDisplayMarkers(marker_set_name);
        end
        
        function LoadAndDisplayMarkers(obj, name)
            % Loads the specified marker set for this dataset
            wait_dialog = obj.WaitDialogHandle;
            wait_dialog.ShowAndHold('Loading Markers');
            
            obj.MarkerManager.LoadMarkers(name);
            obj.ImagePanel.ShowMarkers = true;

            % Store current marker set name
            currently_loaded_image_UID = obj.GuiDataset.GetUidOfCurrentDataset();
            obj.GuiSingleton.GetSettings.AddLastMarkerSet(currently_loaded_image_UID, name);
            obj.SaveSettings();
            
            obj.UpdateToolbar();
            wait_dialog.Hide();
        end
        
        function ExportMarkers(obj)
            obj.MarkerManager.AutoSaveMarkers();
            
            marker_list = obj.ImagePanel.MarkerImageSource.MarkerList;
            patient_name = obj.ImagePanel.BackgroundImage.Title;
            image_info = obj.GuiDataset.GetImageInfo;
            series_uid = image_info.ImageUid;
            template_image = obj.ImagePanel.BackgroundImage;
            path_name = obj.GuiSingleton.GetSettings.SaveImagePath;
            
            MimSaveMarkerListAsXml(path_name, marker_list, patient_name, series_uid, template_image, obj.Reporting);
        end
        
        function handle = GetRenderAxes(obj)
            handle = obj.ImagePanel.GetRenderAxes;
        end
        
        function handle = GetRenderPanel(obj)
            handle = obj.ImagePanel.GetRenderPanel;
        end
        
    end
    
    methods (Access = protected)
        
        function ViewerPanelControlsChangedCallback(obj, ~, ~, ~)
            % This methods is called when controls in the viewer panel have changed
            
            obj.LoadDefaultMarkersIfRequiredWithProgressBar();
            
            obj.UpdateToolbar();
        end
        
        
        function input_has_been_processed = Keypressed(obj, click_point, key, src, eventdata)
            % Shortcut keys are normally processed by the object over which the mouse
            % pointer is located. If a key hasn't been processed, we divert it to the viewer
            % panel so that viewer panel shortcuts will work from other parts of the GUI.            
            input_has_been_processed = obj.ImagePanel.ShortcutKeys(key);

            if strcmpi(key, 'd')
                obj.RunGuiPluginCallback('MimView3D');
                input_has_been_processed = true;
            end

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
            
            % The progress dialog will probably be destroyed before we get here
%             obj.Reporting.CompleteProgress;

            CustomCloseFunction@GemFigure(obj, src);
        end    
    end
    
    methods (Access = private)
        
        function ApplicationClosing(obj)
            obj.MarkerManager.AutoSaveMarkers();
            obj.AutoSaveSegmentation();
            obj.SaveSettings();
        end
        
        function AutoSaveSegmentation(obj)
            if ~isempty(obj.GetCurrentModeName)
                obj.GetMode.SaveEdit();
            end
        end

        function ResizeCallback(obj, ~, ~, ~)
            % Executes when figure is resized
            obj.Resize();
        end
        
        function DeveloperModeChangedCallback(obj, ~, ~, ~)
            % This methods is called when the DeveloperMode property is changed
            
            obj.GuiDataset.UpdateModeTabControl();
            obj.RefreshPlugins();
        end

        function ShowMarkersChanged(obj, ~, ~)
            if obj.MarkerManager.IsLoadMarkersRequired()
                obj.LoadDefaultMarkers();
            end
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
                    obj.ClearDataset();
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
            
            toolbar_height = obj.ToolbarPanel.ToolbarHeight;
            
            status_panel_height = obj.StatusPanel.GetRequestedHeight;
            
            patient_name_panel_height = obj.PatientNamePanel.GetRequestedHeight;
            
            viewer_panel_height = max(1, parent_height_pixels - toolbar_height - patient_name_panel_height);
            
            side_panel_height = max(1, parent_height_pixels - toolbar_height - status_panel_height);
            side_panel_width = obj.SidePanelWidth;
            
            obj.SidePanel.Resize([1, 1 + toolbar_height + status_panel_height, side_panel_width, side_panel_height]);

            image_height_pixels = viewer_panel_height;

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
            
            toolbar_width = parent_width_pixels;
            obj.ToolbarPanel.Resize([1, 1, toolbar_width, toolbar_height]);
            
            right_side_position = image_panel_x_position + viewer_panel_width;

            obj.ModeTabControl.Resize([right_side_position, 1 + toolbar_height + status_panel_height, mode_panel_width, plugins_panel_height]);
            obj.StatusPanel.Resize([right_side_position, 1 + toolbar_height, mode_panel_width, status_panel_height]);
            
            if ~isempty(obj.WaitDialogHandle)
                obj.WaitDialogHandle.Resize();
            end
            
        end

        function ModeTabChanged(obj, ~, event_data)
            mode = obj.ModeTabControl.GetModeToSwitchTo(event_data.Data);
            if ~isempty(mode)
                obj.ChangeMode(mode);
            end
        end
        
    end
    
    methods

        %%% Callbacks from GuiDataset
        
        function UpdateModeTabControl(obj, state)
            obj.ModeTabControl.UpdateMode(state);
        end
        
        function ClearImages(obj)
            obj.ImagePanel.ImageSliceParameters.UpdateLock = true;
            if obj.GuiDataset.DatasetIsLoaded
                obj.AutoSaveSegmentation();
                obj.MarkerManager.AutoSaveMarkers();
                obj.MarkerManager.ClearMarkers();
                obj.ImagePanel.BackgroundImage.Reset;
            end
            obj.DeleteOverlays();
            obj.ImagePanel.ImageSliceParameters.UpdateLock = false;                        
        end
        
        function RefreshPluginsForDataset(obj, dataset)
            obj.ModeTabControl.RefreshPlugins(dataset, obj.ImagePanel.Window, obj.ImagePanel.Level)
        end
        
        function SetImage(obj, new_image)
            obj.ImagePanel.ImageSliceParameters.UpdateLock = true;

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
            obj.ImagePanel.ImageSliceParameters.UpdateLock = false;            
        end
        
        function UpdateGuiForNewDataset(obj, preview_fetcher)
            obj.ModeTabControl.UpdateGuiForNewDataset(obj.PreviewFetcher, obj.ImagePanel.Window, obj.ImagePanel.Level);
            
            % We may need to enable tabs after loading a new dataset
            obj.GuiDataset.UpdateModeTabControl();
            obj.UpdateToolbar();
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

        function LoadDefaultMarkersIfRequiredWithoutProgressBar(obj)
            % If markers need to be displayed, load but do not show progress bar
            obj.MarkerManager.LoadMarkersIfRequired(obj.AppDef.DefaultMarkersName);
        end
        
        function LoadDefaultMarkersIfRequiredWithProgressBar(obj)
            % If markers need to be displayed, load and show progress bar
            if obj.MarkerManager.IsLoadMarkersRequired()
                obj.LoadDefaultMarkers();
            end
        end
        
        function UpdateToolbar(obj)
            obj.ToolbarPanel.Update(obj);
            obj.ModeTabControl.UpdateDynamicPanels();
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
        
        function app_def = GetAppDef(obj)
            app_def = obj.AppDef;
        end
        
        function reporting = GetReporting(obj)
            reporting = obj.Reporting;
        end
        
        function current_markers = GetCurrentMarkerSetName(obj)
            current_markers = obj.MarkerManager.GetCurrentMarkerSetName();
        end
        
        function AddMarkerSet(obj)
            name = inputdlg('Please enter a name for the new set of marker points you wish to create', 'New marker points');
            if ~isempty(name) && iscell(name) && (numel(name) > 0) && ~isempty(name{1})
                obj.MarkerManager.AddMarkerSet(name{1});
                obj.LoadAndDisplayMarkers(name{1});
            end
        end
        
        function DeleteMarkerSet(obj, name)
            choice = questdlg('Do you want to delete this marker set?', ...
                'Delete marker set', 'Delete', 'Don''t delete', 'Don''t delete');
            switch choice
                case 'Delete'
                    obj.MarkerManager.DeleteMarkerSet(name);
                    currently_loaded_image_UID = obj.GuiDataset.GetUidOfCurrentDataset;
                    obj.GuiSingleton.GetSettings.RemoveLastMarkerSet(currently_loaded_image_UID, name);
                    obj.LoadDefaultMarkers();
                    obj.MarkerManager.AutoSaveMarkers();
                    
                case 'Don''t delete'
            end
        end
        
        function RenameMarkerSet(obj, old_name)
            new_name = inputdlg('Please enter a new marker set name', 'Rename marker set');
            if ~isempty(new_name) && iscell(new_name) && (numel(new_name) > 0) && ~isempty(new_name{1})
                existing_file_list = CoreContainerUtilities.GetFieldValuesFromSet(obj.GetListOfMarkerSets(), 'Second');
                if any(strcmp(existing_file_list, new_name{1}))
                    choice = questdlg('A marker set with this name already exists. Do you want to overwrite this marker set?', ...
                    'Marker set already exists', 'Overwrite', 'Cancel', 'Cancel');
                    switch choice
                        case 'Overwrite'
                        otherwise
                            return
                    end
                end

                current_marker_set_name = obj.MarkerManager.GetCurrentMarkerSetName();
                is_current_marker_set = strcmp(current_marker_set_name, old_name);

                if is_current_marker_set
                    obj.MarkerManager.AutoSaveMarkers();
                end

                markers = obj.GuiDataset.LoadMarkers(old_name);
                if ~isempty(markers)
                    obj.GuiDataset.SaveMarkers(new_name{1}, markers);
                    if is_current_marker_set
                        obj.LoadAndDisplayMarkers(new_name{1});
                    end
                    obj.MarkerManager.DeleteMarkerSet(old_name);
                end
            end
        end
        
        function DuplicateMarkerSet(obj, old_name)
            new_name = inputdlg('Please enter a marker set name', 'Duplicate marker set');
            if ~isempty(new_name) && iscell(new_name) && (numel(new_name) > 0) && ~isempty(new_name{1})
                existing_file_list = CoreContainerUtilities.GetFieldValuesFromSet(obj.GetListOfMarkerSets(), 'Second');
                if any(strcmp(existing_file_list, new_name{1}))
                    choice = questdlg('A marker set with this name already exists. Do you want to overwrite this marker set?', ...
                    'Marker set already exists', 'Overwrite', 'Cancel', 'Cancel');
                    switch choice
                        case 'Overwrite'
                        otherwise
                            return
                    end
                end

                current_marker_set_name = obj.MarkerManager.GetCurrentMarkerSetName();
                is_current_marker_set = strcmp(current_marker_set_name, old_name);
                
                % If we are currently editing this marker set, save
                % before duplicating
                if is_current_marker_set
                    obj.MarkerManager.AutoSaveMarkers();
                end                

                markers = obj.GuiDataset.LoadMarkers(old_name);
                if ~isempty(markers)
                    obj.GuiDataset.SaveMarkers(new_name{1}, markers);
                end
            end
        end
        
        
        
        function ImportManualSegmentation(obj)
            if obj.IsDatasetLoaded()
                image_info = MimChooseImagingFiles(obj.GuiSingleton.GetSettings.SaveImagePath, obj.Reporting);
                if ~isempty(image_info)
                    if numel(image_info.ImageFilenames) == 1
                        [~, default, ~] = fileparts(image_info.ImageFilenames{1});
                    else
                        default = [];
                    end
                    obj.GuiSingleton.GetSettings.SetLastSaveImagePath(image_info.ImagePath, obj.Reporting);
                        name = inputdlg('Please enter a name for this segmentation', 'Import manual segmentation', 1, {default});
                    if ~isempty(name) && iscell(name) && (numel(name) > 0) && ~isempty(name{1})
                        if iscell(name)
                            name = name{1};
                        end
                        existing_file_list = CoreContainerUtilities.GetFieldValuesFromSet(obj.GetListOfManualSegmentations(), 'Second');
                        if any(strcmp(existing_file_list, name))
                            choice = questdlg('A segmentation with this name already exists. Do you want to overwrite this segmentation?', ...
                            'Segmentation already exists', 'Overwrite', 'Cancel', 'Cancel');
                            switch choice
                                case 'Overwrite'
                                otherwise
                                    return
                            end
                        end
                        
                        obj.Reporting.ShowProgress(['Importing segmentation ', name]);
                        
                        template = obj.GuiDataset.GetTemplateImage();
                        segmentation = MimLoadImages(image_info, obj.Reporting);
                        segmentation.ChangeRawImage(uint8(segmentation.RawImage));
                        segmentation.ImageType = PTKImageType.Colormap;
                        
                        if ~isequal(template.ImageSize, segmentation.ImageSize)
                            uiwait(errordlg('The segmentation cannot be imported as the image size does not match the original image', [obj.AppDef.GetName ': Cannot import segmentation for ' name], 'modal'));
                        elseif ~isequal(template.VoxelSize, segmentation.VoxelSize)
                            uiwait(errordlg('The segmentation cannot be imported as the voxel size does not match the original image', [obj.AppDef.GetName ': Cannot import segmentation for ' name], 'modal'));
                        else                        
                            obj.GuiDataset.SaveManualSegmentation(name, segmentation);
                            obj.LoadSegmentationCallback(name);
                        end

                        obj.Reporting.CompleteProgress;
                    end
                end
            end
        end
        
        function AddManualSegmentation(obj)
            obj.AutoSaveSegmentation();
            name = inputdlg('Please enter a name for the new manual segmentation you wish to create', 'New manual segmentation');
            if ~isempty(name) && iscell(name) && (numel(name) > 0) && ~isempty(name{1})
                existing_file_list = CoreContainerUtilities.GetFieldValuesFromSet(obj.GetListOfManualSegmentations(), 'Second');
                if any(strcmp(existing_file_list, name{1}))
                    choice = questdlg('A segmentation with this name already exists. Do you want to overwrite this segmentation?', ...
                    'Segmentation already exists', 'Overwrite', 'Cancel', 'Cancel');
                    switch choice
                        case 'Overwrite'
                        otherwise
                            return
                    end
                end

                segmentation = obj.GuiDataset.GetTemplateImage();
                template_raw = zeros(segmentation.ImageSize, 'uint8');
                segmentation.ChangeRawImage(template_raw);
                segmentation.ImageType = PTKImageType.Colormap;
                obj.GuiDataset.SaveManualSegmentation(name{1}, segmentation);
                obj.LoadSegmentationCallback(name{1});
            end
        end
        
        function RenameManualSegmentation(obj, old_name)
            new_name = inputdlg('Please enter a new segmentation name', 'Rename manual segmentation');
            if ~isempty(new_name) && iscell(new_name) && (numel(new_name) > 0) && ~isempty(new_name{1})
                existing_file_list = CoreContainerUtilities.GetFieldValuesFromSet(obj.GetListOfManualSegmentations(), 'Second');
                if any(strcmp(existing_file_list, new_name{1}))
                    choice = questdlg('A segmentation with this name already exists. Do you want to overwrite this segmentation?', ...
                    'Segmentation already exists', 'Overwrite', 'Cancel', 'Cancel');
                    switch choice
                        case 'Overwrite'
                        otherwise
                            return
                    end
                end

                current_segmentation_name = obj.GuiDataset.GuiDatasetState.CurrentSegmentationName;
                is_current_segentation = strcmp(current_segmentation_name, old_name);
                
                if is_current_segentation
                    if isequal(obj.GetCurrentModeName, MimModes.EditMode)
                        obj.AutoSaveSegmentation();
                    end
                end

                segmentation = obj.GuiDataset.LoadManualSegmentation(old_name);
                if ~isempty(segmentation)
                    obj.GuiDataset.SaveManualSegmentation(new_name{1}, segmentation);
                    if is_current_segentation
                        obj.LoadSegmentationCallback(new_name{1});
                    end
                    obj.GuiDataset.DeleteManualSegmentation(old_name);
                end
            end
        end
        
        function DuplicateManualSegmentation(obj, old_name)
            new_name = inputdlg('Please enter a new segmentation name', 'Duplicate manual segmentation');
            if ~isempty(new_name) && iscell(new_name) && (numel(new_name) > 0) && ~isempty(new_name{1})
                existing_file_list = CoreContainerUtilities.GetFieldValuesFromSet(obj.GetListOfManualSegmentations(), 'Second');
                if any(strcmp(existing_file_list, new_name{1}))
                    choice = questdlg('A segmentation with this name already exists. Do you want to overwrite this segmentation?', ...
                    'Segmentation already exists', 'Overwrite', 'Cancel', 'Cancel');
                    switch choice
                        case 'Overwrite'
                        otherwise
                            return
                    end
                end

                current_segmentation_name = obj.GuiDataset.GuiDatasetState.CurrentSegmentationName;
                is_current_segentation = strcmp(current_segmentation_name, old_name);
                
                % If we are currently editing this segmentation, save
                % before duplicating
                if is_current_segentation
                    if isequal(obj.GetCurrentModeName, MimModes.EditMode)
                        obj.AutoSaveSegmentation();
                    end
                end                

                segmentation = obj.GuiDataset.LoadManualSegmentation(old_name);
                if ~isempty(segmentation)
                    obj.GuiDataset.SaveManualSegmentation(new_name{1}, segmentation);
                end
            end
        end
        
        function DeleteManualSegmentation(obj, name)
            choice = questdlg('Do you want to delete this manual segmentation?', ...
                'Delete manual segmentation', 'Delete', 'Don''t delete', 'Don''t delete');
            switch choice
                case 'Delete'
                    obj.GuiDataset.DeleteManualSegmentation(name);
                case 'Don''t delete'
            end
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
            optimal_direction_orientation = MimImageUtilities.GetPreferredOrientation(obj.ImagePanel.BackgroundImage, obj.AppDef.GetDefaultOrientation);
            
            [dim_x_index, dim_y_index, dim_z_index] = GemUtilities.GetXYDimensionIndex(optimal_direction_orientation);
            
            image_height_mm = image_size_mm(dim_y_index);
            image_width_mm = image_size_mm(dim_x_index);
            suggested_width_pixels = ceil(image_width_mm*image_height_pixels/image_height_mm);
            
            suggested_width_pixels = max(suggested_width_pixels, ceil((2/3)*image_height_pixels));
            suggested_width_pixels = min(suggested_width_pixels, ceil((5/3)*image_height_pixels));
        end
    end
end
