classdef TDTreeUtilities < handle
    % TDTreeUtilities. Utility functions related to tree structures
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
                    new_permutations = TDTreeUtilities.GetAllBranchPermutations(branch.Children, max_generations - 1);
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
        function ExpandTree(tree, number_of_generations)
            if (number_of_generations > 0)
                if isempty(tree.Children)
                    new_child_1 = TDTreeModel(tree);
                    new_child_2 = TDTreeModel(tree);
                    new_child_1.Radius = 0.7*tree.Radius;
                    new_child_2.Radius = 0.7*tree.Radius;
                end
                for child = tree.Children
                    TDTreeUtilities.ExpandTree(child, number_of_generations - 1);
                end
            end
        end
        
        function largest_branches = GetLargestBranches(start_branches, number_of_generations_to_search, number_of_branches_to_find)
            
            % Make a copy of the tree - so we can extend it with artificial
            % branches where necessary
            start_branches_copy = TDTreeModel.SimpleTreeCopy(start_branches);
            
            TDTreeUtilities.ExpandTree(start_branches_copy, number_of_generations_to_search);
            
            % Find all combinations of branches
            branch_permutations = TDTreeUtilities.GetAllBranchPermutations(start_branches_copy, number_of_generations_to_search);
            
            % Remove all combinations which don't have the right number of branches
            new_permutations = [];
            for index = 1 : length(branch_permutations)
                this_permutation = branch_permutations{index};
                if numel(this_permutation) == number_of_branches_to_find
                    new_permutations{end + 1} = this_permutation;
                end
            end
            
            if isempty(new_permutations)
                reporting.Error('TDTreeUtilities:PermutationsDoNotMatchSegmentNumber', 'Could not subdivide the tree into exactly the desired number of branches');
            end
            
            % Find the minimum branch radius for each branch permutation
            min_radius = [];
            for index = 1 : length(new_permutations)
                this_permutation = new_permutations{index};
                [sorted_permutation, sorted_radii] = TDTreeUtilities.SortBranchesByRadiusValues(this_permutation);
                
                % Choosing max radius
                min_radius(index) = sorted_radii(1);
                
                
                new_permutations{index} = sorted_permutation;
            end
            
            % Choose the permutation with the largest value of the minimum radius
            [~, sort_indices] = sort(min_radius);
            largest_branches_newtree = new_permutations{sort_indices(end)};
            
            % Now get the corresponding branches from the original tree
            largest_branches = TDTreeModel.empty();
            for index = 1 : length(largest_branches_newtree)
                next_branch = largest_branches_newtree(index);
                while isempty(next_branch.BranchProperties)
                    next_branch = next_branch.Parent;
                end
                largest_branches(end+1) = next_branch.BranchProperties.SourceBranch;
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
        
    end
end

