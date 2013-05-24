classdef PTKSkeletonSegment < PTKTree
    % PTKSkeletonSegment. A data structure representing an airway tree skeleton
    %
    %     A root PTKSkeletonSegment is returned by PTKSkeletonise. From this you
    %     can extract and analyse the resulting airway skeleton tree.
    %
    %     PTKSkeletonSegment is used in the construction and storage of
    %     skeletonised airway trees. A PTKSkeletonSegment stores an individual
    %     segment of the skeleton tree, with references to the parent and child
    %     PTKSkeletonSegments, so that it is possible to reconstruct the entire
    %     tree from a single segment.
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %       
    
    properties (SetAccess = private)
        NextPoint % The next point to start processing from - will be empty once the skeleton is complete
        Points    % The skeleton points in this segment
        GenerationNumber % Generation of this segment, starting at 1
    end
    
    % ToDo: Radius property should be removed; instead create a PTKTreeModel as
    % part of the airway radius computation
    properties
        Radius    % This will be set by the PTKAirwayRadius plugin
        WallThickness    % This will be set by the PTKAirwayRadius plugin
    end
    
    methods
        function obj = PTKSkeletonSegment(start_point, parent)
            obj.GenerationNumber = 1;
            if nargin > 0
                obj.NextPoint = start_point;
                if nargin > 1
                    obj.Parent = parent;
                    obj.Parent.AddChild(obj);
                    obj.GenerationNumber = obj.Parent.GenerationNumber + 1;
                end
            end
        end
        
        function AddPoint(obj, new_point_localindex)
            obj.Points(end + 1) = new_point_localindex;
        end
        
        function CompleteSegment(obj)
            obj.NextPoint = [];
        end
        
        function new_child = SpawnChild(obj, child_start_point)
            new_child = PTKSkeletonSegment(child_start_point, obj);
        end
        
        function DeleteThisSegment(obj)
            if ~isempty(obj.Parent)
                obj.Parent.RemoveChild(obj);
                obj.Parent = [];
            end
        end
        
        function siblings = GetSiblings(obj)
            if isempty(obj.Parent)
                siblings = [];
            else
                siblings = obj.Parent.Children;
            end
        end
        
        function incomplete_segments = GetIncompleteSegments(obj)
            if isempty(obj.NextPoint)
                incomplete_segments = [];
            else
                incomplete_segments = obj;
            end
            for child_segment = obj.Children
                incomplete_segments = [incomplete_segments, child_segment.GetIncompleteSegments]; %#ok<AGROW>
            end
        end
        
        function tree_points = GetTree(obj)
            tree_points = obj.Points;
            for child_segment = obj.Children
                tree_points = [tree_points, child_segment.GetTree]; %#ok<AGROW>
            end
        end
        
        function RecomputeGenerations(obj, new_generation_number)
            obj.GenerationNumber = new_generation_number;
            children = obj.Children;
            for child = children
                child.RecomputeGenerations(new_generation_number + 1);
            end
        end
        
    end
    
    methods (Access = private)
        
        function RemoveChild(obj, child_segment)
            for child_index = 1 : length(obj.Children)
                if (obj.Children(child_index) == child_segment)
                    obj.Children(child_index) = [];
                    break;
                end
            end
            if (length(obj.Children) == 1)
                obj.MergeWithChild;
            end
        end
                
        function MergeWithChild(obj)
            if (length(obj.Children) ~= 1)
                error('MergeWithChild should only be called if there is one child segment');
            end
            child = obj.Children(1);
            obj.Children = child.Children;
            for grandchild = obj.Children
                grandchild.Parent = obj;
            end
            obj.Points = [obj.Points, child.Points];
            obj.NextPoint = child.NextPoint;
        end
        
    end
end