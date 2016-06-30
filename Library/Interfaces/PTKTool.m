classdef PTKTool < CoreBaseClass
    % PTKTool. Interface for tools which are used with the PTKViewerPanel
    %
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
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
    
    properties
        Enabled = false 
    end
    
    methods
        function menu = GetContextMenu(obj)
            menu = [];
        end
        
        function is_enabled = IsEnabled(obj, mode, sub_mode)
            is_enabled = true;
        end
    
        function MouseHasMoved(obj, screen_coords, last_coords)
            % Called when the mouse is moved while this tool is
            % active. Note: may be intercepted by a shortcut tool
        end
        
        function MouseDragged(obj, screen_coords, last_coords)
            % Called when the mouse is dragged while this tool is
            % active. Note: may be intercepted by a shortcut tool
        end
        
        function MouseDown(obj, screen_coords)
            % Called when the mouse button is pressed while this tool is
            % active. Note: may be intercepted by a shortcut tool
        end
        
        function MouseUp(obj, screen_coords)
            % Called when the mouse button is released while this tool is
            % active. Note: may be intercepted by a shortcut tool
        end
        
        function NewSlice(obj)
            % Called when the currently visible image slice number changes while this tool is
            % active.
        end
        
        function NewOrientation(obj)
            % Called when the image orientation changes while this tool is
            % active. Respond to this call if your tool depends on the image orientation
        end
        
        function ImageChanged(obj)
            % Called when the image changes while this tool is
            % active. This usually indicates a new image so the tool shoudl
            % be reset
        end
        
        function OverlayImageChanged(obj)
            % Called when the overlay image changes while this tool is
            % active. Be careful not to respond to this event if the tool
            % itself changed the overlay image
        end
        
        function processed = Keypressed(obj, key_name)
            % Called when a key is pressed while this tool is active. Note:
            % the key may be intercepted by a shortcut tool
            processed = false;
        end
        
        function Enter(obj)
            % Called when this tool is about to become the primary tool
        end
        
        function Exit(obj)
            % Called when the primary tool switches to another tool
        end 
    end
    
    methods (Sealed)
        function Enable(obj, enabled)
            if enabled && ~obj.Enabled
                obj.Enter;
            end
            if ~enabled && obj.Enabled
                obj.Exit;
            end
            obj.Enabled = enabled;
        end
    end
end

