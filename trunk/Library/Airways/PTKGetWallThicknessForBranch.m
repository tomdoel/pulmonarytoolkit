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
            
        
        plot_debug_graphs = true;
        central_centreline = current_centreline(first_radius_index : last_radius_index);
        
        [new_centreline, radius_mean, radius_std, wall_thickness_mean, wall_thickness_std] = RecomputeAllCentreline(central_centreline, direction_vector, image_roi, radius_guess, figure_airways_3d, segment_label, segmented_image, plot_debug_graphs, context);
        
%         centreline_points = [new_centreline.Parameters];
        
%         radius = [centreline_points.FWHMRadiusMm];
%         valid_values = radius ~= -1;
%         radius_mean = mean(radius(valid_values));
%         radius_std = std(radius(valid_values));
        
%         wall_thickness = [centreline_points.FWHMWallThicknessMm];
%         valid_values = wall_thickness ~= -1;
%         wall_thickness_mean = mean(wall_thickness(valid_values));
%         wall_thickness_std = std(wall_thickness(valid_values));
        
        
        results = [];
        results.FWHMRadiusMean = radius_mean;
        results.FWHMRadiusStd = radius_std;
        results.FWHMWallThicknessMean = wall_thickness_mean;
        results.FWHMWallThicknessStd = wall_thickness_std;
        results.Centreline = new_centreline;
        results.GridOverlayImage = segmented_image;
%         new_centreline = RecomputeCentreline(central_centreline, direction_vector, image_roi, radius_guess, figure_airways_3d, segment_label);
    end
end

% function current_centreline = UpdateCentreline(new_centreline, old_centreline)
%     current_centreline = PTKCentrelinePoint.empty;
%     for point_index = 1 : numel(new_centreline)
%         if isempty(new_centreline(point_index))
%             current_centreline(point_index) = old_centreline(point_index);
%         else
%             current_centreline(point_index) = new_centreline(point_index);
%         end
%     end
% end

function centreline_difference = CentrelineDifference(centreline_1, centreline_2)
    num_points = numel(centreline_1);
    centreline_difference = zeros(size(centreline_1));
    for point_index = 1 : num_points
        centreline_difference(point_index) = PTKPoint.Magnitude(PTKPoint.Difference(centreline_1(point_index), centreline_2(point_index)));
    end
end

% function new_centreline = RecomputeCentreline(centreline, direction_vector, image_roi, radius_guess, figure_airways_3d, segment_label)
%     new_centreline = PTKCentrelinePoint.empty;
%     midpoint = max(1, round(numel(centreline)/2));
%     for point_index = 1 : numel(centreline)
%         new_point = RecomputeCentrelinePoint(centreline(point_index), direction_vector, image_roi, radius_guess, figure_airways_3d, midpoint == point_index, segment_label);
%         new_centreline(point_index) = new_point;
%     end
% end

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

