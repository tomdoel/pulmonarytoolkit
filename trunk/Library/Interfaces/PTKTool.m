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
        
        MouseHasMoved(obj, viewer_panel, screen_coords, last_coords, mouse_is_down)
        MouseDown(obj, screen_coords)
        MouseUp(obj, screen_coords)
        Enable(obj, enabled)
        NewSliceOrOrientation(obj)
        ImageChanged(obj)
        OverlayImageChanged(obj)
        Keypress(obj, key_name)
                
    end
    
end

