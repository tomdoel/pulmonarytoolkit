function results = TDGetAirwaysLabelledByLobe(template, airway_results, skeleton_results, reporting)
    % TDGetAirwaysLabelledByLobe. Label segmented bronchi according to the
    % lobes they serve.
    % 
    % Usage:
    %
    %     results = TDGetAirwaysLabelledByLobe(template, airway_results, skeleton_results, reporting)
    %
    % Inputs:
    %
    %     template : A TDImage representing the region of interest used by the
    %         skeletonisation algorithm
    %
    %     airway_results : the root TDTreeSegment of a segmented airway tree
    %         structure produced by TDAirwayRegionGrowingWithExplosionControl
    %
    %     skeleton_results : the root TDSkeletonSegment of a segmented airway
    %         tree skeleton produced by TDSkeletonise
    %
    %     reporting : A TDReporting object used for error and warning messages
    %
    % Outputs:
    %
    %     results : An image showing the segmented airways labelled by lobe.
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

    image_size = skeleton_results.image_size;
    
    start_segment = skeleton_results.airway_skeleton;

    % Separate into left and right lungs
    [left_lung_start, right_lung_start] = SeparateIntoLeftAndRightLungs(start_segment, image_size, reporting);
    
    % Separate left lung into upper and lower lobes
    [left_upper_startindices, left_lower_startindices, uncertain_segments] = SeparateLeftLungIntoLobes(left_lung_start, image_size, reporting);
        
    % Separate right lung into upper and mid/lower lobes
    [right_upper_startindices, right_midlower_startindices] = SeparateRightLungIntoUpperAndMidlowerLobes(right_lung_start, image_size, reporting);
    
    % Separate right mid/lower lobe into mid and lower lobes
    [right_mid_startindices, right_lower_startindices] = SeparateRightLungIntoMidAndLowerLobes(right_midlower_startindices, image_size, reporting);

    % Get voxels for lobes
    left_lower_voxels = GetVoxelsForTheseBranches(left_lower_startindices);
    left_upper_voxels = GetVoxelsForTheseBranches(left_upper_startindices);
    right_lower_voxels = GetVoxelsForTheseBranches(right_lower_startindices);
    right_mid_voxels = GetVoxelsForTheseBranches(right_mid_startindices);
    right_upper_voxels = GetVoxelsForTheseBranches(right_upper_startindices);
    
    uncertain_voxels = GetVoxelsForTheseBranches(uncertain_segments);

    left_lower_voxels_extended = GetVoxelsForTheseBranchesExtended(left_lower_startindices, image_size);
    left_upper_voxels_extended = GetVoxelsForTheseBranchesExtended(left_upper_startindices, image_size);
    right_lower_voxels_extended = GetVoxelsForTheseBranchesExtended(right_lower_startindices, image_size);
    right_mid_voxels_extended = GetVoxelsForTheseBranchesExtended(right_mid_startindices, image_size);
    right_upper_voxels_extended = GetVoxelsForTheseBranchesExtended(right_upper_startindices, image_size);
    
    uncertain_voxels_extended = GetVoxelsForTheseBranchesExtended(uncertain_segments, image_size);
    
    results = zeros(image_size, 'uint8');
    
    full_tree_voxels = start_segment.GetTree;
    
    results(full_tree_voxels) = 7;
    
    results(right_upper_voxels) = 1;
    results(right_mid_voxels) = 2;
    results(right_lower_voxels) = 4;
    results(left_upper_voxels) = 5;
    results(left_lower_voxels) = 6;
    
    results(uncertain_voxels) = 3;

    % Label segments by skeleton
    results(:) = 0;

    segments_to_do = airway_results.AirwayTree;
    
    while ~isempty(segments_to_do)
        segment = segments_to_do(end);
        segments_to_do(end) = [];
        voxel_indices_in_segment = segment.GetAllAirwayPoints;
        voxel_indices_in_segment = template.GlobalToLocalIndices(voxel_indices_in_segment);
        
        lobe_indices = [];
        if any(ismember(right_upper_voxels_extended, voxel_indices_in_segment))
            lobe_indices = [lobe_indices, 1];
        end
        if any(ismember(right_mid_voxels_extended, voxel_indices_in_segment))
            lobe_indices = [lobe_indices, 2];
        end
        if any(ismember(right_lower_voxels_extended, voxel_indices_in_segment))
            lobe_indices = [lobe_indices, 4];
        end
        if any(ismember(left_upper_voxels_extended, voxel_indices_in_segment))
            lobe_indices = [lobe_indices, 5];
        end
        if any(ismember(left_lower_voxels_extended, voxel_indices_in_segment))
            lobe_indices = [lobe_indices, 6];
        end
        
        if any(ismember(uncertain_voxels_extended, voxel_indices_in_segment))
            lobe_indices = [lobe_indices, 3];
        end
        
        if length(lobe_indices) == 1
            results(voxel_indices_in_segment) = lobe_indices;
        end
        
        segments_to_do = [segments_to_do segment.Children];
    end
    
