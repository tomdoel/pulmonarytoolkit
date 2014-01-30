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
    
    methods (Static)
        function diff = Difference(point_1, point_2)
            diff = PTKPoint(point_1.CoordX - point_2.CoordX, point_1.CoordY - point_2.CoordY, point_1.CoordZ - point_2.CoordZ);
        end
        
        function mag = Magnitude(point)
            mag = norm([point.CoordX, point.CoordY, point.CoordZ]);
        end

        function point = SetCoordinate(point, dimension, value)
            switch dimension
                case PTKImageOrientation.Coronal
                    point.CoordY = value;
                case PTKImageOrientation.Sagittal
                    point.CoordX = value;
                case PTKImageOrientation.Axial
                    point.CoordZ = value;
                otherwise
                    error('Unknown dimension');
            end
        end
    end
end

