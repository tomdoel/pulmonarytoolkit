function results_image = PTKGetPrunedAirwayImageFromCentreline(label_bronchi, airway_root, template, colour_by_segment_index)
    % PTKGetPrunedAirwayImageFromCentreline. 
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    airways_image = PTKGetAirwayImageFromCentreline(label_bronchi, airway_root, template, colour_by_segment_index);
    
    child_bronchi = [];
    for label_bronchus_index = 1 : length(label_bronchi)
        child_bronchi = [child_bronchi, label_bronchi(label_bronchus_index).Children];
    end
    
    airways_image_child = PTKGetAirwayImageFromCentreline(child_bronchi, airway_root, template, colour_by_segment_index);
    
    results_image = airways_image;
    results_image_raw = results_image.RawImage;
    results_image_raw(airways_image_child.RawImage ~= 7) = 0;
    results_image.ChangeRawImage(results_image_raw);
    results_image.ImageType = PTKImageType.Colormap;
end