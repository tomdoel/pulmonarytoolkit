classdef PTKZoomTool < PTKTool
    % PTKZoomTool. A tool for interactively zooming an image with PTKViewerPanel
    %
    %     PTKZoomTool is a tool class used with PTKViewerPanel to allow the user
    %     to zoom an image using mouse and keyboard controls.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
        
    properties
        ButtonText = 'Zoom'
        Cursor = 'circle'
        RestoreKeyPressCallbackWhenSelected = false
        ToolTip = 'Zoom tool'
        Tag = 'Zoom'
    end
    
    methods
        function MouseHasMoved(obj, viewer_panel, screen_coords, last_coords, mouse_is_down)
            if mouse_is_down
                [min_coords, max_coords] = viewer_panel.GetImageLimits;
                x_range = max_coords(1) - min_coords(1);
                y_range = max_coords(2) - min_coords(2);
                
                coords_offset = screen_coords - last_coords;
                
                y_relative_movement = coords_offset(2)/y_range;
                
                relative_scale = y_relative_movement;
                x_range_scale = relative_scale*x_range/1;
                y_range_scale = relative_scale*y_range/1;
                
                x_lim = [min_coords(1) - x_range_scale, max_coords(1) + x_range_scale];
                
                y_lim = [min_coords(2) - y_range_scale, max_coords(2) + y_range_scale];
                
                if (abs(x_lim(2) - x_lim(1)) > 10) && (abs(y_lim(2) - y_lim(1)) > 10) && ...
                        (abs(x_lim(2) - x_lim(1)) < 1000) && (abs(y_lim(2) - y_lim(1)) < 800)
                    viewer_panel.SetImageLimits([x_lim(1), y_lim(1)], [x_lim(2), y_lim(2)]);
                end
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
        
        function processed = Keypress(obj, key_name)
            processed = false;
        end
        
    end
    
end

