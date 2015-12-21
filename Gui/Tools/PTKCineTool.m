classdef PTKCineTool < PTKTool
    % PTKCineTool. A tool for interactively moving through slices
    %
    %     PTKCineTool is a tool class used with GemCinePanel to allow the user
    %     to cine through an image using mouse controls.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
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
    
    properties (Access = private)
        Callback
        ImageParameters
        StartCoords
        StartKPosition
    end
    
    methods
        function obj = PTKCineTool(image_parameters, callback)
            obj.Callback = callback;
            obj.ImageParameters = image_parameters;
        end
    
        function MouseHasMoved(obj, screen_coords, last_coords, mouse_is_down)
        end    

        function MouseDragged(obj, screen_coords, last_coords)
            if ~isempty(obj.StartCoords)
                [min_coords, max_coords] = obj.Callback.GetImageLimits;
                coords_offset = screen_coords -  obj.StartCoords;
                
                y_range = max_coords(2) - min_coords(1);
                y_relative_movement = coords_offset(2)/y_range;
                direction = sign(y_relative_movement);
                y_relative_movement = abs(y_relative_movement);
                y_relative_movement = 100*y_relative_movement;
                y_relative_movement = ceil(y_relative_movement);
                
                k_position = obj.StartKPosition - direction*y_relative_movement;
                obj.ImageParameters.SliceNumber(obj.ImageParameters.Orientation) = k_position;
            end
        end
        
        function MouseDown(obj, screen_coords)
            obj.StartCoords = screen_coords;
            obj.StartKPosition = obj.ImageParameters.SliceNumber(obj.ImageParameters.Orientation);
        end
        
        function MouseUp(obj, screen_coords)
        end
        
        function Enable(obj, enabled)
        end
        
        function NewSlice(obj)
        end
        
        function NewOrientation(obj)
            obj.StartCoords = [];
            obj.StartKPosition = [];
        end
        
        function ImageChanged(obj)
            obj.StartCoords = [];
            obj.StartKPosition = [];
        end
        
        function OverlayImageChanged(obj)
        end
              
        function processed = Keypressed(obj, key_name)
            processed = false;
        end
        
    end
    
end

