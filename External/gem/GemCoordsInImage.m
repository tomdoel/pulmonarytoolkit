classdef GemCoordsInImage < handle
    % Class for storing a set of coordinates and whetherthey are inside an image
    %
    %
    % .. Licence
    %    -------
    %    Part of GEM. https://github.com/tomdoel/gem
    %    Author: Tom Doel, 2014.  www.tomdoel.com
    %    Distributed under the MIT licence. Please see website for details.
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
