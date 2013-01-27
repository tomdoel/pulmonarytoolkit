function [results_image, start_branches] = PTKGetAirwaysLabelledByLobe(template, airway_results, airway_centreline_tree, reporting)
    % PTKGetAirwaysLabelledByLobe. Label segmented bronchi according to the
    % lobes they serve.
    % 
    % Usage:
    %
    %     [results_image, start_branches] = PTKGetAirwaysLabelledByLobe(template, airway_results, airway_centreline_tree, reporting)
    %
    % Inputs:
    %
    %     template : A PTKImage representing the region of interest used by the
    %         centreline algorithm
    %
    %     airway_results : the root PTKTreeSegment of a segmented airway tree
    %         structure produced by PTKAirwayRegionGrowingWithExplosionControl
    %
    %     airway_centreline_tree : the root PTKTreeModel of a segmented airway
    %         tree centreline produced by PTKAirwayCentreline
    %
    %     reporting : A PTKReporting object used for error and warning messages
    %
    % Outputs:
    %
    %     results_image : An image showing the segmented airways labelled by lobe.
    %         The following colours are used:
    %             1 (blue)   : Right upper lobe
    %             2 (green)  : Right middle lobe
    %             4 (cyan)   : Right lower lobe
    %             5 (magenta): Left lower lobe
    %             6 (yellow) : Left upper lobe
    %
    %             3 (red)    : Uncertain - unable to allocate to a lobe
    %             7 (grey)   : Airways supplying more than one lobe (before the
    %                          lobar bifurcations)
    %
    %    start_branches : a structure containing the first branch for each lobe
    %
    % This function uses the airway centreline returned by PTKAirwayCentreline
    % and the airway tree returned by PTKAirwayRegionGrowingWithExplosionControl.
    % The centreline is analysed to determine its branching structure. At each
    % bufurcation, the entire subtree growing from each branch is analysed to
    % determine its centroid. The two centroids are compared to separate the
    % branches according to lobes.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %

    start_segment = airway_centreline_tree;
    
    start_segment.GenerateBranchParameters;

    % Separate into left and right lungs
    [left_lung_start, right_lung_start] = SeparateIntoLeftAndRightLungs(start_segment, template, reporting);
    
    % Separate left lung into upper and lower lobes
    [left_upper_startindices, left_lower_startindices, uncertain_segments] = SeparateLeftLungIntoLobesNew(left_lung_start, template, reporting);

    % Separate right lung into upper and mid/lower lobes
    [right_upper_startindices, right_midlower_startindices] = SeparateRightLungIntoUpperAndMidlowerLobes(right_lung_start, template, reporting);
    
    % Separate right mid/lower lobe into mid and lower lobes
    [right_mid_startindices, right_lower_startindices] = SeparateRightLungIntoMidAndLowerLobes(right_midlower_startindices, template, reporting);

    start_branches = [];
    start_branches.Trachea = start_segment;
    start_branches.Left = left_lung_start;
    start_branches.Right = right_lung_start;
    start_branches.LeftUpper = left_upper_startindices;
    start_branches.LeftLower = left_lower_startindices;
    start_branches.RightUpper = right_upper_startindices;
    start_branches.RightMidLower = right_midlower_startindices;
    start_branches.RightMid = right_mid_startindices;
    start_branches.RightLower = right_lower_startindices;
    start_branches.LeftUncertain = uncertain_segments;
    
    results_image = PTKColourBranchesByLobe(start_branches, airway_results.AirwayTree, template);
end


