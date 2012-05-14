function results = TDAirwayRegionGrowingWithExplosionControl(threshold_image, start_point_global, maximum_number_of_generations, explosion_multiplier, reporting)
    % TDAirwayRegionGrowingWithExplosionControl. Segments the airways from a
    %     threshold image using a region growing method.
    %
    %     Given a binary image which representes an airway threshold applied to
    %     a lung CT image, TDAirwayRegionGrowingWithExplosionControl finds a
    %     tree structure representing the bifurcating airway tree. Airway
    %     segmentation proceeds by wavefront growing and splitting, with
    %     heuristics to prevent 'explosions' into the lung parenchyma.
    %
    % Syntax:
    %     results = TDAirwayRegionGrowingWithExplosionControl(threshold_image, start_point, reporting)
    %
    % Inputs:
    %     threshold_image - a lung volume stored as a TDImage which has been
    %         thresholded for air voxels (1=air, 0=background).
    %         Note: the lung volume can be a region-of-interest, or the entire
    %         volume.
    %
    %     start_point_global - coordinate (i,j,k) of a point inside and near the top
    %         of the trachea, in global coordinates (as returned by plugin 
    %         TDTopOfTrachea)
    %
    %     maximum_number_of_generations - tree-growing will terminate for each
    %         branch when it exceeds this number of generations in that branch
    %
    %     explosion_multiplier - 7 is a typical value. An explosion is detected
    %         when the number of new voxels in a wavefront exceeds the previous
    %         minimum by a factor defined by this parameter
    %
    %     reporting (optional) - an object implementing the TDReporting
    %         interface for reporting progress and warnings
    %
    % Outputs:
    %     results - a structure containing the following fields:
    %         airway_tree - a TDTreeSegment object which represents the trachea.
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
    % See the TDAirways plugin for an example of how to reconstruct this results
    % structure into an image
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    if ~isa(threshold_image, 'TDImage')
        reporting.Error('TDAirwayRegionGrowingWithExplosionControl:InvalidInput', 'Requires a TDImage as input');
    end

    reporting.UpdateProgressAndMessage(0, 'Starting region growing with explosion control');
    
    % Perform the airway segmentation
    airway_tree = RegionGrowing(threshold_image, start_point_global, reporting, maximum_number_of_generations, explosion_multiplier);

    
    if isempty(airway_tree)
        reporting.ShowWarning('TDAirwayRegionGrowingWithExplosionControl:AirwaySegmentationFailed', 'Airway segmentation failed', []);
    else
        % Sanity checking and warn user if any branches terminated early
        CheckSegments(airway_tree, reporting);
        
        % Find points which indicate explosions
        explosion_points = GetExplosionPoints(airway_tree);
        
        % Remove segments in which all points are marked as explosions
        airway_tree = RemoveCompletelyExplodedSegments(airway_tree);
        
        % Remove holes within the airway segments
        reporting.ShowProgress('Closing airways segmentally');
        closing_size_mm = 5;
        airway_tree = TDCloseBranchesInTree(airway_tree, closing_size_mm, threshold_image.OriginalImageSize, reporting);

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


