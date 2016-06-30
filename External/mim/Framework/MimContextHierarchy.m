classdef MimContextHierarchy < CoreBaseClass
    % MimContextHierarchy. Part of the internal framework of the Pulmonary Toolkit.
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
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    
    properties
        ContextSets
        Contexts
        ContextDef
        
        DependencyTracker
        ImageTemplates
    end
    
    methods
        function obj = MimContextHierarchy(context_def, dependency_tracker, image_templates)
            obj.DependencyTracker = dependency_tracker;
            obj.ImageTemplates = image_templates;
            
            obj.ContextDef = context_def;
            obj.Contexts = context_def.GetContexts;
            obj.ContextSets = context_def.GetContextSets;
        end
        
        function [result, output_image, plugin_has_been_run, cache_info] = GetResult(obj, plugin_name, output_context, linked_dataset_chooser, plugin_info, plugin_class, dataset_uid, dataset_stack, force_generate_image, allow_results_to_be_cached, reporting)

            % Determines the context and context type requested by the calling function
            if isempty(output_context)
                output_context = obj.ContextDef.ChooseOutputContext(plugin_info.Context);
            end
            
            context_list = [];
            for next_output_context_set = CoreContainerUtilities.ConvertToSet(output_context);
                next_output_context = next_output_context_set{1};
                if obj.Contexts.isKey(char(next_output_context))
                    context_list{end + 1} = next_output_context;
                elseif obj.ContextSets.isKey(char(next_output_context))
                    context_set_mapping = obj.ContextSets(char(next_output_context));
                    context_mapping_list = context_set_mapping.ContextList;
                    context_list = [context_list, CoreContainerUtilities.GetFieldValuesFromSet(context_mapping_list, 'Context')];
                else
                    reporting.Error('MimContextHierarchy:UnknownOutputContext', 'I do not understand the requested output context.');
                end
            end
            
            plugin_has_been_run = false;
            result = [];
            output_image = [];
            cache_info = [];
            
            for next_output_context_set = context_list;
                next_output_context = next_output_context_set{1};
                combined_result = obj.GetResultRecursive(plugin_name, next_output_context, linked_dataset_chooser, plugin_info, plugin_class, dataset_uid, dataset_stack, force_generate_image, allow_results_to_be_cached, reporting);
                plugin_has_been_run = plugin_has_been_run | combined_result.GetPluginHasBeenRun;
                if numel(context_list) == 1
                    result = combined_result.GetResult;
                else
                    result.(char(next_output_context)) = combined_result.GetResult;
                end
                
                % Note for simplicity we return only one output image and
                % one cache info even if we are requesting multiple
                % results. This is because these outputs are really
                % additional aids and we save the caller the responsibility
                % of having to deal with a compound output. But there is an
                % argument for packing all the results consistently - we
                % would need to ensure this is correctly dealt with by the
                % caller
                if isempty(output_image)
                    output_image = combined_result.GetOutputImage;
                end
                if isempty(cache_info)
                    cache_info = combined_result.GetCacheInfo;
                end
            end
        end
        
        function SaveEditedResult(obj, plugin_name, input_context, edited_result_image, plugin_info, dataset_stack, dataset_uid, reporting)
            % This function saves a manually edited result which plugins
            % may use to modify their results
            
            % Determines the context and context type requested by the calling function
            if isempty(input_context)
                reporting.Error('MimContextHierarchy:NoContextSpecified', 'When calling SaveEditedResult(), the contex of the input image must be specified.');
                input_context = obj.ContextDef.GetDefaultContext;
            end
            
            obj.SaveEditedResultForAllContexts(plugin_name, input_context, edited_result_image, plugin_info, dataset_stack, dataset_uid, reporting);

            % Invalidate any image templates which depend on this plugin
            obj.ImageTemplates.InvalidateIfInDependencyList(plugin_name, input_context, reporting);
        end
        
    end
    
    methods (Access = private)
        function combined_result = GetResultRecursive(obj, plugin_name, output_context, linked_dataset_chooser, plugin_info, plugin_class, dataset_uid, dataset_stack, force_generate_image, allow_results_to_be_cached, reporting)
            
            obj.ImageTemplates.NoteAttemptToRunPlugin(plugin_name, output_context, reporting);

            % Determines the type of context supported by the plugin
            plugin_context_set = plugin_info.Context;
            if isempty(plugin_context_set)
                plugin_context_set = obj.ContextDef.GetDefaultContextSet;
            end
            plugin_context_set_mapping = obj.ContextSets(char(plugin_context_set));
            
            % Determines the context and context type requested by the calling function
            if isempty(output_context)
                output_context = obj.ContextDef.GetDefaultContext;
            end
            output_context_mapping = obj.Contexts(char(output_context));
            output_context_set_mapping = output_context_mapping.ContextSet;
            output_context_set = output_context_set_mapping.ContextSet;
            
            % If the input and output contexts are of the same type, or if the
            % plugin context is of type 'Any', then proceed to call the plugin
            if obj.ContextDef.ContextSetMatches(plugin_context_set, output_context_set)
                combined_result = obj.GetResultsForSameContext(plugin_name, output_context, output_context_mapping, linked_dataset_chooser, plugin_info, plugin_class, dataset_uid, dataset_stack, force_generate_image, allow_results_to_be_cached, reporting);
            
            % Otherwise, if the plugin's context set is higher in the hierarchy
            % than the requested output, then get the result for the higher
            % context and then extract out the desired context
            elseif output_context_set_mapping.IsOtherContextSetHigher(plugin_context_set_mapping)
                combined_result = obj.GetResultsForHigherContexts(plugin_name, output_context, output_context_mapping, linked_dataset_chooser, plugin_info, plugin_class, dataset_uid, dataset_stack, force_generate_image, allow_results_to_be_cached, reporting);
                
            % If the plugin's context set is lower in the hierarchy, then get
            % the plugin result for all lower contexts and concatenate the results
            elseif plugin_context_set_mapping.IsOtherContextSetHigher(output_context_set_mapping)
                combined_result = obj.GetResultsForLowerContexts(plugin_name, output_context, output_context_mapping, linked_dataset_chooser, plugin_info, plugin_class, dataset_uid, dataset_stack, force_generate_image, allow_results_to_be_cached, reporting);
            
            else
                reporting.Error('MimContextHierarchy:UnexpectedSituation', 'The requested plugin call cannot be made as I am unable to determine the relationship between the plugin context and the requested result context.');
            end
            
            % Allow the context manager to construct a template image from this
            % result if required
            obj.ImageTemplates.UpdateTemplates(plugin_name, output_context, combined_result.GetResult, combined_result.GetPluginHasBeenRun, combined_result.GetCacheInfo, reporting);
        end
        
        function combined_result = GetResultsForSameContext(obj, plugin_name, output_context, output_context_mapping, linked_dataset_chooser, plugin_info, plugin_class, dataset_uid, dataset_stack, force_generate_image, allow_results_to_be_cached, reporting);
            
            [result, plugin_has_been_run, cache_info] = obj.DependencyTracker.GetResult(plugin_name, output_context, linked_dataset_chooser, plugin_info, plugin_class, dataset_uid, dataset_stack, allow_results_to_be_cached, reporting);
            
            % If the plugin has been re-run, then we will generate an output
            % image, in order to create a new preview image
            if (plugin_info.GeneratePreview && plugin_has_been_run)
                force_generate_image = true;
            end
            
            % We generate an output image if requested, or if the plugin has been re-run (indictaing that we will need to generate a new preview image)
            if force_generate_image
                template_callback = MimTemplateCallback(linked_dataset_chooser, dataset_stack, reporting);
                
                if isa(result, 'PTKImage')
                    output_image = plugin_class.GenerateImageFromResults(result.Copy, template_callback, reporting);
                else
                    output_image = plugin_class.GenerateImageFromResults(result, template_callback, reporting);
                end
            else
                output_image = [];
            end
            
           combined_result = MimCombinedPluginResult(result, output_image, plugin_has_been_run, cache_info);
        end
        
        function context_results_combiner = GetResultsForHigherContexts(obj, plugin_name, output_context, output_context_mapping, linked_dataset_chooser, plugin_info, plugin_class, dataset_uid, dataset_stack, force_generate_image, allow_results_to_be_cached, reporting);
            context_results_combiner = MimContextResultCombiner(obj.ImageTemplates);
            higher_context_mapping = output_context_mapping.Parent;
            if isempty(higher_context_mapping)
                reporting.Error('MimContextHierarchy:UnexpectedSituation', 'The requested plugin call cannot be made as I am unable to determine the relationship between the plugin context and the requested result context.');
            end
            parent_context = higher_context_mapping.Context;
            this_context_results = obj.GetResultRecursive(plugin_name, higher_context_mapping.Context, linked_dataset_chooser, plugin_info, plugin_class, dataset_uid, dataset_stack, force_generate_image, allow_results_to_be_cached, reporting);
            context_results_combiner.AddParentResult(parent_context, this_context_results, output_context, output_context_mapping, dataset_stack, reporting);
        end
        
        function context_results_combiner = GetResultsForLowerContexts(obj, plugin_name, output_context, output_context_mapping, linked_dataset_chooser, plugin_info, plugin_class, dataset_uid, dataset_stack, force_generate_image, allow_results_to_be_cached, reporting);    
            context_results_combiner = MimContextResultCombiner(obj.ImageTemplates);
            child_context_mappings = output_context_mapping.Children;
            
            for child_mapping = child_context_mappings
                child_context = child_mapping{1}.Context;
                this_context_results = obj.GetResultRecursive(plugin_name, child_context, linked_dataset_chooser, plugin_info, plugin_class, dataset_uid, dataset_stack, force_generate_image, allow_results_to_be_cached, reporting);
                
                context_results_combiner.AddChildResult(child_context, this_context_results, output_context, output_context_mapping, dataset_stack, reporting);                
            end
        end
        
        
        function SaveEditedResultForAllContexts(obj, plugin_name, input_context, edited_result_image, plugin_info, dataset_stack, dataset_uid, reporting)
            
            % Determines the type of context supported by the plugin
            plugin_context_set = plugin_info.Context;
            if isempty(plugin_context_set)
                plugin_context_set = obj.ContextDef.GetDefaultContextSet;
            end
            plugin_context_set_mapping = obj.ContextSets(char(plugin_context_set));
            
            % Determines the context and context type requested by the calling function
            if isempty(input_context)
                input_context = obj.ContextDef.GetDefaultContext;
            end
            input_context_mapping = obj.Contexts(char(input_context));
            input_context_set_mapping = input_context_mapping.ContextSet;
            input_context_set = input_context_set_mapping.ContextSet;
            
            % If the input and output contexts are of the same type, or if the
            % plugin context is of type 'Any', then proceed to save the results
            % for this context.
            if obj.ContextDef.ContextSetMatches(plugin_context_set, input_context_set)
                obj.DependencyTracker.SaveEditedResult(plugin_name, input_context, edited_result_image, dataset_uid, reporting);

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
                obj.SaveEditedResultForAllContexts(plugin_name, parent_context, new_edited_image_for_context_image, plugin_info, dataset_stack, dataset_uid, reporting);


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
                    obj.SaveEditedResultForAllContexts(plugin_name, child_context, new_edited_image_for_context_image, plugin_info, dataset_stack, dataset_uid, reporting);
                end

            else
                reporting.Error('MimContextHierarchy:UnexpectedSituation', 'The requested plugin call cannot be made as I am unable to determine the relationship between the plugin context and the requested result context.');
            end
        end
    end    
end 

