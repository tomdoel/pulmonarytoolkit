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
    %             results = dataset_results.GetResult('PluginName');
    %             ...
    %         end
    %     end
    %
    %
    %     Licence
    %     -------
    %     Part of the TD MIM Toolkit. https://github.com/tomdoel
    %     Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %

    

    properties (Access = private)
        
        FrameworkAppDef      % Framework configuration
        ContextHierarchy     % Processes the calls to plugins, performing conversions between contexts where necessary
        DatasetDiskCache     % Reads and writes to the disk cache for this dataset
        DependencyTracker    % Tracks plugin usage to construct dependency lists 
        Pipelines            % Pipelines which trigger Plugins after other Plugins are called
        ImageTemplates       % Template images for different contexts
        OutputFolder         % Saves files to the output folder
        Reporting            % Object for error and progress reporting
        PreviewImages        % Stores the thumbnail preview images
        ImageInfo            % Information about this dataset
        LinkedDatasetChooser % Used to process GetResult() requests during callbacks
        
        % A pointer to the object which contains the event to be triggered when a preview thumbnail image has changed
        ExternalNotifyCallback
        
    end
    
    methods
        function obj = MimDatasetResults(framework_app_def, context_def, image_info, linked_dataset_chooser, notify_callback, dataset_disk_cache, plugin_cache, reporting)
            obj.FrameworkAppDef = framework_app_def;
            obj.ImageInfo = image_info;
            obj.LinkedDatasetChooser = linked_dataset_chooser;
            obj.DatasetDiskCache = dataset_disk_cache;
            obj.ExternalNotifyCallback = notify_callback;
            obj.Pipelines = MimPipelines(obj);
            obj.ImageTemplates = MimImageTemplates(framework_app_def, obj, context_def, dataset_disk_cache, obj.Pipelines, reporting);
            obj.OutputFolder = MimOutputFolder(framework_app_def, dataset_disk_cache, image_info, obj.ImageTemplates, reporting);
            obj.PreviewImages = MimPreviewImages(framework_app_def, dataset_disk_cache, reporting);
            obj.DependencyTracker = MimPluginDependencyTracker(framework_app_def, dataset_disk_cache, plugin_cache);
            obj.ContextHierarchy = MimContextHierarchy(context_def, dataset_disk_cache, obj.DependencyTracker, obj.ImageTemplates, obj.Pipelines);
        end

        function parameter = GetParameter(obj, parameter_name, dataset_stack, reporting)
            % ToDo
            reporting.Error('MimDatasetResults:NotImplemented', 'Not implemented');
        end
        
        function [result, cache_info, output_image] = GetResult(obj, plugin_name, dataset_stack, output_context, parameters, reporting, allow_results_to_be_cached_override)
            % Returns the results of a plugin. If a valid result is cached on disk,
            % this wil be returned provided all the dependencies are valid.
            % Otherwise the plugin will be executed and the new result returned.
            % The optional context parameter specifies the region of interest to which the output result will be framed.
            % Specifying a second argument also produces a representative image from
            % the results. For plugins whose result is an image, this will generally be the
            % same as the results.

            reporting.PushProgress;
            if nargin < 4
                output_context = [];
            end
            generate_image = nargout > 2;
            
            % Get information about the plugin
            plugin_class = feval(plugin_name);
            plugin_info = MimParsePluginClass(plugin_name, plugin_class, [], reporting);
            
            memory_cache_policy = plugin_info.MemoryCachePolicy;
            disk_cache_policy = plugin_info.DiskCachePolicy;

            % Whether results can be cached is determined by the plugin
            % parameters, but the input can force this to be enabled
            if (nargin > 5) && (~isempty(allow_results_to_be_cached_override)) && allow_results_to_be_cached_override
                disk_cache_policy = MimCachePolicy.Permanent;
            end

            % Update the progress dialog with the current plugin being run
            reporting.UpdateProgressMessage(['Computing ' plugin_info.ButtonText]);
            
            preview_exists = obj.PreviewImages.DoesPreviewExist(plugin_name);
            
            % We don't save the preview image if the plugin result was loaded
            % from the cache, unless there is no existing preview image
            force_generate_preview = (plugin_info.GeneratePreview && ~preview_exists);
            
            force_generate_image = generate_image || force_generate_preview;

            % Run the plugin for each required context and assemble result
            dataset_uid = obj.ImageInfo.ImageUid;
            try
                context_list = obj.ContextHierarchy.GetContextList(output_context, plugin_info, reporting);
                plugin_has_been_run = false;
                result = [];
                output_image = [];
                cache_info = [];

                for next_output_context_set = context_list
                    next_output_context = next_output_context_set{1};
                    combined_result = obj.ContextHierarchy.GetResultRecursive(plugin_name, next_output_context, parameters, obj.LinkedDatasetChooser, plugin_info, plugin_class, dataset_uid, dataset_stack, force_generate_image, memory_cache_policy, disk_cache_policy, reporting);
                    plugin_has_been_run = plugin_has_been_run | combined_result.GetPluginHasBeenRun;
                    if numel(context_list) == 1
                        result = combined_result.GetResult();
                    else
                        result.(strrep(char(next_output_context), '.', '_')) = combined_result.GetResult();
                    end

                    % Note for simplicity we return only one output image and
                    % one cache info even if we are requesting multiple
                    % results. This is because these outputs are really
                    % additional aids and we save the caller the responsibility
                    % of having to deal with a compound output. But there is an
                    % argument for packing all the results consistently - we
                    % would need to ensure this is correctly dealt with by the
                    % caller
                    if isempty(output_image)
                        output_image = combined_result.GetOutputImage;
                    end
                    if isempty(cache_info)
                        cache_info = combined_result.GetCacheInfo;
                    end
                end

            catch ex
                dataset_stack.ClearStack;
                rethrow(ex);
            end

            cache_preview = plugin_info.GeneratePreview && (plugin_has_been_run || ~preview_exists);
            
            % Generate and cache a preview image
            if cache_preview && ~isempty(output_image) && output_image.ImageExists
                preview_size = [50, 50];
                output_image.GeneratePreview(preview_size, plugin_info.FlattenPreviewImage);
                obj.PreviewImages.AddPreview(plugin_name, output_image.Preview, reporting);
                
                % Fire an event indictaing the preview image has changed. This
                % will allow any listening gui to update its preview images if
                % necessary
                obj.ExternalNotifyCallback.NotifyPreviewImageChanged(plugin_name);
            end
            
            % Open any output folders which have been written to by the plugin
            obj.OutputFolder.OpenChangedFolders(reporting);
            
            reporting.CompleteProgress;
            
            reporting.PopProgress;
        end
        
        function result_exists = ResultExistsForSpecificContext(obj, plugin_name, context, reporting)
            % Returns true if a result exists for this SPECIFIC context,
            % either in memory or on disk
            
            result_exists = obj.DatasetDiskCache.Exists(plugin_name, context, reporting);
        end

        function result_exists = ManualSegmentationExists(obj, name, reporting)
            % Returns true if a manual segmentation results exists with this name
            
            result_exists = obj.DatasetDiskCache.ManualSegmentationExists(name, reporting);
        end

        function image_info = GetImageInfo(obj, reporting)
            % Returns a PTKImageInfo structure with image information, including the
            % UID, filenames and file path
        
            image_info = obj.ImageInfo;
        end
        
        function patient_name = GetPatientName(obj, dataset_stack, reporting)
            % Returns a single string for identifying the patient. The format will depend on what information is available in the file metadata.
            
            template = obj.GetTemplateImage(obj.FrameworkAppDef.GetContextDef.GetOriginalDataContext, dataset_stack, reporting);
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
        
        function SaveMarkerPoints(obj, name, data, dataset_stack, reporting)
            % Save marker points as a cache file associated with this dataset
            
            dataset_uid = obj.ImageInfo.ImageUid;
            
            try
                obj.DependencyTracker.SaveMarkerPoints(name, data, dataset_uid, reporting);            
            catch ex
                dataset_stack.ClearStack;
                rethrow(ex);
            end
        end
        
        function data = LoadMarkerPoints(obj, name, dataset_stack, reporting)
            % Load data from a cache file associated with this dataset
        
            data = obj.DependencyTracker.LoadMarkerPoints(name, dataset_stack, reporting);
        end
        
        function SaveManualSegmentation(obj, name, data, dataset_stack, reporting)
            % Save manual segmentation as a cache file associated with this dataset
            
            dataset_uid = obj.ImageInfo.ImageUid;
            
            try
                obj.DependencyTracker.SaveManualSegmentation(name, data, dataset_uid, reporting);
            catch ex
                dataset_stack.ClearStack;
                rethrow(ex);
            end
        end
        
        function data = LoadManualSegmentation(obj, name, dataset_stack, reporting)
            % Load data from a cache file associated with this dataset
        
            data = obj.DependencyTracker.LoadManualSegmentation(name, dataset_stack, reporting);
        end
        
        function edited_result = GetDefaultEditedResult(obj, plugin_name, dataset_stack, context, reporting)
            % This function will run a plugin's method to compute a default
            % edited result to be used if a plugin fails to compute a
            % result automatically
            
            reporting.PushProgress;
            if nargin < 4
                context = [];
            end
            
            % Get information about the plugin
            plugin_class = feval(plugin_name);
            plugin_info = MimParsePluginClass(plugin_name, plugin_class, reporting);
            
            % Update the progress dialog with the current plugin being run
            reporting.UpdateProgressMessage(['Computing ' plugin_info.ButtonText]);
            
            % Run the plugin
            edited_result = obj.DependencyTracker.GetDefaultEditedResult(context, obj.LinkedDatasetChooser, plugin_class, dataset_stack, reporting);
            
            reporting.CompleteProgress;
            
            reporting.PopProgress;
        end        
        
        function DeleteEditedPluginResult(obj, plugin_name, reporting)
            % Delete edit data from a cache file associated with this dataset
            
            obj.DatasetDiskCache.DeleteEditedPluginResult(plugin_name, reporting);
        end
        
        function DeleteManualSegmentation(obj, segmentation_name, reporting)
            % Delete manual segmentation from a cache file associated with this dataset
            
            obj.DatasetDiskCache.DeleteManualSegmentation(segmentation_name, reporting);
        end
        
        function DeleteMarkerSet(obj, name, reporting)
            % Delete manual segmentation from a cache file associated with this dataset
            
            obj.DatasetDiskCache.DeleteMarkerSet(name, reporting);
        end
        
        function file_list = GetListOfManualSegmentations(obj)
            % Gets list of manual segmentation files associated with this dataset

            file_list = obj.DatasetDiskCache.GetListOfManualSegmentations;
        end

        function file_list = GetListOfMarkerSets(obj)
            file_list = obj.DatasetDiskCache.GetListOfMarkerSets;
        end
        
        function SaveEditedResult(obj, plugin_name, input_context, edited_result_image, dataset_stack, reporting)
            % Save edit data to a cache file associated with this dataset
            
            dataset_uid = obj.ImageInfo.ImageUid;
            reporting.PushProgress;
            if nargin < 3 || isempty(input_context)
                reporting.Error('MimDatasetResults:NoContextSpecified', 'When calling SaveEditedResult(), the contex of the input image must be specified.');
            end
            
            % Get information about the plugin
            plugin_class = feval(plugin_name);
            plugin_info = MimParsePluginClass(plugin_name, plugin_class, [], reporting);
            
            % Update the progress dialog with the current plugin being run
            reporting.UpdateProgressMessage(['Saving edit for ' plugin_info.ButtonText]);
            
            try
                obj.ContextHierarchy.SaveEditedResultRecursive(plugin_name, input_context, edited_result_image, plugin_info, dataset_stack, dataset_uid, reporting);
            catch ex
                dataset_stack.ClearStack;
                rethrow(ex);
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
                template = obj.GetTemplateImage(obj.FrameworkAppDef.GetContextDef.GetOriginalDataContext, dataset_stack, reporting);
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
        
        function contexts = GetAllContextsForManualSegmentations(obj, dataset_stack, reporting)
            segmentation_list = obj.GetListOfManualSegmentations();
            contexts = {};
            for next_segmentation = segmentation_list
                segmentation_name = next_segmentation{1}.Second;
                segmentation = obj.LoadManualSegmentation(segmentation_name, dataset_stack, reporting);
                labels = setdiff(unique(segmentation.RawImage(:)), 0);
                if ~isempty(labels)
                    for label = labels'
                        contexts{end + 1} = [segmentation_name '.' int2str(label)];
                    end
                end
            end
        end
        
    end
end
