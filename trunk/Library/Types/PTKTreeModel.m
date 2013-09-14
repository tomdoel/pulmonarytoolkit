classdef PTKTreeModel < PTKTree
    % PTKTreeModel. A branch of a tree model (used to store airways, vessels
    % etc.)
    %
    % A PTKTreeModel is s tree structure which represents an airway centreline
    % with radius information. As such, it is a "model" of an airway, rather
    % than a "segmentation"
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
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
                child_radius = [children.Radius];
                [~, sorted_indices] = sort(child_radius, 'descend');
                largest_child = children(sorted_indices(1));
                second_largest_chid = children(sorted_indices(2));
                
                other_children = children(sorted_indices(2:end));
                
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
                new_branch.Radius = second_largest_chid.Radius;
                new_branch.WallThickness = second_largest_chid.Radius;
                
                new_branch.Centreline = obj.Centreline(end);
                new_branch.SmoothedCentreline = obj.Centreline(end);
                new_branch.Density = second_largest_chid.Density;
                
                new_branch.LobeIndex = second_largest_chid.LobeIndex;
                new_branch.SegmentIndex = second_largest_chid.LobeIndex;
                
                new_branch.BranchProperties = second_largest_chid.BranchProperties;
                
                
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
                [c_i, c_j, c_k] = image_template.GlobalIndicesToCoordinatesMm(point);
                new_point = PTKCentrelinePoint(c_i, c_j, c_k, radius, point);
                obj.Centreline(end+1) = new_point;
            end
            
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
            x_coords = [centreline.CoordJ];
            y_coords = [centreline.CoordI];
            z_coords = [centreline.CoordK];
            radius_values = [centreline.Radius];
            global_index = [centreline.GlobalIndex];
            if ~isempty(obj.Parent)
                x_coords = [obj.Parent.Centreline(end).CoordJ(end), x_coords];
                y_coords = [obj.Parent.Centreline(end).CoordI(end), y_coords];
                z_coords = [obj.Parent.Centreline(end).CoordK(end), z_coords];
                radius_values = [obj.Parent.Centreline(end).Radius(end), radius_values];
                global_index = [obj.Parent.Centreline(end).GlobalIndex(end), global_index];
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
            spline = PTKImageCoordinateUtilities.CreateSplineCurve(knot, 2);

            number_of_original_points = size(radius_values, 2);
            number_of_spline_points = size(spline, 2);
            interpolated_indices = round(linspace(1, number_of_original_points, number_of_spline_points));
            
            radius_values = radius_values(interpolated_indices);
            global_index = global_index(interpolated_indices);
            
            % Store smoothed centreline
            obj.SmoothedCentreline = PTKCentrelinePoint.empty;
            for smoothed_point_index = 1 : number_of_spline_points
                obj.SmoothedCentreline(smoothed_point_index) = PTKCentrelinePoint(spline(2, smoothed_point_index), spline(1, smoothed_point_index), spline(3, smoothed_point_index), radius_values(smoothed_point_index), global_index(smoothed_point_index));
            end
            
            % Remove bifurcation point
            if ~isempty(obj.Parent)
                obj.SmoothedCentreline(1) = [];
            end
        end
        
        function GenerateBranchParameters(obj)
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
                radius_sum = radius_sum + radius_point.Radius;    
            end
            obj.Radius = radius_sum/number_radius_points;
            
            for child = obj.Children
                child.GenerateBranchParameters;  
            end
        end
        
        % LengthMm computes the segment length based on the start and end
        % voxels. This method works for arrays.
        function length_mm = LengthMm(obj)
            start_points = [obj.StartPoint];
            end_points = [obj.EndPoint];
            coord_start = [[start_points.CoordI]; [end_points.CoordJ]; [start_points.CoordK]];
            coord_end = [[end_points.CoordI]; [end_points.CoordJ]; [end_points.CoordK]];
            
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
                    terminal_coords(terminal_index, :) =  [branch.EndPoint.CoordI, branch.EndPoint.CoordJ, branch.EndPoint.CoordK];
                    terminal_index = terminal_index + 1;
                end
                
                parent = branch.Parent;
                
                if isempty(parent)
                    start_point_mm = [branch.StartPoint.CoordI, branch.StartPoint.CoordJ, branch.StartPoint.CoordK];
                else
                    start_point_mm = [parent.EndPoint.CoordI, parent.EndPoint.CoordJ, parent.EndPoint.CoordK];
                end
                end_point_mm = [branch.EndPoint.CoordI, branch.EndPoint.CoordJ, branch.EndPoint.CoordK];
                if isnan(end_point_mm)
                    reporting.Error('PTKGrowingTreeBySegment:Nan', 'NaN found in branch coordinate');
                end
                
                all_starts(index, :) = start_point_mm;
                all_ends(index, :) = end_point_mm;
                
                index = index + 1;
            end
            
            if terminal_index ~= num_terminal_branches + 1
                reporting.Error('PTKGrowingTreeBySegment:TerminalBranchCountMismatch', 'A code error occurred: the termina branch count was not as expected');
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