% function new_centreline_point = RecomputeCentrelinePoint(centre_point_mm, direction_vector, image_roi, radius_guess_mm, figure_airways_3d, draw_this_point, segmented_image, segment_label)
% %     [x_coord_mm_cub, y_coord_mm_cub, z_coord_mm_cub, radius_range_half, full_angle_range] = GetGridForCuboid(image_roi, radius_guess_mm, centre_points_mm, direction_vector);
%     
%     [x_coord_mm_cyl, y_coord_mm_cyl, z_coord_mm_cyl, radius_range_half, full_angle_range] = GetGridForCylinder(image_roi, radius_guess_mm, centre_points_mm, direction_vector);
%     interpolated_image_cylinder = GetInterpolatedImage(x_coord_mm_semi, y_coord_mm_semi, z_coord_mm_semi, image_roi, segmented_image, segment_label);
%     
%     
%     [x_coord_mm_semi, y_coord_mm_semi, z_coord_mm_semi, radius_range_full_semi, half_angle_range_semi] = GetGridForSemicircle(image_roi, radius_guess_mm, centre_point_mm, direction_vector);    
%     interpolated_image_semi = GetInterpolatedImage(x_coord_mm_semi, y_coord_mm_semi, z_coord_mm_semi, image_roi, segmented_image, segment_label);
% 
%     if ~isempty(figure_airways_3d)
%         ShowInterpolatedCoordinatesOn3dFigure(figure_airways_3d, x_coord_mm_semi, y_coord_mm_semi, z_coord_mm_semi, centre_point_mm);
%     end
%     
%     [x_coord_mm_circle, y_coord_mm_circle, z_coord_mm_circle, radius_range_half_circle, full_angle_range_circle] = GetGridForCircle(image_roi, radius_guess_mm, centre_point_mm, direction_vector);
%     interpolated_image_circle = GetInterpolatedImage(x_coord_mm_circle, y_coord_mm_circle, z_coord_mm_circle, image_roi, segmented_image, segment_label);
%     
%     new_centreline_point = PTKCentrelinePoint(0,0,0);
%     
%     
%     
%     % Phase congruency
%     pc_image_2d = phasecong3(interpolated_image_semi, 10, 8, 4, 1.3, 0.85, 2, 0.5, 10, -1);
%     pc_image_2d_new = phasecong3_1D(interpolated_image_semi, 10, 8, 4, 1.3, 0.85, 2, 0.5, 10, -1);
% %     pc_image = phasecong3(interp_image);
% %     pc_image2 = PTKPhaseCongruency2D(interp_image);
%     pc_image1 = PTKPhaseCongruency1D(interpolated_image_semi);
%     
%     
%     if draw_this_point
%         im_ct = PTKDicomImage(interpolated_image_semi, image_roi.RescaleSlope, image_roi.RescaleIntercept, [1 1 1], 'CT', '', []);
%         im_ct.ImageType = PTKImageType.Grayscale;
%         v_ct = PTKViewer(im_ct);
%         v_ct.Title = [char(segment_label), ': CT resampled'];
%         v_ct.ViewerPanelHandle.Window = 1600;
%         v_ct.ViewerPanelHandle.Level = -600;
%         
%         im_ct = PTKDicomImage(pc_image1, image_roi.RescaleSlope, image_roi.RescaleIntercept, [1 1 1], 'CT', '', []);
%         im_ct.ImageType = PTKImageType.Grayscale;
%         v_ct = PTKViewer(im_ct);
%         v_ct.Title = [char(segment_label), ': PC'];
%     end
%     
% end


function [new_centreline_points, mean_radius, std_radius, mean_wallthickness, std_wallthickness] = RecomputeAllCentreline(centre_points_mm, direction_vector, image_roi, radius_guess_mm, figure_airways_3d, segment_label, segmented_image, plot_debug_graphs, context)
%     [x_coord_mm_cub, y_coord_mm_cub, z_coord_mm_cub, radius_range_half] = GetGridForCuboid(image_roi, radius_guess_mm, centre_points_mm, direction_vector);
    [x_coord_mm_cyl, y_coord_mm_cyl, z_coord_mm_cyl, radius_range_half, full_angle_range] = GetGridForCylinder(image_roi, radius_guess_mm, centre_points_mm, direction_vector);
    interpolated_image_cylinder = GetInterpolatedImage(x_coord_mm_cyl, y_coord_mm_cyl, z_coord_mm_cyl, image_roi, segmented_image, segment_label, centre_points_mm);
%     [interpolated_image_cylinder, ~] = GetInterpolatedImage(x_coord_mm_cub, y_coord_mm_cub, z_coord_mm_cub, image_roi, segmented_image, segment_label, centre_points_mm);


    if ~isempty(figure_airways_3d)
%         ShowInterpolatedCoordinatesOn3dFigure(figure_airways_3d, x_coord_mm_cub, y_coord_mm_cub, z_coord_mm_cub, []);
        ShowInterpolatedCoordinatesOn3dFigure(figure_airways_3d, x_coord_mm_cyl, y_coord_mm_cyl, z_coord_mm_cyl, []);
    end
    
    
    [new_centrepoints, mean_radius, std_radius, mean_wallthickness, std_wallthickness] = FindWalls(interpolated_image_cylinder, image_roi, radius_range_half, full_angle_range, centre_points_mm, direction_vector, segment_label, radius_guess_mm, plot_debug_graphs, context);

    new_centreline_points = new_centrepoints;
