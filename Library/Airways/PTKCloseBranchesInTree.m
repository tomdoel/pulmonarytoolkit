function airway_tree = PTKCloseBranchesInTree(airway_tree, closing_size_mm, image_size, reporting)
    % PTKCloseBranchesInTree. Takes a segmented airway tree and
    %     performs a morphological closing on each segment, and between each segment
    %     and its child segments.
    %
    % This function is used by PTKAirwayRegionGrowingWithExplosionControl.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    if ~exist('reporting', 'var')
        reporting = [];
    end

    number_of_segments = airway_tree.CountBranches;
    
    reporting.ShowProgress('Closing branches in the airway tree');
    segments_to_do = airway_tree;
    segment_index = 0;
    
    while ~isempty(segments_to_do)
        segment = segments_to_do(end);
        segments_to_do(end) = [];
        segments_to_do = [segments_to_do, segment.Children];
        
        if ~isempty(reporting)
            if reporting.HasBeenCancelled
                reporting.Error(PTKSoftwareInfo.CancelErrorId, 'User cancelled');
            end
            
            progress_value = round(100*(segment_index/number_of_segments));
            reporting.UpdateProgressValue(progress_value);
        end
        segment_index = segment_index + 1;
        
        CloseSegment(segment, closing_size_mm, image_size);
    end
end

function CloseSegment(segment, closing_size_mm, image_size)
    voxel_indices = segment.GetAcceptedVoxels;
    
    if ~isempty(voxel_indices)
        all_points = GetClosedIndicesForSegmentAndChildren(segment, closing_size_mm, image_size);
        new_points = setdiff(all_points, voxel_indices);
        segment.AddClosedPoints(unique(new_points));
    end
end

function result_points = GetClosedIndicesForSegmentAndChildren(current_segment, closing_size_mm, image_size)
    segment_indices = current_segment.GetAcceptedVoxels;
    if isempty(current_segment.Children)
        result_points = GetClosedIndices(segment_indices, closing_size_mm, image_size);
    else
        result_points = [];
        for child_segment  = current_segment.Children
            child_indices = child_segment.GetAcceptedVoxels;
            all_indices = [segment_indices, child_indices];
            new_points_all = GetClosedIndices(all_indices, closing_size_mm, image_size);
            new_points_children = GetClosedIndices(child_indices, closing_size_mm, image_size);
            
            new_points = setdiff(new_points_all, new_points_children);
            result_points = [result_points; new_points];
        end
    end
    result_points = unique(result_points);
end

function new_points = GetClosedIndices(voxel_indices, closing_size_mm, image_size)
    [offset, segment_image, ~] = PTKImageCoordinateUtilities.GetMinimalImageForIndices(voxel_indices, image_size);
    border_size = 3;
    bordered_segment_image = PTKImage(segment_image);
    bordered_segment_image.AddBorder(border_size);
    bordered_segment_image.BinaryMorph(@imclose, closing_size_mm);
    
    border_offset = border_size;
    bordered_image_size = bordered_segment_image.ImageSize;
    all_points = find(bordered_segment_image.RawImage(:));
    new_points = PTKImageCoordinateUtilities.OffsetIndices(int32(all_points), -border_offset + int32(offset), int32(bordered_image_size), int32(image_size));
end

