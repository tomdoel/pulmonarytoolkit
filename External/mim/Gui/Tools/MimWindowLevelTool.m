classdef MimWindowLevelTool < MimTool
    % MimWindowLevelTool. A tool for interactively changing window and level
    %
    %     MimWindowLevelTool is a tool class to allow the user
    %     to change the window and level of an image using the mouse.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    properties
        ButtonText = 'W/L'
        Cursor = 'arrow'
        ToolTip = 'Window/level tool. Drag mouse to change window and level.'
        Tag = 'W/L'
        ShortcutKey = 'w'
    end
    
    properties (Access = private)
        ImageDisplayParameters
        Callback
        StartCoords
        StartWindow
        StartLevel
    end
    
    methods
        function obj = MimWindowLevelTool(image_display_parameters, callback)
            obj.Callback = callback;
            obj.ImageDisplayParameters = image_display_parameters;
        end
        
        function MouseDragged(obj, screen_coords, last_coords)
            if ~isempty(obj.StartCoords)            
                [min_coords, max_coords] = obj.Callback.GetImageLimits;
                coords_offset = screen_coords - obj.StartCoords;
                
                x_range = max_coords(1) - min_coords(1);
                x_relative_movement = coords_offset(1)/x_range;
                
                y_range = max_coords(2) - min_coords(2);
                y_relative_movement = coords_offset(2)/y_range;
                
                new_window = obj.StartWindow + x_relative_movement*100*30;
                obj.Callback.SetWindowWithinLimits(new_window);
                
                new_level = obj.StartLevel + y_relative_movement*100*30;
                obj.Callback.SetLevelWithinLimits(new_level);
            end
        end
        
        function MouseDown(obj, screen_coords)
            obj.StartCoords = screen_coords;
            obj.StartWindow = obj.ImageDisplayParameters.Window;
            obj.StartLevel = obj.ImageDisplayParameters.Level;
        end
        
        function Enter(obj)
            obj.StartCoords = [];
            obj.StartWindow = [];
            obj.StartLevel = [];
        end
        
        function NewSlice(obj)
            obj.StartCoords = [];
            obj.StartWindow = [];
            obj.StartLevel = [];
        end
        
        function NewOrientation(obj)
            obj.StartCoords = [];
            obj.StartWindow = [];
            obj.StartLevel = [];
        end
    end
    
end

