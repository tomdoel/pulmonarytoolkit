classdef PTKPanMatlabTool < PTKTool
    % PTKPanMatlabTool. A tool for invoking the Matlab pan tool with PTKViewerPanel
    %
    %     PTKPanMatlabTool is a tool class used with PTKViewerPanel to allow the user
    %     to use Matlab's pan tool.
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
        Cursor = 'arrow'
        RestoreKeyPressCallbackWhenSelected = true
        ToolTip = 'Pan tool'
        Tag = 'Pan'
        ShortcutKey = 'p'
    end
    
    properties (Access = private)
        Callback
    end
    
    methods
        function obj = PTKPanMatlabTool(callback)
            obj.Callback = callback;
        end
        
        function MouseHasMoved(obj, viewer_panel, screen_coords, last_coords)
        end
        
        function MouseDragged(obj, viewer_panel, screen_coords, last_coords)
        end
        
        function MouseDown(obj, screen_coords)
        end
        
        function MouseUp(obj, screen_coords)
        end
        
        function Enable(obj, enabled)
            obj.Callback.EnablePan(enabled);
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

