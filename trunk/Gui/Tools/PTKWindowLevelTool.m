classdef PTKWindowLevelTool < PTKTool
    % PTKWindowLevelTool. A tool for interactively changing window and level with PTKViewerPanel
    %
    %     PTKWindowLevelTool is a tool class used with PTKViewerPanel to allow the user
    %     to change the window and level of an image using the mouse.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    properties
        ButtonText = 'W/L'
        Cursor = 'arrow'
        RestoreKeyPressCallbackWhenSelected = false
        ToolTip = 'Window/level tool. Drag mouse to change window and level.'
        Tag = 'W/L'
        ShortcutKey = 'w'
    end
    
    properties (Access = private)
        ViewerPanel
        StartCoords
        StartWindow
        StartLevel
    end
    
    methods
        function obj = PTKWindowLevelTool(viewer_panel)
            obj.ViewerPanel = viewer_panel;
        end
        
        function MouseHasMoved(obj, viewer_panel, screen_coords, last_coords)
        end
        
        function MouseDragged(obj, viewer_panel, screen_coords, last_coords)
            if ~isempty(obj.StartCoords)            
                [min_coords, max_coords] = viewer_panel.GetImageLimits;
                coords_offset = screen_coords - obj.StartCoords;
                
                x_range = max_coords(1) - min_coords(1);
                x_relative_movement = coords_offset(1)/x_range;
                
                y_range = max_coords(2) - min_coords(2);
                y_relative_movement = coords_offset(2)/y_range;
                
                new_window = obj.StartWindow + x_relative_movement*100*30;
                viewer_panel.SetWindowWithinLimits(new_window);
                
                new_level = obj.StartLevel + y_relative_movement*100*30;
                viewer_panel.SetLevelWithinLimits(new_level);
            end
        end
        
        function processed = Keypressed(obj, key_name)
            processed = false;
        end
        
        function MouseDown(obj, screen_coords)
            obj.StartCoords = screen_coords;
            obj.StartWindow = obj.ViewerPanel.Window;
            obj.StartLevel = obj.ViewerPanel.Level;
        end
        
        function MouseUp(obj, screen_coords)
        end
        
        function Enable(obj, enabled)
        end
        
        function NewSlice(obj)
            obj.StartCoords = [];
            obj.StartWindow = [];
            obj.StartLevel = [];
        end
        
        function NewOrientation(obj)
            obj.StartCoords = [];
            obj.StartWindow = [];
            obj.StartLevel = [];
        end
        
        function ImageChanged(obj)
        end
        
        function OverlayImageChanged(obj)
        end        
        
    end
    
end

