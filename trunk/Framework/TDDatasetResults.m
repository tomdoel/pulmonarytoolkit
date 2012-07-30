classdef TDDatasetResults < handle
    % TDDatasetResults. Used by plugins to obtain results and associated data for a particualar dataset.
    %
    %     This class is used by plugins to run calculations and fetch cached
    %     results associated with a dataset. The difference between TDDataset 
    %     and TDDatasetResults is that TDDataset is called from outside the 
    %     toolkit, whereas TDDatasetResults is called by plugins during their 
    %     RunPlugin() call. TDDataset calls TDDatasetResults, but provides 
    %     additional progress and error reporting and dependency tracking.
    %
    %     You should not create this class directly. An instance of this class
    %     is given to plugins during their RunPlugin() function call.
    %
    %     Example: 
    %
    %     classdef MyPlugin < TDPlugin
    %
    %     methods (Static)
    %         function results = RunPlugin(dataset_results, reporting)
    %             ...
    %             airway_results = dataset_results.GetResult('TDAirways');
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
        
        ImageTemplates     % Template images for different contexts
        Reporting          % Object for error and progress reporting
        PreviewImages      % Stores the thumbnail preview images
        DependencyTracker  % Tracks plugin usage to construct dependency lists 
        ImageInfo          % Information about this dataset
        
        % A pointer to the TDDataset object which contains the event to be triggered when a preview thumbnail image has changed
        ExternalWrapperNotifyFunction
        
    end
    
    methods
        function obj = TDDatasetResults(image_info, preview_images, dependency_tracker, external_notify_function, disk_cache, reporting)
            obj.ImageInfo = image_info;
            obj.ExternalWrapperNotifyFunction = external_notify_function;
            obj.Reporting = reporting;
            obj.ImageTemplates = TDImageTemplates(obj, disk_cache, reporting);
            obj.PreviewImages = preview_images;
            obj.DependencyTracker = dependency_tracker;            
        end

        % RunPlugin: Returns the results of a plugin. If a valid result is cached on disk,
        % this wil be returned provided all the dependencies are valid.
        % Otherwise the plugin will be executed and the new result returned.
        % The optional context parameter specifies the region of interest to which the output result will be framed.
        % Specifying a second argument also produces a representative image from
        % the results. For plugins whose result is an image, this will generally be the
        % same as the results.
        function [result, output_image] = GetResult(obj, plugin_name, context)
            if nargin < 3
                context = [];
            end
            if nargout > 1
                [result, output_image] = obj.RunPluginWithOptionalImageGeneration(plugin_name, true, context);
            else
                result = obj.RunPluginWithOptionalImageGeneration(plugin_name, false, context);
            end
        end

        % Returns a TDImageInfo structure with image information, including the
        % UID, filenames and file path
        function image_info = GetImageInfo(obj)
            image_info = obj.ImageInfo;
        end
        
        % Returns an empty template image for the specified context
        % See TDImageTemplates.m for valid contexts
        function template_image = GetTemplateImage(obj, context)
            template_image = obj.ImageTemplates.GetTemplateImage(context);
        end
        
        % Check to see if a context has been disabled for this dataset, due to a 
        % failure when running the plugin that generates the template image for 
        % that context.
        function context_is_enabled = IsContextEnabled(obj, context)
            context_is_enabled = obj.ImageTemplates.IsContextEnabled(context);
        end
        
    end

    methods (Access = private)
                
        % Returns the plugin result, computing if necessary
        function [result, output_image] = RunPluginWithOptionalImageGeneration(obj, plugin_name, generate_image, context)
            
            % Get information about the plugin
            plugin_info = eval(plugin_name);
            
            % Update the progress dialog with the current plugin being run
            obj.Reporting.UpdateProgressMessage(['Computing ' plugin_info.ButtonText]);
                        
            % Allow the context manager to construct a template image from this
            % result if required
            obj.ImageTemplates.NoteAttemptToRunPlugin(plugin_name);

            [result, plugin_has_been_run] = obj.GetResultFromDependencyTracker(plugin_name, plugin_info);

            % Allow the context manager to construct a template image from this
            % result if required
            obj.ImageTemplates.UpdateTemplates(plugin_name, result);
            
            preview_exists = obj.PreviewImages.DoesPreviewExist(plugin_name);
            
            % We don't save the preview image if the plugin result was loaded
            % from the cache, unless there is no existing preview image
            cache_preview = plugin_info.GeneratePreview && (plugin_has_been_run || ~preview_exists);
            
            % We generate an output image if requested, or if we need to generate a preview image
            if generate_image || cache_preview
                if isa(result, 'TDImage')
                    output_image = obj.GenerateImageFromResults(plugin_info, result.Copy);
                else
                    output_image = obj.GenerateImageFromResults(plugin_info, result);
                end
            else
                output_image = [];
            end
            
            % Generate and cache a preview image
            if cache_preview && ~isempty(output_image) && output_image.ImageExists
                preview_size = [50, 50];
                output_image.GeneratePreview(preview_size, plugin_info.FlattenPreviewImage);
                obj.PreviewImages.AddPreview(plugin_name, output_image.Preview);
                
                % Fire an event indictaing the preview image has changed. This
                % will allow any listening gui to update its preview images if
                % necessary
                obj.ExternalWrapperNotifyFunction('PreviewImageChanged', TDEventData(plugin_name));
            end
            
            % If a context has been specified then resize the output image
            % to this context
            if ~isempty(context) && isa(result, 'TDImage')
                template_image = obj.ImageTemplates.GetTemplateImage(context);
                result.ResizeToMatch(template_image);
            end
            
            obj.Reporting.CompleteProgress;
            
        end
        
        function [result, plugin_has_been_run] = GetResultFromDependencyTracker(obj, plugin_name, plugin_info)
            
            % If non-debug mode 
            % In debug mode we don't try to catch exceptions so that the
            % debugger will stop at the right place
            if TDSoftwareInfo.DebugMode
                [result, plugin_has_been_run] = obj.DependencyTracker.GetResult(plugin_name, plugin_info, obj, obj.Reporting);
            else
                try
                    [result, plugin_has_been_run] = obj.DependencyTracker.GetResult(plugin_name, plugin_info, obj, obj.Reporting);
                catch ex
                    obj.DependencyTracker.ClearStack;
                    rethrow(ex);
                end
            end
        end
        
        function output_image = GenerateImageFromResults(obj, plugin_info, result)
            
            if TDSoftwareInfo.DebugMode
                output_image = plugin_info.GenerateImageFromResults(result, obj.ImageTemplates, obj.Reporting);
            else
                try
                    output_image = plugin_info.GenerateImageFromResults(result, obj.ImageTemplates, obj.Reporting);
                catch ex
                    obj.ClearStack;
                    rethrow(ex);
                end
            end
        end
    end    
end
