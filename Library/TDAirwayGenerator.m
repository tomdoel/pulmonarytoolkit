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
    %             skeleton_tree,          % A TDModelTree produced from TDRadius
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
        AirwayTree
        LengthLimitMm = 1.2 % A branch is terminated if its length is less than this value. Tawhai et al 2004 use value 2.
        PointLimitVoxels = 4 % A branch is terminated if the point cloud of the apex has fewer points than this limit
        AngleLimitRadians % Maximum permitted branch angle in degrees
        BranchingFraction = 0.4 % The fraction a branch extends towards the centre of the point cloud. Value 0.4 from Tawhai et al., 2004
        ReallocatePointsAtEachGeneration = true % If true, points will be reassigned to apices at each generation up to the generation number set in NumberOfGenerationsToReallocate
        NumberOfGenerationsToReallocate = 10  % If ReallocatePointsAtEachGeneration is set to true, this is the number of generations for which points in the volume will be reallocated at each generation
        PointNumberMultiple = 8 % The desired numbe of grid points is obtained by multiplying approx_number_points by this value
        Reporting
        ApexImage
        GridSpacingMm
        
        Apices
        MaximumGenerationNumber = 25     % All branches of the output tree will terminate if they extend beyond this generation number
    end
    
    methods
        function obj = TDAirwayGenerator(lung_mask, skeleton_tree, approx_number_points, reporting)
            
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
            obj.AirwayTree = obj.CreateInitialTreeFromSegmentation(skeleton_tree, reporting);
        end
        
        function delete(~)
        end
        
        % Use CreateInitialTreeFromSegmentation to create an initial airway tree
        % from the airway skeleton results
        function airway_tree = CreateInitialTreeFromSegmentation(obj, segmented_centreline_tree, reporting)
            airway_tree = TDAirwayGrowingTree;
            airway_tree.SkeletonTreeSegment = segmented_centreline_tree;
            segments_to_do = airway_tree;
            while ~isempty(segments_to_do)
                segment = segments_to_do(end);
                segments_to_do(end) = [];
                
                % Get the first and last voxel coordinates from the segment of
                % the skeleton airway tree
                centreline_segment = segment.SkeletonTreeSegment;
                first_point = centreline_segment.Centreline(1);
                end_point = centreline_segment.Centreline(end);
                
                segment.StartCoords = [first_point.CoordI, first_point.CoordJ, first_point.CoordK];
                segment.EndCoords = [end_point.CoordI, end_point.CoordJ, end_point.CoordK];
                
                if isempty(centreline_segment.GenerationNumber)
                    error('program error');
                end
                
                if centreline_segment.GenerationNumber >= obj.MaximumGenerationNumber
                    obj.Reporting.ShowWarning('TDAirwayGenerator:SegmentedBranchesExcluded', 'Branches have been excluded due to the maximum generation parameter', []);
                else
                    
                    if ~isempty(centreline_segment.Children)
                        % Add a new branch to the tree for each child
                        for child = centreline_segment.Children
                            % Create a new segment
                            new_segment = TDAirwayGrowingTree(segment);
                            new_segment.SkeletonTreeSegment = child;
                            new_segment.IsGenerated = false;
                            segments_to_do = [segments_to_do, new_segment];
                        end
                    end
                end
                
            end            
        end
        
        % Starting from the initial airway tree generated from AddTree(),  
        function GrowTree(obj, growth_volume, starting_segment, reporting)
            [resampled_volume] = obj.CreatePointCloud(growth_volume);
            obj.AddApicesBelowThisBranch(starting_segment, resampled_volume, reporting);
            obj.Grow(resampled_volume);
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
                if (first_run)
                    obj.AssignInitialPointCloudToApices(lung_volume);
                    obj.ApexImage = obj.GetImageFromApex(lung_volume);
                end
                if generation_number >= obj.MaximumGenerationNumber
                    obj.Reporting.ShowMessage('TDAirwayGenerator:IncompleteApices', 'Branches were incomplete when the terminal generation was reached', []);                    
                    return
                end
                
                obj.Reporting.UpdateProgressValue(round(100*generation_number/obj.MaximumGenerationNumber));
                if (~first_run) && (generation_number < obj.NumberOfGenerationsToReallocate) && (obj.ReallocatePointsAtEachGeneration)
                    obj.AssignInitialPointCloudToApices(lung_volume);
                end
                if (first_run)
                    first_run = false;
                end
                
                obj.Reporting.ShowMessage('TDAirwayGenerator:GenerationNumber', ['Generation:' int2str(generation_number)]);
                apices_to_do = TDAirwayGeneratorApex.empty(100000,0);
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
        
        function AddApicesBelowThisBranch(obj, skeleton_branches, lung_volume, reporting)
            obj.Apices = [];
            image_size = lung_volume.ImageSize;
            segments_to_do = [];
            for skeleton_branch = skeleton_branches
                branch = obj.AirwayTree.FindSkeletonBranch(skeleton_branch, reporting);
                segments_to_do = [segments_to_do, branch];
            end
            while ~isempty(segments_to_do)
                segment = segments_to_do(end);
                segments_to_do(end) = [];
                children = segment.Children;
                segments_to_do = [segments_to_do, children];
                
                if isempty(children)
                    % Add apices for airway growing
                    if obj.IsInsideVolume(segment.EndCoords, lung_volume, image_size)
                        new_apex = TDAirwayGeneratorApex(segment, TDPoints);
                        obj.Apices = [obj.Apices new_apex];
                    else
                         obj.Reporting.ShowWarning('TDAirwayGenerator:StartBranchesOutsideVolume', 'Airway growing Start branches were outside of the volume', []);
                    end
                end
            end
                
        end
        
        function AssignInitialPointCloudToApices(obj, resampled_volume)
            if numel(obj.Apices) == 0
               obj.Reporting.Error('TDAirwayGenerator:AssignInitialPointCloudToApices', 'No starting points');
                
            end
            if numel(obj.Apices) > 255
               obj.Reporting.Error('TDAirwayGenerator:AssignInitialPointCloudToApices', 'TooManyStartingPoints');
            end
            sample_image = zeros(resampled_volume.ImageSize, 'uint8');
            for apex_number = 1 : numel(obj.Apices)
                apex = obj.Apices(apex_number);
                end_point_mm = apex.AirwayGrowingTreeSegment.EndCoords;
                end_point_global_coordinates = resampled_volume.CoordinatesMmToGlobalCoordinates(end_point_mm);
                end_point = resampled_volume.GlobalToLocalCoordinates(end_point_global_coordinates);
                current_value = sample_image(end_point(1), end_point(2), end_point(3));
                if current_value ~= 0
                    obj.Reporting.ShowWarning('TDAirwayGeerator:ApexAlreadyUsed', 'The start point for allocating voxels to apices could not be assigned as the poing has already been used by another apex', []);
                end
                sample_image(end_point(1), end_point(2), end_point(3)) = apex_number;
            end
            
            bw_image = sample_image > 0;
            
            [~, IDX] = bwdist(bw_image);
            mapped_image = sample_image(IDX);
            mapped_image_masked = zeros(size(bw_image), 'uint8');
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
            else

                % Find the start end end coordinates for this branch
                branch = current_apex.AirwayGrowingTreeSegment;
                end_coords = branch.EndCoords;
                
                % Compute a normalised direction vector
                branch_direction = branch.Direction;
                
                % determine normal to allow the point cloud to be split
                previous_direction = branch.Parent.Direction;
                normal = cross(previous_direction, branch_direction);
                normal = normal / norm(normal);
                
                % Split the point cloud into two, create a new apex if there are enough points
                [cloud1, cloud2] = obj.SplitPointCloud(current_apex.PointCloud, normal, end_coords);
                
                % Create new branches
                apex_1 = obj.AddBranchAndApex(branch, cloud1, lung_volume, generation, image_size);
                apex_2 = obj.AddBranchAndApex(branch, cloud2, lung_volume, generation, image_size);
            end
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
            end_coords = parent_branch.EndCoords;
            branch_direction = parent_branch.Direction;

            if (numel(cloud.Coords) >= obj.PointLimitVoxels)
                
                % Determine the centre of the point cloud
                centre = obj.GetCentreOfMass(cloud);
                centre = obj.CheckBranchAngleLengthAndAdjust(end_coords, branch_direction, centre);
                
                % If the modified centrepoint is the same as the end point then
                % we cannot add a point here
                if any(isnan((centre)))
                    obj.Stats.EmptyPointCloud = obj.Stats.EmptyPointCloud + 1;
                    return;
                end
                
                % If the branch point isn't inside the volume then terminate
                if ~obj.IsInsideVolume(centre, lung_volume, image_size)
                    obj.Reporting.ShowWarning('TDAirwayGenerator:BranchesOutsideVolume', 'Branches were terminated because they grew outside the lung volume', []);
                    return;
                end
                
                new_branch_length = norm(centre - end_coords);
                
                if (new_branch_length > 10) && (generation > 14)
                    disp('Large branch detected');
                end
                
                if (new_branch_length > obj.LengthLimitMm)
                    
                    % Create the new branch in AirwayTree
                    new_branch = TDAirwayGrowingTree(parent_branch);
                    new_branch.StartCoords = end_coords;
                    new_branch.EndCoords = centre;
                    new_branch.IsGenerated = true;
                    
                    % Create new growth branch
                    new_apex = TDAirwayGeneratorApex(new_branch, cloud);
                else
                    obj.Reporting.ShowWarning('TDAirwayGenerator:BelowLengthThreshold', 'Branches terminated because their length was below the threshold', []);
                end
            else
                obj.Reporting.ShowWarning('TDAirwayGenerator:BelowLengthThreshold', 'Branches terminated because the number of points was below the threshold', []);
            end
            
            % ToDo: reassign unused points
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
        function centre = CheckBranchAngleLengthAndAdjust(obj, start_coords, original_direction, centre)
            % calculate vector from apex start to the centre
            start_point = start_coords;
            new_direction = centre - start_point;
            
            % Record the branching length
            branch_length = norm(new_direction);
            
            new_direction = new_direction / norm(new_direction);
            
            old_direction = original_direction;
            old_direction = old_direction / norm(old_direction);
            
            % determine branch angle
            dot_product = dot(new_direction, original_direction);
            branch_angle = acos(dot_product/(norm(new_direction)*norm(original_direction)));

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
            centre = start_point + new_direction;
        end
        
        function new_image = GetImageFromApex(obj, template)
            new_image = zeros(template.ImageSize, 'uint8');
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
            centre = mean(cloud_points);
        end
    
        function centreline_indices_local = CentrelinePointsToLocalIndices(obj, centreline_points, template_image)
            ic = [centreline_points.CoordI];
            jc = [centreline_points.CoordJ];
            kc = [centreline_points.CoordK];
            centreline_indices_global = sub2ind(template_image.OriginalImageSize, ic, jc, kc);
            centreline_indices_local = template_image.GlobalToLocalIndices(centreline_indices_global);
        end
    end
end
