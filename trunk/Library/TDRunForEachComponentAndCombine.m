function results = TDRunForEachComponentAndCombine(function_handle, image_in, mask, reporting)
    % TDRunForEachComponentAndCombine. Separates an image into components
    % according to the mask image, and runs a given function for each component.
    % The images are then recombined.
    %
    % Note: TDRunForEachComponentAndCombineMaskwise is similar, but is used for
    % running functions directly on the image masks
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    if islogical(mask.RawImage)
        results = function_handle(mask);
    else
        if ~isinteger(mask.RawImage)
            reporting.Error('TDRunForEachComponentAndCombine:NonIntegerMask', 'Mask input must be of integer type');
        end
        component_range = [max(1, mask.Limits(1)), mask.Limits(2)];
        first_run = true;
        for component_index = component_range(1) : component_range(2)
            masked_image = image_in.GetMaskedImage(mask, component_index);
            component_result = function_handle(masked_image);
            if first_run
                results = component_result;
                first_run = false;
            else
                results.ChangeSubImageWithMask(component_result, mask, component_index);
            end
        end
    end
end

