classdef PTKContextResultCombiner < CoreBaseClass
    % PTKContextResultCombiner. Part of the internal framework of the Pulmonary Toolkit.
    %
    %     This class is used to build up aggregate results combined from results for different contexts
    %
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    
    properties (Access = private)
        FirstRun = true
        CacheInfo
        ImageTemplates
        OutputImage
        OutputImageTemplate
        Result
        PluginHasBeenRun = false
    end
    
    methods
        function obj = PTKContextResultCombiner(image_templates)
            obj.ImageTemplates = image_templates;
        end
        
        function AddParentResult(obj, parent_context, this_context_results, output_context, output_context_mapping, dataset_stack, reporting)
            obj.Result = PTKReduceResultToContext(this_context_results.GetResult, output_context_mapping.Context, obj.ImageTemplates, dataset_stack, reporting);
            if ~isempty(this_context_results.GetOutputImage)
                obj.OutputImage = PTKReduceResultToContext(this_context_results.GetOutputImage, output_context, obj.ImageTemplates, dataset_stack, reporting);
            else
                obj.OutputImage = [];
            end
            obj.CacheInfo = this_context_results.GetCacheInfo;
            obj.PluginHasBeenRun = obj.PluginHasBeenRun || this_context_results.GetPluginHasBeenRun;
        end
        
        function AddChildResult(obj, child_context, this_context_results, output_context, output_context_mapping, dataset_stack, reporting)
            if isempty(obj.OutputImageTemplate)
                obj.OutputImageTemplate = obj.ImageTemplates.GetTemplateImage(output_context, dataset_stack, reporting);
            end
            
            obj.Result = PTKExpandResultToContext(obj.Result, this_context_results.GetResult, child_context, obj.OutputImageTemplate, obj.ImageTemplates, dataset_stack, reporting);
            if ~isempty(this_context_results.GetOutputImage)
                obj.OutputImage = PTKExpandResultToContext(obj.OutputImage, this_context_results.GetOutputImage, child_context, obj.OutputImageTemplate, obj.ImageTemplates, dataset_stack, reporting);
            else
                obj.OutputImage = [];
            end
            if isempty(obj.CacheInfo)
                obj.CacheInfo = PTKCompositeResult;
            end
            obj.CacheInfo.AddField(char(child_context), this_context_results.GetCacheInfo);
            obj.PluginHasBeenRun = obj.PluginHasBeenRun || this_context_results.GetPluginHasBeenRun;            
        end

        function result = GetResult(obj)
            result = obj.Result;
        end
        
        function result = GetCacheInfo(obj)
            result = obj.CacheInfo;
        end
        
        function result = GetOutputImage(obj)
            result = obj.OutputImage;
        end
        
        function has_been_run = GetPluginHasBeenRun(obj)
            has_been_run = obj.PluginHasBeenRun;
        end
        
    end
end 

