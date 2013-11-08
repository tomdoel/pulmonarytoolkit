function results_image = PTKGetAirwaysPrunedBySegment(start_branches, airway_results, airway_image)
    % PTKGetAirwaysPrunedBySegment. Prunes branches from an airway
    %     tree according tp the pulmonary segments
    %
    %
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
                
    PruneAirways(start_branches.Segments.UpperLeftSegments);
    PruneAirways(start_branches.Segments.LowerLeftSegments);
    PruneAirways(start_branches.Segments.UpperRightSegments);
    PruneAirways(start_branches.Segments.MiddleRightSegments);
    PruneAirways(start_branches.Segments.LowerRightSegments);
    
    % Split trifurcations into multiple bifurcations
    start_branches.Trachea.RemoveMultipleBifurcations;
    
    % Generate results image
    segments = start_branches.Segments;
    all_segments = [segments.UpperLeftSegments, segments.LowerLeftSegments, ...
        segments.UpperRightSegments, segments.MiddleRightSegments, segments.LowerRightSegments];
    template = airway_image;
    results_image = PTKGetAirwayImageFromCentreline(all_segments, airway_results.AirwayTree, template, false);
    results_image.ImageType = PTKImageType.Colormap;
end

function PruneAirways(segments)
    for airway = segments
        airway.RemoveChildren;
    end
end