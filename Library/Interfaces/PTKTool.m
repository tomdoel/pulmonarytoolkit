classdef PTKTool < handle
    % PTKTool. Interface for tools which are used with the PTKViewerPanel
    %
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
     
    
    properties (Abstract = true)
        ButtonText
        Cursor
        RestoreKeyPressCallbackWhenSelected
        ShortcutKey
        ToolTip
        Tag
    end
    
    methods (Abstract)
        
        MouseHasMoved(obj, viewer_panel, screen_coords, last_coords)
        MouseDragged(obj, viewer_panel, screen_coords, last_coords)
        MouseDown(obj, screen_coords)
        MouseUp(obj, screen_coords)
        Enable(obj, enabled)
        NewSlice(obj)
        NewOrientation(obj)
        ImageChanged(obj)
        OverlayImageChanged(obj)
        Keypressed(obj, key_name)

    end
    
    methods
        
        function menu = GetContextMenu(obj)
            menu = [];
        end
        
        function is_enabled = IsEnabled(obj, mode, sub_mode)
            is_enabled = true;
        end
        
    end
    
end