% Find the starting bronchi for the left and right lungs
function [left_lung_start, right_lung_start] = SeparateIntoLeftAndRightLungs(start_segment, template, reporting)
    if length(start_segment.Children) > 3
       reporting.Error('PTKGetAirwaysLabelledByLobe:TooManyBronchi', 'Main bronchus branches into more than 3 bronchi.'); 
    elseif length(start_segment.Children) < 2
       reporting.Error('PTKGetAirwaysLabelledByLobe:NoBronchi', 'No bronchial branches were found from the trachea.'); 
    end
    
    child_segment_1 = start_segment.Children(1);
    child_segment_2 = start_segment.Children(2);

    tree_1 = PTKTreeUtilities.CentrelinePointsToLocalIndices(child_segment_1.GetCentrelineTree, template);
    tree_2 = PTKTreeUtilities.CentrelinePointsToLocalIndices(child_segment_2.GetCentrelineTree, template);
    
    centroid_1 = PTKTreeUtilities.GetCentroid(tree_1, template);
    centroid_2 = PTKTreeUtilities.GetCentroid(tree_2, template);
    
    if centroid_1(2) < centroid_2(2)
        right_lung_start = child_segment_1;
        left_lung_start = child_segment_2;
    else
        left_lung_start = child_segment_1;
        right_lung_start = child_segment_2;
    end
end

function [left_upper_startsegment, left_lower_startsegment, uncertain] = SeparateLeftLungIntoLobesNew(left_lung_start, template, reporting)
    if length(left_lung_start.Children) > 2
        reporting.ShowWarning('PTKGetAirwaysLabelledByLobe:TooManyBronchi', 'More than 2 bronchial branches were found separating the left upper and lower lobes.', []);
        left_lower_startsegment = [];
        left_upper_startsegment = [];
    elseif length(left_lung_start.Children) < 1
        calback.ShowWarning('PTKGetAirwaysLabelledByLobe:NoBronchi', 'ERROR: No bronchial branches were found separating the left upper and lower lobes.', []);
        left_lower_startsegment = [];
        left_upper_startsegment = [];
    else
        
        % Order branches by their computed radii and choose the largest 4
        top_branches = ForceLingulaAndGetLargestBranches(left_lung_start, 3, 4, template, 2);
        ordered_top_branches = PTKTreeUtilities.OrderSegmentsByCentroidDistanceFromDiagonalPlane(top_branches, template);

        left_lower_startsegment = [ordered_top_branches(1), ordered_top_branches(2)];
        left_upper_startsegment = [ordered_top_branches(3), ordered_top_branches(4)];
        
        left_lower_startsegment = unique(left_lower_startsegment);
        left_upper_startsegment = unique(left_upper_startsegment);
        uncertain = [];
        
        return
    end
end

function largest_branches = GetLargestBranches(start_branches, number_of_generations_to_search, number_of_branches_to_find)
    permutations = PTKTreeUtilities.GetBranchPermutationsForBranchNumber(start_branches, number_of_generations_to_search, number_of_branches_to_find);
    largest_branches = PTKTreeUtilities.GetLargestBranchesFromPermutations(permutations);
    
    % Now get the corresponding branches from the original tree
    largest_branches = PTKTreeUtilities.BranchesToSourceBranches(largest_branches);
end

function largest_branches = ForceLingulaAndGetLargestBranches(start_branches, number_of_generations_to_search, number_of_branches_to_find, template, number_of_branches_1)
    
    permutations = PTKTreeUtilities.GetBranchPermutationsForBranchNumber(start_branches, number_of_generations_to_search, number_of_branches_to_find);
    
    % Remove permutations where the third branch does not have a
    % downward direction
    new_permutations = [];
    for index = 1 : length(permutations)
        this_permutation = permutations{index};
        permutation_source = PTKTreeUtilities.BranchesToSourceBranches(this_permutation);
        ordered_branches = PTKTreeUtilities.OrderSegmentsByCentroidDistanceFromDiagonalPlane(permutation_source, template);
        k_distance_3 = PTKTreeUtilities.GetKDistance(ordered_branches(3));
        if k_distance_3 > 0
            new_permutations{end + 1} = this_permutation;
        end
    end
    
    if isempty(new_permutations)
        reporting.Error('PTKTreeUtilities:NoValidPermutations', 'Branches did not match the expected criteria');
    end
    
    permutations = new_permutations;
    
    largest_branches = PTKTreeUtilities.GetLargestBranchesFromPermutations(permutations);
    
    % Now get the corresponding branches from the original tree
    largest_branches = PTKTreeUtilities.BranchesToSourceBranches(largest_branches);