end




% Find the starting bronchi for the left and right lungs
function [left_lung_start, right_lung_start] = SeparateIntoLeftAndRightLungs(start_segment, image_size, reporting)
    if length(start_segment.Children) > 3
       reporting.Error('TDGetAirwaysLabelledByLobe:TooManyBronchi', 'Main bronchus branches into more than 3 bronchi.'); 
    elseif length(start_segment.Children) < 2
       reporting.Error('TDGetAirwaysLabelledByLobe:NoBronchi', 'No bronchial branches were found from the trachea.'); 
    end
    
    child_segment_1 = start_segment.Children(1);
    child_segment_2 = start_segment.Children(2);

    tree_1 = child_segment_1.GetTree;
    tree_2 = child_segment_2.GetTree;
    
    centroid_1 = GetCentroid(tree_1, image_size);
    centroid_2 = GetCentroid(tree_2, image_size);
    
    if centroid_1(2) < centroid_2(2)
        right_lung_start = child_segment_1;
        left_lung_start = child_segment_2;
    else
        left_lung_start = child_segment_1;
        right_lung_start = child_segment_2;
    end
end

function [left_upper_startsegment, left_lower_startsegment, uncertain] = SeparateLeftLungIntoLobes(left_lung_start, image_size, reporting)
    if length(left_lung_start.Children) > 2
        reporting.ShowWarning('TDGetAirwaysLabelledByLobe:TooManyBronchi', 'More than 2 bronchial branches were found separating the left upper and lower lobes.', []);
        left_lower_startsegment = [];
        left_upper_startsegment = [];
    elseif length(left_lung_start.Children) < 1
        calback.ShowWarning('TDGetAirwaysLabelledByLobe:TooManyBronchi', 'ERROR: No bronchial branches were found separating the left upper and lower lobes.', []);
        left_lower_startsegment = [];
        left_upper_startsegment = [];
    else
        
        uncertain = [];
        
        first_bifurcation = left_lung_start;
        first_children = first_bifurcation.Children;
        first_grandchildren = [first_children(1).Children, first_children(2).Children];
        
        ordered_grandchildren = OrderSegmentsByCentroidDistanceFromDiagonalPlane(first_grandchildren, image_size);
        
        lower_lobe_reference = ordered_grandchildren(1);
        upper_lobe_reference = ordered_grandchildren(end);
        uncertain_segments = ordered_grandchildren(2 : end-1);
        
        upper_lobe_dpcentroid = GetDPCentroid(upper_lobe_reference, image_size);
        lower_lobe_dpcentroid = GetDPCentroid(lower_lobe_reference, image_size);

        lower_lobe_3centroid = GetCentroid(lower_lobe_reference.GetTree, image_size);

        if abs(upper_lobe_dpcentroid - lower_lobe_dpcentroid) < 20
            reporting.Error('TDGetAirwaysLabelledByLobe:NotEnoughCentroidSeparation', 'Unable to determine airway branching structure because there is not enough separation between the centroids of the skeletonised branches');
        end

        left_upper_startsegment = upper_lobe_reference;
        left_lower_startsegment = lower_lobe_reference;
        
        for i = 1 : length(uncertain_segments)
            uncertain_dpcentroid = GetDPCentroid(uncertain_segments(i), image_size);
            uncertain_3centroid = GetCentroid(uncertain_segments(i).GetTree, image_size);
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

