function results_image = PTKGetAirwayImageFromCentreline(label_bronchi, airway_root, template, colour_by_segment_index)
    % PTKGetAirwayImageFromCentreline. Generates an image of the airways
    %     coloured according to a number of subtrees. The start branch of the
    %     subtrees are specified in label_bronchi. Any bronchi serving more than
    %     one subtree is coloured grey.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    results_image = template.BlankCopy;
    
    all_centreline_voxels = [];
    segment_centreline_voxels_extended = [];
    for label_bronchus_index = 1 : length(label_bronchi)
        centreline_voxels = PTKTreeUtilities.GetCentrelineVoxelsForTheseBranchesExtended(label_bronchi(label_bronchus_index), template);
        segment_centreline_voxels_extended{label_bronchus_index} = centreline_voxels;
        all_centreline_voxels = [all_centreline_voxels; centreline_voxels];
    end
    all_centreline_voxels = unique(all_centreline_voxels);
    
    results_image_raw = zeros(template.ImageSize, 'uint8');
    
    bronchi_to_do = airway_root;
    
    while ~isempty(bronchi_to_do)
        airway_bronchus = bronchi_to_do(end);
        bronchi_to_do(end) = [];
        voxel_indices_in_segment = airway_bronchus.GetAllAirwayPoints;
        voxel_indices_in_segment = template.GlobalToLocalIndices(voxel_indices_in_segment);
        
        label_bronchus_indices = [];
        
        number_of_centreline_points_in_bronchus = sum(ismember(all_centreline_voxels, voxel_indices_in_segment));
        
        % Search through all segments to see if the voxels match a bronchus
        % Only match bronchi if more than 50% of the centreline voxels in the
        % bronchus are part of this bronchus
        for label_bronchus_index = 1 : length(label_bronchi)
            number_of_centreline_points_in_bronchus_for_this_centreline = sum(ismember(segment_centreline_voxels_extended{label_bronchus_index}, voxel_indices_in_segment));
            if number_of_centreline_points_in_bronchus_for_this_centreline > (number_of_centreline_points_in_bronchus/2)
                label_bronchus_indices = [label_bronchus_indices, label_bronchus_index];
            end
        end
        
        % Colour the bronchus if it matches only one segment; otherwise colour it grey 
        if length(label_bronchus_indices) == 1
            if colour_by_segment_index
                colour = label_bronchus_indices;
            else
                colour = 1 + mod(label_bronchus_indices - 1, 6);
            end
        else
            if colour_by_segment_index
                colour = 0;
            else
                colour = 7;
            end
        end
        results_image_raw(voxel_indices_in_segment) = colour;
        
        bronchi_to_do = [bronchi_to_do airway_bronchus.Children];
    end
    
    results_image.ChangeRawImage(results_image_raw);
    results_image.ImageType = PTKImageType.Colormap;
end