function airway_image = TDGetImageFromAirwayResults(airway_tree, template_image, reporting)
    % TDGetImageFromAirwayResults. Creates an image of the segmented airways
    %
    %     This function takes the airway results structure from the TDAirways
    %     plugin and creates an image of the segmented airways.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    image_size = template_image.ImageSize;
    
    airway_image_raw = zeros(image_size, 'uint8');
    
    segments_to_do = airway_tree;
    while ~isempty(segments_to_do)
        segment = segments_to_do(end);
        segments_to_do(end) = [];
        voxels = segment.GetAllAirwayPoints;
        voxels = template_image.GlobalToLocalIndices(voxels);
        airway_image_raw(voxels) = 1;
        segments_to_do = [segments_to_do, segment.Children];
    end
    
    airway_image = template_image.BlankCopy;
    airway_image.ChangeRawImage(airway_image_raw);
    airway_image.ImageType = TDImageType.Colormap;
end

