classdef TDTree < handle
    % TDTree. A base class representing a tree structure
    %
    %     Each branch in a tree structure is represented by a TDTree.
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
        Parent = []    % Parent TDTree
        Children = []  % Child TDTree
    end
    
    methods
        function obj = TDTree(parent)
            if nargin > 0
                obj.Parent = parent;
            end
        end
        
        % Remove this branch from the tree, connecting its children to its parent branch 
        function CutFromTree(obj)
            if ~isempty(obj.Parent)
                obj.Parent.Children = [setdiff(obj.Parent.Children, obj), obj.Children];
            end
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

        % Returns all the branches as a set, from this branch onwards
        function branches_list = GetBranchesAsList(obj)
            branches_list = obj;

            branches_to_do = obj;
            while ~isempty(branches_to_do)
                branch = branches_to_do(end);
                branches_to_do(end) = [];
                branches_to_do = [branches_to_do, branch.Children];
                branches_list = [branches_list, branch.Children];
            end
        end

        % Returns all the branches as a set, from this branch onwards
        % This is similar to GetBranchesAsList, but the branches are assembled
        % in a different order. This is simply to match the output produced by
        % other code
        function branches_list = GetBranchesAsListUsingRecursion(obj)
            branches_list = obj;
            for child = obj.Children
                branches_list = [branches_list child.  GetBranchesAsListUsingRecursion];
            end
        end
    end

    methods (Access = protected)
        function AddChild(obj, child)
            obj.Children = [obj.Children, child];
        end
    end
end

