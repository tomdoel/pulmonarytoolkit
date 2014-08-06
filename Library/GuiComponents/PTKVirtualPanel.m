classdef PTKVirtualPanel < PTKUserInterfaceObject
    % PTKVirtualPanel.  Part of the gui for the Pulmonary Toolkit.
    %
    %     This class is used to help build the user interface.
    %
    %     PTKVirtualPanel represents a PTK panel which does not have an underlying
    %     Matlab panel component. In other words, the VirtualPanel acts like a real
    %     panel to PTK, but any Matlab components which act on it are actually
    %     acting on the parent panel handle.
    %
    %     The purpose of a PTKVirtualPanel is to simplify user interface design by
    %     allowing the separation of a panel into smaller panels without introducing
    %     the overhead of creating additional graphical objects.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    

    properties (Access = protected)
        Reporting
    end
    
    methods
        function obj = PTKVirtualPanel(parent, reporting)
            obj = obj@PTKUserInterfaceObject(parent);
            obj.Reporting = reporting;
        end
        
        function CreateGuiComponent(obj, position, reporting)
            % There is no underlying graphical object to create
        end

        function child_coords = ParentToChildCoordinates(obj, parent_coords)
            child_coords = parent_coords;
        end
        
        function parent_coords = ChildToParentCoordinates(obj, child_coords)
            parent_coords = child_coords;
        end        
    end
end