%     
%     [x_coord_mm_semi, y_coord_mm_semi, z_coord_mm_semi, radius_range_full_semi, half_angle_range_semi] = GetGridForSemicircle(image_roi, radius_guess_mm, centre_point_mm, direction_vector);    
%     interpolated_image_semi = GetInterpolatedImage(x_coord_mm_semi, y_coord_mm_semi, z_coord_mm_semi, image_roi, segment_label);
% 
%     
%     [x_coord_mm_circle, y_coord_mm_circle, z_coord_mm_circle, radius_range_half_circle, full_angle_range_circle] = GetGridForCircle(image_roi, radius_guess_mm, centre_point_mm, direction_vector);
%     interpolated_image_circle = GetInterpolatedImage(x_coord_mm_circle, y_coord_mm_circle, z_coord_mm_circle, image_roi, segment_label);
%     
%     new_centreline_point = PTKCentrelinePoint(0,0,0);
    
    
    
%     % Phase congruency
%     pc_image_2d = phasecong3(interpolated_image_semi, 10, 8, 4, 1.3, 0.85, 2, 0.5, 10, -1);
%     pc_image_2d_new = phasecong3_1D(interpolated_image_semi, 10, 8, 4, 1.3, 0.85, 2, 0.5, 10, -1);
% %     pc_image = phasecong3(interp_image);
% %     pc_image2 = PTKPhaseCongruency2D(interp_image);
%     pc_image1 = PTKPhaseCongruency1D(interpolated_image_semi);
%     
%     
%     if draw_this_point
%         im_ct = PTKDicomImage(interpolated_image_semi, image_roi.RescaleSlope, image_roi.RescaleIntercept, [1 1 1], 'CT', '', []);
%         im_ct.ImageType = PTKImageType.Grayscale;
%         v_ct = PTKViewer(im_ct);
%         v_ct.Title = [char(segment_label), ': CT resampled'];
%         v_ct.ViewerPanelHandle.Window = 1600;
%         v_ct.ViewerPanelHandle.Level = -600;
%         
%         im_ct = PTKDicomImage(pc_image1, image_roi.RescaleSlope, image_roi.RescaleIntercept, [1 1 1], 'CT', '', []);
%         im_ct.ImageType = PTKImageType.Grayscale;
%         v_ct = PTKViewer(im_ct);
%         v_ct.Title = [char(segment_label), ': PC'];
%     end
    
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
%     size_big_coord_matrix = [size(x_coord_mm_plane), numel(centre_points_mm)];
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
%     dz = PTKPoint.Magnitude(PTKPoint.Difference(centre_points_mm(2), centre_points_mm(1)));
    
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
%         plot3(points_axes_handle, outer_x_coord_mm(~valid_values_outer(:)), outer_y_coord_mm(~valid_values_outer(:)), outer_z_coord_mm(~valid_values_outer(:)), 'k+');
        
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
    
    
%     number_of_points = size(x_coord_mm, 3);
%     number_of_angles = size(x_coord_mm, 2);
%     for point_index = 1 : number_of_points
%         for angle_index = 1 : number_of_angles
%             x = x_coord_mm(1, angle_index, point_index);
%             y = y_coord_mm(1, angle_index, point_index);
%             z = z_coord_mm(1, angle_index, point_index);
%             angle_plus_index = angle_index + 1;
%             if angle_plus_index > number_of_angles
%                 angle_plus_index = 1;
%             end
%             angle_minus_index = angle_index - 1;
%             if angle_minus_index < 1
%                 angle_plus_index = number_of_angles;
%             end
%             
%             
%         end
%     end
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


    
%     
%     % Limit the intensity values to a threshold in order to prevent
%     % airway wall measurement being skewed by nearby high intensity
%     % tissue
%     min_hu = -1024;
%     min_intensity = lumg_roi.HounsfieldToGreyscale(min_hu);
%     interpolated_volume = max(double(min_intensity), interpolated_volume);
%     interpolated_volume = min(double(max_intensity_cutoff), interpolated_volume);
%     
%     
%     % Find the maxima for each radial line (r is the first dimension)
%     [max_vals, max_indices] = max(interpolated_volume, [], 1);
%     
%     
%     
%     
%     
%     
%     
% %     midpoint = ceil(size(interpolated_volume, 1)/2);
% %     upper_half = interp_image_full(midpoint:end, :);
% %     lower_half = interp_image_full(midpoint:-1:1, :);
% 
%     
% 
% % function [wall_indices, wall_mask, refined_wall_indices, outer_wall_indices, outer_wall_mask] = FindWall(half_image)
%     
%     % We need to store a copy of the image for the refinement later
%     original_half_image = half_image;
%     
%     % Create another image for computing the outer radius
%     outer_half_image = half_image;
%     
%     
%     radii_indices = (1 : number_of_radii)';
%     radii_indices_repeated = repmat(radii_indices, [1, number_of_angles]);
%     
%     % Find the maxima in each column - each column represents one radial line
%     [max_val, max_indices] = max(half_image, [], 1);
%     
%     % If the maxima is very low in some of the columns, replace it with the mean
%     % of the other maxima. This can happen if the airway wall is located off the
%     % end of the image or due to partial volume effects. Replacing the value
%     % with the mean allows us to still find the half maximum value
%     [max_val, values_replaced] = ReplaceOutliersWithMean(max_val);
%     
%     % Maxima which have been replaced should be located off the image, so that
%     % no pixels are removed from that column in the search for the minima
%     max_indices(values_replaced) = number_of_radii + 1;
%     
%     max_val_repeated = repmat(max_val, [number_of_radii, 1]);
%     max_indices_repeated = repmat(max_indices, [number_of_radii, 1]);
%     
%     % Points beyond the maxima are set to the maxima values
%     indices_outside_range = radii_indices_repeated > max_indices_repeated;
%     half_image(indices_outside_range) = max_val_repeated(indices_outside_range);
%     
%     % Do the same for the outer radius approximation
%     outer_half_image(~indices_outside_range) = max_val_repeated(~indices_outside_range);
%     
%     % Find the minima in each column
%     [min_val, ~] = min(half_image, [], 1);
%     
%     % Find the midway value between maxima and minima for each column
%     halfmax = (max_val + min_val)/2;
%     halfmax_repeated = repmat(halfmax, [number_of_radii, 1]);
%     
%     % Find points above the half maximum value
%     % Some columns may have no value above this
%     values_above_halfmax = half_image >= halfmax_repeated;    
%     halfmax_points_found = any(values_above_halfmax, 1);
%     
%     % For outer radius, find points below the half maximum value
%     values_below_halfmax_outer = outer_half_image <= halfmax_repeated;
%     outer_halfmax_points_found = any(values_below_halfmax_outer, 1);
%     
%     % Find the first values which go above the half maximum value - max
%     % will return the indices of the first point in each column
%     [~, indices_halfpoint] = max(values_above_halfmax, [], 1);
%     indices_halfpoint(~halfmax_points_found) = -1;
%     wall_indices = indices_halfpoint;
%     halfpoint_indices_repeated = repmat(indices_halfpoint, [number_of_radii, 1]);
%     mask_maxima = halfpoint_indices_repeated == radii_indices_repeated;
%     
%     % For outer wall, find the first values which go below the half maximum value - max
%     % will return the indices of the first point in each column
%     [~, indices_halfpoint_outer] = max(values_below_halfmax_outer, [], 1);
%     indices_halfpoint_outer(~outer_halfmax_points_found) = -1;
%     outer_wall_indices = indices_halfpoint_outer;
%     halfpoint_indices_repeated_outer = repmat(indices_halfpoint_outer, [number_of_radii, 1]);
%     mask_maxima_outer = halfpoint_indices_repeated_outer == radii_indices_repeated;
% 
%     % Compute a more refined calculation for airway edge using linear
%     % interpolation
%     gradients = zeros(size(original_half_image));
%     gradients(2:end, :) = original_half_image(2:end, :) - original_half_image(1:end-1, :);
%     difference_from_halfmax = original_half_image - halfmax_repeated;
%     partial_offset = difference_from_halfmax./gradients;
%     maxima_indices_refined = mask_maxima.*(halfpoint_indices_repeated - partial_offset);
%     [refined_wall_indices, ~] = max(maxima_indices_refined, [], 1);
%     
%     % Create a mask of points on the interior airway walls
%     wall_mask = uint8(radii_indices_repeated == repmat(indices_halfpoint, [number_of_radii, 1]));
%     outer_wall_mask = uint8(radii_indices_repeated == repmat(indices_halfpoint_outer, [number_of_radii, 1]));
% % end
% 





