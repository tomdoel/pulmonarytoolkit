function results_image = PTKGetPrunedSegmentalAirwayImageFromCentreline(segmental_centreline_tree, unpruned_segmental_centreline_tree, airway_root, template, colour_by_segment_index)
    % PTKGetPrunedSegmentalAirwayImageFromCentreline. 
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    segments_struct = segmental_centreline_tree.Segments;
    segments = [segments_struct.UpperLeftSegments, segments_struct.LowerLeftSegments, ...
        segments_struct.UpperRightSegments, segments_struct.MiddleRightSegments, segments_struct.LowerRightSegments];
    
    unpruned_segments_struct = unpruned_segmental_centreline_tree.Segments;
    unpruned_segments = [unpruned_segments_struct.UpperLeftSegments, unpruned_segments_struct.LowerLeftSegments, ...
        unpruned_segments_struct.UpperRightSegments, unpruned_segments_struct.MiddleRightSegments, unpruned_segments_struct.LowerRightSegments];
    
    child_bronchi = [];
    for segment_index = 1 : length(unpruned_segments)
        child_bronchi = [child_bronchi, unpruned_segments(segment_index).Children];
    end    
    
    results_image = PTKGetPrunedAirwayImageFromCentreline(segments, child_bronchi, airway_root, template, colour_by_segment_index);
end