classdef PTKPoint
    % PTKPoint. A class for storing points
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    properties
        CoordX
        CoordY
        CoordZ
    end
    
    methods
        function obj = PTKPoint(c_x, c_y, c_z)
            if nargin > 0
                obj.CoordX = c_x;
                obj.CoordY = c_y;
                obj.CoordZ = c_z;
            end
        end
    end 
end

