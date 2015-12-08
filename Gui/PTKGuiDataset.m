classdef PTKGuiDataset < CoreBaseClass
    % PTKGuiDataset. Handles the interaction between the GUI and the PTK interfaces
    %
    %
    %     You do not need to modify this file. To add new functionality, create
    %     new plguins in the Plugins and GuiPlugins folders.
    % 
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
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
        AppDef
        ContextDef
        PreviewImageChangedListener
    end
    
    methods
        function obj = PTKGuiDataset(app_def, gui, viewer_panel, settings, reporting)
            obj.AppDef = app_def;
            obj.ContextDef = app_def.GetContextDef;
            obj.GuiDatasetState = PTKGuiDatasetState;
            obj.ModeSwitcher = PTKModeSwitcher(viewer_panel, obj, app_def, settings, reporting);
            
            obj.Gui = gui;
            obj.Reporting = reporting;
            obj.Settings = settings;
            obj.Ptk = PTKMain(reporting);
            obj.AddEventListener(obj.GetImageDatabase, 'SeriesHasBeenDeleted', @obj.SeriesHasBeenDeleted);
            obj.AddEventListener(obj.ModeSwitcher, 'ModeChangedEvent', @obj.ModeHasChanged);
        end

        function ChangeMode(obj, mode)
            obj.ModeSwitcher.SwitchMode(mode, obj.Dataset, obj.GuiDatasetState.CurrentPluginInfo, obj.GuiDatasetState.CurrentPluginName, obj.GuiDatasetState.CurrentVisiblePluginName, obj.CurrentContext, obj.GuiDatasetState.CurrentSegmentationName);
        end        

        function mode = GetMode(obj)
            mode = obj.ModeSwitcher.CurrentMode;
            if isempty(mode)
                obj.Reporting.Error('PTKGui::NoMode', 'The operation is not possible in this mode');
            end
        end
        
        function mode = GetCurrentModeName(obj)
            mode = obj.ModeSwitcher.CurrentModeString;
        end
        
        function mode = GetCurrentSubModeName(obj)
            mode = obj.ModeSwitcher.GetSubModeName;
        end
        
        function is_dataset = DatasetIsLoaded(obj)
            is_dataset = ~isempty(obj.Dataset);
        end
        
        function is_dataset = IsPluginResultLoaded(obj)
            is_dataset = ~isempty(obj.Dataset);
        end
        
        function image_database = GetImageDatabase(obj)
            image_database = obj.Ptk.GetImageDatabase;
        end
        
        function linked_recorder = GetLinkedRecorder(obj)
            linked_recorder = obj.Ptk.FrameworkSingleton.GetLinkedDatasetRecorder;
        end
        
        function uids = ImportDataRecursive(obj, folder_path)
            uids = obj.Ptk.ImportDataRecursive(folder_path);
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
            currently_loaded_image_UID = obj.GuiDatasetState.CurrentSeriesUid;
        end
        
        function ClearDataset(obj)
            try
                obj.ModeSwitcher.UpdateMode([], [], [], [], []);
                obj.Gui.ClearImages;
                delete(obj.Dataset);

                obj.Dataset = [];
                
                obj.Settings.SetLastImageInfo([], obj.Reporting);
                
                obj.SetNoDataset;
                
            catch exc
                if PTKSoftwareInfo.IsErrorCancel(exc.identifier)
                    obj.Reporting.ShowMessage('PTKGui:LoadingCancelled', 'User cancelled');
                else
                    obj.Reporting.ShowMessage('PTKGuiDataset:ClearDatasetFailed', ['Failed to clear dataset due to error: ' exc.message]);
                end
            end
        end
        
        
        function SaveEditedResult(obj)
            obj.ModeSwitcher.SaveEditedResult;
        end
        
        function DeleteThisImageInfo(obj)
            obj.DeleteDatasets(obj.GetUidOfCurrentDataset);
        end
        
        function DeleteImageInfo(obj, uid)
            obj.DeleteDatasets(uid);
        end
        
        function DeleteDatasets(obj, series_uids)
            % Removes a dataset from the database and deletes its disk cache. If the dataset
            % is currently loaded then the callback from the image database will cause the
            % current dataset to be cleared.
            
            obj.Ptk.DeleteDatasets(series_uids)
            obj.Settings.RemoveLastPatientUid(series_uids);
        end
        
        function SwitchPatient(obj, patient_id)
            if ~strcmp(patient_id, obj.GuiDatasetState.CurrentPatientId)
                obj.ModeSwitcher.UpdateMode([], [], [], [], []);
                obj.Gui.SetTab(PTKSoftwareInfo.DefaultModeOnNewDataset);
                obj.Gui.ClearImages;
                obj.DeletePreviewListener;
                delete(obj.Dataset);
                obj.GuiDatasetState.SetPatientClearSeries(patient_id, []);                
            end
        end
        
        function InternalLoadImages(obj, image_info_or_uid)
            
            % Set this to empty in case an exception is thrown before it is
            % set
            series_uid = [];
            
            delete_image_info = false;
            patient_id = obj.GuiDatasetState.CurrentPatientId;
            patient_visible_name = obj.GuiDatasetState.CurrentPatientVisibleName;
            
            try
                if isa(image_info_or_uid, 'PTKImageInfo')
                    new_dataset = obj.Ptk.CreateDatasetFromInfo(image_info_or_uid);
                else
                    new_dataset = obj.Ptk.CreateDatasetFromUid(image_info_or_uid);
                end

                obj.ModeSwitcher.UpdateMode([], [], [], [], []);
                obj.Gui.SetTab(PTKSoftwareInfo.DefaultModeOnNewDataset);
                
                obj.Gui.ClearImages;
                delete(obj.Dataset);

                obj.Dataset = new_dataset;
                
                obj.ReplacePreviewListener(new_dataset);
                
                image_info = obj.Dataset.GetImageInfo;
                modality = image_info.Modality;
                
                [preferred_context, plugin_to_use] = obj.AppDef.GetPreferredContext(modality);
                
                % If the modality is not CT then we load the full dataset
                load_full_data = isempty(preferred_context);
                    
                % Attempt to obtain the region of interest
                if ~load_full_data
                    if obj.Dataset.IsContextEnabled(preferred_context)
                        try
                            new_image = obj.Dataset.GetResult(plugin_to_use);
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
                    new_image = obj.Dataset.GetResult('PTKOriginalImage', PTKContext.OriginalImage, [], true);
                end
                
                series_uid = image_info.ImageUid;
                if isfield(new_image.MetaHeader, 'PatientID')
                    patient_id = new_image.MetaHeader.PatientID;
                else
                    patient_id = series_uid;
                end

                % Update and save settings if anything has changed
                obj.Settings.SetLastImageInfo(image_info, obj.Reporting);
                obj.Settings.AddLastPatientUid(patient_id, series_uid);
                
                if isempty(image_info)
                    patient_visible_name = [];
                    series_name = [];
                else
                    series_info = obj.GetImageDatabase.GetSeries(image_info.ImageUid);
                    patient_info = obj.GetImageDatabase.GetPatient(series_info.PatientId);
                    patient_visible_name = patient_info.ShortVisibleName;
                    series_name = series_info.Name;
                end
                
                obj.GuiDatasetState.SetPatientAndSeries(patient_id, series_uid, patient_visible_name, series_name, modality);
                obj.GuiDatasetState.ClearPlugin;
                obj.UpdateModes;
                
                obj.Gui.UpdateGuiForNewDataset(obj.Dataset);
                
                % Set the image after updating the GuiState. This is necessary because setting
                % the image triggers a GUI resize, and the side panels need to be repopulated
                % first
                if load_full_data
                    obj.SetImage(new_image, PTKContext.OriginalImage);
                else
                    obj.SetImage(new_image, PTKContext.LungROI);
                end


                obj.Gui.LoadMarkersIfRequired;

                
            catch exc
                if PTKSoftwareInfo.IsErrorCancel(exc.identifier)
                    obj.Reporting.ShowProgress('Cancelling load');
                    obj.ClearDataset;
                    obj.Reporting.ShowMessage('PTKGuiDataset:LoadingCancelled', 'User cancelled loading');
                elseif PTKSoftwareInfo.IsErrorFileMissing(exc.identifier)
                    uiwait(errordlg('This dataset is missing. It will be removed from the patient browser.', [obj.AppDef.GetName ': Cannot find dataset'], 'modal'));
                    obj.Reporting.ShowMessage('PTKGuiDataset:FileNotFound', 'The original data is missing. I am removing this dataset.');
                    delete_image_info = true;
                elseif PTKSoftwareInfo.IsErrorUnknownFormat(exc.identifier)
                    uiwait(errordlg('This is not an image file or the format is not supported by PTK. It will be removed from the Patient Browser.', [obj.AppDef.GetName ': Cannot load this image'], 'modal'));
                    obj.Reporting.ShowMessage('PTKGuiDataset:FormatNotSupported', 'This file format is not supported by PTK. I am removing this dataset.');
                    delete_image_info = true;
                else
                    uiwait(errordlg(exc.message, [obj.AppDef.GetName ': Cannot load dataset'], 'modal'));
                    obj.Reporting.ShowMessage('PTKGuiDataset:LoadingFailed', ['Failed to load dataset due to error: ' exc.message]);
                end

                % We do this outside the catch block, in case it throws another exception
                if delete_image_info
                    try
                        % The series_uid may have been set before the
                        % exception was thrown, in which case we use this
                        % to specify which dataset to delete
                        if isempty(series_uid)
                            obj.DeleteThisImageInfo;
                        else
                            obj.DeleteImageInfo(series_uid);
                        end
                    catch exc
                        obj.Reporting.ShowMessage('PTKGuiDataset:DeleteImageInfoFailed', ['Failed to delete dataset due to error: ' exc.message]);
                    end
                end
                                
                obj.GuiDatasetState.SetPatientClearSeries(patient_id, patient_visible_name);
            end
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
                        uiwait(errordlg(['The plugin ' plugin_name ' failed with the following error: ' exc.message], [obj.AppDef.GetName ': Failure in plugin ' plugin_name], 'modal'));
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
        
        function LoadManualSegmentation(obj, segmentation_name, wait_dialog)
         % Causes the GUI to run the named segmentation and display the result
         
            if ~obj.DatasetIsLoaded
                return;
            end
            
            visible_name = segmentation_name;
            wait_dialog.ShowAndHold(['Loading segmentation ' visible_name]);

            % At present we only support top-level context
            context_to_request = PTKContext.OriginalImage;
            
            new_image = obj.Dataset.LoadManualSegmentation(segmentation_name, context_to_request, []);
            
            image_title = visible_name;
            image_title = ['MANUAL SEGMENTATION ', image_title];
            if isempty(new_image)
                obj.Reporting.Error('PTKGui:EmptyImage', ['The segmentation ' segmentation_name ' did not return an image when expected. ']);
            end
            obj.Gui.ReplaceOverlayImageCallback(new_image, image_title);
            obj.GuiDatasetState.SetSegmentation(segmentation_name);
            
            wait_dialog.Hide;
        end
    
        function OverlayImageChanged(obj)
            obj.ModeSwitcher.OverlayImageChanged;
        end
        
        function UpdateModeTabControl(obj)
            obj.Gui.UpdateModeTabControl(obj.GuiDatasetState.CurrentPluginInfo);
        end
        
        function SetNoDataset(obj)
            obj.GuiDatasetState.ClearPatientAndSeries;
            obj.GuiDatasetState.ClearPlugin;
            obj.UpdateModes;
        end
        
        function UpdateEditedStatus(obj, is_edited)
            obj.GuiDatasetState.UpdateEditStatus(is_edited);
        end
            
        function segmentation_list = GetListOfManualSegmentations(obj)
            if isempty(obj.Dataset)
                segmentation_list = PTKPair.empty;
            else
                segmentation_list = obj.Dataset.GetListOfManualSegmentations;
            end
        end
        
        function delete(obj)
            obj.DeletePreviewListener;
        end
    end
    
    methods (Access = private)

        function DeletePreviewListener(obj)
            CoreSystemUtilities.DeleteIfValidObject(obj.PreviewImageChangedListener);
            obj.PreviewImageChangedListener = [];
        end
        
        function ReplacePreviewListener(obj, new_dataset)
            obj.DeletePreviewListener;
            obj.PreviewImageChangedListener = addlistener(new_dataset, 'PreviewImageChanged', @obj.PreviewImageChanged);
        end
        
        function SeriesHasBeenDeleted(obj, series_uid, ~)
            % If the currently loaded dataset has been removed from the database, then clear
            % and delete
            if strcmp(series_uid, obj.GetUidOfCurrentDataset)
                obj.ClearDataset;
            end
        end
        
        function ModeHasChanged(obj, ~, mode)
            % Called when the mode changes
            obj.Gui.SetTabMode(mode.Data);
        end
        
        function RunPluginTryCatchBlock(obj, plugin_name, wait_dialog)
            new_plugin = PTKGuiDataset.LoadPluginInfoStructure(plugin_name, obj.Reporting);
            visible_name = CoreTextUtilities.RemoveHtml(new_plugin.ButtonText);
            wait_dialog.ShowAndHold(['Computing ' visible_name]);
            
            if strcmp(new_plugin.PluginType, 'DoNothing')
                obj.Dataset.GetResult(plugin_name);
            else
                
                % Determine the context we require (full image, lung ROI, etc).
                % Normally we keep the last context, but if a context plugin is
                % selected, we switch to the new context
                context_to_request = obj.CurrentContext;
                if strcmp(new_plugin.PluginType, 'ReplaceImage')
                    context_to_request = obj.ContextDef.ChooseOutputContext(new_plugin.Context);
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
    
    methods (Static)
        % Obtains a handle to the plugin which can be used to parse its properties
        function new_plugin = LoadPluginInfoStructure(plugin_name, reporting)
            plugin_handle = str2func(plugin_name);
            plugin_info_structure = feval(plugin_handle);
            
            % Parse the class properties into a data structure
            new_plugin = PTKParsePluginClass(plugin_name, plugin_info_structure, reporting); 
        end        
    end
end
