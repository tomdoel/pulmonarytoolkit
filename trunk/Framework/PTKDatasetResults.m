classdef PTKDatasetResults < handle
    % PTKDatasetResults. 
    %
    %     This class is used to run calculations and fetch cached
    %     results associated with a dataset. The difference between PTKDataset 
    %     and PTKDatasetResults is that PTKDataset is called from outside the 
    %     toolkit, whereas PTKDatasetResults is called by plugins during their 
    %     RunPlugin() call. PTKDataset calls PTKDatasetResults, but provides 
    %     additional progress and error reporting and dependency tracking.
    %
    %     You should not create this class directly. An instance of this class
    %     is given to plugins during their RunPlugin() function call.
    %
    %     Example: 
    %
    %     classdef MyPlugin < PTKPlugin
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
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %

    

    properties (Access = private)
        
        ContextHierarchy     % Processes the calls to plugins, performing conversions between contexts where necessary
        DatasetDiskCache     % Reads and writes to the disk cache for this dataset
        DependencyTracker    % Tracks plugin usage to construct dependency lists 
        ImageTemplates       % Template images for different contexts
        Reporting            % Object for error and progress reporting
        PreviewImages        % Stores the thumbnail preview images
        ImageInfo            % Information about this dataset
        LinkedDatasetChooser % Used to process GetResult() requests during callbacks
        
        % A pointer to the PTKDataset object which contains the event to be triggered when a preview thumbnail image has changed
        ExternalWrapperNotifyFunction
        
    end
    
    methods
        function obj = PTKDatasetResults(image_info, linked_dataset_chooser, external_notify_function, dataset_disk_cache, reporting)
            obj.ImageInfo = image_info;
            obj.LinkedDatasetChooser = linked_dataset_chooser;
            obj.DatasetDiskCache = dataset_disk_cache;
            obj.ExternalWrapperNotifyFunction = external_notify_function;
            obj.Reporting = reporting;
            obj.ImageTemplates = PTKImageTemplates(obj, dataset_disk_cache, reporting);
            obj.PreviewImages = PTKPreviewImages(dataset_disk_cache, reporting);
            obj.DependencyTracker = PTKPluginDependencyTracker(dataset_disk_cache);
            obj.ContextHierarchy = PTKContextHierarchy(obj.DependencyTracker, obj.ImageTemplates, reporting);
        end

        % Returns the results of a plugin. If a valid result is cached on disk,
        % this wil be returned provided all the dependencies are valid.
        % Otherwise the plugin will be executed and the new result returned.
        % The optional context parameter specifies the region of interest to which the output result will be framed.
        % Specifying a second argument also produces a representative image from
        % the results. For plugins whose result is an image, this will generally be the
        % same as the results.
        function [result, cache_info, output_image] = GetResult(obj, plugin_name, dataset_stack, context, allow_results_to_be_cached_override)
            obj.Reporting.PushProgress;
            if nargin < 4
                context = [];
            end
            generate_results = nargout > 2;
            
            % Get information about the plugin
            plugin_class = feval(plugin_name);
            plugin_info = PTKParsePluginClass(plugin_name, plugin_class, obj.Reporting);
            
            % Whether results can be cached is determined by the plugin
            % parameters, but the input can force this to be enabled
            if nargin < 5 || isempty(allow_results_to_be_cached_override)
                allow_results_to_be_cached = plugin_info.AllowResultsToBeCached;
            else
                allow_results_to_be_cached = allow_results_to_be_cached_override || plugin_info.AllowResultsToBeCached;
            end
            
            % Update the progress dialog with the current plugin being run
            obj.Reporting.UpdateProgressMessage(['Computing ' plugin_info.ButtonText]);
            
            [result, cache_info, output_image, plugin_has_been_run] = obj.RunPluginWithOptionalImageGeneration(plugin_name, plugin_info, plugin_class, generate_results, dataset_stack, context, allow_results_to_be_cached);
            
            obj.Reporting.CompleteProgress;
            
            obj.Reporting.PopProgress;
        end

        % Returns a PTKImageInfo structure with image information, including the
        % UID, filenames and file path
        function image_info = GetImageInfo(obj)
            image_info = obj.ImageInfo;
        end
        
        % Save data as a cache file associated with this dataset
        % Used for marker points
        function SaveData(obj, name, data)
            obj.DatasetDiskCache.SaveData(name, data, obj.Reporting);
        end
        
        % Load data from a cache file associated with this dataset
        function data = LoadData(obj, name)
            data = obj.DatasetDiskCache.LoadData(name, obj.Reporting);
        end
        
        % Load data from a cache file associated with this dataset
        function SaveEditedPluginResult(obj, plugin_name, context, edited_result, cached_cache_info)
            obj.DatasetDiskCache.SaveEditedPluginResult(plugin_name, context, edited_result, cached_cache_info, obj.Reporting);
        end
        
        % Gets the path of the folder where the results for this dataset are
        % stored
        function dataset_cache_path = GetDatasetCachePath(obj)
            dataset_cache_path = obj.DatasetDiskCache.GetCachePath(obj.Reporting);
        end
        
        % Gets the path of the folder where the edited results for this dataset are
        % stored
        function cache_path = GetEditedResultsPath(obj)
           cache_path = obj.DatasetDiskCache.GetEditedResultsPath(obj.Reporting);
        end
        
        % Gets the path of the folder where the output for this dataset are
        % stored
        function cache_path = GetOutputPath(obj)
           cache_path = obj.DatasetDiskCache.GetOutputPath(obj.Reporting);
        end
        
        % Gets the path of the folder where the output files for this dataset are
        % stored
        function dataset_cache_path = GetOutputPathAndCreateIfNecessary(obj)
            results_directory = PTKDirectories.GetOutputDirectoryAndCreateIfNecessary;
            image_info = obj.GetImageInfo;
            uid = image_info.ImageUid;
            dataset_cache_path = fullfile(results_directory, uid);
            if ~exist(dataset_cache_path, 'dir')
                mkdir(dataset_cache_path);
            end      
        end        
        
        % Returns an empty template image for the specified context
        % See PTKImageTemplates.m for valid contexts
        function template_image = GetTemplateImage(obj, context, dataset_stack)
            template_image = obj.ImageTemplates.GetTemplateImage(context, dataset_stack);
        end
        
        % Gets a thumbnail image of the last result for this plugin
        function preview = GetPluginPreview(obj, plugin_name)
            preview = obj.PreviewImages.GetPreview(plugin_name);
        end

        % Removes all the cache files associated with this dataset. Cache files
        % store the results of plugins so they need only be computed once for
        % each dataset. Clearing the cache files forces recomputation of all
        % results.
        function ClearCacheForThisDataset(obj, remove_framework_files)
            obj.DatasetDiskCache.RemoveAllCachedFiles(remove_framework_files, obj.Reporting);
            obj.PreviewImages.Clear;
        end
        
        % Check to see if a context has been disabled for this dataset, due to a 
        % failure when running the plugin that generates the template image for 
        % that context.
        function context_is_enabled = IsContextEnabled(obj, context)
            context_is_enabled = obj.ImageTemplates.IsContextEnabled(context);
        end
        
        % ToDo: This check is based on series description and should be more
        % general
        function is_gas_mri = IsGasMRI(obj, dataset_stack)
            is_gas_mri = false;
            if ~strcmp(obj.GetImageInfo.Modality, 'MR')
                return;
            else
                template = obj.GetTemplateImage(PTKContext.OriginalImage, dataset_stack);
                if ~isfield(template.MetaHeader, 'ReceiveCoilName')
                    return;
                end
                if strcmpi(template.MetaHeader.ReceiveCoilName, 'MNS 129Xe TR')
                    is_gas_mri = true;
                end
            end
        end

        function valid = CheckDependencyValid(obj, next_dependency)
            valid = obj.DependencyTracker.CheckDependencyValid(next_dependency, obj.Reporting);
        end
    end

    methods (Access = private)
                
        % Returns the plugin result, computing if necessary
        function [result, cache_info, output_image, plugin_has_been_run] = RunPluginWithOptionalImageGeneration(obj, plugin_name, plugin_info, plugin_class, generate_image, dataset_stack, context, allow_results_to_be_cached)
            
            preview_exists = obj.PreviewImages.DoesPreviewExist(plugin_name);
            
            % We don't save the preview image if the plugin result was loaded
            % from the cache, unless there is no existing preview image
            
            force_generate_preview = (plugin_info.GeneratePreview && ~preview_exists);
            
            force_generate_image = generate_image || force_generate_preview;

            % Run the plugin for each required context and assemble result
            [result, output_image, plugin_has_been_run, cache_info] = obj.ComputeResultForAllContexts(plugin_name, context, plugin_info, plugin_class, dataset_stack, force_generate_image, allow_results_to_be_cached);

            cache_preview = plugin_info.GeneratePreview && (plugin_has_been_run || ~preview_exists);
            
            % Generate and cache a preview image
            if cache_preview && ~isempty(output_image) && output_image.ImageExists
                preview_size = [50, 50];
                output_image.GeneratePreview(preview_size, plugin_info.FlattenPreviewImage);
                obj.PreviewImages.AddPreview(plugin_name, output_image.Preview);
                
                % Fire an event indictaing the preview image has changed. This
                % will allow any listening gui to update its preview images if
                % necessary
                obj.ExternalWrapperNotifyFunction('PreviewImageChanged', PTKEventData(plugin_name));
            end
        end
        
        function [result, output_image, plugin_has_been_run, cache_info] = ComputeResultForAllContexts(obj, plugin_name, context, plugin_info, plugin_class, dataset_stack, force_generate_image, allow_results_to_be_cached)
            dataset_uid = obj.ImageInfo.ImageUid;
            
            % If non-debug mode 
            % In debug mode we don't try to catch exceptions so that the
            % debugger will stop at the right place
            if PTKSoftwareInfo.DebugMode
                [result, output_image, plugin_has_been_run, cache_info] = obj.ContextHierarchy.GetResult(plugin_name, context, obj.LinkedDatasetChooser, plugin_info, plugin_class, dataset_uid, dataset_stack, force_generate_image, allow_results_to_be_cached, obj.Reporting);
            else
                try
                    [result, output_image, plugin_has_been_run, cache_info] = obj.ContextHierarchy.GetResult(plugin_name, context, obj.LinkedDatasetChooser, plugin_info, plugin_class, dataset_uid, dataset_stack, force_generate_image, allow_results_to_be_cached, obj.Reporting);
                catch ex
                    dataset_stack.ClearStack;
                    rethrow(ex);
                end
            end
        end
    end
end
