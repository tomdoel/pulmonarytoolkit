function results_image = PTKColourBranchesBelowLobe(start_branches, airway_tree, template)
    % PTKColourBranchesBelowLobe. Given a set of labelled branches, this creates an output image with all the subtrees coloured by lobe
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %

    left_upper_startindices = start_branches.LeftUpper;
    left_lower_startindices = start_branches.LeftLower;
    right_upper_startindices = start_branches.RightUpper;
    right_mid_startindices = start_branches.RightMid;
    right_lower_startindices = start_branches.RightLower;
    uncertain_segments = start_branches.LeftUncertain;

    left_upper_startindices = [left_upper_startindices.Children];
    left_lower_startindices = [left_lower_startindices.Children];
    right_upper_startindices = [right_upper_startindices.Children];
    right_mid_startindices = [right_mid_startindices.Children];
    right_lower_startindices = [right_lower_startindices.Children];
    if ~isempty(uncertain_segments)
        uncertain_segments = [uncertain_segments.Children];
    end
    
    start_segments = [left_upper_startindices, left_lower_startindices, right_upper_startindices, ...
        right_mid_startindices, right_lower_startindices, uncertain_segments];

    results_image = PTKDivideAirwayTreeByCentrelineBranches(start_segments, airway_tree, template);
end

function results_image = PTKDivideAirwayTreeByCentrelineBranches(start_segments, airway_tree, template)
    number_startsegments = length(start_segments);

    start_segment_voxels = [];
    extended_start_segment_voxels = [];
    
    results_image = zeros(template.ImageSize, 'uint8');    

    % Get centreline voxels for each starting segment
    for index = 1 : number_startsegments
        start_segment_voxels{index} = PTKTreeUtilities.GetCentrelineVoxelsForTheseBranches(start_segments(index), template);
        extended_start_segment_voxels{index} = GetCentrelineVoxels(start_segments(index), template);
    end
    
    segments_to_do = airway_tree;
    
    while ~isempty(segments_to_do)
        segment = segments_to_do(end);
        segments_to_do(end) = [];
        voxel_indices_in_segment = segment.GetAllAirwayPoints;
        voxel_indices_in_segment = template.GlobalToLocalIndices(voxel_indices_in_segment);
        
        segment_indices = [];
        
        for index = 1 : number_startsegments
            if any(ismember(extended_start_segment_voxels{index}, voxel_indices_in_segment))
                segment_indices = [segment_indices, index];
            end
        end
        
        if length(segment_indices) == 1
            results_image(voxel_indices_in_segment) = segment_indices;
        end
        
        segments_to_do = [segments_to_do segment.Children];
    end
end

function voxel_indices = GetCentrelineVoxels(start_indices, template)
    voxel_indices = PTKTreeUtilities.GetCentrelineVoxelsForTheseBranches(start_indices, template);
    
    % Add nearest neighbours to the list of voxels, otherwise it is possible for
    % a diagnoally-connected centreline segment to pass through a
    % diagnoally-connected airway segment
    voxel_indices = PTKImageCoordinateUtilities.AddNearestNeighbours(voxel_indices, template);
end