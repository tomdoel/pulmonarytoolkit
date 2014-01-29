function segments = PTKGetPulmonarySegments(lobes, acinar_map, reporting)
    % PTKPulmonarySegments. 
    %
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    segments = lobes.BlankCopy;
    segments.ChangeRawImage(zeros(lobes.ImageSize, 'uint8'));
    
    lobe_labels = [1, 2, 4, 5, 6];
    segmental_labels = {[1,2,3], [4,5], [6,7,8,9,10], [11,12,13,14,15], [16,18,19,20]};
    
    for lobe_index = 1 : 5
        lobe_label = lobe_labels(lobe_index);
        lobe_mask = lobes.BlankCopy;
        lobe_mask.ChangeRawImage(lobes.RawImage == lobe_label);
        segments_map = ComputeSmoothedSegmentsForLobe(lobe_mask, acinar_map, segmental_labels{lobe_index}, reporting);
        segments.ChangeSubImageWithMask(segments_map, lobe_mask);
    end
end
function segment_map = ComputeSmoothedSegmentsForLobe(lobe_mask, acinar_map, segmental_labels, reporting)
    smoothing_size_mm = 20;
    template = lobe_mask.BlankCopy;
    lobe_mask.CropToFit;
    acinar_map_cropped = acinar_map.Copy;
    acinar_map_cropped.ResizeToMatch(lobe_mask);
    starting_indices = [];
    for segment_index = 1 : numel(segmental_labels)
        segment_label = segmental_labels(segment_index);
        segmental_indices = find(acinar_map_cropped.RawImage == segment_label);
        global_segmental_indices = acinar_map_cropped.LocalToGlobalIndices(segmental_indices);
        starting_indices{segment_index} = global_segmental_indices;
    end
    segment_map = PTKSmoothedRegionGrowing(lobe_mask, starting_indices, smoothing_size_mm, reporting);
    segment_map_raw = zeros(segment_map.ImageSize, 'uint8');
    for segment_index = 1 : numel(segmental_labels)
        segment_map_raw(segment_map.RawImage == segment_index) = segmental_labels(segment_index);
    end
    segment_map.ChangeRawImage(segment_map_raw);
    segment_map.ChangeRawImage(segment_map.RawImage.*uint8(lobe_mask.RawImage > 0));
    
    segment_map.ResizeToMatch(template);
    
end