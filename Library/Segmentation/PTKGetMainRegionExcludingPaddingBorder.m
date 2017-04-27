function main_image = PTKGetMainRegionExcludingPaddingBorder(original_image, threshold_image, minimum_region_volume_mm3, include_interior_regions, reporting)
    % PTKGetMainRegionExcludingPaddingBorder. Finds the largest connected region in a
    % binary 3D volume, excluding any regions which touch an inner border
    % created by extending an inner padding ring from the top and bottom of the image and growing horizontally.
    %
    % This is a heuristic that find the lung region while excluding regions exterior to the body even
    % if they are connected to the exterior through the airways or by the
    % lung extending beyond the image limits.
    %
    % Syntax:
    %     main_image = PTKGetMainRegionExcludingPaddingBorder(threshold_image, reporting)
    %
    % Inputs:
    %     threshold_image - a binary 3D volume as a PTKImage.
    %
    %     minimum_region_volume_mm3 (optional) - ignore any regions below this
    %         threshold
    %
    %     include_interior_regions - if true, the segmentation will include
    %         interior disconnected regions within the ROI even though they
    %         might not be part of the lungs and airways. Generally this
    %         might be set to true when finding a mask for airway
    %         segmentation, but set to false when finding a mask for lung
    %         segmentation
    %     
    %     reporting (optional) - an object implementing the CoreReporting
    %         interface for reporting progress and warnings
    %
    % Outputs:
    %     main_image - a PTKImage binary volume of the found region
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    if ~isa(threshold_image, 'PTKImage')
        error('Requires a PTKImage as input');
    end
    
    if nargin < 2 || isempty(minimum_region_volume_mm3)
        minimum_region_volume_mm3 = 0;
    end
    
    if nargin < 3
        reporting = CoreReportingDefault;
    end

    reporting.ShowProgress('Finding lung region');
    
    if ~isempty(threshold_image.PaddingValue)
        padding_image = original_image.RawImage == threshold_image.PaddingValue;
    else
        padding_image = false(original_image.ImageSize);
    end
    padding_image(1, :, :) = true;
    padding_image(end, :, :) = true;
    padding_image(:, 1, :) = true;
    padding_image(:, end, :) = true;
    threshold_excluding_padding = threshold_image.RawImage > 0;
    threshold_excluding_padding(padding_image) = false;
    
    % Find an inner border of the padding at the top of the image
    top_slice_padding = padding_image(:, :, 1);
    top_slice_padding = imdilate(top_slice_padding, strel([0 1 0; 1 1 1; 0 1 0]), 'same');
    top_slice_connect_points = top_slice_padding & threshold_excluding_padding(:, :, 1); 

    % Find an inner border of the padding at the bottom of the image
    bottom_slice_padding = padding_image(:, :, 1);
    bottom_slice_padding = imdilate(bottom_slice_padding, strel([0 1 0; 1 1 1; 0 1 0]));
    bottom_slice_connect_points = bottom_slice_padding & threshold_excluding_padding(:, :, end); 

    vert_con = zeros([3,3,3]);
    vert_con(:,:,1) = [0 0 0; 0 1 0; 0 0 0];
    vert_con(:,:,2) = [0 0 0; 0 1 0; 0 0 0];
    vert_con(:,:,3) = [0 0 0; 0 1 0; 0 0 0];
    vert_cc = bwconncomp(threshold_excluding_padding, vert_con);
    lm_vert = labelmatrix(vert_cc);
    lm_vert_top = lm_vert(:, :, 1);
    lm_vert_bottom = lm_vert(:, :, end);
    top_border_indices = lm_vert_top(top_slice_connect_points(:));
    bottom_border_indices = lm_vert_bottom(bottom_slice_connect_points(:));
    vert_border_indices = unique([top_border_indices; bottom_border_indices]);
    
    % We extend each point of the inner border from the top and bottom of
    % the image vertically until they encounter non-air voxels. The
    % resulting set of voxels we define as border points.
    is_border_point = ismember(lm_vert, vert_border_indices);
    
    % Now get horizontal connected components
    hor_con = zeros([3,3,3]);
    hor_con(:,:,2) = [0 1 0; 1 1 1; 0 1 0];
    cc_hor = bwconncomp(threshold_excluding_padding, hor_con);
    lm_hor = labelmatrix(cc_hor);
    
    % Remove horizontal components that are connected to the border points
    % we determined earlier
    hor_border_indices = unique(lm_hor(is_border_point(:)));
    remove_points = ismember(lm_hor, hor_border_indices);

    threshold_excluding_padding(remove_points) = false;
    
    bordered_image = true(threshold_image.ImageSize + [2 2 2]);
    bordered_image(2:end-1, 2:end-1, 2:end-1) = threshold_excluding_padding;
    bordered_image(2:end-1, 2:end-1, 1) = false;
    bordered_image(2:end-1, 2:end-1, end) = false;
    
    
    image_opening_params_mm = [0, 2, 4, 6];
    image_opening_index = 1;
    still_searching = true;
    if max(threshold_image.VoxelSize) >= 2
        connectivity = 6;
    else
        connectivity = 26;
    end
    
    last_ball_element = -1;
    
    while still_searching
    
        opening_mm = image_opening_params_mm(image_opening_index);
        if opening_mm > 0
            ball_element = CoreImageUtilities.CreateBallStructuralElement(threshold_image.VoxelSize, opening_mm);
        else 
            ball_element = [];
        end
        if isequal(ball_element, last_ball_element)
            % We skip the next opening if the structural element is
            % the same as last time (which could happen with large voxel
            % sizes)
            results = [];
        else
            if include_interior_regions
                max_num_regions = 10000;
            else
                max_num_regions = 2;
            end
            [results, CC] = OpenAndGetRegions(bordered_image, ball_element, connectivity, threshold_image.VoxelSize, minimum_region_volume_mm3, max_num_regions, ~include_interior_regions, reporting);
        end
        if numel(results) > 0 || image_opening_index == numel(image_opening_params_mm)
            still_searching = false;
        else
            image_opening_index = image_opening_index + 1;
            last_ball_element = ball_element;
        end
    end
    
    if numel(results) == 0
        reporting.Error('PTKGetMainRegionExcludingPaddingBorder:Failed', 'Unable to extract the main image region');
    end
    
    if ~include_interior_regions
        % Unless we include all interior regions, then determine whether to
        % combine the two results or only choose one of them
        if numel(results) > 1
            % If more than one region was found (after excluding boundary-touching
            % regions), then check if they are disconnected left and right lungs
            bounding_boxes = regionprops(CC, 'BoundingBox');
            bb_1 = bounding_boxes(results(1)).BoundingBox;
            bb_1 = bb_1([2,1,3,5,4,6]); % Bounding box is [xyz] but Matlab indices are [yxz]
            bb_2 = bounding_boxes(results(2)).BoundingBox;
            bb_2 = bb_2([2,1,3,5,4,6]); % Bounding box is [xyz] but Matlab indices are [yxz]
            image_centre = round(size(bordered_image)/2);

            image_centre_j = image_centre(2);
            centre_offset = round(image_centre_j/2);

            use_both_regions = false;
            if (bb_1(2) >= image_centre_j - centre_offset) && (bb_2(5) + bb_2(2) < image_centre_j + centre_offset)
                reporting.LogVerbose('I appear to have found 2 disconnected lungs. I am connecting them.');
                use_both_regions = true;
            end

            if (bb_2(2) >= image_centre_j - centre_offset) && (bb_1(5) + bb_1(2) < image_centre_j + centre_offset)
                reporting.LogVerbose('I appear to have found 2 disconnected lungs. I am connecting them.');
                use_both_regions = true;
            end
        else
            use_both_regions = false;
        end
    end
    
    bordered_image(:) = false;
    if include_interior_regions
        % Include ALL regions
        for index = 1 : numel(results)
            bordered_image(CC.PixelIdxList{results(index)}) = true;
        end
    else
        % Include the main or the main two regions
        bordered_image(CC.PixelIdxList{results(1)}) = true;
        if use_both_regions
            bordered_image(CC.PixelIdxList{results(2)}) = true;        
        end
    end
     
    main_image = threshold_image.BlankCopy;
    main_image.ChangeRawImage(bordered_image(2:end-1, 2:end-1, 2:end-1));
