classdef PTKTreeUtilities < handle
    % PTKTreeUtilities. Utility functions related to tree structures
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %        


    methods (Static)
        function permutations = GetAllBranchPermutations(start_branches, max_generations)
            permutations = [];
            for branch = start_branches
                if ~isempty(branch.Children) && max_generations > 0
                    new_permutations = PTKTreeUtilities.GetAllBranchPermutations(branch.Children, max_generations - 1);
                else
                    new_permutations = [];
                end
                new_permutations{end + 1} = branch;
                if isempty(permutations)
                    permutations = new_permutations;
                else
                    new_list = [];
                    for current_permutation = permutations
                        for new_permutation = new_permutations;
                            combined = [current_permutation{1}, new_permutation{1}];
                            new_list{end + 1} = combined;
                        end
                    end
                    permutations = new_list;
                end
            end
        end
        
        % Returns a branch which is the ancestor of both specifed branches
        function ancestor = FindCommonAncestor(branch_1, branch_2)
            ancestor = branch_1;
            while ~ancestor.ContainsBranch(branch_2);
                ancestor = ancestor.Parent;
                if isempty(ancestor)
                    return
                end
            end
        end
        
        % Adds additional branches to the tree to ensure a minimum number of generations
        function ExpandTree(trees, number_of_generations)
            if (number_of_generations > 0)
                for tree = trees
                    if isempty(tree.Children)
                        new_child_1 = PTKTreeModel(tree);
                        new_child_2 = PTKTreeModel(tree);
                        new_child_1.Radius = 0.7*tree.Radius;
                        new_child_2.Radius = 0.7*tree.Radius;
                    end
                    for child = tree.Children
                        PTKTreeUtilities.ExpandTree(child, number_of_generations - 1);
                    end
                end
            end
        end
        
        % Computes all possible divisions of the tree defined by start_branches
        % into the number of subtrees specified by number_of_branches, where
        % each subtree is specified by a single root branch.
        % Will return an empty matrix if the tree could not be exactly divided 
        % into the requested number of branches
        function new_permutations = GetBranchPermutationsForBranchNumber(start_branches, number_of_generations_to_search, number_of_branches_to_find, reporting)
            
            % Make a copy of the tree - so we can extend it with artificial
            % branches where necessary
            start_branches_copy = [];
            for start_branch = start_branches
                next_start_branches_copy = PTKTreeModel.SimpleTreeCopy(start_branch);
                start_branches_copy = [start_branches_copy, next_start_branches_copy];
            end
            
            PTKTreeUtilities.ExpandTree(start_branches_copy, number_of_generations_to_search);
            
            % Find all combinations of branches
            branch_permutations = PTKTreeUtilities.GetAllBranchPermutations(start_branches_copy, number_of_generations_to_search);
            
            % Remove all combinations which don't have the right number of branches
            new_permutations = [];
            for index = 1 : length(branch_permutations)
                this_permutation = branch_permutations{index};
                if numel(this_permutation) == number_of_branches_to_find
                    new_permutations{end + 1} = this_permutation;
                end
            end
        end
        
        function largest_branches = GetLargestBranchesFromPermutations(permutations)
            
            % Find the minimum branch radius for each branch permutation
            min_radius = [];
            for index = 1 : length(permutations)
                this_permutation = permutations{index};
                [sorted_permutation, sorted_radii] = PTKTreeUtilities.SortBranchesByRadiusValues(this_permutation);
                
                % Choosing min radius
                min_radius(index) = sorted_radii(1);
                
                permutations{index} = sorted_permutation;
            end
            
            % Choose the permutation with the largest value of the minimum radius
            [~, sort_indices] = sort(min_radius);
            
            largest_branch_index = sort_indices(end);
            largest_branches = permutations{largest_branch_index};
        end
        
        
        function source_branches = BranchesToSourceBranches(branches)
            source_branches = PTKTreeModel.empty();
            for index = 1 : length(branches)
                next_branch = branches(index);
                while isempty(next_branch.BranchProperties)
                    next_branch = next_branch.Parent;
                end
                source_branches(end+1) = next_branch.BranchProperties.SourceBranch;
            end
        end
        
        function [sorted_branches, sorted_radii] = SortBranchesByRadiusValues(branches)
            radius_values = [];
            for segment_index = 1 : length(branches)
                radius_values(segment_index) = branches(segment_index).Radius;
            end
            [~, sort_indices] = sort(radius_values);
            sorted_branches = branches(sort_indices);
            sorted_radii = radius_values(sort_indices);
        end
        
        function sorted_segments = OrderSegmentsByCentroidI(segments_to_order, template)
            centroids_i = [];
            for i = 1 : length(segments_to_order)
                centroids_i(end + 1) = PTKTreeUtilities.GetICentroid(segments_to_order(i), template);
            end
            
            [~, sorted_indices] = sort(centroids_i);
            sorted_segments = segments_to_order(sorted_indices);
        end
        
        function sorted_child_indices = OrderByCentroidI(start, template)
            child_indices = start.Children;
            centroids_i = [];
            for i = 1 : length(child_indices)
                centroids_i(end + 1) = PTKTreeUtilities.GetICentroid(child_indices(i), template);
            end
            
            [~, sorted_indices] = sort(centroids_i);
            sorted_child_indices = child_indices(sorted_indices);
        end
        
        function sorted_segments = OrderSegmentsByCentroidDistanceFromDiagonalPlane(segments_to_order, template)
            centroids_dp = [];
            for i = 1 : length(segments_to_order)
                centroids_dp(end + 1) = PTKTreeUtilities.GetDPCentroid(segments_to_order(i), template);
            end
            
            [~, sorted_indices] = sort(centroids_dp);
            sorted_segments = segments_to_order(sorted_indices);
        end
        
        function centroid_i = GetICentroid(start, template)
            tree = PTKTreeUtilities.CentrelinePointsToLocalIndices(start.GetCentrelineTree, template);
            centroid = PTKTreeUtilities.GetCentroid(tree, template);
            centroid_i = centroid(1);
        end
        
        function centroid_dp = GetDPCentroid(start_segments, template)
            tree_points = [];
            for segment = start_segments
                tree_points = [tree_points segment.GetCentrelineTree];
            end
            tree = PTKTreeUtilities.CentrelinePointsToLocalIndices(tree_points, template);
            centroid = PTKTreeUtilities.GetCentroid(tree, template);
            centroid_dp = - centroid(3) - centroid(1);
        end
        
        function centroid = GetCentroid(indices, template)
            [i, j, k] = ind2sub(template.ImageSize, indices);
            centroid = zeros(1, 3);
            centroid(1) = mean(i);
            centroid(2) = mean(j);
            centroid(3) = mean(k);
        end
        
        function centreline_indices_local = CentrelinePointsToLocalIndices(centreline_points, template_image)
            centreline_indices_global = [centreline_points.GlobalIndex];
            centreline_indices_local = template_image.GlobalToLocalIndices(centreline_indices_global);
        end
        
        function k_distance = GetKDistance(branch)
            start_centreline_point = branch.GetCentrelineTree;
            start_centreline_point = start_centreline_point(1);
            start_k = start_centreline_point.CoordK;
            tree_points = branch.GetCentrelineTree;
            k_coords = [tree_points.CoordK];
            max_k = max(k_coords);
            min_k = min(k_coords);
            if abs(max_k - start_k) > abs(min_k - start_k)
                k_distance = max_k - start_k;
            else
                k_distance = min_k - start_k;
            end
        end

        function voxels = GetCentrelineVoxelsForTheseBranches(start_branches, template)
            voxels = [];
            for index = 1 : numel(start_branches)
                voxels = cat(2, voxels, PTKTreeUtilities.CentrelinePointsToLocalIndices(start_branches(index).GetCentrelineTree, template));
            end
        end
        
        function voxels = GetCentrelineVoxelsForTheseBranchesExtended(start_branches, template)
            voxels = [];
            if isempty(start_branches)
                return;
            end
            
            for index = 1 : numel(start_branches)
                voxels = cat(2, voxels, PTKTreeUtilities.CentrelinePointsToLocalIndices(start_branches(index).GetCentrelineTree, template));
                parent = start_branches(index).Parent;
                while ~isempty(parent)
                    centreline_indices = PTKTreeUtilities.CentrelinePointsToLocalIndices(parent.Centreline, template);
                    voxels = cat(2, voxels, centreline_indices);
                    parent = parent.Parent;
                end
            end
            
            % Add nearest neighbours to the list of voxels, otherwise it is possible for
            % a diagnoally-connected centreline segment to pass through a
            % diagnoally-connected airway segment
            [~, linear_offsets27] = PTKImageCoordinateUtilities.GetLinearOffsets(template.ImageSize);
            voxels = repmat(int32(voxels), 27, 1) + repmat(int32(linear_offsets27'), 1, length(voxels));
            voxels = unique(voxels(:));
        end

    end
end

