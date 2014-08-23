function masked_ventilated_volume = PTKGetBorderedVentilatedRegions(ventilation_mask, lung_mask)
    % PTKGetBorderedVentilatedRegions. Masks ventilated regions and then draws a
    %     border
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.

    % Resize the lung mask
    lung_mask = lung_mask.Copy;
    lung_mask.ResizeToMatch(ventilation_mask);
    
    % Create a new ventilation image using the mask
    masked_ventilated_volume_raw = uint8((ventilation_mask.RawImage > 0) & (lung_mask.RawImage > 0));
    
    % Add a border with label 3
    border = PTKGetSurfaceFromSegmentation(masked_ventilated_volume_raw, PTKImageOrientation.Coronal);
    masked_ventilated_volume_raw(border) = 3;
    
    masked_ventilated_volume = ventilation_mask.BlankCopy;
    masked_ventilated_volume.ChangeRawImage(masked_ventilated_volume_raw);
end