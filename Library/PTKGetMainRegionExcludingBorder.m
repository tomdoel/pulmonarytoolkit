function threshold_image = TDGetMainRegionExcludingBorder(threshold_image, reporting)
    % TDGetMainRegionExcludingBorder. Finds the largest connected region in a
    % binary 3D volume, excluding any regions which touch the borders in the
    % first and second dimensions.
    %
    % Syntax:
    %     threshold_image = TDGetMainRegionExcludingBorder(threshold_image, reporting)
    %
    % Inputs:
    %     threshold_image - a binary 3D volume as a TDImage.
    %
    %     reporting (optional) - an object implementing the TDReporting
    %         interface for reporting progress and warnings
    %
    % Outputs:
    %     threshold_image - a TDImage binary volume of the found region
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %

    if ~isa(threshold_image, 'TDImage')
        error('Requires a TDImage as input');
    end
    
    if nargin < 2
        reporting = TDReportingDefault;
    end

    reporting.ShowProgress('Finding lung region');
    
    bordered_image = true(threshold_image.ImageSize + [2 2 2]);
    bordered_image(2:end-1, 2:end-1, 2:end-1) = threshold_image.RawImage;
    bordered_image(2:end-1, 2:end-1, 1) = false;
    bordered_image(2:end-1, 2:end-1, end) = false;
    
    % Borders are marked as segmented - this ensures all components
    % touching the border are connected and allows us to eliminate them
    % when extracting the lung
    
    % Obtain connected component matrix
    CC = bwconncomp(bordered_image, 26);

    % Find largest region
    num_pixels = cellfun(@numel, CC.PixelIdxList);
    [~, sorted_largest_areas_indices] = sort(num_pixels, 'descend');
    
    result_index = 1;
    results = [];
    index_in_sorted_array = 1;
    while (result_index < 3 && index_in_sorted_array <= length(sorted_largest_areas_indices))
        current_region_being_checked = sorted_largest_areas_indices(index_in_sorted_array);
        bordered_image(:) = false;
        bordered_image(CC.PixelIdxList{current_region_being_checked}) = true;
        if (bordered_image(1) || bordered_image(end))
            % This region is connected to the edge
            reporting.ShowMessage('TDGetMainRegionExcludingBorder:LargestROIConnectedToExterior', 'The largest region connected with the edge of the volume. I''m assuming this region is outside the body so choosing the next largest region');
        else
            results(result_index) = current_region_being_checked;
            result_index = result_index + 1;
        end
        index_in_sorted_array = index_in_sorted_array + 1;
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
            reporting.ShowMessage('TDGetMainRegionExcludingBorder:LungsDisconnected', 'I appear to have found 2 disconnected lungs. I am connecting them.');
            use_both_regions = true;
        end
        
        if (bb_2(2) >= image_centre_j - centre_offset) && (bb_1(5) < image_centre_j + centre_offset)
            reporting.ShowMessage('TDGetMainRegionExcludingBorder:LungsDisconnected', 'I appear to have found 2 disconnected lungs. I am connecting them.');
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
     
    threshold_image.ChangeRawImage(bordered_image(2:end-1, 2:end-1, 2:end-1));
end