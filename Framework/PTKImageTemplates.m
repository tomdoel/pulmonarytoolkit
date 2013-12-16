classdef PTKImageTemplates < handle
    % PTKImageTemplates. Part of the internal framework of the Pulmonary Toolkit.
    %
    %     You should not use this class within your own code. It is intended to
    %     be used internally within the framework of the Pulmonary Toolkit.
    %
    %     PTKImageTemplates maintains a list of template images for contexts.
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

        % Callback for error reporting
        Reporting
    end
    
    methods
        function obj = PTKImageTemplates(dataset_results, dataset_disk_cache, reporting)
            
            obj.DatasetDiskCache = dataset_disk_cache;
            obj.DatasetResults = dataset_results;
            obj.Reporting = reporting;
            
            % Create empty maps. Maps must be initialised in the constructor,
            % not as default property values. Initialising as default property
            % values results in every instance of this claas sharing the same
            % map instance
            obj.TemplateImages = containers.Map;
            obj.ValidContexts  = containers.Map;
            obj.TemplateGenerationFunctions = containers.Map;
            obj.TemplatePluginsRun = containers.Map;

            % Add valid contexts
            obj.ValidContexts(char(PTKContext.OriginalImage)) = 'PTKOriginalImage';
            obj.ValidContexts(char(PTKContext.LungROI)) = 'PTKLungROI';
            obj.ValidContexts(char(PTKContext.LeftLung)) = 'PTKGetContextForSingleLung';
            obj.ValidContexts(char(PTKContext.RightLung)) = 'PTKGetContextForSingleLung';
            obj.ValidContexts(char(PTKContext.RightUpperLobe)) = 'PTKGetContextForLobe';
            obj.ValidContexts(char(PTKContext.RightMiddleLobe)) = 'PTKGetContextForLobe';
            obj.ValidContexts(char(PTKContext.RightLowerLobe)) = 'PTKGetContextForLobe';
            obj.ValidContexts(char(PTKContext.LeftUpperLobe)) = 'PTKGetContextForLobe';
            obj.ValidContexts(char(PTKContext.LeftLowerLobe)) = 'PTKGetContextForLobe';

            % Add handles to the functions used to generate the templates
            obj.TemplateGenerationFunctions(char(PTKContext.OriginalImage)) = @PTKCreateTemplateForOriginalImage;
            obj.TemplateGenerationFunctions(char(PTKContext.LungROI)) = @PTKCreateTemplateForLungROI;
            obj.TemplateGenerationFunctions(char(PTKContext.LeftLung)) = @PTKCreateTemplateForSingleLung;
            obj.TemplateGenerationFunctions(char(PTKContext.RightLung)) = @PTKCreateTemplateForSingleLung;
            obj.TemplateGenerationFunctions(char(PTKContext.RightUpperLobe)) = @PTKCreateTemplateForLobe;
            obj.TemplateGenerationFunctions(char(PTKContext.RightMiddleLobe)) = @PTKCreateTemplateForLobe;
            obj.TemplateGenerationFunctions(char(PTKContext.RightLowerLobe)) = @PTKCreateTemplateForLobe;
            obj.TemplateGenerationFunctions(char(PTKContext.LeftUpperLobe)) = @PTKCreateTemplateForLobe;
            obj.TemplateGenerationFunctions(char(PTKContext.LeftLowerLobe)) = @PTKCreateTemplateForLobe;
            
            % Loads cached template data
            obj.Load;
        end
        
        
        % Returns an image template for the requested context
        function template = GetTemplateImage(obj, context, dataset_stack)
            
            % Check the context is recognised
            if ~obj.ValidContexts.isKey(char(context))
                obj.Reporting.Error('PTKImageTemplates:UnknownContext', 'Context not recogised');
            end
            
            % If the template does not already exist, generate it now by calling
            % the appropriate plugin and creating a template copy
            if ~obj.TemplateImages.isKey(char(context))
                obj.Reporting.ShowWarning('PTKImageTemplates:TemplateNotFound', ['No ' char(context) ' template found. I am generating one now.'], []);
                obj.DatasetResults.GetResult(obj.ValidContexts(char(context)), dataset_stack, context);
                

                % The call to GetResult should have automatically created the
                % template image - check that this has happened
                if ~obj.TemplateImages.isKey(char(context))
                    obj.Reporting.Error('PTKImageTemplates:NoContext', 'Code error: a template should have been created by call to plugin, but was not');
                end
                
            end
            
            % return the template
            template = obj.TemplateImages(char(context));
            template = template.Copy;
        end


        % Check to see if a plugin which has been run is associated with any of
        % the contexts. If it is, create a new template image for that context
        % if one does not already exist
        function UpdateTemplates(obj, plugin_name, context, result_image, result_may_have_changed)
            
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
                        if (~obj.TemplateImages.isKey(context)) || result_may_have_changed

                            
                            if ~obj.TemplateGenerationFunctions.isKey(context_char)
                                obj.Reporting.Error('PTKImageTemplates:TemplateGenerationFunctionNotFound', 'Code error: the function handle required to generate this template was not found in the map.');
                            end
                            
                            template_function = obj.TemplateGenerationFunctions(context_char);
                            template_image = template_function(result_image, context, obj.Reporting);
                            
                            % Set the template image. Note: this may be an empty
                            % image (indicating the entire cropped region) or a
                            % boolean mask
                            obj.SetTemplateImage(context, template_image);
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
                obj.Reporting.Error('PTKImageTemplates:UnknownContext', 'Context not recogised');
            end
            
            % The context is enabled unless a previous attempt to run the plugin
            % did not complete (assumed to have failed)
            context_is_enabled = ~((obj.TemplatePluginsRun.isKey(char(context))) && (~obj.TemplateImages.isKey(char(context))));
        end
        

        % Stores the fact that a plugin has been run
        function NoteAttemptToRunPlugin(obj, plugin_name, context)
            if obj.ValidContexts.isKey(char(context))
                context_plugin_name = obj.ValidContexts(char(context));
                if strcmp(plugin_name, context_plugin_name)                    
                    obj.MarkTemplateImage(context);
                end
            end
        end
        
    end
    
    
    methods (Access = private)

        % Cache a template image for this context
        function SetTemplateImage(obj, context, template_image)
            obj.TemplateImages(char(context)) = template_image;
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
            if obj.DatasetDiskCache.Exists(PTKSoftwareInfo.ImageTemplatesCacheName, [], obj.Reporting)
                info = obj.DatasetDiskCache.LoadData(PTKSoftwareInfo.ImageTemplatesCacheName, obj.Reporting);
                obj.TemplateImages = info.TemplateImages;
                obj.TemplatePluginsRun = info.TemplatePluginsRun;
            end
        end
        
        % Stores current templates in the disk cache
        function Save(obj)
            info = [];
            info.TemplateImages = obj.TemplateImages;
            info.TemplatePluginsRun = obj.TemplatePluginsRun;
            obj.DatasetDiskCache.SaveData(PTKSoftwareInfo.ImageTemplatesCacheName, info, obj.Reporting);
        end
    end
end