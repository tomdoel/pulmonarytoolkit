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
    end
    
    methods (Access = protected)
        function AddChild(obj, child)
            obj.Children = [obj.Children, child];
        end
    end
end

