classdef PTKCompositePanel < PTKUserInterfaceObject
    % PTKCompositePanel.  Part of the gui for the Pulmonary Toolkit.
    %
    %     This class is used internally within the Pulmonary Toolkit to help
    %     build the user interface.
    %
    %     PTKAllPatientsPanel represents the panel in the Patient Browser
    %     showing all datasets grouped by patient.
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
    
    properties (Access = private)
        Panels
        CachedHeight
    end
    
    methods
        function obj = PTKCompositePanel(parent, reporting)
            obj = obj@PTKUserInterfaceObject(parent);
            obj.Reporting = reporting;
            obj.Panels = [];
        end
        
        function CreateGuiComponent(obj, position, reporting)
            % There is no underlying graphical object to create
        end
        
        function Resize(obj, new_position)
            Resize@PTKUserInterfaceObject(obj, new_position);
            
            panel_width = new_position(3);
            y_coord_from_top = 1;
            parent_panel_height = new_position(4) + new_position(2);
            
            total_height = obj.GetRequestedHeight;

            visible_y_min_from_base = - new_position(2);
            visible_y_max_from_base = visible_y_min_from_base + parent_panel_height;
            
            for panel_index = 1 : numel(obj.Panels)
                panel = obj.Panels(panel_index);
                panel_height = panel.GetRequestedHeight;
                panel.CachedMinY = y_coord_from_top;
                panel.CachedMaxY = y_coord_from_top + panel_height;

                panel_max_y_from_base = total_height - y_coord_from_top;
                panel_min_y_from_base = total_height - (y_coord_from_top + panel_height);

                panel_y_coord = panel_min_y_from_base + new_position(2);
                
                panel_size = [1, panel_y_coord, panel_width, panel_height];
                panel.Resize(panel_size);

                % Determine if current panel is visible
                panel_is_visible = (panel_min_y_from_base < visible_y_max_from_base) && (panel_max_y_from_base > visible_y_min_from_base);

                if panel_is_visible
                    panel.Enable(obj.Reporting);
                else
                    panel.Disable;
                end

                y_coord_from_top = y_coord_from_top + panel_height;

            end
        end
        
        function height = GetRequestedHeight(obj)
            if ~isempty(obj.CachedHeight)
                height = obj.CachedHeight;
            else
                height = 0;
                for panel = obj.Panels
                    height = height + panel.GetRequestedHeight;
                end
                obj.CachedHeight = height;
            end
        end
        
    end
    
    methods (Access = protected)
        
        function child_coords = ParentToChildCoordinates(obj, parent_coords)
            child_coords = parent_coords;
        end
        
        function AddPanel(obj, panel)
            obj.Panels = [obj.Panels, panel];
            obj.AddChild(panel);
            obj.CachedHeight = [];
        end
        
        function RemoveAllPanels(obj)
            for panel = obj.Panels
                delete(panel);
            end
            
            obj.Children = [];
            obj.Panels = [];
            obj.CachedHeight = [];
        end
    end
end