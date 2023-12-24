classdef MimMarkerPoint
    %MimMarkerPoint Used in exporting of marker points to disk
    %
    % .. Licence
    %    -------
    %    Part of the TD MIM Toolkit. https://github.com/tomdoel
    %    Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %    Distributed under the MIT licence. Please see website for details.
    % 
    properties
        X
        Y
        Z
        Label
    end
    
    methods
        function obj = MimMarkerPoint(x, y, z, label)
            if nargin > 0
                obj.X = x;
                obj.Y = y;
                obj.Z = z;
                obj.Label = label;
            end
        end
    end
end

