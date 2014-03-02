classdef PTKPanel < PTKUserInterfaceObject
    % PTKPanel. Part of the gui for the Pulmonary Toolkit.
    %
    %     This class is used internally within the Pulmonary Toolkit to help
    %     build the user interface.
    %
    %     PTKPanel is used to build panels with the user interface.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    properties (Access = protected)
        Reporting
    end
    
    methods
        function obj = PTKPanel(parent_handle, reporting)
            obj = obj@PTKUserInterfaceObject(parent_handle);
            if nargin > 1
                obj.Reporting = reporting;
            end
        end
        
        function CreateGuiComponent(obj, position, reporting)
            obj.GraphicalComponentHandle = uipanel('Parent', obj.Parent.GetContainerHandle(reporting), 'BorderType', 'none', 'Units', 'pixels', ...
                'BackgroundColor', PTKSoftwareInfo.BackgroundColour, 'ForegroundColor', 'white', 'ResizeFcn', '', 'Position', position);
        end
    end

end