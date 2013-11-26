classdef PTKCoords < handle
    % PTKCoords. Class for storing a set of PTKCoord coordinates.
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
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
