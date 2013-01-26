classdef TDPoint
    % TDPoint. A class for storing points
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
    end
    
    methods
        function obj = TDPoint(c_i, c_j, c_k)
            if nargin > 0
                obj.CoordI = c_i;
                obj.CoordJ = c_j;
                obj.CoordK = c_k;
            end
        end
    end 
end

