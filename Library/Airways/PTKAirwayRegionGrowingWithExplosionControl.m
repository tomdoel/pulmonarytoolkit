function results = PTKAirwayRegionGrowingWithExplosionControl(threshold_image, start_point_global, maximum_number_of_generations, explosion_multiplier, coronal_mode, reporting, debug_mode)
    % PTKAirwayRegionGrowingWithExplosionControl. Segments the airways from a
    %     threshold image using a region growing method.
    %
    %     Given a binary image which representes an airway threshold applied to
    %     a lung CT image, PTKAirwayRegionGrowingWithExplosionControl finds a
    %     tree structure representing the bifurcating airway tree. Airway
    %     segmentation proceeds by wavefront growing and splitting, with
    %     heuristics to prevent 'explosions' into the lung parenchyma.
    %
    % Syntax:
    %     results = PTKAirwayRegionGrowingWithExplosionControl(threshold_image, start_point, maximum_number_of_generations, explosion_multiplier, reporting, debug_mode)
    %
    % Inputs:
    %     threshold_image - a lung volume stored as a PTKImage which has been
    %         thresholded for air voxels (1=air, 0=background).
    %         Note: the lung volume can be a region-of-interest, or the entire
    %         volume.
    %
    %     start_point_global - coordinate (i,j,k) of a point inside and near the top
    %         of the trachea, in global coordinates (as returned by plugin 
    %         PTKTopOfTrachea)
    %
    %     maximum_number_of_generations - tree-growing will terminate for each
    %         branch when it exceeds this number of generations in that branch
    %
    %     explosion_multiplier - 7 is a typical value. An explosion is detected
    %         when the number of new voxels in a wavefront exceeds the previous
    %         minimum by a factor defined by this parameter
    %
    %     coronal_mode - if true, the algorithm performs in a special mode
    %         designed for images with thick coronal slices
    %
    %     reporting - an object implementing the PTKReporting
    %         interface for reporting progress and warnings
    %
    %     debug_mode (optional) - should normally be set to false. 
    %         Provides visual debugging, but the algorithm will run much slower.
    %
    % Outputs:
    %     results - a structure containing the following fields:
    %         airway_tree - a PTKTreeSegment object which represents the trachea.
    %             This is linked to its child segments via its Children
    %             property, and so on, so the entre tree can be accessed from
    %             this property.
    %         explosion_points - Indices of all voxels which were marked as
    %             explosions during the region-growing process.
    %         endpoints - Indices of final points in each
    %             branch of the airway tree
    %         start_point - the trachea location as passed into the function
    %         image_size - the image size
    %
    % See the PTKAirways plugin for an example of how to reconstruct this results
    % structure into an image
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    if nargin < 7
        debug_mode = false;
    end
    
    if ~isa(threshold_image, 'PTKImage')
        reporting.Error('PTKAirwayRegionGrowingWithExplosionControl:InvalidInput', 'Requires a PTKImage as input');
    end

    reporting.UpdateProgressAndMessage(0, 'Airway region growing with explosion control');
    
    % Perform the airway segmentation
    airway_tree = RegionGrowing(threshold_image, start_point_global, reporting, maximum_number_of_generations, explosion_multiplier, coronal_mode, debug_mode);

    
    if isempty(airway_tree)
        reporting.ShowWarning('PTKAirwayRegionGrowingWithExplosionControl:AirwaySegmentationFailed', 'Airway segmentation failed', []);
    else
        % Sanity checking and warn user if any branches terminated early
        CheckSegments(airway_tree, reporting);
        
        % Find points which indicate explosions
        explosion_points = GetExplosionPoints(airway_tree);
        
        % Remove segments in which all points are marked as explosions
        airway_tree = RemoveCompletelyExplodedSegments(airway_tree, reporting);
        
        % Remove holes within the airway segments
        reporting.ShowProgress('Closing airways segmentally');
        closing_size_mm = 5;
        airway_tree = PTKCloseBranchesInTree(airway_tree, closing_size_mm, threshold_image.OriginalImageSize, reporting);

        % Find and store endpoints
        reporting.ShowProgress('Finding endpoints');
        endpoints = FindEndpointsInAirwayTree(airway_tree);

        % Store the results
        results = [];
        results.ExplosionPoints = explosion_points;
        results.EndPoints = endpoints;
        results.AirwayTree = airway_tree;
        results.StartPoint = start_point_global;
        results.ImageSize = threshold_image.OriginalImageSize;
    end
    
