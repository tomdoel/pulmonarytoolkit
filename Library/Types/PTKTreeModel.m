classdef PTKTreeModel < PTKTree
    % PTKTreeModel. A branch of a tree model (used to store airways, vessels
    % etc.)
    %
    % A PTKTreeModel is a tree structure which represents an airway centreline
    % with radius information. As such, it is a "model" of an airway, rather
    % than a "segmentation"
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %           
    
    properties
        StartPoint % PTKCentrelinePoint, mm
        EndPoint   % mm
        Radius     % mm
        WallThickness % mm
        TemporaryIndex
        
        Centreline
        SmoothedCentreline
        Density = -99
        
        LobeIndex
        SegmentIndex
        
        BranchProperties
        
        BronchusIndex % Used in the manual correction of airways labelling by lobe
    end
    
    properties (SetAccess = protected)
        GenerationNumber % Generation of this segment, starting at 1
    end
    
    methods
        function obj = PTKTreeModel(parent)
            obj.Centreline = PTKCentrelinePoint.empty(0);
            obj.SmoothedCentreline = PTKCentrelinePoint.empty(0);
            obj.GenerationNumber = 1;
            if nargin > 0
                obj.Parent = parent;
                parent.AddChild(obj);
                obj.GenerationNumber = parent.GenerationNumber + 1;
            end
        end
        
        function SetParent(obj, parent)
            obj.Parent = parent;
            parent.AddChild(obj);
        end
        
        function RemoveMultipleBifurcations(obj)
            branches_to_do = obj;
            while ~isempty(branches_to_do)
                branch = branches_to_do(end);
                branches_to_do(end) = [];
                branch.SplitChildBranchesIntoBifurcations;
                branches_to_do = [branches_to_do, branch.Children];
            end
        end
        
        function SplitChildBranchesIntoBifurcations(obj)
            while numel(obj.Children) > 2
                children = obj.Children;
                
                child_lobe_numbers = CoreContainerUtilities.GetMatrixOfPropertyValues(children, 'LobeIndex', -1);
                
                largest_child = [];
                
                % Find the child branch which is not one of the most common indices
                child_lobe_numbers_reduced = child_lobe_numbers(child_lobe_numbers > 0);                
                if ~isempty(child_lobe_numbers_reduced)
                    most_common_lobe_number = mode(child_lobe_numbers_reduced);
                    children_not_with_most_common_number = children(child_lobe_numbers ~= most_common_lobe_number);
                    if (numel(children_not_with_most_common_number) > 0) && (numel(children_not_with_most_common_number) < (numel(children) - 1))
                        largest_child = children(find(children_not_with_most_common_number, 1));
                    end
                end
                    
                if isempty(largest_child)
                    child_radius = [children.Radius];
                    [~, sorted_indices] = sort(child_radius, 'descend');
                    largest_child = children(sorted_indices(1));
                    second_largest_child = children(sorted_indices(2));
                    other_children = setdiff(children, largest_child);
                else
                    other_children = setdiff(children. largest_child);
                    child_radius = [other_children.Radius];
                    [~, sorted_indices] = sort(child_radius, 'descend');
                    second_largest_child = children(sorted_indices(1));
                end
                
                % Remove all other branches except the largest
                obj.Children = largest_child;
                
                % Create a new branch and add as a child of the current branch
                new_branch = PTKTreeModel(obj);
                
                % Add the other child branches to the new branch
                for child = other_children
                    new_branch.AddChild(child);
                end
                
                % Set parameters for new branch
                new_branch.StartPoint = obj.EndPoint;
                new_branch.EndPoint = obj.EndPoint;
                new_branch.Radius = second_largest_child.Radius;
                new_branch.WallThickness = second_largest_child.Radius;
                
                new_branch.Centreline = obj.Centreline(end);
                new_branch.SmoothedCentreline = obj.Centreline(end);
                new_branch.Density = second_largest_child.Density;
                
                other_child_segment_indices = CoreContainerUtilities.GetMatrixOfPropertyValues(other_children, 'SegmentIndex', -1);
                
                
                if all(other_child_segment_indices == other_child_segment_indices(1))
                    new_branch.SegmentIndex = second_largest_child.SegmentIndex;
                end
                
                other_child_lobe_indices = CoreContainerUtilities.GetMatrixOfPropertyValues(other_children, 'LobeIndex', -1);
                if all(other_child_lobe_indices == other_child_lobe_indices(1))
                    new_branch.LobeIndex = second_largest_child.LobeIndex;
                end
                
                
                new_branch.BranchProperties = second_largest_child.BranchProperties;
            end
            
        end

        % Returns the number of branches in this tree, from this branch
        % downwards
        function number_of_points = CountPointsInTree(obj)
            number_of_points = 0;            
            branches_to_do = obj;
            while ~isempty(branches_to_do)
                branch = branches_to_do(end);
                branches_to_do(end) = [];
                branches_to_do = [branches_to_do, branch.Children];
                number_of_points = number_of_points + numel(branch.Centreline);
            end
        end
        
        % Returns the number of branches in this tree, from this branch
        % downwards
        function number_of_points = CountSmoothedCentrelinePointsInTree(obj)
            number_of_points = 0;            
            branches_to_do = obj;
            while ~isempty(branches_to_do)
                branch = branches_to_do(end);
                branches_to_do(end) = [];
                branches_to_do = [branches_to_do, branch.Children];
                number_of_points = number_of_points + numel(branch.SmoothedCentreline);
            end
        end
        
        % Makes a deep copy of the tree
        function copy = Copy(obj)
            
            % Create a copy of this branch
            copy = PTKTreeModel;
            
            % Copy properties, except for Children and Parent
            metaclass = ?PTKTreeModel;
            property_list = metaclass.Properties;
            for i = 1 : length(property_list);
                property = property_list{i};
                if (~strcmp(property.Name, 'Parent') && (~strcmp(property.Name, 'Children')))
                    copy.(property.Name) = obj.(property.Name);
                end
            end
            
            % Create copies of child branches and set the Children and Parent
            % properties correctly
            for child = obj.Children
                child_copy = child.Copy;
                child_copy.Parent = copy;
                copy.Children = [copy.Children child_copy];
            end
        end
        
        function CreateFromSkeletonTreeBranch(obj, skeleton_tree, image_template)
            radius = skeleton_tree.Radius;
            obj.WallThickness = skeleton_tree.WallThickness;
            local_indices = skeleton_tree.Points;
            global_indices = image_template.LocalToGlobalIndices(local_indices);
            for point = global_indices
                ptk_coordinates = image_template.GlobalIndicesToPTKCoordinates(point);
                properties = [];
                properties.Radius = radius;
                new_point = PTKCentrelinePoint(ptk_coordinates(1), ptk_coordinates(2), ptk_coordinates(3), properties);
                obj.Centreline(end+1) = new_point;
            end
            obj.StartPoint = obj.Centreline(1);
            obj.EndPoint = obj.Centreline(end);
            obj.Radius = radius;
            
            % Create copies of child branches and set the Children and Parent
            % properties correctly
            for child = skeleton_tree.Children
                child_branch = PTKTreeModel(obj);
                child_branch.CreateFromSkeletonTreeBranch(child, image_template);
            end
        end
        
        function SimpleCopyBranch(obj, tree)
            obj.Radius = tree.Radius;
            obj.BranchProperties.SourceBranch = tree;
            obj.WallThickness = tree.WallThickness;
            
            % Create copies of child branches and set the Children and Parent
            % properties correctly
            for child = tree.Children
                child_branch = PTKTreeModel(obj);
                child_branch.SimpleCopyBranch(child);
            end
        end
        
        function tree_points = GetCentrelineTree(obj)
            tree_points = obj.Centreline;
            for child_segment = obj.Children
                tree_points = [tree_points, child_segment.GetCentrelineTree]; %#ok<AGROW>
            end
        end
        
        function GenerateSmoothedCentreline(obj)
            centreline = obj.Centreline;
            x_coords = [centreline.CoordX];
            y_coords = [centreline.CoordY];
            z_coords = [centreline.CoordZ];
            cp = [centreline.Parameters];
            radius_values = [cp.Radius];
            if ~isempty(obj.Parent)
                x_coords = [obj.Parent.Centreline(end).CoordX(end), x_coords];
                y_coords = [obj.Parent.Centreline(end).CoordY(end), y_coords];
                z_coords = [obj.Parent.Centreline(end).CoordZ(end), z_coords];
                radius_values = [obj.Parent.Centreline(end).Parameters.Radius(end), radius_values];
            end
            
            point_spacing_mm = 5;
            desired_number_of_points = ceil(obj.LengthMm/(3*point_spacing_mm));
            desired_number_of_points = max(2, desired_number_of_points);
            num_points = numel(x_coords);
            range = round(linspace(1, num_points, desired_number_of_points));
            
            x_coords_reduced = x_coords(range);
            y_coords_reduced = y_coords(range);
            z_coords_reduced = z_coords(range);
            
            knot = [x_coords_reduced', y_coords_reduced', z_coords_reduced'];
            
            % Generate a spline curve through the centreline points
            spline = MimImageCoordinateUtilities.CreateSplineCurve(knot, 2);

            number_of_original_points = size(radius_values, 2);
            number_of_spline_points = size(spline, 2);
            interpolated_indices = round(linspace(1, number_of_original_points, number_of_spline_points));
            
            radius_values = radius_values(interpolated_indices);
            
            % Store smoothed centreline
            obj.SmoothedCentreline = PTKCentrelinePoint.empty;
            for smoothed_point_index = 1 : number_of_spline_points
                properties = [];
                properties.Radius = radius_values(smoothed_point_index);
                obj.SmoothedCentreline(smoothed_point_index) = PTKCentrelinePoint(spline(1, smoothed_point_index), spline(2, smoothed_point_index), spline(3, smoothed_point_index), properties);
            end
            
            % Remove bifurcation point
            if ~isempty(obj.Parent)
                obj.SmoothedCentreline(1) = [];
            end
        end
        
        function GenerateBranchParameters(obj)
            if ~isempty(obj.Centreline)
                obj.StartPoint = obj.Centreline(1);
                obj.EndPoint = obj.Centreline(end);
                
                number_centreline_points = numel(obj.Centreline);
                quarter_radius = round(number_centreline_points/4);
                radius_start = 1 + quarter_radius;
                radius_end = number_centreline_points - quarter_radius;
                radius_start = max(1, radius_start);
                radius_start = min(number_centreline_points, radius_start);
                radius_end = max(1, radius_end);
                radius_end = min(number_centreline_points, radius_end);
                radius_start = min(radius_start, radius_end);
                radius_end = max(radius_end, radius_start);
                
                radius_points = obj.Centreline(radius_start : radius_end);
                number_radius_points = numel(radius_points);
                radius_sum = 0;
                for radius_point = radius_points
                    radius_sum = radius_sum + radius_point.Parameters.Radius;
                end
                obj.Radius = radius_sum/number_radius_points;
            end
            for child = obj.Children
                child.GenerateBranchParameters;
            end
        end
        
        % LengthMm computes the segment length based on the start and end
        % voxels. This method works for arrays.
        function length_mm = LengthMm(obj)
            start_points = [obj.StartPoint];
            end_points = [obj.EndPoint];
            coord_start = [[start_points.CoordX]; [end_points.CoordY]; [start_points.CoordZ]];
            coord_end = [[end_points.CoordX]; [end_points.CoordY]; [end_points.CoordZ]];
            
            length_mm = sqrt(sum((coord_start - coord_end).^2, 1));
        end
        
        % This function exists for compatibility with PTKAirwayGrowingTree
        function branch = FindCentrelineBranch(obj, branch_to_find, reporting)
            segments_to_do = obj;
            while ~isempty(segments_to_do)
                segment = segments_to_do(end);
                if (segment == branch_to_find)
                    branch = segment;
                    return;
                end
                segments_to_do(end) = [];
                children = segment.Children;
                segments_to_do = [segments_to_do, children];
            end
            reporting.Error('FindCentrelineBranch', 'Branch not found');
        end
    
        % ToDo: This method is duplicated in PTKAirwayGrowingTree
        % Returns the coordinates of each terminal branch in the tree below this
        % branch
        function terminal_coords = GetTerminalCoordinates(obj, reporting)
            num_branches = obj.CountBranches;
            num_terminal_branches = obj.CountTerminalBranches;
            
            reporting.UpdateProgressMessage('Finding terminal coordinates');
            
            branches_to_do = obj;
            
            all_starts = zeros(num_branches, 3);
            all_ends = zeros(num_branches, 3);
            terminal_coords = zeros(num_terminal_branches, 3);
            terminal_index = 1;
            index = 1;
            
            while ~isempty(branches_to_do)
                branch = branches_to_do(end);
                branches_to_do(end) = [];
                children = branch.Children;
                if ~isempty(children)
                    branches_to_do = [branches_to_do, children];
                else
                    terminal_coords(terminal_index, :) =  [branch.EndPoint.CoordX, branch.EndPoint.CoordY, branch.EndPoint.CoordZ];
                    terminal_index = terminal_index + 1;
                end
                
                parent = branch.Parent;
                
                if isempty(parent)
                    start_point_mm = [branch.StartPoint.CoordX, branch.StartPoint.CoordY, branch.StartPoint.CoordZ];
                else
                    start_point_mm = [parent.EndPoint.CoordX, parent.EndPoint.CoordY, parent.EndPoint.CoordZ];
                end
                end_point_mm = [branch.EndPoint.CoordX, branch.EndPoint.CoordY, branch.EndPoint.CoordZ];
                if isnan(end_point_mm)
                    reporting.Error('PTKAirwayGrowingTree:Nan', 'NaN found in branch coordinate');
                end
                
                all_starts(index, :) = start_point_mm;
                all_ends(index, :) = end_point_mm;
                
                index = index + 1;
            end
            
            if terminal_index ~= num_terminal_branches + 1
                reporting.Error('PTKAirwayGrowingTree:TerminalBranchCountMismatch', 'A code error occurred: the termina branch count was not as expected');
            end
            
            %     all_local_indices = GetAirwayModelAsLocalIndices(all_starts, all_ends);
            
        end
        
        % Returns the number of branches in this tree, from this branch
        % and excluding generations above the max_generation_number
        function number_of_branches = CountBranchesUpToGeneration(obj, max_generation_number)
            number_of_branches = 0;
            if obj.GenerationNumber > max_generation_number
                return;
            else
                branches_to_do = obj;
                while ~isempty(branches_to_do)
                    branch = branches_to_do(end);
                    branches_to_do(end) = [];
                    if branch.GenerationNumber <= max_generation_number
                        branches_to_do = [branches_to_do, branch.Children];
                        number_of_branches = number_of_branches + 1;
                    end
                end
            end
        end
    end
    
    methods (Static)
        function new_tree = CreateFromSkeletonTree(skeleton_tree, image_template)
            new_tree = PTKTreeModel;
            new_tree.CreateFromSkeletonTreeBranch(skeleton_tree, image_template);
        end
        
        % Creates a copy of the tree, but only copies the radius property, but
        % also maintains a reference to the branch that was copied
        function new_tree = SimpleTreeCopy(tree)
            new_tree = PTKTreeModel;
            new_tree.SimpleCopyBranch(tree);
        end
        
    end
    
end

