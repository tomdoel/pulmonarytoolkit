function mask = PTKGetLobeROI(lobe_mask, context, reporting)
    % PTKGetLobeROI. Extracts a region of interest for one of the lobes.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    mask = lobe_mask.BlankCopy;
    
    if context == PTKContext.LeftUpperLobe
        colormap_index = PTKColormapLabels.LeftUpperLobe;
    elseif context == PTKContext.LeftLowerLobe
        colormap_index = PTKColormapLabels.LeftLowerLobe;
    elseif  context == PTKContext.RightUpperLobe
        colormap_index = PTKColormapLabels.RightUpperLobe;
    elseif  context == PTKContext.RightMiddleLobe
        colormap_index = PTKColormapLabels.RightMiddleLobe;
    elseif  context == PTKContext.RightLowerLobe
        colormap_index = PTKColormapLabels.RightLowerLobe;
    else
        reporting.Error('PTKGetLobeROI:UnknownContext', ['The context ' char(context) ' is unknown.']);
    end
    mask.ChangeRawImage(lobe_mask.RawImage == colormap_index);
    mask.CropToFitWithBorder(5);
end

