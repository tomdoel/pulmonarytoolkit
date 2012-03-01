classdef TDPTKGuiApp < handle
    % TDPTKGuiApp. Part of the gui for the Pulmonary Toolkit.
    %
    %     You should not use this class within your own code. It is intended to
    %     be used internally within the gui of the Pulmonary Toolkit.
    %
    %     TDPTKGuiApp is the main application class for the Pulmonary Toolkit
    %     gui. It is created by TDPTKGui. It implements the callbacks which are
    %     called when gui controls are selected, and also provides routines used
    %     by gui plugins.
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
        ImageAxes
    end
    
    methods
        function obj = TDPTKGuiApp(viewer_panel_handle, figure_handle, uipanel_handle, popupmenu_handle, text_version_handle, handles)
            
            % Create the splash screen.
            splash_screen = TDSplashScreen;
            
            obj.ImageAxes = handles.uipanel_image;
            
            % Set the application name and version number
            set(text_version_handle, 'String', obj.GetSoftwareNameAndVersionForDisplay);

            set(figure_handle, 'Color', [0, 0.129, 0.278]);
            obj.PluginsPanel = TDPluginsPanel(uipanel_handle, obj.Reporting);
            obj.ImagePanel = TDViewerPanel(viewer_panel_handle);
            addlistener(obj.ImagePanel, 'MarkerPanelSelected', @obj.MarkerPanelSelected);
            obj.FigureHandle = figure_handle;
            
            % For the moment, we use the splash screen to display progress,
            % because the gui isn't yet visible so the ProgressPanel won't
            % display
            obj.Reporting = TDReporting(splash_screen, obj.ImagePanel);
            obj.Reporting.Log('New session of TDPTKGui');
            
            obj.Ptk = TDPTK(obj.Reporting);
            
            obj.Settings = TDPTKSettings.LoadSettings(obj.ImagePanel, obj.Reporting);
            
            obj.DropDownLoadMenuManager = TDDropDownLoadMenuManager(obj.Settings, popupmenu_handle);

            obj.PluginsPanel.AddPlugins(@obj.RunPluginCallback, @obj.RunGuiPluginCallback, []);
            
            image_info = obj.Settings.ImageInfo;
            
            if ~isempty(image_info)
                obj.LoadImages(image_info, splash_screen);
            end
            
            obj.WaitDialogHandle = TDProgressPanel(obj.ImageAxes);

            
            % Now we switch to a progress panel displayed over the gui
            obj.Reporting.ProgressDialog = obj.WaitDialogHandle;
            splash_screen.Delete;

        end
        
        function SelectFilesAndLoad(obj)
            image_info = TDChooseImagingFiles(obj.Settings.SaveImagePath);
            
            % An empty image_info means the user has cancelled
            if ~isempty(image_info)
                % Save the path in the settings so that future load dialogs 
                % will start from there
                obj.Settings.SaveImagePath = image_info.ImagePath;
                obj.SaveSettings;
                obj.LoadImages(image_info, obj.WaitDialogHandle);
            end
        end
       
        function LoadFromPopupMenu(obj, index)            
            image_info = obj.DropDownLoadMenuManager.GetImageInfoForIndex(index);
            
            % An empty image_info indicates that this dataset has already been
            % selected. This prevents data re-loading when the same dataset is
            % selected.
            % Also, due to a Matlab/Java bug, this callback may be called twice 
            % when an option is selected from the drop-down load menu using 
            % keyboard shortcuts. This will prevent the loading function from
            % being called twice
            if ~isempty(image_info)
                obj.LoadImages(image_info, obj.WaitDialogHandle);
            end
            
        end
        
        function SaveBackgroundImage(obj)
            patient_name = obj.ImagePanel.BackgroundImage.Title;
            image_data = obj.ImagePanel.BackgroundImage;
            path_name = obj.Settings.SaveImagePath;
            
            path_name = TDSaveAs(image_data, patient_name, path_name, obj.Reporting);
            if ~isempty(path_name)
                obj.Settings.SaveImagePath = path_name;
                obj.SaveSettings;
            end
        end
        
        function SaveOverlayImage(obj)
            patient_name = obj.ImagePanel.BackgroundImage.Title;
            image_data = obj.ImagePanel.OverlayImage;
            path_name = obj.Settings.SaveImagePath;
            
            path_name = TDSaveAs(image_data, patient_name, path_name, obj.Reporting);
            if ~isempty(path_name)
                obj.Settings.SaveImagePath = path_name;
                obj.SaveSettings;
            end
        end
        
        function SaveMarkers(obj)
            if ~isempty(obj.Dataset)
                markers = obj.ImagePanel.MarkerPointManager.GetMarkerImage;
                obj.Dataset.SaveData(TDSoftwareInfo.MakerPointsCacheName, markers);
                obj.ImagePanel.MarkerPointManager.MarkerPointsHaveBeenSaved;
            end
        end
        
        function SaveMarkersBackup(obj)
            if ~isempty(obj.Dataset)
                markers = obj.ImagePanel.MarkerPointManager.GetMarkerImage;
                obj.Dataset.SaveData('AbandonedMarkerPoints', markers);
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
        
        function display_string = GetSoftwareNameAndVersionForDisplay(obj)
            display_string = [TDSoftwareInfo.Name, ' version ' TDSoftwareInfo.Version];
        end        
        
        function ApplicationClosing(obj)
            obj.AutoSaveMarkers;
            obj.SaveSettings;
        end
        
        function dataset_cache_path = GetDatasetCachePath(obj)
            if ~isempty(obj.Dataset)
                dataset_cache_path = obj.Dataset.GetDatasetCachePath;
            else
                dataset_cache_path = TDDiskCache.GetCacheDirectory;
            end
        end
        
        function ClearCacheForThisDataset(obj)
            if ~isempty(obj.Dataset)
                obj.Dataset.ClearCacheForThisDataset;
            end
        end
        
        function Resize(obj, handles)
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
            
            set(handles.uipanel_image, 'Units', 'Pixels', 'Position', [1, 1, viewer_panel_width, viewer_panel_height]);
            set(handles.popupmenu_load, 'Units', 'Pixels', 'Position', [0, parent_height_pixels - load_menu_height, parent_width_pixels, load_menu_height]);
            set(handles.uipanel_version, 'Units', 'Pixels', 'Position', [viewer_panel_width, parent_height_pixels - load_menu_height - version_panel_height, version_panel_width, version_panel_height]);
            set(handles.uipanel_plugins, 'Units', 'Pixels', 'Position', [viewer_panel_width, 0, version_panel_width, plugins_panel_height]);
            obj.PluginsPanel.Resize();
            
            if ~isempty(obj.WaitDialogHandle)
                obj.WaitDialogHandle.Resize();
            end
        end
        
        
    end
    
    
    methods (Access = private)
        
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
                    if obj.Dataset.IsContextEnabled(TDContext.LungROI)
                        try
                            lung_roi = obj.Dataset.GetResult('TDLungROI');
                            obj.SetImage(lung_roi);
                        catch exc
                            obj.Reporting.ShowMessage(['Unable to extract region of interest from this dataset. Error: ' exc.message]);
                            load_full_data = true;
                        end
                    else
                        load_full_data = true;
                    end
                end

                % If we couldn't obtain the ROI, we load the full dataset
                if load_full_data
                    lung_roi = obj.Dataset.GetResult('TDOriginalImage');
                    obj.SetImage(lung_roi);
                    obj.Dataset.SaveData('TDOriginalImage', lung_roi);
                end
                
                obj.Settings.ImageInfo = image_info;
                
                old_infos = obj.Settings.PreviousImageInfos;
                if ~old_infos.isKey(image_info.ImageUid)
                    old_infos(image_info.ImageUid) = image_info;
                    obj.Settings.PreviousImageInfos = old_infos;
                end
                
                obj.SaveSettings;
                
                obj.UpdateFigureTitle;
                
                obj.PluginsPanel.AddAllPreviewImagesToButtons(obj.Dataset, obj.ImagePanel.Window, obj.ImagePanel.Level);

                if obj.ImagePanel.IsInMarkerMode
                    obj.LoadMarkers;                    
                end

            catch exc
                msgbox(exc.message, [TDSoftwareInfo.Name ': Cannot load dataset'], 'error');
                obj.Reporting.ShowMessage(['Failed to load dataset due to error: ' exc.message]);
            end
            
            obj.DropDownLoadMenuManager.UpdateQuickLoadMenu;
            wait_dialog.Hide;

        end
        
        
    
        function LoadMarkers(obj)
            
            new_image = obj.Dataset.LoadData(TDSoftwareInfo.MakerPointsCacheName);
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
        
        
        function DeleteOverlays(obj)
            obj.ImagePanel.ClearOverlays;
            obj.UpdateFigureTitle;
        end
        
        
        function UpdateFigureTitle(obj)
            
            figure_title = TDSoftwareInfo.Name;
            if isa(obj.ImagePanel.BackgroundImage, 'TDImage')
                patient_name = obj.ImagePanel.BackgroundImage.Title;
                if obj.ImagePanel.OverlayImage.ImageExists
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
            if isempty(obj.Dataset)
                return;
            end
            
            wait_dialog = obj.WaitDialogHandle;
            
            
            new_plugin = TDPluginInformation.LoadPluginInfoStructure(plugin_name, obj.Reporting);
            wait_dialog.ShowAndHold(['Computing ' new_plugin.ButtonText]);
            
            plugin_text = new_plugin.ButtonText;
            
            if strcmp(new_plugin.PluginType, 'DoNothing')
                obj.Dataset.GetResult(plugin_name);
            else
                [~, new_image] = obj.Dataset.GetResult(plugin_name);
                if strcmp(new_plugin.PluginType, 'ReplaceOverlay')

                    if all(new_image.ImageSize == obj.ImagePanel.BackgroundImage.ImageSize) && all(new_image.Origin == obj.ImagePanel.BackgroundImage.Origin)
                        obj.ReplaceOverlayImage(new_image.RawImage, new_image.ImageType, plugin_text)
                    else
                        obj.ReplaceOverlayImageAdjustingSize(new_image, plugin_text);
                    end
                    obj.UpdateFigureTitle;
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
            
            wait_dialog.Hide;            
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
            obj.Settings.SaveSettings(obj.ImagePanel, obj.Reporting);
        end
        
        function delete(obj)
            obj.Reporting.Log('Closing TDPTKGui');
        end
        
        function PreviewImageChanged(obj, ~, event_data)
            plugin_name = event_data.Data;
            obj.PluginsPanel.AddPreviewImage(plugin_name, obj.Dataset, obj.ImagePanel.Window, obj.ImagePanel.Level);
        end
        
        function AutoSaveMarkers(obj)            
            if obj.ImagePanel.MarkerPointManager.MarkerImageHasChanged && obj.MarkersHaveBeenLoaded
                saved_marker_points = obj.Dataset.LoadData(TDSoftwareInfo.MakerPointsCacheName);
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
end