end


function [left_upper_startsegment, left_lower_startsegment, uncertain] = SeparateLeftLungIntoLobes(left_lung_start, template, reporting)
    if length(left_lung_start.Children) > 2
        reporting.ShowWarning('PTKGetAirwaysLabelledByLobe:TooManyBronchi', 'More than 2 bronchial branches were found separating the left upper and lower lobes.', []);
        left_lower_startsegment = [];
        left_upper_startsegment = [];
    elseif length(left_lung_start.Children) < 1
        calback.ShowWarning('PTKGetAirwaysLabelledByLobe:NoBronchi', 'ERROR: No bronchial branches were found separating the left upper and lower lobes.', []);
        left_lower_startsegment = [];
        left_upper_startsegment = [];
    else
        
        uncertain = [];
        first_bifurcation = left_lung_start;
        first_children = first_bifurcation.Children;
        first_grandchildren = [first_children(1).Children, first_children(2).Children];
        
        ordered_grandchildren = PTKTreeUtilities.OrderSegmentsByCentroidDistanceFromDiagonalPlane(first_grandchildren, template);
        
        lower_lobe_reference = ordered_grandchildren(1);
        upper_lobe_reference = ordered_grandchildren(end);
        uncertain_segments = ordered_grandchildren(2 : end-1);
        
        upper_lobe_dpcentroid = PTKTreeUtilities.GetDPCentroid(upper_lobe_reference, template);
        lower_lobe_dpcentroid = PTKTreeUtilities.GetDPCentroid(lower_lobe_reference, template);

        lower_lobe_3centroid = PTKTreeUtilities.GetCentroid(CentrelinePointsToLocalIndices(lower_lobe_reference.GetCentrelineTree, template), template);

        if abs(upper_lobe_dpcentroid - lower_lobe_dpcentroid) < 20
            reporting.Error('PTKGetAirwaysLabelledByLobe:NotEnoughCentroidSeparation', 'Unable to determine airway branching structure because there is not enough separation between the centroids of the branch centrelines.');
        end

        left_upper_startsegment = upper_lobe_reference;
        left_lower_startsegment = lower_lobe_reference;
        
        for i = 1 : length(uncertain_segments)
            uncertain_dpcentroid = PTKTreeUtilities.GetDPCentroid(uncertain_segments(i), template);
            uncertain_3centroid = PTKTreeUtilities.GetCentroid(CentrelinePointsToLocalIndices(uncertain_segments(i).GetCentrelineTree, template), template);
            distance_to_upper_lobe = abs(uncertain_dpcentroid - upper_lobe_dpcentroid);
            distance_to_lower_lobe = abs(uncertain_dpcentroid - lower_lobe_dpcentroid);
            
            if abs(distance_to_upper_lobe - distance_to_lower_lobe) < 60
                
                % To deal with cases where the bronchi near the fissures which
                % stretch over to the back of the lung are more likely to be
                % part of the lower lobe. This is somewhat heuristic and there
                % should be a more robust way of determining which lobe an
                % airway belongs to
                if (uncertain_3centroid(1) > lower_lobe_3centroid(1))
                    left_lower_startsegment(end + 1) = uncertain_segments(i);
                else
                    
                    if abs(distance_to_upper_lobe - distance_to_lower_lobe) < 30
                        reporting.ShowWarning('PTKGetAirwaysLabelledByLobe:Uncertain', 'Some bronchi have been labeled as uncertain', []);
                        uncertain = [uncertain; uncertain_segments(i)];
                    else
                        if (distance_to_upper_lobe < distance_to_lower_lobe)
                            left_upper_startsegment(end + 1) = uncertain_segments(i);
                        else
                            left_lower_startsegment(end + 1) = uncertain_segments(i);
                        end
                    end
                    
                end
                
            else
                if (distance_to_upper_lobe < distance_to_lower_lobe)
                    left_upper_startsegment(end + 1) = uncertain_segments(i);
                else
                    left_lower_startsegment(end + 1) = uncertain_segments(i);
                end
            end
            
        end
    end
