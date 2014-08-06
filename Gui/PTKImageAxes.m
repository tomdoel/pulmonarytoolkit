classdef PTKImageAxes < PTKAxes
    % PTKImageAxes. Part of the gui for the Pulmonary Toolkit.
    %
    %     PTKImageAxes inherits from PTKAxes, and includes members for caching axis
    %     limits based on image orientation.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    properties (Access = private)
        AxisLimits
        PreviousOrientation
    end
    
    methods
        function obj = PTKImageAxes(parent)
            obj = obj@PTKAxes(parent);
            
            % Always hide the axes
            obj.VisibleParameter = 'off';
            
            obj.ClearAxesCache;
        end
        
        function CreateGuiComponent(obj, position, reporting)
            CreateGuiComponent@PTKAxes(obj, position, reporting);
            set(obj.GraphicalComponentHandle, 'YDir', 'reverse');
        end

        function Resize(obj, position)
            Resize@PTKAxes(obj, position);
            
%             axis(obj.GraphicalComponentHandle, 'fill');
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