classdef PTKCoord
    % PTKCoord. A class for storing voxel coordinates
    %
    %     PTKCoord stores the coordinates of a voxel in global PTK coordinates.
    %     These are Matlab subscripts (I-J-K, corresponding to Y-X-Z), numbered
    %     from [1,1,1].
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    properties
        CoordI
        CoordJ
        CoordK
    end
    
    methods
        function obj = PTKCoord(c_i, c_j, c_k)
            if nargin > 0
                obj.CoordI = c_i;
                obj.CoordJ = c_j;
                obj.CoordK = c_k;
            end
        end
    end 
end