function [right_upper_startindices, right_midlower_startindices] = SeparateRightLungIntoUpperAndMidlowerLobes(right_lung_startindex, image_size, reporting)
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
        
        centroid_1 = GetDPCentroid(child_index_1, image_size);
        centroid_2 = GetDPCentroid(child_index_2, image_size);
        
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

function [right_mid_startindices, right_lower_startindices] = SeparateRightLungIntoMidAndLowerLobes(right_midlower_startindex, image_size, reporting)
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
        sorted_child_indices_A = OrderByCentroidI(right_midlower_startindex, image_size);
        child_index_A1 = sorted_child_indices_A(1);
        child_index_A2 = sorted_child_indices_A(2);

        centroid_A1 = GetICentroid(child_index_A1, image_size);
        centroid_A2 = GetICentroid(child_index_A2, image_size);
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
            sorted_child_indices_B = OrderByCentroidI(child_index_A1, image_size);
            child_index_B1 = sorted_child_indices_B(1);
            child_index_B2 = sorted_child_indices_B(2);
            
            centroid_B1 = GetICentroid(child_index_B1, image_size);
            centroid_B2 = GetICentroid(child_index_B2, image_size);
           
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


function voxels = GetVoxelsForTheseBranches(start_indices)
    voxels = [];
    for index = 1 : numel(start_indices)
        voxels = cat(2, voxels, start_indices(index).GetTree);
    end
end

    
function voxels = GetVoxelsForTheseBranchesExtended(start_indices, image_size)
    voxels = [];
    if isempty(start_indices)
        return;
    end
    
    for index = 1 : numel(start_indices)
        voxels = cat(2, voxels, start_indices(index).GetTree);
        parent = start_indices(index).Parent;
        while ~isempty(parent)
            voxels = cat(2, voxels, parent.Points);
            parent = parent.Parent;
        end
    end

    % Add nearest neighbours to the list of voxels, otherwise it is possible for
    % a diagnoally-connected skeleton segment to pass through a
    % diagnoally-connected airway segment
    [~, linear_offsets27] = TDImageCoordinateUtilities.GetLinearOffsets(image_size);
    voxels = repmat(int32(voxels), 27, 1) + repmat(int32(linear_offsets27'), 1, length(voxels));    
    voxels = unique(voxels(:));
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

function sorted_segments = OrderSegmentsByCentroidDistanceFromDiagonalPlane(segments_to_order, image_size)
    centroids_dp = [];
    for i = 1 : length(segments_to_order)
        centroids_dp(end + 1) = GetDPCentroid(segments_to_order(i), image_size);
    end
    
    [~, sorted_indices] = sort(centroids_dp);
    sorted_segments = segments_to_order(sorted_indices);
end

function centroid_i = GetICentroid(start, image_size)
    tree = start.GetTree;
    centroid = GetCentroid(tree, image_size);
    centroid_i = centroid(1);
end

function centroid_dp = GetDPCentroid(start_segment, image_size)
    tree = start_segment.GetTree;
    centroid = GetCentroid(tree, image_size);
    centroid_dp = - centroid(3) - centroid(1);
end

function centroid = GetCentroid(indices, image_size)
    [i, j, k] = ind2sub(image_size, indices);
    centroid = zeros(1, 3);
    centroid(1) = mean(i);
    centroid(2) = mean(j);
    centroid(3) = mean(k);    
end

