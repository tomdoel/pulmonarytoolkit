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
    end
    
    properties (Access = private)
        GuiDataset
        Settings
        WaitDialogHandle
        MarkersHaveBeenLoaded = false
        
        VersionPanel
        ModeTabControl
        DropDownLoadMenu

        PatientBrowserButton
        PatientBrowserFactory
        
        ModeTabChangedListener
        
        LastWindowSize % Keep track of window size to prevent unnecessary resize
    end
    
    properties (Constant, Access = private)
        LoadMenuHeight = 23
        PatientBrowserWidth = 100
    end
    
    methods
        function obj = PTKGui(splash_screen)

            % Create the splash screen if it doesn't already exist
            if nargin < 1 || isempty(splash_screen) || ~isa(splash_screen, 'PTKProgressInterface')
                splash_screen = PTKSplashScreen;
            end
            
            % Call the base class to initialise the figure class
            obj = obj@PTKFigure(PTKSoftwareInfo.Name, []);

            % Set up the viewer panel and apply settings
            obj.ImagePanel = PTKViewerPanel(obj);
            obj.AddChild(obj.ImagePanel);
            
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
            
            % The Patient Browser factory manages lazy creation of the Patient Browser. The
            % PB may take time to load if there are many datasets
            obj.PatientBrowserFactory = PTKPatientBrowserFactory(obj, obj.GuiDataset, obj.Settings, obj.Reporting);

            % Patient Browser button
            pb = obj.PatientBrowserFactory;
            obj.PatientBrowserButton = PTKButton(obj, 'Patients', 'Open the Patient Browser', 'PatientBrowser', @pb.Show);
            obj.AddChild(obj.PatientBrowserButton);
            
            obj.ModeTabControl = PTKModeTabControl(obj, obj.Settings, obj.Reporting);
            obj.AddChild(obj.ModeTabControl);

            % Drop down quick load menu
            obj.DropDownLoadMenu = PTKDropDownLoadMenu(obj, obj, obj.Settings);
            obj.AddChild(obj.DropDownLoadMenu);
            
            % Create the panel showing the software name and version.
            obj.VersionPanel = PTKVersionPanel(obj, obj, obj.Settings, obj.Reporting);
            obj.AddChild(obj.VersionPanel);
            
            % Load the most recent dataset
            image_info = obj.Settings.ImageInfo;
            if ~isempty(image_info)
                obj.Reporting.ShowProgress('Loading images');
                obj.GuiDataset.InternalLoadImages(image_info);
            
                % There is no need to call obj.UpdateQuickLoadMenu here provided the
                % menu is always updated during the InternalLoadImages.
                % Update can be a bit slow so we don't want to call it twice on
                % startup.
                
            else
                obj.UpdateQuickLoadMenu;
                obj.PatientBrowserFactory.UpdatePatientBrowser([], []);
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
            obj.ModeTabChangedListener = addlistener(obj.ModeTabControl, 'TabChangedEvent', @obj.ModeTabChanged);
            
            % Create a progress panel which will replace the progress dialog
            obj.WaitDialogHandle = PTKProgressPanel(obj.ImagePanel.GraphicalComponentHandle);
            
            % Now we switch the reporting progress bar to a progress panel displayed over the gui
            obj.Reporting.ProgressDialog = obj.WaitDialogHandle;            
            
            % Ensure the GUI stack ordering is correct
            obj.ReorderPanels;

            % Wait until the GUI is visible before removing the splash screen
            splash_screen.Delete;
        end
        
        function ChangeMode(obj, mode)
            obj.GuiDataset.ChangeMode(mode);
        end
        
        function CreateGuiComponent(obj, position, reporting)
            CreateGuiComponent@PTKFigure(obj, position, reporting);

            obj.Reporting.SetViewerPanel(obj.ImagePanel);            
            addlistener(obj.ImagePanel, 'MarkerPanelSelected', @obj.MarkerPanelSelected);
        end
        
        function SaveEditedResult(obj)
            obj.GuiDataset.SaveEditedResult;
        end
        
        
        % Prompts the user for file(s) to load
        function SelectFilesAndLoad(obj)
            image_info = PTKChooseImagingFiles(obj.Settings.SaveImagePath, obj.Reporting);
            
            % An empty image_info means the user has cancelled
            if ~isempty(image_info)
                % Save the path in the settings so that future load dialogs 
                % will start from there
                obj.Settings.SaveImagePath = image_info.ImagePath;
                obj.SaveSettings;
                
                if (image_info.ImageFileFormat == PTKImageFileFormat.Dicom) && (isempty(image_info.ImageFilenames))
                    msgbox('No valid DICOM files were found in this folder', [PTKSoftwareInfo.Name ': No image files found.']);
                    obj.Reporting.ShowMessage('PTKGuiApp:NoFilesToLoad', ['No valid DICOM files were found in folder ' image_info.ImagePath]);
                else
                    obj.LoadImages(image_info);
                    
                    % Add any new datasets to the patient browser
                    obj.DatabaseHasChanged;
                    
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
                obj.Settings.SaveImagePath = folder_path;
                obj.SaveSettings;
                
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
                obj.Settings.SaveImagePath = path_name;
                obj.SaveSettings;
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
                obj.Settings.SaveImagePath = path_name;
                obj.SaveSettings;
            end
        end
        
        function SaveMarkers(obj)
            if obj.GuiDataset.DatasetIsLoaded
                obj.Reporting.ShowProgress('Saving Markers');
                markers = obj.ImagePanel.MarkerPointManager.GetMarkerImage;
                obj.GuiDataset.SaveMarkers(markers);
                obj.ImagePanel.MarkerPointManager.MarkerPointsHaveBeenSaved;
                obj.Reporting.CompleteProgress;
            end
        end
        
        function SaveMarkersBackup(obj)
            if obj.GuiDataset.DatasetIsLoaded
                obj.Reporting.ShowProgress('Abandoning Markers');                
                markers = obj.ImagePanel.MarkerPointManager.GetMarkerImage;
                obj.GuiDataset.SaveAbandonedMarkers(markers);
                obj.Reporting.CompleteProgress;
            end
        end
        
        function SaveMarkersManualBackup(obj)
            if obj.GuiDataset.DatasetIsLoaded
                markers = obj.ImagePanel.MarkerPointManager.GetMarkerImage;
                obj.GuiDataset.SaveMarkersManualBackup(markers);
            end
        end

        function RefreshPlugins(obj)
            obj.GuiDataset.RefreshPlugins;
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
        

        function Capture(obj)
            % Captures an image from the viewer, including the background and transparent
            % overlay. Prompts the user for a filename
            
            path_name = obj.Settings.SaveImagePath;            
            [filename, path_name, save_type] = PTKDiskUtilities.SaveImageDialogBox(path_name);
            if ~isempty(path_name) && ischar(path_name)
                obj.Settings.SaveImagePath = path_name;
                obj.SaveSettings;
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
            obj.ResizeGui(new_position);
        end
        
        function delete(obj)
            delete(obj.ModeTabChangedListener);
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
            
            wait_dialog.Hide;
        end
        
        function RunPluginCallback(obj, plugin_name)
            wait_dialog = obj.WaitDialogHandle;
            obj.GuiDataset.RunPlugin(plugin_name, wait_dialog);
        end
        
        
    end
    
    methods (Access = protected)
        
        % Executes when application closes
        function CustomCloseFunction(obj, src, ~)
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
                obj.ImagePanel.MarkerPointManager.ChangeMarkerImage(new_image);
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
                if ~isempty(obj.ImagePanel.MarkerPointManager) && obj.ImagePanel.MarkerPointManager.MarkerImageHasChanged && obj.MarkersHaveBeenLoaded
                    saved_marker_points = obj.GuiDataset.LoadMarkers;
                    current_marker_points = obj.ImagePanel.MarkerPointManager.GetMarkerImage;
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
                        choice = questdlg('Do you want to save the current markers?', ...
                            'Unsaved changes to markers', 'Save', 'Don''t save', 'Save');
                        switch choice
                            case 'Save'
                                obj.SaveMarkers;
                            case 'Don''t save'
                                obj.SaveMarkersBackup;
                                disp('Abandoned changes have been stored in AbandonedMarkerPoints.mat');
                        end
                    end
                end
            end
        end

        
        function ResizeGui(obj, parent_position)
            
            parent_width_pixels = parent_position(3);
            parent_height_pixels = parent_position(4);
            
            new_size = [parent_width_pixels, parent_height_pixels];
            if isequal(new_size, obj.LastWindowSize)
                return;
            end
            obj.LastWindowSize = new_size;
            
            load_menu_height = obj.LoadMenuHeight;
            viewer_panel_height = max(1, parent_height_pixels - load_menu_height);
            viewer_panel_width = viewer_panel_height;
            
            version_panel_height = obj.VersionPanel.GetRequestedHeight;
            version_panel_width = max(1, parent_width_pixels - viewer_panel_width);
            
            plugins_panel_height = max(1, parent_height_pixels - load_menu_height - version_panel_height);
            
            patient_browser_width = obj.PatientBrowserWidth;
            
            obj.ImagePanel.Resize([1, 1, viewer_panel_width, viewer_panel_height]);
            
            obj.ModeTabControl.Resize([viewer_panel_width + 1, 0, version_panel_width, plugins_panel_height]);
            
            height_additional = 3;
            obj.VersionPanel.Resize([viewer_panel_width + 1, plugins_panel_height, version_panel_width, version_panel_height + height_additional]);
                        
            obj.PatientBrowserButton.Resize([8, parent_height_pixels - load_menu_height + 1, patient_browser_width, load_menu_height - 1]);
            
            if ~isempty(obj.DropDownLoadMenu);
                obj.DropDownLoadMenu.Resize([8 + patient_browser_width, parent_height_pixels - load_menu_height, parent_width_pixels - patient_browser_width - 8, load_menu_height]);
            end
            
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
        
        function UpdateQuickLoadMenu(obj)
            [sorted_paths, sorted_uids] = obj.GuiDataset.GetListOfPaths;
            obj.DropDownLoadMenu.UpdateQuickLoadMenu(sorted_paths, sorted_uids);
        end

        function DatabaseHasChanged(obj)
            obj.PatientBrowserFactory.DatabaseHasChanged;
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
        end
        
        function UpdateFigureTitle(obj, current_plugin_name, is_edited)
            
            figure_title = PTKSoftwareInfo.Name;
            if isa(obj.ImagePanel.BackgroundImage, 'PTKImage')
                patient_name = obj.ImagePanel.BackgroundImage.Title;
                if ~isempty(current_plugin_name) && obj.ImagePanel.OverlayImage.ImageExists
                    if is_edited
                        current_plugin_name = ['EDITED ', current_plugin_name];
                    end
                    patient_name = [patient_name ' (' current_plugin_name ')'];
                end
                if ~isempty(figure_title)
                    figure_title = [patient_name ' : ' figure_title];
                end
            end
            
            % Remove HTML tags
            figure_title = PTKTextUtilities.RemoveHtml(figure_title);
            
            % Set window title
            obj.Title = figure_title;
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

        function UpdateGuiDatasetAndPluginName(obj, series_name, patient_visible_name, plugin_visible_name, is_edited)
            obj.UpdateFigureTitle(plugin_visible_name, is_edited);
            obj.VersionPanel.UpdatePatientName(series_name, patient_visible_name, plugin_visible_name, is_edited);
        end

        
        %%% Callbacks and also called from within this class
        
        
        function SaveSettings(obj)
            if ~isempty(obj.Settings)
                set(obj.GraphicalComponentHandle, 'units', 'pixels');
                obj.Settings.ScreenPosition = get(obj.GraphicalComponentHandle, 'Position');
                obj.Settings.PatientBrowserScreenPosition = obj.PatientBrowserFactory.GetScreenPosition;
                obj.Settings.SaveSettings(obj.ImagePanel, obj.Reporting);
            end
        end
        
        function ReorderPanels(obj)
            % Ensure the stack order is correct, to stop the scrolling panels appearing on
            % top of the version panel or drop-down menu
            
            child_handles = get(obj.GraphicalComponentHandle, 'Children');
            popupmenu_handle = obj.DropDownLoadMenu.GraphicalComponentHandle;
            version_handle = obj.VersionPanel.GraphicalComponentHandle;
            other_handles = setdiff(child_handles, popupmenu_handle);
            other_handles = setdiff(other_handles, version_handle);
            reordered_handles = [version_handle; popupmenu_handle; other_handles];
            set(obj.GraphicalComponentHandle, 'Children', reordered_handles);
        end

    end
end