% end

% function [radius_mm_list, wall_thickness_mm_list, global_coords] = GetRadiusAndCentrepoint(interpolated_volume)
% %     centre_point_voxels, direction_vector_voxels, ...
% %         lung_image_as_double, expected_radius_mm, voxel_size_mm, figure_airways_3d)
%     
%     
%     
%     
%     
% %     % Compute the corresponding cartesian coordinates
% %     [i_coord_voxels_full, j_coord_voxels_full, k_coord_voxels_full] = PolarToGlobal(r_full, theta_half, centre_point_voxels, voxel_size_mm, x_prime_norm, y_prime_norm);
% %     
% %     [i_coord_voxels_half, j_coord_voxels_half, k_coord_voxels_half] = PolarToGlobal(r_half, theta_full, centre_point_voxels, voxel_size_mm, x_prime_norm, y_prime_norm);
% %     
% %     % Interpolate the lung image
% %     values_full = interpn(lung_image_as_double.RawImage, i_coord_voxels_full(:), j_coord_voxels_full(:), k_coord_voxels_full(:), 'cubic');
% %     values_half = interpn(lung_image_as_double.RawImage, i_coord_voxels_half(:), j_coord_voxels_half(:), k_coord_voxels_half(:), 'cubic');
% %     
% %     interp_image_full = zeros(size(i_coord_voxels_full), 'double');
% %     interp_image_full(:) = values_full(:);
% %     interp_image_half = zeros(size(i_coord_voxels_half), 'double');
% %     interp_image_half(:) = values_half(:);
%     
%     % Phase congruency
%     pc_image_2d = phasecong3(interp_image_half, 10, 8, 4, 1.3, 0.85, 2, 0.5, 10, -1);
%     pc_image_2d_new = phasecong3_1D(interp_image_half, 10, 8, 4, 1.3, 0.85, 2, 0.5, 10, -1);
% %     pc_image = phasecong3(interp_image);
% %     pc_image2 = PTKPhaseCongruency2D(interp_image);
%     pc_image1 = PTKPhaseCongruency1D(interp_image_half);
%     PTKViewer(PTKImage(interp_image_half, PTKImageType.Grayscale, [1 2 1]))
%     PTKViewer(PTKImage(pc_image1, PTKImageType.Grayscale, [1 2 1]))
%     
%     composite_image = zeros(size(interp_image_half));
%     for col_index = 1 : size(composite_image, 2)
%         col = interp_image_half(:, col_index);
%         pc = PTKPhaseCongruency1D(col);
%         composite_image(:, col_index) = pc;
%     end
%     PTKViewer(PTKImage(composite_image, PTKImageType.Grayscale, [1 2 1]))
%     
%     figure
% 
%     imagesc(composite_image); colormap gray
%     PTKViewer(1000*composite_image);
%     
%     [M m or ft pc EO, T] = phasecong3(interp_image_full);
%     
%     theta_outer = 3*pi/4;
%     ft2 = ft;
% %     ft2 = ft + pi*(ft<0);
%     feature_dependent_pc = M.*max(cos(ft2 - theta_outer), 0);
%     figure
% 
%     imagesc(feature_dependent_pc); colormap gray
%     PTKViewer(PTKImage(100*feature_dependent_pc, PTKImageType.Grayscale, [1 5 1]))
%     
% %     theta_inner = pi/2;
% %     ft2 = ft + pi*(ft<0);
% %     feature_dependent_pc = M.*max(cos(ft2 - theta_inner), 0);
% %     figure
% %     imagesc(feature_dependent_pc); colormap gray
% %     PTKViewer(PTKImage(100*feature_dependent_pc, PTKImageType.Grayscale, [1 5 1]))
% %     
% %     PTKViewer(PTKImage(interp_image_full, PTKImageType.Grayscale, [1 5 1]))
%     
%     % Limit the intensity values to a threshold in order to prevent
%     % airway wall measurement being skewed by nearby high intensity
%     % tissue
%     min_hu = -1024;
%     max_hu = 0;
%     min_intensity = lung_image_as_double.HounsfieldToGreyscale(min_hu);
%     max_intensity = lung_image_as_double.HounsfieldToGreyscale(max_hu);
%     interp_image_full = max(double(min_intensity), interp_image_full);
%     interp_image_full = min(double(max_intensity), interp_image_full);
%     midpoint = ceil(size(interp_image_full, 1)/2);
%     upper_half = interp_image_full(midpoint:end, :);
%     lower_half = interp_image_full(midpoint:-1:1, :);
%     
%     [upper_wall_indices, wall_mask_upper, upper_wall_indices_refined, outer_upper_wall_indices, outer_wall_mask_upper] = FindWall(upper_half);
%     [lower_wall_indices, wall_mask_lower, lower_wall_indices_refined, outer_lower_wall_indices, outer_wall_mask_lower] = FindWall(lower_half);
%     
%     % Indices that could not be found have index -1
%     mask = (upper_wall_indices >= 0) & (lower_wall_indices >= 0);
%     upper_wall_indices = upper_wall_indices + midpoint - 1;
%     lower_wall_indices = midpoint + 1 - lower_wall_indices;
%     upper_wall_indices_refined = upper_wall_indices_refined + midpoint - 1;
%     lower_wall_indices_refined = midpoint + 1 - lower_wall_indices_refined;
%     
%     outer_mask_upper = (outer_upper_wall_indices >= 0) & (upper_wall_indices >= 0);
%     outer_mask_lower = (outer_lower_wall_indices >= 0) & (lower_wall_indices >= 0);
%     outer_upper_wall_indices = outer_upper_wall_indices + midpoint - 1;
%     outer_lower_wall_indices = midpoint + 1 - outer_lower_wall_indices;
%     
%     % Compute the wall thickness
%     wall_thickness_upper_mm = (outer_upper_wall_indices(outer_mask_upper) - upper_wall_indices(outer_mask_upper))*step_size_mm;
%     wall_thickness_lower_mm = (lower_wall_indices(outer_mask_lower) - outer_lower_wall_indices(outer_mask_lower))*step_size_mm;
%     wall_thickness_mm_list = [wall_thickness_upper_mm, wall_thickness_lower_mm];
%     wall_thickness_mm_list = max(step_size_mm, wall_thickness_mm_list);
%     
%     % Extract out only the valid values
%     upper_wall_indices_refined = upper_wall_indices_refined(mask);
%     lower_wall_indices_refined = lower_wall_indices_refined(mask);
%     upper_wall_indices = upper_wall_indices(mask);
%     lower_wall_indices = lower_wall_indices(mask);
%     
%     diameters_mm = abs(upper_wall_indices_refined - lower_wall_indices_refined)*step_size_mm;
%     radius_mm_list = diameters_mm/2;
% 
%     midpoints = (upper_wall_indices_refined + lower_wall_indices_refined) / 2 - midpoint;
%     
%     midpoints_mm = midpoints*step_size_mm;
%     [mp_i, mp_j, mp_k] = PolarToGlobal(midpoints_mm, half_angle_range(mask), centre_point_voxels, voxel_size_mm, x_prime_norm, y_prime_norm);
%     
%     global_coords = [mean(mp_i), mean(mp_j), mean(mp_k)];
% 
%     
% % Display    
% figure_handle = ShowInterpolatedWall(interp_image_full, midpoints, mask, wall_mask_upper, wall_mask_lower, outer_wall_mask_upper, outer_wall_mask_lower, midpoint, airway_max_mm);
%     
%     % Debugging
%     if ~isempty(figure_airways_3d)
%         figure_handle = ShowInterpolatedWall(interp_image_full, midpoints, mask, wall_mask_upper, wall_mask_lower, outer_wall_mask_upper, outer_wall_mask_lower, midpoint, airway_max_mm);
%         ShowInterpolatedCoordinatesOn3dFigure(figure_airways_3d, lung_image_as_double, centre_point_voxels, i_coord_voxels_full, j_coord_voxels_full, k_coord_voxels_full)
%         
%         file_name = '/Users/tom/Desktop/AirwaysWithRadiusFinding3D-TEST';
%         resolution_dpi = 600;
%         resolution_str = ['-r' num2str(resolution_dpi)];
%         print(figure_airways_3d, '-dpng', resolution_str, file_name);     % Export to .png
%         print(figure_airways_3d, '-depsc2', '-painters', resolution_str, file_name);
% 
%     end
% end

