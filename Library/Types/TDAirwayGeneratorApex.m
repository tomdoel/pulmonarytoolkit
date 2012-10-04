classdef TDAirwayGeneratorApex < handle
    % TDAirwayGeneratorApex. Structure used by TDAirwayGenerator
    %
    % TDAirwayGeneratorApex is used to temporarily store airway tree endpoints
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
        PointCloud;                % The points this tree will grow in to
    end
    
    methods
        function obj = TDAirwayGeneratorApex(tree_segment, point_cloud)
            obj.AirwayGrowingTreeSegment = tree_segment;
            obj.PointCloud = point_cloud;
        end
    end
end