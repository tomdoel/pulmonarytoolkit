classdef GemCoordsInImage < handle
    % GemCoordsInImage. Class for storing a set of coordinates and whether
    % they are inside an image
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
   
    properties
        Coords
        InImage
    end
    
    methods
        function obj = GemCoordsInImage(coords, in_image)
            if nargin > 0
                obj.Coords = coords;
                obj.InImage = in_image;
            end
        end
    end
end
