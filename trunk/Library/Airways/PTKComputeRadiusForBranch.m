function next_result = PTKComputeRadiusForBranch(next_segment, lung_image_as_double, radius_approximation, figure_airways_3d)
    % PTKComputeRadiusForBranch. Image-derived radius estimation of an airway.
    %
    %     PTKComputeRadiusForBranch creates a projection of the lung image
    %     perpendicular to the centrepoint of the airway branch and uses a FWHM
    %     method to estimate the airway radius.
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %       
    
    image_size = lung_image_as_double.ImageSize;
    next_result = [];
    generation_number = next_segment.GenerationNumber;
    points_indices = next_segment.Points;
    if ~isempty(next_segment.Parent)
        first_point = next_segment.Parent.Points(end);
        points_indices = [first_point, points_indices];
    end
    
    expected_radius_mm = mode(radius_approximation.RawImage(points_indices));
    [px, py, pz] = ind2sub(image_size, points_indices');
    knot = [px, py, pz];
    
    % Generate a spline curve through the centreline points
    % Currently this is not used in the radius computation
    spline = GenerateSpline(knot, 2);
    
    % Find points at 1/4, 1/2 and 3/4 way along the centreline
    % We will compute the radius between these points
    number_knots = size(knot, 1);
    quarter_point_index = max(1, round(number_knots/4));
    three_quarter_point_index = min(number_knots, round(3*number_knots/4));
    
    % We compute the radius between the 1/4 and 3/4 points on the centreline
    first_radius_index = quarter_point_index;
    last_radius_index = three_quarter_point_index;
    
    % To compute the direction vector, we select two points on the centreline.
    % If the airway is long enough, we use the 1/4 and 3/4 points. For shorter
    % airways we chooser further away points to get a better centreline
    if abs(three_quarter_point_index - quarter_point_index) < 4
        quarter_point_index = max(1, quarter_point_index - 2);
    end
    if abs(three_quarter_point_index - quarter_point_index) < 4
        three_quarter_point_index = min(number_knots, three_quarter_point_index + 2);
    end

    % Compute the direction based on the selected points
    direction_vector_voxels = knot(three_quarter_point_index, :) - knot(quarter_point_index, :);
    
    radius_mm_allknots = [];
    wall_thickness_mm_allknots = [];
    global_coords_list = [];
    
    middle_point = first_radius_index + round((last_radius_index - first_radius_index)/2);
    
    for central_knot_index = first_radius_index : last_radius_index
        
        % Only show the figure if this is the centre point
        if central_knot_index == middle_point
            debug_figure = figure_airways_3d;
        else
            debug_figure = [];
        end
        central_knot = knot(central_knot_index, :);
        [radius_mm_list, wall_thickness_mm_list, global_coords] = GetRadiusAndCentrepoint(central_knot, direction_vector_voxels, ...
            lung_image_as_double, expected_radius_mm, lung_image_as_double.VoxelSize, debug_figure);
        if ~isempty(radius_mm_list)
            radius_mm_allknots = [radius_mm_allknots; radius_mm_list'];
            wall_thickness_mm_allknots = [wall_thickness_mm_allknots; wall_thickness_mm_list'];
            global_coords_list = [global_coords_list; global_coords];
        end
    end
    
    radius_results = [];
    
    radius_results.RadiusMin = min(radius_mm_allknots);
    radius_results.RadiusMax = max(radius_mm_allknots);
    radius_results.RadiusMean = mean(radius_mm_allknots);
    radius_results.RadiusStdev = std(radius_mm_allknots);

    radius_results.WallThicknessMin = min(wall_thickness_mm_allknots);
    radius_results.WallThicknessMax = max(wall_thickness_mm_allknots);
    radius_results.WallThicknessMean = mean(wall_thickness_mm_allknots);
    radius_results.WallThicknessStdev = std(wall_thickness_mm_allknots);

    radius_results.CentrePoint = mean(global_coords_list, 1);
    
    radius_exp = sprintf('%7.2f', expected_radius_mm);
    radius_min = sprintf('%7.2f', radius_results.RadiusMin);
    radius_max = sprintf('%7.2f', radius_results.RadiusMax);
    radius_mean = sprintf('%7.2f', radius_results.RadiusMean);
    radius_std = sprintf('%7.2f', radius_results.RadiusStdev);
    wt_min = sprintf('%7.2f', radius_results.WallThicknessMin);
    wt_max = sprintf('%7.2f', radius_results.WallThicknessMax);
    wt_mean = sprintf('%7.2f', radius_results.WallThicknessMean);
    wt_std = sprintf('%7.2f', radius_results.WallThicknessStdev);
    
    next_result.CentrelinePoints = knot;
    next_result.CentrelineSpline = spline';
    next_result.Radius = radius_results.RadiusMean;
    next_result.WallThickness = radius_results.WallThicknessMean;
    
    disp(['Generation:' int2str(generation_number) ', Radius: Expected:' radius_exp 'mm, Mean:' radius_mean ...
        ' SD:' radius_std ' Min:' radius_min ' Max:' radius_max]);
    disp(['Generation:' int2str(generation_number) ', Wall Thickness: Mean:' wt_mean ...
        ' SD:' wt_std ' Min:' wt_min ' Max:' wt_max]);
end


function [radius_mm_list, wall_thickness_mm_list, global_coords] = GetRadiusAndCentrepoint(centre_point_voxels, direction_vector_voxels, ...
        lung_image_as_double, expected_radius_mm, voxel_size_mm, figure_airways_3d)
    
    % Determine number of different angles to use to capture the whole
    % airway cross-section
    min_voxel_size_mm = min(voxel_size_mm);
    delta_theta = (1/2)*asin(min_voxel_size_mm/expected_radius_mm);
    number_angles = pi/delta_theta;
    number_angles = 4*ceil(number_angles/4);
    angle_range = linspace(0, pi, number_angles);
    
    % Determine number of radii steps
    % We take a radius step size of half the minimum voxel size and
    % extend it to a multiple of the estimated radius
    radius_multiple = 5;
    step_size_mm = min_voxel_size_mm/2;
    airway_max_mm = step_size_mm*(ceil(radius_multiple*expected_radius_mm/step_size_mm));
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
    values = interpn(lung_image_as_double.RawImage, i_coord_voxels(:), j_coord_voxels(:), k_coord_voxels(:), 'cubic');
    
    interp_image = zeros(size(i_coord_voxels), 'double');
    interp_image(:) = values(:);
    
    % Limit the intensity values to a threshold in order to prevent
    % airway wall measurement being skewed by nearby high intensity
    % tissue
    min_hu = -1024;
    max_hu = 0;
    min_intensity = lung_image_as_double.HounsfieldToGreyscale(min_hu);
    max_intensity = lung_image_as_double.HounsfieldToGreyscale(max_hu);
    interp_image = max(double(min_intensity), interp_image);
    interp_image = min(double(max_intensity), interp_image);
    midpoint = ceil(size(interp_image, 1)/2);
    upper_half = interp_image(midpoint:end, :);
    lower_half = interp_image(midpoint:-1:1, :);
    
    [upper_wall_indices, wall_mask_upper, upper_wall_indices_refined, outer_upper_wall_indices, outer_wall_mask_upper] = FindWall(upper_half);
    [lower_wall_indices, wall_mask_lower, lower_wall_indices_refined, outer_lower_wall_indices, outer_wall_mask_lower] = FindWall(lower_half);
    
    % Indices that could not be found have index -1
    mask = (upper_wall_indices >= 0) & (lower_wall_indices >= 0);
    upper_wall_indices = upper_wall_indices + midpoint - 1;
    lower_wall_indices = midpoint + 1 - lower_wall_indices;
    upper_wall_indices_refined = upper_wall_indices_refined + midpoint - 1;
    lower_wall_indices_refined = midpoint + 1 - lower_wall_indices_refined;
    
    outer_mask_upper = (outer_upper_wall_indices >= 0) & (upper_wall_indices >= 0);
    outer_mask_lower = (outer_lower_wall_indices >= 0) & (lower_wall_indices >= 0);
    outer_upper_wall_indices = outer_upper_wall_indices + midpoint - 1;
    outer_lower_wall_indices = midpoint + 1 - outer_lower_wall_indices;
    
    % Compute the wall thickness
    wall_thickness_upper_mm = (outer_upper_wall_indices(outer_mask_upper) - upper_wall_indices(outer_mask_upper))*step_size_mm;
    wall_thickness_lower_mm = (lower_wall_indices(outer_mask_lower) - outer_lower_wall_indices(outer_mask_lower))*step_size_mm;
    wall_thickness_mm_list = [wall_thickness_upper_mm, wall_thickness_lower_mm];
    wall_thickness_mm_list = max(step_size_mm, wall_thickness_mm_list);
    
    % Extract out only the valid values
    upper_wall_indices_refined = upper_wall_indices_refined(mask);
    lower_wall_indices_refined = lower_wall_indices_refined(mask);
    upper_wall_indices = upper_wall_indices(mask);
    lower_wall_indices = lower_wall_indices(mask);
    
    diameters_mm = abs(upper_wall_indices_refined - lower_wall_indices_refined)*step_size_mm;
    radius_mm_list = diameters_mm/2;

    midpoints = (upper_wall_indices_refined + lower_wall_indices_refined) / 2 - midpoint;
    
    midpoints_mm = midpoints*step_size_mm;
    [mp_i, mp_j, mp_k] = PolarToGlobal(midpoints_mm, angle_range(mask), centre_point_voxels, voxel_size_mm, x_prime_norm, y_prime_norm);
    
    global_coords = [mean(mp_i), mean(mp_j), mean(mp_k)];
    
    % Debugging
    if ~isempty(figure_airways_3d)
        figure_handle = ShowInterpolatedWall(interp_image, midpoints, mask, wall_mask_upper, wall_mask_lower, outer_wall_mask_upper, outer_wall_mask_lower, midpoint, airway_max_mm);
        ShowInterpolatedCoordinatesOn3dFigure(figure_airways_3d, lung_image_as_double, centre_point_voxels, i_coord_voxels, j_coord_voxels, k_coord_voxels)
        
        file_name = '/Users/tom/Desktop/AirwaysWithRadiusFinding3D-TEST';
        resolution_dpi = 600;
        resolution_str = ['-r' num2str(resolution_dpi)];
        print(figure_airways_3d, '-dpng', resolution_str, file_name);     % Export to .png
        print(figure_airways_3d, '-depsc2', '-painters', resolution_str, file_name);

    end
end

% For showing the stretched out wall with midpoints and walls superimposed
function figure_handle = ShowInterpolatedWall(interp_image, midpoints_part, midpoints_mask, wall_mask_upper, wall_mask_lower, outer_wall_mask_upper, outer_wall_mask_lower, midpoint, airway_max_mm)
    
    midpoint_colour = 3;
    
    viewer = PTKViewer(interp_image, PTKImageType.Grayscale);
    viewer.ViewerPanelHandle.Orientation = PTKImageOrientation.Axial;
    midpoints = zeros(size(midpoints_mask));
    midpoints(midpoints_mask) = midpoints_part + midpoint - 1;
    midpoint_repeated = repmat(round(midpoints), [size(interp_image, 1), 1]);
    radii_indices = (1 : size(interp_image, 1))';
    radii_repeated = repmat(radii_indices, [1, size(interp_image, 2)]);
    mp = midpoint_repeated == radii_repeated;
    
    
    wall_overlay = zeros(size(interp_image), 'uint8');
    wall_overlay(midpoint:end, :) = wall_mask_upper + 2*outer_wall_mask_upper;
    wall_overlay(midpoint:-1:1, :) = wall_mask_lower + 2*outer_wall_mask_lower;
    wall_overlay(mp) = midpoint_colour;
    
    viewer.ViewerPanelHandle.OverlayImage = PTKImage(wall_overlay);
    
    
    interp_image_full = [interp_image(end:-1:midpoint,:), interp_image(1:midpoint,:)];
    viewer2 = PTKViewer(interp_image_full, PTKImageType.Grayscale);
    viewer2.ViewerPanelHandle.Orientation = PTKImageOrientation.Axial;

    wall_overlay_full = [wall_overlay(end:-1:midpoint, :), wall_overlay(1:midpoint, :)];
    viewer2.ViewerPanelHandle.OverlayImage = PTKImage(wall_overlay_full);
    
    viewer2.ViewerPanelHandle.Window = 928;
    viewer2.ViewerPanelHandle.Level = -200; % 272;
    frame = viewer2.ViewerPanelHandle.Capture;
    
    figure(11);
    figure_handle = gcf;
    imagesc([0, 360], [airway_max_mm, 0], frame.cdata);
    
    label_font_size = 9;
    axis_line_width = 1;
    axes_label_font_size = 7;
    widthheightratio = 4/3;
    page_width_cm = 12;
    resolution_dpi = 600;
    font_name = PTKSoftwareInfo.GraphFont;

    set(figure_handle, 'Units','centimeters');
    graph_size = [page_width_cm, (page_width_cm/widthheightratio)];
    
    axes_handle = gca;
    set(figure_handle, 'Name', 'FWHM');
    set(figure_handle, 'PaperPositionMode', 'auto');
    set(figure_handle, 'position', [0,0, graph_size]);
    
    hold(axes_handle, 'on');
    axis manual
    
    axes_handle = gca;
    set(axes_handle, 'FontSize', axes_label_font_size);
    set(axes_handle, 'LineWidth', axis_line_width);
    
    xlabel('\theta (degrees)', 'FontName', font_name, 'FontSize', label_font_size);
    ylabel('r (mm)', 'FontName', font_name, 'FontSize', label_font_size);
    set(gca,'YDir','normal')
    
    resolution_str = ['-r' num2str(resolution_dpi)];
    print(figure_handle, '-dpng', resolution_str, '~\Desktop\Radius finding 2D.png');     % export .png
    
end

function ShowInterpolatedCoordinatesOn3dFigure(figure_airways_3d, lung_image, centre_point_voxels, i_coord_voxels, j_coord_voxels, k_coord_voxels)
    figure(figure_airways_3d);
    hold on;

    global_centre_point_voxels = lung_image.LocalToGlobalCoordinates([centre_point_voxels(:, 1), centre_point_voxels(:, 2), centre_point_voxels(:, 3)]);
    [ic_cp, jc_cp, kc_cp] = lung_image.GlobalCoordinatesToCoordinatesMm(global_centre_point_voxels);
    [xc_cp, yc_cp, zc_cp] = lung_image.GlobalCoordinatesMmToCornerCoordinates(ic_cp, jc_cp, kc_cp);
    plot3(xc_cp, yc_cp, zc_cp, 'rx', 'MarkerSize', 10);
    
    global_coordinates = lung_image.LocalToGlobalCoordinates([i_coord_voxels(:), j_coord_voxels(:), k_coord_voxels(:)]);
    [ic, jc, kc] = lung_image.GlobalCoordinatesToCoordinatesMm(global_coordinates);
    [xc, yc, zc] = lung_image.GlobalCoordinatesMmToCornerCoordinates(ic, jc, kc);
    
    plot3(xc(:), yc(:), zc(:), 'r.');
end

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

function [wall_indices, wall_mask, refined_wall_indices, outer_wall_indices, outer_wall_mask] = FindWall(half_image)
    
    % We need to store a copy of the image for the refinement later
    original_half_image = half_image;
    
    % Create another image for computing the outer radius
    outer_half_image = half_image;
    
    number_of_radii = size(half_image, 1);
    number_of_angles = size(half_image, 2);
    
    radii_indices = (1 : number_of_radii)';
    radii_indices_repeated = repmat(radii_indices, [1, number_of_angles]);
    
    % Find the maxima in each column - each column represents one radial line
    [max_val, max_indices] = max(half_image, [], 1);
    
    % If the maxima is very low in some of the columns, replace it with the mean
    % of the other maxima. This can happen if the airway wall is located off the
    % end of the image or due to partial volume effects. Replacing the value
    % with the mean allows us to still find the half maximum value
    [max_val, values_replaced] = ReplaceOutliersWithMean(max_val);
    
    % Maxima which have been replaced should be located off the image, so that
    % no pixels are removed from that column in the search for the minima
    max_indices(values_replaced) = number_of_radii + 1;
    
    max_val_repeated = repmat(max_val, [number_of_radii, 1]);
    max_indices_repeated = repmat(max_indices, [number_of_radii, 1]);
    
    % Points beyond the maxima are set to the maxima values
    indices_outside_range = radii_indices_repeated > max_indices_repeated;
    half_image(indices_outside_range) = max_val_repeated(indices_outside_range);
    
    % Do the same for the outer radius approximation
    outer_half_image(~indices_outside_range) = max_val_repeated(~indices_outside_range);
    
    % Find the minima in each column
    [min_val, ~] = min(half_image, [], 1);
    
    % Find the midway value between maxima and minima for each column
    halfmax = (max_val + min_val)/2;
    halfmax_repeated = repmat(halfmax, [number_of_radii, 1]);
    
    % Find points above the half maximum value
    % Some columns may have no value above this
    values_above_halfmax = half_image >= halfmax_repeated;    
    halfmax_points_found = any(values_above_halfmax, 1);
    
    % For outer radius, find points below the half maximum value
    values_below_halfmax_outer = outer_half_image <= halfmax_repeated;
    outer_halfmax_points_found = any(values_below_halfmax_outer, 1);
    
    % Find the first values which go above the half maximum value - max
    % will return the indices of the first point in each column
    [~, indices_halfpoint] = max(values_above_halfmax, [], 1);
    indices_halfpoint(~halfmax_points_found) = -1;
    wall_indices = indices_halfpoint;
    halfpoint_indices_repeated = repmat(indices_halfpoint, [number_of_radii, 1]);
    mask_maxima = halfpoint_indices_repeated == radii_indices_repeated;
    
    % For outer wall, find the first values which go below the half maximum value - max
    % will return the indices of the first point in each column
    [~, indices_halfpoint_outer] = max(values_below_halfmax_outer, [], 1);
    indices_halfpoint_outer(~outer_halfmax_points_found) = -1;
    outer_wall_indices = indices_halfpoint_outer;
    halfpoint_indices_repeated_outer = repmat(indices_halfpoint_outer, [number_of_radii, 1]);
    mask_maxima_outer = halfpoint_indices_repeated_outer == radii_indices_repeated;

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
    outer_wall_mask = uint8(radii_indices_repeated == repmat(indices_halfpoint_outer, [number_of_radii, 1]));
end

function [values, values_replaced] = ReplaceOutliersWithMean(values)

    remaining_values = values;    
    below_threshold = true;
    
    % Iteratively remove outliers and recompute the mean after each removal
    while any(below_threshold)
        below_threshold = remaining_values < mean(remaining_values)/5;
        remaining_values = remaining_values(~below_threshold);
    end
    
    % Now using the new mean, replace outliers with this mean
    adjusted_mean = mean(remaining_values);
    values_replaced = values < adjusted_mean/5;
    
    values(values_replaced) = adjusted_mean;
end

function value = GenerateSpline(knots, num_points)
    knots_add=zeros(size(knots, 1) + 2, size(knots, 2));
    knots_add(2 : size(knots, 1) + 1, :) = knots;
    knots_add(1, :) = knots_add(2, :) - (knots_add(3, :) - knots_add(2, :));
    knots_add(end, :) = knots_add(end - 1, :) - (knots_add(end - 2, : ) - knots_add(end - 1, :));
    
    total_knots = size(knots_add, 1);
    inter_values = 0 : 1/num_points : 1;
    inter_values2 = inter_values.^2;
    inter_values3 = inter_values.^3;

    for index = 2 : total_knots-2
        coeffs = (1/6).*[knots_add(index - 1,:) + 4*knots_add(index, :)+knots_add(index + 1, :); ...
                    - 3*knots_add(index - 1, :) + 3*knots_add(index + 1, :); ...
                    3*knots_add(index - 1, :) - 6*knots_add(index, :) + 3*knots_add(index + 1, :); ...
                    - knots_add(index - 1, :) + 3*knots_add(index, :) - 3*knots_add(index + 1, :) + knots_add(index+2, :)]';
            
        interv = [ones(size(inter_values)); inter_values; inter_values2; inter_values3];
        value(:, (index - 2)*num_points + 1:(index - 1)*num_points + 1) = coeffs*interv;
    end
end