end

function [results, CC] = OpenAndGetRegions(bordered_image_input, ball_element, connectivity, voxel_size, minimum_region_volume_mm3, max_num_regions, exclude_out_of_roi, reporting)
    
    bordered_image = bordered_image_input;
    if ~isempty(ball_element)
        bordered_image = imopen(bordered_image_input > 0, ball_element);
    end

    % Borders are marked as segmented - this ensures all components
    % touching the border are connected and allows us to eliminate them
    % when extracting the lung
    
    % Obtain connected component matrix
    CC = bwconncomp(bordered_image, connectivity);
    stats = regionprops(CC, 'BoundingBox');

    % Find largest region
    num_pixels = cellfun(@numel, CC.PixelIdxList);
    [sorted_largest_areas, sorted_largest_areas_indices] = sort(num_pixels, 'descend');
    
    % Remove regions that are below the volume threshold - NOTE we must
    % reduce the size due to possible gaps due to noise
    pixel_volume = prod(voxel_size);

    small_area_mask = pixel_volume*sorted_largest_areas >= minimum_region_volume_mm3/100;
    sorted_largest_areas_indices = sorted_largest_areas_indices(small_area_mask);
    sorted_largest_areas = sorted_largest_areas(small_area_mask);
    
    result_index = 1;
    results = [];
    index_in_sorted_array = 1;
    while (result_index <= max_num_regions && index_in_sorted_array <= length(sorted_largest_areas_indices))
        current_region_being_checked = sorted_largest_areas_indices(index_in_sorted_array);
        bordered_image(:) = false;
        bordered_image(CC.PixelIdxList{current_region_being_checked}) = true;
        if (bordered_image(1) || bordered_image(end))
            % This region is connected to the edge
%             reporting.ShowMessage('PTKGetMainRegionExcludingBorder:LargestROIConnectedToExterior', 'The largest region connected with the edge of the volume. I''m assuming this region is outside the body so choosing the next largest region');
        else
            bb = stats(current_region_being_checked).BoundingBox;
            if exclude_out_of_roi && (bb(2) > (5/9)*size(bordered_image_input, 2))
                disp('removed');
                % ToDo
            else
                results(result_index) = current_region_being_checked;
                result_index = result_index + 1;
            end
        end
        index_in_sorted_array = index_in_sorted_array + 1;
    end
end