function start_branches = PTKPruneAirwaysBySegment(start_branches)
    % PTKPruneAirwaysBySegment. Prunes branches from an airway
    %     tree at the end of each segmental bronchus
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
end

function PruneAirways(segments)
    for airway = segments
        airway.RemoveChildren;
    end
end