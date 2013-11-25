classdef PTKAirwayGenerator < handle
    % PTKAirwayGenerator. Creates an artifical airway tree using a volume-filling
    % algorithm.
    %
    %     This class generates an artificial model of the airway tree. You
    %     specify the lung volume to fill, and provide a starting tree (such as 
    %     that produced by a CT region-growing algorithm). The airway growing
    %     starts at the endpoints of the starting tree and grows into the
    %     provided volume. The resulting tree includes the starting tree.
    %
    %     You can also choose to grow specific parts of the tree into specific
    %     volumes, so for example a lobar region can be exclusively allocated to
    %     a lobar bronchus and its descendents.
    %
    %     This code has in part been adapted from C++ code by Rafel Bordas which
    %     forms part of the Chaste project at the University of Oxford.
    %     The algorithm is derived from Tawhai et al. (2004), although some
    %     changes have been made to the algorithm.
    %
    %     Syntax:
    %         airway_generator = PTKAirwayGenerator(
    %             lung_mask,              % A binary mask of the whole lung volume
    %             centreline_tree,          % A PTKModelTree produced from PTKAirwayCentreline
    %             point_limit_voxels,     % Branches will terminate if the size of the region they grow into in voxels is less than this limit
    %             approx_number_points,   %
    %             reporting               % A PTKReporting object for error, warning and progress reporting
    %         )
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %

    properties (Constant)
        LengthLimitMm = 1.2 % A branch is terminated if its length is less than this value. Tawhai et al 2004 use value 2.
        PointLimitVoxels = 1 % A branch is terminated if the point cloud of the apex has fewer points than this limit
        NumberOfGenerationsToReallocate = 20  % If ReallocatePointsAtEachGeneration is set to true, this is the number of generations for which points in the volume will be reallocated at each generation
        PointNumberMultiple = 1 % The desired number of grid points is obtained by multiplying approx_number_points by this value
        MaximumGenerationNumber = 25     % All branches of the output tree will terminate if they extend beyond this generation number
        InitialTerminatingBranchLengthLimit = 6
        BranchingFraction = 0.4 % The fraction a branch extends towards the centre of the point cloud. Value 0.4 from Tawhai et al., 2004
        ReallocatePointsAtEachGeneration = true % If true, points will be reassigned to apices at each generation up to the generation number set in NumberOfGenerationsToReallocate
        AngleLimitRadians = 60*(pi/180.0); % Value 60 degrees from Tawhai et al, 2004
        PointDistanceLimit = 5 % Points greather than a voxel distance of this number multiplied by the number of cloud points are removed from the apex cloud
        BranchLengthToParentRatioLimit = 1 % Child branches cannot be longer than this factor multiplied by ther parent's length
        BranchLengthToParentGenerationLimit = 20 % The BranchLengthToParentRatioLimit parameter starts taking effect from this generation number
    end
    
    
    properties
        AirwayTree
        InitialApexImage
        GridSpacingMm
    end
    
    methods
        function obj = PTKAirwayGenerator(lung_mask, centreline_tree, approx_number_points, reporting)

            % Compute the grid spacing. We choose to have more grid points than
            % the minimum required as a finer grid will give better branching
            approx_number_grid_points = PTKAirwayGenerator.PointNumberMultiple*approx_number_points;
            obj.GridSpacingMm = lung_mask.ComputeResamplingGridSpacing(approx_number_grid_points);
            
            % Initialise airway tree
            initial_airway_tree = obj.CreateInitialTreeFromSegmentation(centreline_tree, PTKAirwayGenerator.MaximumGenerationNumber, reporting);
            obj.RemoveSmallTerminatingAirways(initial_airway_tree, PTKAirwayGenerator.InitialTerminatingBranchLengthLimit, reporting);
            obj.AirwayTree = initial_airway_tree;
        end
        
        function delete(~)
        end
        
        % Starting from the initial airway tree generated from AddTree(),  
        function GrowTree(obj, growth_volume, starting_segment, reporting)
            obj.InitialApexImage = PTKAirwayGenerator.GrowTreeUsingThisGridSpacing(obj.AirwayTree, growth_volume, starting_segment, obj.GridSpacingMm, reporting);
        end        
    end
    
    methods (Static, Access = private)
        function initial_apex_image = GrowTreeUsingThisGridSpacing(airway_tree, growth_volume, starting_segment, grid_spacing_mm, reporting)
            
            reporting.PushProgress;
            
            resampled_volume = PTKAirwayGenerator.CreatePointCloud(growth_volume, grid_spacing_mm);
            disp(['Number of seed points:' int2str(sum(resampled_volume.RawImage(:)))]);
            
            initial_apex_image = PTKAirwayGenerator.Grow(resampled_volume, airway_tree, starting_segment, reporting);
            
            reporting.PopProgress;
        end
        
        % Use CreateInitialTreeFromSegmentation to create an initial airway tree
        % from the airway centreline results
        function airway_tree = CreateInitialTreeFromSegmentation(segmented_centreline_tree, maximum_generation_number, reporting)
            airway_tree = PTKAirwayGrowingTree;
            airway_tree.CentrelineTreeSegment = segmented_centreline_tree;
            segments_to_do = airway_tree;
            while ~isempty(segments_to_do)
                segment = segments_to_do(end);
                segments_to_do(end) = [];
                
                % Get the first and last voxel coordinates from the segment of
                % the centreline airway tree
                centreline_segment = segment.CentrelineTreeSegment;
                if isempty(segment.Parent)
                    first_point = centreline_segment.Centreline(1);
                else
                    first_point = centreline_segment.Parent.Centreline(end);
                end
                end_point = centreline_segment.Centreline(end);
                
                

                segment.StartCoords = [first_point.CoordI, first_point.CoordJ, first_point.CoordK];
                segment.EndCoords = [end_point.CoordI, end_point.CoordJ, end_point.CoordK];
                
                if isempty(centreline_segment.GenerationNumber)
                    error('program error');
                end
                
                if centreline_segment.GenerationNumber >= maximum_generation_number
                    reporting.ShowWarning('PTKAirwayGenerator:SegmentedBranchesExcluded', 'Initial branches have been excluded due to the maximum generation parameter', []);
                else
                    
                    if ~isempty(centreline_segment.Children)
                        % Add a new branch to the tree for each child
                        for child = centreline_segment.Children
                            % Create a new segment
                            new_segment = PTKAirwayGrowingTree(segment);
                            new_segment.CentrelineTreeSegment = child;
                            new_segment.IsGenerated = false;
                            segments_to_do = [segments_to_do, new_segment];
                        end
                    end
                end
                
            end
        end
        
        function RemoveSmallTerminatingAirways(initial_airway_tree, length_limit, reporting)
            branches_to_do = initial_airway_tree;
            has_changed = true;
            iteration_number = 0;
            while (has_changed)
                has_changed = false;
                iteration_number = iteration_number + 1;
                while ~isempty(branches_to_do)
                    branch = branches_to_do(end);
                    branches_to_do(end) = [];
                    if isempty(branch.Children)
                        branch_length = norm(branch.StartCoords - branch.EndCoords);
                        if branch_length < length_limit
                            if ~isempty(branch.Parent)
                                reporting.ShowWarning('PTKAirwayGenerator:SegmentedBranchesBelowLimit', 'Initial branches have been excluded due to their length being below the limit', []);
                                branch.Parent.RemoveChildren;
                                has_changed = true;
                            end
                        end
                        
                    else
                        branches_to_do = [branches_to_do, branch.Children];
                    end
                end
            end
        end
        
        function in_volume = IsInsideVolume(point_mm, lung_volume)
            global_coordinates = lung_volume.CoordinatesMmToGlobalCoordinates(point_mm);
            if ~lung_volume.IsPointInImage(global_coordinates)
                in_volume = false;
            else
                in_volume = lung_volume.GetVoxel(global_coordinates);
            end
        end

        function apices = GetApicesBelowThisBranchForTerminalSegments(centreline_branches, airway_tree, generation_number, reporting)
            apices = [];
            
            % Find the starting segments
            segments_to_do = [];
            for centreline_branch = centreline_branches
                branch = airway_tree.FindCentrelineBranch(centreline_branch, reporting);
                segments_to_do = [segments_to_do, branch];
            end
            
            % Now search the tree below the starting segments and create an apex
            % for each one at the correct generation number
            while ~isempty(segments_to_do)
                segment = segments_to_do(end);
                segments_to_do(end) = [];
                children = segment.Children;
                segments_to_do = [segments_to_do, children];
                
                % Now search the tree below the starting segments and create an apex
                % for each one that is a terminal segment
                if isempty(children) && isempty(segment.IsTerminal)
                    % Add apices for airway growing
                    new_apex = PTKAirwayGeneratorApex(segment, PTKPoints, true);
                    apices = [apices new_apex];
                end
            end
        end
        
        function apices = GetApicesBelowThisBranchForThisGeneration(start_centreline_branches, airway_tree, generation_number, reporting)
            apices = [];
            
            % Find the starting segments
            segments_to_do = [];
            for centreline_branch = start_centreline_branches
                branch = airway_tree.FindCentrelineBranch(centreline_branch, reporting);
                segments_to_do = [segments_to_do, branch];
            end

            % Now search the tree below the starting segments and create an apex
            % for each one at the correct generation number
            while ~isempty(segments_to_do)
                segment = segments_to_do(end);
                segments_to_do(end) = [];
                children = segment.Children;
                segments_to_do = [segments_to_do, children];
                
                % Find all branches of this generation which have not been
                % terminaetd by the algorithm. This includes branches which
                % already have child branches - these will not be grown, but
                % points will be allocated to their apices so that they may
                % later be available for their child branches to grow
                if segment.GenerationNumber == generation_number
                    if isempty(segment.IsTerminal)
                        is_growing_apex = isempty(children);
                        new_apex = PTKAirwayGeneratorApex(segment, PTKPoints, is_growing_apex);
                        apices = [apices new_apex];
                    end
                end
            end
        end
        
        function generation_number = GetMinimumTerminalGeneration(apices)
            generation_number = [];
            for apex = apices
                apex_generation = apex.AirwayGrowingTreeSegment.GenerationNumber;
                if isempty(generation_number)
                    generation_number = apex_generation;
                else
                    generation_number = min(generation_number, apex_generation);
                end
            end
        end
        
        % Find the smallest generation number of a branch in the airway tree
        % which is still growing. This will return an empty variable if no more
        % airways are growing
        function generation_number = GetMinimumActiveTerminalGeneration(airway_tree, start_centreline_branches, reporting)
            % Find the starting segments
            segments_to_do = [];
            for centreline_branch = start_centreline_branches
                branch = airway_tree.FindCentrelineBranch(centreline_branch, reporting);
                segments_to_do = [segments_to_do, branch];
            end

            generation_number = [];
            while ~isempty(segments_to_do)
                next_branch = segments_to_do(end);
                child_branches = next_branch.Children;
                
                % A branch is still growing if it has no child branches and it
                % has not been terminated by the growing algorithm
                if isempty(child_branches) && isempty(next_branch.IsTerminal)
                    
                    % We want the smallest generation number for the tree
                    if (isempty(generation_number) || (generation_number > next_branch.GenerationNumber))
                        generation_number = next_branch.GenerationNumber;
                    end 
                end
                
                segments_to_do(end) = [];
                segments_to_do = [segments_to_do child_branches];
            end
        end
        
        function centre = GetCentreOfMass(point_cloud)
            cloud_points = point_cloud.Coords;
            centre = mean(cloud_points, 1);
        end
        
        function new_image = GetImageFromApex(template, apices)
            new_image = zeros(template.ImageSize, 'uint16');
            colour = 1;
            for apex = apices
                cloud_points = apex.PointCloud.Coords;
                point_coord = template.CoordinatesMmToGlobalCoordinates(cloud_points);
                point_coord = template.GlobalToLocalCoordinates(point_coord);
                indices = sub2ind(template.ImageSize, point_coord(:,1), point_coord(:,2), point_coord(:,3)); 
                new_image(indices) = colour;
                colour = colour + 1;
            end
        end
        
        function centreline_indices_local = CentrelinePointsToLocalIndices(centreline_points, template_image)
            ic = [centreline_points.CoordI];
            jc = [centreline_points.CoordJ];
            kc = [centreline_points.CoordK];
            centreline_indices_global = sub2ind(template_image.OriginalImageSize, ic, jc, kc);
            centreline_indices_local = template_image.GlobalToLocalIndices(centreline_indices_global);
        end
        
        function closest_point = FindClosestPointInCloud(point, cloud)
            num_points_in_cloud = size(cloud.Coords, 1);
            distance = cloud.Coords - repmat(point, [num_points_in_cloud, 1]);
            distance = sqrt(distance(:,1).^2 + distance(:,2).^2 + distance(:,3).^2);
            [~, min_index] = min(distance, [], 1);
            closest_point = cloud.Coords(min_index, :);
        end
        
        % Compute a normalised direction vector for a plane parallel to the
        % given vector and the direction of the given branch. If the two vectors
        % are parallel then the direction of the parent branch is used. If this
        % does not exist or is still parallel, then we choose a guaranteed
        % non-parallel vector using the null space.
        function plane_normal = GetValidPlaneNormal(vector_to_com, branch)
            
            if ~isempty(branch.Parent)
                parent_branch_direction = branch.Parent.Direction;
                plane_normal = cross(vector_to_com, parent_branch_direction);
            else
                branch_direction = branch.Direction;
                plane_normal = cross(vector_to_com, branch_direction);
            end
            
            % This is an implementation of the algorithm described in Tawhai et
            % al., 2004 for finding the plane. However, this does not work since
            % the parent branch will often be collinear with the centre of mass
            % point (since branches are created in the direction of the centre
            % of mass).