% % For showing the stretched out wall with midpoints and walls superimposed
% function figure_handle = ShowInterpolatedWall(interp_image, midpoints_part, midpoints_mask, wall_mask_upper, wall_mask_lower, outer_wall_mask_upper, outer_wall_mask_lower, midpoint, airway_max_mm)
%     
%     midpoint_colour = 3;
%     
%     viewer = PTKViewer(interp_image, PTKImageType.Grayscale);
%     viewer.ViewerPanelHandle.Orientation = PTKImageOrientation.Axial;
%     midpoints = zeros(size(midpoints_mask));
%     midpoints(midpoints_mask) = midpoints_part + midpoint - 1;
%     midpoint_repeated = repmat(round(midpoints), [size(interp_image, 1), 1]);
%     radii_indices = (1 : size(interp_image, 1))';
%     radii_repeated = repmat(radii_indices, [1, size(interp_image, 2)]);
%     mp = midpoint_repeated == radii_repeated;
%     
%     
%     wall_overlay = zeros(size(interp_image), 'uint8');
%     wall_overlay(midpoint:end, :) = wall_mask_upper + 2*outer_wall_mask_upper;
%     wall_overlay(midpoint:-1:1, :) = wall_mask_lower + 2*outer_wall_mask_lower;
%     wall_overlay(mp) = midpoint_colour;
%     
%     viewer.ViewerPanelHandle.OverlayImage = PTKImage(wall_overlay);
%     
%     
%     interp_image_full = [interp_image(end:-1:midpoint,:), interp_image(1:midpoint,:)];
%     viewer2 = PTKViewer(interp_image_full, PTKImageType.Grayscale);
%     viewer2.ViewerPanelHandle.Orientation = PTKImageOrientation.Axial;
% 
%     wall_overlay_full = [wall_overlay(end:-1:midpoint, :), wall_overlay(1:midpoint, :)];
%     viewer2.ViewerPanelHandle.OverlayImage = PTKImage(wall_overlay_full);
%     
%     viewer2.ViewerPanelHandle.Window = 928;
%     viewer2.ViewerPanelHandle.Level = -200; % 272;
%     frame = viewer2.ViewerPanelHandle.Capture;
%     
%     figure(11);
%     figure_handle = gcf;
%     imagesc([0, 360], [airway_max_mm, 0], frame.cdata);
%     
%     label_font_size = 9;
%     axis_line_width = 1;
%     axes_label_font_size = 7;
%     widthheightratio = 4/3;
%     page_width_cm = 12;
%     resolution_dpi = 600;
%     font_name = PTKSoftwareInfo.GraphFont;
% 
%     set(figure_handle, 'Units','centimeters');
%     graph_size = [page_width_cm, (page_width_cm/widthheightratio)];
%     
%     axes_handle = gca;
%     set(figure_handle, 'Name', 'FWHM');
%     set(figure_handle, 'PaperPositionMode', 'auto');
%     set(figure_handle, 'position', [0,0, graph_size]);
%     
%     hold(axes_handle, 'on');
%     axis manual
%     
%     axes_handle = gca;
%     set(axes_handle, 'FontSize', axes_label_font_size);
%     set(axes_handle, 'LineWidth', axis_line_width);
%     
%     xlabel('\theta (degrees)', 'FontName', font_name, 'FontSize', label_font_size);
%     ylabel('r (mm)', 'FontName', font_name, 'FontSize', label_font_size);
%     set(gca,'YDir','normal')
%     
%     resolution_str = ['-r' num2str(resolution_dpi)];
%     print(figure_handle, '-dpng', resolution_str, '~\Desktop\Radius finding 2D.png');     % export .png
%     
% end

