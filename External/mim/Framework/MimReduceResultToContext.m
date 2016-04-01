function result = MimReduceResultToContext(full_result, child_context, image_templates, dataset_stack, reporting)
    % MimReduceResultToContext. Part of the internal framework of the Pulmonary Toolkit.
    %
    %     This function is used to convert a plugin result from one context
    %     to a lower context
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
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
    
    template_image = image_templates.GetTemplateImage(child_context, dataset_stack, reporting);
    
    % Make a copy before we resize
    result = full_result.Copy;
    result.ResizeToMatch(template_image);
    
    if template_image.ImageExists
        result.Clear;
        result.ChangeSubImageWithMask(full_result, template_image, true);
    end
end