function results_image = PTKColourBranchesByLobe(start_branches, airway_tree, template)
    % PTKColourBranchesByLobe. Given a set of labelled branches, this creates an output image with all the subtrees coloured by lobe
    %
    % Usage:
    %
    %     results_image = PTKColourBranchesByLobe(start_branches, airway_tree, template)
    %
    % Inputs:
    %
    %     start_branches : The lobar start branches from PTKGetAirwaysLabelledByLobe
    %
    %     airway_tree : the root PTKTreeSegment of a segmented airway tree
    %         structure produced by PTKAirwayRegionGrowingWithExplosionControl
    %
    %     template : A PTKImage representing the region of interest used by the
    %         centreline algorithm
    %
    %
    %
    %  Output:
    %     results_image : An image showing the segmented airways labelled by lobe.
    %         The following colours are used:
    %             1 (blue)   : Right upper lobe
    %             2 (green)  : Right middle lobe
    %             4 (cyan)   : Right lower lobe
    %             5 (magenta): Left lower lobe
    %             6 (yellow) : Left upper lobe
    %
    %             3 (red)    : Uncertain - unable to allocate to a lobe
    %             7 (grey)   : Airways supplying more than one lobe (before the
    %                          lobar bifurcations)
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
    left_lower_voxels = PTKTreeUtilities.GetCentrelineVoxelsForTheseBranches(left_lower_startindices, template);
    left_upper_voxels = PTKTreeUtilities.GetCentrelineVoxelsForTheseBranches(left_upper_startindices, template);
    right_lower_voxels = PTKTreeUtilities.GetCentrelineVoxelsForTheseBranches(right_lower_startindices, template);
    right_mid_voxels = PTKTreeUtilities.GetCentrelineVoxelsForTheseBranches(right_mid_startindices, template);
    right_upper_voxels = PTKTreeUtilities.GetCentrelineVoxelsForTheseBranches(right_upper_startindices, template);
    
    uncertain_voxels = PTKTreeUtilities.GetCentrelineVoxelsForTheseBranches(uncertain_segments, template);

    left_lower_voxels_extended = PTKTreeUtilities.GetCentrelineVoxelsForTheseBranchesExtended(left_lower_startindices, template);
    left_upper_voxels_extended = PTKTreeUtilities.GetCentrelineVoxelsForTheseBranchesExtended(left_upper_startindices, template);
    right_lower_voxels_extended = PTKTreeUtilities.GetCentrelineVoxelsForTheseBranchesExtended(right_lower_startindices, template);
    right_mid_voxels_extended = PTKTreeUtilities.GetCentrelineVoxelsForTheseBranchesExtended(right_mid_startindices, template);
    right_upper_voxels_extended = PTKTreeUtilities.GetCentrelineVoxelsForTheseBranchesExtended(right_upper_startindices, template);
    
    uncertain_voxels_extended = PTKTreeUtilities.GetCentrelineVoxelsForTheseBranchesExtended(uncertain_segments, template);
    
    results_image = zeros(template.ImageSize, 'uint8');
    
    full_tree_voxels = PTKTreeUtilities.CentrelinePointsToLocalIndices(start_segment.GetCentrelineTree, template);
    
    results_image(full_tree_voxels) = 7;
    
    results_image(right_upper_voxels) = 1;
    results_image(right_mid_voxels) = 2;
    results_image(right_lower_voxels) = 4;
    results_image(left_upper_voxels) = 5;
    results_image(left_lower_voxels) = 6;
    
    results_image(uncertain_voxels) = 3;

    % Label segments by centreline
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