classdef PTKRegionDefinition
    % PTKCoords. Class for storing information about a defined region within an image
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
   
    properties
        ColormapIndex
        RegionNumber
        DistanceFromOrigin
        Coordinates
    end
    
    methods
        function obj = PTKRegionDefinition(index, number, distance, coordinates)
            if nargin > 0
                obj.ColormapIndex = index;
                obj.RegionNumber = number;
                obj.DistanceFromOrigin = distance;
                obj.Coordinates = coordinates;
            end
        end
    end
end
