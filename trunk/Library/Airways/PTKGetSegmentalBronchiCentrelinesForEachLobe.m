function start_branches = PTKGetSegmentalBronchiCentrelinesForEachLobe(airway_tree, airway_results, airway_image, lobes, template, reporting)
    % PTKGetSegmentalBronchiCentrelinesForEachLobe. Given a segmented airway tree, finds the bronchus
    %     corresponding to each pulmonary segment
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %

    [~, start_branches] = PTKGetAirwaysLabelledByLobe(template, airway_results, airway_tree, reporting);
    start_branches = PTKReallocateAirwaysByLobe(start_branches, lobes, reporting);

    left_upper_start_branches = GetMatchingBranches(airway_tree, start_branches.LeftUpper);
    left_lower_start_branches = GetMatchingBranches(airway_tree, start_branches.LeftLower);
    
    right_upper_start_branches = GetMatchingBranches(airway_tree, start_branches.RightUpper);
    right_mid_start_branches = GetMatchingBranches(airway_tree, start_branches.RightMid);
    right_lower_start_branches = GetMatchingBranches(airway_tree, start_branches.RightLower);
    
    segments = [];
    
    segments.UpperLeftSegments = GetSegmentsForUpperLeftLobe(left_upper_start_branches, reporting);
    segments.LowerLeftSegments = GetSegmentsForLowerLeftLobe(left_lower_start_branches, reporting);
    
    segments.UpperRightSegments = GetSegmentsForUpperRightLobe(right_upper_start_branches, reporting);
    segments.MiddleRightSegments = GetSegmentsForMiddleRightLobe(right_mid_start_branches, reporting);
    segments.LowerRightSegments = GetSegmentsForLowerRightLobe(right_lower_start_branches, reporting);
    
    start_branches.Segments = segments;
end

function upper_right_segments = GetSegmentsForUpperRightLobe(right_upper_start_branches, reporting)
    SetLobeIndex(right_upper_start_branches, 1);
    max_generations_to_search = 2;
    upper_right_segments = GetLargestBranches(right_upper_start_branches, max_generations_to_search, 3, reporting);
    if isempty(upper_right_segments)
        reporting.Error('PTKGetSegmentalBronchiCentrelinesForEachLobe:PermutationsDoNotMatchSegmentNumber', 'Could not subdivide the tree into exactly the desired number of branches');
    end
end

function middle_right_segments = GetSegmentsForMiddleRightLobe(right_mid_start_branches, reporting)
    SetLobeIndex(right_mid_start_branches, 2);
    max_generations_to_search = 2;
    middle_right_segments = GetLargestBranches(right_mid_start_branches, max_generations_to_search, 2, reporting);
    if isempty(middle_right_segments)
        reporting.Error('PTKGetSegmentalBronchiCentrelinesForEachLobe:PermutationsDoNotMatchSegmentNumber', 'Could not subdivide the tree into exactly the desired number of branches');
    end
end

function lower_lobe_segments = GetSegmentsForLowerRightLobe(right_lower_start_branches, reporting)
    SetLobeIndex(right_lower_start_branches, 3);    
    max_generations_to_search = 2;
    
    [first_continuation, first_segment] = OrderChildrenByRadius(right_lower_start_branches, reporting);
    SetSegmentIndex(first_segment, PTKPulmonarySegmentLabels.R_S);
    [second_continuation, second_segment] = OrderChildrenByRadius(first_continuation, reporting);
    [third_continuation, third_segment] = OrderChildrenByRadius(second_continuation, reporting);
    final_segments = GetLargestBranches(third_continuation, max_generations_to_search, 2, reporting);
    if isempty(final_segments)
        reporting.Error('PTKGetSegmentalBronchiCentrelinesForEachLobe:PermutationsDoNotMatchSegmentNumber', 'Could not subdivide the tree into exactly the desired number of branches');
    end
    
    lower_lobe_segments = [first_segment, second_segment, third_segment, final_segments];
end

function upper_left_segments = GetSegmentsForUpperLeftLobe(left_upper_start_branches, reporting)
    SetLobeIndex(left_upper_start_branches, 4);
    [division_one, division_two] = OrderChildrenByRadius(left_upper_start_branches, reporting);
    [first, second] = SeparateSmallestBranchByRadius(division_one, reporting);
    [third, fourth] = SeparateSmallestBranchByRadius(division_two, reporting);
    upper_left_segments = [first, second, third, fourth];
    if numel(upper_left_segments) > 4
        disp('More than 4 segments found in upper left lobe');
    end
end

