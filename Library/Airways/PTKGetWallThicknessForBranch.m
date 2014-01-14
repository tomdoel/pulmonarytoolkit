function results = PTKGetWallThicknessForBranch(bronchus, image_roi, context, figure_airways_3d, segmented_image)
    if isempty(bronchus)
        results = [];
    else
        segment_label = PTKPulmonarySegmentLabels(bronchus.SegmentIndex);
        centreline = bronchus.Centreline;
%         disp(['Number of points in centreline:', int2str(numel(centreline))]);
        
        radius_guess = bronchus.Radius;
        if (radius_guess == 0) || isnan(radius_guess)
            disp('Invalid radius found');
        end
        
        
        initial_smoothed_centreline = SmoothCentrelineByNeighbours(centreline);
        [direction_vector, first_radius_index, last_radius_index] = ComputeDirectionVector(initial_smoothed_centreline);
        
        current_centreline = initial_smoothed_centreline;
        
        plot_debug_graphs = false;
        
        max_iters = 20;
        max_mean_centreline_difference = 0.1;
        mean_centreline_difference = 10*max_mean_centreline_difference;
        iter = 0;
        max_jump_mm = 3;
        
        while (iter < max_iters) && (mean_centreline_difference > max_mean_centreline_difference)
            iter = iter + 1;
            [new_centreline, ~, ~, ~, ~] = RecomputeAllCentreline(current_centreline, direction_vector, image_roi, radius_guess, figure_airways_3d, segment_label, segmented_image, plot_debug_graphs, context);
            centreline_difference = CentrelineDifference(current_centreline, new_centreline);
            mean_centreline_difference = mean(centreline_difference);
            current_centreline = new_centreline;
            if any(centreline_difference > max_jump_mm)
                disp('Warning: some points in the centreline jumped by more than the maximum amount');
            end
        end
        
        if (mean_centreline_difference > mean_centreline_difference)
            disp(['Centrelines did not converge. Differnce:' num2str(centreline_difference)]);
        end
            
        
        plot_debug_graphs = PTKSoftwareInfo.GraphicalDebugMode;
        central_centreline = current_centreline(first_radius_index : last_radius_index);
        
        [new_centreline, radius_mean, radius_std, wall_thickness_mean, wall_thickness_std] = RecomputeAllCentreline(central_centreline, direction_vector, image_roi, radius_guess, figure_airways_3d, segment_label, segmented_image, plot_debug_graphs, context);
        
        
        results = [];
        results.FWHMRadiusMean = radius_mean;
        results.FWHMRadiusStd = radius_std;
        results.FWHMWallThicknessMean = wall_thickness_mean;
        results.FWHMWallThicknessStd = wall_thickness_std;
        results.Centreline = new_centreline;
        results.GridOverlayImage = segmented_image;
    end
end


function centreline_difference = CentrelineDifference(centreline_1, centreline_2)
    num_points = numel(centreline_1);
    centreline_difference = zeros(size(centreline_1));
    for point_index = 1 : num_points
        centreline_difference(point_index) = PTKPoint.Magnitude(PTKPoint.Difference(centreline_1(point_index), centreline_2(point_index)));
    end
end

function [direction_vector, first_radius_index, last_radius_index] = ComputeDirectionVector(centreline)
    
    % Find points at 1/4, 1/2 and 3/4 way along the centreline
    % We will compute the radius between these points
    number_points = numel(centreline);
    quarter_point_index = max(1, round(number_points/4));
    three_quarter_point_index = min(number_points, round(3*number_points/4));
    
    first_radius_index = quarter_point_index;
    last_radius_index = three_quarter_point_index;
    
    % To compute the direction vector, we select two points on the centreline.
    % If the airway is long enough, we use the 1/4 and 3/4 points. For shorter
    % airways we chooser further away points to get a better centreline
    if abs(three_quarter_point_index - quarter_point_index) < 4
        quarter_point_index = max(1, quarter_point_index - 2);
    end
    if abs(three_quarter_point_index - quarter_point_index) < 4
        three_quarter_point_index = min(number_points, three_quarter_point_index + 2);
    end

    % Compute the direction based on the selected points
    direction_vector = PTKPoint.Difference(centreline(three_quarter_point_index), centreline(quarter_point_index));
end

function smoothed_centreline = SmoothCentrelineByNeighbours(centreline)
    
    if numel(centreline) < 3
        % Can't smooth with fewer than 3 points
        smoothed_centreline = centreline;
        return;
    end
    
    % Average the coordinate of each point with its centrelines
    smoothed_centreline = PTKCentrelinePoint.empty;
    x_coords = [centreline.CoordX];
    y_coords = [centreline.CoordY];
    z_coords = [centreline.CoordZ];
    first_point_index = 1;
    last_point_index = numel(centreline);
    
    for c_index = first_point_index : last_point_index
        if c_index == first_point_index
            first_coord = c_index;
            last_coord = c_index + 1;
        elseif c_index == last_point_index
            first_coord = c_index - 1;
            last_coord = c_index;
        else
            first_coord = c_index - 1;
            last_coord = c_index + 1;
        end
        
        xmean = mean(x_coords(first_coord : last_coord));
        ymean = mean(y_coords(first_coord : last_coord));
        zmean = mean(z_coords(first_coord : last_coord));
        smoothed_centreline(c_index) = PTKCentrelinePoint(xmean, ymean, zmean, []);
    end 
