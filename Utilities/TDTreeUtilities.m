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
        
        function largest_branches = GetLargestBranches(start_branches, number_of_generations_to_search, number_of_branches_to_find)
            
            % Find all combinations of branches
            branch_permutations = TDTreeUtilities.GetAllBranchPermutations(start_branches, number_of_generations_to_search);
            
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
                radius_values = [];
                for segment_index = 1 : length(this_permutation)
                    radius_values(segment_index) = this_permutation(segment_index).Radius;
                end
                min_radius(index) = min(radius_values);
            end
            
            % Choose the permutation with the largest value of the minimum radius
            [~, sort_indices] = sort(min_radius);
            largest_branches = new_permutations{sort_indices(end)};
        end
        
    end
end