%             branch_direction = branch.Direction;
%             
%             % Find the normal to the plane which passes through the centre
%             % of mass and the branch start and end points
%             plane_normal = cross(vector_to_com, branch_direction);
%             
%             % If the branch direction is parallel to the vector then we try the
%             % parent direction
%             if isequal(plane_normal, [0 0 0])
%                 disp('parallel - correcting');
%                 if ~isempty(branch.Parent)
%                     parent_branch_direction = branch.Parent.Direction;
%                     plane_normal = cross(vector_to_com, parent_branch_direction);
%                 end
%             end
            
            % If the vectors are still parallel then we use the null space to
            % find another vector which is perpendicular
            if isequal(plane_normal, [0 0 0])
                disp('still parallel - correcting');
                plane_null_space = null(vector_to_com/norm(vector_to_com));
                perpendicular_vector = plane_null_space(:, 1);
                plane_normal = cross(vector_to_com, perpendicular_vector);
            end
            
            plane_normal = plane_normal / norm(plane_normal);
        end
        
        % Divides the point cloud in two, based on a plane perpendicular to the
        % direction of the last two branches
        function [this_plane, other_plane] = SplitPointCloud(point_cloud, normal, origin)
            points_coords = point_cloud.Coords;
            p = - dot(normal, origin);
            
            % Find which axis is most parallel to the plane
            [~, ordered_directions] = sort(normal, 'descend');
            main_direction = ordered_directions(1);
            other_directions = ordered_directions(2:3);
            plane_points = - (p + normal(other_directions(1))*points_coords(:, other_directions(1)) + normal(other_directions(2))*points_coords(:, other_directions(2)))/normal(main_direction);
            in_plane = points_coords(:, main_direction) < plane_points;
            this_plane = PTKPoints(points_coords(in_plane, :));
            other_plane = PTKPoints(points_coords(~in_plane, :));
        end
        
        function resampled_volume = CreatePointCloud(growth_volume, grid_spacing_mm)
            resampled_volume = growth_volume.Copy;
            grid_spacing = [grid_spacing_mm, grid_spacing_mm, grid_spacing_mm];
            resampled_volume.Resample(grid_spacing, '*nearest')
        end
       
        % Checks the branch angle of a proposed growth centre and adjusts it within tolerance, if necessary
        function end_coords = CheckBranchAngleLengthAndAdjust(start_coords, end_coords, parent_direction, parent_length_mm, generation_number)
            % calculate vector from apex start to the centre
            start_point = start_coords;
            new_direction = end_coords - start_point;
            
            % Record the branching length
            branch_length = norm(new_direction);
            
            new_direction = new_direction / norm(new_direction);
            
            old_direction = parent_direction;
            old_direction = old_direction / norm(old_direction);
            
            % determine branch angle
            dot_product = dot(new_direction, parent_direction);
            branch_angle = acos(dot_product/(norm(new_direction)*norm(parent_direction)));

            % If the branch angle is above the limit then set it to the limit
            if (branch_angle > PTKAirwayGenerator.AngleLimitRadians)
                perpendicular_one = cross(new_direction, old_direction);
                perpendicular_one = perpendicular_one/norm(perpendicular_one);
                perpendicular_two = cross(old_direction, perpendicular_one);
                perpendicular_two = perpendicular_two/norm(perpendicular_two);
                old_direction = old_direction*cos(PTKAirwayGenerator.AngleLimitRadians);
                perpendicular_two = perpendicular_two*sin(PTKAirwayGenerator.AngleLimitRadians);
                new_direction = old_direction + perpendicular_two;
            end
            
            % Reduce the branch length as required
            branch_length = branch_length*PTKAirwayGenerator.BranchingFraction;
            if generation_number >= PTKAirwayGenerator.BranchLengthToParentGenerationLimit
                branch_length = min(branch_length, parent_length_mm*PTKAirwayGenerator.BranchLengthToParentRatioLimit);
            end
            new_direction = new_direction * branch_length;
            
            % Update the centre
            end_coords = start_point + new_direction;
        end
        
        function new_apex = AddBranchAndApex(parent_branch, cloud, lung_volume, lung_mask, generation_number, image_size, reporting)
            new_apex = [];
            
            % Determine the centre of the point cloud
            centre_of_mass = PTKAirwayGenerator.GetCentreOfMass(cloud);
            
            % The new branch starts at the end of the parent branch
            new_branch_start_point = parent_branch.EndCoords;
            
            % Fetch the director vector of the parent branch
            parent_direction = parent_branch.Direction;
            
            % Calculate the end point of the new branch. This is subject both to
            % a length limit and an angle limit.
            new_branch_end_point = PTKAirwayGenerator.CheckBranchAngleLengthAndAdjust(new_branch_start_point, centre_of_mass, parent_direction, parent_branch.Length, generation_number);

            if ~PTKAirwayGenerator.IsInsideVolume(new_branch_end_point, lung_mask)
                reporting.ShowWarning('PTKAirwayGenerator:OutsideVolume', 'Branches terminated because they grew outside the lung volume', []);
                parent_branch.IsTerminal = true;
                return;
            end
            
            % Create the new branch in AirwayTree
            new_branch = PTKAirwayGrowingTree(parent_branch);
            new_branch.StartCoords = new_branch_start_point;
            new_branch.EndCoords = new_branch_end_point;
            new_branch.IsGenerated = true;

            new_branch_length = norm(new_branch_end_point - new_branch_start_point);            

            % Find closest point in cloud and delete
            closest_point = PTKAirwayGenerator.FindClosestPointInCloud(new_branch_end_point, cloud);
            closest_point_global_coords = lung_volume.CoordinatesMmToGlobalCoordinates(closest_point);
            lung_volume.SetVoxelToThis(closest_point_global_coords, 0);
            
            % Check if the number of points in the cloud is less than the
            % required minimum
            if (size(cloud.Coords, 1) <= PTKAirwayGenerator.PointLimitVoxels)
                new_branch.IsTerminal = true;
                reporting.ShowWarning('PTKAirwayGenerator:BelowLengthThreshold', 'Branches terminated because the number of points was below the threshold', []);
            else
                if (new_branch_length < PTKAirwayGenerator.LengthLimitMm)
                    new_branch.IsTerminal = true;
                    reporting.ShowWarning('PTKAirwayGenerator:BelowLengthThreshold', 'Branches terminated because their length was below the threshold', []);
                else
                    % Create new growth branch
                    new_apex = PTKAirwayGeneratorApex(new_branch, cloud, true);
                end
            end
        end
        
        function apices = AssignPointCloudToApices(apices, resampled_volume, reporting)
            if numel(apices) == 0
               reporting.Error('PTKAirwayGenerator:AssignPointCloudToApices', 'No starting points');
            end
            sample_image = zeros(resampled_volume.ImageSize, 'uint16');
            apex_start_points = zeros(numel(apices), 3);
            for apex_number = 1 : numel(apices)
                apex = apices(apex_number);
                end_point_mm = apex.AirwayGrowingTreeSegment.EndCoords;
                end_point_global_coordinates = resampled_volume.CoordinatesMmToGlobalCoordinates(end_point_mm);
                end_point = resampled_volume.GlobalToLocalCoordinates(end_point_global_coordinates);
                apex_start_points(apex_number, :) = [end_point(1), end_point(2), end_point(3)];
                current_value = sample_image(end_point(1), end_point(2), end_point(3));
                if current_value ~= 0
                    reporting.ShowWarning('PTKAirwayGenerator:ApexAlreadyUsed', 'The start point for allocating voxels to apices could not be assigned as the point has already been used by another apex', []);
                end
                sample_image(end_point(1), end_point(2), end_point(3)) = apex_number;
            end
            
            bw_image = sample_image > 0;
            
            [~, IDX] = bwdist(bw_image);
            mapped_image = sample_image(IDX);
            mapped_image_masked = zeros(size(bw_image), 'uint16');
            point_indices = find(resampled_volume.RawImage);
            mapped_image_masked(point_indices) = mapped_image(point_indices);
            
            for apex_number = 1 : numel(apices)
                local_indices = find(mapped_image_masked == apex_number);
                if ~isempty(local_indices)
                    [di, dj, dk] = ind2sub(size(mapped_image_masked), local_indices);
                    
                    % Calculate the distance from these new points to the start
                    % point
                    root_point = apex_start_points(apex_number, :);
                    di = di - root_point(1);
                    dj = dj - root_point(2);
                    dk = dk - root_point(3);
                    dist_voxels = sqrt(di.^2 + dj.^2 + dk.^2);
                    points_too_far_away = dist_voxels > PTKAirwayGenerator.PointDistanceLimit*numel(local_indices);
                    
                    % This is a check for distance from root point compared to
                    % parent length
