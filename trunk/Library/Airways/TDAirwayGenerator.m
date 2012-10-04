classdef TDAirwayGenerator < handle
    % TDAirwayGenerator. Creates an artifical airway tree using a volume-filling
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
    %         airway_generator = TDAirwayGenerator(
    %             lung_mask,              % A binary mask of the whole lung volume
    %             centreline_tree,          % A TDModelTree produced from TDAirwayCentreline
    %             point_limit_voxels,     % Branches will terminate if the size of the region they grow into in voxels is less than this limit
    %             approx_number_points,   %
    %             reporting               % A TDReporting object for error, warning and progress reporting
    %         )
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %

    
    properties
        OriginalLungImage
        
        AirwayTree
        LengthLimitMm = 1.2 % A branch is terminated if its length is less than this value. Tawhai et al 2004 use value 2.
        PointLimitVoxels = 1 % A branch is terminated if the point cloud of the apex has fewer points than this limit
        AngleLimitRadians % Maximum permitted branch angle in degrees
        BranchingFraction = 0.4 % The fraction a branch extends towards the centre of the point cloud. Value 0.4 from Tawhai et al., 2004
        ReallocatePointsAtEachGeneration = true % If true, points will be reassigned to apices at each generation up to the generation number set in NumberOfGenerationsToReallocate
        NumberOfGenerationsToReallocate = 25  % If ReallocatePointsAtEachGeneration is set to true, this is the number of generations for which points in the volume will be reallocated at each generation
        PointNumberMultiple = 1 % The desired number of grid points is obtained by multiplying approx_number_points by this value
        Reporting
        InitialApexImage
        GridSpacingMm
        InitialTerminatingBranchLengthLimit = 6
        
        Apices
        MaximumGenerationNumber = 25     % All branches of the output tree will terminate if they extend beyond this generation number
    end
    
    methods
        function obj = TDAirwayGenerator(lung_mask, centreline_tree, approx_number_points, reporting)
            obj.OriginalLungImage = lung_mask;
            % Compute the maximum brannching angle in radians
            angle_limit_degrees = 60; % Value 60 from Tawhai et al, 2004
            obj.AngleLimitRadians = pi*angle_limit_degrees/180.0;
            
            % Compute the grid spacing. We choose to have more grid points than
            % the minimum required as a finer grid will give better branching
            approx_number_grid_points = obj.PointNumberMultiple*approx_number_points;
            obj.GridSpacingMm = lung_mask.ComputeResamplingGridSpacing(approx_number_grid_points);
            
            % Initialise other variables
            obj.Apices = [];
            obj.Reporting = reporting;
            initial_airway_tree = obj.CreateInitialTreeFromSegmentation(centreline_tree, reporting);
            obj.RemoveSmallTerminatingAirways(initial_airway_tree, obj.InitialTerminatingBranchLengthLimit, reporting);
            obj.AirwayTree = initial_airway_tree;
        end
        
        function delete(~)
        end
        
        % Use CreateInitialTreeFromSegmentation to create an initial airway tree
        % from the airway centreline results
        function airway_tree = CreateInitialTreeFromSegmentation(obj, segmented_centreline_tree, reporting)
            airway_tree = TDAirwayGrowingTree;
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
                
                if centreline_segment.GenerationNumber >= obj.MaximumGenerationNumber
                    obj.Reporting.ShowWarning('TDAirwayGenerator:SegmentedBranchesExcluded', 'Initial branches have been excluded due to the maximum generation parameter', []);
                else
                    
                    if ~isempty(centreline_segment.Children)
                        % Add a new branch to the tree for each child
                        for child = centreline_segment.Children
                            % Create a new segment
                            new_segment = TDAirwayGrowingTree(segment);
                            new_segment.CentrelineTreeSegment = child;
                            new_segment.IsGenerated = false;
                            segments_to_do = [segments_to_do, new_segment];
                        end
                    end
                end
                
            end            
        end
        
        % Starting from the initial airway tree generated from AddTree(),  
        function GrowTree(obj, growth_volume, starting_segment, reporting)
            % ToDo: This is too specific
            if isa(reporting, 'TDReportingWithCache')
                reporting.PushProgress;
            end
            
            [resampled_volume] = obj.CreatePointCloud(growth_volume);
            disp(['Number of seed points:' int2str(sum(resampled_volume.RawImage(:)))]);
            obj.AddApicesBelowThisBranch(starting_segment, resampled_volume, reporting);
            obj.Grow(resampled_volume);
            
            % ToDo: This is too specific
            if isa(reporting, 'TDReportingWithCache')
                reporting.PopProgress;
            end
        end        
    end
    
    methods (Access= private)
        
        function generation_number = GetMinimumTerminalGeneration(obj)
            generation_number = [];
            for apex = obj.Apices
                apex_generation = apex.AirwayGrowingTreeSegment.GenerationNumber;
                if isempty(generation_number)
                    generation_number = apex_generation;
                else
                    generation_number = min(generation_number, apex_generation);
                end
            end
        end
        
        function Grow(obj, lung_volume)
            obj.Reporting.ShowProgress('Growing branches');
            obj.Reporting.UpdateProgressValue(0);
            first_run = true;
            image_size = lung_volume.ImageSize;
            % Step through generations one by one
            while ~isempty(obj.Apices)
                generation_number = obj.GetMinimumTerminalGeneration;
                if generation_number >= obj.MaximumGenerationNumber
                    obj.Reporting.ShowMessage('TDAirwayGenerator:IncompleteApices', [num2str(length(obj.Apices)) ' branches were incomplete when the terminal generation was reached']);                    
                    return
                end
                obj.Reporting.UpdateProgressValue(round(100*generation_number/obj.MaximumGenerationNumber));

                % Allocate points to the apices
                if (first_run) || ((generation_number < obj.NumberOfGenerationsToReallocate) && (obj.ReallocatePointsAtEachGeneration))
                    obj.AssignInitialPointCloudToApices(lung_volume);
                    if (first_run)
                        obj.InitialApexImage = obj.GetImageFromApex(lung_volume);
                        first_run = false;
                    end
                end
                
                obj.Reporting.ShowMessage('TDAirwayGenerator:GenerationNumber', ['Generation:' int2str(generation_number)]);
                apices_to_do = TDAirwayGeneratorApex.empty(50000,0);
                for apex = obj.Apices
                    generation = apex.AirwayGrowingTreeSegment.GenerationNumber;
                    % If this is the right generation then grow the apex;
                    % otherwise add to the list to do
                    if (generation == generation_number)
                        [new_apex_1, new_apex_2] = obj.GrowApex(apex, lung_volume, generation_number, image_size);
                        if ~isempty(new_apex_1)
                            apices_to_do(end+1) = new_apex_1;
                        end
                        if ~isempty(new_apex_2)
                            apices_to_do(end+1) = new_apex_2;
                        end
                    else
                        apices_to_do(end+1) = apex;
                    end
                end
                obj.Apices = apices_to_do;
            end
        end
        
        function [resampled_volume] = CreatePointCloud(obj, growth_volume)
            resampled_volume = growth_volume.Copy;
            grid_spacing = [obj.GridSpacingMm, obj.GridSpacingMm, obj.GridSpacingMm];
            resampled_volume.Resample(grid_spacing, '*nearest')
        end
        
        function AddApicesBelowThisBranch(obj, centreline_branches, lung_volume, reporting)
            obj.Apices = [];
