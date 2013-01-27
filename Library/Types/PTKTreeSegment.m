classdef PTKTreeSegment < PTKTree
    % PTKTreeSegment. A data structure representing a segmented airway tree 
    %
    %     A root PTKTreeSegment is returned by 
    %     PTKAirwayRegionGrowingWithExplosionControl. From this you
    %     can extract and analyse the resulting airway tree.
    %
    %     PTKTreeSegment is used in the construction and storage of
    %     the airway trees. A PTKTreeSegment stores an individual
    %     segment of the centreline tree, with references to the parent and child
    %     PTKTreeSegments, so that it is possible to reconstruct the entire
    %     tree from a single segment.
    %
    %     The way the airway voxels are stored in each segment is as follows:
    %         The wavefront only exists during the region growing. It is a thick
    %         layer of voxels which exists at the end of each segment
    %         which is currently growing. If the wavefront forms more than one
    %         connected component, the segment is ended and new child segments
    %         formed from the wavefront components. When new voxels are added to
    %         the front of the wavefront, old voxels from the back of the
    %         wavefront are pushed out into the Pending voxels of the segment.
    %         Pending voxels are 'accepted' or 'rejected' according to whether
    %         the heuristics have determined an explosion has occurred.
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %       
    
    properties
        Colour         % A colourmap index allocated to this branch
    end
    
    properties (SetAccess = private)
        % Generation of this segment, starting at 1
        GenerationNumber

        % Indicates if this branch was terminated due to the generation number
        % being too high, which may indicate leakage
        ExceededMaximumNumberOfGenerations = false
        
        MarkedExplosion = false
        
    end

        
    properties (Access = private)

        % List of accepted (i.e. non-exploded) voxels
        AcceptedVoxelIndices
        
        % List of rejected (exploded) voxels        
        RejectedVoxelIndices        
        
        % Indices are allocated to the segment from the back of the wavefront
        % They are pending until the explosion control heuristic has determined
        % they are 'Accepted' or 'Exploded'.
        PendingVoxelIndices

        % Additional voxels that were not originally part of the segment but 
        % were added later after a morphological closing operation
        ClosedPoints

        PreviousMinimumVoxels
        NumberOfVoxelsSkipped = 0
        LastNumberOfVoxels = 0
                
        PermittedVoxelSkips = 0
        IsFirstSegment
        
        
        % We never use less than this value at each step when computing the minimum wavefront
        % size over the image
        MinimumNumberOfPointsThreshold


        ExplosionMultiplier
        
        
    end
    
    methods
        function obj = PTKTreeSegment(parent, min_number_of_points_threshold, explosion_multiplier)
            if nargin > 0
                obj.Parent = parent;
                obj.MarkedExplosion = false;
                obj.PendingVoxelIndices = int32([]);
                obj.AcceptedVoxelIndices = int32([]);
                obj.RejectedVoxelIndices = int32([]);
                
                obj.ExplosionMultiplier = explosion_multiplier;
                obj.MinimumNumberOfPointsThreshold = min_number_of_points_threshold;
                
                if ~isempty(parent)
                    parent.AddChild(obj);                    
                    obj.PreviousMinimumVoxels = parent.PreviousMinimumVoxels;
                    obj.LastNumberOfVoxels = obj.PreviousMinimumVoxels;
                    obj.IsFirstSegment = false;
                    obj.GenerationNumber = parent.GenerationNumber + 1;
                else
                    obj.PreviousMinimumVoxels = 1000;
                    obj.LastNumberOfVoxels = obj.PreviousMinimumVoxels;
                    obj.IsFirstSegment = true;
                    obj.GenerationNumber = 1;
                end
            end
        end
        
        % Returns a list of voxels which have been accepted as not explosions.
        function accepted_voxels = GetAcceptedVoxels(obj)
            accepted_voxels = obj.ConcatenateVoxels(obj.AcceptedVoxelIndices);
        end
        
        % Returns the wavefront for this segment, which includes voxels that may
        % be separated into child segments
        function rejected_voxels = GetRejectedVoxels(obj)
            rejected_voxels = obj.ConcatenateVoxels(obj.RejectedVoxelIndices);
        end

        function endpoints = GetEndpoints(obj)
            endpoints = obj.AcceptedVoxelIndices{end};
        end

        % Returns all accepted region-growing points, plus those added from the airway closing operation
        function all_points = GetAllAirwayPoints(obj)
            all_points = [obj.GetAcceptedVoxels'; obj.ClosedPoints'];
        end
        
        % Points which are added later to close gaps in the airway tree
        function AddClosedPoints(obj, new_points)
            obj.ClosedPoints = [obj.ClosedPoints, new_points];
        end

        function RecomputeGenerations(obj, new_generation_number)
            obj.GenerationNumber = new_generation_number;
            children = obj.Children;
            for child = children
                child.RecomputeGenerations(new_generation_number + 1);
            end
        end
        
        function AddColourValues(obj, new_colour_value)
            obj.Colour = new_colour_value;
            children = obj.Children;
            for child = children
                new_colour_value = new_colour_value + 1;
                if mod(new_colour_value, 7) == 0
                    new_colour_value = new_colour_value + 1;
                end
                child.AddColourValues(new_colour_value);
            end
        end
        
        function AddPendingVoxels(obj, indices_of_new_points)
            
            obj.PendingVoxelIndices{end + 1} = indices_of_new_points;
            
            if obj.MarkedExplosion
                obj.RejectAllPendingVoxelIndices;
            end
            
            number_of_points = numel(indices_of_new_points);
            
            if (number_of_points < obj.PreviousMinimumVoxels) && (~obj.IsFirstSegment)
                obj.PreviousMinimumVoxels = max(number_of_points, obj.MinimumNumberOfPointsThreshold);
            end
            
            if (number_of_points < obj.ExplosionMultiplier*obj.PreviousMinimumVoxels)
                obj.NumberOfVoxelsSkipped = 0;
            else
                obj.NumberOfVoxelsSkipped = obj.NumberOfVoxelsSkipped + 1;
            end
            
            % Keep track of the point at which an explosion starts to occur
            if (number_of_points <= obj.LastNumberOfVoxels)
                obj.AcceptAllPendingVoxelIndices;
            end
            
            % Explosion control: we allow a certain number of consecutive
            % points to exceed the expansion limit.
            % Once exceeded, this segment is not permitted to expand further, and it is also marked so that it can be
            % deleted later.
            if (obj.NumberOfVoxelsSkipped > obj.PermittedVoxelSkips)
                obj.MarkedExplosion = true;
                obj.RejectAllPendingVoxelIndices;
            end
        end
        
        function EarlyTerminateBranch(obj)
            obj.CompleteThisSegment;
            if ~obj.MarkedExplosion
                obj.ExceededMaximumNumberOfGenerations = true;
            end
        end
        
        function CompleteThisSegment(obj)
            if obj.MarkedExplosion
                obj.RejectAllPendingVoxelIndices;
            else
                obj.AcceptAllPendingVoxelIndices;
            end
        end
        
        function MergeWithChild(obj)
            if (length(obj.Children) ~= 1)
                error('MergeWithChild should only be called if there is one child segment');
            end
            child = obj.Children(1);
            if ~isempty(child.PendingVoxelIndices)
                error('Programming error: MergeWithParent should not be called while a segment is in progress');
            end
            grandchildren = child.Children;
            obj.Children = [setdiff(obj.Children, child), grandchildren];
            for grandchild = obj.Children
                grandchild.Parent = obj;
                grandchild.RecomputeGenerations(obj.GenerationNumber + 1);
            end
            while ~isempty(child.AcceptedVoxelIndices)
                obj.AcceptedVoxelIndices{end + 1} = child.AcceptedVoxelIndices{1};
                child.AcceptedVoxelIndices(1) = [];
            end
            while ~isempty(child.RejectedVoxelIndices)
                obj.RejectedVoxelIndices{end + 1} = child.RejectedVoxelIndices{1};
                child.RejectedVoxelIndices(1) = [];
            end
            
        end
        
        
    end
        
    methods (Access = private)
        function AcceptAllPendingVoxelIndices(obj)
            while ~isempty(obj.PendingVoxelIndices)
                obj.AcceptedVoxelIndices{end + 1} = obj.PendingVoxelIndices{1};
                obj.PendingVoxelIndices(1) = [];
            end
        end
        
        function RejectAllPendingVoxelIndices(obj)
            while ~isempty(obj.PendingVoxelIndices)
                obj.RejectedVoxelIndices{end + 1} = obj.PendingVoxelIndices{1};
                obj.PendingVoxelIndices(1) = [];
            end
        end        
    end
    
    methods (Static, Access = private)
        function concatenated_voxels = ConcatenateVoxels(voxels)
            concatenated_voxels = [];
            number_layers = length(voxels);
            for index = 1 : number_layers
                next_voxels = voxels{index};
                if ~isempty(next_voxels)
                    concatenated_voxels = cat(2, concatenated_voxels, next_voxels);
                end
            end
        end
    end
    
end

