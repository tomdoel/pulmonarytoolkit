function output_image = TDSimpleRegionGrowing(threshold_image, start_points, reporting)
    % TDSimpleRegionGrowing. Performs 3D region growing through the supplied
    %     binary threshold image, starting from the specified points
    %
    %
    %     Syntax:
    %         output_image = TDSimpleRegionGrowing(threshold_image, start_points, reporting)
    %
    %         Inputs:
    %         ------
    %             threshold_image - The threshold image in a TDImage class. 1s
    %                 represents voxels which are connected
    %             start_points - an array of points, where each point is a
    %                 coordinate in the form [i, j, k]. The region growing will
    %                 begin from all these points simultaneously
    %             reporting - a TDReporting object for progress, warning and
    %                 error reporting.
    %
    %         Outputs:
    %         -------
    %             output_image - A binary TDImage containing the segmented region
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
    if ~isa(image_data, 'TDImage')
        error('Requires a TDImage as input');
    end
    
    if exist(reporting, 'var')
        reporting.Log('Started region growing');
    end
    
    output_image = threshold_image.BlankCopy;
    threshold_image = logical(threshold_image.RawImage);
    segmented_image = zeros(size(threshold_image), 'uint8');
    
    [linear_offsets, ~] = TDImageCoordinateUtilities.GetLinearOffsets(size(threshold_image));
    next_points = zeros(length(start_points), 1);
    for i = 1 : length(next_points)
        start_point = start_points{i};
        next_points(i) = sub2ind(size(threshold_image), start_point(1), start_point(2), start_point(3));        
    end    

    number_points = length(segmented_image(:));
    
    while ~isempty(next_points)
        all_points = GetNeighbouringPoints(next_points, linear_offsets);
        all_points = all_points(all_points > 0 & all_points <= number_points);
        
        list_of_neighbours_indices = all_points(threshold_image(all_points))';
        segmented_image(list_of_neighbours_indices) = 1;
        threshold_image(list_of_neighbours_indices) = false;

        next_points = list_of_neighbours_indices';
    end
    output_image.ChangeRawImage(segmented_image);
    
    if exist(reporting, 'var')
        reporting.Log('Finished region growing');
    end    
 end
 
function list_of_point_indices = GetNeighbouringPoints(point_indices, linear_offsets)
    list_of_point_indices = repmat(point_indices, 1, 6) + repmat(linear_offsets, length(point_indices), 1);
    list_of_point_indices = unique(list_of_point_indices(:));
end