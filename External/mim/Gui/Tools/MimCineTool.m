classdef MimCineTool < MimTool
    % MimCineTool. A tool for interactively moving through slices
    %
    %     MimCineTool is a tool class used with GemCinePanel to allow the user
    %     to cine through an image using mouse controls.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD MIM Toolkit. https://github.com/tomdoel
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %
        
    properties
        ButtonText = 'Cine'
        Cursor = 'arrow'
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
        function obj = MimCineTool(image_parameters, callback)
            obj.Callback = callback;
            obj.ImageParameters = image_parameters;
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
        
        function NewOrientation(obj)
            obj.StartCoords = [];
            obj.StartKPosition = [];
        end
        
        function ImageChanged(obj)
            obj.StartCoords = [];
            obj.StartKPosition = [];
        end
        
        function Enter(obj)
            obj.StartCoords = [];
            obj.StartKPosition = [];
        end   
    end
end