%                     di = (di - root_point(1))*resampled_volume.VoxelSize(1);
%                     dj = (dj - root_point(2))*resampled_volume.VoxelSize(2);
%                     dk = (dk - root_point(3))*resampled_volume.VoxelSize(3);
%                     dist_mm = sqrt(di.^2 + dj.^2 + dk.^2);
%                     last_branch_length = apices(apex_number).AirwayGrowingTreeSegment.Length;
%                     points_too_far_away = dist_mm > PTKAirwayGenerator.PointDistanceLimit*last_branch_length;

                    number_of_points_to_remove = sum(uint8(points_too_far_away));
                    if number_of_points_to_remove > 0
                        disp([int2str(number_of_points_to_remove) ' points removed as they were too far away (generation' int2str(apices(apex_number).AirwayGrowingTreeSegment.GenerationNumber) ')']);
                    end
                    local_indices = local_indices(~points_too_far_away, :);
                    
                    global_indices =  resampled_volume.LocalToGlobalIndices(local_indices);
                    [ic, jc, kc] = resampled_volume.GlobalIndicesToCoordinatesMm(global_indices);
                    apices(apex_number).PointCloud.Coords = [ic, jc, kc];
                else
                    apices(apex_number).PointCloud.Coords = [];
                end
            end
        end
        
        function [apex_1, apex_2] = GrowApex(current_apex, lung_volume, lung_mask, generation_number, image_size, reporting)
            branch = current_apex.AirwayGrowingTreeSegment;

            if isempty(current_apex.PointCloud.Coords)
                branch.IsTerminal = true;
                reporting.ShowWarning('PTKAirwayGenerator:EmptyPointCloud', 'Branches terminated because they had an empty point cloud', []);
                apex_1 = [];
                apex_2 = [];
            elseif size(current_apex.PointCloud.Coords, 1) < 2
                branch.IsTerminal = true;
                reporting.ShowWarning('PTKAirwayGenerator:TooFewPointsInCloud', 'Branches terminated because there was only one point in the point cloud', []);
                apex_1 = [];
                apex_2 = [];
            else
                
                % Find the end coordinates for this branch
                branch_end_coords = branch.EndCoords;

                % Find the centre of mass for the point cloud assigned to this
                % apex
                centre_of_mass = PTKAirwayGenerator.GetCentreOfMass(current_apex.PointCloud);
                
                % Create a vector from the end branch point to the centre of
                % mass
                vector_to_com = centre_of_mass - branch_end_coords;
                
                % Get a normalised vector perpendicular to the plane passing
                % through the centre of pass and the start and end points of the
                % branch
                plane_normal = PTKAirwayGenerator.GetValidPlaneNormal(vector_to_com, branch);
                
                % Split the point cloud into two, creating a new apex for each if there are enough points
                [cloud1, cloud2] = PTKAirwayGenerator.SplitPointCloud(current_apex.PointCloud, plane_normal, branch_end_coords);
                
                if isempty(cloud1.Coords) || isempty(cloud2.Coords)
                    reporting.ShowWarning('PTKAirwayGenerator:EmptyPointCloud', 'Branches terminated because the point clouds could not be divided into two nonempty clouds', []);
                    branch.IsTerminal = true;
                    apex_1 = [];
                    apex_2 = [];
                    return;
                end
                
                % Create new branches
                apex_1 = PTKAirwayGenerator.AddBranchAndApex(branch, cloud1, lung_volume, lung_mask, generation_number, image_size, reporting);
                apex_2 = PTKAirwayGenerator.AddBranchAndApex(branch, cloud2, lung_volume, lung_mask, generation_number, image_size, reporting);
            end
        end
        
        function [apices, initial_apex_image] = Grow(lung_volume, airway_tree, starting_segment, reporting)
            
            % We need to keep a copy of the lung mask for checking that airways
            % are inside. The original image will have points removed as airways are grown. 
            lung_mask = lung_volume.Copy;
            
            reporting.ShowProgress('Growing branches');
            reporting.UpdateProgressValue(0);
            first_run = true;
            image_size = lung_volume.ImageSize;
            
            % Set this to something non-empty for the first run
            apices = 1;
            generation_number = 1;
            
            % Step through generations one by one and terminate when there are
            % no active growing branches left
            while ~isempty(generation_number)
                
                % Find the lowest generation to grow
                generation_number = PTKAirwayGenerator.GetMinimumActiveTerminalGeneration(airway_tree, starting_segment, reporting);
                if (first_run)
                    min_generation_number = generation_number;
                end
                
                % Terminate when there are no active growing branches left
                if isempty(generation_number)
                    return;
                end
                
                % Terminate when we have exceeded a generation threshold, and
                % report how many branches were incomplete
                if generation_number >= PTKAirwayGenerator.MaximumGenerationNumber
                    reporting.ShowMessage('PTKAirwayGenerator:IncompleteApices', [num2str(length(apices)) ' branches were incomplete when the terminal generation was reached']);                    
                    return
                end
                
                % Progress reporting
                reporting.ShowMessage('PTKAirwayGenerator:GenerationNumber', ['Generation:' int2str(generation_number)]);
                reporting.UpdateProgressValue(round(100*(generation_number - min_generation_number)/(PTKAirwayGenerator.MaximumGenerationNumber - min_generation_number)));
                
                % Allocate/reallocate points to the apices
                if (first_run) || ((generation_number < PTKAirwayGenerator.NumberOfGenerationsToReallocate) && (PTKAirwayGenerator.ReallocatePointsAtEachGeneration))
                    
                    is_this_the_last_reallocation = (generation_number + 1 == PTKAirwayGenerator.NumberOfGenerationsToReallocate) || (~PTKAirwayGenerator.ReallocatePointsAtEachGeneration);
                    
                    if is_this_the_last_reallocation
                        apices = PTKAirwayGenerator.GetApicesBelowThisBranchForTerminalSegments(starting_segment, airway_tree, generation_number, reporting);
                    else
                        apices = PTKAirwayGenerator.GetApicesBelowThisBranchForThisGeneration(starting_segment, airway_tree, generation_number, reporting);
                    end
                    
                    num_apices = numel(apices);
                    apices = PTKAirwayGenerator.AssignPointCloudToApices(apices, lung_volume, reporting);
