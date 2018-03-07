classdef MimImageTemplates < CoreBaseClass
    % MimImageTemplates. Part of the internal framework of the TD MIM Toolkit.
    %
    %     You should not use this class within your own code. It is intended to
    %     be used internally within the framework of the TD MIM Toolkit.
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
    %     Part of the TD MIM Toolkit. https://github.com/tomdoel
    %     Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %
    
    properties (Access = private)
        
        Config                 % configuration which stroes the preview image cache filename
        
        % Template-related plugins which have been run, and those that have been run and succeeded. The idea is that we will 
        % know that a template is not available because the plugin was run
        % but failed
        TemplatePluginsRun
        TemplatePluginsRunSuccess
        
        % A map of all valid contexts to their corresponding plugin
        ValidContexts
        
        % A map of all valid contexts to the function required to generate the
        % context from the result of the plugin
        TemplateGenerationFunctions
        
        % Used for persisting the templates between sessions
        DatasetDiskCache
        
        % Callback for running the plugins required to generate template images
        DatasetResults
        
        % App-specific framework configuration
        FrameworkAppDef
    end
    
    methods
        function obj = MimImageTemplates(framework_app_def, dataset_results, context_def, dataset_disk_cache, pipelines, reporting)
            
            obj.Config = framework_app_def.GetFrameworkConfig;
            obj.DatasetDiskCache = dataset_disk_cache;
            obj.DatasetResults = dataset_results;
            obj.FrameworkAppDef = framework_app_def;
            
            % Create empty maps. Maps must be initialised in the constructor,
            % not as default property values. Initialising as default property
            % values results in every instance of this claas sharing the same
            % map instance
            obj.ValidContexts  = containers.Map;
            obj.TemplateGenerationFunctions = containers.Map;
            obj.TemplatePluginsRun = containers.Map;
            obj.TemplatePluginsRunSuccess = containers.Map;

            context_mappings = context_def.GetContexts;
            for context = context_mappings.keys
                context_mapping = context_mappings(context{1});
                
                % Add valid contexts
                obj.ValidContexts(char(context_mapping.Context)) = context_mapping.ContextTriggerPlugin;

                % Add handles to the functions used to generate the templates
                obj.TemplateGenerationFunctions(char(context_mapping.Context)) = context_mapping.TemplateGenerationFunctions;

                % Add a pipeline to trigger the template generation Plugin
                pipelines.AddPipeline(context_mapping.ContextTriggerPlugin, char(context_mapping.Context), context_mapping.TemplateGenerationFunctions);
            end
            
            % Loads cached template data
            obj.Load(reporting);
        end
        
        
        function template = GetTemplateImage(obj, context, dataset_stack, reporting)
            % Returns an image template for the requested context
            
            if obj.ValidContexts.isKey(char(context))
                % If the context is recognised then use the template
                % generation function
                template_plugin = obj.TemplateGenerationFunctions(char(context));
                parameters = []; % Set parameters to null for a template call; existing parameters in the stack can still be accessed
                template = obj.DatasetResults.GetResult(template_plugin, dataset_stack, context, parameters, reporting);

                % Extract the template
                context_list = fieldnames(template);
                if numel(context_list) ~= 1 || ~CoreCompareUtilities.CompareEnumName(context_list{1}, context)
                    reporting.Error('MimImageTemplates:ContextDoesNotMatch', 'The returned context does not match');
                end
                template = template.(context_list{1});
                
                template = template.Copy;                
            else
                if obj.DatasetDiskCache.ManualSegmentationExists(context, reporting)
                    template = obj.DatasetDiskCache.LoadManualSegmentation(context, reporting);
                    template = template.Copy();
                    template_raw = template.RawImage;
                    if isnumeric(template_raw)
                        template_raw = template_raw > 0;
                    end
                    template.ChangeRawImage(template_raw);
                else
                    [context_prefix, context_suffix] = CoreTextUtilities.SplitAtLastDelimiter(context, '.');
                    if obj.DatasetDiskCache.ManualSegmentationExists(context_prefix, reporting)
                        label_value = str2double(context_suffix);
                        template = obj.DatasetDiskCache.LoadManualSegmentation(context_prefix, reporting);
                        template = template.Copy();
                        template_raw = template.RawImage;
                        if isnumeric(template_raw)
                            template_raw = template_raw == label_value;
                        end
                        template.ChangeRawImage(template_raw);
                    else                
                        reporting.Error('MimImageTemplates:UnknownContext', 'Context not recogised');
                    end
                end
            end
        end
        
        function template = GetTemplateMask(obj, context, dataset_stack, reporting)
            % Returns a mask image for the context. Unlike a template image, which can be an
            % empty image, the mask always has a binary image representing the lungs or
            % regions of the lungs corresponding to the context
            
            template_mask_context = obj.FrameworkAppDef.GetContextDef.GetTemplateMaskContext(context);
            template = obj.GetTemplateImage(template_mask_context, dataset_stack, reporting);
            
            template.CropToFit();
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
            context_is_enabled = obj.TemplatePluginsRunSuccess.isKey(char(context)) || ~obj.TemplatePluginsRun.isKey(char(context));
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
        
        
        function NoteSuccessRunPlugin(obj, plugin_name, context, reporting)
            % Stores the fact that a plugin has been run successfully
            
            if obj.ValidContexts.isKey(char(context))
                context_plugin_name = obj.ValidContexts(char(context));
                if strcmp(plugin_name, context_plugin_name)                    
                    obj.MarkTemplateImageSuccess(context, reporting);
                end
            end
        end
                
        function ClearCache(obj, reporting)
            % Clears cached templates
            obj.TemplatePluginsRun = containers.Map;
            obj.TemplatePluginsRunSuccess = containers.Map;
        end
    end
    
    
    methods (Access = private)
   
        function MarkTemplateImage(obj, context, reporting)
            
            if ~obj.TemplatePluginsRun.isKey(char(context))
                obj.TemplatePluginsRun(char(context)) = true;
                obj.Save(reporting);
            end
        end
        
        function MarkTemplateImageSuccess(obj, context, reporting)
            
            if ~obj.TemplatePluginsRunSuccess.isKey(char(context))
                obj.TemplatePluginsRunSuccess(char(context)) = true;
                obj.Save(reporting);
            end
        end
        
        function Load(obj, reporting)
            % Retrieves previous templates from the disk cache
        
            filename = obj.Config.ImageTemplatesCacheName;
            if obj.DatasetDiskCache.Exists(filename, [], reporting)
                info = obj.DatasetDiskCache.LoadData(filename, reporting);
                if isfield(info, 'TemplatePluginsRun')
                    obj.TemplatePluginsRun = info.TemplatePluginsRun;
                else
                    obj.TemplatePluginsRun = containers.Map;
                end
                
                if isfield(info, 'TemplatePluginsRunSuccess') && ~isempty(info.TemplatePluginsRunSuccess)
                    obj.TemplatePluginsRunSuccess = info.TemplatePluginsRunSuccess;
                else
                    obj.TemplatePluginsRunSuccess = containers.Map;
                end
            end
        end
        
        function Save(obj, reporting)
            % Stores current templates in the disk cache
            
            info = [];
            info.TemplatePluginsRun = obj.TemplatePluginsRun;
            info.TemplatePluginsRunSuccess = obj.TemplatePluginsRunSuccess;
            obj.DatasetDiskCache.SaveData(obj.Config.ImageTemplatesCacheName, info, reporting);
        end
    end
end