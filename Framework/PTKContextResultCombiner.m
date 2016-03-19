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
    end
    
    methods
        function obj = PTKContextResultCombiner(image_templates)
            obj.ImageTemplates = image_templates;
        end
        
        function AddParentResult(obj, parent_context, this_result, this_output_image, this_cache_info, output_context, output_context_mapping, dataset_stack, reporting)
            obj.Result = obj.ReduceResultToContext(this_result, output_context_mapping.Context, dataset_stack, reporting);
            if ~isempty(this_output_image)
                obj.OutputImage = obj.ReduceResultToContext(this_output_image, output_context, dataset_stack, reporting);
            else
                obj.OutputImage = [];
            end
            obj.CacheInfo = this_cache_info;
        end
        
        function AddChildResult(obj, child_context, this_result, this_output_image, this_cache_info, output_context, output_context_mapping, dataset_stack, reporting)
            obj.Result = obj.ExpandResultToContext(obj.Result, this_result, child_context, output_context, dataset_stack, reporting);
            if ~isempty(this_output_image)
                obj.OutputImage = obj.ExpandResultToContext(obj.OutputImage, this_output_image, child_context, output_context, dataset_stack, reporting);
            else
                obj.OutputImage = [];
            end
            if isempty(obj.CacheInfo)
                obj.CacheInfo = PTKCompositeResult;
            end
            obj.CacheInfo.AddField(char(child_context), this_cache_info);            
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
    end
    
    methods (Access = private)
        
        function result = ExpandResultToContext(obj, result, this_result, child_context, output_context, dataset_stack, reporting)
            if isempty(obj.OutputImageTemplate)
                obj.OutputImageTemplate = obj.ImageTemplates.GetTemplateImage(output_context, dataset_stack, reporting);
            end
            
            if isempty(result)
                if isa(this_result, 'PTKImage')
                    result = this_result.Copy;
                    result.ResizeToMatch(obj.OutputImageTemplate);
                    result.Clear;
                else
                    result = PTKCompositeResult;
                end
            end
            
            if isa(this_result, 'PTKImage')
                % If the result is an image, we add the image to the
                % appropriate part of the final image using the context
                % mask.
                template_image_for_this_result = obj.ImageTemplates.GetTemplateImage(child_context, dataset_stack, reporting);
                result.ChangeSubImageWithMask(this_result, template_image_for_this_result);
            else
                % Otherwise, we add the result as a new field in the
                % composite results
                result.AddField(char(child_context), this_result);
            end            
        end
        
        function result = ReduceResultToContext(obj, full_result, child_context, dataset_stack, reporting)
            % Extracts out a result for a particular context
            
            % If the result is a composite result, then get the result for this
            % context            
            if isa(full_result, 'PTKCompositeResult') && full_result.IsField(char(child_context))
                result = full_result.(char(child_context));
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
            
            template_image = obj.ImageTemplates.GetTemplateImage(child_context, dataset_stack, reporting);
            
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

