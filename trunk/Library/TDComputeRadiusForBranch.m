function next_result = TDComputeRadiusForBranch(next_segment, lung_image, dt_image)
    % TDComputeRadiusForBranch. Image-derived radius estimation of an airway.
    %
    %     TDComputeRadiusForBranch creates a projection of the lung image
    %     perpendicular to the centrepoint of the airway branch and uses a FWHM
    %     method to estimate the airway radius.
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %       
    
    
    min_voxel_size_mm = min(lung_image.VoxelSize);
    image_size = lung_image.ImageSize;
    next_result = [];
    generation_number = next_segment.GenerationNumber;
    points_indices = next_segment.Points;
    if ~isempty(next_segment.Parent)
        first_point = next_segment.Parent.Points(end);
        points_indices = [first_point, points_indices];
    end
    dt_at_points = dt_image(points_indices);
    expected_radius_mm = mean(dt_at_points)*min_voxel_size_mm;
    [px, py, pz] = ind2sub(image_size, points_indices');
    knot = [px, py, pz];
    
    % ToDo: Change number of spline points
    spline = GenerateSpline(knot, 2);
    
    % Find image perpendicular to airway
    number_knots = size(knot, 1);
    central_knot_index = max(1, round(number_knots/2));
    central_knot = knot(central_knot_index, :);
    forward_knot_index = min(number_knots, central_knot_index + 3);
    backward_knot_index = max(1, central_knot_index - 3);
    direction_vector_voxels = knot(forward_knot_index, :) - knot(backward_knot_index, :);
    radius_results = GetRadiusAndCentrepoint(central_knot, direction_vector_voxels, ...
        lung_image, expected_radius_mm, lung_image.VoxelSize);
    
    radius_exp = sprintf('%7.2f', expected_radius_mm);
    radius_min = sprintf('%7.2f', radius_results.RadiusMin);
    radius_max = sprintf('%7.2f', radius_results.RadiusMax);
    radius_mean = sprintf('%7.2f', radius_results.RadiusMean);
    radius_std = sprintf('%7.2f', radius_results.RadiusStdev);
    
    next_result.CentrelinePoints = knot;
    next_result.CentrelineSpline = spline';
    next_result.Radius = radius_results.RadiusMean;
    
    disp(['Generation:' int2str(generation_number) ', Radius: Expected:' radius_exp 'mm, Mean:' radius_mean ...
        ' SD:' radius_std ' Min:' radius_min ' Max:' radius_max]);
end


function results = GetRadiusAndCentrepoint(centre_point_voxels, direction_vector_voxels, ...
        lung_image, expected_radius_mm, voxel_size_mm)
    
    % Determine number of different angles to use to capture the whole
    % airway cross-section
    min_voxel_size_mm = min(voxel_size_mm);
    delta_theta = (1/2)*asin(min_voxel_size_mm/expected_radius_mm);
    number_angles = pi/delta_theta;
    number_angles = 4*ceil(number_angles/4);
    angle_range = linspace(0, pi, number_angles);
    
    % Determine number of radii steps
    % We take a radius step size of half the minimum voxel size and
    % extend it to twice the estimated radius
    step_size_mm = min_voxel_size_mm/2;
    airway_max_mm = step_size_mm*(ceil(2*expected_radius_mm/step_size_mm));
    radius_range_upper = step_size_mm : step_size_mm : airway_max_mm;
    
    % Construct the radius range, ensuring there is a point at exactly
    % zero
    radius_range = [-radius_range_upper(end:-1:1), 0, radius_range_upper];
    
    % Find x' and y' vectors in the plane perpendicular to the direction
    direction_vector_norm = direction_vector_voxels.*voxel_size_mm;
    plane_null_space = null(direction_vector_norm/norm(direction_vector_norm));
    x_prime_norm = plane_null_space(:, 1);
    y_prime_norm = plane_null_space(:, 2);
    
    % Compute a grid in polar coordinates
    [r, theta] = ndgrid(radius_range, angle_range);
    
    % Compute the corresponding cartesian coordinates
    [i_coord_voxels, j_coord_voxels, k_coord_voxels] = PolarToGlobal(r, theta, centre_point_voxels, voxel_size_mm, x_prime_norm, y_prime_norm);
    
    % Interpolate the lung image
    % ToDo: consider cubic interpolation
    values = interpn(double(lung_image.RawImage), i_coord_voxels(:), j_coord_voxels(:), k_coord_voxels(:));
    interp_image = zeros(size(i_coord_voxels), 'double');
    interp_image(:) = values(:);
    
    % Limit the intensity values to a threshold in order to prevent
    % airway wall measurement being skewed by nearby high intensity
    % tissue
    min_hu = -1024;
    max_hu = 0;
    min_intensity = lung_image.HounsfieldToGreyscale(min_hu);
    max_intensity = lung_image.HounsfieldToGreyscale(max_hu);
    interp_image = max(double(min_intensity), interp_image);
    interp_image = min(double(max_intensity), interp_image);
    midpoint = ceil(size(interp_image, 1)/2);
    upper_half = interp_image(midpoint:end, :);
    lower_half = interp_image(midpoint:-1:1, :);
    
    [upper_wall_indices, wall_mask_upper, upper_wall_indices_refined] = FindWall(upper_half);
    [lower_wall_indices, wall_mask_lower, lower_wall_indices_refined] = FindWall(lower_half);
    
    upper_wall_indices = upper_wall_indices + midpoint - 1;
    lower_wall_indices = midpoint + 1 - lower_wall_indices;
    upper_wall_indices_refined = upper_wall_indices_refined + midpoint - 1;
    lower_wall_indices_refined = midpoint + 1 - lower_wall_indices_refined;
    
    diameters_mm = abs(upper_wall_indices_refined - lower_wall_indices_refined)*step_size_mm;
    radius_mm = diameters_mm/2;
    
    midpoints = (upper_wall_indices_refined + lower_wall_indices_refined) / 2 - midpoint;
    
    midpoints_mm = midpoints*step_size_mm;
    [mp_i, mp_j, mp_k] = PolarToGlobal(midpoints_mm, angle_range, centre_point_voxels, voxel_size_mm, x_prime_norm, y_prime_norm);
    
    results = [];
    results.RadiusMin = min(radius_mm);
    results.RadiusMax = max(radius_mm);
    results.RadiusMean = mean(radius_mm);
    results.RadiusStdev = std(radius_mm);
    results.CentrePoint = [mean(mp_i), mean(mp_j), mean(mp_k)];
    
    %             TDAirwayRadius.ShowInterpolatedWall(interp_image, midpoints, wall_mask_upper, wall_mask_lower, midpoint);
    %             TDAirwayRadius.ShowInterpolatedCoordinatesOn3dFigure(figure_airways_3d, lung_image.ImageSize, centre_point_voxels, i_coord_voxels, j_coord_voxels, k_coord_voxels)
end

% % For showing the stretched out wall with midpoints and walls superimposed
% function ShowInterpolatedWall(interp_image, midpoints, wall_mask_upper, wall_mask_lower, midpoint)
%     figure(2);
%     viewer = TDViewer(interp_image, TDImageType.Grayscale);
%     viewer.ViewerPanelHandle.Orientation = TDImageOrientation.Axial;
%     midpoint_repeated = repmat(round(midpoints), [size(interp_image, 1), 1]);
%     radii_indices = (1 : size(interp_image, 1))';
%     radii_repeated = repmat(radii_indices, [1, size(interp_image, 2)]);
%     mp = midpoint_repeated == radii_repeated;
%     
%     
%     wall_overlay = zeros(size(interp_image), 'uint8');
%     wall_overlay(midpoint:end, :) = wall_mask_upper;
%     wall_overlay(midpoint:-1:1, :) = wall_mask_lower;
%     wall_overlay(mp) = 3;
%     viewer.ViewerPanelHandle.OverlayImage = TDImage(wall_overlay);
% end
% 
% function ShowInterpolatedCoordinatesOn3dFigure(figure_airways_3d, image_size, centre_point_voxels, i_coord_voxels, j_coord_voxels, k_coord_voxels)
%     figure(figure_airways_3d);
%     plot3(centre_point_voxels(2), centre_point_voxels(1), 1 + image_size(3) - centre_point_voxels(3), 'rx', 'MarkerSize', 10);
%     plot3(j_coord_voxels(:), i_coord_voxels(:), 1 + image_size(3) - k_coord_voxels(:), 'ro');
%     
% end

function [i_coord_voxels, j_coord_voxels, k_coord_voxels] = PolarToGlobal(r, theta, centre_point_voxels, voxel_size_mm, x_prime_norm, y_prime_norm)
    xp_coord_mm = r.*cos(theta);
    yp_coord_mm = r.*sin(theta);
    
    i_coord_mm = x_prime_norm(1)*xp_coord_mm + y_prime_norm(1)*yp_coord_mm;
    j_coord_mm = x_prime_norm(2)*xp_coord_mm + y_prime_norm(2)*yp_coord_mm;
    k_coord_mm = x_prime_norm(3)*xp_coord_mm + y_prime_norm(3)*yp_coord_mm;
    
    i_coord_voxels = centre_point_voxels(1) + i_coord_mm/voxel_size_mm(1);
    j_coord_voxels = centre_point_voxels(2) + j_coord_mm/voxel_size_mm(2);
    k_coord_voxels = centre_point_voxels(3) + k_coord_mm/voxel_size_mm(3);
    
end

function [wall_indices, wall_mask, refined_wall_indices] = FindWall(half_image)
    original_half_image = half_image;
    number_of_radii = size(half_image, 1);
    number_of_angles = size(half_image, 2);
    
    radii_indices = (1 : number_of_radii)';
    radii_indices_repeated = repmat(radii_indices, [1, number_of_angles]);
    
    % Find the maxima in each column - each column represents one radial line
    [max_val, max_indices] = max(half_image, [], 1);
    max_val_repeated = repmat(max_val, [number_of_radii, 1]);
    max_indices_repeated = repmat(max_indices, [number_of_radii, 1]);
    
    % Points beyond the maxima are set to the maxima values
    indices_outside_range = radii_indices_repeated > max_indices_repeated;
    half_image(indices_outside_range) = max_val_repeated(indices_outside_range);
    
    % Find the minima in each column
    [min_val, ~] = min(half_image, [], 1);
    
    % Find the midway value between maxima and minima for each column
    halfmax = (max_val + min_val)/2;
    halfmax_repeated = repmat(halfmax, [number_of_radii, 1]);
    
    % Find points above the half maximum value
    values_above_halfmax = half_image >= halfmax_repeated;
    
    % Find the first values which go above the half maximum value - max
    % will return the indices of the first point in each column
    [~, indices_halfpoint] = max(values_above_halfmax, [], 1);
    wall_indices = indices_halfpoint;
    halfpoint_indices_repeated = repmat(indices_halfpoint, [number_of_radii, 1]);
    mask_maxima = halfpoint_indices_repeated == radii_indices_repeated;
    
    % Compute a more refined calculation for airway edge using linear
    % interpolation
    gradients = zeros(size(original_half_image));
    gradients(2:end, :) = original_half_image(2:end, :) - original_half_image(1:end-1, :);
    difference_from_halfmax = original_half_image - halfmax_repeated;
    partial_offset = difference_from_halfmax./gradients;
    maxima_indices_refined = mask_maxima.*(halfpoint_indices_repeated - partial_offset);
    [refined_wall_indices, ~] = max(maxima_indices_refined, [], 1);
    
    % Create a mask of points on the interior airway walls
    wall_mask = uint8(radii_indices_repeated == repmat(indices_halfpoint, [number_of_radii, 1]));
end

