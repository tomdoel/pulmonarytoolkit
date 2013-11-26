function [high_fissure_indices, ref_image] = PTKGetMaxFissurePoints(fissure_approximation, lung_mask, fissureness, image_roi, image_size)
    % PTKGetMaxFissurePoints. function for finding candidate points of high
    %     fissureness given an initial fissure approximation.
    %
    %     PTKGetMaxFissurePoints is an intermediate stage in segmenting the
    %     lobes. It is not intended to be a general-purpose algorithm.    
    %
    %     For more information, see 
    %     [Doel et al., Pulmonary lobe segmentation from CT images using
    %     fissureness, airways, vessels and multilevel B-splines, 2012]
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %

    data_points_indices = find(fissure_approximation);
    
    bin_size = 2;

    [high_fissure_indices, ref_image] = GetFissurePoints(data_points_indices, image_size, lung_mask, fissureness, image_roi, bin_size);
end


function [maximum_fissureness_indices, ref_image] = GetFissurePoints(indices_for_model, image_size, lung_segmentation, fissureness, image_roi, bin_size)

    % Get the coordinates of every voxel in the lung segmentation
    candidate_indices = find(lung_segmentation.RawImage);

    % An image for debugging
    ref_image = zeros(image_size, 'uint8');
    ref_image(candidate_indices) = 2;
    
    % Remove points with low fissureness
    max_fissureness = max(fissureness.RawImage(candidate_indices));
    fissureness_threshold = max_fissureness/3;
    intensity_threshold_hu = -900;
    intensity_threshold = image_roi.HounsfieldToGreyscale(intensity_threshold_hu);
    candidate_indices = candidate_indices((fissureness.RawImage(candidate_indices) > fissureness_threshold) & (image_roi.RawImage(candidate_indices) > intensity_threshold));
    ref_image(candidate_indices) = 4;

    % Find a rotation matrix
    [eigv, m] = GetRotationMatrix(indices_for_model, image_size);
    
    [x_all, y_all, z_all] = PTKImageCoordinateUtilities.FastInd2sub(image_size, candidate_indices);
    X_all = [x_all(:), y_all(:), z_all(:)]';
    
    % Transform to new basis
    em_all = X_all - m(:, ones(1, size(X_all, 2)));
    em_all = eigv*em_all;
        
    % We allocate each point to a bin according to the x-y coordinates in the
    % transformed domain
    x1_all = em_all(1, :);
    y1_all = em_all(2, :);

    % Get the coordinates of each of the model points
    [x_model, y_model, z_model] = PTKImageCoordinateUtilities.FastInd2sub(image_size, indices_for_model);    
    X_model = [x_model(:), y_model(:), z_model(:)]';
    
    % Transform to new basis
    em_model = X_model - m(:, ones(1, size(X_model, 2)));
    em_model = eigv*em_model;
    
    % We allocate each point to a bin according to the x-y coordinates in the
    % transformed domain
    x1_model = em_model(1, :);
    y1_model = em_model(2, :);
    
    % Project the candidate points onto the fissure plane, and remove those that
    % are not within the convex hull formed by the model points on the plane. In
    % effect, we are using the model coordinates (the initial guess) as a bound
    % for the x-y coordinates used to construct the fissure surface.
    xy_coords_model = [x1_model', y1_model'];
    dt = DelaunayTri(xy_coords_model);
    simplex_index = pointLocation(dt, x1_all', y1_all');
    is_valid = ~isnan(simplex_index);
    candidate_indices_ok = candidate_indices(is_valid);
    
    % Turn into x,y,z vectors
    [x_all, y_all, z_all] = PTKImageCoordinateUtilities.FastInd2sub(image_size, candidate_indices_ok);
    X_all = [x_all(:), y_all(:), z_all(:)]';    

    % Transform to new basis
    em_all = X_all - m(:, ones(1, size(X_all, 2)));
    em_all = eigv*em_all;
    
    % We allocate each point to a bin according to the x-y coordinates in the
    % transformed domain
    x1_all = em_all(1, :);
    y1_all = em_all(2, :);    
    
    [maximum_fissureness_indices, all_maxima] = SortIntoBins(x1_all, y1_all, candidate_indices_ok, fissureness, bin_size, image_size);
    
    ref_image(all_maxima) = 6;
    ref_image(maximum_fissureness_indices) = 3;

    % Remove non-connected points (outliers)
    [x_all, y_all, z_all] = PTKImageCoordinateUtilities.FastInd2sub(image_size, maximum_fissureness_indices);
    points_coords = ArraysToPoints(x_all(:), y_all(:), z_all(:));
        
    min_dilate_size_mm = 2.5;
    max_dilate_size_mm = 2.5;
    
    dilate_size_mm = min_dilate_size_mm;
    
    calculate_again = true;
    target_number_of_points = round(numel(x_all)/2);
    
    % Perform the removal of connected points with a variable dilation size
    while calculate_again
        points_coords_new = RemoveNonConnectedPoints(points_coords, lung_segmentation, image_size, dilate_size_mm);
        number_of_found_points = numel(points_coords_new);
        if (number_of_found_points >= target_number_of_points) || (dilate_size_mm > max_dilate_size_mm)
            calculate_again = false;
        else
            dilate_size_mm = dilate_size_mm + 0.5;
        end
        
    end
    
    disp(['Final dilate size: ' num2str(dilate_size_mm) 'mm']);
    [x_all, y_all, z_all] = PointsToArrays(points_coords_new);
    maximum_fissureness_indices = PTKImageCoordinateUtilities.FastSub2ind(image_size, x_all(:), y_all(:), z_all(:));
    ref_image(maximum_fissureness_indices) = 1;
    
