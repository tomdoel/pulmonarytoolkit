function both_lungs = PTKSeparateAndLabelLungs(unclosed_lungs, filtered_threshold_lung, lung_roi, reporting)
    % PTKSeparateAndLabelLungs. Separates left and right lungs from a lung
    %     segmentation.
    %
    %     The left and right lungs are separated using morphological opening
    %     with spherical structural element of increasing size until the left
    %     and right components are separated. Then and voxels removed by the
    %     opening are added to the left and right segmentations using a
    %     watershed algorithm based on the supplied (filtered) image data.
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    
    both_lungs = unclosed_lungs.Copy;
    
    both_lungs.ChangeRawImage(uint8(both_lungs.RawImage & (filtered_threshold_lung.RawImage == 1)));
    
    % Find the connected components in this mask
    CC = bwconncomp(both_lungs.RawImage > 0, 26);
    
    % Find largest regions
    num_pixels = cellfun(@numel, CC.PixelIdxList);
    total_num_pixels = sum(num_pixels);
    minimum_required_voxels_per_lung = total_num_pixels/10;
    [largest_area_numpixels, largest_areas_indices] = sort(num_pixels, 'descend');
    
    iter_number = 0;
    
    % If there is only one large connected component, the lungs are connected,
    % so we attempt to disconnect them using morphological operations
    while (length(largest_areas_indices) < 2) || (largest_area_numpixels(2) < minimum_required_voxels_per_lung)
        if (iter_number > 10)
            reporting.Error('PTKSeparateAndLabelLungs:FailedToSeparateLungs', ['Failed to separate left and right lungs after ' num2str(iter_number) ' opening attempts']);
        end
        iter_number = iter_number + 1;
        reporting.ShowMessage('PTKSeparateAndLabelLungs:OpeningLungs', ['Failed to separate left and right lungs. Retrying after morphological opening attempt ' num2str(iter_number) '.']);
        opening_size = iter_number;
        image_to_close = both_lungs.Copy;
        image_to_close.BinaryMorph(@imopen, opening_size);
        
        CC = bwconncomp(image_to_close.RawImage > 0, 26);
        
        % Find largest region
        num_pixels = cellfun(@numel, CC.PixelIdxList);
        total_num_pixels = sum(num_pixels);
        minimum_required_voxels_per_lung = total_num_pixels/10;
        
        [largest_area_numpixels, largest_areas_indices] = sort(num_pixels, 'descend');
        
    end
    
    reporting.ShowMessage('PTKSeparateAndLabelLungs:LungsFound', 'Lung regions found.');
    
    largest_area_index = largest_areas_indices(1);
    second_largest_area_index = largest_areas_indices(2);
    
    region_1_voxels = CC.PixelIdxList{largest_area_index};
    region_1_centroid = GetCentroid(both_lungs.ImageSize, region_1_voxels);
    
    region_2_voxels = CC.PixelIdxList{second_largest_area_index};
    region_2_centroid = GetCentroid(both_lungs.ImageSize, region_2_voxels);
    
    both_lungs.Clear;
    both_lungs.ImageType = PTKImageType.Colormap;
    if region_1_centroid(2) < region_2_centroid(2)
        region_1_colour = 1;
        region_2_colour = 2;
    else
        region_1_colour = 2;
        region_2_colour = 1;
    end
    
    % Watershed to fill remaining voxels
    lung_exterior = unclosed_lungs.RawImage == 0;
    starting_voxels = zeros(both_lungs.ImageSize, 'int8');
    starting_voxels(region_1_voxels) = region_1_colour;
    starting_voxels(region_2_voxels) = region_2_colour;
    starting_voxels(lung_exterior) = -1;
    
    labeled_output = PTKWatershedFromStartingPoints(int16(lung_roi.RawImage), starting_voxels);
    labeled_output(labeled_output == -1) = 0;
    
    both_lungs.ChangeRawImage(uint8(labeled_output));
    both_lungs.ImageType = PTKImageType.Colormap;
end

function centroid = GetCentroid(image_size, new_coords_indices)
    [p_x, p_y, p_z] = PTKImageCoordinateUtilities.FastInd2sub(image_size, new_coords_indices);
    centroid = [mean(p_x), mean(p_y), mean(p_z)];
end