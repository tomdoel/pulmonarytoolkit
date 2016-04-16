classdef MimImageTemplates < CoreBaseClass
    % MimImageTemplates. Part of the internal framework of the Pulmonary Toolkit.
    %
    %     You should not use this class within your own code. It is intended to
    %     be used internally within the framework of the Pulmonary Toolkit.
    %
    %     MimImageTemplates maintains a list of template images for contexts.
    %     A context is a region of interest of the lung (e.g. lung roi, left
    %     lung, right lung, original image). For each context there can exist a
    %     template image, which is an empty image containing the correct metadata
    %     for that image. A template image allows the construction of results
    %     images with the correct metadata.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    properties (Access = private)
        
        Config                 % configuration which stroes the preview image cache filename
        
        % Template images for each context
        TemplateImages
        
        % Dependencies for each template image
        TemplateDependencies
        
        % Template-related plugins which have been run. The idea is that we will 
        % know that a template is not available because the plugin was run but 
        % no template was generated
        TemplatePluginsRun
        
        % A map of all valid contexts to their corresponding plugin
        ValidContexts
        
        % A map of all valid contexts to the function required to generate the
        % context from the result of the plugin
        TemplateGenerationFunctions
        
        % Used for persisting the templates between sessions
        DatasetDiskCache
        
        % Callback for running the plugins required to generate template images
        DatasetResults
    end
    
    methods
        function obj = MimImageTemplates(framework_app_def, dataset_results, context_def, dataset_disk_cache, reporting)
            
            obj.Config = framework_app_def.GetFrameworkConfig;
            obj.DatasetDiskCache = dataset_disk_cache;
            obj.DatasetResults = dataset_results;
            
            % Create empty maps. Maps must be initialised in the constructor,
            % not as default property values. Initialising as default property
            % values results in every instance of this claas sharing the same
            % map instance
            obj.TemplateImages = containers.Map;
            obj.TemplateDependencies = containers.Map;
            obj.ValidContexts  = containers.Map;
            obj.TemplateGenerationFunctions = containers.Map;
            obj.TemplatePluginsRun = containers.Map;

            context_mappings = context_def.GetContexts;
            for context = context_mappings.keys
                context_mapping = context_mappings(context{1});
                
                % Add valid contexts
                obj.ValidContexts(char(context_mapping.Context)) = context_mapping.ContextTriggerPlugin;

                % Add handles to the functions used to generate the templates
                obj.TemplateGenerationFunctions(char(context_mapping.Context)) = context_mapping.TemplateGenerationFunctions;
            end
                        

            
            % Loads cached template data
            obj.Load(reporting);
        end
        
        
        function template = GetTemplateImage(obj, context, dataset_stack, reporting)
            % Returns an image template for the requested context
            
            % Check the context is recognised
            if ~obj.ValidContexts.isKey(char(context))
                reporting.Error('MimImageTemplates:UnknownContext', 'Context not recogised');
            end
            
            template_exists = obj.TemplateImages.isKey(char(context));
            
            % The dependency list will only not exist if a previous version of the template
            % file was being used
            dependency_list_exists = obj.TemplateDependencies.isKey(char(context));
            
            % If the template does not already exist, generate it now by calling
            % the appropriate plugin and creating a template copy
            if ~template_exists || ~dependency_list_exists
                reporting.ShowWarning('MimImageTemplates:TemplateNotFound', ['No ' char(context) ' template found. I am generating one now.'], []);
                obj.DatasetResults.GetResult(obj.ValidContexts(char(context)), dataset_stack, context, reporting);

                % The call to GetResult should have automatically created the
                % template image - check that this has happened
                if ~obj.TemplateImages.isKey(char(context))
                    reporting.Error('MimImageTemplates:NoContext', 'Code error: a template should have been created by call to plugin, but was not');
                end
                
            end
            
            % return the template
            template = obj.TemplateImages(char(context));
            template = template.Copy;
        end
        
        function template = GetTemplateMask(obj, context, dataset_stack, reporting)
            % Returns a mask image for the context. Unlike a template image, which can be an
            % empty image, the mask always has a binary image representing the lungs or
            % regions of the lungs corresponding to the context
            
            if (context == PTKContext.LungROI) || (context == PTKContext.OriginalImage)
                template = obj.GetTemplateImage(PTKContext.Lungs, dataset_stack, reporting);
            else
                template = obj.GetTemplateImage(context, dataset_stack, reporting);
            end
            
            template.CropToFit;
        end


        function UpdateTemplates(obj, plugin_name, context, result_image, result_may_have_changed, cache_info, reporting)
            % Check to see if a plugin which has been run is associated with any of
            % the contexts. If it is, create a new template image for that context
            % if one does not already exist
            
            % The cache info may be returned as a heirarchy, so extract out the first
            % stack item. This should be sufficient for parsing the dependency list
            
            if isempty(result_image) || isempty(cache_info)
                return;
            end
            
            while isa(cache_info, 'MimCompositeResult')
                fields = fieldnames(cache_info);
                cache_info = cache_info.(fields{1});
            end
            dependencies = cache_info.DependencyList;
            
            obj.InvalidateIfInDependencyList(plugin_name, reporting);
            
            % Check whether the plugin that has been run is the template for
            % this context
            context_char = char(context);
            if obj.ValidContexts.isKey(context_char)
                context_plugin_name = obj.ValidContexts(context_char);
                if strcmp(plugin_name, context_plugin_name)
                    
                    % Check if the result image is of a type that can be used to
                    % generate a template image
                    if ~isempty(result_image) && isa(result_image, 'PTKImage')
                        
                        % Create a new template image if required for this
                        % context, or if the template has changed
                        if (~obj.TemplateImages.isKey(context_char)) || result_may_have_changed

                            if ~obj.TemplateGenerationFunctions.isKey(context_char)
                                reporting.Error('MimImageTemplates:TemplateGenerationFunctionNotFound', 'Code error: the function handle required to generate this template was not found in the map.');
                            end
                            
                            template_function = obj.TemplateGenerationFunctions(context_char);
                            template_image = template_function(result_image, context, reporting);
                            
                            % Set the template image. Note: this may be an empty
                            % image (indicating the entire cropped region) or a
                            % boolean mask
                            obj.SetTemplateImage(context, template_image, dependencies, reporting);
                        end
                    end
                    
                end
            end
        end


        function context_is_enabled = IsContextEnabled(obj, context, reporting)
            % Check to see if a context has been disabled for this dataset, due to a
            % failure when running the plugin that generates the template image for
            % that context.
        
            % Check the context is recognised
            if ~obj.ValidContexts.isKey(char(context))
                reporting.Error('MimImageTemplates:UnknownContext', 'Context not recogised');
            end
            
            % The context is enabled unless a previous attempt to run the plugin
            % did not complete (assumed to have failed)
            context_is_enabled = ~((obj.TemplatePluginsRun.isKey(char(context))) && (~obj.TemplateImages.isKey(char(context))));
        end
        

        function NoteAttemptToRunPlugin(obj, plugin_name, context, reporting)
            % Stores the fact that a plugin has been run
            
            if obj.ValidContexts.isKey(char(context))
                context_plugin_name = obj.ValidContexts(char(context));
                if strcmp(plugin_name, context_plugin_name)                    
                    obj.MarkTemplateImage(context, reporting);
                end
            end
        end
        
        function ClearCache(obj, reporting)
            % Clears cached templates
            obj.TemplateImages = containers.Map;
            obj.TemplatePluginsRun  = containers.Map;
        end
        
        function InvalidateIfInDependencyList(obj, plugin_name, reporting)
            % Remove any templates whch depend on the given plugin name
            
            for template_name = obj.TemplateDependencies.keys
                dependency_list = obj.TemplateDependencies(template_name{1});
                for dependency = dependency_list.DependencyList
                    dependency_name = dependency.PluginName;
                    if strcmp(dependency_name, plugin_name)
                        reporting.Log(['MimImageTemplates: Context ' template_name{1} ' is now invalid']);
                        if obj.TemplateImages.isKey(template_name{1})
                            obj.TemplateImages.remove(template_name{1});
                        end
                        obj.TemplateDependencies.remove(template_name{1});
                    end
                end
            end
        end
    end
    
    
    methods (Access = private)

        function SetTemplateImage(obj, context, template_image, dependencies, reporting)
            % Cache a template image for this context
            
            obj.TemplateImages(char(context)) = template_image;
            obj.TemplateDependencies(char(context)) = dependencies;

            obj.Save(reporting);
        end
        
        function MarkTemplateImage(obj, context, reporting)
            
            if ~obj.TemplatePluginsRun.isKey(char(context))
                obj.TemplatePluginsRun(char(context)) = true;
                obj.Save(reporting);
            end
        end
        
        function Load(obj, reporting)
            % Retrieves previous templates from the disk cache
        
            filename = obj.Config.ImageTemplatesCacheName;
            if obj.DatasetDiskCache.Exists(filename, [], reporting)
                info = obj.DatasetDiskCache.LoadData(filename, reporting);
                if isfield(info, 'TemplateDependencies')
                    obj.TemplateDependencies = info.TemplateDependencies;
                    obj.TemplateImages = info.TemplateImages;
                    obj.TemplatePluginsRun = info.TemplatePluginsRun;
                else
                    obj.TemplateDependencies = containers.Map;
                    obj.TemplateImages = containers.Map;
                    obj.TemplatePluginsRun = containers.Map;
                end
            end
        end
        
        function Save(obj, reporting)
            % Stores current templates in the disk cache
            
            info = [];
            info.TemplateImages = obj.TemplateImages;
            info.TemplatePluginsRun = obj.TemplatePluginsRun;
            info.TemplateDependencies = obj.TemplateDependencies;
            obj.DatasetDiskCache.SaveData(obj.Config.ImageTemplatesCacheName, info, reporting);
        end
    end
end