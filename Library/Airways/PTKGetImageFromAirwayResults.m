function airway_image = PTKGetImageFromAirwayResults(airway_tree, template_image, suppress_small_structures, reporting)
    % Create an image of the segmented airways
    %
    % This function takes the airway results structure from the PTKAirways
    % plugin and creates an image of the segmented airways.
    %
    %
    % .. Licence
    %    -------
    %    Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %    Author: Tom Doel, 2012.  www.tomdoel.com
    %    Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    image_size = template_image.ImageSize;
    
    airway_image_raw = zeros(image_size, 'uint8');
    
    segments_to_do = airway_tree;
    while ~isempty(segments_to_do)
        segment = segments_to_do(end);
        segments_to_do(end) = [];
        voxels = segment.GetAllAirwayPoints;
        
        show_this_segment = (~suppress_small_structures) || (numel(voxels) > 10) || (~isempty(segment.Children));
        
        if show_this_segment
            voxels = template_image.GlobalToLocalIndices(voxels);
            airway_image_raw(voxels) = 1;
        end
        segments_to_do = [segments_to_do, segment.Children];
    end
    
    airway_image = template_image.BlankCopy();
    airway_image.ChangeRawImage(airway_image_raw);
    airway_image.ImageType = PTKImageType.Colormap;
end
