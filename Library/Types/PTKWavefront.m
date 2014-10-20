classdef PTKWavefront < handle
    % PTKWavefront. A data structure representing a segmented airway tree 
    %
    %     PTKWavefront is used as part of the airway region growing process in 
    %     PTKAirwayRegionGrowingWithExplosionControl.
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
        
    properties (SetAccess = private)
        CurrentBranch = []
    end
        
    properties (Access = private)
    
        % The wavefront is a thick layer of voxels which is used to detect 
        % and process bifurcations in the airway tree before these voxels are
        % added to the segement's list of pending indices
        WavefrontVoxelIndices

        % Additional voxels that were not originally part of the segment but 
        % were added later after a morphological closing operation
        ClosedPoints

        NumberOfVoxelsSkipped = 0
                
        WavefrontSize
        PermittedVoxelSkips = 0
        
        MinimumDistanceBeforeBifurcatingMm
        MinimumChildDistanceBeforeBifurcatingMm = 5
        
        FirstSegmentWavefrontSizeMm = 10
        ChildWavefrontSizeMm = 5
        VoxelSizeMm
        MinCoords
        MaxCoords
        
        % Generations greater than this are automatically terminated
        MaximumNumberOfGenerations

        MinimumNumberOfPointsThresholdMm3 = 6

        ExplosionMultiplier = 7
        
    end
    
    methods
        function obj = PTKWavefront(segment_parent, min_distance_before_bifurcating_mm, voxel_size_mm, maximum_generations, explosion_multiplier)
            if nargin > 0
                obj.WavefrontVoxelIndices = int32([]);

                obj.MinimumDistanceBeforeBifurcatingMm = min_distance_before_bifurcating_mm;
                max_voxel_size_mm = max(voxel_size_mm);
                obj.VoxelSizeMm = voxel_size_mm;
                obj.MaximumNumberOfGenerations = maximum_generations;
                obj.ExplosionMultiplier = explosion_multiplier;
                
                voxel_volume = voxel_size_mm(1)*voxel_size_mm(2)*voxel_size_mm(3);
                min_number_of_points_threshold = max(3, round(obj.MinimumNumberOfPointsThresholdMm3/voxel_volume));

                if ~isempty(segment_parent)
                    obj.WavefrontSize = ceil(obj.ChildWavefrontSizeMm/max_voxel_size_mm);
                    obj.CurrentBranch = PTKTreeSegment(segment_parent, min_number_of_points_threshold, explosion_multiplier);
                else
                    obj.WavefrontSize = ceil(obj.FirstSegmentWavefrontSizeMm/max_voxel_size_mm);
                    obj.CurrentBranch = PTKTreeSegment([], min_number_of_points_threshold, explosion_multiplier);
                end
            end
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

        % Add new voxels to this segment, and returns a list of all segments
        % that require further processing (including this one, and any child
        % segments which have been created as a result of bifurcations)
        function segments_to_do = AddNewVoxelsAndGetNewSegments(obj, indices_of_new_points, image_size, reporting)
            
            % Check that indices are unique
            if (numel(indices_of_new_points) ~= numel(unique(indices_of_new_points)))
                reporting.Error('PTKWavefront:Duplicates', 'Algorithm error - some points have been duplicated');
            end
            
            if any(ismember(indices_of_new_points, obj.CurrentBranch.GetAcceptedVoxels))
                reporting.Error('PTKWavefront:Duplicates', 'Algorithm error - some points have been duplicated');
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

            
            % If an explosion has been detected then do not continue
            if obj.CurrentBranch.MarkedExplosion
                obj.MoveAllWavefrontVoxelsToPendingVoxels;