end



function [new_centreline_points, mean_radius, std_radius, mean_wallthickness, std_wallthickness] = RecomputeAllCentreline(centre_points_mm, direction_vector, image_roi, radius_guess_mm, figure_airways_3d, segment_label, segmented_image, plot_debug_graphs, context)
    [x_coord_mm_cyl, y_coord_mm_cyl, z_coord_mm_cyl, radius_range_half, full_angle_range] = GetGridForCylinder(image_roi, radius_guess_mm, centre_points_mm, direction_vector);
    interpolated_image_cylinder = GetInterpolatedImage(x_coord_mm_cyl, y_coord_mm_cyl, z_coord_mm_cyl, image_roi, segmented_image, segment_label, centre_points_mm);


    if ~isempty(figure_airways_3d)
        ShowInterpolatedCoordinatesOn3dFigure(figure_airways_3d, x_coord_mm_cyl, y_coord_mm_cyl, z_coord_mm_cyl, []);
    end
    
    
    [new_centrepoints, mean_radius, std_radius, mean_wallthickness, std_wallthickness] = FindWalls(interpolated_image_cylinder, image_roi, radius_range_half, full_angle_range, centre_points_mm, direction_vector, segment_label, radius_guess_mm, plot_debug_graphs, context);

    new_centreline_points = new_centrepoints;    
end


function ShowInterpolatedCoordinatesOn3dFigure(figure_airways_3d, xc, yc, zc, centre_point_voxels)
    figure(figure_airways_3d);

    if ~isempty(centre_point_voxels)
        plot3(centre_point_voxels.CoordX, centre_point_voxels.CoordY, centre_point_voxels.CoordZ, 'rx', 'MarkerSize', 10);
    end
    plot3(xc(:), yc(:), zc(:), 'r.');
end


function [x_coord_mm, y_coord_mm, z_coord_mm] = PolarToMm(r, theta, centre_point_mm, direction_vector)
    % Get vectors perpendicular to the bronchus
    [x_prime_norm, y_prime_norm] = GetPerpendicularDirections(direction_vector);

    xp_coord_mm = r.*cos(theta);
    yp_coord_mm = r.*sin(theta);
    
    x_coord_mm = centre_point_mm.CoordX + x_prime_norm(1)*xp_coord_mm + y_prime_norm(1)*yp_coord_mm;
    y_coord_mm = centre_point_mm.CoordY + x_prime_norm(2)*xp_coord_mm + y_prime_norm(2)*yp_coord_mm;
    z_coord_mm = centre_point_mm.CoordZ + x_prime_norm(3)*xp_coord_mm + y_prime_norm(3)*yp_coord_mm;
end

function [x_coord_mm, y_coord_mm, z_coord_mm] = CylindricalToMm(r, theta, centre_points_mm, direction_vector)
    % Get vectors perpendicular to the bronchus
    [x_prime_norm, y_prime_norm] = GetPerpendicularDirections(direction_vector);

    xp_coord_mm = r.*cos(theta);
    yp_coord_mm = r.*sin(theta);
    
    x_coord_mm_plane = x_prime_norm(1)*xp_coord_mm + y_prime_norm(1)*yp_coord_mm;
    y_coord_mm_plane = x_prime_norm(2)*xp_coord_mm + y_prime_norm(2)*yp_coord_mm;
    z_coord_mm_plane = x_prime_norm(3)*xp_coord_mm + y_prime_norm(3)*yp_coord_mm;
    
    size_big_coord_matrix = size(x_coord_mm_plane);
    x_coord_mm = zeros(size_big_coord_matrix);
    y_coord_mm = zeros(size_big_coord_matrix);
    z_coord_mm = zeros(size_big_coord_matrix);
    
    for point_index = 1 : numel(centre_points_mm)
        centre_point_mm = centre_points_mm(point_index);
        x_coord_mm(:, :, point_index) = x_coord_mm_plane(:, :, point_index) + centre_point_mm.CoordX;
        y_coord_mm(:, :, point_index) = y_coord_mm_plane(:, :, point_index) + centre_point_mm.CoordY;
        z_coord_mm(:, :, point_index) = z_coord_mm_plane(:, :, point_index) + centre_point_mm.CoordZ;        
    end
end

