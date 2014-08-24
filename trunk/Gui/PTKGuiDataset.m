classdef PTKGuiDataset < handle
    % PTKGuiDataset. Handles the interaction between the GUI and the PTK interfaces
    %
    %
    %     You do not need to modify this file. To add new functionality, create
    %     new plguins in the Plugins and GuiPlugins folders.
    % 
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    
    properties (SetAccess = private)
        CurrentContext
        GuiDatasetState
    end
    
    properties (Access = private)
        Dataset
        Gui
        ModeSwitcher
        Ptk
        Reporting
        Settings 
    end
    
    methods
        function obj = PTKGuiDataset(gui, viewer_panel, settings, reporting)
            obj.GuiDatasetState = PTKGuiDatasetState;
            obj.ModeSwitcher = PTKModeSwitcher(viewer_panel, obj, settings, reporting);

            obj.Gui = gui;
            obj.Reporting = reporting;
            obj.Settings = settings;
            obj.Ptk = PTKMain(reporting);
        end
        
        function ModeTabChanged(obj, mode_name)
            if strcmp(mode_name, 'all')
                mode_name = '';
            end
            obj.ChangeMode(mode_name)
        end
        
        function ChangeMode(obj, mode)
            obj.ModeSwitcher.SwitchMode(mode, obj.Dataset, obj.GuiDatasetState.CurrentPluginInfo, obj.GuiDatasetState.CurrentPluginName, obj.GuiDatasetState.CurrentVisiblePluginName, obj.CurrentContext);
        end        

        function mode = GetMode(obj)
            mode = obj.ModeSwitcher.CurrentMode;
            if isempty(mode)
                obj.Reporting.Error('PTKGui::NoMode', 'The operation is not possible in this mode');
            end
        end
        
        function is_dataset = DatasetIsLoaded(obj)
            is_dataset = ~isempty(obj.Dataset);
        end
        
        function is_dataset = IsPluginResultLoaded(obj)
            is_dataset = ~isempty(obj.Dataset);
        end
        
        function image_database = GetImageDatabase(obj)
            image_database = obj.Ptk.ImageDatabase;
        end
        
        function uids = ImportDataRecursive(obj, folder_path)
            uids = obj.Ptk.ImportDataRecursive(folder_path);
            
            % Add any new datasets to the patient browser
            obj.Gui.DatabaseHasChanged;
        end
        
        function [sorted_paths, sorted_uids] = GetListOfPaths(obj)
            [sorted_paths, sorted_uids] = obj.Ptk.ImageDatabase.GetListOfPaths;
        end
        
        function template_image = GetTemplateImage(obj)
            template_image = obj.Dataset.GetTemplateImage(PTKContext.OriginalImage);
        end
        
        function SaveMarkers(obj, markers)
            obj.Dataset.SaveData(PTKSoftwareInfo.MakerPointsCacheName, markers);
        end
        
        function SaveAbandonedMarkers(obj, markers)
            obj.Dataset.SaveData('AbandonedMarkerPoints', markers);
        end
        
        function SaveMarkersManualBackup(obj, markers)
            obj.Dataset.SaveData('MarkerPointsLastManualSave', markers);
        end

        function markers = LoadMarkers(obj)
            markers = obj.Dataset.LoadData(PTKSoftwareInfo.MakerPointsCacheName);
        end
        
        
        function dataset_cache_path = GetDatasetCachePath(obj)
            if obj.DatasetIsLoaded
                dataset_cache_path = obj.Dataset.GetDatasetCachePath;
            else
                dataset_cache_path = PTKDirectories.GetCacheDirectory;
            end
        end
        
        function dataset_cache_path = GetEditedResultsPath(obj)
            if obj.DatasetIsLoaded
                dataset_cache_path = obj.Dataset.GetEditedResultsPath;
            else
                dataset_cache_path = PTKDirectories.GetEditedResultsDirectoryAndCreateIfNecessary;
            end
        end

        function dataset_cache_path = GetOutputPath(obj)
            if obj.DatasetIsLoaded
                dataset_cache_path = obj.Dataset.GetOutputPath;
            else
                dataset_cache_path = PTKDirectories.GetOutputDirectoryAndCreateIfNecessary;
            end
        end
        
        function image_info = GetImageInfo(obj)
            if obj.DatasetIsLoaded
                image_info = obj.Dataset.GetImageInfo;
            else
                image_info = [];
            end
        end        
        
        function ClearCacheForThisDataset(obj)
            if obj.DatasetIsLoaded
                obj.Dataset.ClearCacheForThisDataset(false);
                obj.Gui.AddAllPreviewImagesToButtons([]);
            end
        end

        
        function RefreshPlugins(obj)
            obj.Gui.RefreshPluginsForDataset(obj.Dataset)
        end
        
        function currently_loaded_image_UID = GetUidOfCurrentDataset(obj)
            
            if ~isempty(obj.Settings.ImageInfo) && ~isempty(obj.Settings.ImageInfo.ImageUid)
                currently_loaded_image_UID = obj.Settings.ImageInfo.ImageUid;
            else
                currently_loaded_image_UID = [];
            end
        end
        
        function ClearDataset(obj)
            try
                obj.ModeSwitcher.UpdateMode([], [], [], [], []);
                obj.Gui.ClearImages;
                delete(obj.Dataset);

                obj.Dataset = [];
                
                image_info = [];                

                obj.Settings.ImageInfo = image_info;
                
                obj.Gui.SaveSettings;
                
                obj.SetNoDataset;
                
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

            obj.Gui.AddAllPreviewImagesToButtons([]);
            obj.Gui.UpdatePatientBrowser([], []);
        end
        
        
        function SaveEditedResult(obj)
            obj.ModeSwitcher.SaveEditedResult;
        end
        
        function DeleteImageInfo(obj)
            obj.DeleteDatasets(obj.GetUidOfCurrentDataset);
        end
        
        function DeleteDatasets(obj, series_uids)
            % Removes a dataset from the database and deletes its disk cache. If the dataset
            % is currently loaded then we must also clear the current dataset
            
            % Get the UID of the currently loaded dataset
            currently_loaded_series_UID = obj.GetUidOfCurrentDataset;
            
            if ~iscell(series_uids)
                series_uids = {series_uids};
            end
            
            anything_changed = false;
            
            for series_uid_cell = series_uids
                series_uid = series_uid_cell{1};

                % Test whether the dataset to delete is the current dataset
                is_dataset_currently_loaded = strcmp(series_uid, currently_loaded_series_UID);
                if is_dataset_currently_loaded
                    dataset_to_delete = obj.Dataset;
                    obj.Settings.ImageInfo = [];
                else
                    dataset_to_delete = obj.Ptk.CreateDatasetFromUid(series_uid);
                end
                
                if ~isempty(dataset_to_delete)
                    dataset_to_delete.DeleteCacheForThisDataset;
                    
                    anything_changed = true;
                    
                    delete(dataset_to_delete);
                end
                
                if is_dataset_currently_loaded
                    obj.ModeSwitcher.UpdateMode([], [], [], [], []);
                    obj.Gui.ClearImages;
                    obj.Dataset = [];
                    obj.Gui.SaveSettings;
                end
            
            end
            
            obj.Ptk.ImageDatabase.DeleteSeries(series_uids, obj.Reporting);
            
            if anything_changed
                obj.Gui.DatabaseHasChanged;
            end
        end
        
        
        function InternalLoadImages(obj, image_info_or_uid)
            try
                if isa(image_info_or_uid, 'PTKImageInfo')
                    new_dataset = obj.Ptk.CreateDatasetFromInfo(image_info_or_uid);
                else
                    new_dataset = obj.Ptk.CreateDatasetFromUid(image_info_or_uid);
                end

                obj.ModeSwitcher.UpdateMode([], [], [], [], []);
                
                obj.Gui.ClearImages;
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
                            obj.SetImage(lung_roi, PTKContext.LungROI);
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
                    obj.SetImage(lung_roi, PTKContext.OriginalImage);
                end
                
                series_uid = image_info.ImageUid;
                if isfield(lung_roi.MetaHeader, 'PatientID')
                    patient_id = lung_roi.MetaHeader.PatientID;
                else
                    patient_id = series_uid;
                end

                settings_changed = false;
                
                if ~isequal(image_info, obj.Settings.ImageInfo)
                    obj.Settings.ImageInfo = image_info;
                    settings_changed = true;
                end
                
                % Save settings if anything has changed
                if settings_changed
                    obj.Gui.SaveSettings;
                end
                
                obj.GuiDatasetState.ClearPlugin;
                obj.UpdateModes;
                
                if isempty(image_info)
                    patient_visible_name = [];
                    series_name = [];
                else
                    series_info = obj.GetImageDatabase.GetSeries(image_info.ImageUid);
                    patient_info = obj.GetImageDatabase.GetPatient(series_info.PatientId);
                    patient_visible_name = patient_info.ShortVisibleName;
                    series_name = series_info.Name;
                end

                obj.Gui.AddAllPreviewImagesToButtons(obj.Dataset);

                obj.Gui.LoadMarkersIfRequired;

                obj.GuiDatasetState.SetPatientAndSeries(patient_id, series_uid, patient_visible_name, series_name);
                
            catch exc
                % For the patient browser
                patient_id = [];
                series_uid = [];
                
                if PTKSoftwareInfo.IsErrorCancel(exc.identifier)
                    obj.Reporting.ShowProgress('Cancelling load');
                    obj.ClearDataset;
                    obj.Reporting.ShowMessage('PTKGui:LoadingCancelled', 'User cancelled loading');
                elseif PTKSoftwareInfo.IsErrorFileMissing(exc.identifier)
                    msgbox('This dataset is missing. It will be removed from the load menu.', [PTKSoftwareInfo.Name ': Cannot find dataset'], 'error');
                    obj.Reporting.ShowMessage('PTKGui:FileNotFound', 'The original data is missing. I am removing this dataset.');
                    obj.GuiDataset.DeleteImageInfo
                else
                    msgbox(exc.message, [PTKSoftwareInfo.Name ': Cannot load dataset'], 'error');
                    obj.Reporting.ShowMessage('PTKGui:LoadingFailed', ['Failed to load dataset due to error: ' exc.message]);
                end
                
                obj.GuiDatasetState.ClearPatientAndSeries;
                
            end
            
            obj.Gui.UpdatePatientBrowser(patient_id, series_uid);
        end
        
        % Causes the GUI to run the named plugin and display the result
        function RunPlugin(obj, plugin_name, wait_dialog)
            if ~obj.DatasetIsLoaded
                return;
            end
            
            if PTKSoftwareInfo.DebugMode
                obj.RunPluginTryCatchBlock(plugin_name, wait_dialog)
            else
                try
                    obj.RunPluginTryCatchBlock(plugin_name, wait_dialog)
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
       
        function InvalidateCurrentPluginResult(obj)
            % Indicates that the currently loaded result has been deleted or modified in
            % such a way that it is no longer representative of the plugin 
            
            obj.GuiDatasetState.ClearPlugin;
            obj.UpdateModes;
        end

        function OverlayImageChanged(obj)
            obj.ModeSwitcher.OverlayImageChanged;
        end
        
        function UpdateModeTabControl(obj)
            obj.Gui.UpdateModeTabControl(obj.GuiDatasetState.CurrentPluginInfo);
        end
        
        function SaveSettings(obj)
            obj.Gui.SaveSettings;
        end
        
        function SetNoDataset(obj)
            obj.GuiDatasetState.ClearPatientAndSeries;            
            obj.GuiDatasetState.ClearPlugin;
            obj.UpdateModes;
        end
        
        function UpdateEditedStatus(obj, is_edited)
            obj.GuiDatasetState.UpdateEditStatus(is_edited);
        end
            
        
    end
    
    methods (Access = private)
        function RunPluginTryCatchBlock(obj, plugin_name, wait_dialog)
            new_plugin = PTKPluginInformation.LoadPluginInfoStructure(plugin_name, obj.Reporting);
            visible_name = PTKTextUtilities.RemoveHtml(new_plugin.ButtonText);
            wait_dialog.ShowAndHold(['Computing ' visible_name]);
            
            if strcmp(new_plugin.PluginType, 'DoNothing')
                obj.Dataset.GetResult(plugin_name);
            else
                
                % Determine the context we require (full image, lung ROI, etc).
                % Normally we keep the last context, but if a context plugin is
                % selected, we switch to the new context
                context_to_request = obj.CurrentContext;
                if strcmp(new_plugin.PluginType, 'ReplaceImage')
                    if isa(new_plugin.Context, 'PTKContext')
                        context_to_request = new_plugin.Context;
                    elseif new_plugin.Context == PTKContextSet.OriginalImage
                        context_to_request = PTKContext.OriginalImage;
                    elseif new_plugin.Context == PTKContextSet.LungROI
                        context_to_request = PTKContext.LungROI;
                    end
                end
                
                [~, cache_info, new_image] = obj.Dataset.GetResultWithCacheInfo(plugin_name, context_to_request);
                
                if isa(cache_info, 'PTKCompositeResult')
                    cache_info = cache_info.GetFirstResult;
                end
                
                image_title = visible_name;
                if cache_info.IsEdited
                    image_title = ['EDITED ', image_title];
                end
                if strcmp(new_plugin.PluginType, 'ReplaceOverlay')                    
                    if isempty(new_image)
                        obj.Reporting.Error('PTKGui:EmptyImage', ['The plugin ' plugin_name ' did not return an image when expected. If this plugin should not return an image, then set its PluginType property to "DoNothing"']);
                    end
                    obj.ModeSwitcher.PrePluginCall;
                    obj.Gui.ReplaceOverlayImageCallback(new_image, image_title);
                    obj.GuiDatasetState.SetPlugin(new_plugin, plugin_name, visible_name, cache_info.IsEdited);
                    obj.UpdateModes;
                    
                elseif strcmp(new_plugin.PluginType, 'ReplaceQuiver')
                    
                    obj.Gui.ReplaceQuiverCallback(new_image);
                    
                elseif strcmp(new_plugin.PluginType, 'ReplaceImage')
                    obj.SetImage(new_image, context_to_request);
                end
            end
        end
        
        function PreviewImageChanged(obj, ~, event_data)
            plugin_name = event_data.Data;
            obj.Gui.AddPreviewImage(plugin_name, obj.Dataset);
        end
        
        function SetImage(obj, new_image, context)
            obj.CurrentContext = context;
            obj.Gui.SetImage(new_image);
        end
        
       
        function UpdateModes(obj)
            obj.ModeSwitcher.UpdateMode(obj.Dataset, obj.GuiDatasetState.CurrentPluginInfo, obj.GuiDatasetState.CurrentPluginName, obj.GuiDatasetState.CurrentVisiblePluginName, obj.CurrentContext);
            obj.Gui.UpdateModeTabControl(obj.GuiDatasetState.CurrentPluginInfo);
            obj.Gui.UpdateToolbar;
        end
        
    end
end