end

function [right_upper_start_branches, right_midlower_start_branches] = SeparateRightLungIntoUpperAndMidlowerLobes(right_lung_start, template, reporting)
    if numel(right_lung_start) > 1
        reporting.Error('PTKGetAirwaysLabelledByLobe:TooManyStartingIndices', 'Too many start indices for the right upper lobe');
    end
    
    if length(right_lung_start.Children) < 1
        reporting.Error('PTKGetAirwaysLabelledByLobe:NotEnoughChildBranches', 'No bronchial branches were found separating the right upper and right mid lobes.');
        right_upper_start_branches = [];
        right_midlower_start_branches = [];
    else
        % Order branches by their computed radii and choose the largest 3
        top_branches = GetLargestBranches(right_lung_start, 2, 3);
        
        % Find the ancestor branch of the two widest branches - this is the
        % bifurcation point between the upper and middle lobes
        ancestor_branch = PTKTreeUtilities.FindCommonAncestor(top_branches(2), top_branches(3));
        
        % There are two possibilites: the lobar bifurcation happens at either
        % the first or second bifurcaton in the right bronchial tree
        if ancestor_branch == right_lung_start
            
            % In this case the lower branch goes into the mid/lower lobes, and
            % the upper branches go into the upper lobe
            branches_to_order = ancestor_branch.Children;
            ordered_branches = PTKTreeUtilities.OrderSegmentsByCentroidDistanceFromDiagonalPlane(branches_to_order, template);
            right_upper_start_branches = ordered_branches(end);
            right_midlower_start_branches = ordered_branches(1:end-1);
        else
            
            % In this case, there is an additional branch for the upper lobe
            % before the upper/mid-lower bifurcation occurs
            branches_to_order = ancestor_branch.Children;
            earlier_branches = setdiff(ancestor_branch.Parent.Children, ancestor_branch);
            ordered_branches = PTKTreeUtilities.OrderSegmentsByCentroidDistanceFromDiagonalPlane(branches_to_order, template);
            right_upper_start_branches = [ordered_branches(2:end), earlier_branches];
            right_midlower_start_branches = ordered_branches(1);
        end
    end
end

function [right_upper_start_branches, right_midlower_start_branches] = SeparateRightLungIntoUpperAndMidlowerLobesOld(right_lung_start, template, reporting)
    if numel(right_lung_start) > 1
        reporting.Error('PTKGetAirwaysLabelledByLobe:TooManyStartingIndices', 'Too many start indices for the right upper lobe');
    end

    if length(right_lung_start.Children) > 2
        reporting.Error('PTKGetAirwaysLabelledByLobe:TooManyChildBranches', 'More than 2 bronchial branches were found separating the right upper and right mid lobes.');
        right_upper_start_branches = [];
        right_midlower_start_branches = [];
    elseif length(right_lung_start.Children) < 1
        reporting.Error('PTKGetAirwaysLabelledByLobe:NotEnoughChildBranches', 'No bronchial branches were found separating the right upper and right mid lobes.');
        right_upper_start_branches = [];
        right_midlower_start_branches = [];
    else
        child_index_1 = right_lung_start.Children(1);
        child_index_2 = right_lung_start.Children(2);
        
        centroid_1 = PTKTreeUtilities.GetDPCentroid(child_index_1, template);
        centroid_2 = PTKTreeUtilities.GetDPCentroid(child_index_2, template);
        
        if abs(centroid_1 - centroid_2) < 20
            reporting.Error('PTKGetAirwaysLabelledByLobe:NotEnoughCentroidSeparation', 'Unable to determine airway branching structure because there is not enough separation between the centroids of the branch centrelines');
        end
        
        if centroid_1 > centroid_2
            right_upper_start_branches = child_index_1;
            right_midlower_start_branches = child_index_2;
        else
            right_midlower_start_branches = child_index_1;
            right_upper_start_branches = child_index_2;
        end
    end
