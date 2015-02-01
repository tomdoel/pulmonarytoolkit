classdef PTKMapColourTool < PTKTool
    % PTKMapColourTool. Part of the internal gui for the Pulmonary Toolkit.
    %
    %     You should not use this class within your own code. It is intended to
    %     be used internally within the gui of the Pulmonary Toolkit.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    properties
        ButtonText = 'Map'
        Cursor = 'hand'
        RestoreKeyPressCallbackWhenSelected = false
        ToolTip = 'Manually edit current result.'
        Tag = 'Map'
        ShortcutKey = 'b'
        
        FixedOuterBoundary = true % When this is set to true, the outer boundary cannot be changed
        
        BrushSize = 5 % Minimum size of the gaussian used to adjust the distance tranform
        
        Brush
        
        LockToBorderDistance = 10 % When the mouse is closer to the border then this, the brush will actually be applied on the border
    end
    
    properties (SetAccess = private)
        % Blue, Green, Red, Cyan, Magenta, Yellow, Grey
        Colours = {[0 0 0], [0.4 0.4 1.0], [0 0.8 0], [0.8 0 0], [0 0.8 0.8], [0.9 0 0.9],  [0.8 0.8 0.4], [0.7 0.7 0.7]}
        
        % Keep a record of when we have unsaved changes to markers
        ImageHasChanged = false
    end
    
    properties (Access = private)
        ViewerPanel
        FromColour
        Colour
        Enabled = false
        OverlayChangeLock
        ContextMenu
    end
    
    methods
        function obj = PTKMapColourTool(viewer_panel)
            obj.ViewerPanel = viewer_panel;
            obj.OverlayChangeLock = false;
            obj.InitialiseEditMode;
        end
        
        function is_enabled = IsEnabled(obj, mode, sub_mode)
            is_enabled = ~isempty(mode) && ~isempty(sub_mode) && strcmp(mode, PTKModes.EditMode) && strcmp(sub_mode, PTKSubModes.ColourRemapEditing);
        end
        
        function Enable(obj, enable)
            current_status = obj.Enabled;
            obj.Enabled = enable;
            if enable && ~current_status
                obj.InitialiseEditMode;
            end
        end
        
        function processed = Keypressed(obj, key_name)
            processed = true;
            if strcmpi(key_name, 'space')
                obj.ShowMenu;
            elseif strcmpi(key_name, '0')
                obj.ChangeCurrentColour(0);
            elseif strcmpi(key_name, '1') % one
                obj.ChangeCurrentColour(1);
            elseif strcmpi(key_name, '2')
                obj.ChangeCurrentColour(2);
            elseif strcmpi(key_name, '3')
                obj.ChangeCurrentColour(3);
            elseif strcmpi(key_name, '4')
                obj.ChangeCurrentColour(4);
            elseif strcmpi(key_name, '5')
                obj.ChangeCurrentColour(5);
            elseif strcmpi(key_name, '6')
                obj.ChangeCurrentColour(6);
            elseif strcmpi(key_name, '7')
                obj.ChangeCurrentColour(7);
                
            else
                processed = false;
            end
        end
        
        function ChangeCurrentColour(obj, new_colour)
            obj.Colour = new_colour;
        end
        
        function ShowMenu(obj)
            set(obj.GetContextMenu, 'Visible', 'on');
        end
        
        function NewSlice(obj)
        end
        
        function NewOrientation(obj)
        end
        
        function ImageChanged(obj)
            obj.InitialiseEditMode;
        end
        
        function OverlayImageChanged(obj)
            if obj.Enabled && ~obj.OverlayChangeLock
                obj.InitialiseEditMode;
            end
        end
        
        function InitialiseEditMode(obj)
            obj.Colour = 1;
            if ~isempty(obj.ViewerPanel.OverlayImage)
                if obj.ViewerPanel.OverlayImage.ImageExists
                    obj.Brush = PTKImageUtilities.CreateBallStructuralElement(obj.ViewerPanel.OverlayImage.VoxelSize, obj.BrushSize);
                    
                    if isempty(obj.ViewerPanel.OverlayImage.ColorLabelMap)
                        new_colourmap = 0 : 255;
                        obj.ViewerPanel.OverlayImage.ChangeColorLabelMap(new_colourmap);
                    end
                end
            end
        end
        
        function MouseDown(obj, coords)
            if obj.Enabled
                if obj.ViewerPanel.OverlayImage.ImageExists
                    obj.StartBrush(coords);
                end
            end
        end
        
        function MouseUp(obj, coords)
            if obj.Enabled
            end
        end
        
        function StartBrush(obj, coords)
            global_image_coords = round(obj.GetGlobalImageCoordinates(coords));
            local_image_coords = obj.ViewerPanel.OverlayImage.GlobalToLocalCoordinates(global_image_coords);
            
            
            segmentation_colour = obj.ViewerPanel.OverlayImage.RawImage(local_image_coords(1), local_image_coords(2), local_image_coords(3));
            
            if (segmentation_colour == 0)
                segmentation_colour = obj.GetClosestColour2D(local_image_coords);
            end
            
            if (segmentation_colour == 0)
                return;
            end
            
            obj.FromColour = segmentation_colour;
            
            colourmap = obj.ViewerPanel.OverlayImage.ColorLabelMap;
            colourmap(obj.FromColour + 1) = obj.Colour;
            
            child_label_map = obj.ViewerPanel.OverlayImage.ColourLabelChildMap;
            parent_label_map = obj.ViewerPanel.OverlayImage.ColourLabelParentMap;
            
            % Label all child components with the same colour
            if ~isempty(child_label_map)
                children_to_do = PTKStack(child_label_map{segmentation_colour});
                while ~children_to_do.IsEmpty
                    next_child_colour = children_to_do.Pop;
                    colourmap(next_child_colour + 1) = obj.Colour;
                    children_to_do.Push(child_label_map{next_child_colour});
                end
            end
            
            % Label all parent components with the multiple component label
            if ~isempty(parent_label_map)
                parent_colour = parent_label_map{segmentation_colour};
                while ~isempty(parent_colour)
                    colourmap(parent_colour + 1) = 7;
                    parent_colour = parent_label_map{parent_colour};
                end
                
                children_to_do = PTKStack(child_label_map{segmentation_colour});
                while ~children_to_do.IsEmpty
                    next_child_colour = children_to_do.Pop;
                    colourmap(next_child_colour + 1) = obj.Colour;
                    children_to_do.Push(child_label_map{next_child_colour});
                end
            end
            
            obj.OverlayChangeLock = true;
            obj.ViewerPanel.OverlayImage.ChangeColorLabelMap(colourmap);
            obj.OverlayChangeLock = false;
            
        end
        
        
        function ChangeColourCallback(obj, ~, ~, colour)
            obj.Colour = colour;
        end
        
        function MouseHasMoved(obj, coords, last_coords)
        end
        
        function MouseDragged(obj, screen_coords, last_coords)
        end
        
        
        function image_coords = GetImageCoordinates(obj, coords)
            image_coords = zeros(1, 3);
            i_screen = coords(2);
            j_screen = coords(1);
            k_screen = obj.ViewerPanel.SliceNumber(obj.ViewerPanel.Orientation);
            
            switch obj.ViewerPanel.Orientation
                case PTKImageOrientation.Coronal
                    image_coords(1) = k_screen;
                    image_coords(2) = j_screen;
                    image_coords(3) = i_screen;
                case PTKImageOrientation.Sagittal
                    image_coords(1) = j_screen;
                    image_coords(2) = k_screen;
                    image_coords(3) = i_screen;
                case PTKImageOrientation.Axial
                    image_coords(1) = i_screen;
                    image_coords(2) = j_screen;
                    image_coords(3) = k_screen;
            end
        end
        
        function global_image_coords = GetGlobalImageCoordinates(obj, coords)
            local_image_coords = obj.GetImageCoordinates(coords);
            global_image_coords = obj.ViewerPanel.BackgroundImage.LocalToGlobalCoordinates(local_image_coords);
        end
        
        function menu = GetContextMenu(obj)
            if isempty(obj.ContextMenu)
                figure_handle = obj.ViewerPanel.GetParentFigure.GetContainerHandle;
                obj.ContextMenu = uicontextmenu('Parent', figure_handle);
                menu_erase = @(x, y) obj.ChangeColourCallback(x, y, 0);
                menu_blue = @(x, y) obj.ChangeColourCallback(x, y, 1);
                menu_green = @(x, y) obj.ChangeColourCallback(x, y, 2);
                menu_red = @(x, y) obj.ChangeColourCallback(x, y, 3);
                menu_cyan = @(x, y) obj.ChangeColourCallback(x, y, 4);
                menu_magenta = @(x, y) obj.ChangeColourCallback(x, y, 5);
                menu_yellow = @(x, y) obj.ChangeColourCallback(x, y, 6);
                menu_grey = @(x, y) obj.ChangeColourCallback(x, y, 7);
                
                uimenu(obj.ContextMenu, 'Label', '  Erase', 'Callback', menu_erase, 'ForegroundColor', obj.Colours{1});
                uimenu(obj.ContextMenu, 'Label', 'Change lobe to:', 'Separator', 'on', 'Enable', 'off');
                uimenu(obj.ContextMenu, 'Label', '  Right upper', 'Callback', menu_blue, 'ForegroundColor', obj.Colours{2});
                uimenu(obj.ContextMenu, 'Label', '  Right middle', 'Callback', menu_green, 'ForegroundColor', obj.Colours{3});
                uimenu(obj.ContextMenu, 'Label', '  Uncertain', 'Callback', menu_red, 'ForegroundColor', obj.Colours{4});
                uimenu(obj.ContextMenu, 'Label', '  Right lower', 'Callback', menu_cyan, 'ForegroundColor', obj.Colours{5});
                uimenu(obj.ContextMenu, 'Label', '  Left upper', 'Callback', menu_magenta, 'ForegroundColor', obj.Colours{6});
                uimenu(obj.ContextMenu, 'Label', '  Left lower', 'Callback', menu_yellow, 'ForegroundColor', obj.Colours{7});
                uimenu(obj.ContextMenu, 'Label', '  Multiple', 'Callback', menu_grey, 'ForegroundColor', obj.Colours{8});
            end
            menu = obj.ContextMenu;
        end
        
        function closest_colour = GetClosestColour2D(obj, local_image_coords)
            orientation = obj.ViewerPanel.Orientation;
            switch orientation
                case PTKImageOrientation.Coronal
                    x_coord = local_image_coords(2);
                    y_coord = local_image_coords(3);
                case PTKImageOrientation.Sagittal
                    x_coord = local_image_coords(1);
                    y_coord = local_image_coords(3);
                case PTKImageOrientation.Axial
                    x_coord = local_image_coords(1);
                    y_coord = local_image_coords(2);
                otherwise
                    error('Unsupported dimension');
            end
            
            slice_number = obj.ViewerPanel.SliceNumber(orientation);
            image_slice = obj.ViewerPanel.OverlayImage.GetSlice(slice_number, obj.ViewerPanel.Orientation);
            
            colours = unique(image_slice);
            colours = setdiff(colours, 0);
            
            dts = zeros([size(image_slice), numel(colours)]);
            
            for colour_index = 1 : numel(colours);
                colour = colours(colour_index);
                dts(:, :, colour_index) = bwdist(image_slice == colour);
            end
            distances = dts(x_coord, y_coord, :);
            
            [~, sorted_indices] = sort(distances, 'ascend');
            closest = sorted_indices(1);
            closest_colour = colours(closest);
        end
        
    end
end

