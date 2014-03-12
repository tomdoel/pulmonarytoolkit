classdef PTKVisualiseIn2D < PTKGuiPlugin
    % PTKVisualiseIn2D. Gui Plugin for showing the current 2D image slice in a
    % separate figure.
    %
    %     You should not use this class within your own code. It is intended to
    %     be used by the gui of the Pulmonary Toolkit.
    %
    %     PTKVisualiseIn2D is a Gui Plugin for the TD Pulmonary Toolkit.
    %     The gui will create a button for the user to run this plugin.
    %     Running this plugin will create a new figure and display the current
    %     image slice.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    

    properties
        ButtonText = '2D'
        ToolTip = 'Opens a new window showing the current 2D background image'
        Category = 'View'
        Visibility = 'Overlay'
        Mode = 'View'

        HidePluginInDisplay = false
        PTKVersion = '1'
        ButtonWidth = 4
        ButtonHeight = 1
    end
    
    methods (Static)
        function RunGuiPlugin(ptk_gui_app)
            if (ptk_gui_app.ImagePanel.BackgroundImage.ImageExists)
                
                direction = ptk_gui_app.ImagePanel.Orientation;
                slice_number = ptk_gui_app.ImagePanel.SliceNumber(ptk_gui_app.ImagePanel.Orientation);
                image_slice = ptk_gui_app.ImagePanel.BackgroundImage.GetSlice(slice_number, direction);
                figure;
                PTKVisualiseIn2D.Maximize;
                if (direction == 1) || (direction == 2)
                    image_slice = image_slice';
                end
                imagesc(image_slice);
                colormap gray;
                axes_handle = gca;

                set(axes_handle, 'Units', 'pixels');
                axes_position = get(axes_handle, 'Position');
                axes_width_screenpixels = axes_position(3);
                axes_height_screenpixels = axes_position(4);
                image_size = ptk_gui_app.ImagePanel.BackgroundImage.ImageSize;
                voxel_size = ptk_gui_app.ImagePanel.BackgroundImage.VoxelSize;
                
                [dim_x_index, dim_y_index, dim_z_index] = PTKVisualiseIn2D.GetXYDimensionIndex(direction);
                x_range = [1, image_size(dim_x_index)];
                y_range = [1, image_size(dim_y_index)];
                pixel_ratio = [voxel_size(dim_y_index) voxel_size(dim_x_index) voxel_size(dim_z_index)];
                image_height_mm = voxel_size(dim_y_index).*image_size(dim_y_index);
                image_width_mm = voxel_size(dim_x_index).*image_size(dim_x_index);
                
                screenpixels_per_mm = axes_width_screenpixels/image_width_mm;
                rescaled_height_screenpixels = image_height_mm*screenpixels_per_mm;
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
                 
                data_aspect_ratio = 1./[pixel_ratio(2) pixel_ratio(1) pixel_ratio(3)];
                set(axes_handle, 'XLim', x_lim, 'YLim', y_lim, 'DataAspectRatio', data_aspect_ratio);
                set(axes_handle, 'DataAspectRatio', data_aspect_ratio);
                axis off;
            end
        end
    end
    
    methods (Static, Access = private)
        function [dim_x_index dim_y_index dim_z_index] = GetXYDimensionIndex(orientation)
            switch orientation
                case PTKImageOrientation.Coronal
                    dim_x_index = 2;
                    dim_y_index = 3;
                    dim_z_index = 1;
                case PTKImageOrientation.Sagittal
                    dim_x_index = 1;
                    dim_y_index = 3;
                    dim_z_index = 2;
                case PTKImageOrientation.Axial
                    dim_x_index = 2;
                    dim_y_index = 1;
                    dim_z_index = 3;
            end
        end
        
        % Displays a figure full-screen
        function Maximize(fig)
            
            if nargin==0, fig=gcf; end
            
            units=get(fig,'units');
            set(fig,'units','normalized','outerposition',[0 0 1 1]);
            set(fig,'units',units);
        end        
        
    end
end