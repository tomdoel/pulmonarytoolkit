classdef PTKTree < handle
    % A base class representing a tree structure
    %
    % Each branch in a tree structure is represented by a PTKTree.
    % Each branch references its parent and child branches; therefore it is
    % possible to reconstruct the entire tree from a single branch.
    %
    % .. Licence
    %    -------
    %    Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %    Author: Tom Doel, 2012.  www.tomdoel.com
    %    Distributed under the GNU GPL v3 licence. Please see website for details.
    %       
    
    properties (SetAccess = protected)
        Parent = []    % Parent PTKTree
        Children = []  % Child PTKTree
    end
    
    methods
        function obj = PTKTree(parent)
            % Create an empty PTKTree segment with an optional parent segment

            if nargin > 0
                obj.Parent = parent;
            end
        end
        
        function root = GetRoot(obj)
            % Get the topmost branch from the tree containing this branch

            root = obj;
            if numel(root) > 0
                root = root(1);
            end
            while ~isempty(root.Parent)
                root = root.Parent;
            end
        end
        
        function CutFromTree(obj)
            % Remove this branch from the tree
            
            if ~isempty(obj.Parent)
                obj.Parent.Children = setdiff(obj.Parent.Children, obj);
            end
        end
        
        function CutAndSplice(obj)
            % Remove this branch from the tree, connecting its children to its parent branch
            
            if ~isempty(obj.Parent)
                obj.Parent.Children = [setdiff(obj.Parent.Children, obj), obj.Children];
            end
        end

        function RemoveChildren(obj)
            % Remove all child branches from this branch
            
            obj.Children = [];
        end
        
        function PruneDescendants(obj, num_generations_to_keep)
            % Keeps a given number of generations, and remove descendants of those
            
            if num_generations_to_keep <= 0
                obj.RemoveChildren()
            else
                for branch = obj.Children
                    branch.PruneDescendants(num_generations_to_keep - 1);
                end
            end
        end
        
        function number_of_branches = CountBranches(obj)
            % Return the number of branches in this tree, from this branch downwards

            number_of_branches = 0;
            branches_to_do = obj;
            while ~isempty(branches_to_do)
                branch = branches_to_do(end);
                branches_to_do(end) = [];
                branches_to_do = [branches_to_do, branch.Children];
                number_of_branches = number_of_branches + 1;
            end
        end

        function contains_branch = ContainsBranch(obj, branch)
            % Return true if this subtree contains the branch

            segments_to_do = obj;
            while ~isempty(segments_to_do)
                segment = segments_to_do(end);
                if (segment == branch)
                    contains_branch = true;
                    return;
                end
                segments_to_do(end) = [];
                children = segment.Children;
                segments_to_do = [segments_to_do, children];
            end
            contains_branch = false;
        end
        
        function number_of_branches = CountTerminalBranches(obj)
            % Return the number of branches in this tree, from this branch downwards

            number_of_branches = 0;
            branches_to_do = obj;
            while ~isempty(branches_to_do)
                branch = branches_to_do(end);
                branches_to_do(end) = [];
                branches_to_do = [branches_to_do, branch.Children];
                if isempty(branch.Children)
                    number_of_branches = number_of_branches + 1;
                end
            end
        end
        
        function minimum_generation = GetMinimumTerminalGeneration(obj)
            % Returns the number of branches in this tree, from this branch downwards

            minimum_generation = 99;
            branches_to_do = obj;
            while ~isempty(branches_to_do)
                branch = branches_to_do(end);
                branches_to_do(end) = [];
                branches_to_do = [branches_to_do, branch.Children];
                if isempty(branch.Children)
                    minimum_generation = min(minimum_generation, branch.GenerationNumber);
                end
            end
        end
        
        function branches_list = GetBranchesAsList(obj)
            % Return all the branches as a set, from this branch onwards
            branches_list = obj;
            branches_to_do = obj.Children;

            while ~isempty(branches_to_do)
                branch = branches_to_do(end);
                branches_to_do(end) = [];
                branches_to_do = [branches_to_do, branch.Children];
                branches_list(end+1) = branch;
            end
        end

        function branches_list = GetBranchesAsListByGeneration(obj)
            % Returns all the branches as a set, with this branch first, then its children, then its grandchildren, and so on.
            
            current_generation = obj;
            branches_list = current_generation.empty();
            
            while ~isempty(current_generation)
                next_generation = current_generation.empty();
                for branch = current_generation
                    branches_list(end+1) = branch;
                    next_generation(end+1:end+length(branch.Children)) = branch.Children;
                end
                current_generation = next_generation;
            end
        end
        
        function branches_list = GetBranchesAsListUsingRecursion(obj)
            % Returns all the branches as a set, from this branch onwards
            % This is similar to GetBranchesAsList, but the branches are assembled
            % in a different order. This is simply to match the output produced by
            % other code

            branches_list = obj;
            for child = obj.Children
                branches_list = [branches_list child.GetBranchesAsListUsingRecursion];
            end
        end
    end

    methods (Access = protected)
        function AddChild(obj, child)
            obj.Children = [obj.Children, child];
        end
    end
end

