classdef TDImageTemplates < handle
    % TDImageTemplates. Part of the internal framework of the Pulmonary Toolkit.
    %
    %     You should not use this class within your own code. It is intended to
    %     be used internally within the framework of the Pulmonary Toolkit.
    %
    %     TDImageTemplates maintains a list of template images for contexts.
    %     A context is a region of interest of the lung (e.g. lung roi, left
    %     lung, right lung, original image). For each context there can exist a
    %     template image, which is an empty image containing the correct metadata
    %     for that image. A template image allows the construction of results
    %     images with the correct metadata.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    properties (Access = private)
        
        % Template images for each context
        TemplateImages
        
        % Template-related plugins which have been run. The idea is that we will 
        % know that a template is not available because the plugin was run but 
        % no tempalte was generated
        TemplatePluginsRun
        
        % A map of all valid contexts to their corresponding plugin
        ValidContexts
        
        % Used for persisting the templates between sessions
        DiskCache
        
        % Callback for running the plugins required to generate template images
        DatasetResultsCallback

        % Callback for error reporting
        Reporting
    end
    
    methods
        function obj = TDImageTemplates(dataset_callback, disk_cache, reporting)
            
            obj.DiskCache = disk_cache;
            obj.DatasetResultsCallback = dataset_callback;
            obj.Reporting = reporting;
            
            % Create empty maps. Maps must be initialised in the constructor,
            % not as default property values. Initialising as default property
            % values results in every instance of this claas sharing the same
            % map instance
            obj.TemplateImages = containers.Map;
            obj.ValidContexts  = containers.Map;
            obj.TemplatePluginsRun = containers.Map;

            % Add valid contexts
            obj.ValidContexts(char(TDContext.OriginalImage)) = 'TDOriginalImage';
            obj.ValidContexts(char(TDContext.LungROI)) = 'TDLungROI';
            obj.ValidContexts(char(TDContext.LeftLungROI)) = 'TDGetLeftLungROI';
            obj.ValidContexts(char(TDContext.RightLungROI)) = 'TDGetRightLungROI';

            % Loads cached template data
            obj.Load;
        end
        
        
        % Returns an image template for the requested context
        function template = GetTemplateImage(obj, context)
            
            % Check the context is recognised
            if ~obj.ValidContexts.isKey(char(context))
                obj.Reporting.Error('TDImageTemplates:UnknownContext', 'Context not recogised');
            end
            
            % If the template does not already exist, generate it now by calling
            % the appropriate plugin and creating a template copy
            if ~obj.TemplateImages.isKey(char(context))
                obj.Reporting.ShowWarning('TDImageTemplates:TemplateNotFound', ['No ' context ' template found. I am generating one now.'], []);
                obj.DatasetResultsCallback.GetResult(obj.ValidContexts(char(context)));
                
                % The call to GetResult should have automatically created the
                % template image - check that this has happened
                if ~obj.TemplateImages.isKey(char(context))
                    obj.Reporting.Error('TDImageTemplates:NoContext', 'Code error: a template should have been created by call to plugin, but was not');
                end
                
            end
            
            % return the template
            template = obj.TemplateImages(char(context));
            template = template.Copy;
        end


        % Check to see if a plugin which has been run is associated with any of
        % the contexts. If it is, create a new template image for that context
        % if one does not already exist
        function UpdateTemplates(obj, plugin_name, result_image)
            
            % Check if the result image is of a type that can be used to
            % generate a template image
            if ~isempty(result_image) && isa(result_image, 'TDImage')
                all_contexts = obj.ValidContexts.keys;
                
                % Search for contexts which relate to this plugin
                for next_context = all_contexts
                    context = char(next_context);
                    context_plugin = obj.ValidContexts(context);
                    
                    % This context relates to this plugin
                    if strcmp(plugin_name, context_plugin)
                        
                        % Create a new template image if required for this
                        % context
                        if ~obj.TemplateImages.isKey(context)
                            obj.SetTemplateImage(context, result_image.BlankCopy);
                        end
                    end
                end
            end
        end


        % Check to see if a context has been disabled for this dataset, due to a 
        % failure when running the plugin that generates the template image for 
        % that context.
        function context_is_enabled = IsContextEnabled(obj, context)
            % Check the context is recognised
            if ~obj.ValidContexts.isKey(char(context))
                obj.Reporting.Error('TDImageTemplates:UnknownContext', 'Context not recogised');
            end
            
            % The context is enabled unless a previous attempt to run the plugin
            % did not complete (assumed to have failed)
            context_is_enabled = ~((obj.TemplatePluginsRun.isKey(char(context))) && (~obj.TemplateImages.isKey(char(context))));
        end
        

        % Stores the fact that a plugin has been run
        function NoteAttemptToRunPlugin(obj, plugin_name)
            all_contexts = obj.ValidContexts.keys;
            
            % Search for contexts which relate to this plugin
            for next_context = all_contexts
                context = char(next_context);
                context_plugin = obj.ValidContexts(context);
                
                % This context relates to this plugin
                if strcmp(plugin_name, context_plugin)                    
                    obj.MarkTemplateImage(context);
                end
            end
        end
        
    end
    
    
    methods (Access = private)

        % Cache a template image for this context
        function SetTemplateImage(obj, context, template_image)
            obj.TemplateImages(context) = template_image;
            obj.Save;
        end
        
        % Cache a template image for this context
        function MarkTemplateImage(obj, context)
            if ~obj.TemplatePluginsRun.isKey(char(context))
                obj.TemplatePluginsRun(char(context)) = true;
                obj.Save;
            end
        end
        
        % Retrieves previous templates from the disk cache
        function Load(obj)
            if obj.DiskCache.Exists(TDSoftwareInfo.ImageTemplatesCacheName)
                info = obj.DiskCache.Load(TDSoftwareInfo.ImageTemplatesCacheName);
                obj.TemplateImages = info.TemplateImages;
                obj.TemplatePluginsRun = info.TemplatePluginsRun;
            end
        end
        
        % Stores current templates in the disk cache
        function Save(obj)
            info = [];
            info.TemplateImages = obj.TemplateImages;
            info.TemplatePluginsRun = obj.TemplatePluginsRun;
            obj.DiskCache.Save(TDSoftwareInfo.ImageTemplatesCacheName, info);
        end
    end
end