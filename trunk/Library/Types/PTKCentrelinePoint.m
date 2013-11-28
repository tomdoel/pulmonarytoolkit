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
        Parameters
    end
    
    methods
        function obj = PTKCentrelinePoint(c_x, c_y, c_z, parameters)
            obj = obj@PTKPoint(c_x, c_y, c_z);
            if nargin > 3 && ~isempty(parameters)
                for field = fieldnames(parameters)'
                    obj.Parameters.(field{1}) = parameters.(field{1});
                end
            end
        end
    end
    
end

