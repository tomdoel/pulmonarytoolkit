classdef PTKGui < handle
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
        Settings
        Dataset
        Ptk
        FigureHandle
        WaitDialogHandle
        MarkersHaveBeenLoaded = false
        PluginsPanel
        DropDownLoadMenuManager
        OldWindowScrollWheelFcn

        ProfileCheckboxHandle
        UipanelImageHandle
        UipanelPluginsHandle
        PopupmenuLoadHandle
        TextVersionHandle
        UipanelVersionHandle
        
        CurrentPluginName
    end
    
    methods
        function obj = PTKGui(splash_screen)

            % Create the splash screen if it doesn't already exist
            if nargin < 1 || isempty(splash_screen) || ~isa(splash_screen, 'PTKProgressInterface')
                splash_screen = PTKSplashScreen;
            end

            % Create the figure and gui components
            obj.FigureHandle = figure('Color', PTKSoftwareInfo.BackgroundColour, 'Visible', 'off', 'numbertitle', 'off', 'MenuBar', 'none', 'ToolBar', 'none');
            obj.UipanelImageHandle = uipanel('Parent', obj.FigureHandle, 'Units', 'pixels', 'Position', [1 1 921 921], 'BackgroundColor', PTKSoftwareInfo.BackgroundColour, 'BorderType', 'none');
            obj.UipanelPluginsHandle = uipanel('Parent', obj.FigureHandle, 'Units', 'pixels', 'Position', [889 6 668 869], 'BackgroundColor', PTKSoftwareInfo.BackgroundColour, 'BorderType', 'none');
            obj.UipanelVersionHandle = uipanel('Parent', obj.FigureHandle, 'Units', 'pixels', 'Position', [10 2 392 34], 'BackgroundColor', PTKSoftwareInfo.BackgroundColour, 'BorderType', 'none');
            obj.PopupmenuLoadHandle = uicontrol('Parent', obj.FigureHandle', 'Style', 'popupmenu', ...
                'Units', 'pixels', 'Position', [8 912 1560 23], 'Callback', @obj.PopupmenuLoadCallback, 'String', 'Recent datasets');
            obj.TextVersionHandle = uicontrol('Parent', obj.UipanelVersionHandle, 'Style', 'text', ...
                'Units', 'pixels', 'Position', [10 2 392 34], 'BackgroundColor', PTKSoftwareInfo.BackgroundColour, ...
                'FontName', PTKSoftwareInfo.GuiFont, 'FontSize', 20.0, 'ForegroundColor', [1.0 0.694 0.392], 'HorizontalAlignment', 'left', ...
                'FontWeight', 'bold');
            obj.ProfileCheckboxHandle = uicontrol('Parent', obj.UipanelVersionHandle, 'Style', 'checkbox', 'String', 'Enable profiler', ...
                'Units', 'pixels', 'Position', [429 -8 143 49], 'BackgroundColor', PTKSoftwareInfo.BackgroundColour, 'ForegroundColor', [1 1 1], ...
                'Callback', @obj.ProfileCheckboxCallback);

            % Set custom function for application closing
            set(obj.FigureHandle, 'CloseRequestFcn', @obj.CustomCloseFunction);
                        
            % Update the profile checkbox with the current status of the Matlab
            % profilers
            obj.UpdateProfilerStatus;
                        
            % Set the application name and version number
            set(obj.TextVersionHandle, 'String', obj.GetSoftwareNameAndVersionForDisplay);

            obj.ImagePanel = PTKViewerPanel(obj.UipanelImageHandle);
            obj.Reporting = PTKReporting(splash_screen, obj.ImagePanel, PTKSoftwareInfo.WriteVerboseEntriesToLogFile);
            obj.PluginsPanel = PTKPluginsPanel(obj.UipanelPluginsHandle, obj.Reporting);
            addlistener(obj.ImagePanel, 'MarkerPanelSelected', @obj.MarkerPanelSelected);
            
            obj.OldWindowScrollWheelFcn = get(obj.FigureHandle, 'WindowScrollWheelFcn');
            set(obj.FigureHandle, 'WindowScrollWheelFcn', @obj.WindowScrollWheelFcn);
            
            % For the moment, we use the splash screen to display progress,
            % because the gui isn't yet visible so the ProgressPanel won't
            % display
            obj.Reporting.Log('New session of PTKGui');
            
            obj.Ptk = PTKMain(obj.Reporting);
            
            obj.Settings = PTKSettings.LoadSettings(obj.ImagePanel, obj.Reporting);

            if isempty(obj.Settings.ScreenPosition)
                % Initialise full-screen
                units=get(obj.FigureHandle, 'units');
                set(obj.FigureHandle, 'units', 'normalized', 'outerposition', [0 0 1 1]);
                set(obj.FigureHandle, 'units', units);
                
            else
                set(obj.FigureHandle, 'Position', obj.Settings.ScreenPosition);
            end
            
            % Check if any datasets in cache exist which are not part of the
            % drop-down menu
            obj.AddAllDatasetsInCacheToDropDownMenu([], false);
            
            obj.DropDownLoadMenuManager = PTKDropDownLoadMenuManager(obj.Settings, obj.PopupmenuLoadHandle);

            obj.PluginsPanel.AddPlugins(@obj.RunPluginCallback, @obj.RunGuiPluginCallback, []);
            
            image_info = obj.Settings.ImageInfo;
            
            if ~isempty(image_info)
                obj.LoadImages(image_info, splash_screen);
            else
                obj.DropDownLoadMenuManager.UpdateQuickLoadMenu;
            end

            obj.ImagePanel.ShowImage = true;
            obj.ImagePanel.ShowOverlay = true;

            % Resizing will correctly lay out the GUI
            obj.Resize;

            set(obj.FigureHandle, 'ResizeFcn', @obj.ResizeCallback);
            set(obj.FigureHandle, 'Visible', 'on');

            % Now we switch to a progress panel displayed over the gui
            obj.WaitDialogHandle = PTKProgressPanel(obj.UipanelImageHandle);
            obj.Reporting.ProgressDialog = obj.WaitDialogHandle;
            
            % Wait until the GUI is visible before removing the splash screen
            splash_screen.Delete;
        end

        % Causes the GUI to load the images specified either by the UID or the
        % filenames
        function Load(obj, image_info)
            obj.LoadImages(image_info, obj.WaitDialogHandle);
        end
        
        % Causes the GUI to run the named plugin and display the result
        function RunPlugin(obj, plugin_name)
            if isempty(obj.Dataset)
                return;
            end
            
            wait_dialog = obj.WaitDialogHandle;
            
            if PTKSoftwareInfo.DebugMode
                obj.RunPluginTryCatchBlock(plugin_name)
            else
                try
                    obj.RunPluginTryCatchBlock(plugin_name)
                catch exc
                    if PTKSoftwareInfo.IsErrorCancel(exc.identifier)
                        obj.Reporting.ShowMessage('PTKGuiApp:LoadingCancelled', ['The cancel button was clicked while the plugin ' plugin_name ' was running.']);
                    else
                        msgbox(['The plugin ' plugin_name ' failed with the following error: ' exc.message], [PTKSoftwareInfo.Name ': Failure in plugin ' plugin_name], 'error');
                        obj.Reporting.ShowMessage('PTKGui:PluginFailed', ['The plugin ' plugin_name ' failed with the following error: ' exc.message]);
                    end
                end
            end
            wait_dialog.Hide;            
        end
        
        % Causes the GUI to run the named plugin and display the result
        function SaveEditedResult(obj, edited_result)
            if isempty(obj.Dataset)
                return;
            end
            
            plugin_name = obj.CurrentPluginName;
            
            if isempty(plugin_name)
                msgbox(['Cannot save the edited result as no plugin result is currently loaded'], [PTKSoftwareInfo.Name ': Cannot save edited result'], 'error');
                obj.Reporting.ShowMessage('PTKGui:NoPlugin', 'Cannot save the edited result as no plugin result is currently loaded');
                return
            end
            
            wait_dialog = obj.WaitDialogHandle;
            
            new_plugin = PTKPluginInformation.LoadPluginInfoStructure(plugin_name, obj.Reporting);
            plugin_text = new_plugin.ButtonText;
            wait_dialog.ShowAndHold(['Saving edited result for ' plugin_text]);
            
            
            obj.Dataset.SaveEditedResult(plugin_name, edited_result);
            
            wait_dialog.Hide;
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
                    obj.LoadImages(image_info, obj.WaitDialogHandle);
                end
            end
        end
               
        % Prompts the user for file(s) to load
        function ImportMultipleFiles(obj)
            folder_path = PTKDiskUtilities.ChooseDirectory('Select a directory from which files will be imported', obj.Settings.SaveImagePath);
            
            % An empty folder_path means the user has cancelled
            if ~isempty(folder_path)
                
                % Save the path in the settings so that future load dialogs 
                % will start from there
                obj.Settings.SaveImagePath = folder_path;
                obj.SaveSettings;
                
                % Import all datasets from this path
                uids = obj.Ptk.ImportDataRecursive(folder_path);
                
                % Add any new datasets to the menu
                obj.AddAllDatasetsInCacheToDropDownMenu(uids, false);
                
                % Update the menu
                obj.DropDownLoadMenuManager.UpdateQuickLoadMenu;                
            end
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
            template = obj.Dataset.GetTemplateImage(PTKContext.OriginalImage);
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
            if ~isempty(obj.Dataset)
                obj.Reporting.ShowProgress('Saving Markers');                
                markers = obj.ImagePanel.MarkerPointManager.GetMarkerImage;
                obj.Dataset.SaveData(PTKSoftwareInfo.MakerPointsCacheName, markers);
                obj.ImagePanel.MarkerPointManager.MarkerPointsHaveBeenSaved;
                obj.Reporting.CompleteProgress;
            end
        end
        
        function SaveMarkersBackup(obj)
            if ~isempty(obj.Dataset)
                obj.Reporting.ShowProgress('Abandoning Markers');                
                markers = obj.ImagePanel.MarkerPointManager.GetMarkerImage;
                obj.Dataset.SaveData('AbandonedMarkerPoints', markers);
                obj.Reporting.CompleteProgress;
            end
        end
        
        function SaveMarkersManualBackup(obj)
            if ~isempty(obj.Dataset)
                markers = obj.ImagePanel.MarkerPointManager.GetMarkerImage;
                obj.Dataset.SaveData('MarkerPointsLastManualSave', markers);
            end
        end

        function RefreshPlugins(obj)
            obj.PluginsPanel.RefreshPlugins(@obj.RunPluginCallback, @obj.RunGuiPluginCallback, obj.Dataset, obj.ImagePanel.Window, obj.ImagePanel.Level)
        end
        
        function display_string = GetSoftwareNameAndVersionForDisplay(~)
            display_string = [PTKSoftwareInfo.Name, ' version ' PTKSoftwareInfo.Version];
        end        
        
        function dataset_cache_path = GetDatasetCachePath(obj)
            if ~isempty(obj.Dataset)
                dataset_cache_path = obj.Dataset.GetDatasetCachePath;
            else
                dataset_cache_path = PTKDirectories.GetCacheDirectory;
            end
        end
        
        function dataset_cache_path = GetEditedResultsPath(obj)
            if ~isempty(obj.Dataset)
                dataset_cache_path = obj.Dataset.GetEditedResultsPath;
            else
                dataset_cache_path = PTKDirectories.GetEditedResultsDirectoryAndCreateIfNecessary;
            end
        end

        function dataset_cache_path = GetOutputPath(obj)
            if ~isempty(obj.Dataset)
                dataset_cache_path = obj.Dataset.GetOutputPath;
            else
                dataset_cache_path = PTKDirectories.GetOutputDirectoryAndCreateIfNecessary;
            end
        end
        
        function image_info = GetImageInfo(obj)
            if ~isempty(obj.Dataset)
                image_info = obj.Dataset.GetImageInfo;
            else
                image_info = [];
            end
        end        
        
        function ClearCacheForThisDataset(obj)
            if ~isempty(obj.Dataset)
                obj.Dataset.ClearCacheForThisDataset(false);
            end
        end
        

        function Capture(obj)
            obj.Reporting.ProgressDialog.Hide;
            frame = obj.ImagePanel.Capture;
            path_name = obj.Settings.SaveImagePath;
            
            [filename, path_name, filter_index] = obj.SaveImageDialogBox(path_name);
            if ~isempty(path_name) && filter_index > 0
                obj.Settings.SaveImagePath = path_name;
                obj.SaveSettings;
            end
            if (filename ~= 0)
                switch filter_index
                    case 1
                        imwrite(frame.cdata, fullfile(path_name, filename), 'tif');
                    case 2
                        imwrite(frame.cdata, fullfile(path_name, filename), 'jpg', 'Quality', 70);
                end
            end
        end
        
        function DeleteImageInfo(obj)
            obj.Settings.ImageInfo = [];

            if ~isempty(obj.Dataset)
                obj.Dataset.ClearCacheForThisDataset(true);
                image_info = obj.Dataset.GetImageInfo;
                
                old_infos = obj.Settings.PreviousImageInfos;
                if old_infos.isKey(image_info.ImageUid)
                    old_infos.remove(image_info.ImageUid);
                    obj.Settings.PreviousImageInfos = old_infos;
                end
            end
            
            obj.SaveSettings;
            obj.DropDownLoadMenuManager.UpdateQuickLoadMenu;
        end
        
        function DeleteOverlays(obj)
            obj.ImagePanel.ClearOverlays;
            obj.SetCurrentPluginAndUpdateFigureTitle([]);
        end
        
        function ResetCurrentPlugin(obj)
            obj.SetCurrentPluginAndUpdateFigureTitle([]);
        end
        
        function RebuildDropDownLoadMenu(obj)
            obj.AddAllDatasetsInCacheToDropDownMenu([], true);
        end
        
    end
    
    
    methods (Access = private)
        
        % Checks the disk cache and adds any missing datasets to the drop-down
        % load menu. Specifying a list of uids forces those datasets to update.
        % The rebuild_menu flag builds the load menu from scratch
        function AddAllDatasetsInCacheToDropDownMenu(obj, uids_to_update, rebuild_menu)
            
            % Get the complete list of cache folders, unless we are only
            % updating specific uids
            if isempty(uids_to_update) || rebuild_menu
                uids = PTKDirectories.GetUidsOfAllDatasetsInCache;
            else
                uids = uids_to_update;
            end
            
            % If we are rebuilding the menu or are updating specific uids then
            % we force each menu entry to be updated
            if ~isempty(uids_to_update) || rebuild_menu
                rebuild_menu_for_each_uid = true;
            else
                rebuild_menu_for_each_uid = false;
            end
            
            % If we are rebuilding the menu then remove existings entries
            if rebuild_menu
                old_infos = containers.Map;
            else
                old_infos = obj.Settings.PreviousImageInfos;
            end
            settings_changed = false;
            
            for uid = uids
                temporary_uid = uid{1};
                if ~old_infos.isKey(temporary_uid) || rebuild_menu_for_each_uid
                    if ~rebuild_menu_for_each_uid
                        obj.Reporting.ShowMessage('PTKGui:UnimportedDaatsetFound', ['Dataset ' temporary_uid ' was found in the disk cache but not in the settings file. I am adding this dataset to the quick load menu. This may occur if the settings file was recently removed.']);
                    end
                    try
                        cache_parent_directory = PTKDirectories.GetCacheDirectory;
                        temporary_disk_cache = PTKDiskCache(cache_parent_directory, temporary_uid, obj.Reporting);
                        temporary_image_info = temporary_disk_cache.Load(PTKSoftwareInfo.ImageInfoCacheName, [], obj.Reporting);
                        old_infos(temporary_uid) = temporary_image_info;
                        obj.Settings.PreviousImageInfos = old_infos;
                        settings_changed = true;
                    catch exc
                        obj.Reporting.ShowWarning('PTKGui:AddDatasetToMenuFailed', ['An error occured when adding dataset ' temporary_uid ' to the quick load menu. Error: ' exc.message], exc);
                    end
                end                
            end
            
            if settings_changed
                obj.SaveSettings;
            end
        end
        
        function RunPluginTryCatchBlock(obj, plugin_name)
            wait_dialog = obj.WaitDialogHandle;
            
            new_plugin = PTKPluginInformation.LoadPluginInfoStructure(plugin_name, obj.Reporting);
            wait_dialog.ShowAndHold(['Computing ' new_plugin.ButtonText]);
            
            plugin_text = PTKTextUtilities.RemoveHtml(new_plugin.ButtonText);
            
            if strcmp(new_plugin.PluginType, 'DoNothing')
                obj.Dataset.GetResult(plugin_name);
            else
                [~, new_image] = obj.Dataset.GetResult(plugin_name);
                if strcmp(new_plugin.PluginType, 'ReplaceOverlay')
                    
                    if isempty(new_image)
                        obj.Reporting.Error('PTKGui:EmptyImage', ['The plugin ' plugin_name ' did not return an image when expected. If this plugin should not return an image, then set its PluginType property to "DoNothing"']);
                    end
                    if isequal(new_image.ImageSize, obj.ImagePanel.BackgroundImage.ImageSize) && isequal(new_image.Origin, obj.ImagePanel.BackgroundImage.Origin)
                        obj.ReplaceOverlayImage(new_image.RawImage, new_image.ImageType, plugin_text)
                    else
                        obj.ReplaceOverlayImageAdjustingSize(new_image, plugin_text);
                    end
                    obj.SetCurrentPluginAndUpdateFigureTitle(plugin_name);
                elseif strcmp(new_plugin.PluginType, 'ReplaceQuiver')
                    if all(new_image.ImageSize(1:3) == obj.ImagePanel.BackgroundImage.ImageSize(1:3)) && all(new_image.Origin == obj.ImagePanel.BackgroundImage.Origin)
                        obj.ReplaceQuiverImage(new_image.RawImage, 4);
                    else
                        obj.ReplaceQuiverImageAdjustingSize(new_image);
                    end
                    
                elseif strcmp(new_plugin.PluginType, 'ReplaceImage')
                    obj.SetImage(new_image);
                end
            end
        end
        
        
        % Executes when application closes
        function CustomCloseFunction(obj, src, ~)
            obj.ApplicationClosing();
            
            % Note: this will delete the only reference to the application
            % object handle, triggering its destruction which will save settings
            delete(src);
            
        end
        
        function ApplicationClosing(obj)
            obj.AutoSaveMarkers;
            obj.SaveSettings;
        end        
        
        % Executes when figure is resized
        function ResizeCallback(obj, ~, ~, ~)
            obj.Resize;
        end
        
        % Item selected from the pop-up "quick load" menu
        function PopupmenuLoadCallback(obj, hObject, ~, ~)
            obj.LoadFromPopupMenu(get(hObject, 'Value'));
        end
        
        function LoadFromPopupMenu(obj, index)            
            image_info = obj.DropDownLoadMenuManager.GetImageInfoForIndex(index);

            % Get the UID of the newly selected dataset
            if isempty(image_info)
                selected_image_uid = [];
            else
                selected_image_uid = image_info.ImageUid;
            end
            
            % Get the UID of the currently loaded dataset
            if ~isempty(obj.Settings.ImageInfo) && ~isempty(obj.Settings.ImageInfo.ImageUid)
                currently_loaded_image_UID = obj.Settings.ImageInfo.ImageUid;
            else
                currently_loaded_image_UID = [];
            end

            image_already_loaded = strcmp(selected_image_uid, currently_loaded_image_UID);
            if isempty(selected_image_uid) && isempty(currently_loaded_image_UID)
                image_already_loaded = true;
            end
            
            % We prevent data re-loading when the same dataset is selected.
            % Also, due to a Matlab/Java bug, this callback may be called twice 
            % when an option is selected from the drop-down load menu using 
            % keyboard shortcuts. This will prevent the loading function from
            % being called twice
            if ~image_already_loaded
                if ~isempty(image_info)
                    obj.LoadImages(image_info, obj.WaitDialogHandle);
                else
                    obj.ClearDataset(obj.WaitDialogHandle);
                    % Clear dataset
                end
            end
        end
        
        % Profile checkbox
        % Enables or disables (and shows) Matlab's profiler
        function ProfileCheckboxCallback(obj, hObject, ~, ~)
            if get(hObject,'Value')
                profile on
            else
                profile viewer
            end
        end
        
        % Updates the "Show profile" check box according to the current running state
        % of the Matlab profiler
        function UpdateProfilerStatus(obj)
            profile_status = profile('status');
            if strcmp(profile_status.ProfilerStatus, 'on')
                set(obj.ProfileCheckboxHandle, 'Value', true);
            else
                set(obj.ProfileCheckboxHandle, 'Value', false);
            end
        end
        
        % Scroll wheel
        function WindowScrollWheelFcn(obj, src, eventdata)
            current_point = get(obj.FigureHandle, 'CurrentPoint');
            scroll_count = eventdata.VerticalScrollCount; % positive = scroll down
            
            % Give the plugins panel the option of processing the scrollwheel
            % input; if it isn't processed then call the old handler
            if ~obj.PluginsPanel.Scroll(scroll_count, current_point)
                obj.OldWindowScrollWheelFcn(src, eventdata);
            end
        end
        
        function MarkerPanelSelected(obj, ~, ~)
            if ~obj.MarkersHaveBeenLoaded
                wait_dialog = obj.WaitDialogHandle;
                wait_dialog.ShowAndHold('Loading Markers');
                obj.LoadMarkers;
                wait_dialog.Hide;
            end
        end
        
        function LoadImages(obj, image_info, wait_dialog)
            wait_dialog.ShowAndHold('Please wait');
            
            try
                new_dataset = obj.Ptk.CreateDatasetFromInfo(image_info);

                obj.ClearImages;
                delete(obj.Dataset);

                obj.Dataset = new_dataset;
                obj.Dataset.addlistener('PreviewImageChanged', @obj.PreviewImageChanged);
                
                image_info = obj.Dataset.GetImageInfo;
                modality = image_info.Modality;
                
                % If the modality is not CT then we load the full dataset
                load_full_data = ~(isempty(modality) || strcmp(modality, 'CT'));
                    
                % Attempt to obtain the region of interest
                if ~load_full_data
                    if obj.Dataset.IsContextEnabled(PTKContext.LungROI)
                        try
                            lung_roi = obj.Dataset.GetResult('PTKLungROI');
                            obj.SetImage(lung_roi);
                        catch exc
                            if PTKSoftwareInfo.IsErrorCancel(exc.identifier)
                                obj.Reporting.Log('LoadImages cancelled by user');
                                load_full_data = false;
                                rethrow(exc)
                            else
                                obj.Reporting.ShowMessage('PTKGuiApp:CannotGetROI', ['Unable to extract region of interest from this dataset. Error: ' exc.message]);
                                load_full_data = true;
                            end
                        end
                    else
                        load_full_data = true;
                    end
                end

                % If we couldn't obtain the ROI, we load the full dataset
                if load_full_data
                    % Force the image to be saved so that it doesn't have to be
                    % reloaded each time
                    lung_roi = obj.Dataset.GetResult('PTKOriginalImage', PTKContext.OriginalImage, [], true);
                    obj.SetImage(lung_roi);
                end
                
                obj.Settings.ImageInfo = image_info;
                
                old_infos = obj.Settings.PreviousImageInfos;
                if ~old_infos.isKey(image_info.ImageUid)
                    old_infos(image_info.ImageUid) = image_info;
                    obj.Settings.PreviousImageInfos = old_infos;
                end
                
                obj.SaveSettings;
                
                obj.SetCurrentPluginAndUpdateFigureTitle([]);
                
                obj.PluginsPanel.AddAllPreviewImagesToButtons(obj.Dataset, obj.ImagePanel.Window, obj.ImagePanel.Level);

                if obj.ImagePanel.IsInMarkerMode
                    obj.LoadMarkers;                    
                end

            catch exc
                if PTKSoftwareInfo.IsErrorCancel(exc.identifier)
                    obj.ClearDataset(obj.WaitDialogHandle);
                    obj.Reporting.ShowMessage('PTKGui:LoadingCancelled', 'User cancelled loading');
                elseif PTKSoftwareInfo.IsErrorFileMissing(exc.identifier)
                    msgbox('This dataset is missing. It will be removed from the load menu.', [PTKSoftwareInfo.Name ': Cannot find dataset'], 'error');
                    obj.Reporting.ShowMessage('PTKGui:FileNotFound', 'The original data is missing. I am removing this dataset.');
                    obj.DeleteImageInfo
                else
                    msgbox(exc.message, [PTKSoftwareInfo.Name ': Cannot load dataset'], 'error');
                    obj.Reporting.ShowMessage('PTKGui:LoadingFailed', ['Failed to load dataset due to error: ' exc.message]);
                end
            end
            
            obj.DropDownLoadMenuManager.UpdateQuickLoadMenu;
            wait_dialog.Hide;

        end
        
        function ClearDataset(obj, wait_dialog)
            wait_dialog.ShowAndHold('Please wait');
            
            try
                obj.ClearImages;
                delete(obj.Dataset);

                obj.Dataset = [];
                
                image_info = [];                

                obj.Settings.ImageInfo = image_info;
                
                obj.SaveSettings;
                
                obj.SetCurrentPluginAndUpdateFigureTitle([]);
                
                obj.PluginsPanel.AddAllPreviewImagesToButtons(obj.Dataset, obj.ImagePanel.Window, obj.ImagePanel.Level);

            catch exc
                if PTKSoftwareInfo.IsErrorCancel(exc.identifier)
                    obj.Reporting.ShowMessage('PTKGui:LoadingCancelled', 'User cancelled loading');
                elseif PTKSoftwareInfo.IsErrorFileMissing(exc.identifier)
                    msgbox('This dataset is missing. It will be removed from the load menu.', [PTKSoftwareInfo.Name ': Cannot find dataset'], 'error');
                    obj.Reporting.ShowMessage('PTKGui:FileNotFound', 'The original data is missing. I am removing this dataset.');
                    obj.DeleteImageInfo
                else
                    msgbox(exc.message, [PTKSoftwareInfo.Name ': Cannot load dataset'], 'error');
                    obj.Reporting.ShowMessage('PTKGui:LoadingFailed', ['Failed to load dataset due to error: ' exc.message]);
                end
            end
            
            obj.DropDownLoadMenuManager.UpdateQuickLoadMenu;
            wait_dialog.Hide;

        end
        

        function LoadMarkers(obj)
            
            new_image = obj.Dataset.LoadData(PTKSoftwareInfo.MakerPointsCacheName);
            if isempty(new_image)
                disp('No previous markers found for this image');
            else
                obj.ImagePanel.MarkerPointManager.ChangeMarkerImage(new_image);
            end
            obj.MarkersHaveBeenLoaded = true;
        end
        
        
        
        function ClearImages(obj)

            if ~isempty(obj.Dataset)
                obj.AutoSaveMarkers;
                obj.MarkersHaveBeenLoaded = false;
                obj.ImagePanel.BackgroundImage.Reset;
            end
            obj.DeleteOverlays;
        end
        
        
        
        function SetCurrentPluginAndUpdateFigureTitle(obj, plugin_name)
            obj.CurrentPluginName = plugin_name;
            obj.UpdateFigureTitle;
        end
        
        function UpdateFigureTitle(obj)
            
            figure_title = PTKSoftwareInfo.Name;
            if isa(obj.ImagePanel.BackgroundImage, 'PTKImage')
                patient_name = obj.ImagePanel.BackgroundImage.Title;
                if ~isempty(obj.CurrentPluginName) && obj.ImagePanel.OverlayImage.ImageExists
                    overlay_name = obj.ImagePanel.OverlayImage.Title;
                    if ~isempty(overlay_name)
                        patient_name = [patient_name ' (' overlay_name ')'];
                    end
                end
                if ~isempty(figure_title)
                    figure_title = [patient_name ' : ' figure_title];
                end
            end
            
            % Remove HTML tags
            figure_title = regexprep(figure_title, '<.*?>','');
            
            % Set window title
            set(obj.FigureHandle, 'Name', figure_title);
        end
        
        
        function RunGuiPluginCallback(obj, ~, ~, plugin_name)
            
            wait_dialog = obj.WaitDialogHandle;
            
            plugin_info = eval(plugin_name);
            wait_dialog.ShowAndHold([plugin_info.ButtonText]);

            plugin_info.RunGuiPlugin(obj);
            
            wait_dialog.Hide;
        end
        
        
        function RunPluginCallback(obj, ~, ~, plugin_name)
            obj.RunPlugin(plugin_name);
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
                
        function ReplaceOverlayImageAdjustingSize(obj, new_image, title)
            new_image.ResizeToMatch(obj.ImagePanel.BackgroundImage);
            obj.ImagePanel.OverlayImage.ChangeRawImage(new_image.RawImage, new_image.ImageType);
            obj.ImagePanel.OverlayImage.Title = title;
        end
        
        function ReplaceOverlayImage(obj, new_image, image_type, title)
            obj.ImagePanel.OverlayImage.ChangeRawImage(new_image, image_type);
            obj.ImagePanel.OverlayImage.Title = title;
        end
        
        function ReplaceQuiverImageAdjustingSize(obj, new_image)
            new_image.ResizeToMatch(obj.ImagePanel.BackgroundImage);
            obj.ImagePanel.QuiverImage.ChangeRawImage(new_image.RawImage, new_image.ImageType);
        end
        
        function ReplaceQuiverImage(obj, new_image, image_type)
            obj.ImagePanel.QuiverImage.ChangeRawImage(new_image, image_type);
        end
        
        function SaveSettings(obj)
            if ~isempty(obj.Settings)
                set(obj.FigureHandle, 'units', 'pixels');
                obj.Settings.ScreenPosition = get(obj.FigureHandle, 'Position');
                obj.Settings.SaveSettings(obj.ImagePanel, obj.Reporting);
            end
        end
        
        function delete(obj)
            if ~isempty(obj.Reporting);
                obj.Reporting.Log('Closing PTKGui');
            end
        end
        
        function PreviewImageChanged(obj, ~, event_data)
            plugin_name = event_data.Data;
            obj.PluginsPanel.AddPreviewImage(plugin_name, obj.Dataset, obj.ImagePanel.Window, obj.ImagePanel.Level);
        end
        
        function AutoSaveMarkers(obj)
            if ~isempty(obj.ImagePanel)
                if obj.ImagePanel.MarkerPointManager.MarkerImageHasChanged && obj.MarkersHaveBeenLoaded
                    saved_marker_points = obj.Dataset.LoadData(PTKSoftwareInfo.MakerPointsCacheName);
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
        
        function Resize(obj)
            set(obj.FigureHandle, 'Units', 'Pixels');

            parent_position = get(obj.FigureHandle, 'Position');
            parent_width_pixels = parent_position(3);
            parent_height_pixels = parent_position(4);
            
            load_menu_height = 23;
            viewer_panel_height = max(1, parent_height_pixels - load_menu_height);
            viewer_panel_width = viewer_panel_height;
            
            version_panel_height = 35;
            version_panel_width = max(1, parent_width_pixels - viewer_panel_width);
            
            plugins_panel_height = max(1, parent_height_pixels - load_menu_height - version_panel_height);
            
            set(obj.UipanelImageHandle, 'Units', 'Pixels', 'Position', [1, 1, viewer_panel_width, viewer_panel_height]);
            set(obj.PopupmenuLoadHandle, 'Units', 'Pixels', 'Position', [0, parent_height_pixels - load_menu_height, parent_width_pixels, load_menu_height]);
            set(obj.UipanelVersionHandle, 'Units', 'Pixels', 'Position', [viewer_panel_width, parent_height_pixels - load_menu_height - version_panel_height, version_panel_width, version_panel_height]);
            set(obj.UipanelPluginsHandle, 'Units', 'Pixels', 'Position', [viewer_panel_width, 0, version_panel_width, plugins_panel_height]);
            obj.PluginsPanel.Resize();
            
            if ~isempty(obj.WaitDialogHandle)
                obj.WaitDialogHandle.Resize();
            end
        end
        
    end
    
    methods (Static, Access = private)
        function [filename, path_name, filter_index] = SaveImageDialogBox(path_name)
            filespec = {...
                '*.tif', 'TIF (*.tif)';
                '*.jpg', 'JPG (*.jpg)';
                };
            
            if exist(path_name, 'dir') ~= 7
                path_name = '';
            end
            
            [filename, path_name, filter_index] = uiputfile(filespec, 'Save image as', fullfile(path_name, ''));
        end
    end
end
