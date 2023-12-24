function result = MimExpandResultToContext(result, this_result, child_context, output_template_image, image_templates, dataset_stack, reporting)
    % Convert a plugin result from one context to a higher context.
    %
    % For example, some plugins perform computations at a lobar level. Each result will be for its
    % lobar context. You use this funciton to combine these lobar context results into a lung context 
    % and this view the aggregate result for the whole lung.
    %
    %
    % .. Licence
    %    -------
    %    Part of the TD MIM Toolkit. https://github.com/tomdoel
    %    Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %    Distributed under the MIT licence. Please see website for details.
    %    
        
    if isempty(result)
        if isa(this_result, 'PTKImage')
            result = this_result.Copy();
            result.ResizeToMatch(output_template_image);
            result.Clear();
        else
            result = MimCompositeResult();
        end
    end
    
    if isa(this_result, 'PTKImage')
        % If the result is an image, we add the image to the
        % appropriate part of the final image using the context
        % mask.
        template_image_for_this_result = image_templates.GetTemplateImage(child_context, dataset_stack, reporting);
        result.ChangeSubImageWithMask(this_result, template_image_for_this_result);
    else
        % Otherwise, we add the result as a new field in the
        % composite results
        result.AddField(char(child_context), this_result);
    end
end
