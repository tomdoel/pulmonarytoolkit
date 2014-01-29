function airway_tree_without_segmental_labels = PTKMapSegmentalParameters(airway_tree_with_segmental_labels, airway_tree_without_segmental_labels, reporting)
    % PTKMapSegmentalParameters. Copies segmental labels from one airway tree to
    % another
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %

    root_labelled = airway_tree_with_segmental_labels.GetRoot;
    root_unlabelled = airway_tree_without_segmental_labels.GetRoot;
    
    branches_to_match = PTKPair(root_labelled, root_unlabelled);
    
    while ~isempty(branches_to_match)
        next_branches = branches_to_match(end);
        branches_to_match(end) = [];
        labelled_branch = next_branches.First;
        unlabelled_branch = next_branches.Second;

        segmental_label_found = LabelSubtree(labelled_branch, unlabelled_branch);
        if ~segmental_label_found
            labelled_children = labelled_branch.Children;
            unlabelled_children = unlabelled_branch.Children;
            if ~isempty(labelled_children)
                matched_branches = MatchBranches(labelled_children, unlabelled_children, reporting);
                branches_to_match = [branches_to_match, matched_branches];
            end
        end
    end
end

function segmental_label_found = LabelSubtree(labelled_branch, unlabelled_branch)
    segment_index = labelled_branch.SegmentIndex;
    if isempty(segment_index)
        segmental_label_found = false;
    else
        segmental_label_found = true;
        branches_to_do = unlabelled_branch;
        while ~isempty(branches_to_do)
            next_branch = branches_to_do(end);
            next_branch.SegmentIndex = segment_index;
            branches_to_do(end) = [];
            
            branches_to_do = [branches_to_do, next_branch.Children];
        end
    end
end

function matched_branches = MatchBranches(labelled_branches, unlabelled_branches, reporting)
    
    remaining_branches = unlabelled_branches;
    matched_branches = PTKPair.empty;
    unmatched_branches = PTKTreeModel.empty;
    
    for branch = labelled_branches
        matching_branches = GetBranchesMatchingThisBranch(remaining_branches, branch);
        
        if isempty(matching_branches)
            unmatched_branches(end + 1) = branch;
        else
            if numel(matching_branches) > 1
                reporting.Error('PTKMatchSegmentalParameters:UnabelToMatchTrees', 'Could not match the airway trees: More than one branch with the same end coordinates.');
            end
            matched_branches(end + 1) = PTKPair(branch, matching_branches);
            remaining_branches = setdiff(remaining_branches, matching_branches);
        end
    end
    
    if ~isempty(unmatched_branches)
        if numel(unmatched_branches) == 1
            matched_branches(end + 1) = PTKPair(unmatched_branches, remaining_branches);
            reporting.ShowWarning('PTKMapSegmentalParameters:BranchMismatch', 'At a bifurcation, one of the child branches did not match.', []);
        else
            reporting.Error('PTKMapSegmentalParameters:UnabelToMatchTrees', 'Could not match the airway trees: More then one branch with un-matching end coordinates.');
        end
        
    end
    
    
end

function matching_branches = GetBranchesMatchingThisBranch(branch_list, branch_to_match)
    matching_branches = [];
    for branch = branch_list
        if ApproximateMatch(branch.EndPoint, branch_to_match.EndPoint)
            matching_branches = [matching_branches, branch];
        end
    end
end

function is_match = ApproximateMatch(value_1, value_2)
    is_match = (abs(value_1.CoordX - value_2.CoordX) < 0.01) && ...
        (abs(value_1.CoordY - value_2.CoordY) < 0.01) && ...
        (abs(value_1.CoordZ - value_2.CoordZ) < 0.01);
end