end


function first_segment = RegionGrowing(threshold_image_handle, start_point_global, reporting, maximum_number_of_generations, explosion_multiplier, coronal_mode, debug_mode)
    
    threshold_image_handle.AddBorder(1);
    
    voxel_size_mm = threshold_image_handle.VoxelSize;

    min_distance_before_bifurcating_mm = max(3, ceil(threshold_image_handle.ImageSize(3)*voxel_size_mm(3))/4);

    start_point_global = int32(start_point_global);
    image_size_global = int32(threshold_image_handle.OriginalImageSize);

    if debug_mode
        pause_skip = 0;
        debug_image = threshold_image_handle.BlankCopy;
        debug_image.ChangeRawImage(zeros(debug_image.ImageSize, 'uint8'));
    end
    threshold_image = logical(threshold_image_handle.RawImage);
    
    number_of_image_points_local = numel(threshold_image(:));

    [linear_offsets_global, ~] = PTKImageCoordinateUtilities.GetLinearOffsets(image_size_global);

    
    % For Coronal mode compute the linear offsets
    if coronal_mode
        dirs_coronal = [5, 23, 11, 17];
        linear_offsets_global_jk = PTKImageCoordinateUtilities.GetLinearOffsetsForDirections(dirs_coronal, image_size_global);
        linear_offsets_neighbours = linear_offsets_global_jk;
    else
        linear_offsets_neighbours = linear_offsets_global;        
    end

    first_segment = PTKWavefront([], min_distance_before_bifurcating_mm, voxel_size_mm, maximum_number_of_generations, explosion_multiplier);
    start_point_index_global = sub2ind(image_size_global, start_point_global(1), start_point_global(2), start_point_global(3));
    start_point_index_local = threshold_image_handle.GlobalToLocalIndices(start_point_index_global);

    
    threshold_image(start_point_index_local) = false;
    
    if debug_mode
        debug_image.SetIndexedVoxelsToThis(start_point_index_global, 1);
    end

    last_progress_value = 0;

    segments_in_progress = first_segment.AddNewVoxelsAndGetNewSegments(start_point_index_global, image_size_global);


    while ~isempty(segments_in_progress)
        
        if reporting.HasBeenCancelled
            reporting.Error('PTKAirwayRegionGrowingWithExplosionControl:UserCancel', 'User cancelled');
        end
        
        % Get the next airway segment to add voxels to
        current_segment = segments_in_progress(end);
        segments_in_progress(end) = [];
        
        % Fetch the front of the wavefront for this segment
        frontmost_points_global = current_segment.GetFrontmostWavefrontVoxels;
        
        % Find the neighbours of these points, which will form the next 
        % generation of points to add to the wavefront
        indices_of_new_points_global = GetNeighbouringPoints(frontmost_points_global, linear_offsets_neighbours);
        indices_of_new_points_local = threshold_image_handle.GlobalToLocalIndices(indices_of_new_points_global);

        in_range = indices_of_new_points_local > 0 & indices_of_new_points_local <= number_of_image_points_local;
        indices_of_new_points_local = indices_of_new_points_local(in_range);
        indices_of_new_points_global = indices_of_new_points_global(in_range);

        in_threshold = threshold_image(indices_of_new_points_local);
        indices_of_new_points_local = indices_of_new_points_local(in_threshold);
        indices_of_new_points_global = indices_of_new_points_global(in_threshold);
        
        if coronal_mode
            if isempty(indices_of_new_points_global)
                % Fetch the front of the wavefront for this segment
                frontmost_points_global = current_segment.GetWavefrontVoxels;
                indices_of_new_points_global = GetNeighbouringPoints(frontmost_points_global, linear_offsets_global);
                indices_of_new_points_local = threshold_image_handle.GlobalToLocalIndices(indices_of_new_points_global);
                
                in_range = indices_of_new_points_local > 0 & indices_of_new_points_local <= number_of_image_points_local;
                indices_of_new_points_local = indices_of_new_points_local(in_range);
                indices_of_new_points_global = indices_of_new_points_global(in_range);
                
                in_threshold = threshold_image(indices_of_new_points_local);
                indices_of_new_points_local = indices_of_new_points_local(in_threshold)';
                indices_of_new_points_global = indices_of_new_points_global(in_threshold)';
                
                if isempty(indices_of_new_points_global)
                    frontmost_points_global = current_segment.CurrentBranch.GetAcceptedVoxels;
                    indices_of_new_points_global = GetNeighbouringPoints(frontmost_points_global, linear_offsets_global);
                    indices_of_new_points_local = threshold_image_handle.GlobalToLocalIndices(indices_of_new_points_global);
                    
                    in_range = indices_of_new_points_local > 0 & indices_of_new_points_local <= number_of_image_points_local;
                    indices_of_new_points_local = indices_of_new_points_local(in_range);
                    indices_of_new_points_global = indices_of_new_points_global(in_range);
                    
                    in_threshold = threshold_image(indices_of_new_points_local);
                    indices_of_new_points_local = indices_of_new_points_local(in_threshold)';
                    indices_of_new_points_global = indices_of_new_points_global(in_threshold)';
                end
            end
        end

        % If there are no new candidate neighbour indices then complete the
        % segment
        if isempty(indices_of_new_points_global)
            
            current_segment.CompleteThisSegment;

            % If the segment is ending, then report progress
            last_progress_value = GuessSegmentsLeft(segments_in_progress, maximum_number_of_generations, last_progress_value, reporting);

        else
            threshold_image(indices_of_new_points_local) = false;

            if debug_mode
                pause_skip = pause_skip + 1;
                debug_image.SetIndexedVoxelsToThis(current_segment.GetWavefrontVoxels, 1);
            end
                        
            % Add points to the current segment and retrieve a list of segments
            % which reqire further processing - this can comprise of the current
            % segment if it is incomplete, or child segments if it has bifurcated
            next_segments = current_segment.AddNewVoxelsAndGetNewSegments(indices_of_new_points_global, image_size_global);
            
            if debug_mode
                colour_index = 2;
                for segment = next_segments
                    wavefront_voxels = segment.GetWavefrontVoxels;
                    debug_image.SetIndexedVoxelsToThis(wavefront_voxels, colour_index);
                    colour_index = colour_index + 1;
                end
                if (length(next_segments) > 1) || (pause_skip > 10);
                    pause_skip = 0;
                    reporting.UpdateOverlayImage(debug_image);
                    disp('PAUSED');
                    pause
                end
            end

            segments_in_progress = [segments_in_progress, next_segments]; %#ok<AGROW>
            if length(segments_in_progress) > 500
               reporting.Error('PTKAirwayRegionGrowingWithExplosionControl:MaximumSegmentsExceeded', 'More than 500 segments to do: is there a problem with the image?'); 
            end

            if ~debug_mode
                % If the segment is ending, then report progress
                if length(next_segments) ~= 1
                    last_progress_value = GuessSegmentsLeft(segments_in_progress, maximum_number_of_generations, last_progress_value, reporting);
                end
            end

        end
    end
    
    first_segment = first_segment.CurrentBranch;
