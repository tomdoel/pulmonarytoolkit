classdef MockImageTemplates < handle
    % MockImageTemplates. Part of the PTK test framework
    %
    % This class is used in tests in place of a PTKImageTemplates. It allows
    % expected calls to be verified, while maintaining some of the expected
    % behaviour of a PTKImageTemplates object.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    properties
        MockTemplateImages
    end
    
    methods
        function obj = MockImageTemplates()
            obj.MockTemplateImages = containers.Map;
        end
        
        function AddMockImage(obj, context, template_image)
            result = [];
            result.Template = template_image;
            obj.MockTemplateImages(char(context)) = result;
        end
        
        % Returns an image template for the requested context
        function template = GetTemplateImage(obj, context, linked_dataset_chooser, dataset_stack)
            key_name = [char(context)];
            
            result_from_cache = obj.MockTemplateImages(key_name);
            template = result_from_cache.Template;
            template = template.Copy;
        end


        % Check to see if a plugin which has been run is associated with any of
        % the contexts. If it is, create a new template image for that context
        % if one does not already exist
        function UpdateTemplates(obj, plugin_name, context, result_image, result_may_have_changed)
        end


        % Check to see if a context has been disabled for this dataset, due to a 
        % failure when running the plugin that generates the template image for 
        % that context.
        function context_is_enabled = IsContextEnabled(obj, context)
        end
        

        % Stores the fact that a plugin has been run
        function NoteAttemptToRunPlugin(obj, plugin_name, context)
        end
    end
end