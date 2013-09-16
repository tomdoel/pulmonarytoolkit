function separated_mask = PTKDivideVolumeUsingScatteredPoints(volume_mask, scattered_points, volume_fraction_threshold, reporting)
    % PTKDivideVolumeUsingScatteredPoints. Divides a volume into two regions,
    % given a set of points which partly divide the volume
    %
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    volume_mask_copy = volume_mask.BlankCopy;
    volume_mask_copy.ChangeRawImage(logical(volume_mask.RawImage));
    
    % Find the main parts of the two main regions
    separated_mask = SeparateIntoTwo(volume_mask_copy, scattered_points, volume_fraction_threshold, reporting);
    
    % If the separation failed, return empty matrix
    if isempty(separated_mask)
        return;
    end
    
    % Fill in any remaining parts of the regions, excluding the scattered points
    volume_mask_raw = volume_mask_copy.RawImage;
    volume_mask_raw(scattered_points) = false;
    volume_mask_copy.ChangeRawImage(volume_mask_raw);
    separated_mask = FillRemaining(volume_mask_copy, separated_mask);

    % Now fill in the scattered points
    volume_mask_copy.ChangeRawImage(logical(volume_mask.RawImage));
    separated_mask = FillRemaining(volume_mask_copy, separated_mask);

end

function output_mask = FillRemaining(mask, separated_mask)
    output_mask = separated_mask.BlankCopy;
    method = 'cityblock';
    dt_1 = bwdistgeodesic(mask.RawImage, separated_mask.RawImage == 1, method);
    dt_2 = bwdistgeodesic(mask.RawImage, separated_mask.RawImage == 2, method);
    output_mask_raw = zeros(mask.ImageSize, 'uint8');
    output_mask_raw(dt_1 <= dt_2) = 1;
    output_mask_raw(dt_2 < dt_1) = 2;
    output_mask.ChangeRawImage(output_mask_raw);
end
    
function separated_mask = SeparateIntoTwo(volume_mask, scattered_points, volume_fraction_threshold, reporting)
        
    % Place the points in their own image
    dividing_points_image = volume_mask.BlankCopy;
    dividing_points_image_raw = false(dividing_points_image.ImageSize);
    dividing_points_image_raw(scattered_points) = true;
    dividing_points_image.ChangeRawImage(dividing_points_image_raw);
    
    region_1_indices = [];
    closing_size_mm = 0;
    closing_step_mm = 0.5;
    max_closing_size_mm = 6;
    
    while isempty(region_1_indices)
        mask_to_separate_raw = logical(volume_mask.RawImage);
        mask_to_separate_raw(dividing_points_image.RawImage) = false;
        [region_1_indices, region_2_indices] = Separate(mask_to_separate_raw, volume_fraction_threshold);
        
        if isempty(region_1_indices)
            closing_size_mm = closing_size_mm + closing_step_mm;
            if closing_size_mm > max_closing_size_mm
                separated_mask = [];
                return;
            end
            
            % Reset dividing points image to original set of points
            dividing_points_image.ChangeRawImage(dividing_points_image_raw);
            
            % Morphologically dilate to fill the gaps
            dividing_points_image.BinaryMorph(@imdilate, closing_size_mm);
        end
    end
    
    separated_mask = volume_mask.BlankCopy;
    separated_mask_raw = zeros(volume_mask.ImageSize, 'uint8');
    separated_mask_raw(region_1_indices) = 1;
    separated_mask_raw(region_2_indices) = 2;
    separated_mask.ChangeRawImage(separated_mask_raw);    
end

function [region_1_indices, region_2_indices] = Separate(mask_to_separate_raw, volume_fraction_threshold)
    
    region_1_indices = [];
    region_2_indices = [];
    
    % Find the connected components in this mask
    cc = bwconncomp(mask_to_separate_raw, 6);

    number_of_components = cc.NumObjects;
    
    if number_of_components < 2
        return;
    end
    
    % Order the regions by size
    num_voxels_per_component = cellfun(@numel, cc.PixelIdxList);
    [largest_volume_numpixels, largest_volumes_indices] = sort(num_voxels_per_component, 'descend');
    
    % Compute a threshold for the minimum region size
    total_num_voxels = sum(num_voxels_per_component);
    minimum_required_voxels_per_component = total_num_voxels/volume_fraction_threshold;
    
    % If either of the two largest components are below the volume threshold
    % then this separation failed
    if largest_volume_numpixels(1) < minimum_required_voxels_per_component || largest_volume_numpixels(2) < minimum_required_voxels_per_component
        return;
    end
    
    largest_region_index = largest_volumes_indices(1);
    second_largest_region_index = largest_volumes_indices(2);

    largest_region_indices = cc.PixelIdxList{largest_region_index};
    largest_region_centroid = GetCentroid(size(mask_to_separate_raw), largest_region_indices);
    
    second_largest_region_indices = cc.PixelIdxList{second_largest_region_index};
    second_largest_region_centroid = GetCentroid(size(mask_to_separate_raw), second_largest_region_indices);
    
    if largest_region_centroid(3) < second_largest_region_centroid(3)
        region_1_indices = largest_region_indices;
        region_2_indices = second_largest_region_indices;
    else
        region_1_indices = second_largest_region_indices;
        region_2_indices = largest_region_indices;
    end
    
end

function centroid = GetCentroid(image_size, new_coords_indices)
    [p_x, p_y, p_z] = PTKImageCoordinateUtilities.FastInd2sub(image_size, new_coords_indices);
    centroid = [mean(p_x), mean(p_y), mean(p_z)];
end