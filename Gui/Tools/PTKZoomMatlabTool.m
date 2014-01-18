classdef PTKZoomMatlabTool < PTKTool
    % PTKZoomMatlabTool. A tool for invoking the Matlab zoom tool with PTKViewerPanel
    %
    %     PTKZoomMatlabTool is a tool class used with PTKViewerPanel to allow the user
    %     to use Matlab's zoom tool.
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
        Cursor = 'arrow'
        RestoreKeyPressCallbackWhenSelected = true
        ToolTip = 'Zoom tool'
        Tag = 'Zoom'
        ShortcutKey = 'z'
    end
    
    properties (Access = private)    
        ViewerPanel
    end
    
    methods
        
        function obj = PTKZoomMatlabTool(viewer_panel)
            obj.ViewerPanel = viewer_panel;
        end
        
        function MouseHasMoved(obj, viewer_panel, screen_coords, last_coords, mouse_is_down)
        end
        
        function MouseDown(obj, screen_coords)
        end
        
        function MouseUp(obj, screen_coords)
        end
        
        function Enable(obj, enabled)
            obj.ViewerPanel.EnableZoom(enabled);
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

