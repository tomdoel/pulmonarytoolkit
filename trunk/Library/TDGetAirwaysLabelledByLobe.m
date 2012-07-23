function [results_image, start_branches] = TDGetAirwaysLabelledByLobe(template, airway_results, skeleton_airway_tree, reporting)
    % TDGetAirwaysLabelledByLobe. Label segmented bronchi according to the
    % lobes they serve.
    % 
    % Usage:
    %
    %     [results_image, start_branches] = TDGetAirwaysLabelledByLobe(template, airway_results, skeleton_results, reporting)
    %
    % Inputs:
    %
    %     template : A TDImage representing the region of interest used by the
    %         skeletonisation algorithm
    %
    %     airway_results : the root TDTreeSegment of a segmented airway tree
    %         structure produced by TDAirwayRegionGrowingWithExplosionControl
    %
    %     skeleton_airway_tree : the root TDTreeModel of a segmented airway
    %         tree skeleton produced by TDAirwaySkeleton
    %
    %     reporting : A TDReporting object used for error and warning messages
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
    % This function uses the skeletonised airway tree returned by TDSkeletonise
    % and the airway tree returned by TDAirwayRegionGrowingWithExplosionControl.
    % The skeleton is analysed to determine its branching structure. At each
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

    start_segment = skeleton_airway_tree;

    % Separate into left and right lungs
    [left_lung_start, right_lung_start] = SeparateIntoLeftAndRightLungs(start_segment, template, reporting);
    
    % Separate left lung into upper and lower lobes
    [left_upper_startindices, left_lower_startindices, uncertain_segments] = SeparateLeftLungIntoLobes(left_lung_start, template, reporting);
        
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
    
    results_image = TDColourBranchesByLobe(start_branches, airway_results.AirwayTree, template);
end


% Find the starting bronchi for the left and right lungs
function [left_lung_start, right_lung_start] = SeparateIntoLeftAndRightLungs(start_segment, template, reporting)
    if length(start_segment.Children) > 3
       reporting.Error('TDGetAirwaysLabelledByLobe:TooManyBronchi', 'Main bronchus branches into more than 3 bronchi.'); 
    elseif length(start_segment.Children) < 2
       reporting.Error('TDGetAirwaysLabelledByLobe:NoBronchi', 'No bronchial branches were found from the trachea.'); 
    end
    
    child_segment_1 = start_segment.Children(1);
    child_segment_2 = start_segment.Children(2);

    tree_1 = CentrelinePointsToLocalIndices(child_segment_1.GetCentrelineTree, template);
    tree_2 = CentrelinePointsToLocalIndices(child_segment_2.GetCentrelineTree, template);
    
    centroid_1 = GetCentroid(tree_1, template);
    centroid_2 = GetCentroid(tree_2, template);
    
    if centroid_1(2) < centroid_2(2)
        right_lung_start = child_segment_1;
        left_lung_start = child_segment_2;
    else
        left_lung_start = child_segment_1;
        right_lung_start = child_segment_2;
    end
end

function [left_upper_startsegment, left_lower_startsegment, uncertain] = SeparateLeftLungIntoLobes(left_lung_start, template, reporting)
    if length(left_lung_start.Children) > 2
        reporting.ShowWarning('TDGetAirwaysLabelledByLobe:TooManyBronchi', 'More than 2 bronchial branches were found separating the left upper and lower lobes.', []);
        left_lower_startsegment = [];
        left_upper_startsegment = [];
    elseif length(left_lung_start.Children) < 1
        calback.ShowWarning('TDGetAirwaysLabelledByLobe:NoBronchi', 'ERROR: No bronchial branches were found separating the left upper and lower lobes.', []);
        left_lower_startsegment = [];
        left_upper_startsegment = [];
    else
        
        uncertain = [];
        
        first_bifurcation = left_lung_start;
        first_children = first_bifurcation.Children;
        first_grandchildren = [first_children(1).Children, first_children(2).Children];
        
        ordered_grandchildren = OrderSegmentsByCentroidDistanceFromDiagonalPlane(first_grandchildren, template);
        
        lower_lobe_reference = ordered_grandchildren(1);
        upper_lobe_reference = ordered_grandchildren(end);
        uncertain_segments = ordered_grandchildren(2 : end-1);
        
        upper_lobe_dpcentroid = GetDPCentroid(upper_lobe_reference, template);
        lower_lobe_dpcentroid = GetDPCentroid(lower_lobe_reference, template);

        lower_lobe_3centroid = GetCentroid(CentrelinePointsToLocalIndices(lower_lobe_reference.GetCentrelineTree, template), template);

        if abs(upper_lobe_dpcentroid - lower_lobe_dpcentroid) < 20
            reporting.Error('TDGetAirwaysLabelledByLobe:NotEnoughCentroidSeparation', 'Unable to determine airway branching structure because there is not enough separation between the centroids of the skeletonised branches');
        end

        left_upper_startsegment = upper_lobe_reference;
        left_lower_startsegment = lower_lobe_reference;
        
        for i = 1 : length(uncertain_segments)
            uncertain_dpcentroid = GetDPCentroid(uncertain_segments(i), template);
            uncertain_3centroid = GetCentroid(CentrelinePointsToLocalIndices(uncertain_segments(i).GetCentrelineTree, template), template);
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
                        reporting.ShowWarning('TDGetAirwaysLabelledByLobe:Uncertain', 'Some bronchi have been labeled as uncertain', []);
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