end


function [rot_matrix, m] = GetRotationMatrix(indices, image_size)
    [x, y, z] = ind2sub(image_size, indices);
    X = [x, y, z]';

    % Find a suitable basis for these points using PCA
    m = mean(X, 2);
    em = X - m(:, ones(1, size(X, 2)));
    eigv = pts_pca(em);
    
    rot_matrix = eigv';
end


function [maximum_fissureness_indices, all_maxima] = SortIntoBins(x1, y1, candidate_indices, fissureness, bin_size, image_size)
    binx = floor(x1/bin_size);
    binx = binx - min(binx);
    biny = floor(y1/bin_size);
    biny = biny - min(biny);
    
    % bin is an array containing the bin to which each element of indices has been allocated
    bin = binx + (max(binx)+1)*biny;
    
    % Now sort the indices and bins by fissureness
    fissureness_at_indices = fissureness.RawImage(candidate_indices);
    
    is_maxima = GetMaxima(candidate_indices, bin, fissureness_at_indices, fissureness, image_size);
    all_maxima = candidate_indices(is_maxima);
    bin = bin(is_maxima);
    candidate_indices = candidate_indices(is_maxima);

    fissureness_at_indices = fissureness.RawImage(candidate_indices);
    
    [~, sorted_indices] = sort(fissureness_at_indices, 'descend');
    indices_sorted_by_fissureness = candidate_indices(sorted_indices);
    bins_sorted_by_fissureness = bin(sorted_indices);

    % Use unique to obtain the first indices corresponding to each bin - this
    % will be the point with the largest fissureness
    maximum_fissureness_indices = [];
    for selection_index = 1 : 1
        [~, bin_indices, ~] = unique(bins_sorted_by_fissureness, 'first');
        maximum_fissureness_indices = [maximum_fissureness_indices; indices_sorted_by_fissureness(bin_indices)];
        
        bins_sorted_by_fissureness(bin_indices) = [];
        indices_sorted_by_fissureness(bin_indices) = [];
    end
    
    maximum_fissureness_indices = maximum_fissureness_indices(fissureness.RawImage(maximum_fissureness_indices) > 0);

end

function is_maxima = GetMaxima(candidate_indices, bin, fissureness_at_indices, fissureness, image_size)
    bin_allocation = zeros(image_size, 'int32');
    bin_allocation(candidate_indices) = bin;
    
    [linear_offsets, ~] = PTKImageCoordinateUtilities.GetLinearOffsets(image_size);
    neighbours = repmat(int32(candidate_indices), 1, 6) + repmat(int32(linear_offsets), length(candidate_indices), 1);
    fissureness_neighbours = fissureness.RawImage(neighbours);
    bins_neighbours = bin_allocation(neighbours);
    bins_match = bins_neighbours == repmat(bin', 1, 6);
    fissureness_centre = repmat(fissureness_at_indices, 1, 6);
    
    % Force neighbouring points in different bins to have a lower fissureness
    fissureness_neighbours(~bins_match) = fissureness_centre(~bins_match) - 1;
    fissureness_less = fissureness_neighbours < fissureness_centre;
    sums = sum(fissureness_less, 2);
    is_maxima = sums == 6;
end


function points_coords = RemoveNonConnectedPoints(points_coords, template_image, image_size, dilate_size_mm)
    voxel_volume = prod(template_image.VoxelSize);
    min_component_size_mm3 = 300;
    min_component_size_voxels = round(min_component_size_mm3/voxel_volume);

    
    image_mask = false(image_size);
    indices = sub2ind(image_size, points_coords(:,1), points_coords(:,2), points_coords(:,3));
    image_mask(indices) = true;
    
    tci = template_image.BlankCopy;
    tci.ChangeRawImage(image_mask);
    tci.BinaryMorph(@imdilate, dilate_size_mm);
    connected_image = tci.RawImage;
    
    connected_components = bwconncomp(connected_image, 26);
    num_components = connected_components.NumObjects;
    for component = 1 : num_components
        pixels = connected_components.PixelIdxList{component};
        if length(pixels) < min_component_size_voxels
            connected_image(pixels) = false;
        end
    end
    image_mask = image_mask & connected_image;
    indices = find(image_mask(:));
    [i2_coords, j2_coords, k2_coords] = ind2sub(image_size, indices);
    points_coords = ArraysToPoints(i2_coords, j2_coords, k2_coords);
end


function points = ArraysToPoints(i, j, k)
    points = [i(:), j(:), k(:), ones(size(i(:)))];
end


function [is, js, ks] = PointsToArrays(points)
    is = points(:, 1);
    js = points(:, 2);
    ks = points(:, 3);
end