function first_segment_global = RegionGrowing(threshold_image_handle, start_point_global, reporting, maximum_number_of_generations, explosion_multiplier)

    voxel_size_mm = threshold_image_handle.VoxelSize;

    min_distance_before_bifurcating_mm = max(3, ceil(threshold_image_handle.ImageSize(3)*voxel_size_mm(3))/4);

    start_point_global = int32(start_point_global);
    image_size_global = int32(threshold_image_handle.OriginalImageSize);

    threshold_image = logical(threshold_image_handle.RawImage);
    number_of_image_points_local = numel(threshold_image(:));

    [linear_offsets_global, ~] = TDImageCoordinateUtilities.GetLinearOffsets(image_size_global);

    first_segment_global = TDTreeSegment([], min_distance_before_bifurcating_mm, voxel_size_mm, maximum_number_of_generations, explosion_multiplier);
    start_point_index_global = sub2ind(image_size_global, start_point_global(1), start_point_global(2), start_point_global(3));

    threshold_image(start_point_index_global) = false;

    last_progress_value = 0;

    segments_in_progress = first_segment_global.AddNewVoxelsAndGetNewSegments(start_point_index_global, image_size_global);


    while ~isempty(segments_in_progress)
        
        if reporting.HasBeenCancelled
            reporting.Error('TDAirwayRegionGrowingWithExplosionControl:UserCancel', 'User cancelled');
        end
        
        % Get the next airway segment to add voxels to
        current_segment = segments_in_progress(end);
        segments_in_progress(end) = [];
        
        % Fetch the front of the wavefront for this segment
        frontmost_points_global = current_segment.GetFrontmostWavefrontVoxels;
        
        % Find the neighbours of these points, which will form the next 
        % generation of points to add to the wavefront
        indices_of_new_points_global = GetNeighbouringPoints(frontmost_points_global', linear_offsets_global);
        indices_of_new_points_local = threshold_image_handle.GlobalToLocalIndices(indices_of_new_points_global);

        in_range = indices_of_new_points_local > 0 & indices_of_new_points_local <= number_of_image_points_local;
        indices_of_new_points_local = indices_of_new_points_local(in_range);
        indices_of_new_points_global = indices_of_new_points_global(in_range);

        in_threshold = threshold_image(indices_of_new_points_local);
        indices_of_new_points_local = indices_of_new_points_local(in_threshold)';
        indices_of_new_points_global = indices_of_new_points_global(in_threshold)';

        % If there are no new candidate neighbour indices then complete the
        % segment
        if isempty(indices_of_new_points_global)
            
            current_segment.CompleteThisSegment;

            % If the segment is ending, then report progress
            last_progress_value = GuessSegmentsLeft(segments_in_progress, maximum_number_of_generations, last_progress_value, reporting);

        else
            threshold_image(indices_of_new_points_local) = false;

            % Add points to the current segment and retrieve a list of segments
            % which reqire further processing - this can comprise of the current
            % segment if it is incomplete, or child segments if it has bifurcated
            next_segments = current_segment.AddNewVoxelsAndGetNewSegments(indices_of_new_points_global, image_size_global);

            segments_in_progress = [segments_in_progress, next_segments]; %#ok<AGROW>
            if length(segments_in_progress) > 500
               reporting.Error('TDAirwayRegionGrowingWithExplosionControl:MaximumSegmentsExceeded', 'More than 500 segments to do: is there a problem with the image?'); 
            end

            % If the segment is ending, then report progress
            if length(next_segments) ~= 1
                last_progress_value = GuessSegmentsLeft(segments_in_progress, maximum_number_of_generations, last_progress_value, reporting);
            end

        end
    end
end

function last_value = GuessSegmentsLeft(segments_in_progress, maximum_number_of_generations, last_value, reporting)
    % Estimate number of segments still to do
    segments_left = 0;
    segments_temp = segments_in_progress;
    while ~isempty(segments_temp)
        segment = segments_temp(end);
        segments_temp(end) = [];
        generation = segment(1).GenerationNumber;
        generations_left = (maximum_number_of_generations - generation);
        num_segments_to_do = 2^(generations_left+1) - 1;
        segments_left = segments_left + num_segments_to_do;
        segments_temp = [segments_temp, segment(1).Children];
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
        explosion_points = cat(2, explosion_points, next_segment.GetRejectedVoxels);
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
        wavefront = next_segment.GetWavefrontVoxels;
        if ~isempty(wavefront)
            reporting.Error('TDAirwayRegionGrowingWithExplosionControl:NonEmptyWavefront', 'Program error: Wavefront is not empty when it should be.');
        end
        segments_to_do = [segments_to_do, next_segment.Children]; %#ok<AGROW>
    end
    
    if number_of_branches_with_exceeded_generations > 0
        if number_of_branches_with_exceeded_generations == 1
            loop_text = 'branch has';
        else
            loop_text = 'branches have';
        end
        reporting.ShowWarning('TDProcessAirwaySkeleton:InternalLoopRemoved', [num2str(number_of_branches_with_exceeded_generations) ...
            ' airway ' loop_text ' been terminated because the maximum number of airway generations has been exceeded. This may indicate that the airway has leaked into the surrounding parenchyma.'], []);
    end
    
end

function list_of_point_indices = GetNeighbouringPoints(point_indices, linear_offsets)
    if isempty(point_indices)
        list_of_point_indices = [];
        return
    end
    
    list_of_point_indices = repmat(int32(point_indices), 1, 6) + repmat(int32(linear_offsets), length(point_indices), 1);    
    list_of_point_indices = unique(list_of_point_indices(:));
    
end
    


function airway_tree = RemoveCompletelyExplodedSegments(airway_tree)
    segments_to_do = airway_tree;
    while ~isempty(segments_to_do)
        next_segment = segments_to_do(1);
        segments_to_do(1) = [];
        
        if numel(next_segment.GetAcceptedVoxels) == 0
            next_segment.CutFromTree;
            if ~isempty(next_segment.Children)
               disp('exploded segment has children'); 
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
                reporting.Error('TDAirwayRegionGrowingWithExplosionControl:NoAcceptedIndices', 'No accepted indices in this airway segment');
            end
            endpoints(end + 1) = final_voxels_in_segment(end);
        end        
    end
end