function lower_left_segments = GetSegmentsForLowerLeftLobe(left_lower_start_branches, reporting)
    SetLobeIndex(left_lower_start_branches, 5);
    max_generations_to_search = 2;
    [first_continuation, first_segment] = OrderChildrenByLength(left_lower_start_branches, reporting);
    SetSegmentIndex(first_segment, PTKPulmonarySegmentLabels.L_S);
    final_segments = GetLargestBranches(first_continuation, max_generations_to_search, 3, reporting);
    if isempty(final_segments)
        reporting.Error('PTKGetSegmentalBronchiCentrelinesForEachLobe:PermutationsDoNotMatchSegmentNumber', 'Could not subdivide the tree into exactly the desired number of branches');
    end
    
    lower_left_segments = [first_segment, final_segments];
end

function SetLobeIndex(segments, lobe_index)
    segments_to_do = segments;
    while ~isempty(segments_to_do)
        segment = segments_to_do(end);
        segments_to_do(end) = [];
        segment.LobeIndex = lobe_index;
        segments_to_do = [segments_to_do, segment.Children];
    end
end

function SetSegmentIndex(segments, segment_index)
    segments_to_do = segments;
    while ~isempty(segments_to_do)
        segment = segments_to_do(end);
        segments_to_do(end) = [];
        segment.SegmentIndex = uint8(segment_index);
        segments_to_do = [segments_to_do, segment.Children];
    end
end

function [larger_child, smaller_child] = OrderChildrenByRadius(parent_branch, reporting)
    max_generations_to_search = 2;
    set_of_bronchi = GetLargestBranches(parent_branch, max_generations_to_search, 2, reporting);
    if isempty(set_of_bronchi)
        reporting.Error('PTKGetSegmentalBronchiCentrelinesForEachLobe:PermutationsDoNotMatchSegmentNumber', 'Could not subdivide the tree into exactly the desired number of branches');
    end
    [~, larger_branch_index] = max([set_of_bronchi.Radius]);
    smaller_branch_index = setdiff([1, 2], larger_branch_index);
    
    larger_child = set_of_bronchi(larger_branch_index);
    smaller_child = set_of_bronchi(smaller_branch_index);
end

function [smallest_branch, other_branches] = SeparateSmallestBranchByRadius(parent_branch, reporting)
    max_generations_to_search = 2;
    set_of_bronchi = GetLargestBranches(parent_branch, max_generations_to_search, 2, reporting);
    
    % If we can't separate into 2 branches, try separating into three
    if isempty(set_of_bronchi)
        set_of_bronchi = GetLargestBranches(parent_branch, max_generations_to_search, 3, reporting);
        if isempty(set_of_bronchi)
            reporting.Error('PTKGetSegmentalBronchiCentrelinesForEachLobe:PermutationsDoNotMatchSegmentNumber', 'Could not subdivide the tree into exactly the desired number of branches');
        end
    end
    [~, sorted_indicies] = sort([set_of_bronchi.Radius], 'ascend');
    smallest_branch_index = sorted_indicies(1);
    smallest_branch = set_of_bronchi(smallest_branch_index);
    other_branches = set_of_bronchi(setdiff(sorted_indicies, smallest_branch_index));
end


function [larger_child, smaller_child] = OrderChildrenByLength(parent_branch, reporting)
    max_generations_to_search = 2;
    set_of_bronchi = GetLargestBranches(parent_branch, max_generations_to_search, 2, reporting);
    if isempty(set_of_bronchi)
        reporting.Error('PTKGetSegmentalBronchiCentrelinesForEachLobe:PermutationsDoNotMatchSegmentNumber', 'Could not subdivide the tree into exactly the desired number of branches');
    end
    [~, larger_branch_index] = max([set_of_bronchi.LengthMm]);
    smaller_branch_index = setdiff([1, 2], larger_branch_index);
    
    larger_child = set_of_bronchi(larger_branch_index);
    smaller_child = set_of_bronchi(smaller_branch_index);
end

function largest_branches = GetLargestBranches(start_branches, number_of_generations_to_search, number_of_branches_to_find, reporting)
    permutations = PTKTreeUtilities.GetBranchPermutationsForBranchNumber(start_branches, number_of_generations_to_search, number_of_branches_to_find, reporting);
    if isempty(permutations)
        largest_branches = [];
        return;
    end     
    
    largest_branches = PTKTreeUtilities.GetLargestBranchesFromPermutations(permutations);
    
    % Now get the corresponding branches from the original tree
    largest_branches = PTKTreeUtilities.BranchesToSourceBranches(largest_branches);
end


function matching_branches = GetMatchingBranches(growing_tree, start_branches)
    if isa(growing_tree, 'PTKAirwayGrowingTree') 
        matching_branches = PTKAirwayGrowingTree.empty();
    else
        matching_branches = PTKTreeModel.empty();
    end
    for branch = start_branches
        matching_branches(end + 1) = growing_tree.FindCentrelineBranch(branch);
    end
end
