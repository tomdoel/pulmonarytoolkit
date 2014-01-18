classdef PTKPanTool < PTKTool
    % PTKPanTool. A tool for interactively panning an image with PTKViewerPanel
    %
    %     PTKPanTool is a tool class used with PTKViewerPanel to allow the user
    %     to pan an image using mouse and keyboard controls.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    properties
        ButtonText = 'Pan'
        Cursor = 'hand'
        RestoreKeyPressCallbackWhenSelected = false
        ToolTip = 'Pan tool'
        Tag = 'Pan'
        ShortcutKey = ''
    end
    
    properties (Access = private)
    end
    
    methods
        function MouseHasMoved(obj, viewer_panel, screen_coords, last_coords, mouse_is_down)
            if mouse_is_down
                [min_coords, max_coords] = viewer_panel.GetImageLimits;
                pan_offset = screen_coords - last_coords;
                x_lim = [min_coords(1), max_coords(1)];
                x_lim = x_lim - pan_offset(1);
                y_lim = [min_coords(2), max_coords(2)];
                y_lim = y_lim - pan_offset(2);
                
                viewer_panel.SetImageLimits([x_lim(1), y_lim(1)], [x_lim(2), y_lim(2)]);
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

