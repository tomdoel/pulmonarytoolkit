classdef TDCentrelinePoint
    % TDCentrelinePoint. A class for storing points on the centreline
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    properties
        CoordI
        CoordJ
        CoordK
        Radius
    end
    
    methods
        function obj = TDCentrelinePoint(c_i, c_j, c_k, radius)
            obj.CoordI = c_i;
            obj.CoordJ = c_j;
            obj.CoordK = c_k;
            obj.Radius = radius;
        end
    end
    
end

