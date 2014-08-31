classdef PTKGui < PTKFigure
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
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    properties (SetAccess = private)
        ImagePanel
        Reporting
        Settings
    end
    
    properties (Access = private)
        GuiDataset
        WaitDialogHandle
        MarkersHaveBeenLoaded = false
        
        PatientNamePanel
        SidePanel
        ToolbarPanel

        OrganisedPlugins
        ModeTabControl

        PatientBrowserFactory
        
        LastWindowSize % Keep track of window size to prevent unnecessary resize
    end
    
    properties (Constant, Access = private)
        LoadMenuHeight = 23
        PatientBrowserWidth = 100
        SidePanelWidth = 250
    end
    
    methods
        function obj = PTKGui(splash_screen)

            % Create the splash screen if it doesn't already exist
            if nargin < 1 || isempty(splash_screen) || ~isa(splash_screen, 'PTKProgressInterface')
                splash_screen = PTKSplashScreen.GetSplashScreen;
            end
            
            % Call the base class to initialise the figure class
            obj = obj@PTKFigure(PTKSoftwareInfo.Name, []);

            % Set the figure title to the sotware name and version
            obj.Title = [PTKSoftwareInfo.Name, ' ', PTKSoftwareInfo.Version];
            
            show_control_panel_in_viewer = PTKSoftwareInfo.ViewerPanelToolbarEnabled;
            
            % Set up the viewer panel
            obj.ImagePanel = PTKViewerPanel(obj, show_control_panel_in_viewer);
            obj.AddChild(obj.ImagePanel, obj.Reporting);
            
            % Any unhandled keyboard input goes to the viewer panel
            obj.DefaultKeyHandlingObject = obj.ImagePanel;

            % Create the reporting object. Later we will update it with the viewer panel and
            % the new progress panel when these have been created.
            obj.Reporting = PTKReporting(splash_screen, [], PTKSoftwareInfo.WriteVerboseEntriesToLogFile);
            obj.Reporting.Log('New session of PTKGui');
            
            % Load the settings file
            obj.Settings = PTKSettings.LoadSettings(obj.Reporting);
            obj.Settings.ApplySettingsToViewerPanel(obj.ImagePanel);
            
            % Create the object which manages the current dataset
            obj.GuiDataset = PTKGuiDataset(obj, obj.ImagePanel, obj.Settings, obj.Reporting);

            obj.SidePanel = PTKSidePanel(obj, obj.GuiDataset.GetImageDatabase, obj.GuiDataset.GuiDatasetState, obj.GuiDataset.GetLinkedRecorder, obj, obj.Reporting);
            obj.AddChild(obj.SidePanel, obj.Reporting);
            
            % The Patient Browser factory manages lazy creation of the Patient Browser. The
            % PB may take time to load if there are many datasets
            obj.PatientBrowserFactory = PTKPatientBrowserFactory(obj, obj.GuiDataset, obj.Settings, obj.Reporting);

            % Map of all plugins visible in the GUI
            obj.OrganisedPlugins = PTKOrganisedPlugins(obj.Settings, obj, obj.Reporting);

            % Create the panel of tools across the bottom of the interface
            if PTKSoftwareInfo.ToolbarEnabled
                obj.ToolbarPanel = PTKToolbarPanel(obj, obj.OrganisedPlugins, obj, obj.Settings, obj.Reporting);
                obj.AddChild(obj.ToolbarPanel, obj.Reporting);
            end
            
            obj.ModeTabControl = PTKModeTabControl(obj, obj.OrganisedPlugins, obj.Settings, obj.Reporting);
            obj.AddChild(obj.ModeTabControl, obj.Reporting);

            obj.PatientNamePanel = PTKNamePanel(obj, obj, obj.Settings, obj.GuiDataset.GuiDatasetState, obj.Reporting);
            obj.AddChild(obj.PatientNamePanel, obj.Reporting);
            
            % Load the most recent dataset
            image_info = obj.Settings.ImageInfo;
            if ~isempty(image_info)
                obj.Reporting.ShowProgress('Loading images');
                obj.GuiDataset.InternalLoadImages(image_info);
            
                % There is no need to call UpdatePatientBrowser here provided the
                % PB is always updated during the InternalLoadImages.
                
            else
                obj.PatientBrowserFactory.UpdatePatientBrowser([], []);
                obj.GuiDataset.SetNoDataset;

            end            
            
            % Resizing has to be done before we call Show(), and will ensure the GUI is
            % correctly laid out when it is shown
            if isempty(obj.Settings.ScreenPosition)
                position = [0, 0, PTKSystemUtilities.GetMonitorDimensions];
            else
                position = obj.Settings.ScreenPosition;
            end
            obj.Resize(position);
            
            % We need to force all the tabs to be created at this point, to ensure the
            % ordering is correct. The following Show() command will create the tabs, but
            % only if they are eabled
            obj.ModeTabControl.ForceEnableAllTabs;
            
            % Create the figure and graphical components
            obj.Show(obj.Reporting);
            
            % After creating all the tabs, we now re-disable the ones that should be hidden
            obj.GuiDataset.UpdateModeTabControl;
            
            % Add listener for switching modes when the tab is changed
            obj.AddEventListener(obj.ModeTabControl, 'PanelChangedEvent', @obj.ModeTabChanged);
            
            % Create a progress panel which will replace the progress dialog
            obj.WaitDialogHandle = PTKProgressPanel(obj.ImagePanel.GraphicalComponentHandle);
            
            % Now we switch the reporting progress bar to a progress panel displayed over the gui
            obj.Reporting.ProgressDialog = obj.WaitDialogHandle;            
            
            % Ensure the GUI stack ordering is correct
            obj.ReorderPanels;

            % Wait until the GUI is visible before removing the splash screen
            splash_screen.delete;
        end
        
        function ShowPatientBrowser(obj)
            obj.PatientBrowserFactory.Show;
        end
        
        function ChangeMode(obj, mode)
            obj.GuiDataset.ChangeMode(mode);
        end
        
        function CreateGuiComponent(obj, position, reporting)
            CreateGuiComponent@PTKFigure(obj, position, reporting);

            obj.Reporting.SetViewerPanel(obj.ImagePanel);            
            obj.AddEventListener(obj.ImagePanel, 'MarkerPanelSelected', @obj.MarkerPanelSelected);
        end
        
        function SaveEditedResult(obj)
            obj.GuiDataset.SaveEditedResult;
        end
        
        
        function SelectFilesAndLoad(obj)
            % Prompts the user for file(s) to load
            image_info = PTKChooseImagingFiles(obj.Settings.SaveImagePath, obj.Reporting);
            
            % An empty image_info means the user has cancelled
            if ~isempty(image_info)
                % Save the path in the settings so that future load dialogs 
                % will start from there
                obj.Settings.SetLastSaveImagePath(image_info.ImagePath, obj.Reporting);
                
                if (image_info.ImageFileFormat == PTKImageFileFormat.Dicom) && (isempty(image_info.ImageFilenames))
                    uiwait(msgbox('No valid DICOM files were found in this folder', [PTKSoftwareInfo.Name ': No image files found.']));
                    obj.Reporting.ShowMessage('PTKGuiApp:NoFilesToLoad', ['No valid DICOM files were found in folder ' image_info.ImagePath]);
                else
                    obj.LoadImages(image_info);
                    
                end
            end
        end
               
        function uids = ImportMultipleFiles(obj)
            % Prompts the user for file(s) to import
            
            obj.WaitDialogHandle.ShowAndHold('Import data');
            
            folder_path = PTKDiskUtilities.ChooseDirectory('Select a directory from which files will be imported', obj.Settings.SaveImagePath);
            
            % An empty folder_path means the user has cancelled
            if ~isempty(folder_path)
                
                % Save the path in the settings so that future load dialogs 
                % will start from there
                obj.Settings.SetLastSaveImagePath(folder_path, obj.Reporting);
                
                % Import all datasets from this path
                uids = obj.GuiDataset.ImportDataRecursive(folder_path);

                % Bring Patient Browser to the front after import
                obj.PatientBrowserFactory.Show;
            end
            
            obj.WaitDialogHandle.Hide;
        end
               
        function SaveBackgroundImage(obj)
            patient_name = obj.ImagePanel.BackgroundImage.Title;
            image_data = obj.ImagePanel.BackgroundImage;
            path_name = obj.Settings.SaveImagePath;
            
            path_name = PTKSaveAs(image_data, patient_name, path_name, obj.Reporting);
            if ~isempty(path_name)
                obj.Settings.SetLastSaveImagePath(image_info.ImagePath, obj.Reporting);
            end
        end
        
        function SaveOverlayImage(obj)
            patient_name = obj.ImagePanel.BackgroundImage.Title;
            background_image = obj.ImagePanel.OverlayImage.Copy;
            template = obj.GuiDataset.GetTemplateImage;
            background_image.ResizeToMatch(template);
            image_data = background_image;
            path_name = obj.Settings.SaveImagePath;
            
            path_name = PTKSaveAs(image_data, patient_name, path_name, obj.Reporting);
            if ~isempty(path_name)
                obj.Settings.SetLastSaveImagePath(image_info.ImagePath, obj.Reporting);
            end
        end
        
        function SaveMarkers(obj)
            if obj.GuiDataset.DatasetIsLoaded
                obj.Reporting.ShowProgress('Saving Markers');
                markers = obj.ImagePanel.GetMarkerPointManager.GetMarkerImage;
                obj.GuiDataset.SaveMarkers(markers);
                obj.ImagePanel.GetMarkerPointManager.MarkerPointsHaveBeenSaved;
                obj.Reporting.CompleteProgress;
            end
        end
        
        function SaveMarkersBackup(obj)
            if obj.GuiDataset.DatasetIsLoaded
                obj.Reporting.ShowProgress('Abandoning Markers');                
                markers = obj.ImagePanel.GetMarkerPointManager.GetMarkerImage;
                obj.GuiDataset.SaveAbandonedMarkers(markers);
                obj.Reporting.CompleteProgress;
            end
        end
        
        function SaveMarkersManualBackup(obj)
            if obj.GuiDataset.DatasetIsLoaded
                markers = obj.ImagePanel.GetMarkerPointManager.GetMarkerImage;
                obj.GuiDataset.SaveMarkersManualBackup(markers);
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
        
        function patient_id = GetCurrentPatientId(obj)
        end

        function Capture(obj)
            % Captures an image from the viewer, including the background and transparent
            % overlay. Prompts the user for a filename
            
            path_name = obj.Settings.SaveImagePath;            
            [filename, path_name, save_type] = PTKDiskUtilities.SaveImageDialogBox(path_name);
            if ~isempty(path_name) && ischar(path_name)
                obj.Settings.SetLastSaveImagePath(image_info.ImagePath, obj.Reporting);
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
        
        function LoadFromPatientBrowser(obj, series_uid)
            obj.BringToFront;
            obj.LoadFromUid(series_uid, obj.WaitDialogHandle);
        end
        
        function LoadPatient(obj, patient_id)
            datasets = obj.GuiDataset.GetImageDatabase.GetAllSeriesForThisPatient(patient_id);
            series_uid = datasets{1}.SeriesUid;
            obj.LoadFromUid(series_uid, obj.WaitDialogHandle);
        end
        
        function CloseAllFiguresExceptPtk(obj)
            all_figure_handles = get(0, 'Children');
            for figure_handle = all_figure_handles'
                if (figure_handle ~= obj.GraphicalComponentHandle) && (~obj.PatientBrowserFactory.HandleMatchesPatientBrowser(figure_handle))
                    if ishandle(figure_handle)
                        delete(figure_handle);
                    end
                end
            end
        end
        
        function Resize(obj, new_position)
            Resize@PTKFigure(obj, new_position);
            obj.ResizeGui(new_position, false);
        end
        
        function delete(obj)
            delete(obj.GuiDataset);
            if ~isempty(obj.Reporting);
                obj.Reporting.Log('Closing PTKGui');
            end
            delete@PTKFigure(obj);
        end        
        
        function UpdatePatientBrowser(obj, patient_id, series_uid)
            obj.PatientBrowserFactory.UpdatePatientBrowser(patient_id, series_uid);
        end
        
        function LoadFromPopupMenu(obj, uid)
            obj.LoadFromUid(uid, obj.WaitDialogHandle);
        end

        function DeleteImageInfo(obj)
            obj.GuiDataset.DeleteImageInfo;
        end

        function DeleteFromPatientBrowser(obj, series_uids)
            obj.WaitDialogHandle.ShowAndHold('Deleting data');
            obj.DeleteDatasets(series_uids);
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
                    obj.DeleteFromPatientBrowser(series_uid);
                case 'Don''t delete'
            end
        end
        
        function DeletePatient(obj, patient_id)
            choice = questdlg('Do you want to delete this patient?', ...
                'Delete patient', 'Delete', 'Don''t delete', 'Don''t delete');
            switch choice
                case 'Delete'
                    obj.BringToFront;
                    
                    series_descriptions = obj.GuiDataset.GetImageDatabase.GetAllSeriesForThisPatient(patient_id);
                    
                    series_uids = {};
                    
                    for series_index = 1 : numel(series_descriptions)
                        series_uids{series_index} = series_descriptions{series_index}.SeriesUid;
                    end
                    
                    % Note that obj may be deleted during this loop as the patient panels are
                    % rebuilt, so we can't reference obj at all from here on
                    % for line
                    obj.DeleteFromPatientBrowser(series_uids);
                    
                case 'Don''t delete'
            end
        end
        
        function DeleteDatasets(obj, series_uids)
            obj.GuiDataset.DeleteDatasets(series_uids);
        end
        
        function mode = GetMode(obj)
            mode = obj.GuiDataset.GetMode;
        end
        
        function RunGuiPluginCallback(obj, plugin_name)
            
            wait_dialog = obj.WaitDialogHandle;
            
            plugin_info = eval(plugin_name);
            wait_dialog.ShowAndHold([plugin_info.ButtonText]);

            plugin_info.RunGuiPlugin(obj);
            
            obj.UpdateToolbar;
            
            wait_dialog.Hide;
        end
        
        function RunPluginCallback(obj, plugin_name)
            wait_dialog = obj.WaitDialogHandle;
            obj.GuiDataset.RunPlugin(plugin_name, wait_dialog);
        end
        
        function dataset_is_loaded = IsDatasetLoaded(obj)
            dataset_is_loaded = obj.GuiDataset.DatasetIsLoaded;
        end
        
        function ToolClicked(obj)
            obj.UpdateToolbar;
        end
         
    end
    
    
    
    
    methods (Access = protected)
        
        function input_has_been_processed = Keypressed(obj, click_point, key)
            % Shortcut keys are normally processed by the object over which the mouse
            % pointer is located. If a key hasn't been processed, we divert it to the viewer
            % panel so that viewer panel shortcuts will work from other parts of the GUI.            
            input_has_been_processed = obj.ImagePanel.ShortcutKeys(key);
        end

        
        function CustomCloseFunction(obj, src, ~)
            % Executes when application closes
            obj.Reporting.ShowProgress('Saving settings');
            
            % Hide the Patient Browser, as it can take a short time to close
            obj.PatientBrowserFactory.Hide;

            obj.ApplicationClosing();
            
            delete(obj.PatientBrowserFactory);
            
            % The progress dialog will porbably be destroyed before we get here