% function ShowInterpolatedCoordinatesOn3dFigure(figure_airways_3d, lung_image, centre_point_voxels, i_coord_voxels, j_coord_voxels, k_coord_voxels)
%     figure(figure_airways_3d);
%     hold on;
% 
%     global_centre_point_voxels = lung_image.LocalToGlobalCoordinates([centre_point_voxels(:, 1), centre_point_voxels(:, 2), centre_point_voxels(:, 3)]);
%     [ic_cp, jc_cp, kc_cp] = lung_image.GlobalCoordinatesToCoordinatesMm(global_centre_point_voxels);
%     [ic_cp, jc_cp, kc_cp] = lung_image.GlobalCoordinatesMmToCentredGlobalCoordinatesMm(ic_cp, jc_cp, kc_cp);
%     plot3(jc_cp, ic_cp, - kc_cp, 'rx', 'MarkerSize', 10);
%     
%     global_coordinates = lung_image.LocalToGlobalCoordinates([i_coord_voxels(:), j_coord_voxels(:), k_coord_voxels(:)]);
%     [ic, jc, kc] = lung_image.GlobalCoordinatesToCoordinatesMm(global_coordinates);
%     [ic, jc, kc] = lung_image.GlobalCoordinatesMmToCentredGlobalCoordinatesMm(ic, jc, kc);
%     
%     plot3(jc(:), ic(:), -kc(:), 'r.');    
% end




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