%                     disp(['Generation:' int2str(generation_number) ' Number of apices:' int2str(num_apices) ' Apices post-allocation:' int2str(numel(apices))]);
                    if (first_run)
                        initial_apex_image = PTKAirwayGenerator.GetImageFromApex(lung_volume, apices);
                        first_run = false;
                    end
                end
                
                apices_next_generation = PTKAirwayGeneratorApex.empty(50000,0);
                for apex = apices
                    
                    % Ignore non-growing apices - they are just there to help
                    % with the point reallocation
                    if (apex.IsGrowingApex)
                        % After the final point reallocation, we may have apices
                        % with higher generation numbers than the current one - this
                        % will happen if the segmented tree has a higher number of
                        % generations than the number of generations to reallocate.
                        % We ignore any apices with a higher generation number than
                        % the current one, but save these for processing later
                        if (generation_number == apex.AirwayGrowingTreeSegment.GenerationNumber)
                            [new_apex_1, new_apex_2] = PTKAirwayGenerator.GrowApex(apex, lung_volume, lung_mask, generation_number, image_size, reporting);
                            if ~isempty(new_apex_1)
                                apices_next_generation(end+1) = new_apex_1;
                            end
                            if ~isempty(new_apex_2)
                                apices_next_generation(end+1) = new_apex_2;
                            end
                        else
                            apices_next_generation(end + 1) = apex;
                        end
                    end
                end
                
                % The next generation of apices is used when point reallocation
                % no longer happens (either the point reallocation generation
                % has been exceeded, or the reallocation flag is switched off).
                % The list of apices includes newly generated apices, plus any
                % terminal branhces from the segmented airways which are waiting
                % to be grown
                apices = apices_next_generation;
            end
        end
    end
end