function [right_upper_startindices, right_midlower_startindices] = SeparateRightLungIntoUpperAndMidlowerLobes(right_lung_startindex, template, reporting)
    if numel(right_lung_startindex) > 1
        reporting.Error('TDGetAirwaysLabelledByLobe:TooManyStartingIndices', 'Too many start indices for the right upper lobe');
    end
    
    if length(right_lung_startindex.Children) > 2
        reporting.Error('TDGetAirwaysLabelledByLobe:TooManyChildBranches', 'More than 2 bronchial branches were found separating the right upper and right mid lobes.');
        right_upper_startindices = [];
        right_midlower_startindices = [];
    elseif length(right_lung_startindex.Children) < 1
        reporting.Error('TDGetAirwaysLabelledByLobe:NotEnoughChildBranches', 'No bronchial branches were found separating the right upper and right mid lobes.');
        right_upper_startindices = [];
        right_midlower_startindices = [];
    else
        child_index_1 = right_lung_startindex.Children(1);
        child_index_2 = right_lung_startindex.Children(2);
        
        centroid_1 = GetDPCentroid(child_index_1, template);
        centroid_2 = GetDPCentroid(child_index_2, template);
        
        if abs(centroid_1 - centroid_2) < 20
            reporting.Error('TDGetAirwaysLabelledByLobe:NotEnoughCentroidSeparation', 'Unable to determine airway branching structure because there is not enough separation between the centroids of the skeletonised branches');
        end
        
        if centroid_1 > centroid_2
            right_upper_startindices = child_index_1;
            right_midlower_startindices = child_index_2;
        else
            right_midlower_startindices = child_index_1;
            right_upper_startindices = child_index_2;
        end
    end
end

function [right_mid_startindices, right_lower_startindices] = SeparateRightLungIntoMidAndLowerLobes(right_midlower_startindex, template, reporting)
    if isempty(right_midlower_startindex)
        reporting.Error('TDGetAirwaysLabelledByLobe:NoStartBranch', 'No start branch was specified.');
    end
    if numel(right_midlower_startindex) > 1
        reporting.Error('TDGetAirwaysLabelledByLobe:TooManyStartBranch', 'Too many start indices for the right mid-lower lobes.');
    end
    
    if length(right_midlower_startindex.Children) > 2
        reporting.ShowWarning('TDGetAirwaysLabelledByLobe:TooManyBronchi', 'More than 2 bronchial branches were found separating the right lower and right mid lobes.', []);
        right_mid_startindices = [];
        right_lower_startindices = [];
    elseif length(right_midlower_startindex.Children) < 1
        reporting.ShowWarning('TDGetAirwaysLabelledByLobe:TooManyBronchi', 'ERROR: No bronchial branches were found separating the right lower and right mid lobes.', []);
        right_mid_startindices = [];
        right_lower_startindices = [];
    else
        sorted_child_indices_A = OrderByCentroidI(right_midlower_startindex, template);
        child_index_A1 = sorted_child_indices_A(1);
        child_index_A2 = sorted_child_indices_A(2);

        centroid_A1 = GetICentroid(child_index_A1, template);
        centroid_A2 = GetICentroid(child_index_A2, template);
        if abs(centroid_A1 - centroid_A2) < 10
            reporting.ShowWarning('TDGetAirwaysLabelledByLobe:NotEnoughCentroidSeparation', 'Not enough centroid separation.', []);
        end
        
        if centroid_A1 < centroid_A2
            right_mid_startindices = child_index_A1;
            right_lower_startindices = child_index_A2;
        else
            reporting.Error('TDGetAirwaysLabelledByLobe:ProgramError', 'Programming error: centroid should be sorted.', []);
            right_lower_startindices = child_index_A1;
            right_mid_startindices = child_index_A2;
        end

        child_indices_B = right_mid_startindices.Children;
        if ~isempty(child_indices_B)
            sorted_child_indices_B = OrderByCentroidI(child_index_A1, template);
            child_index_B1 = sorted_child_indices_B(1);
            child_index_B2 = sorted_child_indices_B(2);
            
            centroid_B1 = GetICentroid(child_index_B1, template);
            centroid_B2 = GetICentroid(child_index_B2, template);
           
            distance_1 = centroid_A2 - centroid_B2;
            distance_2 = centroid_B2 - centroid_B1;
            
            % distance_1 can be negative but distance_2 by definition must be positive
            if distance_2 < 0
                reporting.Error('TDGetAirwaysLabelledByLobe:ProgramError', 'Programming error: distance computation error.', []);
            end
            
            if (distance_1 < distance_2)
                right_lower_startindices = [right_lower_startindices child_index_B2];
                right_mid_startindices = child_index_B1;
            else
            end

        end
    end
end



function sorted_child_indices = OrderByCentroidI(start, image_size)
    child_indices = start.Children;
    centroids_i = [];
    for i = 1 : length(child_indices)
        centroids_i(end + 1) = GetICentroid(child_indices(i), image_size);
    end
    
    [~, sorted_indices] = sort(centroids_i);
    sorted_child_indices = child_indices(sorted_indices);
end

function sorted_segments = OrderSegmentsByCentroidDistanceFromDiagonalPlane(segments_to_order, template)
    centroids_dp = [];
    for i = 1 : length(segments_to_order)
        centroids_dp(end + 1) = GetDPCentroid(segments_to_order(i), template);
    end
    
    [~, sorted_indices] = sort(centroids_dp);
    sorted_segments = segments_to_order(sorted_indices);
end

function centroid_i = GetICentroid(start, template)
    tree = CentrelinePointsToLocalIndices(start.GetCentrelineTree, template);
    centroid = GetCentroid(tree, template);
    centroid_i = centroid(1);
end

function centroid_dp = GetDPCentroid(start_segment, template)
    tree = CentrelinePointsToLocalIndices(start_segment.GetCentrelineTree, template);
    centroid = GetCentroid(tree, template);
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

