classdef PTKCineTool < PTKTool
    % PTKCineTool. A tool for interactively moving through slices an image with PTKViewerPanel
    %
    %     PTKCineTool is a tool class used with PTKViewerPanel to allow the user
    %     to cine through an image using mouse controls.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
        
    properties
        ButtonText = 'Cine'
        Cursor = 'arrow'
        RestoreKeyPressCallbackWhenSelected = false
        ToolTip = 'Cine tool. Drag mouse to cine through slices.'
        Tag = 'Cine'
        ShortcutKey = 'n'
    end
    
    methods
        function MouseHasMoved(obj, viewer_panel, screen_coords, last_coords, mouse_is_down)
            if mouse_is_down
                [min_coords, max_coords] = viewer_panel.GetImageLimits;
                coords_offset = screen_coords - last_coords;
                
                y_range = max_coords(2) - min_coords(1);
                y_relative_movement = coords_offset(2)/y_range;
                direction = sign(y_relative_movement);
                y_relative_movement = abs(y_relative_movement);
                y_relative_movement = 100*y_relative_movement;
                y_relative_movement = ceil(y_relative_movement);
                
                k_position = viewer_panel.SliceNumber(viewer_panel.Orientation);
                k_position = k_position - direction*y_relative_movement;
                viewer_panel.SliceNumber(viewer_panel.Orientation) = k_position;
            end
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
        
        function OverlayImageChanged(obj)
        end
              
        function processed = Keypress(obj, key_name)
            processed = false;
        end
        
    end
    
end

