classdef PTKCentrelinePoint < PTKPoint
    % PTKCentrelinePoint. A class for storing points on the centreline
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    properties
        GlobalIndex
        Radius
    end
    
    methods
        function obj = PTKCentrelinePoint(c_i, c_j, c_k, radius, global_index)
            obj = obj@PTKPoint(c_i, c_j, c_k);
            obj.Radius = radius;
            obj.GlobalIndex = global_index;
        end
    end
    
end

