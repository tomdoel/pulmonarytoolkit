classdef PTKContextHierarchy < handle
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
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    
    properties
        ContextSets
        Contexts
        
        DependencyTracker
        ImageTemplates
        Reporting
    end
    
    methods
        function obj = PTKContextHierarchy(dependency_tracker, image_templates, reporting)
            obj.DependencyTracker = dependency_tracker;
            obj.ImageTemplates = image_templates;
            obj.Reporting = reporting;
            
            % Create the hierarchy of context types
            obj.ContextSets = containers.Map;
            full_set =  PTKContextSetMapping(PTKContextSet.OriginalImage, []);
            roi_set = PTKContextSetMapping(PTKContextSet.LungROI, full_set);
            single_lung_set = PTKContextSetMapping(PTKContextSet.SingleLung, roi_set);
            obj.ContextSets(char(PTKContextSet.OriginalImage)) = full_set;
            obj.ContextSets(char(PTKContextSet.LungROI)) = roi_set;
            obj.ContextSets(char(PTKContextSet.SingleLung)) = single_lung_set;
            
            % Create the hierarchy of contexts
            obj.Contexts = containers.Map;
            full_context =  PTKContextMapping(PTKContext.OriginalImage, full_set, 'PTKOriginalImage', []);
            roi_context = PTKContextMapping(PTKContext.LungROI, roi_set, 'PTKLungROI', full_context);
            left_lung_context = PTKContextMapping(PTKContext.LeftLung, single_lung_set, 'PTKGetContextForSingleLung', roi_context);
            right_lung_context = PTKContextMapping(PTKContext.RightLung, single_lung_set, 'PTKGetContextForSingleLung', roi_context);
            obj.Contexts(char(PTKContext.OriginalImage)) = full_context;
            obj.Contexts(char(PTKContext.LungROI)) = roi_context;
            obj.Contexts(char(PTKContext.LeftLung)) = left_lung_context;
            obj.Contexts(char(PTKContext.RightLung)) = right_lung_context;
        end
        
        function [result, output_image, plugin_has_been_run, cache_info] = GetResult(obj, plugin_name, output_context, linked_dataset_chooser, plugin_info, plugin_class, dataset_uid, dataset_stack, force_generate_image, reporting)
            
            obj.ImageTemplates.NoteAttemptToRunPlugin(plugin_name, output_context);
            
            [result, output_image, plugin_has_been_run, cache_info] = obj.GetResultForAllContexts(plugin_name, output_context, linked_dataset_chooser, plugin_info, plugin_class, dataset_uid, dataset_stack, force_generate_image, reporting);
            
                        
            % Allow the context manager to construct a template image from this
            % result if required
            obj.ImageTemplates.UpdateTemplates(plugin_name, output_context, result, plugin_has_been_run);
        end
    end
    
    methods (Access = private)
        function [result, output_image, plugin_has_been_run, cache_info] = GetResultForAllContexts(obj, plugin_name, output_context, linked_dataset_chooser, plugin_info, plugin_class, dataset_uid, dataset_stack, force_generate_image, reporting)
            % Determines the type of context supported by the plugin
            plugin_context_set = plugin_info.Context;
            if isempty(plugin_context_set)
                plugin_context_set = PTKContextSet.LungROI;
            end
            plugin_context_set_mapping = obj.ContextSets(char(plugin_context_set));
            
            % Determines the context and context type requested by the calling function
            if isempty(output_context)
                output_context = PTKContext.LungROI;
            end
            output_context_mapping = obj.Contexts(char(output_context));
            output_context_set_mapping = output_context_mapping.ContextSet;
            output_context_set = output_context_set_mapping.ContextSet;
            
            % If the input and output contexts are of the same type, then
            % proceed to call the plugin
            if plugin_context_set == output_context_set
                [result, plugin_has_been_run, cache_info] = obj.DependencyTracker.GetResult(plugin_name, output_context, linked_dataset_chooser, plugin_info, plugin_class, dataset_uid, dataset_stack, reporting);

                % If the plugin has been re-run, then we will generate an output
                % image, in order to create a new preview image
                if (plugin_info.GeneratePreview && plugin_has_been_run)
                   force_generate_image = true;
                end
                
                % We generate an output image if requested, or if the plugin has been re-run (indictaing that we will need to generate a new preview image)
                if force_generate_image
