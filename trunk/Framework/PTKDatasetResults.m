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
        
        ContextHierarchy   % Processes the calls to plugins, performing conversions between contexts where necessary
        DependencyTracker  % Tracks plugin usage to construct dependency lists 
        ImageTemplates     % Template images for different contexts
        Reporting          % Object for error and progress reporting
        PreviewImages      % Stores the thumbnail preview images
        ImageInfo          % Information about this dataset
        
        % A pointer to the PTKDataset object which contains the event to be triggered when a preview thumbnail image has changed
        ExternalWrapperNotifyFunction
        
    end
    
    methods
        function obj = PTKDatasetResults(image_info, preview_images, external_notify_function, dataset_disk_cache, reporting)
            obj.ImageInfo = image_info;
            obj.ExternalWrapperNotifyFunction = external_notify_function;
            obj.Reporting = reporting;
            obj.ImageTemplates = PTKImageTemplates(obj, dataset_disk_cache, reporting);
            obj.PreviewImages = preview_images;
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
        function [result, cache_info, output_image] = GetResult(obj, plugin_name, linked_dataset_chooser, dataset_stack, context)
            obj.Reporting.PushProgress;
            if nargin < 5
                context = [];
            end
            generate_results = nargout > 2;
            
            % Get information about the plugin
            plugin_class = feval(plugin_name);
            plugin_info = PTKParsePluginClass(plugin_name, plugin_class, obj.Reporting);
            
            % Update the progress dialog with the current plugin being run
            obj.Reporting.UpdateProgressMessage(['Computing ' plugin_info.ButtonText]);
            
            [result, cache_info, output_image, plugin_has_been_run] = obj.RunPluginWithOptionalImageGeneration(plugin_name, plugin_info, plugin_class, generate_results, linked_dataset_chooser, dataset_stack, context);
            
            obj.Reporting.CompleteProgress;
            
            obj.Reporting.PopProgress;
        end

        % Returns a PTKImageInfo structure with image information, including the
        % UID, filenames and file path
        function image_info = GetImageInfo(obj)
            image_info = obj.ImageInfo;
        end
        
        % Returns an empty template image for the specified context
        % See PTKImageTemplates.m for valid contexts
        function template_image = GetTemplateImage(obj, context, linked_dataset_chooser, dataset_stack)
            template_image = obj.ImageTemplates.GetTemplateImage(context, linked_dataset_chooser, dataset_stack);
        end
        
        % Check to see if a context has been disabled for this dataset, due to a 
        % failure when running the plugin that generates the template image for 
        % that context.
        function context_is_enabled = IsContextEnabled(obj, context)
            context_is_enabled = obj.ImageTemplates.IsContextEnabled(context);
        end
        
        % ToDo: This check is based on series description and should be more
        % general
        function is_gas_mri = IsGasMRI(obj, linked_dataset_chooser, dataset_stack)
            is_gas_mri = false;
            if ~strcmp(obj.GetImageInfo.Modality, 'MR')
                return;
            else
                template = obj.GetTemplateImage(PTKContext.OriginalImage, linked_dataset_chooser, dataset_stack);
                if strcmp(template.MetaHeader.SeriesDescription(1:2), 'Xe')
                    is_gas_mri = true;
                end
            end
        end

        % Gets the path of the folder where the output files for this dataset are
        % stored
        function dataset_cache_path = GetOutputPathAndCreateIfNecessary(obj)
            results_directory = PTKDirectories.GetResultsDirectoryAndCreateIfNecessary;
            image_info = obj.GetImageInfo;
            uid = image_info.ImageUid;
            dataset_cache_path = fullfile(results_directory, uid);
            if ~exist(dataset_cache_path, 'dir')
                mkdir(dataset_cache_path);
            end      
        end        
        
        function valid = CheckDependencyValid(obj, next_dependency)
            valid = obj.DependencyTracker.CheckDependencyValid(next_dependency, obj.Reporting);
        end
    end

    methods (Access = private)
                
        % Returns the plugin result, computing if necessary
        function [result, cache_info, output_image, plugin_has_been_run] = RunPluginWithOptionalImageGeneration(obj, plugin_name, plugin_info, plugin_class, generate_image, linked_dataset_chooser, dataset_stack, context)
            
            preview_exists = obj.PreviewImages.DoesPreviewExist(plugin_name);
            
            % We don't save the preview image if the plugin result was loaded
            % from the cache, unless there is no existing preview image
            
            force_generate_preview = (plugin_info.GeneratePreview && ~preview_exists);
            
            force_generate_image = generate_image || force_generate_preview;

            % Run the plugin for each required context and assemble result
            [result, output_image, plugin_has_been_run, cache_info] = obj.ComputeResultForAllContexts(plugin_name, context, linked_dataset_chooser, plugin_info, plugin_class, dataset_stack, force_generate_image);

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
        
        function [result, output_image, plugin_has_been_run, cache_info] = ComputeResultForAllContexts(obj, plugin_name, context, linked_dataset_chooser, plugin_info, plugin_class, dataset_stack, force_generate_image)
            dataset_uid = obj.ImageInfo.ImageUid;
            
            % If non-debug mode 
            % In debug mode we don't try to catch exceptions so that the
            % debugger will stop at the right place
            if PTKSoftwareInfo.DebugMode
                [result, output_image, plugin_has_been_run, cache_info] = obj.ContextHierarchy.GetResult(plugin_name, context, linked_dataset_chooser, plugin_info, plugin_class, dataset_uid, dataset_stack, force_generate_image, obj.Reporting);
            else
                try
                    [result, output_image, plugin_has_been_run, cache_info] = obj.ContextHierarchy.GetResult(plugin_name, context, linked_dataset_chooser, plugin_info, plugin_class, dataset_uid, dataset_stack, force_generate_image, obj.Reporting);
                catch ex
                    dataset_stack.ClearStack;
                    rethrow(ex);
                end
            end
        end
    end    
end
