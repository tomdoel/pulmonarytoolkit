function mask = PTKGetLungROIFromLeftAndRightLungs(left_and_right_lung_mask, context, reporting)
    % PTKGetLungROIFromLeftAndRightLungs. Extracts a region of interest for the left or right lung given the original image and the left and right lung mask.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    mask = left_and_right_lung_mask.BlankCopy;
    
    if context == PTKContext.RightLung
        colormap_index = PTKColormapLabels.RightLung;
    elseif context == PTKContext.LeftLung
        colormap_index = PTKColormapLabels.LeftLung;
    else
        reporting.Error('PTKGetLungROIFromLeftAndRightLungs:UnknownContext', ['The context ' char(context) ' is unknown.']);
    end
    mask.ChangeRawImage(left_and_right_lung_mask.RawImage == colormap_index);
    mask.CropToFitWithBorder(5);
end