%             obj.Reporting.CompleteProgress;

            CustomCloseFunction@PTKFigure(obj, src);
        end
        
    end
    
    
    
    
    
    
    
    methods (Access = private)
        
        function ApplicationClosing(obj)
            obj.AutoSaveMarkers;
            obj.SaveSettings;
        end        
        
        % Executes when figure is resized
        function ResizeCallback(obj, ~, ~, ~)
            obj.Resize;
        end
        
        
        function MarkerPanelSelected(obj, ~, ~)
            if ~obj.MarkersHaveBeenLoaded
                wait_dialog = obj.WaitDialogHandle;
                wait_dialog.ShowAndHold('Loading Markers');
                obj.LoadMarkers;
                wait_dialog.Hide;
            end
        end
        
        function LoadFromUid(obj, series_uid, wait_dialog_handle)
            
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


        function ClearDataset(obj)
            obj.WaitDialogHandle.ShowAndHold('Clearing dataset');
            obj.GuiDataset.ClearDataset;
            obj.WaitDialogHandle.Hide;
        end


        function LoadMarkers(obj)
            
            new_image = obj.GuiDataset.LoadMarkers;
            if isempty(new_image)
                disp('No previous markers found for this image');
            else
                obj.ImagePanel.GetMarkerPointManager.ChangeMarkerImage(new_image);
            end
            obj.MarkersHaveBeenLoaded = true;
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




        function AutoSaveMarkers(obj)
            if ~isempty(obj.ImagePanel)
                if ~isempty(obj.ImagePanel.GetMarkerPointManager) && obj.ImagePanel.GetMarkerPointManager.MarkerImageHasChanged && obj.MarkersHaveBeenLoaded
                    saved_marker_points = obj.GuiDataset.LoadMarkers;
                    current_marker_points = obj.ImagePanel.GetMarkerPointManager.GetMarkerImage;
                    markers_changed = false;
                    if isempty(saved_marker_points)
                        if any(current_marker_points.RawImage(:))
                            markers_changed = true;
                        end
                    else
                        if ~isequal(saved_marker_points.RawImage, current_marker_points.RawImage)
                            markers_changed = true;
                        end
                    end
                    if markers_changed
                        
                        % Depending on the software settings, the user can be prompted before saving
                        % changes to the markers
                        if PTKSoftwareInfo.ConfirmBeforeSavingMarkers
                            choice = questdlg('Do you want to save the changes you have made to the current markers?', ...
                                'Unsaved changes to markers', 'Delete changes', 'Save', 'Save');
                            switch choice
                                case 'Save'
                                    obj.SaveMarkers;
                                case 'Don''t save'
                                    obj.SaveMarkersBackup;
                                    disp('Abandoned changes have been stored in AbandonedMarkerPoints.mat');
                            end
                        else
                            obj.SaveMarkers;
                        end
                    end
                end
            end
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
            
            patient_name_panel_height = obj.PatientNamePanel.GetRequestedHeight;
            
            viewer_panel_height = max(1, parent_height_pixels - toolbar_height - patient_name_panel_height);
            
            side_panel_height = max(1, parent_height_pixels);
            side_panel_width = obj.SidePanelWidth;
            
            obj.SidePanel.Resize([1, 1, side_panel_width, side_panel_height]);
            
            if obj.ImagePanel.ShowControlPanel
                image_height_pixels = viewer_panel_height - obj.ImagePanel.ControlPanelHeight;
            else
                image_height_pixels = viewer_panel_height;
            end
            
            image_width_pixels = obj.GetSuggestedWidth(image_height_pixels);
            viewer_panel_width = image_width_pixels + PTKSlider.SliderWidth;
            
            patient_name_panel_width = viewer_panel_width;
            
            mode_panel_width = max(1, parent_width_pixels - viewer_panel_width - side_panel_width);
            
            plugins_panel_height = max(1, parent_height_pixels - toolbar_height);
            
            image_panel_position = 2 + side_panel_width;
            obj.ImagePanel.Resize([image_panel_position, toolbar_height, viewer_panel_width, viewer_panel_height]);

            patient_name_panel_y_position = toolbar_height + viewer_panel_height;
            obj.PatientNamePanel.Resize([image_panel_position, patient_name_panel_y_position, patient_name_panel_width, patient_name_panel_height]);
            
            if PTKSoftwareInfo.ToolbarEnabled
                toolbar_width = parent_width_pixels;
                obj.ToolbarPanel.Resize([image_panel_position, 1, toolbar_width, toolbar_height]);
            end
            
            right_side_position = image_panel_position + viewer_panel_width + 1;
            
            obj.ModeTabControl.Resize([right_side_position, toolbar_height, mode_panel_width, plugins_panel_height]);
            
            if ~isempty(obj.WaitDialogHandle)
                obj.WaitDialogHandle.Resize();
            end
        end

        function ModeTabChanged(obj, ~, event_data)
            mode = obj.ModeTabControl.GetPluginMode(event_data.Data);
            obj.GuiDataset.ModeTabChanged(mode);
        end
        
    end
    
    methods

        %%% Callbacks from GuiDataset
        
        function UpdateModeTabControl(obj, plugin_info)
            obj.ModeTabControl.UpdateMode(plugin_info);
        end
        
        function DatabaseHasChanged(obj)
            obj.PatientBrowserFactory.DatabaseHasChanged;
            obj.SidePanel.DatabaseHasChanged;
        end
        
        function AddPreviewImage(obj, plugin_name, dataset)
            obj.ModeTabControl.AddPreviewImage(plugin_name, dataset, obj.ImagePanel.Window, obj.ImagePanel.Level);
        end
        
        function ClearImages(obj)
            if obj.GuiDataset.DatasetIsLoaded
                obj.AutoSaveMarkers;
                obj.MarkersHaveBeenLoaded = false;
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
            
            % Force a resize. This is so that the image panel can resize itself to optimally
            % fit the image. If however the image panel is changed to retain a fixed size
            % between datasets, then this resize is not necessary.
            if obj.ComponentHasBeenCreated
                obj.ResizeGui(obj.Position, true);
            end
        end
        
        function AddAllPreviewImagesToButtons(obj, dataset)
            obj.ModeTabControl.AddAllPreviewImagesToButtons(dataset, obj.ImagePanel.Window, obj.ImagePanel.Level);
        end

        function ReplaceOverlayImageCallback(obj, new_image, image_title)
            if isequal(new_image.ImageSize, obj.ImagePanel.BackgroundImage.ImageSize) && isequal(new_image.Origin, obj.ImagePanel.BackgroundImage.Origin)
                obj.ReplaceOverlayImage(new_image, image_title, new_image.ColorLabelMap, new_image.ColourLabelParentMap, new_image.ColourLabelChildMap)
            else
                obj.ReplaceOverlayImageAdjustingSize(new_image, image_title, new_image.ColorLabelMap, new_image.ColourLabelParentMap, new_image.ColourLabelChildMap);
            end
        end
        
        function ReplaceQuiverImageCallback(obj, new_image)
            if all(new_image.ImageSize(1:3) == obj.ImagePanel.BackgroundImage.ImageSize(1:3)) && all(new_image.Origin == obj.ImagePanel.BackgroundImage.Origin)
                obj.ReplaceQuiverImage(new_image.RawImage, 4);
            else
                obj.ReplaceQuiverImageAdjustingSize(new_image);
            end
        end

        function LoadMarkersIfRequired(obj)
            if obj.ImagePanel.IsInMarkerMode
                obj.LoadMarkers;
            end
        end
        
        function UpdateToolbar(obj)
            if PTKSoftwareInfo.ToolbarEnabled
                obj.ToolbarPanel.Update(obj);
            end
        end

        
        %%% Callbacks and also called from within this class
        
        
        function SaveSettings(obj)
            if ~isempty(obj.Settings)
                set(obj.GraphicalComponentHandle, 'units', 'pixels');
                obj.Settings.ScreenPosition = get(obj.GraphicalComponentHandle, 'Position');
                obj.Settings.PatientBrowserScreenPosition = obj.PatientBrowserFactory.GetScreenPosition;
                obj.Settings.UpdateSettingsFromViewerPanel(obj.ImagePanel);
                obj.Settings.SaveSettings(obj.Reporting);
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
    end
    
    methods (Access = private)
        
        function suggested_width_pixels = GetSuggestedWidth(obj, image_height_pixels)
            % Computes the width of the viewer so that the coronal view fills the whole window
            
            image_size_mm = obj.ImagePanel.BackgroundImage.ImageSize.*obj.ImagePanel.BackgroundImage.VoxelSize;

            % We choose the preferred orientation based on the image
            % Note we could change this to the current orientation
            % (obj.ImagePanel.Orientation), but if we did this we would need to force a
            % GUI resize whenever the orientation was changed
            optimal_direction_orientation = PTKImageUtilities.GetPreferredOrientation(obj.ImagePanel.BackgroundImage);
            
            [dim_x_index, dim_y_index, dim_z_index] = PTKImageCoordinateUtilities.GetXYDimensionIndex(optimal_direction_orientation);
            
            image_height_mm = image_size_mm(dim_y_index);
            image_width_mm = image_size_mm(dim_x_index);
            suggested_width_pixels = ceil(image_width_mm*image_height_pixels/image_height_mm);
            
            suggested_width_pixels = max(suggested_width_pixels, ceil((2/3)*image_height_pixels));
            suggested_width_pixels = min(suggested_width_pixels, ceil((5/3)*image_height_pixels));
        end
    end
end
