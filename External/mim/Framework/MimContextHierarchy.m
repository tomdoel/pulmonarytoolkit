classdef MimContextHierarchy < CoreBaseClass
    % MimContextHierarchy. Part of the internal framework of the TD MIM Toolkit.
    %
    %     This class is used to switch beteen different contexts.
    %
    %     There are a number of contexts, which each represent particular
    %     regions of the lung. For example, the OriginalImage context is the
    %     entire image, whereas the LungROI is the parrallipiped region
    %     containing the lungs and airways. The LeftLung and RightLung comprise
    %     just the voumes of the left and right lung respectively.
    %
    %     Context sets describe a collection of related contexts. For example,
    %     the SingleLung context set contains LeftLung and RightLung.
    %
    %     Each plugin specifies its context set, which is the domain of the
    %     results produced by the plugin. Some plugins operate over the whole
    %     LungROI region, while some operate on individual lungs.
    %
    %     This class manages the situations where a result is requested for a
    %     particualar context (e.g. LungROI) but the plugin defines a different
    %     context set (e.g. SingleLung). The LungROI can be built from the two
    %     contexts in the SingleLung set. Therefore in this case, the plugin is run twice,
    %     once for the left and once for the right lung. Then the resutls are
    %     combined to produce the result for the LungROI context.
    %
    %     Thie class manages this heirarchy of contexts and context sets. In
    %     this way plugins can operate on whichever context is appropriate,
    %     while results can be requested for any context, and the conversions
    %     are handled automatically.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD MIM Toolkit. https://github.com/tomdoel
    %     Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %    
    
    
    properties
        ContextSets
        Contexts
        ContextDef
        
        DatasetDiskCache
        DependencyTracker
        ImageTemplates
        Pipelines
        FrameworkAppDef % Framework configuration
        PluginCache % Used to check plugin version numbers        
    end
    
    methods
        function obj = MimContextHierarchy(context_def, dataset_disk_cache, dependency_tracker, image_templates, pipelines, framework_app_def, plugin_cache)
            obj.DatasetDiskCache = dataset_disk_cache;
            obj.DependencyTracker = dependency_tracker;
            obj.ImageTemplates = image_templates;
            obj.Pipelines = pipelines;
            obj.FrameworkAppDef = framework_app_def;
            obj.PluginCache = plugin_cache;
            
            obj.ContextDef = context_def;
            obj.Contexts = context_def.GetContexts;
            obj.ContextSets = context_def.GetContextSets;
        end
        
        function context_list = GetContextList(obj, output_context, plugin_info, reporting)
            % Parses a list of Contexts, expands out any ContextSets into
            % Contexts, and returns an error if a Context is not known
            
            % Determines the context and context type requested by the calling function
            if isempty(output_context)
                output_context = obj.ContextDef.ChooseOutputContext(plugin_info.Context);
            end
            
            context_list = [];
            
            for next_output_context_set = CoreContainerUtilities.ConvertToSet(output_context)
                next_output_context = next_output_context_set{1};
                if obj.Contexts.isKey(char(next_output_context))
                    % Note that if the enum name of the context set matches
                    % the enum name of a context, we need to be sure the
                    % contet gets added, not the context set
                    context_list{end + 1} = obj.Contexts(char(next_output_context)).Context;
                elseif obj.ContextSets.isKey(char(next_output_context))
                    context_set_mapping = obj.ContextSets(char(next_output_context));
                    context_mapping_list = context_set_mapping.ContextList;
                    context_list = [context_list, CoreContainerUtilities.GetFieldValuesFromSet(context_mapping_list, 'Context')];
                else
                    if obj.DatasetDiskCache.ManualSegmentationExists(char(next_output_context), reporting)
                        context_list{end + 1} = char(next_output_context);
                    else
                        % Allow contexts with specific label indices
                        [context_prefix, context_suffix] = CoreTextUtilities.SplitAtLastDelimiter(char(next_output_context), '.');
                        if obj.DatasetDiskCache.ManualSegmentationExists(context_prefix, reporting)
                            context_list{end + 1} = char(next_output_context);
                        else
                            reporting.Error('MimContextHierarchy:UnknownOutputContext', 'I do not understand the requested output context.');
                        end
                    end
                end
            end            
        end
        
        function value = GetParameter(obj, name, dataset_stack, reporting)
            value = dataset_stack.GetParameterAndAddDependenciesToPluginsInStack(name, reporting);
        end
        
        function combined_result = GetResultRecursive(obj, plugin_name, output_context, parameters, linked_dataset_chooser, plugin_info, plugin_class, dataset_uid, dataset_stack, force_generate_image, memory_cache_policy, disk_cache_policy, reporting)
            
            % Records that there has been an attempt to call this plugin,
            % so that we can detect if a plugin call failed
            obj.ImageTemplates.NoteAttemptToRunPlugin(plugin_name, output_context, reporting);

            [plugin_context_set, plugin_context_set_mapping] = obj.GetContextSetMappings(plugin_info.Context);            
            [output_context, output_context_set, output_context_mapping, output_context_set_mapping] = obj.GetContextMaps(output_context);
            
            % If the input and output contexts are of the same type, or if the
            % plugin context is of type 'Any', then proceed to call the plugin
            if isempty(output_context_set) || obj.ContextDef.ContextSetMatches(plugin_context_set, output_context_set)
                [result, plugin_has_been_run, cache_info] = obj.DependencyTracker.GetResult(plugin_name, output_context, parameters, linked_dataset_chooser, plugin_info, plugin_class, dataset_uid, dataset_stack, memory_cache_policy, disk_cache_policy, reporting);

                % If the plugin has been re-run, then we will generate an output
                % image, in order to create a new preview image
                if (plugin_info.GeneratePreview && plugin_has_been_run)
                    force_generate_image = true;
                end

                % We generate an output image if requested, or if the plugin has been re-run (indictaing that we will need to generate a new preview image)
                if force_generate_image
                    output_image = obj.GenerateImageFromResults(result, plugin_class, linked_dataset_chooser, dataset_stack, reporting);
                else
                    output_image = [];
                end

                combined_result = MimCombinedPluginResult(result, output_image, plugin_has_been_run, cache_info);
            
            % Otherwise, if the plugin's context set is higher in the hierarchy
            % than the requested output, then get the result for the higher
            % context and then extract out the desired context
            elseif output_context_set_mapping.IsOtherContextSetHigher(plugin_context_set_mapping)
                combined_result = MimContextResultCombiner(obj.ImageTemplates);
                higher_context_mapping = output_context_mapping.Parent;
                if isempty(higher_context_mapping)
                    reporting.Error('MimContextHierarchy:UnexpectedSituation', 'The requested plugin call cannot be made as I am unable to determine the relationship between the plugin context and the requested result context.');
                end
                parent_context = higher_context_mapping.Context;
                this_context_results = obj.GetResultRecursive(plugin_name, parent_context, parameters, linked_dataset_chooser, plugin_info, plugin_class, dataset_uid, dataset_stack, force_generate_image, memory_cache_policy, disk_cache_policy, reporting);
                combined_result.AddParentResult(parent_context, this_context_results, output_context, output_context_mapping, dataset_stack, reporting);
                
            % If the plugin's context set is lower in the hierarchy, then get
            % the plugin result for all lower contexts and concatenate the results
            elseif plugin_context_set_mapping.IsOtherContextSetHigher(output_context_set_mapping)
                combined_result = MimContextResultCombiner(obj.ImageTemplates);
                child_context_mappings = output_context_mapping.Children;

                for child_mapping = child_context_mappings
                    child_context = child_mapping{1}.Context;
                    this_context_results = obj.GetResultRecursive(plugin_name, child_context, parameters, linked_dataset_chooser, plugin_info, plugin_class, dataset_uid, dataset_stack, force_generate_image, memory_cache_policy, disk_cache_policy, reporting);

                    combined_result.AddChildResult(child_context, this_context_results, output_context, output_context_mapping, dataset_stack, reporting);                
                end
            
            else
                reporting.Error('MimContextHierarchy:UnexpectedSituation', 'The requested plugin call cannot be made as I am unable to determine the relationship between the plugin context and the requested result context.');
            end
            
            % Note that the plugin completed successfully
            obj.ImageTemplates.NoteSuccessRunPlugin(plugin_name, output_context, reporting);
            
            % Allow pipelines to be run if required
            obj.Pipelines.RunPipelines(plugin_name, output_context, parameters, combined_result.GetPluginHasBeenRun, dataset_stack, dataset_uid, reporting);
        end
        
        function SaveEditedResultRecursive(obj, plugin_name, input_context, edited_result_image, plugin_info, dataset_stack, dataset_uid, reporting)
            % This function saves a manually edited result which plugins
            % may use to modify their results
            
            % Determines the context and context type requested by the calling function
            if isempty(input_context)
                reporting.Error('MimContextHierarchy:NoContextSpecified', 'When calling SaveEditedResult(), the contex of the input image must be specified.');
                input_context = obj.ContextDef.GetDefaultContext;
            end
            
            [plugin_context_set, plugin_context_set_mapping] = obj.GetContextSetMappings(plugin_info.Context);
        
            [input_context, input_context_set, input_context_mapping, input_context_set_mapping] = obj.GetContextMaps(input_context);
            
            % If the input and output contexts are of the same type, or if the
            % plugin context is of type 'Any', then proceed to save the results
            % for this context.
            if obj.ContextDef.ContextSetMatches(plugin_context_set, input_context_set)
                plugin_version = plugin_info.PluginVersion;
                obj.SaveEditedResult(plugin_name, input_context, edited_result_image, dataset_uid, plugin_version, reporting);

            % Otherwise, if the input's context set is lower in the hierarchy
            % than that of the plugin, then resize the input to match the plugin
            elseif input_context_set_mapping.IsOtherContextSetHigher(plugin_context_set_mapping)
                
                higher_context_mapping = input_context_mapping.Parent;
                if isempty(higher_context_mapping)
                    reporting.Error('MimContextHierarchy:UnexpectedSituation', 'The requested plugin call cannot be made as I am unable to determine the relationship between the plugin context and the requested result context.');
                end
                parent_context = higher_context_mapping.Context;
                parent_image_template = obj.ImageTemplates.GetTemplateImage(parent_context, dataset_stack, reporting);
                new_edited_image_for_context_image = edited_result_image.Copy;
                new_edited_image_for_context_image.ResizeToMatch(parent_image_template);
                obj.SaveEditedResultRecursive(plugin_name, parent_context, new_edited_image_for_context_image, plugin_info, dataset_stack, dataset_uid, reporting);


            % If the plugin's context set is lower in the hierarchy, then get
            % reduce the edited image input to each lower context in turn and save to each
            elseif plugin_context_set_mapping.IsOtherContextSetHigher(input_context_set_mapping)
                
                child_context_mappings = input_context_mapping.Children;
                
                for child_mapping = child_context_mappings
                    child_context = child_mapping{1}.Context;
                    
                    % Create a new image from the edited result, reduced to this
                    % context
                    new_edited_image_for_context_image = MimReduceResultToContext(edited_result_image, child_mapping{1}.Context, obj.ImageTemplates, dataset_stack, reporting);
                    
                    % Save this new image
                    obj.SaveEditedResultRecursive(plugin_name, child_context, new_edited_image_for_context_image, plugin_info, dataset_stack, dataset_uid, reporting);
                end

            else
                reporting.Error('MimContextHierarchy:UnexpectedSituation', 'The requested plugin call cannot be made as I am unable to determine the relationship between the plugin context and the requested result context.');
            end
        end        
    end
    
    methods (Access = private)
        function [context_set, context_set_mapping] = obj.GetContextSetMappings(obj, context)
            % Determines the type of context supported by the plugin

            context_set = context;
            if isempty(context_set)
                    context_set = obj.ContextDef.GetDefaultContextSet();
            end
            context_set_mapping = obj.ContextSets(char(context_set));
        end

        function [context, context_set, context_mapping, context_set_mapping] = GetContextMaps(obj, context)
            % Determines the context and context type requested by the calling function

            if isempty(context)
                context = obj.ContextDef.GetDefaultContext();
            end
            if obj.Contexts.isKey(char(context))
                context_mapping = obj.Contexts(char(context));
                context_set_mapping = context_mapping.ContextSet;
                context_set = context_set_mapping.ContextSet;
            else
                context_mapping = [];
                context_set_mapping = [];
                context_set = [];
            end
        end
        
        function output_image = GenerateImageFromResults(obj, result, plugin_class, linked_dataset_chooser, dataset_stack, reporting)
            template_callback = MimTemplateCallback(linked_dataset_chooser, dataset_stack, reporting);

            if isa(result, 'PTKImage')
                output_image = plugin_class.GenerateImageFromResults(result.Copy, template_callback, reporting);
            else
                output_image = plugin_class.GenerateImageFromResults(result, template_callback, reporting);
            end
        end

        
        function edited_cached_info = SaveEditedResult(obj, plugin_name, context, edited_result, dataset_uid, plugin_version, reporting)
            % Saves the result of a plugin after semi-automatic editing
            
            attributes = [];
            attributes.IgnoreDependencyChecks = false;
            attributes.IsEditedResult = true;
            attributes.PluginVersion = plugin_version;
            instance_identifier = PTKDependency(plugin_name, context, CoreSystemUtilities.GenerateUid, dataset_uid, attributes);
            edited_cached_info = obj.FrameworkAppDef.GetClassFactory.CreateDatasetStackItem(instance_identifier, PTKDependencyList(), false, false, reporting);
            edited_cached_info.MarkEdited();

            obj.DatasetDiskCache.SaveEditedResult(plugin_name, context, edited_result, edited_cached_info, reporting);
        end        
    end
end 