%                 if generate_image || cache_preview
                    template_callback = PTKTemplateCallback(linked_dataset_chooser, dataset_stack);
                    
                    if isa(result, 'PTKImage')
                        output_image = plugin_class.GenerateImageFromResults(result.Copy, template_callback, reporting);
%                         output_image = obj.GenerateImageFromResults(plugin_info, plugin_class, linked_dataset_chooser, dataset_stack, result.Copy);
                    else
                        output_image = plugin_class.GenerateImageFromResults(result, template_callback, reporting);
%                         output_image = obj.DependencyTracker.GenerateImageFromResults(plugin_info, plugin_class, linked_dataset_chooser, dataset_stack, result);
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
                [result, output_image, plugin_has_been_run, cache_info] = obj.GetResult(plugin_name, higher_context_mapping.Context, linked_dataset_chooser, plugin_info, plugin_class, dataset_uid, dataset_stack, force_generate_image, reporting);
                
                result = obj.ReduceResultToContext(result, output_context_mapping, linked_dataset_chooser, dataset_stack);
                output_image = obj.ReduceResultToContext(output_image, output_context_mapping, linked_dataset_chooser, dataset_stack);
                
            % If the plugin's context set is lower in the hierarchy, then get
            % run the plugin for all lower contexts and concatenate the results
            elseif plugin_context_set_mapping.IsOtherContextSetHigher(output_context_set_mapping)
                child_context_mappings = output_context_mapping.Children;
                result = [];
                output_image_template = obj.ImageTemplates.GetTemplateImage(output_context, linked_dataset_chooser, dataset_stack);
                cache_info = [];
                plugin_has_been_run = false;
                first_run = true;
                for child_mapping = child_context_mappings
                    child_context = child_mapping{1}.Context;
                    [this_result, this_output_image, this_plugin_has_been_run, this_cache_info] = obj.GetResult(plugin_name, child_context, linked_dataset_chooser, plugin_info, plugin_class, dataset_uid, dataset_stack, force_generate_image, reporting);
                    if first_run
                        if isempty(this_output_image)
                            output_image = [];
                        else
                            output_image = this_output_image.Copy;
                            output_image.ResizeToMatch(output_image_template);
                            output_image.Clear;
                        end
                        first_run = false;
                    end
                    
                    template_image_for_this_result = obj.ImageTemplates.GetTemplateImage(child_context, linked_dataset_chooser, dataset_stack);
                    
                    result.(char(child_context)) = this_result;
                    output_image.ChangeSubImageWithMask(this_output_image, template_image_for_this_result);
                    cache_info.(char(child_context)) = this_cache_info;
                    plugin_has_been_run = plugin_has_been_run || this_plugin_has_been_run;
                    
                end
            else
                reporting.Error('PTKContextHierarchy:UnexpectedSituation', 'The requested plugin call cannot be made as I am unable to determine the relationship between the plugin context and the requested result context.');
            end
        end
        
        function result = ReduceResultToContext(obj, full_result, context_mapping, linked_dataset_chooser, dataset_stack)
            if ~isa(full_result, 'PTKImage')
                result = full_result;
                return
            end
            template_image = obj.ImageTemplates.GetTemplateImage(context_mapping.Context, linked_dataset_chooser, dataset_stack);
            full_result.ResizeToMatch(template_image);
            result = full_result.Copy;
            
            if template_image.ImageExists
                result.Clear;
                result.ChangeSubImageWithMask(full_result, template_image, true);
            end
        end
    end
    
end 

