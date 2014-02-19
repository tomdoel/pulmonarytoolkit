classdef PTKReplaceColourTool < PTKTool
    % PTKReplaceColourTool. Part of the internal gui for the Pulmonary Toolkit.
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
        ButtonText = 'Paint'
        Cursor = 'hand'
        RestoreKeyPressCallbackWhenSelected = false
        ToolTip = 'Manually edit current result.'
        Tag = 'Paint'
        ShortcutKey = 'r'
        
    end
    
    properties
        PaintOverBackground = false % When false, acts as a replace brush
        
        BrushSize = 5 % Minimum size of the gaussian used to adjust the distance tranform
        
        Brush
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
    end
    
    methods
        function obj = PTKReplaceColourTool(viewer_panel, axes)
            obj.ViewerPanel = viewer_panel;
            obj.OverlayChangeLock = false;
            obj.InitialiseEditMode;
            
            
            
            figure_handle = ancestor(axes, 'figure');
            obj.AddContextMenu(figure_handle);
            
        end
        
        
        function Enable(obj, enable)
            current_status = obj.Enabled;
            obj.Enabled = enable;
            if enable && ~current_status
                obj.InitialiseEditMode;
            end
        end
        
        function processed = Keypress(obj, key_name)
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
        
        function ShowMenu(obj)
            set(obj.ContextMenu, 'Visible', 'on');
        end
        
        function ChangeCurrentColour(obj, new_colour)
            obj.Colour = new_colour;
        end
        
        function NewSliceOrOrientation(obj)
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
                    
                    % For binary images, switch to paint over mode. For other
                    % images, switch to replace colour mode
                    obj.PaintOverBackground = islogical(obj.ViewerPanel.OverlayImage.RawImage);
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
                        
            if segmentation_colour == 0
                return;
            end
            
            obj.FromColour = segmentation_colour;
            
            obj.ApplyBrush(coords);            
        end
        
        function ApplyBrush(obj, coords)
            segmentation_colour = obj.FromColour;
            
            if ~obj.PaintOverBackground && (segmentation_colour == 0)
                return;
            end
            
            image_size = obj.ViewerPanel.OverlayImage.ImageSize;
            
            global_image_coords = round(obj.GetGlobalImageCoordinates(coords));
            local_image_coords = obj.ViewerPanel.OverlayImage.GlobalToLocalCoordinates(global_image_coords);
            
            
            brush_image = obj.Brush;
            
            local_size = size(brush_image);
            
            
            halfsize = floor(local_size/2);
            midpoint = 1 + halfsize;
            min_coords = local_image_coords - halfsize;
            max_coords = local_image_coords + halfsize;
            
            min_clipping = max(0, 1 - min_coords);
            max_clipping = max(0, max_coords - image_size);
            
            brush_min_coords = 1 + min_clipping;
            brush_max_coords = size(brush_image) - max_clipping;
            clipped_brush = brush_image(brush_min_coords(1) : brush_max_coords(1), brush_min_coords(2) : brush_max_coords(2), brush_min_coords(3) : brush_max_coords(3));
            
            min_coords = max(1, min_coords);
            max_coords = min(max_coords, image_size);
            
            raw_image = obj.ViewerPanel.OverlayImage.RawImage;
            
            subimage = raw_image(min_coords(1):max_coords(1), min_coords(2):max_coords(2), min_coords(3):max_coords(3));
            
            
            if obj.PaintOverBackground
                subimage(clipped_brush) = obj.Colour;
                
            else
                subimage_mask = clipped_brush & (subimage > 0);
                connected_components_structure =  bwconncomp(subimage_mask, 6);
                labeled_components = labelmatrix(connected_components_structure);
                central_component_label = labeled_components(midpoint(1), midpoint(2), midpoint(3));
                central_component = labeled_components == central_component_label;
                subimage(central_component) = obj.Colour;
            end
            
            
            
            raw_image(min_coords(1):max_coords(1), min_coords(2):max_coords(2), min_coords(3):max_coords(3)) = subimage;
            
            obj.OverlayChangeLock = true;
            obj.ViewerPanel.OverlayImage.ChangeRawImage(raw_image);
            obj.OverlayChangeLock = false;
            
            
        end
        
        function ChangeColourCallback(obj, ~, ~, colour)
            obj.Colour = colour;
        end
        
        function MouseHasMoved(obj, viewer_panel, coords, last_coords, mouse_is_down)
            %             if obj.Enabled
            %             end
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
        
    end
    
    methods (Access = private)
        function AddContextMenu(obj, figure_handle)
            obj.ContextMenu = uicontextmenu('Parent', figure_handle);
            menu_erase = @(x, y) obj.ChangeColourCallback(x, y, 0);
            menu_blue = @(x, y) obj.ChangeColourCallback(x, y, 1);
            menu_green = @(x, y) obj.ChangeColourCallback(x, y, 2);
            menu_red = @(x, y) obj.ChangeColourCallback(x, y, 3);
            menu_cyan = @(x, y) obj.ChangeColourCallback(x, y, 4);
            menu_magenta = @(x, y) obj.ChangeColourCallback(x, y, 5);
            menu_yellow = @(x, y) obj.ChangeColourCallback(x, y, 6);
            menu_grey = @(x, y) obj.ChangeColourCallback(x, y, 7);
            
            uimenu(obj.ContextMenu, 'Label', 'Erase', 'Callback', menu_erase, 'ForegroundColor', obj.Colours{1});
            uimenu(obj.ContextMenu, 'Label', 'Change colour to:', 'Separator', 'on', 'Enable', 'off');
            uimenu(obj.ContextMenu, 'Label', '  Blue', 'Callback', menu_blue, 'ForegroundColor', obj.Colours{2});
            uimenu(obj.ContextMenu, 'Label', '  Green', 'Callback', menu_green, 'ForegroundColor', obj.Colours{3});
            uimenu(obj.ContextMenu, 'Label', '  Red', 'Callback', menu_red, 'ForegroundColor', obj.Colours{4});
            uimenu(obj.ContextMenu, 'Label', '  Cyan', 'Callback', menu_cyan, 'ForegroundColor', obj.Colours{5});
            uimenu(obj.ContextMenu, 'Label', '  Magenta', 'Callback', menu_magenta, 'ForegroundColor', obj.Colours{6});
            uimenu(obj.ContextMenu, 'Label', '  Yellow', 'Callback', menu_yellow, 'ForegroundColor', obj.Colours{7});
            uimenu(obj.ContextMenu, 'Label', '  Grey', 'Callback', menu_grey, 'ForegroundColor', obj.Colours{8});
        end
        
    end
end

