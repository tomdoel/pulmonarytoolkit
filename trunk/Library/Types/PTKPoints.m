classdef PTKPoints < handle
    % PTKPoints. Class for storing point coordinates.
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
   
    properties
        Coords
    end
    
    methods
        function obj = PTKPoints(coords)
            if nargin > 0
                obj.Coords = coords;
            end
        end
    end
end
