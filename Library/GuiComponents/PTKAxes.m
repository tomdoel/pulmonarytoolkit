classdef PTKAxes < PTKUserInterfaceObject
    % PTKAxes. Part of the gui for the Pulmonary Toolkit.
    %
    %     This class is used internally within the Pulmonary Toolkit to help
    %     build the user interface.
    %
    %     PTKAxes is used to build axes for supporting image display.
    %     By default the axes are always hidden, but they are required in order to
    %     define the image limits to display
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    properties (Access = private)
        XLim
        YLim
        HoldOnCreate = true
        AxisLimits
        PreviousOrientation
    end
    
    methods
        function obj = PTKAxes(parent)
            obj = obj@PTKUserInterfaceObject(parent);
            
            % Always hide the axes
            obj.VisibleParameter = 'off';
            
            obj.ClearAxesCache;
        end
        
        function CreateGuiComponent(obj, position, reporting)
            obj.GraphicalComponentHandle = axes('Parent', obj.Parent.GetContainerHandle(reporting), 'Units', 'pixels', 'Position', position, 'YDir', 'reverse', 'Visible', 'off');
            
            if ~isempty(obj.XLim)
                set(obj.GraphicalComponentHandle, 'XLim', obj.XLim, 'YLim', obj.YLim)
            end
            
            if obj.HoldOnCreate
                hold(obj.GraphicalComponentHandle, 'on');
            end
        end

        function current_point = GetCurrentPoint(obj)
            current_point = get(obj.GraphicalComponentHandle, 'CurrentPoint');
        end
        
        function SetContextMenu(obj, context_menu)
            set(obj.GraphicalComponentHandle, 'uicontextmenu', context_menu);
        end
        
        function EnablePan(obj, enabled)
            if ~isempty(obj.GraphicalComponentHandle)
                if enabled
                    param = 'on';
                else
                    param = 'off';
                end
                pan(obj.GraphicalComponentHandle, param);
            end
        end        
        
        function EnableZoom(obj, enabled)
            if ~isempty(obj.GraphicalComponentHandle)
                if enabled
                    param = 'on';
                else
                    param = 'off';
                end
                zoom(obj.GraphicalComponentHandle, param);
            end
        end
        
        function ResetZoom(obj)
            zoom(obj.GraphicalComponentHandle, 'reset');
        end

        function Resize(obj, position)
            Resize@PTKUserInterfaceObject(obj, position);
            
            axis(obj.GraphicalComponentHandle, 'fill');
        end
        
        function SetLimitsAndRatio(obj, x_lim, y_lim, data_aspect_ratio, axes_reset_object)
            set(obj.GraphicalComponentHandle, 'XLim', x_lim, 'YLim', y_lim, 'DataAspectRatio', data_aspect_ratio);
            if isempty(axes_reset_object)
                obj.ResetZoom;
            else
                setappdata(obj.GraphicalComponentHandle, 'matlab_graphics_resetplotview', axes_reset_object);
            end
        end
        
        function SetLimits(obj, x_lim, y_lim)
            % Set the limits of the axes
            
            x_valid = ~isempty(x_lim) && x_lim(2) > x_lim(1);
            y_valid = ~isempty(y_lim) && y_lim(2) > y_lim(1);
            
            if x_valid
                obj.XLim = x_lim;
            end
            if y_valid
                obj.YLim = y_lim;
            end
            
            if ~isempty(obj.GraphicalComponentHandle)
                if x_valid && y_valid
                    set(obj.GraphicalComponentHandle, 'XLim', x_lim, 'YLim', y_lim)
                elseif x_valid
                    set(obj.GraphicalComponentHandle, 'XLim', x_lim)
                elseif y_valid
                    set(obj.GraphicalComponentHandle, 'YLim', y_lim)
                end
            end
        end

        function [x_lim, y_lim] = GetLimits(obj)
            x_lim = get(obj.GraphicalComponentHandle, 'XLim');
            y_lim = get(obj.GraphicalComponentHandle, 'YLim');
        end
                
        function [min_coords, max_coords] = GetImageLimits(obj)
            % Gets the current limits of the visible image axes
            
            [x_lim, y_lim] = obj.GetLimits;
            min_coords = [x_lim(1), y_lim(1)];
            max_coords = [x_lim(2), y_lim(2)];
        end
        
        
        function frame = Capture(obj, xlim_image, ylim_image)
            % Captures the image from the current axes as a frame
            
            % Matlab cannot capture images on a secondary monitor, so we must
            % move the figure to the primary monitor
            old_position = get(obj.GraphicalComponentHandle, 'Position');
            movegui(obj.GraphicalComponentHandle);
            
            % Fetch the current screen coordinates of the axes
            rect_screenpixels = get(obj.GraphicalComponentHandle, 'Position');
            
            % The image may not occupy the entire axes, so we need to crop the
            % rectangle to only include the image
            xlim = get(obj.GraphicalComponentHandle, 'XLim');
            ylim = get(obj.GraphicalComponentHandle, 'YLim');

            x_size_screenpixels = rect_screenpixels(3);
            x_size_imagepixels = xlim(2) - xlim(1);
            scale_x = x_size_screenpixels/x_size_imagepixels;
            y_size_screenpixels = rect_screenpixels(4);
            y_size_imagepixels = ylim(2) - ylim(1);
            scale_y = y_size_screenpixels/y_size_imagepixels;
            
            
            x_offset_imagevoxels = max(0, xlim_image(1) - xlim(1));
            x_offset_screenvoxels = x_offset_imagevoxels*scale_x;
            
            x_endoffset_imagevoxels = max(0, xlim(2) - xlim_image(2));
            x_endoffset_screenvoxels = x_endoffset_imagevoxels*scale_x;

            y_offset_imagevoxels = max(0, ylim_image(1) - ylim(1));
            y_offset_screenvoxels = y_offset_imagevoxels*scale_y;
            
            y_endoffset_imagevoxels = max(0, ylim(2) - ylim_image(2));
            y_endoffset_screenvoxels = y_endoffset_imagevoxels*scale_y;

            % Crop the image rectangle so it only contains the image
            rect_screenpixels(1) = rect_screenpixels(1) + x_offset_screenvoxels;
            rect_screenpixels(2) = rect_screenpixels(2) + y_offset_screenvoxels;
            rect_screenpixels(3) = rect_screenpixels(3) - x_offset_screenvoxels - x_endoffset_screenvoxels;
            rect_screenpixels(4) = rect_screenpixels(4) - y_offset_screenvoxels - y_endoffset_screenvoxels;
            rect_screenpixels = round(rect_screenpixels);

            % Capture the image as a bitmap
            frame = PTKImageUtilities.CaptureFigure(obj.GetParentFigure.GetContainerHandle, rect_screenpixels);
            
            % Return the figure to its original position 
            set(obj.GraphicalComponentHandle, 'Position', old_position);            
        end
        
        function ClearAxesCache(obj)
            obj.PreviousOrientation = [];
            obj.AxisLimits = [];
            obj.AxisLimits{1} = PTKAxisCache;
            obj.AxisLimits{2} = PTKAxisCache;
            obj.AxisLimits{3} = PTKAxisCache;
        end
        
        function [x_range, y_range] = UpdateAxes(obj, background_image, orientation)
            if ~isempty(obj.PreviousOrientation)
                [x_lim, y_lim] = obj.GetLimits;

                obj.AxisLimits{obj.PreviousOrientation}.XLim = x_lim;
                obj.AxisLimits{obj.PreviousOrientation}.YLim = y_lim;
                obj.AxisLimits{obj.PreviousOrientation}.ResetAxisData = getappdata(obj.GraphicalComponentHandle, 'matlab_graphics_resetplotview');
            end
            
            axes_width_screenpixels = obj.Position(3);
            axes_height_screenpixels = obj.Position(4);
            
            % If a resize has changed the aspect ratio of the axes then we need to reset the
            % cached limits to force new limits to be set
            axes_ratio = axes_width_screenpixels/axes_height_screenpixels;
            if ~isempty(obj.AxisLimits{orientation}.AxesAspectRatio)
                if abs(obj.AxisLimits{orientation}.AxesAspectRatio - axes_ratio) > 0.001
                    obj.ClearAxesCache;
                end
            end

            % Use the cached axes limit value if available
            if isempty(obj.PreviousOrientation) || isempty(obj.AxisLimits{orientation}.XLim)
                [x_lim, y_lim, x_range, y_range, data_aspect_ratio] = obj.ComputeNewAxisLimits(background_image, orientation);
                obj.SetLimitsAndRatio(x_lim, y_lim, data_aspect_ratio, []);
                obj.AxisLimits{orientation}.AxesAspectRatio = axes_ratio;
                obj.AxisLimits{orientation}.XRange = x_range;
                obj.AxisLimits{orientation}.YRange = y_range;
                obj.AxisLimits{orientation}.DataAspectRatio = data_aspect_ratio;
            else
                [x_lim, y_lim, x_range, y_range, data_aspect_ratio, axes_reset_object] = obj.GetPreviousAxisLimits(orientation);
                obj.SetLimitsAndRatio(x_lim, y_lim, data_aspect_ratio, axes_reset_object);
            end
                        
            obj.PreviousOrientation = orientation;
        end
        
        function [x_lim, y_lim, x_range, y_range, data_aspect_ratio, axes_reset_object] = GetPreviousAxisLimits(obj, orientation)
            x_lim = obj.AxisLimits{orientation}.XLim;
            y_lim = obj.AxisLimits{orientation}.YLim;
            x_range = obj.AxisLimits{orientation}.XRange;
            y_range = obj.AxisLimits{orientation}.YRange;
            data_aspect_ratio = obj.AxisLimits{orientation}.DataAspectRatio;
            axes_reset_object = obj.AxisLimits{orientation}.ResetAxisData;
        end
        
        function [x_lim, y_lim, x_range, y_range, data_aspect_ratio] = ComputeNewAxisLimits(obj, background_image, orientation)
            image_size = background_image.ImageSize;
            voxel_size = background_image.VoxelSize;
            axes_width_screenpixels = obj.Position(3);
            axes_height_screenpixels = obj.Position(4);
            
            [dim_x_index, dim_y_index, dim_z_index] = PTKImageCoordinateUtilities.GetXYDimensionIndex(orientation);
            x_range = [1, image_size(dim_x_index)];
            y_range = [1, image_size(dim_y_index)];
            
            pixel_ratio = [voxel_size(dim_y_index), voxel_size(dim_x_index), voxel_size(dim_z_index)];
            data_aspect_ratio = 1./[pixel_ratio(2) pixel_ratio(1) pixel_ratio(3)];
            
            image_size_mm = image_size.*voxel_size;
            image_height_mm = image_size_mm(dim_y_index);
            image_width_mm = image_size_mm(dim_x_index);
            
            screenpixels_per_mm_x = axes_width_screenpixels/image_width_mm;
            rescaled_height_screenpixels = image_height_mm*screenpixels_per_mm_x;
            if rescaled_height_screenpixels <= axes_height_screenpixels
                scale_to_x = true;
            else
                scale_to_x = false;
            end
            
            if (scale_to_x)
                screenpixels_per_mm = axes_width_screenpixels./image_width_mm;
                rescaled_height_screenpixels = image_height_mm.*screenpixels_per_mm;
                vertical_space_screenpixels = (axes_height_screenpixels - rescaled_height_screenpixels)/2;
                vertical_space_mm = vertical_space_screenpixels./screenpixels_per_mm;
                vertical_space_pixels = vertical_space_mm./pixel_ratio(1);
                x_lim = [x_range(1) - 0.5, x_range(2) + 0.5];
                y_lim = [y_range(1) - vertical_space_pixels - 0.5, y_range(2) + vertical_space_pixels + 0.5];
            else
                screenpixels_per_mm = axes_height_screenpixels./image_height_mm;
                rescaled_width_screenpixels = image_width_mm.*screenpixels_per_mm;
                horizontal_space_screenpixels = (axes_width_screenpixels - rescaled_width_screenpixels)/2;
                horizontal_space_mm = horizontal_space_screenpixels./screenpixels_per_mm;
                horizontal_space_pixels = horizontal_space_mm./pixel_ratio(2);
                x_lim = [x_range(1) - horizontal_space_pixels - 0.5, x_range(2) + horizontal_space_pixels + 0.5];
                y_lim = [y_range(1) - 0.5, y_range(2) + 0.5];
            end
            
        end
        
        function ZoomTo(obj, orientation, i_limits_local, j_limits_local, k_limits_local)
            
            % Update the cached axis limits
            obj.AxisLimits{PTKImageOrientation.Coronal}.XLim = j_limits_local;
            obj.AxisLimits{PTKImageOrientation.Coronal}.YLim = k_limits_local;
            obj.AxisLimits{PTKImageOrientation.Sagittal}.XLim = i_limits_local;
            obj.AxisLimits{PTKImageOrientation.Sagittal}.YLim = k_limits_local;
            obj.AxisLimits{PTKImageOrientation.Axial}.XLim = j_limits_local;
            obj.AxisLimits{PTKImageOrientation.Axial}.YLim = i_limits_local;

            % Update the current axis limits
            switch orientation
                case PTKImageOrientation.Coronal
                    obj.SetLimits(j_limits_local, k_limits_local)
                case PTKImageOrientation.Sagittal
                    obj.SetLimits(i_limits_local, k_limits_local)
                case PTKImageOrientation.Axial
                    obj.SetLimits(j_limits_local, i_limits_local)
            end
            
        end
        
    end
end