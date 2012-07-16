function results_image = TDColourBranchesByLobe(start_branches, airway_tree, template)
    % TDColourBranchesByLobe. Given a set of labelled branches, this creates an output image with all the subtrees coloured by lobe
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %

    start_segment = start_branches.Trachea;
    left_upper_startindices = start_branches.LeftUpper;
    left_lower_startindices = start_branches.LeftLower;
    right_upper_startindices = start_branches.RightUpper;
    right_mid_startindices = start_branches.RightMid;
    right_lower_startindices = start_branches.RightLower;
    uncertain_segments = start_branches.LeftUncertain;

    % Get voxels for lobes
    left_lower_voxels = GetVoxelsForTheseBranches(left_lower_startindices, template);
    left_upper_voxels = GetVoxelsForTheseBranches(left_upper_startindices, template);
    right_lower_voxels = GetVoxelsForTheseBranches(right_lower_startindices, template);
    right_mid_voxels = GetVoxelsForTheseBranches(right_mid_startindices, template);
    right_upper_voxels = GetVoxelsForTheseBranches(right_upper_startindices, template);
    
    uncertain_voxels = GetVoxelsForTheseBranches(uncertain_segments, template);

    left_lower_voxels_extended = GetVoxelsForTheseBranchesExtended(left_lower_startindices, template);
    left_upper_voxels_extended = GetVoxelsForTheseBranchesExtended(left_upper_startindices, template);
    right_lower_voxels_extended = GetVoxelsForTheseBranchesExtended(right_lower_startindices, template);
    right_mid_voxels_extended = GetVoxelsForTheseBranchesExtended(right_mid_startindices, template);
    right_upper_voxels_extended = GetVoxelsForTheseBranchesExtended(right_upper_startindices, template);
    
    uncertain_voxels_extended = GetVoxelsForTheseBranchesExtended(uncertain_segments, template);
    
    results_image = zeros(template.ImageSize, 'uint8');
    
    full_tree_voxels = CentrelinePointsToLocalIndices(start_segment.GetCentrelineTree, template);
    
    results_image(full_tree_voxels) = 7;
    
    results_image(right_upper_voxels) = 1;
    results_image(right_mid_voxels) = 2;
    results_image(right_lower_voxels) = 4;
    results_image(left_upper_voxels) = 5;
    results_image(left_lower_voxels) = 6;
    
    results_image(uncertain_voxels) = 3;

    % Label segments by skeleton
    results_image(:) = 0;

    segments_to_do = airway_tree;
    
    while ~isempty(segments_to_do)
        segment = segments_to_do(end);
        segments_to_do(end) = [];
        voxel_indices_in_segment = segment.GetAllAirwayPoints;
        voxel_indices_in_segment = template.GlobalToLocalIndices(voxel_indices_in_segment);
        
        lobe_indices = [];
        if any(ismember(right_upper_voxels_extended, voxel_indices_in_segment))
            lobe_indices = [lobe_indices, 1];
        end
        if any(ismember(right_mid_voxels_extended, voxel_indices_in_segment))
            lobe_indices = [lobe_indices, 2];
        end
        if any(ismember(right_lower_voxels_extended, voxel_indices_in_segment))
            lobe_indices = [lobe_indices, 4];
        end
        if any(ismember(left_upper_voxels_extended, voxel_indices_in_segment))
            lobe_indices = [lobe_indices, 5];
        end
        if any(ismember(left_lower_voxels_extended, voxel_indices_in_segment))
            lobe_indices = [lobe_indices, 6];
        end
        
        if any(ismember(uncertain_voxels_extended, voxel_indices_in_segment))
            lobe_indices = [lobe_indices, 3];
        end
        
        if length(lobe_indices) == 1
            results_image(voxel_indices_in_segment) = lobe_indices;
        end
        
        segments_to_do = [segments_to_do segment.Children];
    end
    
end

function voxels = GetVoxelsForTheseBranches(start_indices, template)
    voxels = [];
    for index = 1 : numel(start_indices)
        voxels = cat(2, voxels, CentrelinePointsToLocalIndices(start_indices(index).GetCentrelineTree, template));
    end
end

    
function voxels = GetVoxelsForTheseBranchesExtended(start_indices, template)
    voxels = [];
    if isempty(start_indices)
        return;
    end
    
    for index = 1 : numel(start_indices)
        voxels = cat(2, voxels, CentrelinePointsToLocalIndices(start_indices(index).GetCentrelineTree, template));
        parent = start_indices(index).Parent;
        while ~isempty(parent)
            centreline_indices = CentrelinePointsToLocalIndices(parent.Centreline, template);
            voxels = cat(2, voxels, centreline_indices);
            parent = parent.Parent;
        end
    end

    % Add nearest neighbours to the list of voxels, otherwise it is possible for
    % a diagnoally-connected skeleton segment to pass through a
    % diagnoally-connected airway segment
    [~, linear_offsets27] = TDImageCoordinateUtilities.GetLinearOffsets(template.ImageSize);
    voxels = repmat(int32(voxels), 27, 1) + repmat(int32(linear_offsets27'), 1, length(voxels));    
    voxels = unique(voxels(:));
end



function centreline_indices_local = CentrelinePointsToLocalIndices(centreline_points, template_image)
    centreline_indices_global = [centreline_points.GlobalIndex];
    centreline_indices_local = template_image.GlobalToLocalIndices(centreline_indices_global);
end

