classdef TDTreeModel < TDTree
    % TDTreeModel. A branch of a tree model (used to store airways, vessels
    % etc.)
    %
    % A TDTreeModel is s tree structure which represents an airway centreline
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
        StartPoint % TDCentrelinePoint, mm
        EndPoint   % mm
        Radius     % mm
        TemporaryIndex
        
        Centreline
        Density = -99
        
        BranchProperties
    end
    
    properties (SetAccess = protected)
        GenerationNumber % Generation of this segment, starting at 1
    end
    
    methods
        function obj = TDTreeModel(parent)
            obj.Centreline = TDCentrelinePoint.empty(0);
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
        
        % Makes a deep copy of the tree
        function copy = Copy(obj)
            
            % Create a copy of this branch
            copy = TDTreeModel;
            
            % Copy properties, except for Children and Parent
            metaclass = ?TDTreeModel;
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
            local_indices = skeleton_tree.Points;
            global_indices = image_template.LocalToGlobalIndices(local_indices);
            for point = global_indices
                [c_i, c_j, c_k] = ind2sub(image_template.OriginalImageSize, point);
                c_i = (c_i - 0.5)*image_template.VoxelSize(1);
                c_j = (c_j - 0.5)*image_template.VoxelSize(2);
                c_k = (c_k - 0.5)*image_template.VoxelSize(3);
                new_point = TDCentrelinePoint(c_i, c_j, c_k, radius, point);
                obj.Centreline(end+1) = new_point;
            end
            
            % Create copies of child branches and set the Children and Parent
            % properties correctly
            for child = skeleton_tree.Children
                child_branch = TDTreeModel(obj);
                child_branch.CreateFromSkeletonTreeBranch(child, image_template);
            end
        end
        
        function SimpleCopyBranch(obj, tree)
            obj.Radius = tree.Radius;
            obj.BranchProperties.SourceBranch = tree;
            
            % Create copies of child branches and set the Children and Parent
            % properties correctly
            for child = tree.Children
                child_branch = TDTreeModel(obj);
                child_branch.SimpleCopyBranch(child);
            end
        end
        
        function tree_points = GetCentrelineTree(obj)
            tree_points = obj.Centreline;
            for child_segment = obj.Children
                tree_points = [tree_points, child_segment.GetCentrelineTree]; %#ok<AGROW>
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
        
        function length_mm = LengthMm
            coord_start = [obj.StartPoint.CoordI, obj.StartPoint.CoordJ, obj.StartPoint.CoordK];
            coord_end = [obj.EndPoint.CoordI, obj.EndPoint.CoordJ, obj.EndPoint.CoordK];
            length_mm = norm(coord_start - coord_end, 2);            
        end
        
        % This function exists for compatibility with TDAirwayGrowingTree
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
    
        % ToDo: This method is duplicated in TDAirwayGrowingTree
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
                    reporting.Error('TDGrowingTreeBySegment:Nan', 'NaN found in branch coordinate');
                end
                
                all_starts(index, :) = start_point_mm;
                all_ends(index, :) = end_point_mm;
                
                index = index + 1;
            end
            
            if terminal_index ~= num_terminal_branches + 1
                reporting.Error('TDGrowingTreeBySegment:TerminalBranchCountMismatch', 'A code error occurred: the termina branch count was not as expected');
            end
            
            %     all_local_indices = GetAirwayModelAsLocalIndices(all_starts, all_ends);
            
        end

    end
    
    methods (Static)
        function new_tree = CreateFromSkeletonTree(skeleton_tree, image_template)
            new_tree = TDTreeModel;
            new_tree.CreateFromSkeletonTreeBranch(skeleton_tree, image_template);
        end
        
        % Creates a copy of the tree, but only copies the radius property, but
        % also maintains a reference to the branch that was copied
        function new_tree = SimpleTreeCopy(tree)
            new_tree = TDTreeModel;
            new_tree.SimpleCopyBranch(tree);
        end
        
    end
    
end

