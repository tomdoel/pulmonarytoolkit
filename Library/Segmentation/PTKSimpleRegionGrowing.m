function output_image = PTKSimpleRegionGrowing(threshold_image, start_points_global, reporting)
    % PTKSimpleRegionGrowing. Performs 3D region growing through the supplied
    %     binary threshold image, starting from the specified points
    %
    %
    %     Syntax:
    %         output_image = PTKSimpleRegionGrowing(threshold_image, start_points_global, reporting)
    %
    %         Inputs:
    %         ------
    %             threshold_image - The threshold image in a PTKImage class. 1s
    %                 represents voxels which are connected
    %             start_points - an array of points, where each point is a
    %                 coordinate in the form [i, j, k]. The region growing will
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
    start_points_matrix = cell2mat(start_points_global');
    start_points_matrix = threshold_image.GlobalToLocalCoordinates(start_points_matrix);
    next_points = PTKImageCoordinateUtilities.FastSub2ind(threshold_image.ImageSize, start_points_matrix(:, 1), start_points_matrix(:, 2), start_points_matrix(:, 3));

    threshold_image = logical(threshold_image.RawImage);
    number_points = length(segmented_image(:));
    
    number_of_points_to_grow = sum(threshold_image(:));
    iteration = 0;

    while ~isempty(next_points)
        if mod(iteration, 100) == 0
            points_to_do = sum(threshold_image(:));
            reporting.UpdateProgressStage(number_of_points_to_grow - points_to_do, number_of_points_to_grow);
        end
        iteration = iteration + 1;
        all_points = GetNeighbouringPoints(next_points, linear_offsets);
        all_points = all_points(all_points > 0 & all_points <= number_points);
        
        list_of_neighbours_indices = all_points(threshold_image(all_points))';
        segmented_image(list_of_neighbours_indices) = 1;
        threshold_image(list_of_neighbours_indices) = false;

        next_points = list_of_neighbours_indices';
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