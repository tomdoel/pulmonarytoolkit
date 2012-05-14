classdef TDTreeSegment < TDTree
    % TDTreeSegment. A data structure representing a segmented airway tree 
    %
    %     A root TDTreeSegment is returned by 
    %     TDAirwayRegionGrowingWithExplosionControl. From this you
    %     can extract and analyse the resulting airway tree.
    %
    %     TDTreeSegment is used in the construction and storage of
    %     the airway trees. A TDTreeSegment stores an individual
    %     segment of the skeleton tree, with references to the parent and child
    %     TDTreeSegments, so that it is possible to reconstruct the entire
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
    end

        
    properties (Access = private)

        % List of accepted (i.e. non-exploded) voxels
        AcceptedVoxelIndices
        
        % List of rejected (exploded) voxels        
        RejectedVoxelIndices        
    
        % The wavefront is a thick layer of voxels which is used to detect 
        % and process bifurcations in the airway tree before these voxels are
        % added to the segement's list of pending indices
        WavefrontVoxelIndices
        
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
                
        WavefrontSize
        PermittedVoxelSkips = 0
        IsFirstSegment
        
        MinimumDistanceBeforeBifurcatingMm
        MinimumChildDistanceBeforeBifurcatingMm = 5
        
        FirstSegmentWavefrontSizeMm = 10
        ChildWavefrontSizeMm = 5
        VoxelSizeMm
        MinCoords
        MaxCoords
        
        % Generations greater than this are automatically terminated
        MaximumNumberOfGenerations
        
        % We never use less than this value at each step when computing the minimum wavefront
        % size over the image
        MinimumNumberOfPointsThreshold

        MinimumNumberOfPointsThresholdMm3 = 6

        ExplosionMultiplier = 7
        
        TemporaryIndex

        MarkedExplosion = false
        
    end
    
    methods
        function obj = TDTreeSegment(parent, min_distance_before_bifurcating_mm, voxel_size_mm, maximum_generations, explosion_multiplier)
            if nargin > 0
                obj.Parent = parent;
                obj.MarkedExplosion = false;
                obj.WavefrontVoxelIndices = int32([]);
                obj.PendingVoxelIndices = int32([]);
                obj.AcceptedVoxelIndices = int32([]);
                obj.RejectedVoxelIndices = int32([]);

                obj.MinimumDistanceBeforeBifurcatingMm = min_distance_before_bifurcating_mm;
                max_voxel_size_mm = max(voxel_size_mm);
                obj.VoxelSizeMm = voxel_size_mm;
                obj.MaximumNumberOfGenerations = maximum_generations;
                obj.ExplosionMultiplier = explosion_multiplier;
                voxel_volume = voxel_size_mm(1)*voxel_size_mm(2)*voxel_size_mm(3);
                obj.MinimumNumberOfPointsThreshold = max(3, round(obj.MinimumNumberOfPointsThresholdMm3/voxel_volume));
                
                if ~isempty(parent)
                    parent.AddChild(obj);                    
                    obj.PreviousMinimumVoxels = parent.PreviousMinimumVoxels;
                    obj.LastNumberOfVoxels = obj.PreviousMinimumVoxels;
                    obj.IsFirstSegment = false;
                    obj.WavefrontSize = ceil(obj.ChildWavefrontSizeMm/max_voxel_size_mm);
                    obj.GenerationNumber = parent.GenerationNumber + 1;
                else
                    obj.PreviousMinimumVoxels = 1000;
                    obj.LastNumberOfVoxels = obj.PreviousMinimumVoxels;
                    obj.IsFirstSegment = true;
                    obj.WavefrontSize = ceil(obj.FirstSegmentWavefrontSizeMm/max_voxel_size_mm);
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
        
        % Returns the very front layer of voxels at the wavefront
        function frontmost_points = GetFrontmostWavefrontVoxels(obj)
            frontmost_points = obj.WavefrontVoxelIndices{end}; 
        end
        
        % Returns the wavefront for this segment, which includes voxels that may
        % be separated into child segments
        function wavefront_voxels = GetWavefrontVoxels(obj)
            wavefront_voxels = obj.ConcatenateVoxels(obj.WavefrontVoxelIndices);
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

        % Add new voxels to this segment, and returns a list of all segments
        % that require further processing (including this one, and any child
        % segments which have been created as a result of bifurcations)
        function segments_to_do = AddNewVoxelsAndGetNewSegments(obj, indices_of_new_points, image_size)
            
            if (numel(indices_of_new_points) ~= numel(unique(indices_of_new_points)))
                error('duplicates');
            end
            
            if any(ismember(indices_of_new_points, obj.GetAcceptedVoxels))
                error('duplicates');
            end
                        
            % First we move voxels at the rear of the wavefront into the
            % PendingVoxels
            if ~isempty(obj.WavefrontVoxelIndices)
                while length(obj.WavefrontVoxelIndices) > obj.WavefrontSize
                    obj.MoveVoxelsFromRearOfWavefrontToPendingVoxels;
                end
            end
            
            % Next add the new points to the front of the wavefront
            obj.WavefrontVoxelIndices{end + 1} = indices_of_new_points;            

            
            % If an explostion has been detected then do not continue
            if obj.MarkedExplosion
                obj.MoveAllWaverfrontVoxelsToPendingVoxels;
                segments_to_do = TDTreeSegment.empty; % This segment has been terminated
                return                
            end
            
            obj.AdjustMaxAndMinForVoxels(indices_of_new_points, image_size);
            
            % Do not allow the segment to bifurcate until it is above a minimum
            % length
            if ~obj.MinimumLengthPassed
                segments_to_do = obj; % This segment is to continue growing
                return
            end

            % Do not allow the segment to bifurcate until it is above a minimum size
            if ~obj.WavefrontIsMinimumSize
                segments_to_do = obj; % This segment is to continue growing
                return
            end
                        
            % Determine whether to continue growing the current segment, or to 
            % split it into a new set of child segments
            segments_to_do = obj.DivideWavefrontIntoSegments(image_size);
            
        end
        
        
        function CompleteThisSegment(obj)
            obj.MoveAllWaverfrontVoxelsToPendingVoxels;
            obj.AcceptAllPendingVoxelIndices
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
    end
        
    methods (Access = private)
        
        function MoveAllWaverfrontVoxelsToPendingVoxels(obj)
            while ~isempty(obj.WavefrontVoxelIndices)                
                obj.MoveVoxelsFromRearOfWavefrontToPendingVoxels;
            end
        end
        
        function MoveVoxelsFromRearOfWavefrontToPendingVoxels(obj)
            % The wavefront may be empty after voxels have been divided
            % amongst child branches
            if ~isempty(obj.WavefrontVoxelIndices{1})
                obj.AddPendingVoxels(obj.WavefrontVoxelIndices{1});
            end
            obj.WavefrontVoxelIndices(1) = [];
        end

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

        function AdjustMaxAndMinForVoxels(obj, voxel_indices, image_size)
            [x, y, z] = ind2sub(image_size, voxel_indices);
            mins = [min(x), min(y), min(z)];
            maxs = [max(x), max(y), max(z)];
            if isempty(obj.MinCoords)
                obj.MinCoords = mins;
                obj.MaxCoords = maxs;
            else
                obj.MinCoords = min(mins, obj.MinCoords);
                obj.MaxCoords = max(maxs, obj.MaxCoords);
            end
        end

        function is_minimum_size = WavefrontIsMinimumSize(obj)
            is_minimum_size = (length(obj.WavefrontVoxelIndices) >= obj.WavefrontSize);
        end
        
        function passed_minimum_lengths = MinimumLengthPassed(obj)
            lengths = obj.MaxCoords - obj.MinCoords;
            lengths = single(lengths).*obj.VoxelSizeMm;
            max_length = max(lengths);
            
            passed_minimum_lengths = max_length >= obj.MinimumDistanceBeforeBifurcatingMm;
        end
        
        function segments_to_do = DivideWavefrontIntoSegments(obj, image_size)
            points_by_branches = [];
            
            % Find connected components from the wavefront (which is several voxels thick)
            [offset, reduced_image, reduced_image_size] = TDImageCoordinateUtilities.GetMinimalImageForIndices(int32(obj.GetWavefrontVoxels), image_size);
            wavefront_connected_components = bwconncomp(reduced_image, 26);

            % Iterate over the components
            for component_number = 1 : wavefront_connected_components.NumObjects
                % Get voxel list, and adjust the indices to match those for the full image
                indices_of_component_points = wavefront_connected_components.PixelIdxList{component_number};
                indices_of_component_points = TDImageCoordinateUtilities.OffsetIndices(int32(indices_of_component_points), offset, reduced_image_size, image_size);
                points_by_branches{component_number} = indices_of_component_points;
            end
            
            % Separate the wavefront voxels of the current segment into a new
            % segment for each branch
            segments_to_do = obj.DivideWavefrontPointsIntoBranches(points_by_branches);
        end
        
        function segments_to_do = DivideWavefrontPointsIntoBranches(obj, points_by_branches)
            segments_to_do = TDTreeSegment.empty;
            
            if length(points_by_branches) == 1
                % If there is only one component, it will be growing, so we 
                % shortcut to reduce overhead from the
                % IsThisComponentStillGrowing() function call
                growing_branches = 1;
            else
                growing_branches = [];
                for index = 1 : length(points_by_branches)
                    still_growing = obj.IsThisComponentStillGrowing(points_by_branches{index});
                    if (still_growing)
                        growing_branches(end + 1) = index;
                    end
                end
            end
            
            if length(growing_branches) < 1
                error('No growing branches - program error');
            end
            
            if length(growing_branches) == 1
                segments_to_do = obj;
                return
            end
            
            if length(growing_branches) > 1
                
                if ~isempty(obj.MaximumNumberOfGenerations)
                    % If the maximum permitted number of generations is exceeded
                    % then terminate this segment
                    if obj.GenerationNumber >= obj.MaximumNumberOfGenerations
                        obj.ExceededMaximumNumberOfGenerations = true;
                        obj.CompleteThisSegment;
                        return;
                    end
                end
                
                for index = 1 : length(growing_branches)
                    segments_to_do(end + 1) = obj.SpawnChildFromWavefrontVoxels(points_by_branches{growing_branches(index)});
                end
                
                % If the branch has divided, there may be some unaccepted points
                % left over
                obj.CompleteThisSegment;
            end
        end

        function new_segment = SpawnChildFromWavefrontVoxels(obj, voxel_indices)
            wavefront_voxels = [];
            for index = 1 : length(obj.WavefrontVoxelIndices)
                wavefront_voxels{index} = intersect(int32(voxel_indices), obj.WavefrontVoxelIndices{index});
                obj.WavefrontVoxelIndices{index} = setxor(wavefront_voxels{index}, obj.WavefrontVoxelIndices{index});
            end
            new_segment = TDTreeSegment(obj, obj.MinimumChildDistanceBeforeBifurcatingMm, obj.VoxelSizeMm, obj.MaximumNumberOfGenerations, obj.ExplosionMultiplier);
            new_segment.WavefrontVoxelIndices = wavefront_voxels;
        end

        function still_growing = IsThisComponentStillGrowing(obj, voxel_indices)
            wavefront_voxels_end = intersect(int32(voxel_indices), obj.WavefrontVoxelIndices{end});
            still_growing = ~isempty(wavefront_voxels_end);            
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

