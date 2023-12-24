classdef MimViewerPanelWithControlPanel < MimViewerPanel
    % MimViewerPanelWithControlPanel. Creates a MimViewerPanel window with
    % a basic toolbar
    %
    %
    %
    % .. Licence
    %    -------
    %    Part of the TD MIM Toolkit. https://github.com/tomdoel
    %    Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %    Distributed under the MIT licence. Please see website for details.
    %
    
    properties (SetAccess = private)
        ControlPanelHeight = 33
    end
    
    properties (Access = private)
        ControlPanel
    end
    
    methods
        function obj = MimViewerPanelWithControlPanel(parent)
            obj = obj@MimViewerPanel(parent);
            
            % Create the control panel
            obj.ControlPanel = MimViewerPanelToolbar(obj);
            obj.AddChild(obj.ControlPanel);
        end
        
        function Resize(obj, position)
            % Resize the viewer panel and its subcomponents
            
            Resize@GemPanel(obj, position);
            
            % Position axes and slice slider
            parent_width_pixels = position(3);
            parent_height_pixels = position(4);
            image_width = parent_width_pixels;
            
            control_panel_height = obj.ControlPanelHeight;
            control_panel_width = image_width;
            
            image_height = max(1, parent_height_pixels - control_panel_height);
            
            control_panel_position = [1, 1, control_panel_width, control_panel_height];
            image_panel_position = [1, 1 + control_panel_height, image_width, image_height];
            
            % Resize the image and slider
            obj.ViewerPanelMultiView.Resize(image_panel_position);
            
            % Resize the control panel
            obj.ControlPanel.Resize(control_panel_position);
        end
    end
end