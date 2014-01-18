classdef PTKEditManager < PTKTool
    % PTKEditManager. Part of the internal gui for the Pulmonary Toolkit.
    %
    %     You should not use this class within your own code. It is intended to
    %     be used internally within the gui of the Pulmonary Toolkit.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    properties
        ButtonText = 'Edit'
        Cursor = 'hand'
        RestoreKeyPressCallbackWhenSelected = false
        ToolTip = 'Manually edit current result.'
        Tag = 'Edit'
        ShortcutKey = 'e'
    end
    
    properties
        FixedOuterBoundary = true % When this is set to true, the outer boundary cannot be changed
        
        BrushSize = 15 % Minimum size of the gaussian used to adjust the distance tranform
        
        LockToBorderDistance = 10 % When the mouse is closer to the border then this, the brush will actually be applied on the border
    end
    
    properties (SetAccess = private)
        
        % Keep a record of when we have unsaved changes to markers
        ImageHasChanged = false
        
    end
    
    properties (Access = private)
        Colours
        
        ViewerPanel
        
        ClosestColour
        SecondClosestColour

        Enabled = false
        
        OverlayChangeLock
    end
    
    methods
        function obj = PTKEditManager(viewer_panel)
            obj.ViewerPanel = viewer_panel;
            obj.OverlayChangeLock = false;
            obj.InitialiseEditMode;
        end
        
        
        function Enable(obj, enable)
            obj.Enabled = enable;
        end
        
        function processed = Keypress(obj, key_name)
            processed = false;
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
            if ~isempty(obj.ViewerPanel.OverlayImage)
                if ~obj.ViewerPanel.OverlayImage.IsEmpty
                    colours = unique(obj.ViewerPanel.OverlayImage.RawImage);
                    obj.FixedOuterBoundary = numel(colours) > 2;
                end
            end
        end

        
        function [closest, second_closest] = GetClosestIndices(obj, local_image_coords)
            distances = obj.DT(local_image_coords(1), local_image_coords(2), local_image_coords(3), :);
            [~, sorted_indices] = sort(distances, 'ascend');
            closest = sorted_indices(1);
            second_closest = sorted_indices(2);
        end
        
        function [closest_colour, second_closest_colour] = GetClosestIndices2D(obj, local_image_coords)
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
            
            if obj.FixedOuterBoundary
                colours = setdiff(colours, 0);
            end
            
            dts = zeros([size(image_slice), numel(colours)]);
            
            for colour_index = 1 : numel(colours);
                colour = colours(colour_index);
                dts(:, :, colour_index) = bwdist(image_slice == colour);
            end
            distances = dts(x_coord, y_coord, :);
            
            [~, sorted_indices] = sort(distances, 'ascend');
            closest = sorted_indices(1);
            second_closest = sorted_indices(2);            

            closest_colour = colours(closest);
            second_closest_colour = colours(second_closest);
        end

        function [distance, border_distance, border_point] = GetClosestIndices2DForColours(obj, local_image_coords, closest_colour, second_closest_colour)
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
            
            
%             dt_closest =  bwdist(image_slice == closest_colour);
            dt_second_closest =  bwdist(image_slice == second_closest_colour);
            
            distance = dt_second_closest(x_coord, y_coord);
            
            [dt_border, indices] = bwdist(image_slice == 0);
            border_distance = dt_border(x_coord, y_coord);
            border_index = indices(x_coord, y_coord);
            [border_index_x, border_index_y]  = ind2sub(size(indices), double(border_index));
            
            switch orientation
                case PTKImageOrientation.Coronal
                    border_point = [slice_number, border_index_x, border_index_y];
                case PTKImageOrientation.Sagittal
                    border_point = [border_index_x, slice_number, border_index_y];
                case PTKImageOrientation.Axial
                    border_point = [border_index_x, border_index_y, slice_number];
                otherwise
                    error('Unsupported dimension');
            end

        end
        

        
        
        function MouseDown(obj, coords)
            if obj.Enabled
                if obj.ViewerPanel.OverlayImage.ImageExists
