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
    
    methods
        function MouseHasMoved(obj, viewer_panel, screen_coords, last_coords, mouse_is_down)
            if mouse_is_down
                [min_coords, max_coords] = viewer_panel.GetImageLimits;
                coords_offset = screen_coords - last_coords;
                
                x_range = max_coords(1) - min_coords(1);
                x_relative_movement = coords_offset(1)/x_range;
                
                y_range = max_coords(2) - min_coords(2);
                y_relative_movement = coords_offset(2)/y_range;
                
                new_window = viewer_panel.Window + x_relative_movement*100*30;
                viewer_panel.SetWindowWithinLimits(new_window);
                
                new_level = viewer_panel.Level + y_relative_movement*100*30;
                viewer_panel.SetLevelWithinLimits(new_level);
            end
        end
        
        function processed = Keypress(obj, key_name)
            processed = false;
        end
        
        function MouseDown(obj, screen_coords)
        end
        
        function MouseUp(obj, screen_coords)
        end
        
        function Enable(obj, enabled)
        end
        
        
        function NewSliceOrOrientation(obj)
        end
        
        function ImageChanged(obj)
        end
        
    end
    
end

