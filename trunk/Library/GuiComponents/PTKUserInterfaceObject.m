classdef PTKUserInterfaceObject < handle
    % PTKUserInterfaceObject. Base class for PTK user interface components
    %
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %

    methods (Abstract)
        Resize(obj, new_size)
    end
    
    methods
        % Returns a value for the height of the object. A null value indicates
        % the height is not important
        function height = GetRequestedHeight(~)
            height = [];
        end
    end 
end