end

function last_value = GuessSegmentsLeft(segments_in_progress, maximum_number_of_generations, last_value, reporting)
    % Estimate number of segments still to do
    segments_left = 0;
    segments_temp = segments_in_progress;
    while ~isempty(segments_temp)
        segment = segments_temp(end);
        segments_temp(end) = [];
        generation = segment(1).CurrentBranch.GenerationNumber;
        generations_left = (maximum_number_of_generations - generation);
        num_segments_to_do = 2^(generations_left+1) - 1;
        segments_left = segments_left + num_segments_to_do;
%         segments_temp = [segments_temp, segment(1).Children];
    end
    total_segments = 2^maximum_number_of_generations - 1;

    progress = 100*(total_segments - segments_left)/total_segments;
    if progress > last_value
        reporting.UpdateProgressValue(progress);
        last_value = progress;
    end
end

function explosion_points = GetExplosionPoints(processed_segments)
    explosion_points = [];
    segments_to_do = processed_segments;
    while ~isempty(segments_to_do)
        next_segment = segments_to_do(1);
        segments_to_do(1) = [];
        explosion_points = cat(1, explosion_points, next_segment.GetRejectedVoxels);
        segments_to_do = [segments_to_do, next_segment.Children]; %#ok<AGROW>
    end
end

