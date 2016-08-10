classdef PTKContextHierarchy < CoreBaseClass
    % PTKContextHierarchy. Part of the internal framework of the Pulmonary Toolkit.
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
        function obj = PTKContextHierarchy(context_def, dependency_tracker, image_templates)
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
                    reporting.Error('PTKContextHierarchy:UnknownOutputContext', 'I do not understand the requested output context.');
                end
            end
            
            plugin_has_been_run = false;
            result = [];
            for next_output_context_set = context_list;
                next_output_context = next_output_context_set{1};
                [next_result, output_image, next_plugin_has_been_run, cache_info] = obj.GetResultRecursive(plugin_name, next_output_context, linked_dataset_chooser, plugin_info, plugin_class, dataset_uid, dataset_stack, force_generate_image, allow_results_to_be_cached, reporting);
                plugin_has_been_run = plugin_has_been_run | next_plugin_has_been_run;
                if numel(context_list) == 1
                    result = next_result;
                else
                    result.(char(next_output_context)) = next_result;
                end
            end
        end
        
        function SaveEditedResult(obj, plugin_name, input_context, edited_result_image, plugin_info, dataset_stack, dataset_uid, reporting)
            % This function saves a manually edited result which plugins
            % may use to modify their results
            
            % Determines the context and context type requested by the calling function
            if isempty(input_context)
                reporting.Error('PTKContextHierarchy:NoContextSpecified', 'When calling SaveEditedResult(), the contex of the input image must be specified.');
                input_context = obj.ContextDef.GetDefaultContext;
            end
            
            obj.SaveEditedResultForAllContexts(plugin_name, input_context, edited_result_image, plugin_info, dataset_stack, dataset_uid, reporting);

            % Invalidate any image templates which depend on this plugin
            obj.ImageTemplates.InvalidateIfInDependencyList(plugin_name, input_context, reporting);
        end
        
    end
    
    methods (Access = private)
        function [result, output_image, plugin_has_been_run, cache_info] = GetResultRecursive(obj, plugin_name, output_context, linked_dataset_chooser, plugin_info, plugin_class, dataset_uid, dataset_stack, force_generate_image, allow_results_to_be_cached, reporting)
            obj.ImageTemplates.NoteAttemptToRunPlugin(plugin_name, output_context, reporting);
            
            [result, output_image, plugin_has_been_run, cache_info] = obj.GetResultForAllContexts(plugin_name, output_context, linked_dataset_chooser, plugin_info, plugin_class, dataset_uid, dataset_stack, force_generate_image, allow_results_to_be_cached, reporting);
            
            % Allow the context manager to construct a template image from this
            % result if required
            obj.ImageTemplates.UpdateTemplates(plugin_name, output_context, result, plugin_has_been_run, cache_info, reporting);
        end
        
        function [result, output_image, plugin_has_been_run, cache_info] = GetResultForAllContexts(obj, plugin_name, output_context, linked_dataset_chooser, plugin_info, plugin_class, dataset_uid, dataset_stack, force_generate_image, allow_results_to_be_cached, reporting)
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
                [result, plugin_has_been_run, cache_info] = obj.DependencyTracker.GetResult(plugin_name, output_context, linked_dataset_chooser, plugin_info, plugin_class, dataset_uid, dataset_stack, allow_results_to_be_cached, reporting);

                % If the plugin has been re-run, then we will generate an output
                % image, in order to create a new preview image
                if (plugin_info.GeneratePreview && plugin_has_been_run)
                   force_generate_image = true;
                end
                
                % We generate an output image if requested, or if the plugin has been re-run (indictaing that we will need to generate a new preview image)
                if force_generate_image
                    template_callback = PTKTemplateCallback(linked_dataset_chooser, dataset_stack, reporting);
                    
                    if isa(result, 'PTKImage')
                        output_image = plugin_class.GenerateImageFromResults(result.Copy, template_callback, reporting);
                    else
                        output_image = plugin_class.GenerateImageFromResults(result, template_callback, reporting);
                    end
                else
                    output_image = [];
                end
                
            
            % Otherwise, if the plugin's context set is higher in the hierarchy
            % than the requested output, then get the result for the higher
            % context and then extract out the desired context
            elseif output_context_set_mapping.IsOtherContextSetHigher(plugin_context_set_mapping)
                higher_context_mapping = output_context_mapping.Parent;
                if isempty(higher_context_mapping)
                    reporting.Error('PTKContextHierarchy:UnexpectedSituation', 'The requested plugin call cannot be made as I am unable to determine the relationship between the plugin context and the requested result context.');
                end
                [result, output_image, plugin_has_been_run, cache_info] = obj.GetResultRecursive(plugin_name, higher_context_mapping.Context, linked_dataset_chooser, plugin_info, plugin_class, dataset_uid, dataset_stack, force_generate_image, allow_results_to_be_cached, reporting);
                
                result = obj.ReduceResultToContext(result, output_context_mapping, dataset_stack, reporting);
                if ~isempty(output_image)
                    output_image = obj.ReduceResultToContext(output_image, output_context_mapping, dataset_stack, reporting);
                end
                
            % If the plugin's context set is lower in the hierarchy, then get
            % the plugin result for all lower contexts and concatenate the results
            elseif plugin_context_set_mapping.IsOtherContextSetHigher(output_context_set_mapping)
                child_context_mappings = output_context_mapping.Children;
                output_image_template = obj.ImageTemplates.GetTemplateImage(output_context, dataset_stack, reporting);
                cache_info = PTKCompositeResult;
                plugin_has_been_run = false;
                first_run = true;
                for child_mapping = child_context_mappings
                    child_context = child_mapping{1}.Context;
                    [this_result, this_output_image, this_plugin_has_been_run, this_cache_info] = obj.GetResultRecursive(plugin_name, child_context, linked_dataset_chooser, plugin_info, plugin_class, dataset_uid, dataset_stack, force_generate_image, allow_results_to_be_cached, reporting);
                    if first_run
                        if isa(this_result, 'PTKImage')
                            result = this_result.Copy;
                            result.ResizeToMatch(output_image_template);
                            result.Clear;
                        else
                            result = PTKCompositeResult;
                        end
                        
                        if isempty(this_output_image)
                            output_image = [];
                        else
                            output_image = this_output_image.Copy;
                            output_image.ResizeToMatch(output_image_template);
                            output_image.Clear;
                        end
                        first_run = false;
                    end
                    
                    template_image_for_this_result = obj.ImageTemplates.GetTemplateImage(child_context, dataset_stack, reporting);
                    
                    if isa(this_result, 'PTKImage')
                        % If the result is an image, we add the image to the
                        % appropriate part of the final image using the context
                        % mask.
                        result.ChangeSubImageWithMask(this_result, template_image_for_this_result);
                    else
                        % Otherwise, we add the result as a new field in the
                        % composite results
                        result.AddField(char(child_context), this_result);
                    end
                    
                    if ~isempty(output_image) && ~isempty(this_output_image)
                        output_image.ChangeSubImageWithMask(this_output_image, template_image_for_this_result);
                    end
                    cache_info.AddField(char(child_context), this_cache_info);
                    plugin_has_been_run = plugin_has_been_run || this_plugin_has_been_run;
                    
                end
            else
                reporting.Error('PTKContextHierarchy:UnexpectedSituation', 'The requested plugin call cannot be made as I am unable to determine the relationship between the plugin context and the requested result context.');
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
                plugin_version = plugin_info.PluginVersion;
                obj.DependencyTracker.SaveEditedResult(plugin_name, input_context, edited_result_image, dataset_uid, plugin_version, reporting);

            % Otherwise, if the input's context set is lower in the hierarchy
            % than that of the plugin, then resize the input to match the plugin
            elseif input_context_set_mapping.IsOtherContextSetHigher(plugin_context_set_mapping)
                
                higher_context_mapping = input_context_mapping.Parent;
                if isempty(higher_context_mapping)
                    reporting.Error('PTKContextHierarchy:UnexpectedSituation', 'The requested plugin call cannot be made as I am unable to determine the relationship between the plugin context and the requested result context.');
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
                    new_edited_image_for_context_image = obj.ReduceResultToContext(edited_result_image, child_mapping{1}, dataset_stack, reporting);
                    
                    % Save this new image
                    obj.SaveEditedResultForAllContexts(plugin_name, child_context, new_edited_image_for_context_image, plugin_info, dataset_stack, dataset_uid, reporting);
                end

            else
                reporting.Error('PTKContextHierarchy:UnexpectedSituation', 'The requested plugin call cannot be made as I am unable to determine the relationship between the plugin context and the requested result context.');
            end
        end
        
        
        function result = ReduceResultToContext(obj, full_result, context_mapping, dataset_stack, reporting)
            % Extracts out a result for a particular context
            
            % If the result is a composite result, then get the result for this
            % context            
            if isa(full_result, 'PTKCompositeResult') && full_result.IsField(char(context_mapping.Context))
                result = full_result.(char(context_mapping.Context));
                return
            end
            
            % Otherwise, we can only perform the reduction if the result it a
            % PTKImage
            if ~isa(full_result, 'PTKImage')
                result = full_result;
                return
            end
            
            % Resize an image to match the template for a particular context,
            % and extract out only the part of the image specified by the
            % context map
            
            template_image = obj.ImageTemplates.GetTemplateImage(context_mapping.Context, dataset_stack, reporting);
            
            % Make a copy before we resize
            result = full_result.Copy;
            result.ResizeToMatch(template_image);
            
            if template_image.ImageExists
                result.Clear;
                result.ChangeSubImageWithMask(full_result, template_image, true);
            end
        end
    end
    
end 

