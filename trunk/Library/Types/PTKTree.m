classdef PTKTree < handle
    % PTKTree. A base class representing a tree structure
    %
    %     Each branch in a tree structure is represented by a PTKTree.
    %     Each branch references its parent and child branches; therefore it is
    %     possible to reconstruct the entire tree from a single branch.
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %       
    
    properties (SetAccess = protected)
        Parent = []    % Parent PTKTree
        Children = []  % Child PTKTree
    end
    
    methods
        function obj = PTKTree(parent)
            if nargin > 0
                obj.Parent = parent;
            end
        end
        
        
        function root = GetRoot(obj)
            root = obj;
            if numel(root) > 0
                root = root(1);
            end
            while ~isempty(root.Parent)
                root = root.Parent;
            end
        end
        
        % Remove this branch from the tree
        function CutFromTree(obj)
            if ~isempty(obj.Parent)
                obj.Parent.Children = setdiff(obj.Parent.Children, obj);
            end
        end
        
        % Remove this branch from the tree, connecting its children to its parent branch
        function CutAndSplice(obj)
            if ~isempty(obj.Parent)
                obj.Parent.Children = [setdiff(obj.Parent.Children, obj), obj.Children];
            end
        end

        % Remove all child branches from this branch
        function RemoveChildren(obj)
            obj.Children = [];
        end
        
        % Returns the number of branches in this tree, from this branch
        % downwards
        function number_of_branches = CountBranches(obj)
            number_of_branches = 0;
            branches_to_do = obj;
            while ~isempty(branches_to_do)
                branch = branches_to_do(end);
                branches_to_do(end) = [];
                branches_to_do = [branches_to_do, branch.Children];
                number_of_branches = number_of_branches + 1;
            end
        end

        % Returns true if this subtree contains the branch
        function contains_branch = ContainsBranch(obj, branch)
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
        
        % Returns the number of branches in this tree, from this branch
        % downwards
        function number_of_branches = CountTerminalBranches(obj)
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
        
        % Returns the number of branches in this tree, from this branch
        % downwards
        function minimum_generation = GetMinimumTerminalGeneration(obj)
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
        
        
        

        

        % Returns all the branches as a set, from this branch onwards
        function branches_list = GetBranchesAsList(obj)
            branches_list = obj;
            branches_to_do = obj.Children;

            while ~isempty(branches_to_do)
                branch = branches_to_do(end);
                branches_to_do(end) = [];
                branches_to_do = [branches_to_do, branch.Children];
                branches_list(end+1) = branch;
            end
        end

        % Returns all the branches as a set, with this branch first, then its
        % children, then its grandchildren, and so on.
        function branches_list = GetBranchesAsListByGeneration(obj)
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
        
        % Returns all the branches as a set, from this branch onwards
        % This is similar to GetBranchesAsList, but the branches are assembled
        % in a different order. This is simply to match the output produced by
        % other code
        function branches_list = GetBranchesAsListUsingRecursion(obj)
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