%             image_size = lung_volume.ImageSize;
            segments_to_do = [];
            for centreline_branch = centreline_branches
                branch = obj.AirwayTree.FindCentrelineBranch(centreline_branch, reporting);
                segments_to_do = [segments_to_do, branch];
            end
            while ~isempty(segments_to_do)
                segment = segments_to_do(end);
                segments_to_do(end) = [];
                children = segment.Children;
                segments_to_do = [segments_to_do, children];
                
                if isempty(children)
                    % Add apices for airway growing
%                     if obj.IsInsideVolume(segment.EndCoords, lung_volume, image_size)
                        new_apex = TDAirwayGeneratorApex(segment, TDPoints);
                        obj.Apices = [obj.Apices new_apex];
%                     else
%                          obj.Reporting.ShowWarning('TDAirwayGenerator:StartBranchesOutsideVolume', 'Airway growing start branches were outside of the volume', []);
%                     end
                end
            end
                
        end
        
        function AssignInitialPointCloudToApices(obj, resampled_volume)
            if numel(obj.Apices) == 0
               obj.Reporting.Error('TDAirwayGenerator:AssignInitialPointCloudToApices', 'No starting points');
                
            end
            sample_image = zeros(resampled_volume.ImageSize, 'uint16');
            for apex_number = 1 : numel(obj.Apices)
                apex = obj.Apices(apex_number);
                end_point_mm = apex.AirwayGrowingTreeSegment.EndCoords;
                end_point_global_coordinates = resampled_volume.CoordinatesMmToGlobalCoordinates(end_point_mm);
                end_point = resampled_volume.GlobalToLocalCoordinates(end_point_global_coordinates);
                current_value = sample_image(end_point(1), end_point(2), end_point(3));
                if current_value ~= 0
                    obj.Reporting.ShowWarning('TDAirwayGenerator:ApexAlreadyUsed', 'The start point for allocating voxels to apices could not be assigned as the point has already been used by another apex', []);
                end
                sample_image(end_point(1), end_point(2), end_point(3)) = apex_number;
            end
            
            bw_image = sample_image > 0;
            
            [~, IDX] = bwdist(bw_image);
            mapped_image = sample_image(IDX);
            mapped_image_masked = zeros(size(bw_image), 'uint16');
            point_indices = find(resampled_volume.RawImage);
            mapped_image_masked(point_indices) = mapped_image(point_indices);
            
            for apex_number = 1 : numel(obj.Apices)
                local_indices = find(mapped_image_masked == apex_number);
                global_indices =  resampled_volume.LocalToGlobalIndices(local_indices);
                [ic, jc, kc] = resampled_volume.GlobalIndicesToCoordinatesMm(global_indices);
                obj.Apices(apex_number).PointCloud.Coords = [ic, jc, kc];
            end
        end
        
        function [apex_1, apex_2] = GrowApex(obj, current_apex, lung_volume, generation, image_size)
            if isempty(current_apex.PointCloud.Coords)
                obj.Reporting.ShowWarning('TDAirwayGenerator:EmptyPointCloud', 'Branches terminated because they had an empty point cloud', []);
                apex_1 = [];
                apex_2 = [];
            elseif size(current_apex.PointCloud.Coords, 1) < 2
                obj.Reporting.ShowWarning('TDAirwayGenerator:TooFewPointsInCloud', 'Branches terminated because there was only one point in the point cloud', []);
                apex_1 = [];
                apex_2 = [];
            else
                
                % Find the end coordinates for this branch
                branch = current_apex.AirwayGrowingTreeSegment;
                branch_end_coords = branch.EndCoords;

                % Find the centre of mass for the point cloud assigned to this
                % apex
                centre_of_mass = obj.GetCentreOfMass(current_apex.PointCloud);
                
                % Create a vector from the end branch point to the centre of
                % mass
                vector_to_com = centre_of_mass - branch_end_coords;
                
                % Get a normalised vector perpendicular to the plane passing
                % through the centre of pass and the start and end points of the
                % branch
                plane_normal = obj.GetValidPlaneNormal(vector_to_com, branch);
                
                % Split the point cloud into two, creating a new apex for each if there are enough points
                [cloud1, cloud2] = obj.SplitPointCloud(current_apex.PointCloud, plane_normal, branch_end_coords);
                
                if isempty(cloud1.Coords) || isempty(cloud2.Coords)
                    obj.Reporting.ShowWarning('TDAirwayGenerator:EmptyPointCloud', 'Branches terminated because the point clouds could not be divided into two nonempty clouds', []);
                    apex_1 = [];
                    apex_2 = [];
                    return;
                end
                
                % Create new branches
                apex_1 = obj.AddBranchAndApex(branch, cloud1, lung_volume, generation, image_size);
                apex_2 = obj.AddBranchAndApex(branch, cloud2, lung_volume, generation, image_size);
            end
        end
        
        % Compute a normalised direction vector for a plane parallel to the
        % given vector and the direction of the given branch. If the two vectors
        % are parallel then the direction of the parent branch is used. If this
        % does not exist or is still parallel, then we choose a guaranteed
        % non-parallel vector using the null space.
        function plane_normal = GetValidPlaneNormal(obj, vector_to_com, branch)
            
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
        function [this_plane, other_plane] = SplitPointCloud(obj, point_cloud, normal, origin)
            points_coords = point_cloud.Coords;
            p = - dot(normal, origin);
            
            % Find which axis is most parallel to the plane
            [~, ordered_directions] = sort(normal, 'descend');
            main_direction = ordered_directions(1);
            other_directions = ordered_directions(2:3);
            plane_points = - (p + normal(other_directions(1))*points_coords(:, other_directions(1)) + normal(other_directions(2))*points_coords(:, other_directions(2)))/normal(main_direction);
            in_plane = points_coords(:, main_direction) < plane_points;
            this_plane = TDPoints(points_coords(in_plane, :));
            other_plane = TDPoints(points_coords(~in_plane, :));
        end
        
        function new_apex = AddBranchAndApex(obj, parent_branch, cloud, lung_volume, generation, image_size)
            new_apex = [];
            
            % Determine the centre of the point cloud
            centre_of_mass = obj.GetCentreOfMass(cloud);
            
            % The new branch starts at the end of the parent branch
            new_branch_start_point = parent_branch.EndCoords;
            
            % Fetch the director vector of the parent branch
            parent_direction = parent_branch.Direction;
            
            % Calculate the end point of the new branch. This is subject both to
            % a length limit and an angle limit.
            new_branch_end_point = obj.CheckBranchAngleLengthAndAdjust(new_branch_start_point, centre_of_mass, parent_direction);

            % Create the new branch in AirwayTree
            new_branch = TDAirwayGrowingTree(parent_branch);
            new_branch.StartCoords = new_branch_start_point;
            new_branch.EndCoords = new_branch_end_point;
            new_branch.IsGenerated = true;

            new_branch_length = norm(new_branch_end_point - new_branch_start_point);            

            % Find closest point in cloud and delete
            closest_point = FindClosestPointInCloud(obj, new_branch_end_point, cloud);
            closest_point_global_coords = lung_volume.CoordinatesMmToGlobalCoordinates(closest_point);
            lung_volume.SetVoxelToThis(closest_point_global_coords, 0);
            
            
            [~, matches] = ismember(cloud.Coords, closest_point, 'rows');
            index_closest_point = find(matches);
            
            % Check if the number of points in the cloud is less than the
            % required minimum
            if (size(cloud.Coords, 1) <= obj.PointLimitVoxels)
                obj.Reporting.ShowWarning('TDAirwayGenerator:BelowLengthThreshold', 'Branches terminated because the number of points was below the threshold', []);
            else
                if (new_branch_length < obj.LengthLimitMm)
                    obj.Reporting.ShowWarning('TDAirwayGenerator:BelowLengthThreshold', 'Branches terminated because their length was below the threshold', []);
                else
                    % Create new growth branch
                    new_apex = TDAirwayGeneratorApex(new_branch, cloud);
                end
            end            
        end
        
        function closest_point = FindClosestPointInCloud(obj, point, cloud)
            num_points_in_cloud = size(cloud.Coords, 1);
            distance = cloud.Coords - repmat(point, [num_points_in_cloud, 1]);
            distance = sqrt(distance(:,1).^2 + distance(:,2).^2 + distance(:,3).^2);
            [~, min_index] = min(distance, [], 1);
            closest_point = cloud.Coords(min_index, :);
        end
        
        function in_volume = IsInsideVolume(obj, point_mm, lung_volume, image_size)
            global_coordinates = floor(point_mm./lung_volume.VoxelSize);
            point = global_coordinates + [1, 1, 1] - lung_volume.Origin;
            
            x = point(1); y = point(2); z = point(3);
            if (x < 1) || (x > image_size(1)) || (y < 1) || (y > image_size(2)) || (z < 1) || (z > image_size(3))
                in_volume = false;
                return
            else
                in_volume = lung_volume.RawImage(x, y, z);
            end
        end

        % Checks the branch angle of a proposed growth centre and adjusts it within tolerance, if necessary
        function end_coords = CheckBranchAngleLengthAndAdjust(obj, start_coords, end_coords, parent_direction)
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
            if (branch_angle > obj.AngleLimitRadians)
                perpendicular_one = cross(new_direction, old_direction);
                perpendicular_one = perpendicular_one/norm(perpendicular_one);
                perpendicular_two = cross(old_direction, perpendicular_one);
                perpendicular_two = perpendicular_two/norm(perpendicular_two);
                old_direction = old_direction*cos(obj.AngleLimitRadians);
                perpendicular_two = perpendicular_two*sin(obj.AngleLimitRadians);
                new_direction = old_direction + perpendicular_two;
            end
            
            % Reduce the branch length as required
            branch_length = branch_length*obj.BranchingFraction;
            new_direction = new_direction * branch_length;
            
            % Update the centre
            end_coords = start_point + new_direction;
        end
        
        function new_image = GetImageFromApex(obj, template)
            new_image = zeros(template.ImageSize, 'uint16');
            colour = 1;
            for apex = obj.Apices
                cloud_points = apex.PointCloud.Coords;
                point_coord = template.CoordinatesMmToGlobalCoordinates(cloud_points);
                point_coord = template.GlobalToLocalCoordinates(point_coord);
                indices = sub2ind(template.ImageSize, point_coord(:,1), point_coord(:,2), point_coord(:,3)); 
                new_image(indices) = colour;
                colour = colour + 1;
            end
        end
        
        function airway_tree = GetAirwayTree(obj)
            airway_tree = obj.AirwayTree;
        end
        
        function centre = GetCentreOfMass(obj, point_cloud)
            cloud_points = point_cloud.Coords;
            centre = mean(cloud_points, 1);
        end
    
        function centreline_indices_local = CentrelinePointsToLocalIndices(obj, centreline_points, template_image)
            ic = [centreline_points.CoordI];
            jc = [centreline_points.CoordJ];
            kc = [centreline_points.CoordK];
            centreline_indices_global = sub2ind(template_image.OriginalImageSize, ic, jc, kc);
            centreline_indices_local = template_image.GlobalToLocalIndices(centreline_indices_global);
        end
        
        function RemoveSmallTerminatingAirways(obj, initial_airway_tree, length_limit, reporting)
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
                                obj.Reporting.ShowWarning('TDAirwayGenerator:SegmentedBranchesBelowLimit', 'Initial branches have been excluded due to their length being below the limit', []);
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
    end
end
