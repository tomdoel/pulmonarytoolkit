classdef TDTreeSegment < handle
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
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %       
    
    properties
        Parent = []    % Parent TDTreeSegment
        Children = []  % Child TDTreeSegments
        Colour         % A colourmap index allocated to this branch
    end
    
    properties (SetAccess = private)

        % List of accepted (i.e. non-exploded) voxels
        AcceptedIndicesOK
    
        % Generation of this segment, starting at 1
        GenerationNumber

        % The wavefront is a thick layer of voxels which is used to detect 
        % and process bifurcations in the airway tree before these voxels are
        % added to the segement's list of pending indices
        WavefrontIndices
        
        % Indicates if this branch was terminated due to the generation number
        % being too high, which may indicate leakage
        ExceededMaximumNumberOfGenerations = false
    end

        
    properties (Access = private)
        
        % Additional voxels that were not originally part of the segment but 
        % were added later after a morphological closing operation
        ClosedPoints
        
        % Indices are allocated to the segment from the back of the wavefront
        % They are pending until the explosion control heuristic has determined
        % they are 'Accepted' or 'Exploded'.
        PendingIndices

        % List of rejected (exploded) voxels        
        AcceptedIndicesExplosion
        
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
        MaximumNumberOfGenerations = 15
        
        
        % We never use less than this value at each step when computing the minimum wavefront
        % size over the image
        MinimumNumberOfPointsThreshold

        MinimumNumberOfPointsThresholdMm3 = 6

        ExplosionMultiplier = 7
        
        TemporaryIndex

        MarkedExplosion = false
        
    end
    
    methods
        function obj = TDTreeSegment(parent, min_distance_before_bifurcating_mm, voxel_size_mm)
            if nargin > 0
                obj.Parent = parent;
                obj.Children = {};
                obj.MarkedExplosion = false;
                obj.WavefrontIndices = int32([]);
                obj.PendingIndices = int32([]);
                obj.AcceptedIndicesOK = int32([]);
                obj.AcceptedIndicesExplosion = int32([]);

                obj.MinimumDistanceBeforeBifurcatingMm = min_distance_before_bifurcating_mm;
                max_voxel_size_mm = max(voxel_size_mm);
                obj.VoxelSizeMm = voxel_size_mm;
                voxel_volume = voxel_size_mm(1)*voxel_size_mm(2)*voxel_size_mm(3);
                obj.MinimumNumberOfPointsThreshold = max(3, round(obj.MinimumNumberOfPointsThresholdMm3/voxel_volume));
                
                if ~isempty(parent)
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
            accepted_voxels = [];
            for index = 1 : length(obj.AcceptedIndicesOK)
                if ~isempty(obj.AcceptedIndicesOK{index})
                    accepted_voxels = cat(2, accepted_voxels, obj.AcceptedIndicesOK{index});
                end
            end
            accepted_voxels = accepted_voxels';
        end
        
        % Returns the wavefront for this segment, which includes voxels that may
        % be separated into child segments
        function exploded_voxels = GetExplodedVoxels(obj)
            exploded_voxels = [];
            for index = 1 : numel(obj.AcceptedIndicesExplosion)
                next_exploded_voxels = obj.AcceptedIndicesExplosion{index};
                if ~isempty(next_exploded_voxels)
                    exploded_voxels = cat(2, exploded_voxels, next_exploded_voxels);
                end
            end
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
                        
            % Add the new voxels to the wavefront of this segment
            obj.AddNewVoxelsToWavefront(indices_of_new_points);
            
            % If an explostion has been detected then do not continue
            if obj.MarkedExplosion
                obj.AddAllWaverfrontVoxelsToPendingVoxels;
                segments_to_do = {}; % This segment has been terminated
                return                
            end
            
            obj.AdjustMaxAndMinForVoxels(indices_of_new_points, image_size);
            
            % Do not allow the segment to bifurcate until it is above a minimum
            % length
            if ~obj.MinimumLengthPassed
                segments_to_do = {obj}; % This segment is to continue growing
                return
            end

            % Do not allow the segment to bifurcate until it is above a minimum size
            if ~obj.WavefrontIsMinimumSize
                segments_to_do = {obj}; % This segment is to continue growing
                return
            end
                        
            % Determine whether to continue growing the current segment, or to 
            % split it into a new set of child segments
            segments_to_do = obj.DivideWavefrontIntoSegments(image_size);
            
        end
        
        % Returns the very front layer of voxels at the wavefront
        function frontmost_points = GetFrontmostPoints(obj)
            frontmost_points = obj.WavefrontIndices{end}; 
        end
        
        function CompleteThisSegment(obj)
            obj.AddAllWaverfrontVoxelsToPendingVoxels;
            obj.AcceptAllPendingIndices
        end
        
        function number_of_segments = CountSegments(obj)
            number_of_segments = 0;
            
            segments_to_do = obj;
            while ~isempty(segments_to_do)
                segment = segments_to_do(end);
                segments_to_do(end) = [];
                segments_to_do = [segments_to_do, segment.Children];
                
                number_of_segments = number_of_segments + 1;
            end
        end
        
        function AddClosedPoints(obj, new_points)
            obj.ClosedPoints = [obj.ClosedPoints, new_points];
        end
        
        % Returns all accepted region-growing points, plus those added from the airway closing operation
        function all_points = GetAllAirwayPoints(obj)
            all_points = [obj.GetAcceptedVoxels; obj.ClosedPoints];
                
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
        
        % Returns the wavefront for this segment, which includes voxels that may
        % be separated into child segments
        function wavefront_voxels = GetWavefrontVoxels(obj)
            wavefront_voxels = [];
            for index = 1 : length(obj.WavefrontIndices)
                next_wavefront_voxels = obj.WavefrontIndices{index};
                if ~isempty(next_wavefront_voxels)
                    wavefront_voxels = cat(2, wavefront_voxels, next_wavefront_voxels);
                end
            end
        end
        
        
        function AddNewVoxelsToWavefront(obj, indices_of_new_points)
            obj.AddRearOfWavefrontVoxelsToSegment;
            obj.WavefrontIndices{end + 1} = indices_of_new_points;
        end

        function AddAllWaverfrontVoxelsToPendingVoxels(obj)
            while ~isempty(obj.WavefrontIndices)
                
                % The wavefront may be empty after voxels have been divided
                % amongst child branches
                if ~isempty(obj.WavefrontIndices{1})
                    obj.AddPendingVoxels(obj.WavefrontIndices{1});
                end
                obj.WavefrontIndices(1) = [];
            end
        end
        
        function AcceptAllPendingIndices(obj)
            while ~isempty(obj.PendingIndices)
                obj.AcceptedIndicesOK{end + 1} = obj.PendingIndices{1};
                obj.PendingIndices(1) = [];
            end
        end
        
        function RejectAllPendingIndices(obj)
            while ~isempty(obj.PendingIndices)
                obj.AcceptedIndicesExplosion{end + 1} = obj.PendingIndices{1};
                obj.PendingIndices(1) = [];
            end
        end
        
        function is_minimum_size = WavefrontIsMinimumSize(obj)
            is_minimum_size = (length(obj.WavefrontIndices) >= obj.WavefrontSize);
        end
        
        function passed_minimum_lengths = MinimumLengthPassed(obj)
            lengths = obj.MaxCoords - obj.MinCoords;
            lengths = single(lengths).*obj.VoxelSizeMm;
            max_length = max(lengths);
            
            passed_minimum_lengths = max_length >= obj.MinimumDistanceBeforeBifurcatingMm;
        end
        
        function segments_to_do = DivideWavefrontIntoSegments(obj, image_size)
            points_by_branches = [];
            
            % Find connected components from the wavefront over several
            % generations
            [wavefront_connected_components, offset, size_im] = obj.GetConnectedComponentsOfThickWavefront(image_size);
            
            % Iterate over the components
            for component_number = 1 : wavefront_connected_components.NumObjects
                % Get voxel list, and adjust the indices to match those for the full image
                indices_of_component_points = wavefront_connected_components.PixelIdxList{component_number};
                indices_of_component_points = TDImageCoordinateUtilities.OffsetIndices(int32(indices_of_component_points), offset, size_im, image_size);
                points_by_branches{component_number} = indices_of_component_points;
            end
            
            % Separate the wavefront voxels of the current segment into a new
            % segment for each branch
            segments_to_do = obj.DivideWavefrontPointsIntoBranches(points_by_branches);
        end
        
        function [CC, offset, reduced_image_size] = GetConnectedComponentsOfThickWavefront(obj, original_image_size)
            thick_wavefront = obj.GetWavefrontVoxels;
            [offset, reduced_image, reduced_image_size] = TDImageCoordinateUtilities.GetMinimalImageForIndices(int32(thick_wavefront), original_image_size);
            
            CC = bwconncomp(reduced_image, 26);
        end
        

        function segments_to_do = DivideWavefrontPointsIntoBranches(obj, points_by_branches)
            segments_to_do = [];
            
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
                segments_to_do = {obj};
                return
            end
            
            if length(growing_branches) > 1
                
                % If the maximum permitted number of generations is exceeded
                % then terminate this segment
                if obj.GenerationNumber >= obj.MaximumNumberOfGenerations
                    obj.ExceededMaximumNumberOfGenerations = true;
                    obj.CompleteThisSegment;
                    return;
                end
                
                for index = 1 : length(growing_branches)
                    segments_to_do{end + 1} = obj.SpawnChildFromWavefrontVoxels(points_by_branches{growing_branches(index)});
                end
                
                % If the branch has divided, there may be some unaccepted points
                % left over
                obj.CompleteThisSegment;
            end
        end

        function new_segment = SpawnChildFromWavefrontVoxels(obj, voxel_indices)
            wavefront_voxels = [];
            for index = 1 : length(obj.WavefrontIndices)
                wavefront_voxels{index} = intersect(int32(voxel_indices), obj.WavefrontIndices{index});
                obj.WavefrontIndices{index} = setxor(wavefront_voxels{index}, obj.WavefrontIndices{index});
            end
            new_segment = TDTreeSegment(obj, obj.MinimumChildDistanceBeforeBifurcatingMm, obj.VoxelSizeMm);
            obj.AddChild(new_segment);
            new_segment.WavefrontIndices = wavefront_voxels;
        end

        function still_growing = IsThisComponentStillGrowing(obj, voxel_indices)
            wavefront_voxels_end = intersect(int32(voxel_indices), obj.WavefrontIndices{end});
            still_growing = ~isempty(wavefront_voxels_end);            
        end
        
        
        function AddPendingVoxels(obj, indices_of_new_points)

            obj.PendingIndices{end + 1} = indices_of_new_points;

            if obj.MarkedExplosion
                obj.RejectAllPendingIndices;
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
                obj.AcceptAllPendingIndices;
            end

            % Explosion control: we allow a certain number of consecutive
            % points to exceed the expansion limit.
            % Once exceeded, this segment is not permitted to expand further, and it is also marked so that it can be
            % deleted later.
            if (obj.NumberOfVoxelsSkipped > obj.PermittedVoxelSkips)
                obj.MarkedExplosion = true;
                obj.RejectAllPendingIndices;
            end
            
        end

        function AddRearOfWavefrontVoxelsToSegment(obj)
            if ~isempty(obj.WavefrontIndices)
                while length(obj.WavefrontIndices) > obj.WavefrontSize
                    obj.AddPendingVoxels(obj.WavefrontIndices{1});
                    obj.WavefrontIndices(1) = [];
                end
            end
        end

        function AddChild(obj, child)
            obj.Children = [obj.Children, child];
        end
        
    end
end

