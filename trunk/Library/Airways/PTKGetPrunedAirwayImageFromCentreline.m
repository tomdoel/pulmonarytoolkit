function results_image = PTKGetPrunedAirwayImageFromCentreline(parent_bronchi, child_bronchi, airway_root, template, colour_by_segment_index)
    % PTKGetPrunedAirwayImageFromCentreline. 
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    airways_image = PTKGetAirwayImageFromCentreline(parent_bronchi, airway_root, template, colour_by_segment_index);
    airways_image_child = PTKGetAirwayImageFromCentreline(child_bronchi, airway_root, template, colour_by_segment_index);
    
    results_image = airways_image.BlankCopy;
    results_image_raw = airways_image.RawImage;
    results_image_raw(airways_image_child.RawImage ~= 7) = 0;
    results_image.ChangeRawImage(results_image_raw);
    results_image.ImageType = PTKImageType.Colormap;
end