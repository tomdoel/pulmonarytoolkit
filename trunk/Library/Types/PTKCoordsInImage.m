classdef PTKCoordsInImage < handle
    % PTKCoordsInImage. Class for storing a set of coordinates and whether
    % they are inside an image
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
   
    properties
        Coords
        InImage
    end
    
    methods
        function obj = PTKCoordsInImage(coords, in_image)
            if nargin > 0
                obj.Coords = coords;
                obj.InImage = in_image;
            end
        end
    end
end
