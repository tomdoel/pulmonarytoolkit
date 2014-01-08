classdef PTKAirwayGeneratorApex < handle
    % PTKAirwayGeneratorApex. Structure used by PTKAirwayGenerator
    %
    % PTKAirwayGeneratorApex is used to temporarily store airway tree endpoints
    % as part of the volume-filling airway growing algorithm.
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    properties
        AirwayGrowingTreeSegment   % The terminal tree segment
        PointCloud                 % The points this tree will grow in to
        IsGrowingApex              % Determines whether this apex can grow
    end
    
    methods
        function obj = PTKAirwayGeneratorApex(tree_segment, point_cloud, is_growing)
            if nargin > 0
                obj.AirwayGrowingTreeSegment = tree_segment;
                obj.PointCloud = point_cloud;
                obj.IsGrowingApex = is_growing;
            end
        end
    end
end