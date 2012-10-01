function [top_of_trachea, trachea_voxels] = TDFindTopOfTrachea(lung_image, reporting)
    % TDFindTopOfTrachea. Finds the trachea from a thresholded lung CT image.
    %
    % Given a binary image which representes an airway threshold applied to a
    % lung CT image, TDFindTopOfTrachea finds the coordinate of a point
    % within and near the top of the trachea
    %
    % Syntax:
    %     top_of_trachea = TDFindTopOfTrachea(lung_image, reporting)
    %     [top_of_trachea, trachea_voxels] = TDFindTopOfTrachea(lung_image, reporting)
    %
    % Inputs:
    %     lung_image - a lung volume stored as a TDImage which has been
    %         thresholded for air voxels (1=air, 0=background).
    %         Note: the lung volume can be a region-of-interest, or the entire
    %         volume. To ensure correct results, TDImage usage guidelines 
    %         should be followed, i.e. a TDImage should be formed from the
    %         original (uncropped) dataset, and the methods of TDImage used to
    %         crop the image, so that the correct VoxelSize,
    %         OriginalImageSize and Origin parameters are set.
    %
    %     reporting (optional) - an object implementing the TDReporting
    %         interface for reporting progress and warnings
    %
    % Outputs:
    %     top_of_trachea - coordinate (i,j,k) of a point inside and near the top
    %         of the trachea
    %
    %     trachea_voxels - voxel indices (relative to the input image) of
    %         voxels within the trachea
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    if ~isa(lung_image, 'TDImage')
        error('Requires a TDImage as input');
    end
    
    if nargin < 2
        reporting = TDReportingDefault;
    end
    
    reporting.UpdateProgressMessage('Finding top of trachea');
    image_size = lung_image.ImageSize;
    
    % The algorithm works faster if we are supplied with a region of
    % interest. However, it is critical that we know where the midpoint
    % (on the x-y plane) of the original scan is. This is not always the
    % midpoint of the ROI, e.g. if one of the lungs is blocked.
    if isempty(lung_image.OriginalImageSize)
        reporting.ShowWarning('TDFindTopOfTrachea:NoOriginalImageSize', 'OriginalImageSize not found for this image. Using default values', []);
        midpoint_roi = round(image_size/2);
    else
        % Find the midpoint of the original image
        full_image_size = lung_image.OriginalImageSize;
        midpoint_full_image = round(full_image_size/2);
        
        % Find the midpoint in the coordinates of the reduced ROI image
        midpoint_roi = midpoint_full_image - lung_image.Origin + [1, 1, 1];
    end
    
    % Compute the number of voxels over which we will search for the
    % trachea - typically this will be about half of the image size
    % in x,y and a third of the image length in the z direction
    search_length_mm = [200, 150, 130];
    search_length_voxels = round(search_length_mm./lung_image.VoxelSize);
    
    % Compute the starting and ending coordinates over which to search in
    % the x and y directions
    startpoint = midpoint_roi - round(search_length_voxels/2);
    endpoint = midpoint_roi + round(search_length_voxels/2);
    startpoint = max(1, startpoint);
    endpoint = min(image_size, endpoint);
    
    %Compute the start and end coordinates in the z direction
    startpoint(3) = 1;
    endpoint(3) = search_length_voxels(3);
    
    % Crop the image
    partial_image = lung_image.RawImage(startpoint(1):endpoint(1), startpoint(2):endpoint(2), startpoint(3):endpoint(3));
    
    % First pass: iterate through 2-slice thick segments and remove components
    % that are too wide or which touch the edges. The first pass helps to
    % disconnect the trachea from the rest of the lung, so that less of the
    % trachea is removed in the second pass.
    partial_image2 = ReduceImageToCentralComponents(partial_image, 2, lung_image.VoxelSize, 1, reporting);
    
    % Second pass: repeat with a thicker slice. This is more effective at
    % removing the lungs but could also delete the lower trachea - we mitigate this by disconnecting the trachea in the first pass.
    partial_image2 = ReduceImageToCentralComponents(partial_image2, 10, lung_image.VoxelSize, 2, reporting);
    
    % Reduce the image to the main component
    result = FindLargestComponent(partial_image2);
    
    % Find coordinates of highest point in the resulting image
    relative_top_of_trachea = FindHighestPoint(result, lung_image.VoxelSize);
    top_of_trachea = relative_top_of_trachea + startpoint - [1, 1, 1];
    
    % Convert to global image coordinates
    top_of_trachea = lung_image.LocalToGlobalCoordinates(top_of_trachea);
    
    if (nargout > 1)
        % Store all the trachea voxels
        trachea_voxels = find(result(:));
        [is, js, ks] = ind2sub(size(result), trachea_voxels);
        is = is + startpoint(1) - 1;
        js = js + startpoint(2) - 1;
        ks = ks + startpoint(3) - 1;
        trachea_voxels = sub2ind(image_size, is, js, ks);
        
        % Convert to global indices
        trachea_voxels = lung_image.LocalToGlobalIndices(trachea_voxels);
    end
    
end

