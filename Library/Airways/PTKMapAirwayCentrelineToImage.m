function [airway_mapped_image, airway_tree_root] = PTKMapAirwayCentrelineToImage(centreline_results, airway_image)
    % PTKMapAirwayCentrelineToImage.
    %
    %
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    
    airway_mapped_image_raw = zeros(airway_image.ImageSize, 'uint16');
    airway_mapped_image = airway_image.BlankCopy;
    
    airway_tree_root = centreline_results.AirwayCentrelineTree;
    centreline_bronchi_to_do = PTKStack(airway_tree_root);
    
    bronchus_index = uint16(1);
    
    
    number_of_branches = airway_tree_root.CountBranches;
    
    parent_map = cell(number_of_branches, 1);
    child_map = cell(number_of_branches, 1);
    
    % Assign a label to each centreline bronchus, and mark the label
    % image with that index at each centreline voxel
    while ~centreline_bronchi_to_do.IsEmpty
        next_centreline_bronchus = centreline_bronchi_to_do.Pop;
        voxels = PTKTreeUtilities.GetCentrelineVoxelsForTheseBranches(next_centreline_bronchus, airway_image);
        airway_mapped_image_raw(voxels) = bronchus_index;
        next_centreline_bronchus.BronchusIndex = bronchus_index;
        
        % Add parent index to this branch, and add this branch index to
        % parent's child indices
        if ~isempty(next_centreline_bronchus.Parent)
            parent = next_centreline_bronchus.Parent;
            parent_index = parent.BronchusIndex;
            parent_map{bronchus_index} = parent_index;
            child_map{parent_index} = [child_map{parent_index}, bronchus_index];
        end
        
        centreline_bronchi_to_do.Push(next_centreline_bronchus.Children);
        bronchus_index = bronchus_index + 1;
    end
    
    % Find the nearest centreline point for every voxel in the airway
    % segmentation, and assign every voxel to that label
    [~, nearest_centreline_index] = bwdist(airway_mapped_image_raw > 0);
    airway_mapped_image_raw(:) = airway_mapped_image_raw(nearest_centreline_index(:));
    airway_mapped_image_raw(airway_image.RawImage ~= 1) = 0;
    airway_mapped_image.ChangeRawImage(airway_mapped_image_raw);
    
    
    airway_mapped_image.ChangeColorLabelParentChildMap(parent_map, child_map)
end

