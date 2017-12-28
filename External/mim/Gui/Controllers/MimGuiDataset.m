classdef MimGuiDataset < CoreBaseClass
    % MimGuiDataset. Handles the interaction between the GUI and the MIM interfaces
    %
    %
    %     You do not need to modify this file. To add new functionality, create
    %     new plguins in the Plugins and GuiPlugins folders.
    % 
    %
    %     Licence
    %     -------
    %     Part of the TD MIM Toolkit. https://github.com/tomdoel
    %     Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %
    
    
    properties (SetAccess = private)
        CurrentContext
        GuiDatasetState
    end
    
    properties (Access = private)
        Dataset
        Gui
        ModeSwitcher
        MimMain
        Reporting
        Settings
        AppDef
        ContextDef
        ManualSegmentationsChangedListener
        MarkersChangedListener
        PreviewImageChangedListener
    end
    
    methods
        function obj = MimGuiDataset(app_def, gui, viewer_panel, settings, reporting)
            obj.AppDef = app_def;
            obj.ContextDef = app_def.GetContextDef;
            obj.GuiDatasetState = MimGuiDatasetState();
            obj.ModeSwitcher = MimModeSwitcher(viewer_panel, obj, app_def, settings, reporting);
            
            obj.Gui = gui;
            obj.Reporting = reporting;
            obj.Settings = settings;
            obj.MimMain = MimMain(app_def.GetFrameworkAppDef, reporting);
            obj.AddEventListener(obj.GetImageDatabase, 'SeriesHasBeenDeleted', @obj.SeriesHasBeenDeleted);
            obj.AddEventListener(obj.ModeSwitcher, 'ModeChangedEvent', @obj.ModeHasChanged);
        end

        function ChangeMode(obj, mode)
            obj.ModeSwitcher.SwitchMode(mode, obj.Dataset, obj.GuiDatasetState.CurrentPluginInfo, obj.GuiDatasetState.CurrentPluginName, obj.GuiDatasetState.CurrentVisiblePluginName, obj.CurrentContext, obj.GuiDatasetState.CurrentSegmentationName);
        end
        
        function ModeAutoSave(obj)
            obj.ModeSwitcher.ModeAutoSave();
        end
        
        function AutoSaveMarkers(obj)
            obj.Gui.AutoSaveMarkers();
        end

        function mode = GetMode(obj)
            mode = obj.ModeSwitcher.CurrentMode;
            if isempty(mode)
                obj.Reporting.Error('MimGuiDataset::NoMode', 'The operation is not possible in this mode');
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
            image_database = obj.MimMain.GetImageDatabase();
        end
        
        function linked_recorder = GetLinkedRecorder(obj)
            linked_recorder = obj.MimMain.FrameworkSingleton.GetLinkedDatasetRecorder();
        end
        
        function [uids, patient_ids] = ImportDataRecursive(obj, folder_path)
            [uids, patient_ids] = obj.MimMain.ImportDataRecursive(folder_path);
        end
        
        function [sorted_paths, sorted_uids] = GetListOfPaths(obj)
            [sorted_paths, sorted_uids] = obj.MimMain.ImageDatabase.GetListOfPaths();
        end
        
        function template_image = GetTemplateImage(obj)
            template_image = obj.Dataset.GetTemplateImage(PTKContext.OriginalImage);
        end
        
        function SaveMarkers(obj, name, markers)
            if obj.DatasetIsLoaded()
                obj.Dataset.SaveMarkerPoints(name, markers);
            end
        end
        
        function markers = LoadMarkers(obj, name)
            markers = obj.Dataset.LoadMarkerPoints(name);
        end
        
        function DeleteMarkerSet(obj, name)
            if obj.DatasetIsLoaded()
                obj.Dataset.DeleteMarkerSet(name);
            end
        end
        
        function SaveManualSegmentation(obj, name, segmentation)
            if obj.DatasetIsLoaded()
                obj.Dataset.SaveManualSegmentation(name, segmentation);
            end
        end
        
        function segmentation = LoadManualSegmentation(obj, segmentation_name)
            if obj.DatasetIsLoaded()
                segmentation = obj.Dataset.LoadManualSegmentation(segmentation_name, []);
            else
                segmentation = [];
            end
        end
        
        function DeleteManualSegmentation(obj, name)
            if obj.DatasetIsLoaded()
                obj.Dataset.DeleteManualSegmentation(name);
                if strcmp(name, obj.GuiDatasetState.CurrentSegmentationName)
                    obj.Gui.DeleteOverlays();
                end
            end
        end
        
        function dataset_cache_path = GetDatasetCachePath(obj)
            if obj.DatasetIsLoaded()
                dataset_cache_path = obj.Dataset.GetDatasetCachePath();
            else
                dataset_cache_path = obj.MimMain.GetDirectories.GetCacheDirectory();
            end
        end
        
        function dataset_cache_path = GetEditedResultsPath(obj)
            if obj.DatasetIsLoaded()
                dataset_cache_path = obj.Dataset.GetEditedResultsPath();
            else
                dataset_cache_path = obj.MimMain.GetDirectories.GetEditedResultsDirectoryAndCreateIfNecessary();
            end
        end

        function dataset_cache_path = GetOutputPath(obj)
            if obj.DatasetIsLoaded()
                dataset_cache_path = obj.Dataset.GetOutputPath();
            else
                dataset_cache_path = obj.MimMain.GetDirectories.GetOutputDirectoryAndCreateIfNecessary();
            end
        end
        
        function image_info = GetImageInfo(obj)
            if obj.DatasetIsLoaded()
                image_info = obj.Dataset.GetImageInfo();
            else
                image_info = [];
            end
        end
        
        function patint_name = GetPatientName(obj)
            if obj.DatasetIsLoaded()
                patint_name = obj.Dataset.GetPatientName();
            else
                patint_name = [];
            end
        end
        
        function ClearCacheForThisDataset(obj)
            if obj.DatasetIsLoaded()
                obj.Dataset.ClearCacheForThisDataset(false);
                obj.Gui.UpdateGuiForNewDataset([]);
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
                
                obj.SetNoDataset(false);
                obj.Gui.UpdateGuiForNewDataset([]);
                
            catch exc
                if MimErrors.IsErrorCancel(exc.identifier)
                    obj.Reporting.ShowMessage('MimGuiDataset:LoadingCancelled', 'User cancelled');
                else
                    obj.Reporting.ShowMessage('MimGuiDataset:ClearDatasetFailed', ['Failed to clear dataset due to error: ' exc.message]);
                end
            end
        end
        
        function ClearDatasetKeepPatient(obj)
            try
                obj.ModeSwitcher.UpdateMode([], [], [], [], []);
                obj.Gui.ClearImages;
                delete(obj.Dataset);

                obj.Dataset = [];
                
                obj.Settings.SetLastImageInfo([], obj.Reporting);
                
                obj.SetNoDataset(true);
                obj.Gui.UpdateGuiForNewDataset([]);
                
            catch exc
                if MimErrors.IsErrorCancel(exc.identifier)
                    obj.Reporting.ShowMessage('MimGuiDataset:LoadingCancelled', 'User cancelled');
                else
                    obj.Reporting.ShowMessage('MimGuiDataset:ClearDatasetFailed', ['Failed to clear dataset due to error: ' exc.message]);
                end
            end
        end
        
        
        function SaveEditedResult(obj)
            obj.ModeSwitcher.SaveEditedResult();
        end
        
        function DeleteThisImageInfo(obj)
            obj.DeleteDatasets(obj.GetUidOfCurrentDataset());
        end
        
        function DeleteImageInfo(obj, uid)
            obj.DeleteDatasets(uid);
        end
        
        function DeleteDatasets(obj, series_uids)
            % Removes a dataset from the database and deletes its disk cache. If the dataset
            % is currently loaded then the callback from the image database will cause the
            % current dataset to be cleared.
            
            obj.MimMain.DeleteDatasets(series_uids);
            obj.Settings.RemoveLastPatientUid(series_uids);
            if any(strcmp(series_uids, obj.GetUidOfCurrentDataset()))
                obj.ClearDataset();
            end
        end
        
        function SwitchPatient(obj, patient_id)
            if ~strcmp(patient_id, obj.GuiDatasetState.CurrentPatientId)
                obj.ModeSwitcher.UpdateMode([], [], [], [], []);
                obj.Gui.SetTab(obj.AppDef.DefaultModeOnNewDataset);
                obj.Gui.ClearImages;
                obj.DeleteListeners;
                delete(obj.Dataset);
                obj.Dataset = [];
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
                    series_uid = image_info_or_uid.ImageUid;
                    new_dataset = obj.MimMain.CreateDatasetFromInfo(image_info_or_uid);
                elseif ischar(image_info_or_uid)
                    series_uid = image_info_or_uid;
                    new_dataset = obj.MimMain.CreateDatasetFromUid(image_info_or_uid);
                else
                   new_dataset = [];
                end

                obj.ModeSwitcher.UpdateMode([], [], [], [], []);
                obj.Gui.SetTab(obj.AppDef.DefaultModeOnNewDataset);
                
                obj.Gui.ClearImages();
                delete(obj.Dataset);

                obj.Dataset = new_dataset;
                
                obj.ReplaceListeners(new_dataset);
                
                image_info = obj.Dataset.GetImageInfo();
                series_uid = image_info.ImageUid;
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
                            if MimErrors.IsErrorCancel(exc.identifier)
                                obj.Reporting.Log('LoadImages cancelled by user');
                                load_full_data = false;
                                rethrow(exc)
                            else
                                obj.Reporting.ShowMessage('MimGuiDataset:CannotGetROI', ['Unable to extract region of interest from this dataset. Error: ' exc.message]);
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
                
                % The modality may not have been set if it is not contained
                % in the file metadata, but may have been set after
                % loading, in which case we update it here
                if isempty(modality) && ~isempty(new_image.Modality)
                    modality = new_image.Modality;
                    image_info.Modality = new_image.Modality;
                end
                
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
                obj.Gui.SetTab(obj.AppDef.DefaultModeOnNewDataset);
                
                
                obj.Gui.UpdateGuiForNewDataset(obj.Dataset);
                
                % Set the image after updating the GuiState. This is necessary because setting
                % the image triggers a GUI resize, and the side panels need to be repopulated
                % first
                if load_full_data
                    obj.SetImage(new_image, PTKContext.OriginalImage);
                else
                    obj.SetImage(new_image, PTKContext.LungROI);
                end
                
                % Update toolbar again because setting the image will
                % change the visibility of some gui plugins
                obj.Gui.UpdateToolbar();

                obj.Gui.LoadDefaultMarkersIfRequiredWithoutProgressBar;

                
            catch exc
                if MimErrors.IsErrorCancel(exc.identifier)
                    obj.Reporting.ShowProgress('Cancelling load');
                    obj.ClearDataset;
                    obj.Reporting.ShowMessage('MimGuiDataset:LoadingCancelled', 'User cancelled loading');
                elseif MimErrors.IsErrorUidNotFound(exc.identifier)
                    uiwait(errordlg('This dataset is missing. It will be removed from the patient browser.', [obj.AppDef.GetName ': Cannot find dataset'], 'modal'));
                    obj.Reporting.ShowMessage('MimGuiDataset:FileNotFound', 'The original data is missing. I am removing this dataset.');
                    delete_image_info = true;
                elseif MimErrors.IsErrorFileMissing(exc.identifier)
                    uiwait(errordlg('This dataset is missing. It will be removed from the patient browser.', [obj.AppDef.GetName ': Cannot find dataset'], 'modal'));
                    obj.Reporting.ShowMessage('MimGuiDataset:FileNotFound', 'The original data is missing. I am removing this dataset.');
                    delete_image_info = true;
                elseif MimErrors.IsErrorUnknownFormat(exc.identifier)
                    uiwait(errordlg('This is not an image file or the format is not supported. It will be removed from the Patient Browser.', [obj.AppDef.GetName ': Cannot load this image'], 'modal'));
                    obj.Reporting.ShowMessage('MimGuiDataset:FormatNotSupported', 'This file format is not supported. I am removing this dataset.');
                    delete_image_info = true;
                else
                    uiwait(errordlg(exc.message, [obj.AppDef.GetName ': Cannot load dataset'], 'modal'));
                    obj.Reporting.ShowMessage('MimGuiDataset:LoadingFailed', ['Failed to load dataset due to error: ' exc.message]);
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
                        obj.Reporting.ShowMessage('MimGuiDataset:DeleteImageInfoFailed', ['Failed to delete dataset due to error: ' exc.message]);
                    end
                end
                obj.ClearDatasetKeepPatient;
            end
        end
        
        function result = RunPlugin(obj, plugin_name, context, wait_dialog)
            % Causes the GUI to run the named plugin and display the result
            
            if ~obj.DatasetIsLoaded()
                return;
            end
            
            try
                result = obj.RunPluginTryCatchBlock(plugin_name, context, wait_dialog);
            catch exc
                result = [];
                if MimErrors.IsErrorCancel(exc.identifier)
                    obj.Reporting.ShowMessage('MimGuiDataset:LoadingCancelled', ['The cancel button was clicked while the plugin ' plugin_name ' was running.']);
                else
                    obj.Reporting.ShowMessage('MimGuiDataset:PluginFailed', ['The plugin ' plugin_name ' failed with the following error: ' exc.message]);
                    show_error_dialog = true;

                    if isa(exc, 'MimSuggestEditException')
                        default_edited_result = obj.Dataset.GetDefaultEditedResult(exc.PluginToEdit, exc.PluginContext);
                        if ~isempty(default_edited_result)
                            show_error_dialog = false;

                            choice = questdlg(['Segmentation for ' exc.PluginVisibleName ' could not be performed automatically because the algorithm was not able to process this dataset. Do you wish to create the segmentation manually using the editing tools? If you are unsure, click Cancel.'], ...
                                ['Segmentation failed for ' exc.PluginVisibleName '.'], ...
                                'Create segmentation manually', 'Cancel', 'Cancel');
                            switch choice
                                case 'Create segmentation manually'
                                    % Save the new edit
                                    obj.Dataset.SaveEditedResult(exc.PluginToEdit, default_edited_result, exc.PluginContext);

                                    % Run the plugin to load the edit
                                    % into the viewer
                                    obj.RunPluginTryCatchBlock(exc.PluginToEdit, context, wait_dialog);
                                    
                                    % Switch to edit mode
                                    obj.Gui.ChangeMode(MimModes.EditMode);
                                    
                                    uiwait(warndlg(['The segmentation created for ' exc.PluginVisibleName ' is incomplete. Please review and corect the segmentation before performing any analysis.'], ['Review and correct  ' exc.PluginVisibleName], 'modal'));                        
                            end
                        end

                    end

                    if show_error_dialog
                        uiwait(errordlg(['The plugin ' plugin_name ' failed with the following error: ' exc.message], [obj.AppDef.GetName ': Failure in plugin ' plugin_name], 'modal'));
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

        function LoadManualSegmentationCallback(obj, segmentation_name)
            obj.Gui.LoadSegmentationCallback(segmentation_name);
        end
        
        function LoadAndDisplayManualSegmentation(obj, segmentation_name, wait_dialog)
            % Causes the GUI to run the named segmentation and display the result
         
            if ~obj.DatasetIsLoaded()
                return;
            end
            
            visible_name = segmentation_name;
            wait_dialog.ShowAndHold(['Loading segmentation ' visible_name]);

            new_image = obj.LoadManualSegmentation(segmentation_name);
            
            image_title = visible_name;
            image_title = ['MANUAL SEGMENTATION ', image_title];
            if isempty(new_image)
                obj.Reporting.Error('MimGuiDataset:EmptyImage', ['The segmentation ' segmentation_name ' did not return an image when expected. ']);
            end
            obj.Gui.ReplaceOverlayImageCallback(new_image, image_title);
            % We need to reset the image changed callback because we have
            % deliberately changed the image, and otherwise UpdateModes()
            % will trigger a prompt to the user to save changes
            obj.ModeSwitcher.MarkOverlayAsUnchanged();
            obj.GuiDatasetState.SetSegmentation(segmentation_name);
            obj.UpdateModes();
            
            wait_dialog.Hide;
        end
    
        function OverlayImageChanged(obj)
            obj.ModeSwitcher.OverlayImageChanged;
        end
        
        function UpdateModeTabControl(obj)
            obj.Gui.UpdateModeTabControl(obj.GuiDatasetState);
        end
        
        function SetNoDataset(obj, keep_patient)
            if keep_patient
                obj.GuiDatasetState.ClearSeries();
            else
                obj.GuiDatasetState.ClearPatientAndSeries();
            end
            obj.GuiDatasetState.ClearPlugin();
            obj.UpdateModes();
            obj.Gui.UpdateGuiForNewDataset([]);
        end
        
        function UpdateEditedStatus(obj, is_edited)
            obj.GuiDatasetState.UpdateEditStatus(is_edited);
        end

        function segmentation_list = GetListOfManualSegmentations(obj)
            if isempty(obj.Dataset)
                segmentation_list = CorePair.empty;
            else
                segmentation_list = obj.Dataset.GetListOfManualSegmentations();
            end
        end

        function context_list = GetAllContextsForManualSegmentations(obj)
            if isempty(obj.Dataset)
                context_list = {};
            else
                context_list = obj.Dataset.GetAllContextsForManualSegmentations();
            end
        end
        
        function segmentation_list = GetListOfMarkerSets(obj)
            if isempty(obj.Dataset)
                segmentation_list = CorePair.empty();
            else
                segmentation_list = obj.Dataset.GetListOfMarkerSets();
            end
        end

        function delete(obj)
            obj.DeleteListeners();
        end
        
        function plugin_cache = GetPluginCache(obj)
            plugin_cache = obj.MimMain.FrameworkSingleton.GetPluginInfoMemoryCache();
        end
        
        function preview_image = FetchPreview(obj, plugin_name)
            if isempty(obj.Dataset)
                preview_image = [];
            else
                preview_image = obj.Dataset.GetPluginPreview(plugin_name);
            end
        end
        
       function is_linked_dataset = IsLinkedDataset(obj, linked_name_or_uid)
            % Returns true if another dataset has been linked to this one, using
            % the name or uid specified
            
            if isempty(obj.Dataset)
                is_linked_dataset = false;
            else
                is_linked_dataset = obj.Dataset.IsLinkedDataset(linked_name_or_uid);
            end
       end
        
        function is_gas_mri = IsGasMRI(obj)
            % Check if this is a hyperpolarised gas MRI image
            
            if isempty(obj.Dataset)
                is_gas_mri = false;
            else
                is_gas_mri = obj.Dataset.IsGasMRI();
            end
        end
        
        function SaveTableAsCSV(obj, plugin_name, subfolder_name, file_name, description, table, file_dim, row_dim, col_dim, filters)
            if isempty(obj.Dataset)
                obj.Reporting.Error('MimGuiDataset:NoDatasetLoaded', ['Could not save analysis results because no dataset is currently loaded.']);
            else
                obj.Dataset.SaveTableAsCSV(plugin_name, subfolder_name, file_name, description, table, file_dim, row_dim, col_dim, filters);
            end
        end
    end
    
    methods (Access = private)

        function DeleteListeners(obj)
            CoreSystemUtilities.DeleteIfValidObject(obj.PreviewImageChangedListener);
            CoreSystemUtilities.DeleteIfValidObject(obj.MarkersChangedListener);
            CoreSystemUtilities.DeleteIfValidObject(obj.ManualSegmentationsChangedListener);
            obj.PreviewImageChangedListener = [];
        end
        
        function ReplaceListeners(obj, new_dataset)
            obj.DeleteListeners();
            if ~isempty(new_dataset)
                obj.PreviewImageChangedListener = addlistener(new_dataset, 'PreviewImageChanged', @obj.PreviewImageChangedCallback);
                obj.MarkersChangedListener = addlistener(new_dataset, 'MarkersChanged', @obj.MarkersChangedCallback);
                obj.ManualSegmentationsChangedListener = addlistener(new_dataset, 'ManualSegmentationsChanged', @obj.ManualSegmentationsChangedCallback);
            end
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
        
        function result = RunPluginTryCatchBlock(obj, plugin_name, context_to_request, wait_dialog)
            new_plugin = obj.LoadPluginInfoStructure(plugin_name, obj.Reporting);
            visible_name = CoreTextUtilities.RemoveHtml(new_plugin.ButtonText);
            wait_dialog.ShowAndHold(['Computing ' visible_name]);
            
            if strcmp(new_plugin.PluginType, 'DoNothing')
                % Call with 2 output arguments to prevent fetching of cache
                % info
                [result, ~] = obj.Dataset.GetResultWithCacheInfo(plugin_name, context_to_request);
            else
                
                % Determine the context we require (full image, lung ROI,
                % etc) if not specified by the caller
                % Normally we keep the last context, but if a context plugin is
                % selected, we switch to the new context
                if isempty(context_to_request)
                    context_to_request = obj.CurrentContext;
                end
                if strcmp(new_plugin.PluginType, 'ReplaceImage')
                    context_to_request = obj.ContextDef.ChooseOutputContext(new_plugin.Context);
                end
                
                [result, cache_info, new_image] = obj.Dataset.GetResultWithCacheInfo(plugin_name, context_to_request);
                
                if isa(cache_info, 'MimCompositeResult')
                    cache_info = cache_info.GetFirstResult;
                end
                
                image_title = visible_name;
                if cache_info.IsEdited
                    image_title = ['EDITED ', image_title];
                end
                if strcmp(new_plugin.PluginType, 'ReplaceOverlay')                    
                    if isempty(new_image)
                        obj.Reporting.Error('MimGuiDataset:EmptyImage', ['The plugin ' plugin_name ' did not return an image when expected. If this plugin should not return an image, then set its PluginType property to "DoNothing"']);
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
        
        function PreviewImageChangedCallback(obj, ~, event_data)
            notify(obj.GuiDatasetState, 'PreviewImageChanged', CoreEventData(event_data.Data));
        end
        
        function ManualSegmentationsChangedCallback(obj, ~, event_data)
            notify(obj.GuiDatasetState, 'ManualSegmentationsChanged', CoreEventData(event_data.Data));
        end
        
        function MarkersChangedCallback(obj, ~, event_data)
            notify(obj.GuiDatasetState, 'MarkersChanged', CoreEventData(event_data.Data));
        end
        
        function SetImage(obj, new_image, context)
            obj.CurrentContext = context;
            obj.Gui.SetImage(new_image);
        end
        
       
        function UpdateModes(obj)
            obj.ModeSwitcher.UpdateMode(obj.Dataset, obj.GuiDatasetState.CurrentPluginInfo, obj.GuiDatasetState.CurrentPluginName, obj.GuiDatasetState.CurrentVisiblePluginName, obj.CurrentContext);
            obj.Gui.UpdateModeTabControl(obj.GuiDatasetState);
            obj.Gui.UpdateToolbar;
        end
        
        function new_plugin = LoadPluginInfoStructure(obj, plugin_name, reporting)
            % Obtains a handle to the plugin which can be used to parse its properties
            new_plugin = obj.GetPluginCache.GetPluginInfo(plugin_name, [], reporting);
        end        
    end
end
