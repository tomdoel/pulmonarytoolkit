function result = MimExpandResultToContext(result, this_result, child_context, output_template_image, image_templates, dataset_stack, reporting)
    % MimExpandResultToContext. Part of the internal framework of the Pulmonary Toolkit.
    %
    %     This function is used to convert a plugin result from one context
    %     to a higher context
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
        
    if isempty(result)
        if isa(this_result, 'PTKImage')
            result = this_result.Copy;
            result.ResizeToMatch(output_template_image);
            result.Clear;
        else
            result = PTKCompositeResult;
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