function main_image = PTKGetMainRegionExcludingBorder(threshold_image, minimum_region_volume_mm3, reporting)
    % PTKGetMainRegionExcludingBorder. Finds the largest connected region in a
    % binary 3D volume, excluding any regions which touch the borders in the
    % first and second dimensions.
    %
    % Syntax:
    %     main_image = PTKGetMainRegionExcludingBorder(threshold_image, reporting)
    %
    % Parameters:
    %     threshold_image - a binary 3D volume as a PTKImage.
    %
    %     minimum_region_volume_mm3 (optional) - ignore any regions below this
    %         threshold
    %
    %     reporting (optional) - an object implementing CoreReportingInterface
    %                             for reporting progress and warnings
    %
    % Returns:
    %     main_image - a PTKImage binary volume of the found region
    %
    %
    % .. Licence
    %    -------
    %    Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %    Author: Tom Doel, 2012.  www.tomdoel.com
    %    Distributed under the GNU GPL v3 licence. Please see website for details.
    %

    if ~isa(threshold_image, 'PTKImage')
        error('Requires a PTKImage as input');
    end
    
    if nargin < 2 || isempty(minimum_region_volume_mm3)
        minimum_region_volume_mm3 = 0;
    end
    
    if nargin < 3
        reporting = CoreReportingDefault();
    end

    reporting.ShowProgress('Finding lung region');
    
    
    
    bordered_image = true(threshold_image.ImageSize + [2 2 2]);
    bordered_image(2:end-1, 2:end-1, 2:end-1) = threshold_image.RawImage;
    bordered_image(2:end-1, 2:end-1, 1) = false;
    bordered_image(2:end-1, 2:end-1, end) = false;
    
    image_opening_params_mm = [0, 2, 4, 6];
    image_opening_index = 1;
    still_searching = true;
    
    while still_searching
    
        [results, CC] = OpenAndGetRegions(bordered_image, image_opening_params_mm(image_opening_index), threshold_image.VoxelSize, minimum_region_volume_mm3, reporting);
    
        if numel(results) > 0 || image_opening_index == numel(image_opening_params_mm)
            still_searching = false;
        else
            image_opening_index = image_opening_index + 1;
        end
    end
    
    if numel(results) == 0
        main_image = [];
        reporting.Error('PTKGetMainRegionExcludingBorder:NoRegionFound', 'No region could be found');
    end
    
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
        
        if threshold_image.IsCT
            centre_offset = 0;
        else
            % Allow some leeway for MRI images where the lung boundaries may not be so
            % clear
            centre_offset = 10;
        end
        
        use_both_regions = false;
        if (bb_1(2) >= image_centre_j - centre_offset) && (bb_2(5) < image_centre_j + centre_offset)
            reporting.LogVerbose('I appear to have found 2 disconnected lungs. I am connecting them.');
            use_both_regions = true;
        end
        
        if (bb_2(2) >= image_centre_j - centre_offset) && (bb_1(5) < image_centre_j + centre_offset)
            reporting.LogVerbose('I appear to have found 2 disconnected lungs. I am connecting them.');
            use_both_regions = true;
        end
    else
        use_both_regions = false;
    end

    bordered_image(:) = false;
    bordered_image(CC.PixelIdxList{results(1)}) = true;
    if use_both_regions
        bordered_image(CC.PixelIdxList{results(2)}) = true;        
    end
     
    main_image = threshold_image.BlankCopy();
    main_image.ChangeRawImage(bordered_image(2:end-1, 2:end-1, 2:end-1));
end

function [results, CC] = OpenAndGetRegions(bordered_image_input, opening_mm, voxel_size, minimum_region_volume_mm3, reporting)
    
    bordered_image = bordered_image_input;
    if opening_mm > 0
        ball_element = CoreImageUtilities.CreateBallStructuralElement(voxel_size, opening_mm);
        bordered_image = imopen(bordered_image_input > 0, ball_element);
    end

    % Borders are marked as segmented - this ensures all components
    % touching the border are connected and allows us to eliminate them
    % when extracting the lung
    
    % Obtain connected component matrix
    CC = bwconncomp(bordered_image, 26);

    % Find largest region
    num_pixels = cellfun(@numel, CC.PixelIdxList);
    [sorted_largest_areas, sorted_largest_areas_indices] = sort(num_pixels, 'descend');
    
    % Remove regions that are below the volume threshold
    pixel_volume = prod(voxel_size);
    sorted_largest_areas_indices = sorted_largest_areas_indices(pixel_volume*sorted_largest_areas >= minimum_region_volume_mm3);
    
    
    result_index = 1;
    results = [];
    index_in_sorted_array = 1;
    while (result_index < 3 && index_in_sorted_array <= length(sorted_largest_areas_indices))
        current_region_being_checked = sorted_largest_areas_indices(index_in_sorted_array);
        bordered_image(:) = false;
        bordered_image(CC.PixelIdxList{current_region_being_checked}) = true;
        if (bordered_image(1) || bordered_image(end))
            % This region is connected to the edge
%             reporting.ShowMessage('PTKGetMainRegionExcludingBorder:LargestROIConnectedToExterior', 'The largest region connected with the edge of the volume. I''m assuming this region is outside the body so choosing the next largest region');
        else
            results(result_index) = current_region_being_checked;
            result_index = result_index + 1;
        end
        index_in_sorted_array = index_in_sorted_array + 1;
    end
end