function relative_top_of_trachea = FindHighestPoint(component, voxel_size)
    
    % Find k-coordinate of highest point in the image component
    k_highest = find(any(any(component, 1), 2), 1, 'first');
    
    % Get a thick slice starting from this coordinate
    slice_thickness_mm = 3;
    voxel_thickness = ceil(slice_thickness_mm/voxel_size(3));
    thick_slice = component(:, :, k_highest : k_highest+voxel_thickness-1);
    voxel_indices = find(thick_slice(:));
    
    % Find the centrepoint
    centroid = GetCentroid(voxel_indices, size(thick_slice));
    
    % Look for a central point at the top
    centrepoint = [centroid(1), centroid(2), 1];
    
    % Get coordinates of all the points
    all_points = find(thick_slice(:));
    [p_x, p_y, p_z] = ind2sub(size(thick_slice), all_points);
    
    % Find closest point in the component to this point
    X = double([p_x, p_y, p_z]);
    nearest_point_index_index = dsearchn(X, centrepoint);
    
    % Return point in [i,j,k] notation
    [i, j, k] = ind2sub(size(thick_slice), all_points(nearest_point_index_index));
    relative_top_of_trachea = [i, j, k + k_highest - 1];
    
    %     [i j] = find(component(:, :, k), 1);
    
end

function centroid = GetCentroid(indices, image_size)
    [i, j, k] = ind2sub(image_size, indices);
    centroid = zeros(1, 3);
    centroid(1) = mean(i);
    centroid(2) = mean(j);
    centroid(3) = mean(k);
end


function result = ReduceImageToCentralComponents(image_to_reduce, slices_per_step, voxel_size, reporting_stage, reporting)
    result = false(size(image_to_reduce));

    % for images with thick slices, we need to choose the minimum voxel size, not the maximum
    max_xy_voxel_size = min(voxel_size(1), voxel_size(2));
%     max_xy_voxel_size = max(voxel_size(1), voxel_size(2));
    
    % Compute a maximum for the trachea diameter - we will filter out structures
    % wider than this
    max_trachea_diameter_mm = 30;
    max_trachea_diameter = max_trachea_diameter_mm/max_xy_voxel_size; % typically about 80 voxels
    
    % Compute an additional factor for the permitted diameter to take into
    % account that the trachea may not be vertical when computing over multiple
    % slices
    vertical_height_mm = slices_per_step*voxel_size(3);
    permitted_horizontal_trachea_movement_mm = vertical_height_mm;
    permitted_horizontal_trachea_movement_voxels = permitted_horizontal_trachea_movement_mm/max_xy_voxel_size;
    
    % The trachea may be at an angle so we take into account movement between
    % slices by increasing the maximum permitted diameter by the factor computed
    % above
    max_trachea_diameter = max_trachea_diameter + permitted_horizontal_trachea_movement_voxels;
    
    % We add a border in the x and y (horizontal) directions - we use this to
    % remove components which touch these borders
    border_slice = false(size(image_to_reduce, 1), size(image_to_reduce, 2), slices_per_step);
    border_slice(1, :, :) = true;
    border_slice(end, :, :) = true;
    border_slice(:, 1, :) = true;
    border_slice(:, end, :) = true;
    num_slices = size(image_to_reduce, 3);
    num_slices = slices_per_step*floor(num_slices/slices_per_step);
    
    % Iterate through all slices
    for k_index = 1 : slices_per_step : num_slices
        reporting.UpdateProgressValue((reporting_stage - 1)*50 + round(50*k_index/num_slices));
        k_max = k_index + slices_per_step - 1;
        slice = logical(image_to_reduce(:, :, k_index : k_max));
        slice = slice | border_slice;
        if slices_per_step == 1
            connected_components = bwconncomp(slice, 8); % 2D connected components
        else
            connected_components = bwconncomp(slice, 26); % 3D connected components
        end
        stats = regionprops(connected_components, 'BoundingBox');
        
        % Iterate through all components
        for component_index = 1 : connected_components.NumObjects
            pixels = connected_components.PixelIdxList{component_index};
            bounding_box = stats(component_index).BoundingBox;
            width = bounding_box(3:4);
            
            % Remove components greater than a certain size in the i and j
            % dimensions, and remove and components which connect to the
            % edge
            if (any(pixels == 1)) || (width(1) > max_trachea_diameter) || (width(2) > max_trachea_diameter)
                slice(pixels) = false;
            end
        end
        
        slice = FillHoles(slice);
        result(:, :, k_index : k_max) = slice;
    end
end

function thick_slice = FillHoles(thick_slice)
    for k_index = 1 : size(thick_slice, 3)
        slice = thick_slice(:, :, k_index);
        connected_components = bwconncomp(~slice, 4);
        
        % Iterate through all components
        for component_index = 1 : connected_components.NumObjects
            pixels = connected_components.PixelIdxList{component_index};
            
            % Add components that aren't connected to the edge
            if ~any(pixels == 1)
                slice(pixels) = true;
            end
        end
        thick_slice(:, :, k_index) = slice;
    end
end

function result = FindLargestComponent(mask)
    result = false(size(mask));
    connected_components = bwconncomp(mask, 26);
    num_pixels = cellfun(@numel, connected_components.PixelIdxList);
    [~, sorted_largest_areas_indices] = sort(num_pixels, 'descend');
    voxels = connected_components.PixelIdxList{sorted_largest_areas_indices(1)};
    result(voxels) = true;
end
