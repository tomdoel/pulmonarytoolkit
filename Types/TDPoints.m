classdef TDPoints < handle
   
    properties
        Coords
    end
    
    methods
        function obj = TDPoints(coords)
            if nargin > 0
                obj.Coords = coords;
                if nargin > 1
                    error;
                end
            end
        end
    end
end