%                 obj.IsDragging = true;
                    obj.StartBrush(coords);
                end
            end
        end
        
        function MouseUp(obj, coords)
            if obj.Enabled
                    obj.ApplyBrush(coords);
                
%                 if obj.IsDragging
%                     obj.IsDragging = false;
%                 end
            end
        end

        function StartBrush(obj, coords)
            global_image_coords = round(obj.GetGlobalImageCoordinates(coords));
            local_image_coords = obj.ViewerPanel.OverlayImage.GlobalToLocalCoordinates(global_image_coords);
            [closest_colour, second_closest_colour] = obj.GetClosestIndices2D(local_image_coords);
            
            obj.ClosestColour = closest_colour;
            obj.SecondClosestColour = second_closest_colour;
            
        end
        
        function ApplyBrush(obj, coords)
            if (~isempty(obj.ClosestColour)) && (~isempty(obj.SecondClosestColour))
                image_size = obj.ViewerPanel.OverlayImage.ImageSize;
                voxel_size = obj.ViewerPanel.OverlayImage.VoxelSize;
                
                global_image_coords = round(obj.GetGlobalImageCoordinates(coords));
                local_image_coords = obj.ViewerPanel.OverlayImage.GlobalToLocalCoordinates(global_image_coords);
                
                closest_colour = obj.ClosestColour;
                second_closest_colour = obj.SecondClosestColour;
                [distance_2d, border_distance_2d, border_point] = obj.GetClosestIndices2DForColours(local_image_coords, closest_colour, second_closest_colour);
                
                % When the mouse is close to the region border, we apply the
                % correction at the nearest border point, as this gives a connection
                % between the selected point and the image boundary
                if obj.FixedOuterBoundary
                    if border_distance_2d < distance_2d || border_distance_2d < obj.LockToBorderDistance
                        local_image_coords = border_point;
                    end
                end
                
                gaussian_size = max(obj.BrushSize, distance_2d/2);
                gaussian_image = PTKNormalisedGaussianKernel(voxel_size, gaussian_size);
                
                local_size = size(gaussian_image);
                
                
                halfsize = floor(local_size/2);
                midpoint = 1 + halfsize;
                min_coords = local_image_coords - halfsize;
                max_coords = local_image_coords + halfsize;
                
                min_clipping = max(0, 1 - min_coords);
                max_clipping = max(0, max_coords - image_size);
                
                min_coords = max(1, min_coords);
                max_coords = min(max_coords, image_size);
                
                raw_image = obj.ViewerPanel.OverlayImage.RawImage;
                subimage = raw_image(min_coords(1):max_coords(1), min_coords(2):max_coords(2), min_coords(3):max_coords(3));
%                 dt_subimage_first = bwdist(subimage == closest_colour);
                dt_subimage_second = bwdist(subimage == second_closest_colour);
                dt_value = dt_subimage_second(midpoint(1), midpoint(2), midpoint(3));
                
                brush_min_coords = 1 + min_clipping;
                brush_max_coords = size(gaussian_image) - max_clipping;
                
                
                add_mask = -dt_value*gaussian_image;
                add_mask = add_mask(brush_min_coords(1) : brush_max_coords(1), brush_min_coords(2) : brush_max_coords(2), brush_min_coords(3) : brush_max_coords(3));
                
                dt_subimage_second = dt_subimage_second + add_mask;
%                 dt_subimage_first = dt_subimage_first - add_mask;
                
                old_subimage = subimage;
                
                subimage(old_subimage == closest_colour & dt_subimage_second <= 0) = second_closest_colour;

                subimage = PTKFillHolesForDualColourImageColours(subimage, closest_colour, second_closest_colour);
                
                raw_image(min_coords(1):max_coords(1), min_coords(2):max_coords(2), min_coords(3):max_coords(3)) = subimage;
                
                
                
                obj.OverlayChangeLock = true;
                obj.ViewerPanel.OverlayImage.ChangeRawImage(raw_image);
                obj.OverlayChangeLock = false;

            end
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
end