function [x_coord_mm, y_coord_mm, z_coord_mm] = CuboidToMm(xp_coord_mm, yp_coord_mm, centre_points_mm, direction_vector)
    % Get vectors perpendicular to the bronchus
    [x_prime_norm, y_prime_norm] = GetPerpendicularDirections(direction_vector);

    x_coord_mm_plane = x_prime_norm(1)*xp_coord_mm + y_prime_norm(1)*yp_coord_mm;
    y_coord_mm_plane = x_prime_norm(2)*xp_coord_mm + y_prime_norm(2)*yp_coord_mm;
    z_coord_mm_plane = x_prime_norm(3)*xp_coord_mm + y_prime_norm(3)*yp_coord_mm;
    
    size_big_coord_matrix = [size(x_coord_mm_plane), numel(centre_points_mm)];
    x_coord_mm = zeros(size_big_coord_matrix);
    y_coord_mm = zeros(size_big_coord_matrix);
    z_coord_mm = zeros(size_big_coord_matrix);
    
    for point_index = 1 : numel(centre_points_mm)
        centre_point_mm = centre_points_mm(point_index);
        x_coord_mm(:, :, point_index) = x_coord_mm_plane + centre_point_mm.CoordX;
        y_coord_mm(:, :, point_index) = y_coord_mm_plane + centre_point_mm.CoordY;
        z_coord_mm(:, :, point_index) = z_coord_mm_plane + centre_point_mm.CoordZ;        
    end
end

function [x_coord_mm, y_coord_mm, z_coord_mm, radius_range_half, full_angle_range] = GetGridForCircle(image_roi, radius_guess_mm, centre_point_mm, direction_vector)
    % Compute a grid in polar coordinates, with r starting at zer0, and theta going from 0 to 2pi
    
    number_of_angles = GetNumberOfAngles(image_roi, radius_guess_mm);
    full_angle_range = linspace(0, 2*pi, number_of_angles);
    
    radius_range_upper = GetPositiveRadiusRange(image_roi, radius_guess_mm);
    
    % Construct the radius range, ensuring there is a point at exactly
    % zero
    radius_range_half = [0, radius_range_upper];    
    
    % Convert to coordinates in mm
    [x_coord_mm, y_coord_mm, z_coord_mm] = GetImageCoordinatesForRadialGrid(radius_range_half, full_angle_range, centre_point_mm, direction_vector);
end

function [x_coord_mm, y_coord_mm, z_coord_mm, radius_range_half, full_angle_range] = GetGridForCylinder(image_roi, radius_guess_mm, centre_points_mm, direction_vector)
    % Compute a grid in cylindrical coordinates, with r starting at zero, and theta going from 0 to 2pi
    
    number_of_angles = GetNumberOfAngles(image_roi, radius_guess_mm);
    full_angle_range = linspace(0, 2*pi, number_of_angles);
    
    radius_range_upper = GetPositiveRadiusRange(image_roi, radius_guess_mm);
    
    % Construct the radius range, ensuring there is a point at exactly
    % zero
    radius_range_half = [0, radius_range_upper];    
    
    % Convert to coordinates in mm
    [x_coord_mm, y_coord_mm, z_coord_mm] = GetImageCoordinatesForCylinderGrid(radius_range_half, full_angle_range, centre_points_mm, direction_vector);
end

function [x_coord_mm, y_coord_mm, z_coord_mm, radius_range_full] = GetGridForCuboid(image_roi, radius_guess_mm, centre_points_mm, direction_vector)
    
    radius_range_upper = GetPositiveRadiusRange(image_roi, radius_guess_mm);
    
    % Construct the radius range, ensuring there is a point at exactly
    % zero
    radius_range_full = [-radius_range_upper(end:-1:1), 0, radius_range_upper];
    
    % Convert to coordinates in mm
    [x_coord_mm, y_coord_mm, z_coord_mm] = GetImageCoordinatesForCuboidGrid(radius_range_full, centre_points_mm, direction_vector);
end

function [x_coord_mm, y_coord_mm, z_coord_mm, radius_range_full, half_angle_range] = GetGridForSemicircle(image_roi, radius_guess_mm, centre_point_mm, direction_vector)
    % Compute a grid in polar coordinates, with r positive and negative, and
    % theta from 0 to pi

    number_of_angles = GetNumberOfAngles(image_roi, radius_guess_mm);
    half_angle_range = linspace(0, pi, round(number_of_angles/2));
    
    radius_range_upper = GetPositiveRadiusRange(image_roi, radius_guess_mm);
    
    % Construct the radius range, ensuring there is a point at exactly
    % zero
    radius_range_full = [-radius_range_upper(end:-1:1), 0, radius_range_upper];
    
    % Convert to coordinates in mm    
    [x_coord_mm, y_coord_mm, z_coord_mm] = GetImageCoordinatesForRadialGrid(radius_range_full, half_angle_range, centre_point_mm, direction_vector);
end

