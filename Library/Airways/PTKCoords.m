classdef PTKCoords < handle
    % Class for storing a set of coordinates.
    %
    % .. Licence
    %    -------
    %    Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %    Author: Tom Doel, 2013.  www.tomdoel.com
    %    Distributed under the GNU GPL v3 licence. Please see website for details.
    %
   
    properties
        Coords
    end
    
    methods
        function obj = PTKCoords(coords)
            if nargin > 0
                obj.Coords = coords;
            end
        end
    end
end
