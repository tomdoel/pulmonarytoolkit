classdef MimDatasetResults < handle
    % MimDatasetResults. 
    %
    %     This class is used to run calculations and fetch cached
    %     results associated with a dataset. The difference between MimDataset 
    %     and MimDatasetResults is that MimDataset is called from outside the 
    %     toolkit, whereas MimDatasetResults is called by plugins during their 
    %     RunPlugin() call. MimDataset calls MimDatasetResults, but provides 
    %     additional progress and error reporting and dependency tracking.
    %
    %     You should not create this class directly. An instance of this class
    %     is given to plugins during their RunPlugin() function call.
    %
    %     Example: 
    %
    %     classdef MyPlugin < MimPlugin
    %
    %     methods (Static)
    %         function results = RunPlugin(dataset_results, reporting)
    %             ...
    %             airway_results = dataset_results.GetResult('PTKAirways');
    %             ...
    %         end
    %     end
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %

    

    properties (Access = private)
        
        FrameworkAppDef      % Framework configuration
        ContextHierarchy     % Processes the calls to plugins, performing conversions between contexts where necessary
        DatasetDiskCache     % Reads and writes to the disk cache for this dataset
        DependencyTracker    % Tracks plugin usage to construct dependency lists 
        ImageTemplates       % Template images for different contexts
        OutputFolder         % Saves files to the output folder
        Reporting            % Object for error and progress reporting
        PreviewImages        % Stores the thumbnail preview images
        ImageInfo            % Information about this dataset
        LinkedDatasetChooser % Used to process GetResult() requests during callbacks
        
        % A pointer to the object which contains the event to be triggered when a preview thumbnail image has changed
        ExternalWrapperNotifyFunction
        
    end
    
    methods
        function obj = MimDatasetResults(framework_app_def, context_def, image_info, linked_dataset_chooser, external_notify_function, dataset_disk_cache, plugin_cache, reporting)
            obj.FrameworkAppDef = framework_app_def;
            obj.ImageInfo = image_info;
            obj.LinkedDatasetChooser = linked_dataset_chooser;
            obj.DatasetDiskCache = dataset_disk_cache;
            obj.ExternalWrapperNotifyFunction = external_notify_function;
            obj.ImageTemplates = MimImageTemplates(framework_app_def, obj, context_def, dataset_disk_cache, reporting);
            obj.OutputFolder = MimOutputFolder(framework_app_def, dataset_disk_cache, image_info, obj.ImageTemplates, reporting);
            obj.PreviewImages = MimPreviewImages(framework_app_def, dataset_disk_cache, reporting);
            obj.DependencyTracker = MimPluginDependencyTracker(framework_app_def, dataset_disk_cache, plugin_cache);
            obj.ContextHierarchy = MimContextHierarchy(context_def, obj.DependencyTracker, obj.ImageTemplates);
        end

        function [result, cache_info, output_image] = GetResult(obj, plugin_name, dataset_stack, context, reporting, allow_results_to_be_cached_override)
            % Returns the results of a plugin. If a valid result is cached on disk,
            % this wil be returned provided all the dependencies are valid.
            % Otherwise the plugin will be executed and the new result returned.
            % The optional context parameter specifies the region of interest to which the output result will be framed.
            % Specifying a second argument also produces a representative image from
            % the results. For plugins whose result is an image, this will generally be the
            % same as the results.

            reporting.PushProgress;
            if nargin < 4
                context = [];
            end
            generate_results = nargout > 2;
            
            % Get information about the plugin
            plugin_class = feval(plugin_name);
            plugin_info = MimParsePluginClass(plugin_name, plugin_class, [], reporting);
            
            % Whether results can be cached is determined by the plugin
            % parameters, but the input can force this to be enabled
            if nargin < 6 || isempty(allow_results_to_be_cached_override)
                allow_results_to_be_cached = plugin_info.AllowResultsToBeCached;
            else
                allow_results_to_be_cached = allow_results_to_be_cached_override || plugin_info.AllowResultsToBeCached;
            end
            
            % Update the progress dialog with the current plugin being run
            reporting.UpdateProgressMessage(['Computing ' plugin_info.ButtonText]);
            
            % Run the plugin
            [result, cache_info, output_image, plugin_has_been_run] = obj.RunPluginWithOptionalImageGeneration(plugin_name, plugin_info, plugin_class, generate_results, dataset_stack, context, allow_results_to_be_cached, reporting);
            
            % Open any output folders which have been written to by the plugin
            obj.OutputFolder.OpenChangedFolders(reporting);
            
            reporting.CompleteProgress;
            
            reporting.PopProgress;
        end

        function image_info = GetImageInfo(obj, reporting)
            % Returns a MimImageInfo structure with image information, including the
            % UID, filenames and file path
        
            image_info = obj.ImageInfo;
        end
        
        function patient_name = GetPatientName(obj, dataset_stack, reporting)
            % Returns a single string for identifying the patient. The format will depend on what information is available in the file metadata.
            
            template = obj.GetTemplateImage(PTKContext.OriginalImage, dataset_stack, reporting);
            patient_name = '';

            if isfield(template.MetaHeader, 'PatientName')
                if isfield(template.MetaHeader.PatientName, 'FamilyName')
                    patient_name = template.MetaHeader.PatientName.FamilyName;
                else
                    patient_name = template.MetaHeader.PatientName;
                end
                if isempty(patient_name) && isfield(template.MetaHeader.PatientName, 'PatientID')
                    patient_name = template.MetaHeader.PatientName.PatientID;
                end
            end
            if isempty(patient_name)
                image_info = obj.GetImageInfo(reporting);
                patient_name = image_info.ImageUid;
            end
            
        end
        
        function SaveData(obj, name, data, reporting)
            % Save data as a cache file associated with this dataset
        
            obj.DatasetDiskCache.SaveData(name, data, reporting);
        end
        
        function data = LoadData(obj, name, reporting)
            % Load data from a cache file associated with this dataset
        
            data = obj.DatasetDiskCache.LoadData(name, reporting);
        end
        
        function SaveMarkerPoints(obj, name, data, reporting)
            % Save marker points as a cache file associated with this dataset
        
            obj.DatasetDiskCache.SaveMarkerPoints(name, data, reporting);
        end
        
        function data = LoadMarkerPoints(obj, name, reporting)
            % Load data from a cache file associated with this dataset
        
            data = obj.DatasetDiskCache.LoadMarkerPoints(name, reporting);
        end
        
        function SaveManualSegmentation(obj, name, data, context, reporting)
            % Save manual segmentation as a cache file associated with this dataset
        
            obj.DatasetDiskCache.SaveManualSegmentation(name, data, context, reporting);
        end
        
        function data = LoadManualSegmentation(obj, name, context, reporting)
            % Load data from a cache file associated with this dataset
        
            data = obj.DatasetDiskCache.LoadManualSegmentation(name, context, reporting);
        end
        
        function DeleteEditedPluginResult(obj, plugin_name, reporting)
            % Delete edit data from a cache file associated with this dataset
            
            obj.DatasetDiskCache.DeleteEditedPluginResult(plugin_name, reporting);
        end
        
        function DeleteManualSegmentation(obj, segmentation_name, reporting)
            % Delete manual segmentation from a cache file associated with this dataset
            
            obj.DatasetDiskCache.DeleteManualSegmentation(segmentation_name, reporting);
        end
        
        function file_list = GetListOfManualSegmentations(obj)
            % Gets list of manual segmentation files associated with this dataset

            file_list = obj.DatasetDiskCache.GetListOfManualSegmentations;
        end
        
        function SaveEditedPluginResult(obj, plugin_name, input_context, edited_result_image, dataset_stack, reporting)
            % Save edit data to a cache file associated with this dataset
            
            dataset_uid = obj.ImageInfo.ImageUid;
            reporting.PushProgress;
            if nargin < 3
                input_context = [];
            end
            
            % Get information about the plugin
            plugin_class = feval(plugin_name);
            plugin_info = MimParsePluginClass(plugin_name, plugin_class, [], reporting);
            
            % Update the progress dialog with the current plugin being run
            reporting.UpdateProgressMessage(['Saving edit for ' plugin_info.ButtonText]);
            
            
            % In debug mode we don't try to catch exceptions so that the
            % debugger will stop at the right place
            if obj.FrameworkAppDef.IsDebugMode
                obj.ContextHierarchy.SaveEditedResult(plugin_name, input_context, edited_result_image, plugin_info, dataset_stack, dataset_uid, reporting);
            else
                try
                    obj.ContextHierarchy.SaveEditedResult(plugin_name, input_context, edited_result_image, plugin_info, dataset_stack, dataset_uid, reporting);
                catch ex
                    dataset_stack.ClearStack;
                    rethrow(ex);
                end
            end

            reporting.CompleteProgress;
            reporting.PopProgress;
        end
        
        function dataset_cache_path = GetDatasetCachePath(obj, reporting)
            % Gets the path of the folder where the results for this dataset are
            % stored
        
            dataset_cache_path = obj.DatasetDiskCache.GetCachePath(reporting);
        end
        
        function cache_path = GetEditedResultsPath(obj, reporting)
            % Gets the path of the folder where the edited results for this dataset are stored
            
           cache_path = obj.DatasetDiskCache.GetEditedResultsPath(reporting);
        end
        
        function output_path = GetOutputPathAndCreateIfNecessary(obj, dataset_stack, reporting)
            % Gets the path of the folder where the output files for this dataset are
            % stored
        
            output_path = obj.OutputFolder.GetOutputPath(dataset_stack, reporting);
            if ~exist(output_path, 'dir')
                mkdir(output_path);
            end      
        end        
        
        function template_image = GetTemplateImage(obj, context, dataset_stack, reporting)
            % Returns an empty template image for the specified context
            % Valid contexts are specified via the AppDef file
        
            template_image = obj.ImageTemplates.GetTemplateImage(context, dataset_stack, reporting);
        end
        
        function template_image = GetTemplateMask(obj, context, dataset_stack, reporting)
            % Returns a template image mask for the specified context
            % Valid contexts are specified via the AppDef file
        
            template_image = obj.ImageTemplates.GetTemplateMask(context, dataset_stack, reporting);
        end
        
        function preview = GetPluginPreview(obj, plugin_name, reporting)
            % Gets a thumbnail image of the last result for this plugin
        
            preview = obj.PreviewImages.GetPreview(plugin_name, reporting);
        end

        function ClearCacheForThisDataset(obj, remove_framework_files, reporting)
            % Removes all the cache files associated with this dataset. Cache files
            % store the results of plugins so they need only be computed once for
            % each dataset. Clearing the cache files forces recomputation of all
            % results.
        
            obj.PreviewImages.Clear(reporting);
            obj.ImageTemplates.ClearCache(reporting);
            obj.DatasetDiskCache.RemoveAllCachedFiles(remove_framework_files, reporting);
        end
        
        function DeleteCacheForThisDataset(obj, reporting)
            % Removes all the cache files associated with this dataset. Cache files
            % store the results of plugins so they need only be computed once for
            % each dataset. Clearing the cache files forces recomputation of all
            % results.
        
            obj.PreviewImages.Clear(reporting);
            obj.DatasetDiskCache.Delete(reporting);
        end
        
        function context_is_enabled = IsContextEnabled(obj, context, reporting)
            % Check to see if a context has been disabled for this dataset, due to a
            % failure when running the plugin that generates the template image for
            % that context.
            context_is_enabled = obj.ImageTemplates.IsContextEnabled(context, reporting);
        end
        
        % ToDo: This check is based on series description and should be more
        % general
        function is_gas_mri = IsGasMRI(obj, dataset_stack, reporting)
            is_gas_mri = false;
            if ~strcmp(obj.GetImageInfo.Modality, 'MR')
                return;
            else
                template = obj.GetTemplateImage(PTKContext.OriginalImage, dataset_stack, reporting);
                if ~isfield(template.MetaHeader, 'ReceiveCoilName')
                    return;
                end
                if strcmpi(template.MetaHeader.ReceiveCoilName, 'MNS 129Xe TR')
                    is_gas_mri = true;
                end
            end
        end

        function [valid, edited_result_exists] = CheckDependencyValid(obj, next_dependency, reporting)
            [valid, edited_result_exists] = obj.DependencyTracker.CheckDependencyValid(next_dependency, reporting);
        end

        function SaveTableAsCSV(obj, plugin_name, subfolder_name, file_name, description, table, file_dim, row_dim, col_dim, filters, dataset_stack, reporting)
            obj.OutputFolder.SaveTableAsCSV(plugin_name, subfolder_name, file_name, description, table, file_dim, row_dim, col_dim, filters, dataset_stack, reporting);
        end
        
        function SaveFigure(obj, figure_handle, plugin_name, subfolder_name, file_name, description, dataset_stack, reporting)
            obj.OutputFolder.SaveFigure(figure_handle, plugin_name, subfolder_name, file_name, description, dataset_stack, reporting);
        end

        function SaveSurfaceMesh(obj, plugin_name, subfolder_name, file_name, description, segmentation, smoothing_size, small_structures, coordinate_system, template_image, dataset_stack, reporting)
            obj.OutputFolder.SaveSurfaceMesh(plugin_name, subfolder_name, file_name, description, segmentation, smoothing_size, small_structures, coordinate_system, template_image, dataset_stack, reporting)
        end

        function RecordNewFileAdded(obj, plugin_name, file_path, file_name, description, reporting)
            obj.OutputFolder.RecordNewFileAdded(plugin_name, file_path, file_name, description, reporting)
        end
    end

    methods (Access = private)
                
        function [result, cache_info, output_image, plugin_has_been_run] = RunPluginWithOptionalImageGeneration(obj, plugin_name, plugin_info, plugin_class, generate_image, dataset_stack, context, allow_results_to_be_cached, reporting)
            % Returns the plugin result, computing if necessary
            
            preview_exists = obj.PreviewImages.DoesPreviewExist(plugin_name);
            
            % We don't save the preview image if the plugin result was loaded
            % from the cache, unless there is no existing preview image
            
            force_generate_preview = (plugin_info.GeneratePreview && ~preview_exists);
            
            force_generate_image = generate_image || force_generate_preview;

            % Run the plugin for each required context and assemble result
            [result, output_image, plugin_has_been_run, cache_info] = obj.ComputeResultForAllContexts(plugin_name, context, plugin_info, plugin_class, dataset_stack, force_generate_image, allow_results_to_be_cached, reporting);

            cache_preview = plugin_info.GeneratePreview && (plugin_has_been_run || ~preview_exists);
            
            % Generate and cache a preview image
            if cache_preview && ~isempty(output_image) && output_image.ImageExists
                preview_size = [50, 50];
                output_image.GeneratePreview(preview_size, plugin_info.FlattenPreviewImage);
                obj.PreviewImages.AddPreview(plugin_name, output_image.Preview, reporting);
                
                % Fire an event indictaing the preview image has changed. This
                % will allow any listening gui to update its preview images if
                % necessary
                obj.ExternalWrapperNotifyFunction('PreviewImageChanged', CoreEventData(plugin_name));
            end
        end
        
        function [result, output_image, plugin_has_been_run, cache_info] = ComputeResultForAllContexts(obj, plugin_name, context, plugin_info, plugin_class, dataset_stack, force_generate_image, allow_results_to_be_cached, reporting)
            dataset_uid = obj.ImageInfo.ImageUid;
            
            % If non-debug mode 
            % In debug mode we don't try to catch exceptions so that the
            % debugger will stop at the right place
            if obj.FrameworkAppDef.IsDebugMode
                [result, output_image, plugin_has_been_run, cache_info] = obj.ContextHierarchy.GetResult(plugin_name, context, obj.LinkedDatasetChooser, plugin_info, plugin_class, dataset_uid, dataset_stack, force_generate_image, allow_results_to_be_cached, reporting);
            else
                try
                    [result, output_image, plugin_has_been_run, cache_info] = obj.ContextHierarchy.GetResult(plugin_name, context, obj.LinkedDatasetChooser, plugin_info, plugin_class, dataset_uid, dataset_stack, force_generate_image, allow_results_to_be_cached, reporting);
                catch ex
                    dataset_stack.ClearStack;
                    rethrow(ex);
                end
            end
        end
    end
end