function [x_coord_mm, y_coord_mm, z_coord_mm] = GetImageCoordinatesForRadialGrid(radius_range, angle_range, centre_point_mm, direction_vector)
    [r_values, theta_values] = ndgrid(radius_range, angle_range);
    
    [x_coord_mm, y_coord_mm, z_coord_mm] = PolarToMm(r_values, theta_values, centre_point_mm, direction_vector);
end

function [x_coord_mm, y_coord_mm, z_coord_mm] = GetImageCoordinatesForCylinderGrid(radius_range, angle_range, centre_points_mm, direction_vector)
    [r_values, theta_values] = ndgrid(radius_range, angle_range);
    r_values = repmat(r_values, [1, 1, numel(centre_points_mm)]);
    theta_values = repmat(theta_values, [1, 1, numel(centre_points_mm)]);
    
    [x_coord_mm, y_coord_mm, z_coord_mm] = CylindricalToMm(r_values, theta_values, centre_points_mm, direction_vector);
end

function [x_coord_mm, y_coord_mm, z_coord_mm] = GetImageCoordinatesForCuboidGrid(radius_range, centre_points_mm, direction_vector)
    [x1_values, y1_values] = ndgrid(radius_range, radius_range);
    
    [x_coord_mm, y_coord_mm, z_coord_mm] = CuboidToMm(x1_values, y1_values, centre_points_mm, direction_vector);
end

function number_of_angles = GetNumberOfAngles(image_roi, radius_guess_mm)
    voxel_size_mm = image_roi.VoxelSize;
    min_voxel_size_mm = min(voxel_size_mm);
    % Determine number of different angles to use to capture the whole
    % airway cross-section
    delta_theta = (1/2)*asin(min_voxel_size_mm/radius_guess_mm);
    number_of_angles = 2*pi/delta_theta;
    number_of_angles = 8*ceil(number_of_angles/8);    
end


function radius_range_upper = GetPositiveRadiusRange(image_roi, radius_guess_mm)
    voxel_size_mm = image_roi.VoxelSize;
    min_voxel_size_mm = min(voxel_size_mm);
    
    % Determine number of radii steps
    % We take a radius step size of half the minimum voxel size and
    % extend it to a multiple of the estimated radius
    radius_multiple = 3;
    step_size_mm = min_voxel_size_mm/2;
    airway_max_mm = step_size_mm*(ceil(radius_multiple*radius_guess_mm/step_size_mm));
    radius_range_upper = step_size_mm : step_size_mm : airway_max_mm;
end

function [x_prime_norm, y_prime_norm] = GetPerpendicularDirections(direction_vector)
    
    % Find x' and y' vectors in the plane perpendicular to the direction
    direction_vector_norm = [direction_vector.CoordX, direction_vector.CoordY, direction_vector.CoordZ];
    plane_null_space = null(direction_vector_norm/norm(direction_vector_norm));
    x_prime_norm = plane_null_space(:, 1);
    y_prime_norm = plane_null_space(:, 2);
end

function [interpolated_image, centre_global_indices] = GetInterpolatedImage(x_coord_mm, y_coord_mm, z_coord_mm, lung_roi, segmented_image, segment_label, centre_points_mm)
    ptk_coordinates = [x_coord_mm(:), y_coord_mm(:), z_coord_mm(:)];
    coordinates_mm = PTKImageCoordinateUtilities.PTKCoordinatesToCoordinatesMm(ptk_coordinates);
    global_coordinates = lung_roi.CoordinatesMmToGlobalCoordinatesUnrounded(coordinates_mm);
    local_coordinates = lung_roi.GlobalToLocalCoordinates(global_coordinates);
    
    global_indices = lung_roi.GlobalCoordinatesToGlobalIndices(round(global_coordinates));
    if ~isempty(segmented_image)
        segmented_image.SetIndexedVoxelsToThis(global_indices, segment_label);
    end
    
    values = interpn(double(lung_roi.RawImage), local_coordinates(:, 1), local_coordinates(:, 2), local_coordinates(:, 3), 'cubic');
    interpolated_image = zeros(size(x_coord_mm), 'double');
    interpolated_image(:) = values(:);
    
    centre_ponts_x = [centre_points_mm.CoordX]';
    centre_ponts_y = [centre_points_mm.CoordY]';
    centre_ponts_z = [centre_points_mm.CoordZ]';
    centre_ponts = [centre_ponts_x, centre_ponts_y, centre_ponts_z];
    centre_coordinates_mm = PTKImageCoordinateUtilities.PTKCoordinatesToCoordinatesMm(centre_ponts);
    centre_global_coordinates = lung_roi.CoordinatesMmToGlobalCoordinatesUnrounded(centre_coordinates_mm);
    centre_global_indices = lung_roi.GlobalCoordinatesToGlobalIndices(round(centre_global_coordinates));    
end

