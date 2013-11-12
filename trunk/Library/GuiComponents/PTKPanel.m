classdef PTKPanel < PTKUserInterfaceObject
    % PTKPanel. Part of the gui for the Pulmonary Toolkit.
    %
    %     This class is used internally within the PUlmonary Toolkit to help
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
        ParentHandle
        PanelHandle
        Reporting
    end
    
    methods
        function obj = PTKPanel(parent_handle, reporting)
            obj.ParentHandle = parent_handle;
            obj.Reporting = reporting;
            obj.PanelHandle = uipanel('Parent', parent_handle, 'BorderType', 'none', 'Units', 'pixels', ...
                'BackgroundColor', PTKSoftwareInfo.BackgroundColour, 'ForegroundColor', 'white', 'ResizeFcn', '');
        end
        
        function Resize(obj, new_size)
            set(obj.PanelHandle, 'Position', new_size);
        end
    end

end