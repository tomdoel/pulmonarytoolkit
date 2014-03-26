function output_image = PTKMultipleRegionGrowing(threshold_image, start_points_global, reporting)
    % PTKMultipleRegionGrowing. Performs 3D region growing of several regions
    %      simultaneously through the supplied binary threshold image, beginning
    %      at the specified starting points for each region.
    %
    %
    %     Syntax:
    %         output_image = PTKMultipleRegionGrowing(threshold_image, start_points_global, reporting)
    %
    %         Inputs:
    %         ------
    %             threshold_image - The threshold image in a PTKImage class. 1s
    %                 represents voxels which are connected
    %             start_points - an set of starting points, where each element
    %                 in the set is array of points representing one region.
    %                 Each point is a global index. The region growing will 
    %                 begin from all these points simultaneously
    %             reporting - a PTKReporting object for progress, warning and
    %                 error reporting.
    %
    %         Outputs:
    %         -------
    %             output_image - A binary PTKImage containing the segmented region
    %                 of all voxels connected to the starting points
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    % Check the input image is of the correct form
    if ~isa(threshold_image, 'PTKImage')
        error('Requires a PTKImage as input');
    end
    
    if exist('reporting', 'var')
        reporting.Log('Started region growing');
        reporting.ShowProgress('Region growing');
    end
    
    output_image = threshold_image.BlankCopy;
    segmented_image = zeros(threshold_image.ImageSize, 'uint8');
    
    [linear_offsets, ~] = PTKImageCoordinateUtilities.GetLinearOffsets(threshold_image.ImageSize);

    threshold_image_raw = logical(threshold_image.RawImage);
    number_points = length(segmented_image(:));
    
    number_of_points_to_grow = sum(threshold_image_raw(:));
    iteration = 0;
    
    
    % Set up initial points
    number_of_regions = length(start_points_global);
    
    multiple_next_points = [];
    for region_index = 1 : number_of_regions
        start_points_in_region = start_points_global{region_index};
        start_points_local = threshold_image.GlobalToLocalIndices(start_points_in_region);
        next_points = start_points_local;
        threshold_image_raw(next_points) = false;
        segmented_image(next_points) = region_index;
        multiple_next_points{region_index} = next_points;
    end
    
    more_points = true;
    
    while more_points
        more_points = false;
        
        if mod(iteration, 20) == 0
            points_to_do = sum(threshold_image_raw(:));
            reporting.UpdateProgressStage(number_of_points_to_grow - points_to_do, number_of_points_to_grow);
        end
        
        iteration = iteration + 1;
        
        for region_index = 1 : number_of_regions
            if ~isempty(multiple_next_points{region_index})
                next_points = multiple_next_points{region_index};

                all_points = GetNeighbouringPoints(next_points, linear_offsets);
                all_points = all_points(all_points > 0 & all_points <= number_points);
                
                list_of_neighbours_indices = all_points(threshold_image_raw(all_points))';
                segmented_image(list_of_neighbours_indices) = region_index;
                threshold_image_raw(list_of_neighbours_indices) = false;
                
                next_points = list_of_neighbours_indices';
                multiple_next_points{region_index} = next_points;
                
                if ~isempty(next_points)
                    more_points = true;
                end                
            end
        end
    end
    output_image.ChangeRawImage(segmented_image);
    
    if exist('reporting', 'var')
        reporting.Log('Finished region growing');
        reporting.CompleteProgress;
    end
 end
 
function list_of_point_indices = GetNeighbouringPoints(point_indices, linear_offsets)
    list_of_point_indices = repmat(point_indices, 1, 6) + repmat(linear_offsets, length(point_indices), 1);
    list_of_point_indices = unique(list_of_point_indices(:));
end