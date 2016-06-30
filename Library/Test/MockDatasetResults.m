classdef MockDatasetResults < handle
    % MockDatasetResults. Part of the PTK test framework
    %
    % This class is used in tests in place of a MimDatasetResults. It allows
    % expected calls to be verified, while maintaining some of the expected
    % behaviour of a MimDatasetResults object.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    

    properties
        ImageTemplates
        MockResults
    end
    
    methods
        function obj = MockDatasetResults
            obj.MockResults = containers.Map;
        end
        
        function AddMockResult(obj, name, context, result_to_add, cache_info, output_image, has_been_run)
            result = [];
            result.Result = result_to_add;
            result.CacheInfo = cache_info;
            result.OutputImage = output_image;
            result.HasBeenRun = has_been_run;
            obj.MockResults([name '.' char(context)]) = result;
        end

        function [result, cache_info, output_image] = GetResult(obj, plugin_name, dataset_stack, context, reporting)
            
            obj.ImageTemplates.NoteAttemptToRunPlugin(plugin_name, context, reporting);

            key_name = [plugin_name '.' char(context)];
            
            result_from_cache = obj.MockResults(key_name);
            result = result_from_cache.Result;
            cache_info = result_from_cache.CacheInfo;
            output_image = result_from_cache.OutputImage;
            has_been_run = result_from_cache.HasBeenRun;
            
            obj.ImageTemplates.UpdateTemplates(plugin_name, context, result, has_been_run, cache_info, reporting);
        end

        % Returns a MimImageInfo structure with image information, including the
        % UID, filenames and file path
        function image_info = GetImageInfo(obj)
        end
        
        % Returns an empty template image for the specified context
        function template_image = GetTemplateImage(obj, context, linked_dataset_chooser, dataset_stack, reporting)
        end
        
        % Check to see if a context has been disabled for this dataset, due to a 
        % failure when running the plugin that generates the template image for 
        % that context.
        function context_is_enabled = IsContextEnabled(obj, context, reporting)
        end
        
        % ToDo: This check is based on series description and should be more
        % general
        function is_gas_mri = IsGasMRI(obj, linked_dataset_chooser, dataset_stack, reporting)
        end

        % Gets the path of the folder where the output files for this dataset are
        % stored
        function dataset_cache_path = GetOutputPathAndCreateIfNecessary(obj, reporting)
        end        
        
        function valid = CheckDependencyValid(obj, next_dependency, reporting)
        end
    end    
end