%                 obj.DeleteSegmentIfNoAcceptedVoxels;
                segments_to_do = PTKWavefront.empty; % This segment has been terminated
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
            
            % Find connected components from the wavefront (which is several voxels thick)
            [offset, reduced_image, reduced_image_size] = PTKImageCoordinateUtilities.GetMinimalImageForIndices(int32(obj.GetWavefrontVoxels)', image_size);
            wavefront_connected_components = bwconncomp(reduced_image, 26);
            number_of_components = wavefront_connected_components.NumObjects;
            
            % If there is only one component, it will be growing, so there is no
            % need to do any further component analysis
            if number_of_components == 1
                segments_to_do = obj;
                return;
            end
            
            segments_to_do = PTKWavefront.empty;
            growing_branches = [];
            points_by_branches = [];
            
            % Iterate over the components and separate the wavefront voxels of
            % the current segment into a new branch for each growing component
            for component_number = 1 : wavefront_connected_components.NumObjects
                
                % Get voxel list, and adjust the indices to match those for the full image
                indices_of_component_points = wavefront_connected_components.PixelIdxList{component_number};
                indices_of_component_points = PTKImageCoordinateUtilities.OffsetIndices(int32(indices_of_component_points), offset, reduced_image_size, image_size);
                points_by_branches{component_number} = indices_of_component_points;
                
                still_growing = obj.IsThisComponentStillGrowing(indices_of_component_points);
                if (still_growing)
                    growing_branches(end + 1) = component_number;
                end
            end
            
            if length(growing_branches) < 1
                reporting.Error('PTKWavefront:NoGrowingBranches', 'Algorithm error - no growing branches');
            end
            
            if length(growing_branches) == 1
                segments_to_do = obj;
                return
            end
            
            if length(growing_branches) > 1
                
                if ~isempty(obj.MaximumNumberOfGenerations)
                    % If the maximum permitted number of generations is exceeded
                    % then terminate this segment. This will discard any
                    % remaining wavefront voxels and mark the segment as
                    % incomplete (unless it is marked as exploded)
                    if obj.CurrentBranch.GenerationNumber >= obj.MaximumNumberOfGenerations
                        obj.CurrentBranch.EarlyTerminateBranch;
                        return;
                    end
                end
                
                for index = 1 : length(growing_branches)
                    segments_to_do(end + 1) = obj.SpawnChildFromWavefrontVoxels(points_by_branches{growing_branches(index)});
                end
                
                % If the branch has divided, there may be some unaccepted points
                % left over
                obj.CompleteThisSegment;

                if isempty(obj.CurrentBranch.GetAcceptedVoxels)
                    reporting.Warning('PTKWavefront:EmptyBranch', 'Algorithm error - no points in final branch');
                end
                
            end

        end
        
        
        function CompleteThisSegment(obj)
            obj.MoveAllWavefrontVoxelsToPendingVoxels;
            obj.CurrentBranch.CompleteThisSegment
        end
    end
        
    methods (Access = private)
        
        function MoveAllWavefrontVoxelsToPendingVoxels(obj)
            while ~isempty(obj.WavefrontVoxelIndices)                
                obj.MoveVoxelsFromRearOfWavefrontToPendingVoxels;
            end
        end
        
        function MoveVoxelsFromRearOfWavefrontToPendingVoxels(obj)
            % The wavefront may be empty after voxels have been divided
            % amongst child branches
            if ~isempty(obj.WavefrontVoxelIndices{1})
                obj.CurrentBranch.AddPendingVoxels(obj.WavefrontVoxelIndices{1});
            end
            obj.WavefrontVoxelIndices(1) = [];
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

        function new_segment = SpawnChildFromWavefrontVoxels(obj, voxel_indices)
            wavefront_voxels = [];
            for index = 1 : length(obj.WavefrontVoxelIndices)
                wavefront_voxels{index} = intersect(int32(voxel_indices), obj.WavefrontVoxelIndices{index});
                obj.WavefrontVoxelIndices{index} = setxor(wavefront_voxels{index}, obj.WavefrontVoxelIndices{index});
            end
            new_segment = PTKWavefront(obj.CurrentBranch, obj.MinimumChildDistanceBeforeBifurcatingMm, obj.VoxelSizeMm, obj.MaximumNumberOfGenerations, obj.ExplosionMultiplier);
            new_segment.WavefrontVoxelIndices = wavefront_voxels;
        end

        function still_growing = IsThisComponentStillGrowing(obj, voxel_indices)
            wavefront_voxels_end = intersect(int32(voxel_indices), obj.WavefrontVoxelIndices{end});
            still_growing = ~isempty(wavefront_voxels_end);            
        end
        
    end
    
    methods (Static, Access = private)
        function concatenated_voxels = ConcatenateVoxels(voxels)
            concatenated_voxels = [];
            number_layers = length(voxels);
            for index = 1 : number_layers
                next_voxels = voxels{index};
                if ~isempty(next_voxels)
                    concatenated_voxels = cat(1, concatenated_voxels, next_voxels);
                end
            end
        end
    end
end

