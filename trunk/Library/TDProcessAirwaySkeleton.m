function results = TDProcessAirwaySkeleton(skeleton_image, start_point, reporting)
    % TDProcessAirwaySkeleton. Processes a skeletonised image of the airway
    % tree, beginning from start_point and returning a data structure containing
    % the processed informtion
    %
    % Syntax:
    %     results = TDProcessAirwaySkeleton(skeleton_image, start_point)
    %            
    %     skeleton_image - A 3D volume containing the airway skeleton:
    %         0=background, 1=skeleton point
    %
    %     start_point - coordinate of the first point in the skeleton (the
    %         trachea) as a coordinate vector [i,j,k]
    %
    %     reporting (optional) - an object implementing the TDReporting
    %         interface for reporting progress and warnings
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    [airway_skeleton, skeleton_points, bifurcation_points, removed_points] = GetSkeletonTree(skeleton_image, start_point, reporting);
    
    
    results = [];
    results.original_skeleton_points = find(skeleton_image);
    results.airway_skeleton = airway_skeleton;
    results.bifurcation_points = bifurcation_points;
    results.skeleton_points = skeleton_points;
    results.image_size = size(skeleton_image);
    results.start_point = start_point;
    results.removed_points = removed_points;
    
end


function [results, skeleton_points, bifurcation_points, removed_points] = GetSkeletonTree(skeleton, start_point, reporting)
    skeleton = logical(skeleton);
    
    % Compute linear index offsets for neighbouring points
    neighbour_offsets = ComputeOffsets(size(skeleton));
    
    start_point = sub2ind(size(skeleton), start_point(1), start_point(2), start_point(3));
    
    skeleton(start_point) = false;
    
    bifurcation_points = [];
    skeleton_points = [];
    removed_points = [];
    
    % The first segment in the tree - this is a recursive tree structure
    skeleton_parent = TDSkeletonSegment(start_point);
    
    segments_to_do = skeleton_parent.GetIncompleteSegments;
    
    internal_loops_removed = 0;
    
    while ~isempty(segments_to_do)
        current_skeleton_segment = segments_to_do(end);
        segments_to_do(end) = [];
        first_point_for_segment = current_skeleton_segment.NextPoint;
        neighbour_indices = first_point_for_segment;
        current_skeleton_segment.CompleteSegment;
        
        % Continue until we get to the end of a line or reach a furcation
        while (length(neighbour_indices) == 1)
            next_point = neighbour_indices(1);

            current_skeleton_segment.AddPoint(next_point);
            skeleton_points(end + 1) = next_point; %#ok<AGROW>
    
            % Find indices of neighbouring points
            neighbour_indices = next_point + neighbour_offsets;
            
            % Remove neighbouring points which are outside the image
            neighbour_indices = neighbour_indices(neighbour_indices > 0);

            % Detection of loops in segmentation is done by checking if any of
            % the neighbours of this new point match the start points of
            % segments waiting to be processed
            if (next_point == first_point_for_segment)
                
                % The first point in any segment is permitted to connect to its
                % siblings - this is not a loop, since the bifurcation point
                % already connects these points
                segments_to_check_for_loop = setdiff(segments_to_do, current_skeleton_segment.GetSiblings);
            else
                segments_to_check_for_loop = segments_to_do;
            end
            
            % Iterate through all the candidate segment start points and check
            % against current neighbours
            loop_detected = false;
            for segment = segments_to_check_for_loop
                if find(segment.NextPoint == neighbour_indices, 1)
                    loop_detected = true;
                    removed_points = [removed_points, segment.GetTree]; %#ok<AGROW>
                    removed_points = [removed_points, segment.NextPoint]; %#ok<AGROW>
                    segment.DeleteThisSegment;
                end
            end
            
            % If a loop has been found, remove this segment from the tree
            if (loop_detected)
                internal_loops_removed = internal_loops_removed + 1;
                removed_points = [removed_points, current_skeleton_segment.GetTree]; %#ok<AGROW>
                current_skeleton_segment.DeleteThisSegment;
                
                % Fetch a new list of segments to do, since the removal of the
                % segments may have triggered merging of tree branches
                segments_to_do = skeleton_parent.GetIncompleteSegments;
            end
            
            % Get indices of neighbours which are part of the skeleton
            neighbour_indices = neighbour_indices(skeleton(neighbour_indices(:)));
            
            % Remove these indices from the available indices
            skeleton(neighbour_indices) = false;
        end
        
        
        num_neighbours = length(neighbour_indices);
        
        % Store the bifurcation points
        if (num_neighbours > 0)
            current_skeleton_segment.AddPoint(next_point);
            bifurcation_points(end+1) = next_point; %#ok<AGROW>
        end
        
        % Furcation: create new segments and add them to the list of segments to do
        for neighbour_index = 1 : num_neighbours
            new_child = current_skeleton_segment.SpawnChild(neighbour_indices(neighbour_index));
            segments_to_do(end + 1) = new_child; %#ok<AGROW>
        end
        
    end

    if internal_loops_removed > 0
        if internal_loops_removed == 1
            loop_text = 'loop was';
        else
            loop_text = 'loops were';
        end
        reporting.ShowWarning('TDProcessAirwaySkeleton:InternalLoopRemoved', [num2str(internal_loops_removed) ' internal ' loop_text ' detected and removed from the airway skeleton.'], []);
    end
    
    results = skeleton_parent;
end



function neighbour_offsets = ComputeOffsets(image_size)
    [n_i, n_j, n_k] = ind2sub([3,3,3], 1:27);
    n_indices = sub2ind(image_size, n_i, n_j, n_k);
    neighbour_offsets = n_indices(14) - [n_indices(1:13) n_indices(15:27)];
end
