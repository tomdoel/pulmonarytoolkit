function output_image = PTKSmoothedRegionGrowingMatlab(threshold_image, start_points_global, smoothing_size_mm, reporting)
    % PTKSmoothedRegionGrowingMatlab. Performs 3D region growing for multiple
    %     regions, with a smoothing constraint applied to the region boundaries.
    %
    %
    %     Syntax:
    %         output_image = PTKSmoothedRegionGrowingMatlab(threshold_image, start_points_global, reporting)
    %
    %         Inputs:
    %         ------
    %             threshold_image - The threshold image in a PTKImage class. 1s
    %                 represents voxels which are connected
    %             start_points - an set of starting points, where each element
    %                 in the set is array of points representing one region.
    %                 Each point is a global index. The region growing will 
    %                 begin from all these points simultaneously
    %             smoothing_size_mm - amoung of smoothing. A larger value will
    %                 give better results but will be slower
    %             reporting - an object implementing CoreReportingInterface
    %                             for reporting progress and warnings
    %
    %         Outputs:
    %         -------
    %             output_image - A binary PTKImage containing the segmented region
    %                 of all voxels connected to the starting points
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    % Check the input image is of the correct form
    if ~isa(threshold_image, 'PTKImage')
        error('Requires a PTKImage as input');
    end
    
    if exist('reporting', 'var')
        reporting.Log('Started smoothed region growing');
        reporting.ShowProgress('Smoothed region growing');
    end
    
    threshold_image_cropped = threshold_image.Copy;
    threshold_image_cropped.CropToFit;
    
    points_left = threshold_image_cropped.RawImage;
    output_image_raw = zeros(threshold_image_cropped.ImageSize, 'uint8');
    
    % Set up initial points
    number_of_regions = length(start_points_global);
    
    region_image_raw = false(threshold_image_cropped.ImageSize);
    
    for region_index = 1 : number_of_regions
        region_image_raw(:) = false;
        start_points_for_this_index = start_points_global{region_index};
        points_index_local = threshold_image_cropped.GlobalToLocalIndices(start_points_for_this_index);
        points_left(points_index_local) = false;
        output_image_raw(points_index_local) = region_index;
    end
    
    % This controls the size of the element used to find the nearest neighbours
    growing_size_mm = 3;    
    
    average_el = uint16(CoreImageUtilities.CreateBallStructuralElement(threshold_image_cropped.VoxelSize, smoothing_size_mm));

    nn_element = CoreImageUtilities.CreateBallStructuralElement(threshold_image_cropped.VoxelSize, growing_size_mm);
    
    
    number_of_neighbouring_voxels = zeros([threshold_image_cropped.ImageSize, number_of_regions], 'double');
    
    iter = 0;
    more_to_do = true;
    while (more_to_do)
        iter = iter + 1;
        disp(iter);
        
        for region_index = 1 : number_of_regions
            input_image = uint16(output_image_raw == region_index);
            result = convn(input_image, average_el, 'same');
            number_of_neighbouring_voxels(:, :, :, region_index) = result;
        end
        
        [~, max_index] = max(number_of_neighbouring_voxels, [], 4);
        zero_mask = ~any(number_of_neighbouring_voxels, 4);
        max_index(zero_mask) = 0;
        
        more_to_do = false;
        
        for region_index = 1 : number_of_regions
            neighbours = convn(output_image_raw == region_index, nn_element, 'same');
            neighbours = neighbours & points_left;
            if any(neighbours(:))
                more_to_do = true;
            end
            neighbours = neighbours & (max_index == region_index);
            points_left(neighbours) = false;
            output_image_raw(neighbours) = region_index;
        end
    end    
    
    output_image = threshold_image_cropped.BlankCopy;
    output_image.ChangeRawImage(output_image_raw);
    output_image.ResizeToMatch(threshold_image);

end