% Check the segments have completed correctly, and warn the user if some
% branches terminated early
function CheckSegments(airway_tree, reporting)
    number_of_branches_with_exceeded_generations = 0;
    segments_to_do = airway_tree;
    while ~isempty(segments_to_do)
        next_segment = segments_to_do(1);
        if next_segment.ExceededMaximumNumberOfGenerations
            number_of_branches_with_exceeded_generations = number_of_branches_with_exceeded_generations + 1;
        end
        segments_to_do(1) = [];
        segments_to_do = [segments_to_do, next_segment.Children]; %#ok<AGROW>
    end
    
    if number_of_branches_with_exceeded_generations > 0
        if number_of_branches_with_exceeded_generations == 1
            loop_text = 'branch has';
        else
            loop_text = 'branches have';
        end
        reporting.ShowWarning('PTKAirwayRegionGrowingWithExplosionControl:InternalLoopRemoved', [num2str(number_of_branches_with_exceeded_generations) ...
            ' airway ' loop_text ' been terminated because the maximum number of airway generations has been exceeded. This may indicate that the airway has leaked into the surrounding parenchyma.'], []);
    end
    
end

function list_of_point_indices = GetNeighbouringPoints(point_indices, linear_offsets)
    if isempty(point_indices)
        list_of_point_indices = [];
        return
    end
    
    list_of_point_indices = repmat(int32(point_indices), 1, size(linear_offsets,2)) + repmat(int32(linear_offsets), length(point_indices), 1);    
    list_of_point_indices = unique(list_of_point_indices(:));
    
end
    


function airway_tree = RemoveCompletelyExplodedSegments(airway_tree, reporting)
    segments_to_do = airway_tree;
    while ~isempty(segments_to_do)
        next_segment = segments_to_do(1);
        segments_to_do(1) = [];
        
        % Remove segments which are explosions
        if numel(next_segment.GetAcceptedVoxels) == 0
            next_segment.CutFromTree;
            if ~isempty(next_segment.Children)
               reporting.Error('PTKAirwayRegionGrowingWithExplosionControl:ExplodedSegmentWithChildren', 'Exploded segment has children - this should never happen, and indicates an program error.');
            end
            
            % Removing an explosion may leave its parent with only one child, in
            % which case these should be merged, since they are really the same
            % segment
            if (length(next_segment.Parent.Children) == 1)
                remaining_child = next_segment.Parent.Children;
                next_segment.Parent.MergeWithChild;
                
                % Need to be careful when merging a child branch with its
                % parent - if the child branch is currently in the
                % segments_to_do we need to remove it and put its child branches
                % in so they get processed correctly
                if ismember(remaining_child, segments_to_do)
                    segments_to_do = setdiff(segments_to_do, remaining_child);
                    segments_to_do = [segments_to_do, remaining_child.Children];
                end
            end
        end
        segments_to_do = [segments_to_do, next_segment.Children];
    end
    airway_tree.RecomputeGenerations(1);
end

function endpoints = FindEndpointsInAirwayTree(airway_tree, reporting)
    endpoints = [];

    segments_to_do = airway_tree;
    while ~isempty(segments_to_do)
        segment = segments_to_do(end);
        segments_to_do(end) = [];
        segments_to_do = [segments_to_do, segment.Children];

        if isempty(segment.Children)
            final_voxels_in_segment = segment.GetEndpoints;
            if isempty(final_voxels_in_segment)
                reporting.Error('PTKAirwayRegionGrowingWithExplosionControl:NoAcceptedIndices', 'No accepted indices in this airway segment');
            end
            endpoints(end + 1) = final_voxels_in_segment(end);
        end        
    end
end

