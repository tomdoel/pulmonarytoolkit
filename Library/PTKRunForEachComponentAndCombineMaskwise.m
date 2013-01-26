function results = TDRunForEachComponentAndCombineMaskwise(function_handle, mask, reporting)
    % TDRunForEachComponentAndCombineMaskwise. Separates a mask into components
    % and runs a given function for each component. The result masks are then
    % recombined, and given their original colour value.
    %
    % Note: TDRunForEachComponentAndCombine is similar, but is used for
    % running functions on images which consist of several components defined by
    % masks
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    if ~isinteger(mask.RawImage)
        reporting.Error('TDRunForEachComponentAndCombineMaskwise:NonIntegerMask', 'Mask input must be of integer type');
    end
    
    component_range = [max(1, mask.Limits(1)), mask.Limits(2)];
    first_run = true;
    for component_index = component_range(1) : component_range(2)
        masked_image = mask.GetMask(component_index);
        component_result = function_handle(masked_image);
        if ~islogical(component_result.RawImage)
            reporting.Error('TDRunForEachComponentAndCombineMaskwise:NonBooleanResult', 'Expecting the function result to be a boolean mask');
        end
        component_result.ChangeRawImage(component_index.*uint8(component_result.RawImage));
        if first_run
            results = component_result;
            first_run = false;
        else
            results.ChangeSubImageWithMask(component_result, component_result, component_index);
        end
    end
end

