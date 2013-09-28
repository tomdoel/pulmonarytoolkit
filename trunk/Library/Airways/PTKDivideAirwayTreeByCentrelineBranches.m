function results_image = PTKDivideAirwayTreeByCentrelineBranches(start_branches, airway_tree, template)
    % PTKDivideAirwayTreeByCentrelineBranches. Given a set of branches, this
    %     creates an output image which divides an airway tree into the subtrees
    %     serving each branch
    %
    %     PTKDivideAirwayTreeByCentrelineBranches takes a segmented airway tree
    %     (airway_tree) and creates an output image (results_image) which is
    %     coloured according to the the subtrees served by the branches
    %     (start_branches). Any branches which serve more than one branch in
    %     start_branches will not be coloured.
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    number_startsegments = length(start_branches);

    start_segment_voxels = [];
    extended_start_segment_voxels = [];
    
    results_image = zeros(template.ImageSize, 'uint8');    

    % Get centreline voxels for each starting segment
    for index = 1 : number_startsegments
        start_segment_voxels{index} = PTKTreeUtilities.GetCentrelineVoxelsForTheseBranches(start_branches(index), template);
        extended_start_segment_voxels{index} = GetCentrelineVoxels(start_branches(index), template);
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