end

function [right_mid_startindices, right_lower_startindices] = SeparateRightLungIntoMidAndLowerLobesNew(right_midlower_startindex, template, reporting)
    if isempty(right_midlower_startindex)
        reporting.Error('PTKGetAirwaysLabelledByLobe:NoStartBranch', 'No start branch was specified.');
    end
    
    % Order branches by their computed radii and choose the largest 3
    top_branches = GetLargestBranches(right_midlower_startindex, 2, 3);

    ordered_branches = PTKTreeUtilities.OrderSegmentsByCentroidI(top_branches, template);
    right_mid_startindices = ordered_branches(1);
    right_lower_startindices = ordered_branches(2:end);
end

function [right_mid_startindices, right_lower_startindices] = SeparateRightLungIntoMidAndLowerLobes(right_midlower_startindex, template, reporting)
    if isempty(right_midlower_startindex)
        reporting.Error('PTKGetAirwaysLabelledByLobe:NoStartBranch', 'No start branch was specified.');
    end
    if numel(right_midlower_startindex) > 1
        reporting.Error('PTKGetAirwaysLabelledByLobe:TooManyStartBranch', 'Too many start indices for the right mid-lower lobes.');
    end
    
    if length(right_midlower_startindex.Children) > 2
        reporting.ShowWarning('PTKGetAirwaysLabelledByLobe:TooManyBronchi', 'More than 2 bronchial branches were found separating the right lower and right mid lobes.', []);
        right_mid_startindices = [];
        right_lower_startindices = [];
    elseif length(right_midlower_startindex.Children) < 1
        reporting.ShowWarning('PTKGetAirwaysLabelledByLobe:TooManyBronchi', 'ERROR: No bronchial branches were found separating the right lower and right mid lobes.', []);
        right_mid_startindices = [];
        right_lower_startindices = [];
    else
        sorted_child_indices_A = PTKTreeUtilities.OrderByCentroidI(right_midlower_startindex, template);
        child_index_A1 = sorted_child_indices_A(1);
        child_index_A2 = sorted_child_indices_A(2);

        centroid_A1 = PTKTreeUtilities.GetICentroid(child_index_A1, template);
        centroid_A2 = PTKTreeUtilities.GetICentroid(child_index_A2, template);
        if abs(centroid_A1 - centroid_A2) < 10
            reporting.ShowWarning('PTKGetAirwaysLabelledByLobe:NotEnoughCentroidSeparation', 'Not enough centroid separation.', []);
        end
        
        if centroid_A1 < centroid_A2
            right_mid_startindices = child_index_A1;
            right_lower_startindices = child_index_A2;
        else
            reporting.Error('PTKGetAirwaysLabelledByLobe:ProgramError', 'Programming error: centroid should be sorted.', []);
            right_lower_startindices = child_index_A1;
            right_mid_startindices = child_index_A2;
        end

        child_indices_B = right_mid_startindices.Children;
        if ~isempty(child_indices_B)
            sorted_child_indices_B = PTKTreeUtilities.OrderByCentroidI(child_index_A1, template);
            child_index_B1 = sorted_child_indices_B(1);
            child_index_B2 = sorted_child_indices_B(2);
            
            centroid_B1 = PTKTreeUtilities.GetICentroid(child_index_B1, template);
            centroid_B2 = PTKTreeUtilities.GetICentroid(child_index_B2, template);
           
            distance_1 = centroid_A2 - centroid_B2;
            distance_2 = centroid_B2 - centroid_B1;
            
            % distance_1 can be negative but distance_2 by definition must be positive
            if distance_2 < 0
                reporting.Error('PTKGetAirwaysLabelledByLobe:ProgramError', 'Programming error: distance computation error.', []);
            end
            
            if (distance_1 < distance_2)
                right_lower_startindices = [right_lower_startindices child_index_B2];
                right_mid_startindices = child_index_B1;
            else
            end

        end
    end
end