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
        Callback
    end
    
    methods
        
        function obj = PTKZoomMatlabTool(callback)
            obj.Callback = callback;
        end
        
        function MouseHasMoved(obj, screen_coords, last_coords)
        end
        
        function MouseDragged(obj, coords, last_coords)
        end
        
        function MouseDown(obj, screen_coords)
        end
        
        function MouseUp(obj, screen_coords)
        end
        
        function Enable(obj, enabled)
            obj.Callback.EnableZoom(enabled);
        end
        
        function NewSlice(obj)
        end
        
        function NewOrientation(obj)
        end
        
        function ImageChanged(obj)
        end

        function OverlayImageChanged(obj)
        end
        
        function processed = Keypressed(obj, key_name)
            processed = false;
        end        
    end
    
end

