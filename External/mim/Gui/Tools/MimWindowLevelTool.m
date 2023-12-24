classdef MimWindowLevelTool < MimTool
    % MimWindowLevelTool. A tool for interactively changing window and level
    %
    %     MimWindowLevelTool is a tool class to allow the user
    %     to change the window and level of an image using the mouse.
    %
    %
    % .. Licence
    %    -------
    %    Part of the TD MIM Toolkit. https://github.com/tomdoel
    %    Author: Tom Doel, 2013.  www.tomdoel.com
    %    Distributed under the MIT licence. Please see website for details.
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
        ContextMenu
        ViewerPanel
    end
    
    methods
        function obj = MimWindowLevelTool(image_display_parameters, callback, viewer_panel)
            obj.Callback = callback;
            obj.ViewerPanel = viewer_panel;
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
        
        function menu = GetContextMenu(obj)
            % Disable W/L context menu because it interferes with zoom
            % shortcut
            menu = [];
%             if isempty(obj.ContextMenu)
%                 figure_handle = obj.ViewerPanel.GetParentFigure.GetContainerHandle;
%                 obj.ContextMenu = uicontextmenu('Parent', figure_handle);
%                 menu_bone = @(x, y) obj.ChangeWLCallback(x, y, 2000, 300);
%                 menu_lung = @(x, y) obj.ChangeWLCallback(x, y, 1600, -600);
%                 menu_soft = @(x, y) obj.ChangeWLCallback(x, y, 350, 40);
%                 
%                 uimenu(obj.ContextMenu, 'Label', 'Set window and level:', 'Separator', 'off', 'Enable', 'off');
%                 uimenu(obj.ContextMenu, 'Label', '  Lung', 'Callback', menu_lung);
%                 uimenu(obj.ContextMenu, 'Label', '  Bone', 'Callback', menu_bone);
%                 uimenu(obj.ContextMenu, 'Label', '  Soft Tissue', 'Callback', menu_soft);
%                 uimenu(obj.ContextMenu, 'Label', '  Image', 'Callback', @obj.WLImageCallback);
%             end
%             
%             menu = obj.ContextMenu;
        end
        
        function ChangeWLCallback(obj, ~, ~, window, level)
            obj.ViewerPanel.Window = window;
            obj.ViewerPanel.Level = level;
        end
        
        function WLImageCallback(obj, ~, ~)
            background_image = obj.ViewerPanel.BackgroundImage;
            if isa(background_image, 'PTKDicomImage') && isfield(background_image.MetaHeader, 'WindowWidth') && isfield(background_image.MetaHeader, 'WindowCenter')
                obj.ViewerPanel.Window = background_image.MetaHeader.WindowWidth(1);
                obj.ViewerPanel.Level = background_image.MetaHeader.WindowCenter(1);
            end
        end
    end
    
end