function [new_centrepoints, mean_radius, std_radius, mean_wallthickness, std_wallthickness] = FindWalls(interpolated_volume, lung_roi, radius_range_half, full_angle_range, centre_points_mm, direction_vector, segment_label, radius_guess_mm, plot_debug_graphs, context)

    number_of_radii = size(interpolated_volume, 1);
    number_of_angles = size(interpolated_volume, 2);
    number_of_centreline_points = size(interpolated_volume, 3);
    
    radius_values_repeated = repmat(radius_range_half', [1, number_of_angles, number_of_centreline_points]);
    
    % Find half maximum intensity value across the whole bronchus
    half_maximum = ComputeHalfMaximum(interpolated_volume, lung_roi);
    
    [inner_radius_values, valid_values_inner, outer_radius_values, valid_values_outer, wall_thickness] = FindWallRadius(interpolated_volume, half_maximum, radius_values_repeated, radius_guess_mm, lung_roi, segment_label, plot_debug_graphs, context);

    if plot_debug_graphs
        % 3D figure showing points on the centreline and inner walls
        points_fig_handle = figure;
        hold on;
        points_axes_handle = gca;
        set(points_fig_handle, 'Name', [char(context), ': Centreline and inner wall points']);
        daspect([1 1 1]);
    else
        points_axes_handle = [];
    end
    
    % Get the image coordinates of the inner wall points
    theta_repeated = repmat(full_angle_range, [1, 1, number_of_centreline_points]);
    dtheta = full_angle_range(2) - full_angle_range(1);
    
    dz = norm(lung_roi.VoxelSize);
    
    [inner_x_coord_mm, inner_y_coord_mm, inner_z_coord_mm] = CylindricalToMm(inner_radius_values, theta_repeated, centre_points_mm, direction_vector);
    inner_connected = WallConnectivity(inner_x_coord_mm, inner_y_coord_mm, inner_z_coord_mm, radius_guess_mm, dtheta, dz);
    valid_values_inner = valid_values_inner & inner_connected;
    
    [outer_x_coord_mm, outer_y_coord_mm, outer_z_coord_mm] = CylindricalToMm(outer_radius_values, theta_repeated, centre_points_mm, direction_vector);
    outer_connected = WallConnectivity(outer_x_coord_mm, outer_y_coord_mm, outer_z_coord_mm, radius_guess_mm, dtheta, dz);
    valid_values_outer = valid_values_outer & outer_connected;
    
    % Compute the mean radius for each centreline point
    [radius_mm_list, mean_radius, std_radius] = ComputeMeanRadiusForEachPoint(inner_radius_values, valid_values_inner);
    
    % Compute the mean wall thickness for each centreline point
    valid_both = valid_values_inner & valid_values_outer;
    [wall_thickness_mm_list, mean_wallthickness, std_wallthickness] = ComputeMeanWallThicknessForEachPoint(wall_thickness, valid_both);

    if ~isempty(points_axes_handle)
        plot3(points_axes_handle, inner_x_coord_mm(valid_values_inner(:)), inner_y_coord_mm(valid_values_inner(:)), inner_z_coord_mm(valid_values_inner(:)), 'ro');
        plot3(points_axes_handle, inner_x_coord_mm(~valid_values_inner(:)), inner_y_coord_mm(~valid_values_inner(:)), inner_z_coord_mm(~valid_values_inner(:)), 'bo');
        
        plot3(points_axes_handle, outer_x_coord_mm(valid_values_outer(:)), outer_y_coord_mm(valid_values_outer(:)), outer_z_coord_mm(valid_values_outer(:)), 'm+');
        
    end
    
    % Compute a set of new centreline points
    new_centrepoints = ComputeNewCentrelinePoints(inner_radius_values, valid_values_inner, full_angle_range, centre_points_mm, direction_vector, points_axes_handle);
    
    for point_index = 1 : numel(new_centrepoints)
        new_centrepoints(point_index).Parameters.FWHMRadiusMm = radius_mm_list(point_index);
        new_centrepoints(point_index).Parameters.FWHMWallThicknessMm = wall_thickness_mm_list(point_index);
    end
end

function connected = WallConnectivity(x_coord_mm, y_coord_mm, z_coord_mm, radius_guess_mm, dtheta, dz)
    % Compute the distances between wall points and their neighbours (nearest
    % angle coordinate)
    x_coord_mm_plus = circshift(x_coord_mm, [0, 1, 0]);
    x_coord_mm_minus = circshift(x_coord_mm, [0, -1, 0]);
    y_coord_mm_plus = circshift(y_coord_mm, [0, 1, 0]);
    y_coord_mm_minus = circshift(y_coord_mm, [0, -1, 0]);
    z_coord_mm_plus = circshift(z_coord_mm, [0, 1, 0]);
    z_coord_mm_minus = circshift(z_coord_mm, [0, -1, 0]);
    
    distance_plus_mm = PointwiseNorm(x_coord_mm - x_coord_mm_plus, y_coord_mm - y_coord_mm_plus, z_coord_mm - z_coord_mm_plus);
    distance_minus_mm = PointwiseNorm(x_coord_mm - x_coord_mm_minus, y_coord_mm - y_coord_mm_minus, z_coord_mm - z_coord_mm_minus);
    
    max_distance_mm = 2*radius_guess_mm*sin(dtheta);
    
    within_limits = distance_plus_mm < max_distance_mm & distance_minus_mm < max_distance_mm;
    connected = within_limits;
    
    
    % Compute the distances between wall points and their neighbours (adjacent points)
    x_coord_mm_plus = circshift(x_coord_mm, [0, 0, 1]);
    y_coord_mm_plus = circshift(y_coord_mm, [0, 0, 1]);
    z_coord_mm_plus = circshift(z_coord_mm, [0, 0, 1]);
    x_coord_mm_plus(:, :, 1) = x_coord_mm(:, :, 1);
    y_coord_mm_plus(:, :, 1) = y_coord_mm(:, :, 1);
    z_coord_mm_plus(:, :, 1) = z_coord_mm(:, :, 1);

    x_coord_mm_minus = circshift(x_coord_mm, [0, 0, -1]);
    y_coord_mm_minus = circshift(y_coord_mm, [0, 0, -1]);
    z_coord_mm_minus = circshift(z_coord_mm, [0, 0, -1]);
    x_coord_mm_minus(:, :, end) = x_coord_mm(:, :, end);
    y_coord_mm_minus(:, :, end) = y_coord_mm(:, :, end);
    z_coord_mm_minus(:, :, end) = z_coord_mm(:, :, end);
    
    distance_plus_mm = PointwiseNorm(x_coord_mm - x_coord_mm_plus, y_coord_mm - y_coord_mm_plus, z_coord_mm - z_coord_mm_plus);
    distance_minus_mm = PointwiseNorm(x_coord_mm - x_coord_mm_minus, y_coord_mm - y_coord_mm_minus, z_coord_mm - z_coord_mm_minus);
    
    max_distance_mm = 2*dz;
    
    within_limits = distance_plus_mm < max_distance_mm & distance_minus_mm < max_distance_mm;
    connected = connected & within_limits;
    
end

function pointwise_norm = PointwiseNorm(xc, yc, zc)
    pointwise_norm = sqrt(xc.^2 + yc.^2 + zc.^2);
end


function [inner_radius_values, valid_values_inner, outer_radius_values, valid_values_outer, wall_thickness] = FindWallRadius(interpolated_volume, half_maximum, radius_values_repeated, radius_guess_mm, lung_roi, segment_label, plot_debug_graphs, context)
    
    % Choose a region of interest for the inner wall and set values outside to
    % zero, so that they don't contribute to the half maximum value or to the
    % inner wall locations
    radius_limit_mm = 2*radius_guess_mm;
    points_in_inner_wall_region = radius_values_repeated < radius_limit_mm;
    interpolated_volume_inner = interpolated_volume;
    interpolated_volume_inner(~points_in_inner_wall_region) = 0;    
    
    number_of_angles = size(interpolated_volume_inner, 2);
    number_of_centreline_points = size(interpolated_volume_inner, 3);
    number_of_radii = size(interpolated_volume_inner, 1);
    radii_indices = (1 : number_of_radii)';
    radii_indices_repeated = repmat(radii_indices, [1, number_of_angles, number_of_centreline_points]);

    
    % Mask of points above the half maximum value
    values_above_halfmax = interpolated_volume_inner >= half_maximum;
    
    % Mask of radial lines where some point went above the half maximum value
    valid_values_inner = any(values_above_halfmax, 1);
    
    % Indices of first point in each radial line which went above half maximum
    [~, indices_halfpoint] = max(values_above_halfmax, [], 1);
    
    % Indices of the point before that one
    indices_before_halfpoint = max(1, indices_halfpoint - 1);
    
    % Create a mask of points where 1 is the first point in each radial line
    % going above half maximum value
    indices_halfpoint_repeated = repmat(indices_halfpoint, [number_of_radii, 1, 1]);
    indices_before_halfpoint_repeated = repmat(indices_before_halfpoint, [number_of_radii, 1, 1]);
    mask_indices_halfpoint = indices_halfpoint_repeated == radii_indices_repeated;
    mask_indices_before_halfpoint = indices_before_halfpoint_repeated == radii_indices_repeated;
    
    % Compute the subvoxel coordinate where the half maximum value would be
    % crossed (assuming a linear interpolation)
    intensity_difference = sum(interpolated_volume_inner.*(mask_indices_halfpoint - mask_indices_before_halfpoint), 1);
    difference_to_halfpoint = sum((half_maximum - interpolated_volume_inner).*mask_indices_before_halfpoint, 1);
    subvoxel_halfmaximum_index_offset = difference_to_halfpoint./intensity_difference;
    
    % Compute the inner radius of the bronchial wall
    radius_step = radius_values_repeated(2, 1, 1) - radius_values_repeated(1, 1, 1);
    inner_radius_values = sum(radius_values_repeated.*mask_indices_before_halfpoint, 1) + subvoxel_halfmaximum_index_offset*radius_step;
    
    
    
    % Find outer wall
    interpolated_volume_outer = interpolated_volume;

    % Mask of points beyond the inner wall
    points_beyond_inner_wall = radii_indices_repeated > indices_halfpoint_repeated;

    % Mask of points below the half maximum value
    values_below_halfmax_outer = interpolated_volume_outer <= half_maximum;    
    values_below_halfmax_outer = values_below_halfmax_outer & points_beyond_inner_wall;
    
    % Mask of radial lines where some point went below the half maximum value
    valid_values_outer = any(values_below_halfmax_outer, 1);
    
    % Indices of first point in each radial line which went below half maximum
    [~, indices_halfpoint_outer] = max(values_below_halfmax_outer, [], 1);
    
    % Indices of the point before that one
    indices_before_halfpoint_outer = max(1, indices_halfpoint_outer - 1);
    
    % Create a mask of points where 1 is the first point in each radial line
    % going below half maximum value
    indices_halfpoint_outer_repeated = repmat(indices_halfpoint_outer, [number_of_radii, 1, 1]);
    indices_before_halfpoint_outer_repeated = repmat(indices_before_halfpoint_outer, [number_of_radii, 1, 1]);
    mask_indices_halfpoint_outer = indices_halfpoint_outer_repeated == radii_indices_repeated;
    mask_indices_before_halfpoint_outer = indices_before_halfpoint_outer_repeated == radii_indices_repeated;

    % Compute the subvoxel coordinate where the half maximum value would be
    % crossed (assuming a linear interpolation)
    intensity_difference_outer = sum(interpolated_volume_outer.*(mask_indices_before_halfpoint_outer - mask_indices_halfpoint_outer), 1);
    difference_to_halfpoint_outer = sum((interpolated_volume_outer - half_maximum).*mask_indices_before_halfpoint_outer, 1);
    subvoxel_halfmaximum_outer_index_offset = difference_to_halfpoint_outer./intensity_difference_outer;
    
    % Compute the outer radius of the bronchial wall
    radius_step = radius_values_repeated(2, 1, 1) - radius_values_repeated(1, 1, 1);
    outer_radius_values = sum(radius_values_repeated.*mask_indices_before_halfpoint_outer, 1) + subvoxel_halfmaximum_outer_index_offset*radius_step;
    
    
    % Compute wall thickness
    wall_thickness = outer_radius_values - inner_radius_values;
    
    
    if plot_debug_graphs
        % Image showing the interpolated CT values
        im_ct = PTKDicomImage(interpolated_volume, lung_roi.RescaleSlope, lung_roi.RescaleIntercept, [1 1 1], 'CT', '', []);
        im_ct.ImageType = PTKImageType.Grayscale;
        v_ct = PTKViewer(im_ct);
        v_ct.Title = [char(context), ': CT cartesian'];
        v_ct.ViewerPanelHandle.Window = 1600;
        v_ct.ViewerPanelHandle.Level = -600;
        v_ct.ViewerPanelHandle.Orientation = PTKImageOrientation.Axial;
        
        im_overlay = im_ct.BlankCopy;
        im_overlay_raw = zeros(im_ct.ImageSize, 'uint8');
        v_ct.ViewerPanelHandle.OverlayImage = im_overlay;
        im_overlay.ImageType = PTKImageType.Colormap;
        
        im_overlay_raw(mask_indices_halfpoint) = 3;
        im_overlay_raw(mask_indices_before_halfpoint) = 2;
        im_overlay_raw(mask_indices_halfpoint_outer) = 5;
        im_overlay_raw(mask_indices_before_halfpoint_outer) = 5;
        im_overlay.ChangeRawImage(im_overlay_raw);
    end

end

function half_maximum = ComputeHalfMaximum(interpolated_volume, lung_roi)
    % Finds the half maximum value of the intensity across the whole bronchus
    
    % We will clip the maximum considered values to prevent high-density non-airway tissue
    % from affecting the maxima calculations
    max_hu_cutoff = 0;
    max_intensity_cutoff = lung_roi.HounsfieldToGreyscale(max_hu_cutoff);
    
    % Find the maxima for each radial line (r is the first dimension)
    [max_vals, max_indices] = max(interpolated_volume, [], 1);
    
    % Find all radial lines where the density is above the cutoff
    maxima_above_cutoff = max_vals(:) > max_intensity_cutoff;
    
    % We find the maximum value for the whole bronchus, excluding all the radial
    % lines where any points went above the cutoff
    if isempty(maxima_above_cutoff)
        disp('Warning: all radial lines have a maximum exceeding the threshold');
        maximum_intensity = max_intensity_cutoff;
    else
        maximum_intensity = max(max_vals(maxima_above_cutoff));
        if numel(maxima_above_cutoff) < numel(max_vals)/2
            disp('Warning: more than half of the radial lines have a maximum exceeding the threshold');
        end
    end
    
    % Compute the half maximum value
    minimum_intensty = min(interpolated_volume(:));
    half_maximum = minimum_intensty + (maximum_intensity-minimum_intensty)/2;
end

function [radius_mm_list, mean_radius_along_whole_bronchus, std_radius_along_whole_bronchus] = ComputeMeanRadiusForEachPoint(radius_value, valid_radial_lines)
    number_of_contributing_radii = sum(valid_radial_lines, 2);
    
    % Find the mean radius
    radius_value(~valid_radial_lines) = 0;
    
    mean_radii_across_angles = sum(radius_value, 2)./number_of_contributing_radii;
    mean_radii_across_angles(number_of_contributing_radii == 0) = -1;
    radius_mm_list = squeeze(mean_radii_across_angles);
    
    all_radius_values = radius_value(valid_radial_lines(:));
    mean_radius_along_whole_bronchus = mean(all_radius_values);
    std_radius_along_whole_bronchus = std(all_radius_values);
end
    
function [wall_thickness_mm_list, mean_wall_thickness_along_whole_bronchus, std_wall_thickness_along_whole_bronchus] = ComputeMeanWallThicknessForEachPoint(wall_thickness_values, valid_radial_lines)
    number_of_contributing_radii = sum(valid_radial_lines, 2);
    
    % Find the mean radius
    wall_thickness_values(~valid_radial_lines) = 0;
    
    mean_wall_thickness_across_angles = sum(wall_thickness_values, 2)./number_of_contributing_radii;
    mean_wall_thickness_across_angles(number_of_contributing_radii == 0) = -1;
    wall_thickness_mm_list = squeeze(mean_wall_thickness_across_angles);
    
    all_wall_thickness_values = wall_thickness_values(valid_radial_lines(:));
    mean_wall_thickness_along_whole_bronchus = mean(all_wall_thickness_values);
    std_wall_thickness_along_whole_bronchus = std(all_wall_thickness_values);
end

function new_centrepoints = ComputeNewCentrelinePoints(radius_value, valid_radial_lines, full_angle_range, centre_points_mm, direction_vector, points_axes_handle)
    % Calculate a new centreline by finding the point in the centre of the
    % bronchus for each radial line, and computing an average point by finding
    % the mean of all the coordinates
    
    number_of_angles = size(radius_value, 2);
    number_of_centreline_points = size(radius_value, 3);
    
    theta_repeated = repmat(full_angle_range, [1, 1, number_of_centreline_points]);
    new_centrepoint_radius_offset = (radius_value(:,1:number_of_angles/2, :) - radius_value(:,number_of_angles/2+1:end, :))/2;
    
    % Get the image coordinates of the new centrepoints
    [c_x_coord_mm, c_y_coord_mm, c_z_coord_mm] = CylindricalToMm(new_centrepoint_radius_offset, theta_repeated(:, 1:number_of_angles/2, :), centre_points_mm, direction_vector);
    
    valid_radii_half = valid_radial_lines(:,1:number_of_angles/2, :) & valid_radial_lines(:,number_of_angles/2+1:end, :);
    
    number_of_contributing_radii_half = sum(valid_radii_half, 2);
    
    invalid_points = number_of_contributing_radii_half < 1;
    
    c_x_coord_mm(~valid_radii_half) = 0;
    c_y_coord_mm(~valid_radii_half) = 0;
    c_z_coord_mm(~valid_radii_half) = 0;
    
    mean_c_x = sum(c_x_coord_mm, 2)./number_of_contributing_radii_half;
    mean_c_y = sum(c_y_coord_mm, 2)./number_of_contributing_radii_half;
    mean_c_z = sum(c_z_coord_mm, 2)./number_of_contributing_radii_half;
    
    if ~isempty(points_axes_handle)
        plot3(points_axes_handle, mean_c_x(:), mean_c_y(:), mean_c_z(:), 'bx');
    end
    
    new_centrepoints = PTKCentrelinePoint.empty;
    for centrepoint_index = 1 : number_of_centreline_points
        if invalid_points(centrepoint_index)
            new_centrepoints(centrepoint_index) = centre_points_mm(centrepoint_index);
        else
            new_centrepoints(centrepoint_index) = PTKCentrelinePoint(mean_c_x(:,:,centrepoint_index), mean_c_y(:,:,centrepoint_index), mean_c_z(:,:,centrepoint_index));
        end
    end
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

